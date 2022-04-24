# Diplomats in Germany

The German ministry of foreign affairs (Auswärtiges Amt) regularly updates a list of all foreign diplomatic missions and their diplomats, which are accredited by the Federal Republic of Germany.

The list in PDF format could be retrieved from the following [website](https://www.auswaertiges-amt.de/de/ReiseUndSicherheit/diplomatische-vertretungen-in-deutschland/199678?openAccordionId=item-199682-0-panel). Click on *"Diplomatische und andere Vertretungen in der Bundesrepublik Deutschland"* to retrieve the newest version of the PDF file.

## Problem
It is difficult to study changes over time, mainly because of two reasons:
- Previous versions of the list are not available anymore, even if you have saved the specific link to the respective PDF file. 
- The data needs to be extracted from the PDF file for easier comparison.  

## Motivation
This project could help overcome this problem, by checking regularly if a new version of the list was published. If a new version was found, the data will be extracted from the PDF file and saved in the database. To track changes between the versions, a raw data vault DWH model is used.

This data model could help answering questions such as:
- How many diplomats were accredited by Germany at a given time?
- What is the average time diplomats spent at the various diplomatic missions in Germany?


# Infrastructure

tbd


# Run the Walkthrough Tutorial

I have created interactive instructions to walk you through the project.

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://console.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/GoogleCloudPlatform/professional-services&cloudshell_tutorial=project-walkthrough.md)

By clicking the button, the Google Cloud Shell Editor will open and ask for your authorization to clone this repository.  
The interactive walkthrough for the project will be displayed on the right side of the Cloud Shell Editor.

***
***Note:** If you have closed the walkthrough and want to reopen it, run the following command in the cloudshell terminal window:*
```sh
cloudshell launch-tutorial setup-instructions.md
```
***

If you don't want to use Cloud Shell Editor you could go through the instructions manually: [Instructions](project-walkthrough.md)




# Setup GCS Environment

Open https://console.cloud.google.com/home/dashboard?cloudshell=true.
On the bottom of the screen a Cloud Shell Terminal pane will appear.

Paste the following command into this terminal window and press enter.

```
PROJECT_ID="diplomats-in-germany-$(shuf -i 100000-999999 -n 1)"
```

Now paste the next command into the terminal and press enter.
You might need to authorise the terminal session.

```
gcloud projects create $PROJECT_ID --name="Diplomats in Germany"
```

If you want to retrieve your PROJECT_ID variable, because the Cloud Shell session was timed out, use this command:
```
PROJECT_ID=$(gcloud projects list --filter='diplomats-in-germany' --limit=1 | egrep -e '[A-Za-z-]+[[:digit:]]+' -o)
```


## Service Account

Create service account for Terraform.
It must have the following roles:
- Bigquery: Create/delete datasets, create/delete tables
    - roles/bigquery.dataOwner
    - roles/bigquery.dataEditor (for DBT only)
    - roles/bigquery.user (for DBT only)
- GCS: create/delete buckets
    - roles/storage.admin
- Cloud Composer: create/delete environment
    - roles/composer.environmentAndStorageObjectAdmin
    - roles/composer.ServiceAgentV2Ext
- Container Registry: create/delete container


gcloud iam service-accounts create terraform --display-name="Terraform Service Account" --project $PROJECT_ID

gcloud beta iam service-accounts add-iam-policy-binding terraform@$PROJECT_ID.iam.gserviceaccount.com --member="serviceAccount:terraform@$PROJECT_ID.iam.gserviceaccount.com" --role='roles/bigquery.dataOwner' --project $PROJECT_ID

gcloud beta iam service-accounts add-iam-policy-binding terraform@$PROJECT_ID.iam.gserviceaccount.com --member="serviceAccount:terraform@$PROJECT_ID.iam.gserviceaccount.com" --role='roles/storage.admin' --project $PROJECT_ID

gcloud iam service-accounts add-iam-policy-binding terraform@$PROJECT_ID.iam.gserviceaccount.com --member="serviceAccount:terraform@$PROJECT_ID.iam.gserviceaccount.com" --role='roles/composer.environmentAndStorageObjectAdmin' --project $PROJECT_ID

gcloud iam service-accounts add-iam-policy-binding terraform@$PROJECT_ID.iam.gserviceaccount.com --member="serviceAccount:terraform@$PROJECT_ID.iam.gserviceaccount.com" --role='roles/composer.ServiceAgentV2Ext' --project $PROJECT_ID


gcloud iam service-accounts keys create ~/terraform-private-key.json --iam-account=terraform@$PROJECT_ID.iam.gserviceaccount.com

cloudshell download ~/terraform-private-key.json


## GCS

gsutil mb -p $PROJECT_ID -c STANDARD -l EUROPE-WEST6 -b on gs://$PROJECT_ID

## BQ

bq --location=EUROPE-WEST6 mk --dataset $PROJECT_ID:staging


CREATE OR REPLACE EXTERNAL TABLE staging.diplomats
OPTIONS (
  format = 'PARQUET',
  uris = ['gs://$PROJECT_ID-data-lake/data/*']
)