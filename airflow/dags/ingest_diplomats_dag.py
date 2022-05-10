import datetime
import os
from typing import Dict

from airflow import DAG
from airflow.utils.dates import days_ago
from airflow.utils.task_group import TaskGroup
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator, ShortCircuitOperator
from airflow.providers.google.cloud.transfers.local_to_gcs import LocalFilesystemToGCSOperator
from airflow.providers.google.cloud.transfers.gcs_to_bigquery import GCSToBigQueryOperator
from google.cloud import storage

from extract_diplomats import ExtractDiplomats


PROJECT_ID: str = os.environ.get("GCP_PROJECT_ID")
GCS_BUCKET: str = os.environ.get("GCP_GCS_BUCKET")
BQ_DATASET: str = os.environ.get("GCQ_BQ_DATASET", 'staging')
BQ_TABLE: str   = os.environ.get("GCQ_BQ_TABLE", 'diplomats')

URL_FULL: str      = 'https://www.auswaertiges-amt.de/blob/199684/87c67abc7386c2a3117858a4428404ec/vertretungenfremderstaatendl-data.pdf'
AIRFLOW_HOME: str  = os.environ.get("AIRFLOW_HOME", "/opt/airflow")
TARGET_FOLDER: str = os.path.join(AIRFLOW_HOME, 'pdf')
TARGET_FILE: str   = os.path.join(TARGET_FOLDER, 'data.pdf')


default_args: Dict = {
    "start_date": days_ago(1),
    "depends_on_past": False,
    "retries": 1,
}


def exists_in_gcs(bucket_name, blob_name) -> bool:
    """Checks whether or not the blob exists in GCS.
    :param bucket_name: GCS bucket name
    :param blob_name: target path & file-name
    :return: bool
    """
    storage_client: storage.Client = storage.Client()
    bucket: storage.bucket.Bucket = storage_client.bucket(bucket_name)
    return storage.Blob(blob_name, bucket).exists()


def check_download(pdf_file, bucket_name, ti) -> bool:
    """Checks whether the downloaded file exists and is valid diplomats pdf file. 
    Extracts date from title page of the diplomats pdf and check whether the data for this date was extracted before.
    :param pdf_file: path & file-name of the diplomats pdf
    :param bucket_name: GCS bucket name to check if data exists there already
    :param ti: Airflow task instance object
    :return: True, if downloaded file is new and valid or False otherwise to stop the ingestion.
    """
    
    # if file path does not exist
    if not os.path.exists(pdf_file):
        return False
    
    try:
        # load PDF file to extract date from title page (autostart=False to prevent full data extraction)
        pdf: ExtractDiplomats = ExtractDiplomats(pdf_file, autostart=False)
    except Exception as e:
        return False
    
    # if not date was found in the pdf file
    if not isinstance(pdf.date, datetime.date):
        return False

    # check if data for the date was extracted and saved to GCS before
    blob_name: str = f'pdf/{pdf.date:%Y-%m-%d}-data.pdf'
    if exists_in_gcs(bucket_name, blob_name):
        return False

    # save date
    ti.xcom_push(key='pdf_date', value=f"{pdf.date:%Y_%m_%d}")
    # save GCS blob name
    ti.xcom_push(key='blob_name', value=f"data/{os.path.join(*pdf.date.strftime('%Y_%m_%d').split('_'))}.parquet")
    
    # return True to continue the DAG
    return True


def extract_data(pdf_file, target_folder) -> None:
    """Checks whether the downloaded file exists and is valid diplomats pdf file. 
    Extracts date from title page of the diplomats pdf.
    :param pdf_file: path & file-name of the diplomats pdf
    :param target_folder: target folder for exracted parquet data files
    """

    # load PDF file to extract date from title page (autostart=False to prevent full data extraction)
    pdf: ExtractDiplomats = ExtractDiplomats(pdf_file)
    pdf.to_parquet(target_folder, date_subdirectory=True)


with DAG(
    dag_id="ingest_diplomats_dag",
    schedule_interval="@daily",
    default_args=default_args,
    catchup=False,
    max_active_runs=1,
    is_paused_upon_creation=False,
) as dag:

    #with TaskGroup(group_id='Extract') as extract_group:

        download_pdf_task = BashOperator(
            task_id='download_pdf',
            do_xcom_push=False,
            bash_command=f'curl -sSLf -o {TARGET_FILE} --create-dirs {URL_FULL} && ls -la /opt/airflow/pdf',
            # -sS: silent, but shows errors
            # -L: follow HTTP/S redirects
            # -f: fail when resource is not available (404 error)
            # -o: output path
            # --create-dirs: create missing folders in the output path
            doc='Download PDF with list of diplomats from Germany Ministry of Foreign Affairs'
        )

        check_download_task = ShortCircuitOperator(
            task_id="check_download",
            do_xcom_push=False,
            python_callable=check_download,
            op_kwargs={
                "pdf_file": TARGET_FILE,
                "bucket_name": GCS_BUCKET,
            },
        )
    
        extract_data_task = PythonOperator(
            task_id="extract_data",
            python_callable=extract_data,
            op_kwargs={
                "pdf_file": TARGET_FILE,
                "target_folder": os.path.join(AIRFLOW_HOME, "data"),
                "test": "{{ ti.xcom_pull(task_ids='check_download', key='pdf_date') }}"
            },
        )

        #download_pdf_task >> check_download_task >> extract_data_task


    #with TaskGroup(group_id='Load') as load_group:

        upload_pdf_to_gcs_task = LocalFilesystemToGCSOperator(
            task_id="upload_pdf_to_gcs",
            src=TARGET_FILE,
            dst="pdf/{{ ti.xcom_pull(task_ids='check_download', key='pdf_date') }}_data.pdf",
            mime_type="application/pdf",
            bucket=GCS_BUCKET,
        )

        upload_pq_to_gcs_task = LocalFilesystemToGCSOperator(
            task_id="upload_pq_to_gcs",
            src=os.path.join(AIRFLOW_HOME, "{{ ti.xcom_pull(task_ids='check_download', key='blob_name') }}"),
            dst="{{ ti.xcom_pull(task_ids='check_download', key='blob_name') }}",
            bucket=GCS_BUCKET,
        )

        load_data_to_bq_task = GCSToBigQueryOperator(
            task_id="load_data_to_bq",
            bucket=GCS_BUCKET,
            source_objects="{{ ti.xcom_pull(task_ids='check_download', key='blob_name') }}",
            destination_project_dataset_table=f"{PROJECT_ID}:{BQ_DATASET}.{BQ_TABLE}",
            source_format="PARQUET",
            autodetect=True,
            create_disposition="CREATE_IF_NEEDED",
            write_disposition="WRITE_TRUNCATE",
        )

        #upload_pq_to_gcs_task >> load_data_to_bq_task


    #with TaskGroup(group_id='Transform') as transform_group:

        dbt_run_task = BashOperator(
            task_id="dbt_run",
            do_xcom_push=False,
            bash_command=f"cd {os.path.join(AIRFLOW_HOME, 'dbt')} && dbt seed && dbt run",
        )
    

    #extract_group >> load_group >>  transform_group
        download_pdf_task >> check_download_task >> extract_data_task >> [upload_pdf_to_gcs_task, upload_pq_to_gcs_task] >> load_data_to_bq_task >> dbt_run_task