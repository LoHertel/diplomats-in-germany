
# Project Walkthrough
<walkthrough-tutorial-duration duration="30"></walkthrough-tutorial-duration>

Welcome to the *Diplomats in Germany* project. This instructions will guide you through the setup process.  
Most steps are automated to make the setup as easy as possible. 

The septup will have the following steps:
1. create Google Cloud project
2. set preferred cloud location
3. authorize APIs
4. create service account for Terraform
5. create infrastructure with Terraform
6. setup Airflow
7. run data pipeline
8. view the Google Data Studio report
9. remove project infrastructure

It costs approx. $1 credit to run the project for an hour.

> ***Note:** If you have closed this instrunctions pane and want to reopen it, run the following command in the Cloud Shell terminal window:*
> ```terminal
> cloudshell launch-tutorial project-walkthrough.md
> ```

&nbsp;  
Click on **Start** to open the instructions for creating a new project.

## 1. Create Google Cloud Project

There are two options to create a Google Cloud project:
* Option 1: Command Line  
* Option 2: Graphical User Interface  

Proceed with <u>one</u> of both.

### Option 1: Command Line
*(Choose <u>either</u> option 1 <u>or</u> option 2)*

> ***Tip:** If you have opened the instructions in Google Cloud Shell, you could click on the grey <walkthrough-cloud-shell-icon></walkthrough-cloud-shell-icon> Cloud Shell icon next to the shell commands to transfer the code to the Cloud Shell terminal window, then press enter in the terminal window to execute the command.*

1. Generate a name for your project:

```sh
PROJECT_ID="diplomats-in-germany-$(shuf -i 100000-999999 -n 1)"
```

2. Create the project with the generated name
*(**Note:** You might need to authorise the terminal session)*:

```sh
gcloud projects create $PROJECT_ID --name="Diplomats in Germany"
```

3. Activate the project in Cloud Shell:
```sh
gcloud config set project $PROJECT_ID
```

> ***Note:** If you want to reopen your project, because the Cloud Shell session has timed out, you can use the following command:*
> ```sh
> PROJECT_ID=$(gcloud projects list --filter='diplomats-in-germany' --limit=1 --format='value(projectId)')
> gcloud config set project $PROJECT_ID
> ```


### Option 2: Graphical User Interface 
*(Choose <u>either</u> option 1 <u>or</u> option 2)*


Click on [create a new project](https://console.cloud.google.com/projectcreate) to create a new Google Cloud project.
Select the created project afterwards in the dropdown field below.

<walkthrough-project-setup></walkthrough-project-setup>
<walkthrough-open-cloud-shell-button></walkthrough-open-cloud-shell-button>

Project ID: <walkthrough-project-id/>  
Project Name: <walkthrough-project-name/>  

&nbsp;  
Click **Next** configure the cloud location.

## 2. Set Preferred Cloud Location

Execute the following command to set a **region** as cloud location for this project:  

```sh
gcloud config set compute/region europe-west1
```
> *The region will be set to `europe-west1`. If you would like to use another location, [choose your preferred region](https://cloud.google.com/storage/docs/locations#location-r) and change it in the shell command above.*

&nbsp;  

Execute the following command to set a **corresponding zone** to the selected region above:  
```sh
gcloud config set compute/zone "$(gcloud config get compute/region)-b"
```
> *The zone will be set to `europe-west1-b`. If you would like to use another zone, change the letter `b` to your preferred zone. All available zones for a region could be [found here](https://cloud.google.com/compute/docs/regions-zones#available).*

&nbsp;  

Execute the following command to store the selected region on a variable for further usage in this walkthrough: 
```sh
GOOGLE_CLOUD_REGION=$(gcloud config get compute/region)
GOOGLE_CLOUD_ZONE=$(gcloud config get compute/zone)
```

&nbsp;  
Click **Next** to start authorizing the necessary APIs for this project.

## 3. Authorize APIs

You need to authorize the following APIs for the project:
* bigquery
* storage
* compute engine

<walkthrough-enable-apis apis="bigquery.googleapis.com,storage-component.googleapis.com,compute.googleapis.com"></walkthrough-enable-apis>

&nbsp;  
Click **Next** to configure a service account for Terraform.

## 4. Create Service Account for Terraform

Create service account for Terraform:
```sh
gcloud iam service-accounts create svc-terraform --display-name="Terraform Service Account" --project=$GOOGLE_CLOUD_PROJECT

GCP_SA_MAIL="svc-terraform@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com"
```

Add roles to the service account:
```sh
gcloud iam service-accounts add-iam-policy-binding $GCP_SA_MAIL --member="serviceAccount:$GCP_SA_MAIL" --role='roles/bigquery.dataOwner' --project $GOOGLE_CLOUD_PROJECT

gcloud iam service-accounts add-iam-policy-binding $GCP_SA_MAIL --member="serviceAccount:$GCP_SA_MAIL" --role='roles/composer.storage.admin' --project $GOOGLE_CLOUD_PROJECT

gcloud iam service-accounts add-iam-policy-binding $GCP_SA_MAIL --member="serviceAccount:$GCP_SA_MAIL" --role='roles/compute.admin' --project $GOOGLE_CLOUD_PROJECT
```

Create API keys:
```sh
gcloud iam service-accounts keys create credentials/terraform-gcp-key.json --iam-account=svc-terraform@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com
```

&nbsp;  
Click **Next** to start creating the cloud infrastructure.

## 5. Create Infrastructure with Terraform

### Create bucket for the Terraform state file. 
It is a [good practice](https://www.terraform.io/language/state/remote) to store the state file on a remote storage, in order to version the state description of the infrastructure, to prevent data loss and to give other members of a team the opportunity to change the infrastructure as well. 

Execute the following command to create a bucket for the Terraform remote state file:
```sh
gsutil mb -p $GOOGLE_CLOUD_PROJECT -c STANDARD -l $GOOGLE_CLOUD_REGION gs://$GOOGLE_CLOUD_PROJECT-tf-state
```

Enable object versioning on the bucket to track changes in the state file and therefore document infrastructure changes:
```sh
gsutil versioning set on gs://$GOOGLE_CLOUD_PROJECT-tf-state
```

### Edit Terraform configuration

Add remote bucket in the ```main.tf``` file:  
Click here to <walkthrough-editor-select-regex filePath='setup/main.tf' regex='(?<=")diplomats-in-germany-xxxxxx'>set your Project ID</walkthrough-editor-select-regex>.

> ***Note:** You could find out your project id by running:*
> ```sh
> echo $GOOGLE_CLOUD_PROJECT
> ```


### Run Terraform

Create SSH key for the Google Compute Engine:
```sh
ssh-keygen
```

Initialize the remote state file (.tfstate):
```sh
terraform init
```

Create an execution plan to build the defined infrastructure:
```sh
terraform plan -var="project=$GOOGLE_CLOUD_PROJECT" -var="region=$GOOGLE_CLOUD_REGION" -var="zone=$GOOGLE_CLOUD_ZONE"
```

Execute the plan and build the infrastructure (it might take a couple of minutes):
```sh
terraform apply -auto-approve -var="project=$GOOGLE_CLOUD_PROJECT" -var="region=$GOOGLE_CLOUD_REGION" -var="zone=$GOOGLE_CLOUD_ZONE"
```

Now you have created the necessary infrastructure.  


&nbsp;  
Click **Next** to setup Airflow.

## 6. Setup Airflow

Get IP adress of compute engine:
```sh
IP_ADDRESS="$(gcloud compute instances describe airflow-host --format='get(networkInterfaces[0].accessConfigs[0].natIP)')"
```

Transfer data to compute engine:


Connect to compute engine:
```sh
ssh local@$IP_ADDRESS
```

Download Git Repository:
```sh
git clone https://github.com/LoHertel/diplomats-in-germany
```


## 7. Run Data Pipeline

> ***Note:** If you are not connected to `local@airflow-host` execute the following command:*
> ```sh
> IP_ADDRESS="$(gcloud compute instances describe airflow-host --format='get(networkInterfaces[0].accessConfigs[0].natIP)')"
> ssh local@$IP_ADDRESS
> ```

Connect to airflow sheduler:
```sh
docker exec -it diplomats-airflow-scheduler-1 bash
```



## 8. Open Data Studio Report

[![infrastructure diagram](https://www.lorenz-hertel.net/dashboard.png "Infrastructure")](https://datastudio.google.com/reporting/c67883ee-7b3a-481f-a28f-e001b0c3c743)


Open the Report using the following link: 
https://datastudio.google.com/reporting/c67883ee-7b3a-481f-a28f-e001b0c3c743


## 9. Clean Up Project 

1. Remove infrastructure using Terraform:
```sh
terraform destroy
```

2. Delete Google Cloud project  
*(**Note:** The following command is going to delete the currently active project in Cloud Shell. Use `echo $GOOGLE_CLOUD_PROJECT` to review, which project is active)*:  
```sh
gcloud projects delete $GOOGLE_CLOUD_PROJECT
```  
If you feel uncertain, you could delete the project from Google Cloud manually: [Visit Ressource Manager](https://console.cloud.google.com/cloud-resource-manager)

3. Remove cloned project repository from your persistent Google Cloud Shell storage:
```sh
cd ~/cloudshell_open
rm -rf diplomats-in-germany
```

Click **Next** to complete the walkthrough.

## Congratulations
<walkthrough-conclusion-trophy></walkthrough-conclusion-trophy>

You went through the whole project, from setup, over running the data pipelines, to using the resulting dashboard. I hope you have liked the project.

Do not forget to remove the infrastructure, if you have not done so already.

This project is my capstone of [DataTalksClub](https://datatalks.club/)'s highly recommended [Data Engineering Zoomcamp](https://github.com/DataTalksClub/data-engineering-zoomcamp). Pay a visit to them, they are amazing!


