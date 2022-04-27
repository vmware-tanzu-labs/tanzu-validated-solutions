# Deploy Tanzu for Kubernetes Operations on AWS air-gap environment

This document outlines the steps for deploying VMware Tanzu for Kubernetes Operations on AWS. The deployment is based on the reference design provided in  [VMware Tanzu Kubernetes Grid  on AWS Air-gap Reference Design](../reference-designs/tko-on-aws-airgap.md).


## Prerequisites
Before deploying VMware Tanzu for Kubernetes Operations on AWS air-gap environment, ensure that the following are set up.

* **AWS Account**: An IAM user account with **administrative privileges**.


* **AWS Resource Quotas**: Sufficient quotas to support both the management cluster and the workload clusters in your deployment. Otherwise, the cluster deployments will fail. Depending on the number of workload clusters you plan to deploy, you may need to increase the AWS services quotas from their default values. You will need to increase the quota in every region in which you deploy Tanzu Kubernetes Grid.
For more information See following links on 
	* [Tanzu Kubernetes Grid resources in AWS account](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.5/vmware-tanzu-kubernetes-grid-15/GUID-mgmt-clusters-aws.html#aws-resources).
	* [AWS service quotas](https://docs.aws.amazon.com/general/latest/gr/aws_service_limits.html) in the AWS.



* **An Internet-connected Linux bootstrap machine** 
The bootstrap machine can be a local device such as a laptop, or a virtual machine running in, for example, VMware Workstation or Fusion. You will use the bootstrap machine to create the AWS VPC and jumpbox
	* Is not inside the internet-restricted environment or can access the domains listed in Proxy Server Allowlist.
	* Has the Docker client app installed.
	* Has [imgpkg](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.5/vmware-tanzu-kubernetes-grid-15/GUID-install-cli.html) installed. 
	* Has a latest version of yq installed.
	* Has a latest version of jq installed.
	* Has AWS cli installed
	* If you intend to install one or more of the optional packages provided by Tanzu Kubernetes Grid, for example, Harbor, the Carvel tools are installed. For more information, see [Install the Carvel Tools](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.5/vmware-tanzu-kubernetes-grid-15/GUID-install-cli.html)

* **VMware Cloud**: Access to [VMware Cloud]( https://customerconnect.vmware.com/login ) to download Tanzu CLI.

For additional information about preparing to deploy Tanzu Kubernetes Grid on AWS, see [Prepare to Deploy Management Clusters to Amazon EC2](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.5/vmware-tanzu-kubernetes-grid-15/GUID-mgmt-clusters-aws.html).

## Overview of the Deployment Steps

The following provides an overview of the major steps necessary to deploy Tanzu for Kubernetes Operations on AWS EC2. Each steps links to the section for detailed information.

1. [Set up AWS Infrastructure](#aws-infra).
2. [Creating offline JumpBox](#offline-jumpbox)
3. [Create and Set Up a Private container registry](#private-repo).
4. [Copy the container images required to deploy Tanzu Kubernetes Grid](#copy-tkg-img).  
5. [Prepare an Internet-Restricted Environment](#prepEnv).
6. [Install Tanzu Kubernetes Grid Management Cluster](#install-tkg).
7. [Examine the Management Cluster Deployment](#examine-cluster).
8. [Deploy Workload Clusters](#deploy-workload-cluster).
9. [Install and Configure Packages into Workload Clusters](#install-packages).
10. [Logs and Troubleshooting](#logs).
11. [Delete Clusters](#cluster-mgmt).
12. [Air-gapped <!-- /* cSpell:disable */ -->STIG/FIPS <!-- /* cSpell:enable */ --> deployment on AWS](#stig-fips). 	
13. [Tanzu Kubernetes Grid Upgrade](#upgrade-tkg).


## <a id=aws-infra> </a> Set up AWS Infrastructure
The following describes the steps to create your AWS environment and configure your network. Follow the steps in the order provided.

  ### Create internet restricted(aka offline) vpc
   You should follow steps given below to create aws offline vpc or you can check [aws vpc documentation](https://docs.aws.amazon.com/vpc/latest/userguide/working-with-vpcs.html) . Make sure in offline VPC should not have NAT gateway or internet gateway. Create your offline vpc with private subnets only. 
Steps to follow -

 **Step 01. Create a VPC**

* Login to your AWS Console and select vpc service.
* Create your VPC with Valid CIDR and name.

**Step 02.  Create 3 Private Subnets**

* Click Subnet and create your Subnet with:
* Private Subnet 1 , Private Subnet 2 and Private Subnet 3 valid Name & VPC.
* Valid Subnet range which is valid IPv4 CIDR Block.

**Step 03. Create Private Route Table**

* Create a Route table in the same VPC.
* Make sure you selected the right VPC and give a proper tag.

**Step 04. Add Private Subnet in Private Route Table**

* Edit the Subnet Association.
* Select the PrivateSubnet checkbox.
* Click on the Save button.

**Step 05. Edit DNS Resolution and Hostname**
* Click on Action and Edit DNS hostname
* Checkmark on DNS Hostname and click on save.

**Note :** If you are creating multiple offline VPC's , please follow instructions to create [aws transit gateway](https://docs.aws.amazon.com/vpc/latest/tgw/tgw-getting-started.html)

### Add VPC endpoints into offline VPC

After you create the offline VPC, you must add following endpoints to it (VPC endpoint enables private connections between your VPC and supported AWS services):

* Service endpoints:
* sts
* ssm
* ec2
* ec2messages
* elasticloadbalancing
* secretsmanager
* ssmmessages
* s3(gateway type)

You can refer [aws create endpoints service documentation](https://docs.aws.amazon.com/vpc/latest/privatelink/create-endpoint-service.html) for further details.

## <a id=offline-jumpbox> </a> Creating offline JumpBox

After doing the network configuration, complete the steps described in this section to set up your jumpbox. You will download the Tanzu CLI to the jumpbox, which you will use to deploy the management cluster and workload clusters from the jumpbox. You also keep the Tanzu and Kubernetes configuration files for your deployments on your jumpbox.

1. Create a jumpbox.

	<!-- /* cSpell:disable */ -->

	```bash

	#Set up AWS credentials
	export AWS_ACCESS_KEY_ID=xx
	export AWS_SECRET_ACCESS_KEY=xx
	# Should be a region with at least 3 available AZs
	export AWS_REGION=us-east-1
	export AWS_PAGER=""

	#Set up AWS profile

	aws ec2 describe-instances --profile <profile name>
	export AWS_PROFILE=<profile name>

   # set offline vpc and private subnet id
   export vpcId=<offline vpc id>
   export prisubnetId=<private subnet id>
   export WORKING_DIR=<local working dir>

	aws ec2 create-security-group --group-name "jumpbox-ssh" --description "To Jumpbox" --vpc-id "$vpcId" --output json > $WORKING_DIR/sg_jumpbox_ssh
	aws ec2 create-tags --resources $(jq -r .GroupId $WORKING_DIR/sg_jumpbox_ssh) --tags Key=Name,Value="jumpbox-ssh"
	# Allow ssh to jumpbox
	aws ec2 authorize-security-group-ingress --group-id  $(jq -r .GroupId $WORKING_DIR/sg_jumpbox_ssh) --protocol tcp --port 22 --cidr "0.0.0.0/0"

	# Save this file or use some team keypair already created
	aws ec2 create-key-pair --key-name tkg-kp --query 'KeyMaterial' --output text > tkgkp.pem
	chmod 400 tkgkp.pem

	# Find an AMI for your region https://cloud-images.ubuntu.com/locator/ec2/ (20.04)
	aws ec2 run-instances --image-id ami-036d46416a34a611c --count 1 --instance-type t2.xlarge --key-name tkg-kp --security-group-ids  $(jq -r .GroupId $WORKING_DIR/sg_jumpbox_ssh)   --subnet-id $prisubnetId  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=tkg-jumpbox}]' --block-device-mappings 'DeviceName=/dev/sda1,Ebs={VolumeSize=64}' > $WORKING_DIR/instance_jb_starting
	```
	<!-- /* cSpell:enable */ -->

2. Wait a few minutes for the instance to start. After it restarts, SSH to the jumpbox.

	<!-- /* cSpell:disable */ -->
	```bash
	aws ec2 describe-instances --instance-id $(jq -r '.Instances[0].InstanceId' $WORKING_DIR/instance_jb_starting) > $WORKING_DIR/instance_jb_started

	echo j IP: $(jq -r '.Reservations[0].Instances[0].PrivateIpAddress' $WORKING_DIR/instance_jb_started)

	ssh ubuntu@$(jq -r '.Reservations[0].Instances[0].PrivateIpAddress' $WORKING_DIR/instance_jb_started) -i tkgkp.pem
	```
	<!-- /* cSpell:enable */ -->

3. Log in to the jumpbox to install the necessary packages and configurations. Then reboot.
 
	<!-- /* cSpell:disable */ -->
 
  * [Download docker package](https://download.docker.com/linux/ubuntu/dists/) , choose your Ubuntu version, then browse to pool/stable and choose amd64, armhf, arm64, or s390x, and download the .deb file for the Docker Engine version you want to install.

	```bash
	#Copy the files and binaries to the jumpbox.
	scp -i tkgkp.pem <docker package file>.deb ubuntu@$(jq -r '.Reservations[0].Instances[0].PrivateIpAddress' $WORKING_DIR/instance_jb_started):/home/ubuntu
	#login to jumpbox
	ssh ubuntu@<jumpbox-ip> -i tkgkp.pem
	#Install Docker Engine and reboot jumpbox
	sudo dpkg -i /home/ubuntu/<docker package file>.deb
	sudo adduser ubuntu docker
	sudo reboot
	```
<!-- /* cSpell:enable */ -->

4. Download the Tanzu CLI and other utilities for Linux from the Tanzu Kubernetes Grid [Download Product](https://customerconnect.vmware.com/downloads/details?downloadGroup=TKG-142&productId=988&rPId=73652) site.

5. Copy the files and binaries to the jumpbox.

	<!-- /* cSpell:disable */ -->
	```bash
	scp -i tkgkp.pem tanzu-cli-bundle-linux-amd64.tar kubectl-linux-v1.21.8+vmware.1-142.gz ubuntu@$(jq -r '.Reservations[0].Instances[0].PrivateIpAddress' $WORKING_DIR/instance_jb_started):/home/ubuntu
	```
<!-- /* cSpell:enable */ -->

7. Connect to the jumpbox 

	<!-- /* cSpell:disable */ -->
	```bash
	ssh ubuntu@<jumpbox-ip> -i tkgkp.pem

	```
	<!-- /* cSpell:enable */ -->

8. Install the Tanzu CLI.

	Run the session in `screen` in case your SSH connection is terminated.
	If your connection is terminated, you can reattach to the screen session
	with `screen -r` once you have reconnected.

	<!-- /* cSpell:disable */ -->		
	```bash
	screen
	tar -xzvf tanzu-cli-bundle-linux-amd64.tar.gz
	gunzip kubectl-*.gz
	sudo install kubectl-linux-* /usr/local/bin/kubectl
	cd cli/
	sudo install core/*/tanzu-core-linux_amd64 /usr/local/bin/tanzu
	gunzip *.gz
	sudo install imgpkg-linux-amd64-* /usr/local/bin/imgpkg
	sudo install kapp-linux-amd64-* /usr/local/bin/kapp
	sudo install kbld-linux-amd64-* /usr/local/bin/kbld
	sudo install vendir-linux-amd64-* /usr/local/bin/vendir
	sudo install ytt-linux-amd64-* /usr/local/bin/ytt
	cd ..
	tanzu plugin sync
	tanzu config init
	```
	<!-- /* cSpell:enable */ -->


	Running the `tanzu config init` command for the first time creates the `~/.config/tanzu/tkg` subdirectory, which contains the Tanzu Kubernetes Grid configuration files.

	<!-- /* cSpell:enable */ -->



## <a id=private-repo> </a> Create and Set Up a Private container registry

This registry should run outside of Tanzu Kubernetes Grid and is separate from any registry deployed as a shared service for clusters

* You can configure the container registry with SSL certificates signed by a trusted CA, or with self-signed certificates.
* The registry must not implement user authentication. For example, if you use a Harbor registry, the project must be public, and not private.
* You can setup this private registry into offline jumpbox machine or setup in another ec2 instance inside offline vpc. 

### Install Harbor
* Download the [binaries for the latest Harbor release](https://github.com/goharbor/harbor/releases)
* Follow the Harbor [Installation and Configuration](https://goharbor.io/docs/2.0.0/install-config/) instructions in the Harbor documentation.

## <a id=copy-tkg-img> </a> Copy the container images required to deploy Tanzu Kubernetes Grid



 Copy the container images required to deploy Tanzu Kubernetes Grid on AWS to a private registry in a physically air-gapped, offline environment. <!-- /* cSpell:disable */ --> This procedure uses the scripts download-images.sh, gen-publish-images-totar.sh, and gen-publish-images-fromtar.sh to:<!-- /* cSpell:enable */ -->



* Copy the images from the Tanzu Kubernetes Grid public registry and save them locally in tar format in offline jumpbox.
* Extract the images from tar files and copy them to a private registry.

Please follow [Copy the container images required to deploy Tanzu Kubernetes Grid](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.5/vmware-tanzu-kubernetes-grid-15/GUID-mgmt-clusters-image-copy-airgapped.html) instructions for further details.

## <a id=prepEnv> </a> Prepare an Internet-Restricted Environment

Before you can deploy management clusters and Tanzu Kubernetes clusters in an Internet-restricted environment, you should prepare an internet restricted environment. Please follow [Prepare an Internet-Restricted Environment](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.5/vmware-tanzu-kubernetes-grid-15/GUID-mgmt-clusters-airgapped-environments.html) instructions.




## <a id=install-tkg></a> Deploy a Tanzu Kubernetes Grid Management Cluster

Create and edit YAML configuration files, and use the configuration files to deploy a management cluster with the CLI commands. 

This section describes how to deploy a Tanzu Kubernetes Grid management cluster from a configuration file using the Tanzu CLI. 

Before creating a management cluster using the Tanzu CLI, define the base configuration for the cluster in a YAML file. You specify this file by using the `--file` option of the `tanzu management-cluster create` command.

**Note** - Set AWS_LOAD_BALANCER_SCHEME_INTERNAL to true in the cluster configuration file `AWS_LOAD_BALANCER_SCHEME_INTERNAL: true`
This setting customizes the management cluster’s load balancer to use an internal scheme, which means that its Kubernetes API server will not be accessible and routed over the Internet.


To create a new Tanzu Kubernetes Grid management cluster, run the following command:

<!-- /* cSpell:disable */ -->
```bash
tanzu management-cluster create --file path/to/cluster-config-file.yaml
```
<!-- /* cSpell:enable */ -->


For more information about deploying a management cluster from a configuration file, see [Deploy Management Clusters from a Configuration File](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.5/vmware-tanzu-kubernetes-grid-15/GUID-mgmt-clusters-deploy-cli.html).  

## <a id=examine-cluster></a> Examine the Management Cluster Deployment

During the deployment of the management cluster, either from the installer interface or from a configuration file using Tanzu CLI, Tanzu Kubernetes Grid creates a temporary management cluster using a Kubernetes in Docker, `kind`, cluster on the jumpbox.

Tanzu Kubernetes Grid uses the temporary management cluster to provision the final management cluster on AWS. For information about how to examine and verify your Tanzu Kubernetes Grid management cluster deployment, see [Examine the Management Cluster Deployment](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.5/vmware-tanzu-kubernetes-grid-15/GUID-mgmt-clusters-verify-deployment.html).

## <a id=deploy-workload-cluster></a> Deploy Workload Clusters

After deploying the management cluster, you can create the workload clusters. The management cluster's context is updated automatically, so you can begin interacting with the management cluster.

Run the following command to create a basic workload cluster:

<!-- /* cSpell:disable */ -->
```bash

tanzu cluster create <cluster_name> --plan=prod
```
<!-- /* cSpell:enable */ -->

Workload clusters can be highly customized through YAML manifests and applied to the management cluster for deployment and lifecycle management. To generate a YAML template to update and modify to your own needs use the `--dry-run` switch. Edit the manifests to meet your requirements and apply them to the cluster.

Example:

<!-- /* cSpell:disable */ -->
```
tanzu cluster create <workload_cluster> --plan=prod --worker-machine-count 3 --dry-run
```
<!-- /* cSpell:enable */ -->

After the workload cluster is created, the current context changes to the new workload cluster.

For more information on cluster lifecycle and management, see [Manage Clusters](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.5/vmware-tanzu-kubernetes-grid-15/GUID-cluster-lifecycle-index.html).



### Troubleshooting Tips for Tanzu Kubernetes Grid

For tips to help you to troubleshoot common problems that you might encounter when installing Tanzu Kubernetes Grid and deploying Tanzu Kubernetes clusters, see [Troubleshooting Tips for Tanzu Kubernetes Grid](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.5/vmware-tanzu-kubernetes-grid-15/GUID-troubleshooting-tkg-tips.html).

## <a id=install-packages></a> Install and Configure Packages into Workload Clusters

A package in Tanzu Kubernetes Grid is a collection of related software that supports or extends the core functionality of the Kubernetes cluster in which the package is installed. Tanzu Kubernetes Grid includes two types of packages, core packages and user-managed packages. For more information about packages in Tanzu Kubernetes Grid, see [Install and Configure Packages](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.5/vmware-tanzu-kubernetes-grid-15/GUID-packages-index.html).

### Core Packages

Tanzu Kubernetes Grid automatically installs the core packages during cluster creation. For more information about core packages, see [Core Packages](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.5/vmware-tanzu-kubernetes-grid-15/GUID-packages-core-index.html).

### User-Managed Packages

A user-managed package is an optional component of a Kubernetes cluster that you can install and manage with the Tanzu CLI. These packages are installed after cluster creation. User-managed packages are grouped into package repositories in the Tanzu CLI. If a package repository that contains user-managed packages is available in the target cluster, you can use the Tanzu CLI to install and manage any of the packages from that repository.   

Using the Tanzu CLI, you can install user-managed packages from the built-in `tanzu-standard` package repository or from package repositories that you add to your target cluster. From the `tanzu-standard` package repository, you can install the Cert Manager, Contour, Fluent Bit, Grafana, Harbor, and Prometheus packages. For more information about user-managed packages, see [User-Managed Packages](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.5/vmware-tanzu-kubernetes-grid-15/GUID-packages-cli-reference-packages.html).

VMware recommends installing the following packages:

* [Installing Cert Manager](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.5/vmware-tanzu-kubernetes-grid-15/GUID-packages-cert-manager.html)

* [Implementing Ingress Control with Contour](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.5/vmware-tanzu-kubernetes-grid-15/GUID-packages-ingress-contour.html)
For private load balancer, you can specifically request one by setting `service.beta.kubernetes.io/aws-load-balancer-internal: "true"` in the annotations of the service. This setting also applies to the Contour ingress and controls.
Example : 
```
annotations:
   service.beta.kubernetes.io/aws-load-balancer-internal: "true"
   ```

* [Implementing Log Forwarding with Fluent Bit](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.5/vmware-tanzu-kubernetes-grid-15/GUID-packages-logging-fluentbit.html)

* [Implementing Monitoring with Prometheus and Grafana](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.5/vmware-tanzu-kubernetes-grid-15/GUID-packages-monitoring.html)

* [Implementing Multiple Pod Network Interfaces with Multus](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.5/vmware-tanzu-kubernetes-grid-15/GUID-packages-cni-multus.html)


## <a id=logs></a> Logs and Troubleshooting
For information about how to find the Tanzu Kubernetes Grid logs, how to troubleshoot frequently encountered Tanzu Kubernetes Grid issues, and how to use the Crash Recovery and Diagnostics tool, see [Logs and Troubleshooting](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.5/vmware-tanzu-kubernetes-grid-15/GUID-troubleshooting-tkg-index.html).

## <a id=cluster-mgmt> </a> Delete Clusters
The procedures in this section are optional. They are provided in case you want to clean up your production or lab environment.

### Delete a Workload Cluster

To delete a provisioned workload first set your context back to the management cluster.

<!-- /* cSpell:disable */ -->
```bash
kubectl config use-context [mgmt_cluster_name]-admin@[mgmt_cluster_name]

```
<!-- /* cSpell:enable */ -->

From the management cluster context run:

<!-- /* cSpell:disable */ -->
```bash
tanzu cluster delete <cluster_name>
```
<!-- /* cSpell:enable */ -->

### Delete a Management Cluster

Use this procedure to delete the management cluster as well as all of the AWS objects Tanzu Kubernetes Grid created such as VPC, subnets and NAT Gateways.

**Note**: Be sure to wait until all the workload clusters have been reconciled before deleting the management cluster or infrastructure will need to be manually cleaned up.

Running the following command will delete the objects.

<!-- /* cSpell:disable */ -->
```bash
tanzu cluster delete <management-cluster-name>
```


## <a id=stig-fips> </a>Air-gapped STIG/FIPS deployment on AWS
For how to deploy STIG-hardened management/FIPS cluster to an air-gapped AWS environment, see [Deploy a STIG-Hardened Management Cluster to an Air-gapped AWS VPC](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.4/vmware-tanzu-kubernetes-grid-14/GUID-security-airgap-stig-aws.html)

<!-- /* cSpell:enable */ -->

## <a id=upgrade-tkg> Tanzu Kubernetes Grid Upgrade
To upgrade the previous version of Tanzu Kubernetes Grid into your environment you can refer [Tanzu Kubernetes Grid Upgrade](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.5/vmware-tanzu-kubernetes-grid-15/GUID-upgrade-tkg-index.html) instructions.
 
