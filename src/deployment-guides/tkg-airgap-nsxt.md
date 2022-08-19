**Overview**

VMware Tanzu Kubernetes Grid (multi-cloud) provides organizations with a consistent, upstream-compatible, regional Kubernetes substrate that is ready for end-user workloads and ecosystem integrations. It delivers an open source aligned Kubernetes distribution with consistent operations and management to support infrastructure and app modernization.

An airgap installation method is used when the TKG components (bootstrapper and cluster nodes) are unable to connect to the internet to download the installation binaries from the public [VMware Registry](https://projects.registry.vmware.com/) during TKG install, or upgrades. 

The scope of the document is limited to providing deployment steps based on the reference design in [Tanzu Kubernetes Grid on NSX-T Networking](../reference-designs/tkg-nsxt-airgap-ra.md) and does not cover any deployment procedures for the underlying SDDC components.

## Supported Component Matrix

The following table provides the component versions and interoperability matrix supported with the reference design:

|**Software Components**|**Version**|
| :- | :- |
|Tanzu Kubernetes Grid|1.5.4|
|VMware vSphere ESXi|7.0 U2 and later|
|VMware vCenter Server|7.0 U2 and later|
|NSX Advanced Load Balancer|21.1.3|

The Interoperability Matrix can be verified at all times [here](https://interopmatrix.vmware.com/Interoperability?col=551,7906&row=789,%262,).

# Prepare the Environment for Deployment of the Tanzu Kubernetes Grid

Before deploying the Tanzu Kubernetes Grid in the vSphere environment, ensure that your environment is set up as described in the section below:

- [General Requirements](#general-requirements)
- [Network Requirements](#network-requirements)
- [Firewall Requirements](#firewall-requirements)

## <a id=general-requirements> </a>  General Requirements
- vSphere 7.0 U2 or greater instance with an Enterprise Plus license.
- A vCenter with NSX-T backed environment.
- Ensure that the following NSX-T configurations are in place:
  - NSX-T manager instance is deployed and configured with an Advanced or higher license.
  - vCenter Server that is associated with the NSX-T Data Center is configured as Compute Manager.
  - Required overlay and VLAN Transport Zones are created.
  - IP pools for host and edge tunnel endpoints (TEP) are created.
  - Host and edge uplink profiles are in place.
  - Transport node profiles are created. This is not required if configuring NSX-T datacenter on each host instead of the cluster.
  - NSX-T datacenter configured on all hosts part of the vSphere cluster or clusters.
  - Edge transport nodes and at least one edge cluster is created
  - Tier-0 uplink segments and tier-0 gateway is created.
  - Tier-0 router has peered with uplink L3 switch.
- Your SDDC environment has the following objects in place: 
  - A vSphere cluster with at least 3 hosts, on which vSphere DRS is enabled and NSX-T is successfully configured. If you are using vSAN for shared storage, it is recommended that you use 4 ESXi hosts.
  - Dedicated resource pool in which to deploy the Tanzu Kubernetes Grid Instance.
  - VM folders in which to collect the Tanzu Kubernetes Grid VMs. 
  - A shared datastore with sufficient capacity for the control plane and worker node VMs. 
  - Network Time Protocol (NTP) service is running on all ESXi hosts and vCenter and time is synchronized from the centralized NTP servers.
  - A host/server/VM based on Linux acts as your **Bastion host** and is **outside the internet-restricted environment (i.e. connected to the internet)**. The installation binaries for TKG and NSX Advanced Load Balancer will be downloaded on this machine. You will need to transfer files from this Bastion host to your internet restricted environment (proxy connection, shared drive, USB drive, sneakernet, etc.)
  - A host/server/VM **inside your internet-restricted environment** based on Linux/Windows which acts as your bootstrap machine and has Tanzu CLI, Kubectl and docker installed. An internal harbor registry will be installed on the same machine. This document makes use of a virtual machine based on CentOS.
- vSphere account with permissions as described in [Required Permissions for the vSphere Account](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.5/vmware-tanzu-kubernetes-grid-15/GUID-mgmt-clusters-vsphere.html#required-permissions-for-the-vsphere-account-5)

**Note:** You can also download and import supported older versions of Kubernetes in order to deploy workload clusters on the intended Kubernetes versions

## Resource Pools and VM Folders

Below are the sample entries of the resource pools and folders that need to be created.

|**Resource Type**|**Resource Pool**|**Sample Folder**|
| :- | :- | :- |
|NSX ALB Components|NSX-ALB|NSX-ALB-VMs|
|TKG Management components|TKG-Mgmt|TKG-Mgmt-VMs|
|TKG Shared Service Components|TKG-SS|TKG-SS-VMs|
|TKG Workload components|TKG-Workload|TKG-Workload-VMs|

## Network Requirements

Create logical segments in NSX-T for deploying TKG components as per [Network Requirements](../reference-designs/tkg-nsxt-airgap-ra.md/#network-requirements) defined in the reference architecture. 

## Firewall Requirements

Ensure that the firewall is set up as described in [Firewall Requirements](../reference-designs/tkg-nsxt-airgap-ra.md/#a-idfirewall-requirements-a-firewall-requirements). 

## Subnet and CIDR Examples

For the purpose of this demonstration, this document makes use of the following CIDR for TKG deployment. Please change the values to reflect your environment.


|**Network Type**|**Port Group Name**|**Gateway CIDR**|**DHCP Pool**|**NSX ALB IP Pool**|
| :- | :- | :- | :- | :- |
|NSX ALB Mgmt Network|alb-mgmt-ls|172.19.71.1/27|N/A|172.19.71.6 - 172.19.71.30|
|TKG Management Network|tkg-mgmt-ls|172.19.72.1/27|172.19.72.10 - 172.19.72.30|N/A|
|TKG Shared Service Network|tkg-ss-ls|172.19.73.1/27|172.19.73.2 - 172.19.73.30|N/A|
|TKG Mgmt VIP Network|tkg-mgmt-vip-ls|172.19.74.1/26|N/A|172.19.74.2 - 172.19.74.62|
|TKG Cluster VIP Network|tkg-cluster-vip-ls|172.19.75.1/26|N/A|172.19.75.2 - 172.19.75.62|
|TKG Workload VIP Network|tkg-workload-vip-ls|172.19.76.1/26|N/A|172.19.76.2 - 172.19.76.62|
|TKG Workload Network|tkg-workload-ls|172.19.77.1/24|172.19.77.2 - 172.19.77.251|N/A|

**Tanzu Kubernetes Grid Deployment Workflow**

Here are the high-level steps for deploying Tanzu Kubernetes Grid on NSX-T networking in an airgap environment:

- [Configure Bastion Host](#configure-bastion)
- [Install Harbor Image Registry](#install-harbor)
- [Configure Bootstrap Virtual machine](#configure-bootstrap)
- [Deploy and Configure NSX Advanced Load Balancer](#configure-alb)
- [Deploy TKGm Management Cluster](#deploy-tkg-management)
- [Deploy TKGm Shared Service Cluster](#deploy-tkg-shared-services)
- [Deploy TKGm Workload Cluster](#deploy-workload-cluster)
- [Deploy User-Managed packages on TKG clusters](#deploy-packages)

# <a id=configure-bastion> </a> Deploy and Configure Bastion Host
Bastion host is the physical/virtual machine where you will download the required installation images/binaries (for TKG installation) from the internet. The downloaded items then need to be shipped to the bootstrap machine which is inside the airgap environment. The bastion host needs to have a browser installed to download the binaries from the internet. You need to download the following items from the internet. 

The bastion host needs to be deployed with the following hardware configuration:

- CPU: 1
- Memory: 4 GB
- Storage (HDD): 200 GB or greater.

**Note:** The instructions provided below are for Centos 7. If you are using any other operating system for your bastion host, change the commands accordingly.

1. Download Docker Engine and associated dependencies binaries using the steps provided below

```bash
### Create a directory for collecting docker installation binaries

mkdir docker-binaries && cd docker-binaries

### Add docker repository to the yum command

yum install yum-utils -y

yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

### Download docker and associated dependencies 

yumdownloader --resolve docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

The yumdownloader command downloads the following binaries. 

![](img/tkg-airgap-nsxt/docker-installation-binaries.jpg)

2. Download Harbor installation binaries from [here](https://github.com/goharbor/harbor/releases/tag/v2.3.3). 4

3. Download NSX Advanced Load Balancer ova from [here](https://customerconnect.vmware.com/downloads/info/slug/networking_security/vmware_nsx_advanced_load_balancer/21_1_x).

4. Download **Tanzu CLI, Kubectl, and the Kubernetes ova** images from [here](https://customerconnect.vmware.com/downloads/details?downloadGroup=TKG-154&productId=988&rPId=90871). Tanzu CLI and Plugins need to be installed on the bastion host and the bootstrap machine.

5. Download the [yq](https://github.com/mikefarah/yq) installation binary from [here](https://github.com/mikefarah/yq/releases/tag/v4.25.2).

6. Download the [gen-publish-images](https://raw.githubusercontent.com/vmware-tanzu/tanzu-framework/e3de5b1557d9879dc814d771f431ce8945681c48/hack/gen-publish-images-totar.sh) script for pulling TKG installation binaries from the internet.

**Configure Bastion Host**

Step 1: Install Tanzu CLI

```bash
gunzip tanzu-cli-bundle-linux-amd64.tar.gz

cd cli/

sudo install core/v0.11.6/tanzu-core-linux_amd64 /usr/local/bin/tanzu 

chmod +x /usr/local/bin/tanzu
```
Run the `tanzu version` command to check that the correct version of tanzu is installed and executable.

Step 2: Install [imgpkg](https://carvel.dev/imgpkg/)

imgpkg is a tool that enables Kubernetes to store configurations and the associated container images as OCI images and to transfer these images.

```bash
gunzip imgpkg-linux-amd64-v0.22.0+vmware.1.gz

chmod +x imgpkg-linux-amd64-v0.22.0+vmware.1

mv imgpkg-linux-amd64-v0.22.0+vmware.1 /usr/local/bin/imgpkg
```

Step 3: Install the Tanzu CLI Plugins

The tanzu cli plugins provides commands for Tanzu Kubernetes cluster management and feature operations.

Running the tanzu init command for the first time installs the necessary Tanzu Kubernetes Grid configuration files in the **~/.config/tanzu/tkg** folder on your system. The script that you create and run in subsequent steps requires the Bill of Materials (BoM) YAML files in the **~/.config/tanzu/tkg/bom** folder to be present on your machine. The scripts in this procedure use the BoM files to identify the correct versions of the different Tanzu Kubernetes Grid component images to pull.

```bash
# tanzu init

Checking for required plugins...
Installing plugin 'login:v0.11.6'
Installing plugin 'management-cluster:v0.11.6'
Installing plugin 'package:v0.11.6'
Installing plugin 'pinniped-auth:v0.11.6'
Installing plugin 'secret:v0.11.6'
Successfully installed all required plugins
✔  successfully initialized CLI
```

After installing the tanzu plugins, run the tanzu plugin list command to check the plugins version and installation status.

![Tanzu Plugins List](img/tkg-airgap-nsxt/tanzu-plugins-version.jpg)

Validate the BOM files by listing the contents of the folder **.config/tanzu/tkg/bom/**

```bash
ls .config/tanzu/tkg/bom/

tkg-bom-v1.5.4.yaml  tkr-bom-v1.22.9+vmware.1-tkg.1.yaml
```

Step 4: Set the following environment variables

4a: IP address or FQDN of your local image registry. 

```bash
export TKG_CUSTOM_IMAGE_REPOSITORY="PRIVATE-REGISTRY"
```

Where PRIVATE-REGISTRY is the IP address or FQDN of your private registry and the name of the project. For example, `registry.example.com/library`

4b: Set the repository from which to fetch Bill of Materials (BoM) YAML files.

```bash
export TKG_IMAGE_REPO="projects.registry.vmware.com/tkg"

export TKG_BOM_IMAGE_TAG="v1.5.4"
```

4c: If your private registry uses a self-signed certificate, provide the CA certificate of the registry in base64 encoded format e.g. **base64 -w 0 your-ca.crt**

```bash
export TKG_CUSTOM_IMAGE_REPOSITORY_CA_CERTIFICATE=LS0t[...]tLS0tLQ==
```
This CA certificate is automatically injected into all Tanzu Kubernetes clusters that you create in this Tanzu Kubernetes Grid instance. 

4d: (Optional) Define the Tanzu Kubernetes releases (TKrs) to download. By default, the download script retrieves container images used in TKG versions v1.3.0 and later. 

List all TKrs and their associations with a TKG releases.

```bash
imgpkg pull -i ${TKG_IMAGE_REPO}/tkr-compatibility:v$(imgpkg tag list -i ${TKG_IMAGE_REPO}/tkr-compatibility |sed 's/v//' |sort -rn |head -1) --output "tkr-tmp"; cat tkr-tmp/tkr-compatibility.yaml; rm -rf tkr-tmp
```
For your TKG version, note the supported Kubernetes versions. The one with the latest minor version is used by the management cluster. For example the TKG v1.5.4 management cluster uses TKr v1.22.9\_vmware.1-tkg.1.

Export as DOWNLOAD\_TKRS a space-separated string of the TKrs required for your management cluster and workloads. For example, to download the images for Kubernetes v1.21 and v1.22 versions supported by TKG v1.5.4:

```bash
export DOWNLOAD_TKRS="v1.21.11_vmware.1-tkg.3 v1.22.9_vmware.1-tkg.1"
```

Step 5: Prepare and execute the scripts for pulling TKG installation binaries.

5a: Create a folder to collect tkg installation binaries.

```bash
mkdir -p /root/tkg-images && cd /root/tkg-images
```
5b: Download the script gen-publish-images-totar.sh

```bash
wget https://raw.githubusercontent.com/vmware-tanzu/tanzu-framework/e3de5b1557d9879dc814d771f431ce8945681c48/hack/gen-publish-images-totar.sh
```

5c: Make the gen-publish-images-totar.sh script executable.

```bash
chmod +x gen-publish-images-totar.sh
```

5d: Generate the images-to-tar-list file. 

```bash
./gen-publish-images.sh > images-to-tar-list
```

Step 6: Run the **download-images.sh** Script

6a: Create the script using the below code snippet to download the TKG installation binaries.

```bash
#!/bin/bash

set -euo pipefail

images_script=${1:-}
if [ ! -f $images_script ]; then
  echo "You may add your images list filename as an argument."
  echo "E.g ./download-images.sh image-copy-list"
fi

commands="$(cat ${images_script} |grep imgpkg |sort |uniq)"

while IFS= read -r cmd; do
  echo -e "\nrunning $cmd\n"
  until $cmd; do
     echo -e "\nDownload failed. Retrying....\n"
     sleep 1
  done
done <<< "$commands"
```

6b: Make the download-images script executable.

```bash
chmod +x download-images.sh
```

6c: Run the download-images.sh script on the images-to-tar-list file to pull the required images from the public Tanzu Kubernetes Grid registry and save them as a tar file.

```bash
./download-images.sh images-to-tar-list
```
After the script has finished execution, you will see the required TKG binaries in tar format in the directory tkg-images. The content of this directory needs to be transferred to the bootstrap machine which is running inside the airgap environment.

Step 7: Generate the publish-images-fromtar.sh Script

This script needs to be run on the bootstrap machine when you have copied the download TKG binaries onto the bootstrap vm. This script will copy the binaries from bootstrap vm into the project in your private repository.

7a: Download the script named gen-publish-images-fromtar.sh.

```bash
wget  https://raw.githubusercontent.com/vmware-tanzu/tanzu-framework/e3de5b1557d9879dc814d771f431ce8945681c48/hack/gen-publish-images-fromtar.sh
```

7b: Make the gen-publish-images-fromtar.sh script executable.

```bash
chmod +x gen-publish-images-fromtar.sh
```

7c: Generate a publish-images-fromtar.sh shell script that is populated with the address of your private Docker registry.

```bash
./gen-publish-images-fromtar.sh > publish-images-fromtar.sh
```

7d: Verify that the generated script contains the correct registry address.

```bash
cat publish-images-fromtar.sh
```
Transfer the generated publish-images-fromtar.sh script file to the bootstrap machine. 

Step 8: Collect all the binaries that you downloaded in steps 1 - 3, step 6c and step 7c of the section [Deploy and Configure Bastion Host ](#configure-bastion)and move them to the bootstrap vm using your internal process. 

# <a id=install-harbor> </a> Install Harbor Image Registry

This step is only needed if you don’t have any existing image repository in your environment and will deploy a new registry solution using Harbor. 

To install harbor, deploy an operating system of your choice with the following hardware configuration:

- vCPU: 4
- Memory: 8 GB
- Storage (HDD): 160 GB

Copy the harbor binary from the bootstrap vm to the harbor vm and follow the instructions provided in [Harbor Installation and Configuration](https://goharbor.io/docs/2.3.0/install-config/) page to deploy and configure harbor. It is recommended to deploy Harbor on the logical segment chosen for TKG management.  

# <a id=configure-bootstrap> </a> Deploy and Configure Bootstrap Machine

The bootstrap machine can be a laptop, host, or server (running on Linux/MAC/Windows platform) that you deploy management and workload clusters from, and that keeps the Tanzu and Kubernetes configuration files for your deployments, the bootstrap machine is typically local.

This machine now hosts all the required binaries for TKG installation. The bootstrap machine should have the following resources allocated:

- vCPU: 4
- RAM: 8 GB
- Storage: 200 GB or greater

Below procedure provides steps to configure bootstrap virtual machines based on CentOS,  refer to [Install the Tanzu CLI and Other Tools](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.5/vmware-tanzu-kubernetes-grid-15/GUID-install-cli.html) to configure MAC/Windows machines

- It is recommended to connect the bootstrap VM is connected to logical segment chosen for TKG management network.
- [Configure NTP](https://www.cyberithub.com/how-to-install-configure-ntp-server-in-rhel-centos-7-8/) on your bootstrap vm and ensure time is synchronized with the NTP server. It is recommended to use the same NTP server that you have configured for the other infrastructure components like vCenter, ESXi hosts, etc.

**Step 1:** Install Tanzu CLI

```bash
gunzip tanzu-cli-bundle-linux-amd64.tar.gz

cd cli/

install core/v0.11.6/tanzu-core-linux_amd64 /usr/local/bin/tanzu
 
chmod +x /usr/local/bin/tanzu
```

Run the `tanzu version` command to check that the correct version of tanzu is installed and executable.

Step 2: Install Kubectl utility

```bash
gunzip kubectl-linux-v1.22.9+vmware.1.gz

mv kubectl-linux-v1.22.9+vmware.1 /usr/local/bin/kubectl

chmod +x /usr/local/bin/kubectl
```

Run the `kubectl version --short=true` to check that the correct version of kubectl is installed and executable.

Step 3: Configure Environment Variables

In an airgap environment, if you run the tanzu init or tanzu plugin sync command, the command hangs and times out after some time with an error as shown below:

```bash
[root@bootstrap ~]# tanzu init
Checking for required plugins...
unable to list plugin from discovery 'default': error while processing package: failed to get resource files from discovery: Checking if image is bundle: Fetching image: Get "https://projects.registry.vmware.com/v2/": dial tcp 10.188.25.227:443: i/o timeout
All required plugins are already installed and up-to-date
✔  successfully initialized CLI

[root@bootstrap ~]# tanzu plugin sync
Checking for required plugins...
unable to list plugin from discovery 'default': error while processing package: failed to get resource files from discovery: Checking if image is bundle: Fetching image: Get "https://projects.registry.vmware.com/v2/": dial tcp 10.188.25.227:443: i/o timeout
All required plugins are already installed and up-to-date
✔  Done
```

By default the tanzu global config file (config.yaml) which gets created when you first run tanzu init command, points to repository url <https://projects.registry.vmware.com> to fetch the tanzu plugins for installation, and since there is no internet in the environment, the commands fails after some time.

To make sure that Tanzu Kubernetes Grid always pulls images from the local private registry, run the tanzu config set command to add TKG\_CUSTOM\_IMAGE\_REPOSITORY to the global Tanzu CLI configuration file, ~/.config/tanzu/config.yaml. 

If your image registry is configured with a public signed CA certificate, set the following environment variables.

```bash
tanzu config set env.TKG_CUSTOM_IMAGE_REPOSITORY custom-image-repository.io/yourproject

tanzu config set env.TKG_CUSTOM_IMAGE_REPOSITORY_SKIP_TLS_VERIFY true
```

If your registry solution uses self-signed certificates, also add TKG\_CUSTOM\_IMAGE\_REPOSITORY\_CA\_CERTIFICATE in base64-encoded format to the global Tanzu CLI configuration file. In the case of self-signed certificates, set the following environment variables:

```bash
tanzu config set env.TKG_CUSTOM_IMAGE_REPOSITORY custom-image-repository.io/yourproject

tanzu config set env.TKG_CUSTOM_IMAGE_REPOSITORY_SKIP_TLS_VERIFY false

tanzu config set env.TKG_CUSTOM_IMAGE_REPOSITORY_CA_CERTIFICATE LS0t[...]tLS0tLQ==

```

Step 3: Initialize Tanzu Kubernetes Grid and Install Tanzu CLI Plugins

```bash
### Initialize Tanzu Kubernetes Grid 

tanzu config init 

## (Optional) Remove existing plugins from any previous CLI installations.

tanzu plugin clean

tanzu plugin sync
```

After installing the tanzu plugins, run the tanzu plugin list command to check the plugins version and installation status.

Step 4: Install carvel Tools

Tanzu Kubernetes Grid uses the following tools from the Carvel open-source project:

- [ytt](https://carvel.dev/ytt/) - a command-line tool for templating and patching YAML files. You can also use ytt to collect fragments and piles of YAML into modular chunks for easy re-use.
- [kapp](https://carvel.dev/kapp/) - the application deployment CLI for Kubernetes. It allows you to install, upgrade, and delete multiple Kubernetes resources as one application.
- [kbld](https://carvel.dev/kbld/) - an image-building and resolution tool.
- [imgpkg](https://carvel.dev/imgpkg/) - a tool that enables Kubernetes to store configurations and the associated container images as OCI images, and to transfer these images.

4.1 Install ytt

```bash
cd ./cli

gunzip ytt-linux-amd64-v0.37.0+vmware.1.gz

mv ytt-linux-amd64-v0.37.0+vmware.1 /usr/local/bin/ytt

chmod +x /usr/local/bin/ytt

```
Run `ytt --version` to check that the correct version of ytt is installed and executable

4.2 Install kapp

```bash
gunzip kapp-linux-amd64-v0.42.0+vmware.2.gz

mv kapp-linux-amd64-v0.42.0+vmware.2 /usr/local/bin/kapp

chmod +x /usr/local/bin/kapp
```

Run `kapp --version` to check that the correct version of kapp is installed and executable.

4.3 Install kbld

```bash
gunzip kbld-linux-amd64-v0.31.0+vmware.1.gz

mv kbld-linux-amd64-v0.31.0+vmware.1 /usr/local/bin/kbld

chmod +x /usr/local/bin/kbld
```

Run `kbld --version` to check that the correct version of kbld is installed and executable.

4.4 Install imgpkg

```bash
gunzip imgpkg-linux-amd64-v0.22.0+vmware.1.gz
mv imgpkg-linux-amd64-v0.22.0+vmware.1 /usr/local/bin/imgpkg
chmod +x /usr/local/bin/imgpkg
```

Run `imgpkg --version` to check that the correct version of imgpkg is installed and executable.

Step 5: Install yq

yq a lightweight and portable command-line YAML processor. 

```bash
wget https://github.com/mikefarah/yq/releases/download/v4.25.2/yq_linux_amd64.tar.gz

tar -zxvf yq_linux_amd64.tar.gz

mv yq_linux_amd64 /usr/local/bin/
```
Run the `yq -V` command to check that the correct version of yq is installed and executable.

Step 6: Install Docker

Navigate to the folder where the docker installation binaries are located and run the rpm -ivh <package-name> command.

```bash
cd docker-binaries

rpm -ivh *.rpm
```

Wait for the installation process to finish.

![Docker Installation](img/tkg-airgap-nsxt/docker-installation.jpg)

Start the docker service and set the service to run at boot time.

```bash
systemctl start docker && systemctl enable docker && systemctl status docker
```

Step 7: Create an SSH Key Pair

This is required for Tanzu CLI to connect to vSphere from the bootstrap machine.  The public key part of the generated key will be passed during the TKG management cluster deployment.  

```bash
### Generate public/Private key pair.

ssh-keygen -t rsa -b 4096 -C "email@example.com"

### Add the private key to the SSH agent running on your machine and enter the password you created in the previous step 

ssh-add ~/.ssh/id_rsa 

### If the above command fails, execute "eval $(ssh-agent)" and then rerun the command.
```

Make a note of the public key from the file **$home/.ssh/id\_rsa.pub**. You need this while creating a config file for deploying the TKG management cluster.

Step 8: Push TKG installation binaries to your private image registry.

Navigate to the folder which contains all TKG binaries and the publish-images-fromtar.sh file that you have copied from the bastion host and then execute the below command to push the binaries to your private image registry. 

```bash
### Make the publish-images-fromtar.sh script executable.

chmod +x publish-images-fromtar.sh

### Execute the publish-images-fromtar.sh script

sh publish-images-fromtar.sh
```

Now all the required packages are installed and required configurations are in place on the bootstrap virtual machine.

## Import the Base Image Template in vCenter Server

A base image template containing the OS and Kubernetes versions, that will be used to deploy management & workload clusters, is imported in vSphere. See [Import the Base Image Template into vSphere](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.5/vmware-tanzu-kubernetes-grid-15/GUID-mgmt-clusters-vsphere.html#import-a-base-image-template-into-vsphere-4).

**Note:** If using a **non-administrator SSO account**: In the VMs and Templates view, right-click the new template, select **Add Permission**, and assign the **tkg-user** to the template with the **TKG role**.

For information about how to create the user and role for Tanzu Kubernetes Grid, see [Required Permissions for the vSphere Account](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.5/vmware-tanzu-kubernetes-grid-15/GUID-mgmt-clusters-vsphere.html#required-permissions-for-the-vsphere-account-5).

## Import NSX Advanced Load Balancer in Content Library

Create a content library following the instructions provided in the VMware [documentation](https://docs.vmware.com/en/VMware-vSphere/7.0/com.vmware.vsphere.vm_admin.doc/GUID-2A0F1C13-7336-45CE-B211-610D39A6E1F4.html). NSX Advanced Load Balancer ova is stored in this library. To import the ova into the content library, follow the instructions provided [here](https://docs.vmware.com/en/VMware-vSphere/7.0/com.vmware.vsphere.vm_admin.doc/GUID-897EEEC2-B378-41A7-B92B-D1159B5F6095.html). 

# Deploy and Configure NSX Advanced Load Balancer

NSX ALB is deployed in Write Access Mode mode in the vSphere Environment. This mode grants NSX ALB Controllers full write access to the vCenter which helps in automatically creating, modifying, and removing SEs and other resources as needed to adapt to changing traffic needs.

For a production-grade deployment, it is recommended to deploy 3 instances of the NSX ALB Controller for high availability and resiliency. To know more about how NSX ALB provides load balancing in the Tanzu Kubernetes Grid environment, please see the official [documentation](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.5/vmware-tanzu-kubernetes-grid-15/GUID-mgmt-clusters-install-nsx-adv-lb.html)**

Below is the sample IP and FQDN set for the NSX ALB controllers:

|**Controller Node**|**IP Address**|**FQDN**|
| :- | :- | :- |
|Node 01 (Primary)|172.19.71.3|alb01.tanzu.lab|
|Node 02 (Secondary)|172.19.71.4|alb02.tanzu.lab|
|Node 03 (Secondary) |172.19.71.5|alb03.tanzu.lab|
|Controller Cluster|172.19.71.2|alb.tanzu.lab|

### Deploy NSX ALB Controllers

To deploy NSX ALB controller nodes, follow the steps provided in the[ Deploy a Virtual Machine from an OVF Template](https://docs.vmware.com/en/VMware-vSphere/7.0/com.vmware.vsphere.vm_admin.doc/GUID-3C02B3FC-5DE6-48AA-9AD3-7F0D1C7EC4B6.html) page. Follow the wizard to configure the following:

- VM Name and select the NSX-ALB-VMs folder for controller nodes placement.
- Select the **NSX-ALB** resource pool as a compute resource.
- Select the datastore for the controller node deployment.
- Select the **nsx\_alb\_management\_pg** port group for the Management Network.
- Customize the configuration by providing Management Interface IP Address, Subnet Mask, and Default Gateway. The rest of the fields are optional and should be left blank.

![](img/tkg-airgap-nsxt/deploy-alb01.jpg)

A new task for creating the virtual machine appears in the Recent Tasks pane. After the task is complete, the NSX ALB virtual machine is created on the selected resource. Power on the Virtual Machine and give it a few minutes for the system to boot, upon successful boot up navigate to NSX ALB on your browser.

Once the NSX ALB is successfully deployed and boots up, navigate to NSX ALB on your browser using the URL “https://<alb-fqdn>/” and configure the basic system settings as follows:

- Configure the administrator account by setting up a password and email (optional).

![](img/tkg-airgap-nsxt/deploy-alb02.jpg)

- Configure System Settings by specifying the backup passphrase and DNS information.

![](img/tkg-airgap-nsxt/deploy-alb03.jpg)

- (Optional) Configure Email/SMTP: Provide **Email** or **SMTP** information.

![](img/tkg-airgap-nsxt/deploy-alb04.jpg)

- Configure Multi-Tenant settings as follows:
- **IP Route Domain:** Share IP route domain across tenants.
- **Service Engine Context:** Service Engines are managed within the tenant context, not shared across tenants.

![](img/tkg-airgap-nsxt/deploy-alb05.jpg)

If you did not select the Setup Cloud After option before saving, the initial configuration wizard exits. The Cloud configuration window does not automatically launch and you are directed to a Dashboard view on the controller.

### Configure NTP Settings

To Configure NTP, navigate to **Administration** > **Settings** > **DNS/NTP > Edit** 

![](img/tkg-airgap-nsxt/deploy-alb06.jpg)

Add your NTP server details and **Save.**

**Note:** You may also delete the default NTP servers.

![](img/tkg-airgap-nsxt/deploy-alb07.jpg)

### Configure Licensing

This document focuses on enabling NSX ALB using the **Enterprise License.**

To configure licensing, navigate to the **Administration** > **Settings** > **Licensing** and click on the gear icon to change the license type to Enterprise.

![](img/tkg-airgap-nsxt/deploy-alb08.jpg)

Select license type as “**Enterprise Tier**” and click on Save.

![](img/tkg-airgap-nsxt/deploy-alb09.jpg)

Once the license tier has been changed, apply the NSX ALB Enterprise license key. If you have a license file instead of a license key, apply the license by selecting the Upload a License File option.

![](img/tkg-airgap-nsxt/deploy-alb10.jpg)

### NSX Advanced Load Balancer: Controller High Availability

In a production environment, it is recommended to deploy additional controller nodes and configure the controller cluster for high availability and disaster recovery. Adding 2 additional nodes to create a 3-node cluster provides node-level redundancy for the controller and also maximizes performance for CPU-intensive analytics functions. 

To run a 3 node controller cluster, you deploy the first node and perform the initial configuration, and set the Cluster IP. After that, you deploy and power on two more Controller VMs, but you must not run the initial configuration wizard or change the admin password for these controllers VMs. The configuration of the first controller VM is assigned to the two new Controller VMs.

The first controller of the cluster receives the "Leader" role. The second and third controllers will work as "Follower".

Perform the below steps to configure the NSX ALB cluster:

- Log in to the primary NSX ALB controller > Navigate to Administrator > Controller > Nodes and click Edit. 

![](img/tkg-airgap-nsxt/deploy-alb11.jpg)

- Specify the cluster **name,** and** set the Controller Cluster IP. This IP address should be from the NSX ALB management network. Also, specify the IP address for the 2nd and 3rd controller and click on **Save.**

- ` `Optional - Provide a friendly name for all 3 Nodes

![](img/tkg-airgap-nsxt/deploy-alb12.jpg)

After these steps, the primary NSX ALB Controller becomes the leader for the cluster and invites the other controllers to the cluster as members. 

NSX ALB then performs a warm reboot of the cluster. This process can take approximately 10-15 minutes. You will be automatically logged out of the controller node where you are currently logged in. On entering the cluster IP in the browser, you can see details about the cluster formation task.

![](img/tkg-airgap-nsxt/deploy-alb13.jpg)

The configuration of the primary (leader) Controller is synchronized to the new member nodes when the cluster comes online following the reboot. Once the cluster is successfully formed we should see the below status:

![](img/tkg-airgap-nsxt/deploy-alb14.jpg)

**Note:** Going forward all NSX ALB configurations will be configured by connecting to the NSX ALB Controller Cluster IP/FQDN.

### Change NSX Advanced Load Balancer Portal Certificate

The default system-generated controller certificate generated for SSL/TSL connections will not have required SAN entries. Follow the below steps to create a Controller certificate

- Login to NSX ALB Controller > **Templates** > **Security** > **SSL/TLS Certificates**
- Click on **Create** and Select **Controller Certificate**

![](img/tkg-airgap-nsxt/deploy-alb15.jpg)

- You can either generate a Self-Signed certificate, generate CSR or import a certificate.
  For the purpose of this document, a self-signed certificate will be generated, 
- Provide all required details as per your infrastructure requirements, and under the Subject Alternate Name (SAN) section, provide IP and FQDN of all NSX ALB controllers including NSX ALB cluster IP and FQDN, and click on Save

![](img/tkg-airgap-nsxt/deploy-alb16.jpg)

![](img/tkg-airgap-nsxt/deploy-alb17.jpg)

- Once the certificate is created, capture the certificate contents as this is required while deploying the TKG management cluster. 
  To capture the certificate content, click on the “Download” icon next to the certificate, and then click on “Copy to clipboard” under the certificate section.

![](img/tkg-airgap-nsxt/deploy-alb18.jpg)

- To replace the system-generated certificate with the newly created certificate navigate to **Administration** > **Settings** > **Access** **Settings**, and click on the pencil icon at the top right to **edit** the System Access Settings, replace the SSL/TSL certificate and click on **Save**

![](img/tkg-airgap-nsxt/deploy-alb19.jpg)

Now, logout and login back to the NSX ALB. You will be prompt to accept the SSL certificate warning in the browser.

### Configure vCenter Cloud and Service Engine Groups

NSX ALB Vantage may be deployed in multiple environments for the same system. Each environment is called a “cloud”. The below procedure provides steps on how to create a VMware vCenter cloud, and as shown in the architecture two Service Engine Groups will be created

**Service Engine Group 1**: Service engines part of this Service Engine group hosts:

- Virtual services for all load balancer functionalities requested by TKG Management and Shared-Services cluster.
- Virtual services that load balances control plane nodes of all TKG clusters

**Service Engine Group 2**: Service engines part of this Service Engine group, hosts virtual services for all load balancer functionalities requested by TKG Workload clusters mapped to this SE group.
**Note:** 

- Based on your requirements, you can create additional Service Engine groups for the workload clusters. 
- Multiple Workload clusters can be mapped to a single SE group.
- A TKG cluster can be mapped to only one SE group for Application load balancer services.  

Below are the components that will be created in NSX ALB

|Object|Sample Name|
| :- | :- |
|vCenter Cloud|tkg-vsphere|
|Service Engine Group 1|tkg-mgmt-seg|
|Service Engine Group 2|tkg-workload-seg|

1. Login to NSX ALB > Infrastructure > Clouds > Create > VMware vCenter/vSphere ESX

   ![](img/tkg-airgap-nsxt/deploy-alb20.jpg)

1. Provide Cloud Name and click on Next

   ![](img/tkg-airgap-nsxt/deploy-alb21.jpg)

1. Under the Infrastructure pane, provide vCenter Address, username and password and set Access Permission to "Write" and click on the Next button.

   ![](img/tkg-airgap-nsxt/deploy-alb22.jpg)

1. Under the **Datacenter** pane, Choose the Datacenter for NSX ALB to discover Infrastructure resources. Ensure that the Default Network IP Address Management is set to **DHCP**.

   ![](img/tkg-airgap-nsxt/deploy-alb23.jpg)

1. Under the **Network** pane, choose the NSX ALB **Management** **Network** for Service Engines and provide a **Static** **IP** **pool** for SEs and VIPs and click on the Complete button.

   ![](img/tkg-airgap-nsxt/deploy-alb24.jpg)

1. Wait for the status of the Cloud to configure and the status to turn Green. 

   ![](img/tkg-airgap-nsxt/deploy-alb25.jpg)

1. To create a Service Engine group for TKG management clusters, click on the **Service Engine Group** tab, under Select Cloud, choose the Cloud created in the previous step, and click **Create**

1. Provide a name for the TKG management Service Engine group and set the below parameters

|**Parameter**|**Value**|
| :- | :- |
|High availability mode|N+M (buffer)|
|Memory per Service Engine|4|
|vCPU per Service Engine|2|

The rest of the parameters can be left as default

![](img/tkg-airgap-nsxt/deploy-alb26.jpg)

For advanced configuration click on the Advanced tab, to specify a specific cluster and datastore for service engine placement, to change the SE folder name and Service engine name prefix and, click on **Save**

9. Follow steps 7 and 8 to create another Service Engine group for TKG workload clusters. Once complete there must be two service engine groups created.

  ![](img/tkg-airgap-nsxt/deploy-alb27.jpg)

### **Configure TKG Networks in NSX ALB** 

As part of the Cloud creation in NSX ALB, only the management Network has been configured in NSX ALB, follow the below procedure to configure the following networks: 

- TKG Cluster VIP Network 
- TKG Management VIP (TKG-SS-VIP) Network 
- TKG Workload VIP Network 

Login to NSX ALB and navigate to **Infrastructure** > **Networks** tab and** select the **tkg-vsphere** Cloud. All the networks available in vCenter will be listed.

Click on the edit icon next for the network and configure it as below. Change the details provided below as per your SDDC configuration.

|**Network Name**|**DHCP** |**Subnet**|**Static IP Pool**|
| :- | :- | :- | :- |
|tkg-cluster-vip-ls|No|172.19.75.1/26|172.19.75.2 - 172.19.75.62|
|tkg-mgmt-vip-ls|No|172.19.74.1/26|172.19.74.2 - 172.19.74.62|
|tkg-workload-vip-ls|No|172.19.76.1/26|172.19.76.2 - 172.19.76.62|

Below is the snippet of configuring one of the networks, for example: “tkg-cluster-vip-ls”
![](img/tkg-airgap-nsxt/deploy-alb28.jpg)

Once the networks configured, the configuration must look like below

![](img/tkg-airgap-nsxt/deploy-alb29.jpg)

**Configure Routing**

After the VIP networks are configured, set the default routes for all VIP/Data networks. The below table lists the default routes used in the current environment.

|**Gateway Subnet**|**Next Hop**|
| :- | :- |
|0.0.0.0/0|172.19.75.1|
|0.0.0.0/0|172.19.74.1|
|0.0.0.0/0|172.19.76.1|

**Note:** Change the gateway for VIP networks as per your network configurations.

Navigate to the **Routing** page and click on the Create button. Add default routes for the VIP networks.
![](img/tkg-airgap-nsxt/deploy-alb30.jpg)

A total of 3 default gateways are configured.

![](img/tkg-airgap-nsxt/deploy-alb31.jpg)


### **Create IPAM & DNS Profiles**

IPAM is required to allocate virtual IP addresses when virtual services get created. NSX ALB provides IPAM service for TKG Cluster VIP Network, TKG Mgmt VIP Network, and TKG Workload VIP Network.

To create an IPAM profile, navigate to the **Templates > Profiles > IPAM/DNS Profiles** page, click on the **Create** button, and select IPAM Profile. 

Create the IPAM profile using the values shown in the below table.

|**Parameter**|**Value**|
| :- | :- |
|Name|tkg-alb-ipam|
|Type|AVI Vintage IPAM|
|Cloud for Usable Networks|tkg-vsphere|
|Usable Networks|<p>- alb-mgmt-ls</p><p>- tkg-cluster-vip-ls</p><p>- tkg-mgmt-vip-ls</p><p>- tkg-workload-vip-ls</p>|

Click on the Save button to finish the IPAM creation wizard.

![](img/tkg-airgap-nsxt/deploy-alb32.jpg)

To create a DNS profile, click on the Create button again and select DNS Profile.

- Provide a name for the DNS Profile and select the type as AVI Vantage DNS. 
- Under Domain Name specify the domain that you want to use with NSX ALB. Optionally override record TTL value for the domain. The default is 30 seconds for all domains.**

![](img/tkg-airgap-nsxt/deploy-alb33.jpg)

The newly created IPAM and DNS profiles need to be associated with the cloud in order to be leveraged by the NSX ALB objects created under that cloud. 

To assign the IPAM and DNS profile to the cloud, navigate to the **Infrastructure > Cloud** page and edit the cloud configuration.

- Under IPAM Profile, select the IPAM profile. 
- Under DNS Profile, select the DNS profile and save the settings. 

![](img/tkg-airgap-nsxt/deploy-alb34.jpg)

Verify that the status of the cloud is green after configuring the IPAM and DNS profile.

![](img/tkg-airgap-nsxt/deploy-alb35.jpg)

This completes the NSX Advanced Load Balancer configuration. Next is to deploy and configure the Tanzu Kubernetes Grid management cluster.

# <a id=deploy-tkg-management> </a> Deploy Tanzu Kubernetes Grid Management Cluster

The management cluster is a Kubernetes cluster that runs Cluster API operations on a specific cloud provider to create and manage workload clusters on that provider.

The management cluster is also where you configure the shared and in-cluster services that the workload clusters use.

You may deploy management clusters in two ways:

1. Run the Tanzu Kubernetes Grid installer, a wizard interface that guides you through the process of deploying a management cluster. 
1. Create and edit YAML configuration files, and use them with Tanzu CLI commands to deploy a management cluster.

Before creating a management cluster using the Tanzu CLI, you must define its configuration in a YAML configuration file that provides the base configuration for the cluster. When you deploy the management cluster from the CLI, you specify this file by using the --file option of the tanzu mc create command.

In an airgap environment, deploying a management cluster through yaml is the recommended method. You can use the templates provided in the following section to deploy management clusters on vSphere. 

## Management Cluster Configuration Template

The templates include all of the options that are relevant to deploying management clusters on vSphere. You can copy this template and use it to deploy management clusters to vSphere.

**Important:** The environment variables that you have set, override values from a cluster configuration file. To use all settings from a cluster configuration file, unset any conflicting environment variables before you deploy the management cluster from the CLI.

```yaml
#! ---------------------------------------------------------------------
#! Basic cluster creation configuration
#! ---------------------------------------------------------------------

CLUSTER_NAME:
CLUSTER_PLAN: <dev/prod>
INFRASTRUCTURE_PROVIDER: vsphere
ENABLE_CEIP_PARTICIPATION: <true/false>
ENABLE_AUDIT_LOGGING: <true/false>
CLUSTER_CIDR: 100.96.0.0/11
SERVICE_CIDR: 100.64.0.0/13
# CAPBK_BOOTSTRAP_TOKEN_TTL: 30m

#! ---------------------------------------------------------------------
#! vSphere configuration
#! ---------------------------------------------------------------------

VSPHERE_SERVER:
VSPHERE_USERNAME:
VSPHERE_PASSWORD:
VSPHERE_DATACENTER:
VSPHERE_RESOURCE_POOL:
VSPHERE_DATASTORE:
VSPHERE_FOLDER:
VSPHERE_NETWORK: <tkg-management-network>
VSPHERE_CONTROL_PLANE_ENDPOINT: #Leave blank as VIP network is configured in NSX ALB and IPAM is configured with VIP network

# VSPHERE_TEMPLATE:

VSPHERE_SSH_AUTHORIZED_KEY:
VSPHERE_TLS_THUMBPRINT:
VSPHERE_INSECURE: <true/false>
DEPLOY_TKG_ON_VSPHERE7: true

#! ---------------------------------------------------------------------
#! Node configuration
#! ---------------------------------------------------------------------

# SIZE:
# CONTROLPLANE_SIZE:
# WORKER_SIZE:
# OS_NAME: ""
# OS_VERSION: ""
# OS_ARCH: ""
# VSPHERE_NUM_CPUS: 2
# VSPHERE_DISK_GIB: 40
# VSPHERE_MEM_MIB: 4096
# VSPHERE_CONTROL_PLANE_NUM_CPUS: 2
# VSPHERE_CONTROL_PLANE_DISK_GIB: 40
# VSPHERE_CONTROL_PLANE_MEM_MIB: 8192
# VSPHERE_WORKER_NUM_CPUS: 2
# VSPHERE_WORKER_DISK_GIB: 40
# VSPHERE_WORKER_MEM_MIB: 4096

#! ---------------------------------------------------------------------
#! NSX Advanced Load Balancer configuration
#! ---------------------------------------------------------------------

AVI_ENABLE: true
AVI_CONTROL_PLANE_HA_PROVIDER: true
AVI_CONTROLLER:
AVI_USERNAME: ""
AVI_PASSWORD: ""
AVI_CLOUD_NAME:
AVI_SERVICE_ENGINE_GROUP:
AVI_MANAGEMENT_CLUSTER_SERVICE_ENGINE_GROUP:
AVI_DATA_NETWORK:
AVI_DATA_NETWORK_CIDR:
AVI_MANAGEMENT_CLUSTER_VIP_NETWORK_NAME:
AVI_MANAGEMENT_CLUSTER_VIP_NETWORK_CIDR:
AVI_CA_DATA_B64: ""
AVI_LABELS: ""

# AVI_DISABLE_STATIC_ROUTE_SYNC: true
# AVI_INGRESS_DEFAULT_INGRESS_CONTROLLER: false
# AVI_INGRESS_SHARD_VS_SIZE: ""
# AVI_INGRESS_SERVICE_TYPE: ""
# AVI_INGRESS_NODE_NETWORK_LIST: ""
# AVI_NAMESPACE: "tkg-system-networking"
# AVI_DISABLE_INGRESS_CLASS: true
# AVI_AKO_IMAGE_PULL_POLICY: IfNotPresent
# AVI_ADMIN_CREDENTIAL_NAME: avi-controller-credentials
# AVI_CA_NAME: avi-controller-ca
#AVI_CONTROLLER_VERSION:# Required for NSX Advanced Load Balancer (ALB) v21.1.x.

#! ---------------------------------------------------------------------
#! Image repository configuration
#! ---------------------------------------------------------------------

TKG_CUSTOM_IMAGE_REPOSITORY: ""
TKG_CUSTOM_IMAGE_REPOSITORY_SKIP_TLS_VERIFY: false
TKG_CUSTOM_IMAGE_REPOSITORY_CA_CERTIFICATE: ""

#! ---------------------------------------------------------------------
#! Machine Health Check configuration
#! ---------------------------------------------------------------------

ENABLE_MHC:
ENABLE_MHC_CONTROL_PLANE: <true/false>
ENABLE_MHC_WORKER_NODE: <true/flase>

#! ---------------------------------------------------------------------
#! Identity management configuration
#! ---------------------------------------------------------------------

IDENTITY_MANAGEMENT_TYPE: "none"

#! Settings for IDENTITY_MANAGEMENT_TYPE: "oidc"
# CERT_DURATION: 2160h
# CERT_RENEW_BEFORE: 360h
# OIDC_IDENTITY_PROVIDER_CLIENT_ID:
# OIDC_IDENTITY_PROVIDER_CLIENT_SECRET:
# OIDC_IDENTITY_PROVIDER_GROUPS_CLAIM: groups
# OIDC_IDENTITY_PROVIDER_ISSUER_URL:
# OIDC_IDENTITY_PROVIDER_SCOPES: "email,profile,groups"
# OIDC_IDENTITY_PROVIDER_USERNAME_CLAIM: email

#! Settings for IDENTITY_MANAGEMENT_TYPE: "ldap"
# LDAP_BIND_DN:
# LDAP_BIND_PASSWORD:
# LDAP_HOST:
# LDAP_USER_SEARCH_BASE_DN:
# LDAP_USER_SEARCH_FILTER:
# LDAP_USER_SEARCH_USERNAME: userPrincipalName
# LDAP_USER_SEARCH_ID_ATTRIBUTE: DN
# LDAP_USER_SEARCH_EMAIL_ATTRIBUTE: DN
# LDAP_USER_SEARCH_NAME_ATTRIBUTE:
# LDAP_GROUP_SEARCH_BASE_DN:
# LDAP_GROUP_SEARCH_FILTER:
# LDAP_GROUP_SEARCH_USER_ATTRIBUTE: DN
# LDAP_GROUP_SEARCH_GROUP_ATTRIBUTE:
# LDAP_GROUP_SEARCH_NAME_ATTRIBUTE: cn
# LDAP_ROOT_CA_DATA_B64:
```

For a full list of configurable values and to know more about the fields present in the template file, please see [Create a Management Cluster Configuration File](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.5/vmware-tanzu-kubernetes-grid-15/GUID-tanzu-config-reference.html)

Create a file using the values provided in the template and save the file with .yaml extension. A sample yaml file used for management cluster deployment is provided in the [Appendix section](#supplemental-information) for the reference.

After you have created or updated the cluster configuration file, you can deploy a management cluster by running the `tanzu mc create --file CONFIG-FILE` command, where CONFIG-FILE is the name of the configuration file. 

The cluster deployment logs are streamed in the terminal when you run the tanzu mc create command. The first run of tanzu mc create takes longer than subsequent runs because it has to pull the required Docker images into the image store on your bootstrap machine. Subsequent runs do not require this step, and thus the process is faster.

While the cluster is being deployed, you will find that a Virtual service will be created in NSX Advanced Load Balancer and new service engines will be deployed in vCenter by NSX ALB and the service engines will be mapped to the SE Group `tkg-mgmt-seg`.

Now you can access the TKG management cluster from the bootstrap machine and perform additional tasks such as verifying the management cluster health and deploying the workload clusters etc.

To get the status of the TKG Management cluster execute the below command:

```bash
tanzu management-cluster get
```
![](img/tkg-airgap-nsxt/mgmt-cluster-status.jpg)

To interact with the management cluster using the kubectl command, you have to retrieve the management cluster kubeconfig and switch to the cluster context to run kubectl commands.

```bash
tanzu mc kubeconfig get --admin

Kubectl config use-context <mgmt cluster context>
```

![](img/tkg-airgap-nsxt/connect-mgmt-cluster.jpg)

The TKG management cluster is successfully deployed and now you can proceed with creating Shared Service and workload clusters.

# <a id=deploy-tkg-shared-services> </a> Deploy Tanzu Kubernetes Grid Shared Services Cluster
Each Tanzu Kubernetes Grid instance can have only one shared services cluster. Create a shared services cluster if you intend to deploy Harbor.

Deploying a Shared service cluster and workload cluster is exactly the same, the only difference is, for the shared service cluster you will be adding a tanzu-services label to the shared services cluster, as its cluster role. This label identifies the shared services cluster to the management cluster and workload clusters.

Another **major difference** between shared service cluster when compared with Workload clusters is that Shared service cluster will be applied with the **Cluster Labels** which were defined while deploying Management Cluster. This is to enforce that only the Shared Service Cluster will make use of the `tkg-mgmt-vip-ls` Network for application load balancing purposes and the virtual services are deployed on the same Service Engine that is used by the management cluster.

Deployment of the shared services cluster is done by creating a yaml file and invoking the tanzu cluster create -f <file-name> command. The yaml file used for shared services deployment is usually a bit smaller than the yaml used for the management cluster deployment because you don’t need to define the AVI fields except AVI\_CONTROL\_PLANE\_HA\_PROVIDER in the yaml. 

A sample yaml for shared services cluster deployment is given below:

```yaml
CLUSTER_CIDR: 100.96.0.0/11
SERVICE_CIDR: 100.64.0.0/13
CLUSTER_NAME: tkg154-ss-airgap
CLUSTER_PLAN: prod
ENABLE_AUDIT_LOGGING: "true"
ENABLE_CEIP_PARTICIPATION: "false"
ENABLE_MHC: "true"
IDENTITY_MANAGEMENT_TYPE: none
INFRASTRUCTURE_PROVIDER: vsphere
DEPLOY_TKG_ON_VSPHERE7: true
AVI_CONTROL_PLANE_HA_PROVIDER: "true"
OS_ARCH: amd64
OS_NAME: photon
OS_VERSION: "3"
TKG_HTTP_PROXY_ENABLED: "false"
TKG_IP_FAMILY: ipv4
ENABLE_DEFAULT_STORAGE_CLASS: "true"
VSPHERE_CONTROL_PLANE_ENDPOINT: ""
CONTROLPLANE_SIZE: "medium"
WORKER_SIZE: "medium"
CONTROL_PLANE_MACHINE_COUNT: "3"
WORKER_MACHINE_COUNT: "3"
VSPHERE_DATACENTER: /Tanzu-DC
VSPHERE_DATASTORE: /Tanzu-DC/datastore/ds1/vsanDatastore
VSPHERE_FOLDER: /Tanzu-DC/vm/TKG-SS-VMs
VSPHERE_INSECURE: "true"
VSPHERE_NETWORK: /Tanzu-DC/network/tkg-ss-ls
VSPHERE_PASSWORD: <encoded:Vk13YXJlMSE=>
VSPHERE_RESOURCE_POOL: /Tanzu-DC/host/Tanzu-CL01/Resources/tkg-ss-ls
VSPHERE_SERVER: tanzu-vc01.tanzu.lab
VSPHERE_TLS_THUMBPRINT: ""
VSPHERE_USERNAME: administrator@vsphere.local
VSPHERE_SSH_AUTHORIZED_KEY: ssh-rsa AAAA[...]== email@example.com
TKG_CUSTOM_IMAGE_REPOSITORY: registry.vstellar.local/tkg154
TKG_CUSTOM_IMAGE_REPOSITORY_SKIP_TLS_VERIFY: 'False'
TKG_CUSTOM_IMAGE_REPOSITORY_CA_CERTIFICATE: LS0t[...]tLS0tLQ==
```

Cluster creation roughly takes 15-20 minutes to complete. Verify the health of the cluster by running the tanzu cluster list command

![](img/tkg-airgap-nsxt/shared-services-cluster.jpg)

After the cluster deployment completes, connect to the Tanzu Management Cluster context and apply the below labels.

```bash
## Connect to tkg management cluster

kubectl config use-context <mgmt cluster context>

## Add the tanzu-services label to the shared services cluster as its cluster role.

kubectl label cluster.cluster.x-k8s.io/<shared services cluster name> cluster-role.tkg.tanzu.vmware.com/tanzu-services="" --overwrite=true

## Tag shared service cluster with all “Cluster Labels” defined while deploying Management Cluster, once the “Cluster Labels” are applied AKO pod will be deployed on the Shared Service Cluster

kubectl label cluster <shared services cluster name> key=value

Example: kubectl label cluster tkg154-ss-airgap type=management
```

Get the admin context of the shared service cluster using the below commands and switch the context to the Shared Service cluster

```bash
## Use below command to get the admin context of Shared Service Cluster.

tanzu cluster kubeconfig get shared services cluster name --admin

## Use below to use the context of Shared Service Cluster

kubectl config use-context <shared services cluster context>

## Verify that ako pod gets deployed in avi-system namespace

kubectl get pods -n avi-system
NAME    READY   STATUS    RESTARTS   AGE
ako-0   1/1     Running   0          41s
```

Now the shared service cluster is successfully created, you may proceed with deploying the workload clusters. 

# <a id=deploy-workload-cluster> </a> Deploy Tanzu Kubernetes Grid Workload Cluster

Deployment of the workload cluster** is done using a yaml similar to the shared services cluster yaml but customized for the workload cluster placement objects.

A sample yaml for the workload cluster deployment is given below:

```yaml
CLUSTER_CIDR: 100.96.0.0/11
SERVICE_CIDR: 100.64.0.0/13
CLUSTER_NAME: tkg154-wld-airgap
CLUSTER_PLAN: prod
ENABLE_AUDIT_LOGGING: "true"
ENABLE_CEIP_PARTICIPATION: "false"
ENABLE_MHC: "true"
IDENTITY_MANAGEMENT_TYPE: none
INFRASTRUCTURE_PROVIDER: vsphere
DEPLOY_TKG_ON_VSPHERE7: true
AVI_CONTROL_PLANE_HA_PROVIDER: "true"
OS_ARCH: amd64
OS_NAME: photon
OS_VERSION: "3"
TKG_HTTP_PROXY_ENABLED: "false"
TKG_IP_FAMILY: ipv4
ENABLE_DEFAULT_STORAGE_CLASS: "true"
VSPHERE_CONTROL_PLANE_ENDPOINT: ""
CONTROLPLANE_SIZE: "medium"
WORKER_SIZE: "medium"
CONTROL_PLANE_MACHINE_COUNT: "3"
WORKER_MACHINE_COUNT: "3"
VSPHERE_DATACENTER: /Tanzu-DC
VSPHERE_DATASTORE: /Tanzu-DC/datastore/ds1/vsanDatastore
VSPHERE_FOLDER: /Tanzu-DC/vm/TKG-Workload-VMs
VSPHERE_INSECURE: "true"
VSPHERE_NETWORK: /Tanzu-DC/network/tkg-workload-ls
VSPHERE_PASSWORD: <encoded:Vk13YXJlMSE=>
VSPHERE_RESOURCE_POOL: /Tanzu-DC/host/Tanzu-CL01/Resources/TKG-WLD
VSPHERE_SERVER: tanzu-vc01.tanzu.lab
VSPHERE_SSH_AUTHORIZED_KEY: ssh-rsa AAAAB3[...]]qaO79UQ== email@example.com
VSPHERE_TLS_THUMBPRINT: ""
VSPHERE_USERNAME: administrator@vsphere.local
TKG_CUSTOM_IMAGE_REPOSITORY: registry.tanzu.lab/tkg154
TKG_CUSTOM_IMAGE_REPOSITORY_SKIP_TLS_VERIFY: 'False'
TKG_CUSTOM_IMAGE_REPOSITORY_CA_CERTIFICATE: LS0t[...]tLS0tLQ==
```

Cluster creation roughly takes 15-20 minutes to complete. Verify the health of the cluster by running the tanzu cluster list command.

![](img/tkg-airgap-nsxt/tkg-clusters-list.jpg)

As per the architecture, workload clusters make use of a separate SE group `tkg-workload-seg` and VIP Network `tkg-workload-vip-ls` for application load balancing. This can be controlled by creating a new **AKODeploymentConfig**. For more details refer to the next section.

### **Configure NSX Advanced Load Balancer in TKG Workload Cluster**

Tanzu Kubernetes Grid v1.5.4 management clusters with NSX Advanced Load Balancer are deployed with 2 default AKODeploymentConfigs. 

1. Install-ako-for-management-cluster: default config for management cluster
1. Install-ako-for-all:  default config for all TKG clusters. By default, any clusters that match the cluster labels defined in install-ako-for-all will reference this file for their virtual IP networks, service engine (SE) groups, and L7 ingress. As part of our architecture, only the shared service cluster makes use of the configuration defined in the default AKODeploymentConfig “install-ako-for-all”

As per the defined architecture, workload clusters must **not** make **use** of Service Engine Group `tkg-mgmt-seg` and VIP Network `tkg-cluster-vip-ls` for application load balancer services.

These configurations can be enforced on workload clusters by

- Creating a new AKODeploymentConfig in the TKG management cluster. This AKODeploymentConfig file dictates which specific SE group and VIP network the workload clusters can use for load balancer functionalities  

- Apply the new AKODeploymentConfig:  Label the workload cluster to match the AKODeploymentConfig.spec.clusterSelector.matchLabels element in the AKODeploymentConfig file. 
  Once the labels are applied to the workload cluster, the TKG management cluster will deploy the AKO pod on the target workload cluster which has the configuration defined in the new AKODeploymentConfig 

Below is the format of the AKODeploymentConfig yaml file. 

```yaml
apiVersion: networking.tkg.tanzu.vmware.com/v1alpha1
kind: AKODeploymentConfig
metadata:
  generation: 1
  name: <Unique name of AKODeploymentConfig>
spec:
  adminCredentialRef:
    name: avi-controller-credentials
    namespace: tkg-system-networking
  certificateAuthorityRef:
    name: avi-controller-ca
    namespace: tkg-system-networking
  cloudName: <Cloud name in NSX ALB>
  clusterSelector:
    matchLabels:
      <KEY>: <VALUE>
  controlPlaneNetwork:
    cidr: <Workload Control Plane VIP Network CIDR>
    name: <Workload Control Plane VIP Network>
  controller: <NSX ALB CONTROLLER IP/FQDN>
  controllerVersion: <Controller Version>
  dataNetwork:
    cidr: <Workload VIP Network CIDR>
    name: <Workload VIP Network NAME>
  extraConfigs:
    cniPlugin: antrea
    disableStaticRouteSync: true
    ingress:
      defaultIngressController: true
      disableIngressClass: false
    l4Config:
      autoFQDN: disabled
    layer7Only: false
    networksConfig: {}
  serviceEngineGroup: <Service Engine Group Name>
```

The following is a sample AKODeploymentConfig file with sample values in place. In this example, the Tanzu Kubernetes Grid management cluster will deploy AKO pod on any workload cluster that matches the label **type=workload**. The AKO configuration will be as follows:

- cloud: tkg-vsphere​
- service engine Group: tkg-workload-seg
- VIP/data network: tkg-workload-vip-ls

```yaml
apiVersion: networking.tkg.tanzu.vmware.com/v1alpha1
kind: AKODeploymentConfig
metadata:
  generation: 1
  name: adc-workload
spec:
  adminCredentialRef:
    name: avi-controller-credentials
    namespace: tkg-system-networking
  certificateAuthorityRef:
    name: avi-controller-ca
    namespace: tkg-system-networking
  cloudName: tkg-vsphere
  clusterSelector:
    matchLabels:
      type: workload
  controlPlaneNetwork:
    cidr: 172.19.75.0/26
    name: tkg-cluster-vip-ls
  controller: alb.vstellar.local
  controllerVersion: 21.1.3
  dataNetwork:
    cidr: 172.19.76.0/26
    name: tkg-workload-vip-ls
  extraConfigs:
    cniPlugin: antrea
    disableStaticRouteSync: true
    ingress:
      defaultIngressController: true
      disableIngressClass: false
    l4Config:
      autoFQDN: disabled
    layer7Only: false
    networksConfig: {}
  serviceEngineGroup: tkg-workload-seg
```

Once you have the AKO configuration file ready, use the kubectl command to set the context to the TKG management cluster and use the below command to create AKODeploymentConfig for the workload cluster.

```bash
kubectl apply -f <path_to_akodeploymentconfig.yaml>
```

Use the below command to list all AKODeploymentConfig created under management cluster

```bash
kubectl get akodeploymentconfig
```

![](img/tkg-airgap-nsxt/tkg-adc.jpg)

Now that you have successfully created the AKO deployment config, you need to apply the cluster labels defined in the AKODeploymentConfig to any of the TKG workload clusters, once the labels are applied, AKO operator running in the TKG management cluster will deploy AKO pod on the target workload cluster.

```bash
kubectl label cluster <cluster Name> <label>
```

### Connect to TKG Workload Cluster and validate the deployment

Now that you have the TKG workload cluster created and required AKO configurations are applied, use the below command to get the admin context of the TKG workload cluster. 

```bash
tanzu cluster kubeconfig get <cluster-name> --admin

Kubectl config use-context <workload cluster context>
```

Run the following commands to check the status of AKO and other components

```bash
kubectl get nodes                ## List all nodes with status
kubectl get pods -n avi-system   ## To check the status of AKO pod
kubectl get pods -A              ## Lists all pods and it’s status
```

![](img/tkg-airgap-nsxt/workload-cluster-pods.jpg)

You can see that the workload cluster is successfully deployed and AKO pod is deployed on the cluster. You can now deploy user-managed packages on this cluster.

# <a id=deploy-packages> </a> Deploy User-Managed Packages

user-managed packages are installed after workload cluster creation. These packages extend the core functionality of Kubernetes clusters created by Tanzu Kubernetes Grid. 

Tanzu Kubernetes Grid includes the following user-managed packages. These packages provide in-cluster and shared services to the Kubernetes clusters that are running in your Tanzu Kubernetes Grid environment.

|**Function**|**Package**|**Location**|
| :- | :- | :- |
|Certificate Management|cert-manager|Workload and shared services cluster|
|Container networking|multus-cni|Workload cluster|
|Container registry|harbor|Shared services cluster|
|Ingress control|contour|Workload and shared services cluster|
|Log forwarding|fluent-bit|Workload cluster|
|Monitoring|Grafana<br>Prometheus|Workload cluster|

user-managed packages can be installed via CLI by invoking the `tanzu package install` command. Before installing the user-managed packages, ensure that you have switched to the context of the cluster where you want to install the packages.

Also, ensure that the tanzu-standard repository is configured on the cluster where you want to install the packages. By default, the newly deployed clusters should have the tanzu-standard repository configured.

You can run the command `tanzu package repository list -n tanzu-package-repo-global` to verify this. Also, ensure that the repository status is "Reconcile succeeded".

![](img/tkg-airgap-nsxt/package-repository-list.jpg)

## Install cert-manager

The first package that you should install on your cluster is the [**cert-manager**](https://github.com/cert-manager/cert-manager) package which adds certificates and certificate issuers as resource types in Kubernetes clusters and simplifies the process of obtaining, renewing and using those certificates.

1: Capture the available cert-manager version

```bash
tanzu package available list cert-manager.tanzu.vmware.com -n tanzu-package-repo-global
```

![](img/tkg-airgap-nsxt/cert-manager-list.jpg)

2: Install cert-manager package

Capture the latest version from the previous command, if there are multiple versions available check the "RELEASED-AT" to collect the version of the latest one. This document make use of version 1.5.3+vmware.2-tkg.1 for installation.

The command to install cert-manager is shown below

```bash
tanzu package install cert-manager --package-name cert-manager.tanzu.vmware.com --namespace package-cert-manager --version <AVAILABLE-PACKAGE-VERSION> --create-namespace
 
Example: tanzu package install cert-manager --package-name cert-manager.tanzu.vmware.com --namespace cert-manager --version 1.5.3+vmware.2-tkg.1 --create-namespace
```

3: Confirm that the cert-manager package has been installed successfully and the status is "Reconcile succeeded"

```bash
tanzu package installed get cert-manager -n cert-manager

### Output 

- Retrieving installation details for cert-manager

NAME:                    cert-manager
PACKAGE-NAME:            cert-manager.tanzu.vmware.com
PACKAGE-VERSION:         1.5.3+vmware.2-tkg.1
STATUS:                  Reconcile succeeded
CONDITIONS:              [{ReconcileSucceeded True  }]

```

## Install Contour

[Contour](https://projectcontour.io/) is an open-source Kubernetes ingress controller providing the control plane for the Envoy edge and service proxy.​ Tanzu Mission Control catalog includes signed binaries for Contour and Envoy, which you can deploy into Tanzu Kubernetes (workload) clusters to provide ingress control services in those clusters.

Package installation can be customized by entering the user-configurable values in yaml format. An example yaml for customizing contour installation is shown below.

```yaml
---
infrastructure_provider: vsphere
namespace: tanzu-system-ingress
contour:
 configFileContents: {}
 useProxyProtocol: false
 replicas: 2
 pspNames: "vmware-system-restricted"
 logLevel: info
envoy:
 service:
   type: LoadBalancer
   annotations: {}
   nodePorts:
     http: null
     https: null
   externalTrafficPolicy: Cluster
   disableWait: false
 hostPorts:
   enable: true
   http: 80
   https: 443
 hostNetwork: false
 terminationGracePeriodSeconds: 300
 logLevel: info
 pspNames: null
certificates:
 duration: 8760h
 renewBefore: 360h
```

For a full list of user-configurable values, please see contour official [documentation](https://docs.vmware.com/en/VMware-vSphere/7.0/vmware-vsphere-with-tanzu/GUID-A1288362-61F7-46D9-AB42-1A5711AB4B57.html#GUID-A1288362-61F7-46D9-AB42-1A5711AB4B57__GUID-3E4520E4-6D20-4D27-8772-E4A9817EBAA8)

1: Capture the available contour version

```bash
tanzu package available list contour.tanzu.vmware.com -n tanzu-package-repo-global
```

![](img/tkg-airgap-nsxt/contour-package-list.jpg)

Capture the latest version from the previous command. If there are multiple versions available check the "RELEASED-AT" to collect the version of the latest one. This document make use of version 1.18.2+vmware.1-tkg.1 for installation.

2: Install the Contour Package

```bash
tanzu package install contour --package-name contour.tanzu.vmware.com --version <AVAILABLE-PACKAGE-VERSION> --values-file <Path_to_contour-data-values.yaml_file> --namespace tanzu-system-contour --create-namespace
 
Example: tanzu package install contour --package-name contour.tanzu.vmware.com --version 1.18.2+vmware.1-tkg.1 --values-file ./contour-data-values.yaml --namespace tanzu-system-ingress --create-namespace
```

3: Confirm that the contour package has been installed and the status is "Reconcile succeeded".

```bash
tanzu package installed get contour --namespace tanzu-system-ingress

### output

- Retrieving installation details for contour

NAME:                    contour
PACKAGE-NAME:            contour.tanzu.vmware.com
PACKAGE-VERSION:         1.18.2+vmware.1-tkg.1
STATUS:                  Reconcile succeeded
CONDITIONS:              [{ReconcileSucceeded True  }]
```

### **Install Harbor**

[Harbor](https://goharbor.io/) is an open-source container registry. Harbor Registry may be used as a private registry for container images that you want to deploy to Tanzu Kubernetes clusters.

Tanzu Kubernetes Grid includes signed binaries for Harbor, which you can deploy into:

- A workload cluster to provide container registry services for that clusters
- A shared services cluster to provide container registry services for other Tanzu Kubernetes (workload) clusters.

When deployed as a shared service, Harbor is available to all of the workload clusters in a given Tanzu Kubernetes Grid instance.

Follow this procedure to deploy Harbor into a workload cluster or a shared services cluster.

1: Confirm that the Harbor package is available in the cluster and retrieve the version of the available package.

```bash
tanzu package available list harbor.tanzu.vmware.com -A
```

![](img/tkg-airgap-nsxt/harbor-package-list.jpg)

2: Create a configuration file named harbor-data-values.yaml by executing the following commands:

```bash
image_url=$(kubectl -n tanzu-package-repo-global get packages harbor.tanzu.vmware.com.2.3.3+vmware.1-tkg.1 -o jsonpath='{.spec.template.spec.fetch[0].imgpkgBundle.image}')
 
imgpkg pull -b $image_url -o /tmp/harbor-package

cp /tmp/harbor-package/config/values.yaml harbor-data-values.yaml
```

3: Set the mandatory passwords and secrets in the harbor-data-values.yaml file

```bash
bash /tmp/harbor-package/config/scripts/generate-passwords.sh harbor-data-values.yaml
```

4: Edit the harbor-data-values.yaml file and configure the values for the following mandatory parameters. 

- namespace
- port
- harborAdminPassword
- secretKey

Other parameters' values can be changed to meet the deployment's requirements.. For the full list of the user-configurable values, please refer to the product [documentation](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.5/vmware-tanzu-kubernetes-grid-15/GUID-packages-harbor-registry.html#deploy-harbor-into-a-cluster-5).

5: Remove the comments in the harbor-data-values.yaml file

```bash
yq -i eval '... comments=""' harbor-data-values.yaml
```

6: Install the harbor package by executing the following command

```bash
tanzu package install harbor --package-name harbor.tanzu.vmware.com --version 2.3.3+vmware.1-tkg.1 --values-file ./harbor-data-values.yaml --namespace tanzu-system-registry --create-namespace
```

7. Confirm that the harbor package has been installed and the status is "Reconcile succeeded".

```bash
tanzu package installed get harbor --namespace tanzu-system-registry

- Retrieving installation details for harbor

NAME:                    harbor
PACKAGE-NAME:            harbor.tanzu.vmware.com
PACKAGE-VERSION:         2.3.3+vmware.1-tkg.1
STATUS:                  Reconcile succeeded
CONDITIONS:              [{ReconcileSucceeded True  }]
```

## Install Prometheus

[Prometheus](https://prometheus.io/) is a system and service monitoring system. It collects metrics from configured targets at given intervals, evaluates rule expressions, displays the results, and can trigger alerts if some condition is observed to be true. Alertmanager handles alerts generated by Prometheus and routes them to their receiving endpoints.

Follow this procedure to deploy Prometheus into a workload cluster.

1:  Capture the available Prometheus version

```bash
tanzu package available list prometheus.tanzu.vmware.com -n tanzu-package-repo-global
```

![](img/tkg-airgap-nsxt/prometheus-list.jpg)

Capture the latest version from the previous command. If there are multiple versions available check the "RELEASED-AT" to collect the version of the latest one. This document make use of version  2.27.0+vmware.2-tkg.1 for installation.

2: Retrieve the template of the Prometheus package’s default configuration:

```bash
image_url=$(kubectl -n tanzu-package-repo-global get packages prometheus.tanzu.vmware.com.2.27.0+vmware.1-tkg.1 -o jsonpath='{.spec.template.spec.fetch[0].imgpkgBundle.image}')

imgpkg pull -b $image_url -o /tmp/prometheus-package-2.27.0+vmware.1-tkg.1

cp /tmp/prometheus-package-2.27.0+vmware.1-tkg.1/config/values.yaml prometheus-data-values.yaml
```

This creates a configuration file named prometheus-data-values.yaml that you can modify.

3: To customize the Prometheus installation, modify the below values.

|**Key**|**Default Value**|**Modified value**|
| :- | :- | :- |
|Ingress.tlsCertificate.tls.crt|Null|<p><Full chain cert provided in Input file></p><p></p><p>Note: This is optional.</p>|
|ingress.tlsCertificate.tls.key|Null|<p><Cert Key provided in Input file</p><p></p><p>Note: This is optional.</p>|
|ingress.enabled|false|true|
|ingress.virtual\_host\_fqdn|prometheus.system.tanzu|prometheus.<your-domain>|

To see a full list of user configurable configuration parameters, see [Prometheus Package Configuration Parameters](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.5/vmware-tanzu-kubernetes-grid-15/GUID-packages-prometheus.html#config-table).

4: After you make any changes needed to your prometheus-data-values.yaml file, remove all comments in it:

```bash
yq -i eval '... comments=""' prometheus-data-values.yaml
```

5: Install Prometheus package

```bash
tanzu package install prometheus --package-name prometheus.tanzu.vmware.com --version 2.27.0+vmware.2-tkg.1 --values-file ./prometheus-data-values.yaml --namespace tanzu-system-monitoring --create-namespace
```

6: Confirm that the Prometheus package has been installed successfully and the status is "Reconcile succeeded"

```bash
tanzu package installed get prometheus -n tanzu-system-monitoring

- Retrieving installation details for prometheus

NAME:                    prometheus
PACKAGE-NAME:            prometheus.tanzu.vmware.com
PACKAGE-VERSION:         2.27.0+vmware.2-tkg.1
STATUS:                  Reconcile succeeded
CONDITIONS:              [{ReconcileSucceeded True  }]
```

### **Install Grafana**

[Grafana](https://grafana.com/) allows you to query, visualize, alert on, and explore metrics no matter where they are stored. Grafana provides tools to form graphs and visualizations from application data. 

**Note:** Grafana is configured with Prometheus as a default data source. If you have customized the Prometheus deployment namespace and it is not deployed in the default namespace, **tanzu-system-monitoring**, you need to change the Grafana datasource configuration in the code shown below.

1: Retrieve the version of the available package

```bash
tanzu package available list grafana.tanzu.vmware.com -A
```

![](img/tkg-airgap-nsxt/grafana-package-list.jpg)

Capture the latest version from the previous command. If there are multiple versions available check the "RELEASED-AT" to collect the version of the latest one. This document make use of version 7.5.7+vmware.2-tkg.1 for installation.

2: Retrieve the template of the Grafana package’s default configuration.

```bash
image_url=$(kubectl -n tanzu-package-repo-global get packages grafana.tanzu.vmware.com.7.5.7+vmware.2-tkg.1 -o jsonpath='{.spec.template.spec.fetch[0].imgpkgBundle.image}')

imgpkg pull -b $image_url -o /tmp/grafana-package-7.5.7+vmware.2-tkg.1

cp /tmp/grafana-package-7.5.7+vmware.2-tkg.1/config/values.yaml grafana-data-values.yaml
```

This creates a configuration file named grafana-data-values.yaml that you can modify. For a full list of user-configurable values, please see official [Grafana Package Configuration Parameters](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.5/vmware-tanzu-kubernetes-grid-15/GUID-packages-grafana.html#grafana-package-configuration-parameters-5)

4: Edit grafana-data-values.yaml and replace the following with your custom values.

|**Key**|**Default Value**|**Modified value**|
| :- | :- | :- |
|virtual\_host\_fqdn|grafana.system.tanzu|grafana.<your-domain>|
|secret.admin\_password|Null|Your password in Base64 encoded format.|

5: (Otional) Modify the Grafana datasource configuration 

Grafana is configured with Prometheus as a default data source. If you have customized the Prometheus deployment namespace and it is not deployed in the default namespace, tanzu-system-monitoring, you need to change the Grafana datasource configuration in grafana-data-values.yaml.

```yaml
datasources:
        - name: Prometheus
          type: prometheus
          url: prometheus-server.<change-to-prometheus-namespace>.svc.cluster.local
```

6: Remove all comments from grafana-data-values.yaml file

```bash
yq -i eval '... comments=""' grafana-data-values.yaml
```

7: Install Grafana package

```bash
tanzu package install grafana --package-name grafana.tanzu.vmware.com --version 7.5.7+vmware.2-tkg.1 --values-file grafana-data-values.yaml --namespace tanzu-system-dashboards --create-namespace
```

8: Confirm that the Grafana package has been installed and the status is "Reconcile succeeded".

```bash
tanzu package installed get grafana -n tanzu-system-dashboards

- Retrieving installation details for grafana

NAME:                    grafana
PACKAGE-NAME:            grafana.tanzu.vmware.com
PACKAGE-VERSION:         7.5.7+vmware.2-tkg.1
STATUS:                  Reconcile succeeded
CONDITIONS:              [{ReconcileSucceeded True  }]
```

## Install Fluent-Bit

[Fluent Bit](https://fluentbit.io/) is a lightweight log processor and forwarder that allows you to collect data and logs from different sources, unify them, and send them to multiple destinations.

The current release of Fluent Bit allows you to gather logs from management clusters or Tanzu Kubernetes clusters running in vSphere, Amazon EC2, and Azure. You can then forward them to a log storage provider such as [Elastic Search](https://www.elastic.co/), [Kafka](https://www.confluent.io/confluent-operator/), [Splunk](https://www.splunk.com/), or an HTTP endpoint. 

The example shown in this document uses HTTP endpoint ([vRealize Log Insight Cloud](https://docs.vmware.com/en/VMware-vRealize-Log-Insight-Cloud/index.html)) for forwarding logs from Tanzu Kubernetes clusters.

1: Retrieve the version of the available package

```bash
tanzu package available list fluent-bit.tanzu.vmware.com -A
```

![](img/tkg-airgap-nsxt/fluent-bit-package-list.jpg)

Capture the latest version from the previous command. If there are multiple versions available check the "RELEASED-AT" to collect the version of the latest one. This document make use of version 1.7.5+vmware.2-tkg.1 for installation.

2:  Retrieve the template of the FluentBit package’s default configuration.

```bash
image_url=$(kubectl -n tanzu-package-repo-global get packages fluent-bit.tanzu.vmware.com.1.7.5+vmware.2-tkg.1 -o jsonpath='{.spec.template.spec.fetch[0].imgpkgBundle.image}')

imgpkg pull -b $image_url -o /tmp/fluent-bit-1.7.5+vmware.2-tkg.1

cp /tmp/fluent-bit-1.7.5+vmware.2-tkg.1/config/values.yaml fluentbit-data-values.yaml
```

3: Modify the resulting fluentbit-data-values.yaml file and configure the endpoint as per your choice. A sample endpoint configuration for sending logs to vRealize Log Insight Cloud over http is shown below for the reference.

```bash
outputs: |
      [OUTPUT]
        Name            http
        Match           *
        Host            data.mgmt.cloud.vmware.com
        Port            443
        URI             /le-mans/v1/streams/ingestion-pipeline-stream
        Header          Authorization Bearer Sl0dzovlCKArhgyGdbvC8M9C7tfvT9Y5
        Format          json
        tls             On
        tls.verify      off
```

4: Deploy Fluent-Bit package

```bash
tanzu package install fluent-bit --package-name fluent-bit.tanzu.vmware.com --version 1.7.5+vmware.2-tkg.1 --namespace tanzu-system-logging --create-namespace
```

5: Confirm that the Fluent-Bit package has been installed and the status is "Reconcile succeeded".

```bash
tanzu package installed get fluent-bit -n tanzu-system-logging

- Retrieving installation details for fluent-bit

NAME:                    fluent-bit
PACKAGE-NAME:            fluent-bit.tanzu.vmware.com
PACKAGE-VERSION:         1.7.5+vmware.2-tkg.1
STATUS:                  Reconcile succeeded
CONDITIONS:              [{ReconcileSucceeded True  }]
```

# <a id=supplemental-information> </a> Appendix 

## Appendix A - Management Cluster Configuration File

```yaml
AVI_CA_DATA_B64: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUM0RENDQWNpZ0F3SUJBZ0lVWDNvVVFaOXMzSFlwZkluWERmSWFWdDlaKzU0d0RRWUpLb1pJaHZjTkFRRUwKQlFBd0dERVdNQlFHQTFVRUF3d05ZV3hpTG5SaGJucDFMbXhoWWpBZUZ3MHlNakE0TURReE5qTXpNamRhRncweQpNekE0TURReE5qTXpNamRhTUJneEZqQVVCZ05WQkFNTURXRnNZaTUwWVc1NmRTNXNZV0l3Z2dFaU1BMEdDU3FHClNJYjNEUUVCQVFVQUE0SUJEd0F3Z2dFS0FvSUJBUUROQ2VEVVcxMGYyN3U0OERQVERHQ0Z5Qnp5RVNIaElVcm4KbXJ0VWJvNWNrRnpSVWp1VVJWSlFjYnM3b1VLTVRrazBLam5TbDE1bkdtTGNnVzQ2ZnY0ZWtGT0lYN0VZNzZUegoraFovL2djanMzSHY0cFk2NlFJV1BoSmhpb0MxdktQYy9FTkZTUnlqd1Y2SkJJRENEcjViY3RwYkNvMnFpNHJnCnhMNkJIc3Fxb0JKc2xJNk9qT3RsZnl1RmVpVTZGU0VldGdlRzB2VENzNHZuTUE2dDYvV3VydkgvWXRZQ0RMazYKQldXaHRYMVRSVHdPamhBUFBBalEvMDcvSWdtMkh4RU9YRTdRYXZFbkFFVWdzTmhBZVhZdzlJSTF6d2p5T1AwKwp3TDhJSzV2ZWEzOFFmMDVqdnZGMFVjbUtBNHRBN2hYd09mRmY3aWRXR2tKY0Iva2pBekdQQWdNQkFBR2pJakFnCk1CNEdBMVVkRVFRWE1CV0NEV0ZzWWk1MFlXNTZkUzVzWVdLSEJLd1RSd0l3RFFZSktvWklodmNOQVFFTEJRQUQKZ2dFQkFFWThscWVhLzQ0UlA3SS9UTXRHcHllWXVNb3FoVkRtYjh0c3ROdXBPY295ZS9kVUxVbzVpM0hteFhCegpBNjczOVdOT1dNTE9vWjlZc3BIdmdSNFlmZG45b3F1Rkp5QUNHRERGanRlK1JoOFlkUzhkK01FMElRSUkyT0Q4CnpubkcwL3dRNERrTzhqN0F5SlBRZlZlYVFvRkxSWDdWNkxlZ2lpYmxwYVFINmNZWjY1bW54RFlFeDFFTUlOZFYKT0VqQXd3d29hN3lDWUFwMDFBZXBJMzUvWTg3MlM5N3J1RmV1WjNvNHlzbU1DNWhiZG9QWWNzWUhoZzM1WldMTAp0TzF6d3Q2Sm5qNXdTTWVJTXNDZ2JxQy9Xbzk5WXIrTUt2R2xNazVKT0pYanFMS24xb0I1bzJDZXdGUGY0NVFrCkRsWDI1ajJ0YVNNN2dLemZZcnJhUkRVMlRzTT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQ==
AVI_CLOUD_NAME: tkg-vsphere
AVI_CONTROL_PLANE_HA_PROVIDER: "true"
AVI_CONTROLLER: alb.tanzu.lab
AVI_DATA_NETWORK: tkg-mgmt-vip-ls
AVI_DATA_NETWORK_CIDR: 172.19.74.0/26
AVI_ENABLE: "true"
AVI_LABELS: |
    'type': 'management'
AVI_MANAGEMENT_CLUSTER_VIP_NETWORK_CIDR: 172.19.75.0/26
AVI_MANAGEMENT_CLUSTER_VIP_NETWORK_NAME: tkg-cluster-vip-ls
AVI_PASSWORD: <encoded:Vk13YXJlMSE=>
AVI_SERVICE_ENGINE_GROUP: tkg-mgmt-seg
AVI_USERNAME: admin
AVI_CONTROLLER_VERSION: 21.1.3
CLUSTER_CIDR: 100.96.0.0/11
CLUSTER_NAME: tkg154-mgmt-airgap
CLUSTER_PLAN: prod
ENABLE_AUDIT_LOGGING: "true"
ENABLE_CEIP_PARTICIPATION: "false"
ENABLE_MHC: "true"
IDENTITY_MANAGEMENT_TYPE: none
INFRASTRUCTURE_PROVIDER: vsphere
DEPLOY_TKG_ON_VSPHERE7: true
OS_ARCH: amd64
OS_NAME: photon
OS_VERSION: "3"
SERVICE_CIDR: 100.64.0.0/13
TKG_HTTP_PROXY_ENABLED: "false"
TKG_IP_FAMILY: ipv4
VSPHERE_CONTROL_PLANE_DISK_GIB: "40"
VSPHERE_CONTROL_PLANE_ENDPOINT: ""
VSPHERE_CONTROL_PLANE_MEM_MIB: "8192"
VSPHERE_CONTROL_PLANE_NUM_CPUS: "2"
VSPHERE_DATACENTER: /Tanzu-DC
VSPHERE_DATASTORE: /Tanzu-DC/datastore/ds1/vsanDatastore
VSPHERE_FOLDER: /Tanzu-DC/vm/TKG-Mgmt-VMs
VSPHERE_INSECURE: "true"
VSPHERE_NETWORK: /Tanzu-DC/network/tkg-mgmt-ls
VSPHERE_PASSWORD: <encoded:Vk13YXJlMSE=>
VSPHERE_RESOURCE_POOL: /Tanzu-DC/host/Tanzu-CL01/Resources/TKG-Mgmt
VSPHERE_SERVER: tanzu-vc01.tanzu.lab
VSPHERE_SSH_AUTHORIZED_KEY: ssh-rsa AAAAB3NzaC[.....]o8O6gqaO79UQ== email@example.com
VSPHERE_TLS_THUMBPRINT: ""
VSPHERE_USERNAME: administrator@vsphere.local
VSPHERE_WORKER_DISK_GIB: "40"
VSPHERE_WORKER_MEM_MIB: "8192"
VSPHERE_WORKER_NUM_CPUS: "2"
CONTROL_PLANE_MACHINE_COUNT: "3"
WORKER_MACHINE_COUNT: "3"
TKG_CUSTOM_IMAGE_REPOSITORY: registry.tanzu.lab/tkg154
TKG_CUSTOM_IMAGE_REPOSITORY_SKIP_TLS_VERIFY: 'false'
TKG_CUSTOM_IMAGE_REPOSITORY_CA_CERTIFICATE: LS0t[...]tLS0tLQ==
```