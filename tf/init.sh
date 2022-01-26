#!/bin/bash

set -eax

PROJECT=$(gcloud config get-value project)

terraform init
terraform ${1:-apply} \
          -var="project_id=$PROJECT" \
          -var="region=europe-west1" \
          -var="default_zone=europe-west1-b" \
          -auto-approve

if [ -z ${1+x} ];
then
    gcloud compute ssh solace-broker -- -L :80:localhost:8080 -L :8008:localhost:8008
fi
