
# Project Walkthrough
<walkthrough-tutorial-duration duration="30"></walkthrough-tutorial-duration>

Welcome to the *diplomats in Germany* project. This instructions will guide you through the setup process.  
Most steps are automated to make the setup as smooth as possible. 

The septup will have the following steps:
1. create Google Cloud project
2. authorize APIs
3. create service account for Terraform
4. create infrastructure with Terraform
5. run data pipeline
6. view the Google Data Studio report
7. remove project infrastructure

The cost for running this project


***

***Note:** If you have closed the instrunctions pane and want to reopen it, run the following command in the Cloud Shell terminal window:*
```terminal
cloudshell launch-tutorial project-walkthrough.md
```
***

Click on **Start** to open the instructions for creating a new project.

## 1. Create Google Cloud Project

There are two options to create a Google Cloud project:
* command line
* graphical user interface  

Proceed with <u>either</u> of them.

### Option 1: Command Line

*** 

***Tip:** If you have opened the instructions in Google Cloud Shell, you could click on the <walkthrough-cloud-shell-icon></walkthrough-cloud-shell-icon> Cloud Shell icon next to the shell commands to transfer the code to the Cloud Shell terminal window, then press enter in the terminal window to execute the command.*

***

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

***

***Note:** If you want to reactivate your project, because the Cloud Shell session has timed out, you can use the following command:*
```sh
PROJECT_ID=$(gcloud projects list --filter='diplomats-in-germany' --limit=1 | egrep -e '[A-Za-z-]+[[:digit:]]+' -o)
gcloud config set project $PROJECT_ID
```

***

### Option 2: Graphical User Interface 

Click on [create a new project](https://console.cloud.google.com/projectcreate) to create a new Google Cloud project.
Select the created project afterwards in the dropdown field below.

<walkthrough-project-setup></walkthrough-project-setup>
<walkthrough-open-cloud-shell-button></walkthrough-open-cloud-shell-button>

Project ID: <walkthrough-project-id/>  
Project Name: <walkthrough-project-name/>  

Click **Next** 

## 2. Authorize APIs

You need to authorize the following APIs for the project:
* bigquery
* storage
* cloud composer

<walkthrough-enable-apis apis="bigquery.googleapis.com,storage-component.googleapis.com"></walkthrough-enable-apis>


## 3. Create Service Account for Terraform


## 4. Create Infrastructure with Terraform

Edit Terraform configuration in the ```variables.tf``` file:  
1. <walkthrough-editor-select-regex filePath="variables.tf" regex="REGEX">Set a GCP region</walkthrough-editor-select-regex>


```sh
# Refresh service-account's auth-token for this session
gcloud auth application-default login

# Initialize state file (.tfstate)
terraform init

# Check changes to new infra plan
terraform plan -var="project=$GOOGLE_CLOUD_PROJECT"
```

```sh
# Create new infra
terraform apply -var="project=$GOOGLE_CLOUD_PROJECT"
```

## 5. Run Data Pipeline


## 6. Open Data Studio Report


## 7. Clean Up Project 

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

Do not forget to remove the infrastructure, if you have not done already.

This project is my capstone of [DataTalksClub](https://datatalks.club/)'s highly recommended [Data Engineering Zoomcamp](https://github.com/DataTalksClub/data-engineering-zoomcamp). Pay a visit to them, they are amazing!


