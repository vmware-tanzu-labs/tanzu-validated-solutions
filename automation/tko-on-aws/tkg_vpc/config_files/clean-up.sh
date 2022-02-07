#!/usr/bin/env bash

set -e

CONTEXT="${CONTEXT:-tkg-mgmt-aws-admin@tkg-mgmt-aws}"

kubectl config use-context "${CONTEXT}"
kubectl delete cluster -n default --all

export AWS_REGION=$(curl http://169.254.169.254/latest/meta-data/placement/region)
tanzu management-cluster delete tkg-mgmt-aws --yes