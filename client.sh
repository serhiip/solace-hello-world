#!/bin/bash

set -eax

pushd tf

SOLACE_HOST=tcp://$(terraform output -raw broker-internal-ip):55555

popd

gcloud compute scp ./requirements.txt client:
gcloud compute scp ./*.py client:
gcloud compute ssh client -- "pip3 install virtualenv"
gcloud compute ssh client -- "python3 -m virtualenv env && source ./env/bin/activate && pip3 install -r requirements.txt && SOLACE_HOST=$SOLACE_HOST python listener.py"
