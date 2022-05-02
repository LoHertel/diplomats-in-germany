#!/bin/bash

# Setup Script for running Airflow docker container in a VM

# Install docker in vm instance
sudo apt-get update
sudo apt-get install docker.io


# Setup docker to be run without sudo
sudo groupadd docker  
sudo usermod -aG docker $USER  
newgrp docker  

