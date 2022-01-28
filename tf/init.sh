#!/bin/bash

set -eax

CURDIR=$(dirname $0)
CURPATH=$(realpath $CURDIR)
PROJECT=$(gcloud config get-value project)

terraform init
terraform ${1:-apply} \
          -var="project_id=$PROJECT" \
          -var="region=europe-west1" \
          -var="default_zone=europe-west1-b" \
          -auto-approve

if [ -z ${1+x} ];
then
    gcloud compute ssh solace-broker -- -L :80:localhost:8080 -L :8008:localhost:8008 -L :55554:localhost:55555 -L :1883:localhost:1883 -L :8000:localhost:8000 -L :5672:localhost:5672 -L :9000:localhost:9000 -L :2222:localhost:2222
fi
