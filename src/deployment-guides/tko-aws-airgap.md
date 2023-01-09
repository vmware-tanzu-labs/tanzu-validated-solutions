# Deploy Tanzu Kubernetes Grid on AWS in an Air-Gapped Environment

This document outlines the steps for deploying VMware Tanzu for Kubernetes Operations on AWS in an air-gapped (Internet-restricted) environment. The deployment is based on the reference design provided in [VMware Tanzu Kubernetes Grid on AWS Airgap Reference Design](../reference-designs/tko-on-aws-airgap.md).

## Deploying with VMware Service Installer for Tanzu

You can use VMware Service Installer for VMware Tanzu to automate this deployment. 

VMware Service Installer for Tanzu automates the deployment of the reference designs for Tanzu for Kubernetes Operations. It uses best practices for deploying and configuring the required Tanzu for Kubernetes Operations components.

To use Service Installer to automate this deployment, see [Deploying Tanzu Kubernetes Grid on Federal Air-gapped AWS VPC Using Service Installer for VMware Tanzu](https://docs.vmware.com/en/Service-Installer-for-VMware-Tanzu/1.4/service-installer/GUID-AWS%20-%20Federal%20Airgap-AWSFederalAirgap-DeploymentGuide.html).

Alternatively, if you decide to manually deploy each component, follow the steps provided in this document.

## Prerequisites

Before deploying VMware Tanzu for Kubernetes Operations in an AWS air-gapped environment, ensure that the following are set up.

* **AWS Account**: An IAM user account with **administrative privileges**.
* **AWS Resource Quotas**: Sufficient quotas to support both the management cluster and the workload clusters in your deployment. Otherwise, the cluster deployments will fail. Depending on the number of workload clusters you plan to deploy, you may need to increase the AWS services quotas from their default values. You will need to increase the quota in every region in which you deploy Tanzu Kubernetes Grid.
  For more information, follow these links:

  * [Tanzu Kubernetes Grid resources in AWS account](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.6/vmware-tanzu-kubernetes-grid-16/GUID-mgmt-clusters-aws.html#aws-resources).
  * [AWS service quotas](https://docs.aws.amazon.com/general/latest/gr/aws_service_limits.html) in the AWS.
* **An Internet-connected Linux bootstrap machine**
  The bootstrap machine can be a local device such as a laptop or a virtual machine running in, for example, VMware Workstation or Fusion. You will use the bootstrap machine to create the AWS VPC and jumpbox. The bootstrap machine:

  * Is not inside the Internet-restricted environment or is able to access the domains listed in Proxy Server Allowlist.
  * Has the Docker client app installed.
  * Has [imgpkg](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.6/vmware-tanzu-kubernetes-grid-16/GUID-install-cli.html) installed.
  * Has the latest version of yq installed.
  * Has the latest version of jq installed.
  * Has AWS CLI installed.
  * Has the [Carvel Tools](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.6/vmware-tanzu-kubernetes-grid-16/GUID-install-cli.html) installed, if you intend to install one or more of the optional packages provided by Tanzu Kubernetes Grid, such as Harbor.
* **VMware Cloud**: Access to [VMware Cloud](https://customerconnect.vmware.com/login ) to download Tanzu CLI.

For additional information about preparing to deploy Tanzu Kubernetes Grid on AWS, see [Prepare to Deploy Management Clusters to Amazon EC2](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.6/vmware-tanzu-kubernetes-grid-16/GUID-mgmt-clusters-aws.html).

## Overview of the Deployment Steps

The main steps to deploy Tanzu for Kubernetes Operations on AWS EC2 are as follows. Each step links to more detailed instructions.

1. [Set Up AWS Infrastructure](#aws-infra).
2. [Create an Offline JumpBox](#offline-jumpbox).
3. [Create and Set Up a Private Container Registry](#private-repo).
4. [Copy the Container Images Required to Deploy Tanzu Kubernetes Grid](#copy-tkg-img).
5. [Tanzu Kubernetes Grid Build Machine Image](#tkg-build-machine-img).
6. [Prepare an Internet-Restricted Environment](#prepEnv).
7. [Install Tanzu Kubernetes Grid Management Cluster](#install-tkg).
8. [Examine the Management Cluster Deployment](#examine-cluster).
9. [Deploy Workload Clusters](#deploy-workload-cluster).
10. [Install and Configure Packages into Workload Clusters](#install-packages).
11. [Logs and Troubleshooting](#logs).
12. [Delete Clusters](#cluster-mgmt).
13. [Air-Gapped STIG/FIPS Deployment on AWS](#stig-fips).
14. [Tanzu Kubernetes Grid Upgrade](#upgrade-tkg).

## <a id=aws-infra> </a> Set Up AWS Infrastructure

The following describes the steps to create your AWS environment and configure your network. Follow the steps in the order provided.

### Create an Internet-Restricted Virtual Private Cloud (VPC)

Follow these steps to create an Internet-restricted (offline) AWS VPC or see [Work with VPCs](https://docs.aws.amazon.com/vpc/latest/userguide/working-with-vpcs.html) in AWS documentation. The offline VPC must not have a NAT or Internet gateway. Create your offline VPC with private subnets only.

1. Create a VPC.
   1. Log in to your AWS Console and select VPC service.
   2. Create your VPC with Valid CIDR and name.
2. Create 3 Private Subnets.
   Click **Subnet** and create your subnet with:
   1. Private Subnet 1, Private Subnet 2 and Private Subnet 3 valid Name & VPC.
   2. Valid Subnet range which is valid IPv4 CIDR Block.
3. Create Private Route Table.
   1. Create a Route table in the same VPC.
   2. Make sure you selected the right VPC and gave a proper tag.
4. Add Private Subnet in Private Route Table.
   1. Edit the Subnet Association.
   2. Select the PrivateSubnet checkbox.
   3. Click **Save**.
5. Edit DNS Resolution and Hostname.
   1. Click **Action** and Edit DNS hostname.
   2. Select DNS Hostname and click **Save**.
   3. Refer to [AWS Documentation](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-dns.html#vpc-dns-updating) for more information.

**Note:** If you create multiple offline VPCs, also see [Getting started with transit gateways](https://docs.aws.amazon.com/vpc/latest/tgw/tgw-getting-started.html) in AWS documentation to create an AWS transit gateway.

6. Create a [VPC peering](https://docs.aws.amazon.com/vpc/latest/peering/create-vpc-peering-connection.html) connection between offline and Internet-connected VPC. If you have created the transit gateway, you can skip this step.

### Add VPC Endpoints into Offline VPC

After you create the offline VPC, you must add the following endpoints to the offline VPC. VPC endpoints enable private connections between your VPC and supported AWS services.

**Service endpoints:**

* sts
* ssm
* ec2
* ec2messages
* elasticloadbalancing
* secretsmanager
* ssmmessages
* s3 (gateway type)

For more information about creating an endpoint service, see [Create a service powered by AWS PrivateLink](https://docs.aws.amazon.com/vpc/latest/privatelink/create-endpoint-service.html) in AWS documentation.

## <a id=offline-jumpbox> </a> Create an Offline JumpBox

After configuring the network, complete the steps described in this section to set up your jumpbox. You will download the Tanzu CLI to the jumpbox, which you will use to deploy the management cluster and workload clusters. You also keep the Tanzu and Kubernetes configuration files for your deployments on your jumpbox.

1. Create a jumpbox.

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

   # Set offline VPC and private subnet ID
   export vpcId=<offline vpc id>
   export prisubnetId=<private subnet id>
   export WORKING_DIR=<local working dir>

   aws ec2 create-security-group --group-name "jumpbox-ssh" --description "To Jumpbox" --vpc-id "$vpcId" --output json > $WORKING_DIR/sg_jumpbox_ssh
   aws ec2 create-tags --resources $(jq -r .GroupId $WORKING_DIR/sg_jumpbox_ssh) --tags Key=Name,Value="jumpbox-ssh"

   # Allow SSH access to jumpbox
   aws ec2 authorize-security-group-ingress --group-id  $(jq -r .GroupId $WORKING_DIR/sg_jumpbox_ssh) --protocol tcp --port 22 --cidr "0.0.0.0/0"

   # Save this file (or use an existing team keypair)
   aws ec2 create-key-pair --key-name tkg-kp --query 'KeyMaterial' --output text > tkgkp.pem
   chmod 400 tkgkp.pem

   # Find an Amazon Machine Image (AMI) for your region https://cloud-images.ubuntu.com/locator/ec2/ (20.04)<_Correct?_>
   aws ec2 run-instances --image-id ami-036d46416a34a611c --count 1 --instance-type t2.xlarge --key-name tkg-kp --security-group-ids  $(jq -r .GroupId $WORKING_DIR/sg_jumpbox_ssh)   --subnet-id $prisubnetId  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=tkg-jumpbox}]' --block-device-mappings 'DeviceName=/dev/sda1,Ebs={VolumeSize=64}' > $WORKING_DIR/instance_jb_starting
   ```

2. Wait a few minutes for the instance to start. Then SSH to the jumpbox.

   ```bash
   aws ec2 describe-instances --instance-id $(jq -r '.Instances[0].InstanceId' $WORKING_DIR/instance_jb_starting) > $WORKING_DIR/instance_jb_started

   echo j IP: $(jq -r '.Reservations[0].Instances[0].PrivateIpAddress' $WORKING_DIR/instance_jb_started)

   ssh ubuntu@$(jq -r '.Reservations[0].Instances[0].PrivateIpAddress' $WORKING_DIR/instance_jb_started) -i tkgkp.pem
   ```

3. Log in to the jumpbox to install the necessary packages and configurations.

   1. Download [Docker Ubuntu binaries](https://download.docker.com/linux/ubuntu/dists/focal/pool/stable/amd64/) and transfer to the jumpbox.

      ```bash
      #transfer docker package file 
      scp -i tkgkp.pem docker-ce-cli_20.10.9_3-0_ubuntu-focal_amd64.deb ubuntu@$(jq -r '.Reservations[0].Instances[0].PrivateIpAddress' $WORKING_DIR/instance_jb_started):/home/ubuntu
      ```

   2. Add `ubuntu` user to Docker and reboot the jumpbox.

      ```bash
      #login to jumpbox
      ssh ubuntu@<jumpbox-ip> -i tkgkp.pem
      #install docker
      dpkg --install <docker-ce-cli_20.10.9_3-0_ubuntu-focal_amd64.deb
      #add ubuntu user to docker
      sudo adduser ubuntu docker
      #reboot
      sudo reboot
      ```

4. Download the Tanzu CLI and other Linux utilities from the Tanzu Kubernetes Grid [Download Product](https://customerconnect.vmware.com/downloads/details?downloadGroup=TKG-142&productId=988&rPId=73652) site.
5. Copy the files and binaries to the jumpbox.

   ```bash
   scp -i tkgkp.pem tanzu-cli-bundle-linux-amd64.tar kubectl-linux-v1.23.8+vmware.gz ubuntu@$(jq -r '.Reservations[0].Instances[0].PublicIpAddress' $WORKING_DIR/instance_jb_started):/home/ubuntu
   ```

6. Connect to the jumpbox.

   ```bash
   ssh ubuntu@<jumpbox-ip> -i tkgkp.pem
   ```

7. Install the Tanzu CLI.

   Run the session in `screen` in case your SSH connection is terminated.
   If your connection is terminated, you can reattach to the screen session
   with `screen -r` once you have reconnected.

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

   Running the `tanzu config init` command for the first time creates the `~/.config/tanzu/tkg` subdirectory, which contains the Tanzu Kubernetes Grid configuration files.

## <a id=private-repo> </a> Create and Set Up a Private Container Registry

This registry should run outside of Tanzu Kubernetes Grid and is separate from any registry deployed as a shared service for clusters.

* You can configure the container registry with SSL certificates signed by a trusted CA, or with self-signed certificates.
* The registry must not implement user authentication. For example, if you use a Harbor registry, the project must be public, not private.
* You can set up this private registry on an offline jumpbox machine (should be large enough to set up a private registry) or set it up on another ec2 instance inside an offline VPC.

### Install Harbor

* Download the [binaries for the latest Harbor release](https://github.com/goharbor/harbor/releases).
* Follow the Harbor [Installation and Configuration](https://goharbor.io/docs/2.0.0/install-config/) instructions in the Harbor documentation.

## <a id=copy-tkg-img> </a> Copy the Container Images Required to Deploy Tanzu Kubernetes Grid

Copy the container images required to deploy Tanzu Kubernetes Grid on AWS to a private registry in a physically air-gapped, offline environment.  This procedure uses the scripts `download-images.sh`, `gen-publish-images-totar.sh`, and `gen-publish-images-fromtar.sh` to:

* Copy the images from the Tanzu Kubernetes Grid public registry and save them locally in tar format on an offline jumpbox.
* Extract the images from the tar files and copy them to a private registry.

See [Copy the container images required to deploy Tanzu Kubernetes Grid](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.6/vmware-tanzu-kubernetes-grid-16/GUID-mgmt-clusters-image-copy-airgapped.html) for more detailed instructions.

### <a id=tkg-build-machine-img> </a> Tanzu Kubernetes Grid Build Machine Image

If you have a requirement to build custom images, follow the steps in [Tanzu Kubernetes Grid Build Machine Images](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.6/vmware-tanzu-kubernetes-grid-16/GUID-build-images-index.html).

VMware support FIPS-capable version of Tanzu Kubernetes Grid. Refer to [Tanzu Kubernetes Grid FIPS-Capable Version](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.6/vmware-tanzu-kubernetes-grid-16/GUID-mgmt-clusters-prepare-deployment.html#fips) for more information.

For compliance and security requirements VMware has published security overview whitepaper. Refer to [Tanzu Kubernetes Grid security overview whitepaper](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.6/vmware-tanzu-kubernetes-grid-16/GUID-security-overview.html) for more information.

## <a id=prepEnv> </a> Prepare an Internet-Restricted Environment

Before you can deploy management clusters and Tanzu Kubernetes clusters in an Internet-restricted environment, you need to prepare the environment. 

Set the IP address or FQDN of your local private registry as an environment variable:

`export TKG_CUSTOM_IMAGE_REPOSITORY="PRIVATE-REGISTRY"` Where PRIVATE-REGISTRY is the IP address or FQDN of your private registry and the name of the project. For example, `custom-image-repository.io/yourproject`.

Follow the instructions in [Prepare an Internet-Restricted Environment](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.6/vmware-tanzu-kubernetes-grid-16/GUID-mgmt-clusters-airgapped-environments.html).

## <a id=install-tkg></a> Deploy a Tanzu Kubernetes Grid Management Cluster

Create and edit a YAML configuration file. Then use the configuration file with CLI commands to deploy a management cluster.

This section describes how to deploy a Tanzu Kubernetes Grid management cluster from a configuration file using the Tanzu CLI.

Before creating a management cluster using the Tanzu CLI, define the base configuration for the cluster in a YAML file. Specify this file by using the `tanzu management-cluster create` command with the `--file` option.

**Note** In the configuration file for the management cluster, enable the AWS internal load balancer as follows:

`AWS_LOAD_BALANCER_SCHEME_INTERNAL: "true"`
Using an internal load balancer scheme prevents the Kubernetes API server for the cluster from being accessed and routed over the Internet.

To create a new Tanzu Kubernetes Grid management cluster, run the following command:

```bash
tanzu management-cluster create --file path/to/cluster-config-file.yaml
```

For more information about deploying a management cluster from a configuration file, see [Deploy Management Clusters from a Configuration File](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.6/vmware-tanzu-kubernetes-grid-16/GUID-mgmt-clusters-deploy-cli.html).

## <a id=examine-cluster></a> Examine the Management Cluster Deployment

When the management cluster is deployed, either from the installer interface or from a configuration file using Tanzu CLI, Tanzu Kubernetes Grid uses a Kubernetes in Docker kind cluster on the jumpbox to create a temporary management cluster. kind is a tool for running Kubernetes clusters locally using Docker containers as Kubernetes nodes.

Tanzu Kubernetes Grid uses the temporary management cluster to provision the final management cluster on AWS. For information about how to examine and verify your Tanzu Kubernetes Grid management cluster deployment, see [Examine the Management Cluster Deployment](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.6/vmware-tanzu-kubernetes-grid-16/GUID-mgmt-clusters-verify-deployment.html).

## <a id=deploy-workload-cluster></a> Deploy Workload Clusters

After deploying the management cluster, you can create the workload clusters. The context of the management cluster is updated automatically, so you can begin interacting with the management cluster.

Run the following command to create a basic workload cluster:

```bash
tanzu cluster create <cluster_name> --plan=prod
```

Workload clusters can be highly customized through YAML manifests and applied to the management cluster for deployment and lifecycle management. To generate a YAML template to update and modify to your own needs, use the `--dry-run` switch. Edit the manifests to meet your requirements and apply them to the cluster.

**Example:**

```
tanzu cluster create <workload_cluster> --plan=prod --worker-machine-count 3 --dry-run
```

After the workload cluster is created, the current context changes to the new workload cluster.

For more information on cluster lifecycle and management, see [Manage Clusters](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.6/vmware-tanzu-kubernetes-grid-16/GUID-cluster-lifecycle-index.html).

### Troubleshooting Tips for Tanzu Kubernetes Grid

For tips to help you to troubleshoot common problems that you might encounter when installing Tanzu Kubernetes Grid and deploying Tanzu Kubernetes clusters, see [Troubleshooting Tips for Tanzu Kubernetes Grid](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.6/vmware-tanzu-kubernetes-grid-16/GUID-troubleshooting-tkg-tips.html).

## <a id=install-packages></a> Install and Configure Packages into Workload Clusters

A package in Tanzu Kubernetes Grid is a collection of related software that supports or extends the core functionality of the Kubernetes cluster in which the package is installed. Tanzu Kubernetes Grid includes two types of packages, auto-managed packages and CLI-managed packages. For more information about packages in Tanzu Kubernetes Grid, see [Install and Configure Packages](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.6/vmware-tanzu-kubernetes-grid-16/GUID-packages-index.html).

### Auto-Managed Packages

Tanzu Kubernetes Grid automatically installs the auto-managed packages during cluster creation. For more information about auto-managed packages, see [Auto-Managed Packages](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.6/vmware-tanzu-kubernetes-grid-16/GUID-packages-index.html#auto).

### CLI-Managed Packages

A CLI-managed packages package is an optional component of a Kubernetes cluster that you can install and manage with the Tanzu CLI. These packages are installed after cluster creation. CLI-managed packages are grouped into package repositories in the Tanzu CLI. If a package repository that contains CLI-managed packages is available in the target cluster, you can use the Tanzu CLI to install and manage any of the packages from that repository.

Using the Tanzu CLI, you can install cli-managed packages from the built-in `tanzu-standard` package repository or from package repositories that you add to your target cluster. From the `tanzu-standard` package repository, you can install the Cert Manager, Contour, Fluent Bit, Grafana, Harbor, and Prometheus packages. See [CLI-Managed Packages](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.6/vmware-tanzu-kubernetes-grid-16/GUID-packages-user-managed-index.html) for more information.

**Recommended packages:**

* **Cert Manager** for automating the management and issuance of TLS certificates. See [Installing Cert Manager](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.6/vmware-tanzu-kubernetes-grid-16/GUID-packages-cert-manager.html).
* **Contour** for ingress control. See [Implementing Ingress Control with Contour](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.6/vmware-tanzu-kubernetes-grid-16/GUID-packages-ingress-contour.html).
  For use a private load balancer, set `service.beta.kubernetes.io/aws-load-balancer-internal: "true"` in the annotations for the service. This setting also applies to the Contour ingress and controls.
* **Fluent Bit** for log processing and forwarding. See [Implementing Log Forwarding with Fluent Bit](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.6/vmware-tanzu-kubernetes-grid-16/GUID-packages-logging-fluentbit.html)
* **Prometheus** and **Grafana** for monitoring. See [Implementing Monitoring with Prometheus and Grafana](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.6/vmware-tanzu-kubernetes-grid-16/GUID-packages-monitoring.html)
* **Multus** for multi networking. [Implementing Multiple Pod Network Interfaces with Multus](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.6/vmware-tanzu-kubernetes-grid-16/GUID-packages-cni-multus.html)

## <a id=logs></a> Logs and Troubleshooting

For information about how to find the Tanzu Kubernetes Grid logs, how to troubleshoot frequently encountered Tanzu Kubernetes Grid issues, and how to use the Crash Recovery and Diagnostics tool, see [Logs and Troubleshooting](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.6/vmware-tanzu-kubernetes-grid-16/GUID-troubleshooting-tkg-index.html).

## <a id=cluster-mgmt> </a> Delete Clusters

The procedures in this section are optional. They are provided in case you want to clean up your production or lab environment.

### Delete a Workload Cluster

To delete a provisioned workload cluster, first set your context back to the management cluster.

```bash
kubectl config use-context [mgmt_cluster_name]-admin@[mgmt_cluster_name]
```

From the management cluster context, run:

```bash
tanzu cluster delete <cluster_name>
```

### Delete a Management Cluster

Use this procedure to delete the management cluster as well as all of the AWS objects that Tanzu Kubernetes Grid created, such as VPC, subnets, and NAT Gateways.

**Note**: Be sure to wait until all the workload clusters have been reconciled before deleting the management cluster, or you will need to manually clean up the infrastructure.

Run the following command to delete the management cluster and related objects:

```bash
tanzu cluster delete <management-cluster-name>
```

## <a id="stig-fips"> </a>Air-Gapped STIG/FIPS Deployment on AWS

For how to deploy a STIG-hardened management/FIPS cluster to an air-gapped AWS environment, see [Deploy a STIG-Hardened Management Cluster to an Air-gapped AWS VPC](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.4/vmware-tanzu-kubernetes-grid-14/GUID-security-airgap-stig-aws.html).

## <a id=upgrade-tkg> </a>Tanzu Kubernetes Grid Upgrade

For information about how to upgrade to Tanzu Kubernetes Grid 1.6, see [Tanzu Kubernetes Grid Upgrade](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.6/vmware-tanzu-kubernetes-grid-16/GUID-upgrade-tkg-index.html).
 
