#!/usr/bin/env bash
# Nukes everything the deployed management cluster deployed
kubectl config use-context tkg-mgmt-aws-admin@tkg-mgmt-aws
kubectl delete cluster -n default --all
export AWS_REGION=$(curl http://169.254.169.254/latest/meta-data/placement/region)
tanzu management-cluster delete tkg-mgmt-aws --yes