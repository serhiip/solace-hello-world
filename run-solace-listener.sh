#!/bin/bash

set -eax

pushd tf

SOLACE_HOST=tcp://$(terraform output -raw solace-broker-internal-ip):55555

popd

gcloud compute scp ./requirements.txt solace-client:
gcloud compute scp ./*.py solace-client:
gcloud compute ssh solace-client -- "pip3 install virtualenv"
gcloud compute ssh solace-client -- "python3 -m virtualenv env && source ./env/bin/activate && pip3 install -r requirements.txt && SOLACE_HOST=$SOLACE_HOST python solace-listener.py"
