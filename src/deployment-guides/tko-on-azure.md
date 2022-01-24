# Deploy Tanzu for Kubernetes Operations on Microsoft Azure
VMware Tanzu simplifies the operations of Kubernetes for multi-cloud deployments by centralizing management and governance for clusters and teams across on-premises, public clouds and the edge. It delivers an open source aligned Kubernetes distribution with consistent operations and management to support infrastructure and app modernization.

This document provides a step-by-step guide for how to install and deploy Tanzu Kubernetes for Operators within Microsoft Azure. This document will only walk-through the deployment of a base architecture that can be found within the TKO Reference Architecture for Azure which is a production level deployment.

**NOTE:** Additional Workload clusters and different size workload clusters can absolutely be deployed using this guide, but configuration changes will be needed near the end.

The scope of the document is limited to providing the deployment steps based on the reference design in [VMware Tanzu for Kubernetes Operations on Azure Reference Design](../reference-designs/tko-on-azure.md)

## Prerequisites
The instructions provided in this document assumes that you have the following setup:

* Microsoft Azure subscription
* Owner level access to Subscription

# Tanzu for Kubernetes Operations: Key Components
The following is a list of the components that comprise Tanzu for Kubernetes Operations:

* Tanzu Kubernetes Grid (TKG) - Enables creation and lifecycle management of Kubernetes clusters.
* Tanzu Mission Control (TMC) - A centralized management platform for consistently operating and securing Kubernetes infrastructure and modern applications across multiple teams and clouds, and allows for centralized policy management across all deployed and attached clusters.
* Tanzu Observability (TO) - Provides enterprise-grade observability and analytics at scale with granular controls, which allows to achieve higher levels of application health and availability for an overall improved end user experience
* Tanzu Service Mesh (TSM) - Provides end-to-end connectivity, continuity, resiliency, security, compliance, and observability for modern applications running in single and multi-cloud environments. Global Namespace can be used to leverage the power of the hybrid cloud.
* Tanzu User Managed Packages (Optional):
    - Contour Ingress Controller - Provides Layer 7 control to deployed HTTP(s) applications
    - Harbor Image Registry - Provides a centralized location to push, pull, store, and scan container images used in Kubernetes workloads. It also supports storing artifacts such as Helm charts and includes enterprise-grade features such as RBAC, retention policies, automated garbage collection of stale images, and DockerHub proxying among many other things
    - Fluent bit - Provides export log streaming of cluster & workload logs to a wide range of supported aggregators provided in the extensions package for TKG
    - Prometheus - Provides out-of-the-box health monitoring of Kubernetes clusters
    - Grafana - Provides monitoring dashboards for displaying key health metrics of Kubernetes clusters

Tanzu for Kubernetes Operations puts all these components together into a coherent solution.

# Tanzu Kubernetes Grid for Microsoft Azure

## Architecture Overview
Below, you will find an architecture diagram that is one of the two production-level reference architectures and it will be this architecture that will be deployed through the following set of steps. This architecture shows both the TKG Management Cluster and Workload clusters in the same Virtual Network along with the Bootstrap machine, but each cluster being placed in their own Subnets. In addition, the Control Plane and Worker Nodes of each cluster are also separated by Subnet.

![TKG on Azure (Single VNet)](img/tko-on-azure/image005.png)

ASSUMPTIONS

1. The above architecture only show the deployments of the base components within TKG.

2. The above architecture should fit into any production-level design that a customer may have in place, such as a Hub and Spoke, Global WAN Peering, or just a simple DMZ based implementation

3. No assumptions were made about a customer’s chosen tooling with respect to Security or DevOps other than what all customers have access to through their default Azure subscription as can be seen in the right-hand column of each architecture.

## Pre-deployment (Azure)
Using the architectures shown above, if you would like more information about the specific Azure components, please review the [Reference Architecture](../reference-designs/tko-on-azure.md) document to get a better understand of why each component is used.

Before we start doing anything with Tanzu to install the actual Kubernetes clusters, let’s make sure that we have everything in place within Azure. To make things easier, we have provided an example Azure ARM template. This template contains a number of parameters that you can fill-in to make your environment fit into your naming standards and fit into your networking requirements.

The ARM template will deploy the following items that are seen within the diagram above:

* Virtual Network
* 5 Subnets
    - Bootstrap
    - Management Cluster Control Plane (API Servers)
    - Management Cluster Worker Nodes
    - Workload Cluster Control Plane (API Servers)
    - Workload Cluster Worker Nodes
* Network Security Group for Bootstrap Machine NIC
* Network Security Groups for each of the Cluster Subnets
* Public IP Address attached to Bootstrap Machine
* Virtual Machine for Bootstrap (Ubuntu 20.0.4)

### Quotas
When deploying TKG to Azure you will need to make sure your quotas are sufficient to support both the Management Cluster and Workload Cluster deployments otherwise the deployments will fail. The following quotas will likely need to be increased from their default values. It is important to note that quota increases will be necessary in every region you plan to deploy TKG.

* Total Regional vCPUs
* Family vCPUs based on your chosen family of VM (D, E, F, etc.)
* Public IP Addresses - Basic
* Static Public IP Addresses
* Public IP Addresses - Standard

**NOTE:** For the subsequent discussion points about how to deploy an ARM Template with the necessary resources listed above, you can leverage the example [ARM Template](./resources/tko-on-azure/azure-deploy.json) and example [Parameters](./resources/tko-on-azure/azure-deploy.parameters.json) files provided within this repo.

### ARM Template Deployment
If you are already very knowledgeable with Azure, then please feel free to update the parameters file and then deploy the ARM template however is most comfortable for you. However, if you are inexperienced in Azure, then here is an example Azure CLI command that you can use either locally or within Azure Cloud Shell as well as an example Azure PowerShell command as well.

**NOTE:** You will need to have a Resource Group already created before you run these commands. In addition, this template should be run by someone with the “Contributor” role.

#### Azure CLI
```bash
az deployment create –template-file azure-deploy.json –parameters azure-deploy.parameters.json –resource-group <Resource Group Name>
```

#### Azure Powershell
```bash
New-AzResourceGroupDeployment -ResourceGroupName <Resource Group Name> -TemplateFile azure-deploy.json -TemplateParameterFile azure-deploy.parameters.json
```

#### Azure Portal
If you are more comfortable with the Azure Portal, then it is possible to process an ARM template directly within the Azure Portal.

Step 1: Search and click on “Deploy a Custom Template”
![Custom Deployment](img/tko-on-azure/CustomDeployment.png)

Make sure to click on the “Build your own template in the editor” link within the Custom Deployment screen shown above. This will take you to the next screen where you can upload the ARM template (azuredeploy.json)

Step 2 Upload `azuredeploy.json` to be processed
![Load File](img/tko-on-azure/LoadFile.png)

The last task is to fill in all of the parameters to make sure that everything is specific to your deployment, naming, and network standards.

Step 3: Fill in Parameter Values
![Provide Parameter Values](img/tko-on-azure/Parameters.png)

**IMPORTANT**

* The ARM template provided uses the Region where the Resource Group is located to specify where the resources should be deployed.
* The ARM template contains security rules for each of the Network Security Groups attached to the Control Plane clusters. These rules allow for SSH and Secure Kubectl access from the Public Internet. This was done to allow for Troubleshooting to be done during the Management and Workload cluster deployments. Please feel free to remove these rules once your deployment is complete.

### Azure Service Principal/App Registration Creation
The Tanzu CLI requires access to an Azure Service Principal (SP) or Application Registration which can be used for programmatic manipulation of the Tanzu cluster’s infrastructure both during deployment and during auto-scale events. If you have the ability and access to create the SP yourself, then it is recommended that you do so using the Azure Portal. However, if you would like to do it using either the Azure CLI or Powershell, links to the corresponding Azure docs for each can be found below.

**IMPORTANT:** The creation of an Azure Service Principal or Application Registration you will either need to be an “Administrator” within your Azure Active Directory tenant or the “App Registrations” setting will need to be set to “Yes” to allow all Users to create Service Principals.

* [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli)
* [Azure PowerShell](https://docs.microsoft.com/en-us/powershell/azure/create-azure-service-principal-azureps?view=azps-6.6.0)

#### Portal UI

Step 1: Azure Active Directory -> Application Registrations
![Azure Active Directory Application Registrations](img/tko-on-azure/AADAppReg.png)

Step 2: New App Registration
![New Application Registration](img/tko-on-azure/NewReg.png)

There are only two fields that are required for a new App Registration:

* Name – Name should be reflective of what the App Registration is being used for. (i.e. tanzucli)
* URL – When the App Registration is only be used for programmatic purposes like here, the URL can be anything, but the field is required.

However, the third field, Supported Account Type will automatically select that the new App Registration will only be used for a Single Azure Active Directory tenant and for development clusters, this should be sufficient. Depending on the size of the organization that Tanzu is being deployed within, the App Registration may need to be available across one-to-many Azure Active Directory tenants, so choose which ever is needed for this deployment.

Step 3: Fill Out App. Registration Fields
![Fill Out Application Registration Fields](img/tko-on-azure/AppRegFields.png)

Once the App Registration, has been created, an Overview page will appear providing you with two important pieces of information that you will need when actually running the Tanzu CLI, Application Client ID and the Azure Active Directory tenant ID.

![Application Registration Overview](img/tko-on-azure/AppRegInfo.png)
<div align="center">Figure 4: Application Registration Information</div>

Make sure to grab the Application Client ID and Tenant ID from the Overview page once the Application Registration (SP) has been created. These are needed for the use of the Tanzu CLI.

Before you can leverage this new App Registration, you will need to create a Password/Key that can be used during programmatic authentication and execution. Start by clicking on the Certificates and Secrets area of the Application Registration navigation and choose the “Client Secrets” tab.

Step 4: Add a Key to an Application Registration
![Add Application Registration Key](img/tko-on-azure/AppRegSecret.png)

Choose the expiration date and then make sure to store the randomly generated Key so that it can be used later.

After completing the Azure SP creation process, make sure to assign the “VM Contributor” and “Network Contributor” roles to this SP. These two roles provide the minimum level of permissions required for the Tanzu CLI to function properly within Azure.

This should be done through the Subscription scope, but it can also be done at the Resource Group scope depending on your security boundaries. Find your specific Subscription within the Azure Portal and click on the “Access Control (IAM)” navigation item and then click on the “Roles” tab.

Step 5: Click on “Access Control/IAM” navigation
![Subscription Scoped Identity Access Management(IAM)](img/tko-on-azure/SubscriptionIAM.png)

Once you are on the Roles page, you will need to perform each of the Role Assignments individually, one for the “Network Contributor” and one for the “VM Contributor”. Once you have selected the specific role that you will be adding, do a quick search for the Name of the App Registration that you created above.

Step 6: Assign Roles to the App Registrations
![Assign a Role to Application Registration](img/tko-on-azure/RoleAssign.png)

In the screen above, make sure that the “User, group, or service principal” radio button is selected and then when the “Select Members” screen appears as you can see on the right side of the image, search for your new SP based on the name that you gave it.

IMPORTANT: To assign a role to the SP, you will need to have either the “Owner” role or “User Access Administration” role within the scope of the Azure subscription.

Once you are finished creating your Application Registration/Service Principal, make sure that you have gathered the following pieces of information as they will be needed when putting together the configuration files for the Tanzu CLI and needed during the Bootstrap machine setup:

* Azure Subscription ID
* Azure Active Directory Tenant ID
* Azure Application ID (ServicePrincipal)
* Azure Application Key

### Pre-Deployment (Bootstrap)
Now that the Azure Architecture is in place, we need to get all of the correct components installed within the Bootstrap VM as this VM will be used to deploy both the Management and first Workload Cluster for TKG. To make this happen, you will need to create an Application Registration or Service Principal within Azure Active Directory. I would recommend doing this within the Azure Portal, but it can be done using the Azure CLI as well. 

Once you have verified that the VM is up and running, connect to the VM through a standard SSH connection. The Bootstrap machine will need to have some updates and installs done on it before we can start to deploy the clusters. It should have the following deployed within before you run the Tanzu CLI can be used:

* Docker
* Azure CLI
* Tanzu CLI
* Tanzu Kubectl

Using the below Shell commands, you will be able to handle all of the items listed above. The six variables at the top will need to be filled in before running all of the commands. The first two variables are required for access to the VMWare Customer Connect portal, which is used for downloading the required Tanzu components. Just put in your email address and password that can successfully login to the Customer Connect Portal.

**NOTE:** If you would like to validate your Customer Connect authentication or view the available downloads for Tanzu Kubernetes Grid, please check the following URL: [https://customerconnect.vmware.com/en/downloads/details?downloadGroup=TKG-140&productId=988&rPId=73652](https://customerconnect.vmware.com/en/downloads/details?downloadGroup=TKG-140&productId=988&rPId=73652)

The remaining variables are all tied to the Azure subscription that you are deploying Tanzu into. The first will be a GUID for your Azure Active Directory Tenant and the next one is the GUID for the Subscription where all the resources were created from the ARM Template above. The last two items are tied to the Client ID and Secret Key that you created above for your Application Registration/Service Principal.

<!-- cSpell:disable -->
```bash
# Variables
export VMWUSER = "<CUSTOMER_CONNECT_USERID>"
export VMWPASS = "<CUSTOMER_CONNECT_PWD>"
export AZURETENANTID = "<AAD Tenant ID>"
export AZURESUBSCRIPTION = "<Subscription GUID>"
export AZURECLIENTID = "<Service Principal ID>"
export AZURECLIENTSECRET = "<Service Principal Secret>"

sudo apt-get update
sudo apt-get upgrade

# Docker Install & Verify
sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io

sudo groupadd docker
sudo usermod -aG docker $USER

# Optional Verification
# docker run hello-world

# Downloading and Installing Tanzu CLI
git clone https://github.com/z4ce/vmw-cli
curl -o tmc 'https://tmc-cli.s3-us-west-2.amazonaws.com/tmc/0.4.0-fdabbe74/linux/x64/tmc'
./vmw-cli/vmw-cli ls vmware_tanzu_kubernetes_grid
./vmw-cli/vmw-cli cp tanzu-cli-bundle-linux-amd64.tar
./vmw-cli/vmw-cli cp kubectl-linux-v1.21.2+vmware.1.gz

tar -xvf tanzu-cli-bundle-linux-amd64.tar
gzip -d kubectl-linux-v1.21.2+vmware.1.gz

sudo install cli/core/v1.4.0/tanzu-core-linux_amd64 /usr/local/bin/tanzu
tanzu plugin install --local cli all
sudo install kubectl-linux-v1.21.2+vmware.1 /usr/local/bin/kubectl

# Azure CLI Install and VM Acceptance
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

az login --service-principal --username $AZURECLIENTID --password $AZURECLIENTSECRET --tenant $AZURETENANTID
az vm image terms accept --publisher vmware-inc --offer tkg-capi --plan k8s-1dot21dot2-ubuntu-2004 --subscription $AZURESUBSCRIPTION
```
<!-- cSpell:enable -->

**NOTE:** Please be aware, that because of permission issues, you will need to logout/login to the Bootstrap machine between the installation of Docker and the Download and Install of the Tanzu components. Example script files can be found [here](./resources/tko-on-azure/bootstrapsetup.sh) and [here](./resources/tko-on-azure/bootstraptanzu.sh) if you would like to start here rather than doing a copy/paste.

### Deployment (TKG)
The last piece of a TKG deployment is to leverage the installed Tanzu CLI to deploy both a Management Cluster and Workload Cluster into the deployed Azure infrastructure that was deployed at the beginning. To make this possible, you will need to have a YAML config file that tells the CLI where the clusters will be deployed with respect to your Azure infrastructure. A complete example config file with all available values for an Azure deployment can be downloaded from [here](./resources/tko-on-azure/ex-config.yaml)

**IMPORTANT:** Please be aware that you will need to create an SSH key so that you can pass the necessary Base 64 encoded value of the public key within the AZURE_SSH_PUBLIC_KEY_B64 parameter of the configuration file. How you generate your SSH key and how you then encode the entire Public key is up to you, but you will need to encode it before storing it within configuration file.

If you would like a more detailed walk-through of how to create your config file and what each value corresponds to in Azure, please see the Tanzu documentation for this topic, which can be found [here](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.4/vmware-tanzu-kubernetes-grid-14/GUID-mgmt-clusters-config-azure.html).

Once you have put in all of the values that are going to be relevant to your deployment within your respective config files, you will need to run the following commands from your Bootstrap VM.

```bash
tanzu management-cluster create --file config.yaml -v 0-9

tanzu cluster create –file config.yaml -v 0-9
```

### Configure SaaS Services (TMC, TO, TSM)
The last deployment requirement for a TKO implementation is to connect your TKG Workload Cluster to the different SaaS services: Tanzu Mission (TMC), Tanzu Observabililty (TO), and Tanzu Service Mesh (TSM). The preferred method for this, would be to use the TMC Console and corresponding TO and TSM Consoles as well, because there is a lot of information that flows back and forth between these systems for integration purposes.

The following VMware SaaS services provide additional Kubernetes lifecycle management, observability, and service mesh features.

* Tanzu Mission Control (TMC)
* Tanzu Observability (TO)
* Tanzu Service Mesh (TSM)

For configuration information, see [Configure SaaS Services](./tko-saas-services.md).

**NOTE:** Optional scripting options for connecting the SaaS services will be available in the future and found directly within the [bootstraptanzu.sh](./resources/tko-on-azure/bootstraptanzu.sh)

### (OPTIONAL) Deploy Packages
Once your clusters have been deployed, you may want to deploy some of the available out-of-the-box packages that come with Tanzu. Most of them will not be needed because of the existence of the SaaS services that are part of TKO, but for those functions and features that are not part of the TKO bundle, here are some steps for how to deploy packages such as Harbor or Pinniped. These packages are available for deployment within each Workload Cluster that you deploy, but they are not actually installed and working as Pods within the cluster until you perform the steps below.

**NOTE:** Please keep in mind that any cluster can be used to run the available packages. For the purposes of this document, we will use the name "Shared Services Cluster" to denote the cluster where these packages are to be installed.

#### Core Packages

Tanzu Kubernetes Grid automatically installs the core packages during cluster creation. For more information about core packages, see [Core Packages](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.4/vmware-tanzu-kubernetes-grid-14/GUID-packages-core-index.html).

#### User-Managed Packages

A user-managed package is an optional component of a Kubernetes cluster that you can install and manage with the Tanzu CLI. These packages are installed after cluster creation. User-managed packages are grouped into package repositories in the Tanzu CLI. If a package repository that contains user-managed packages is available in the target cluster, you can use the Tanzu CLI to install and manage any of the packages from that repository.

Using the Tanzu CLI, you can install user-managed packages from the built-in `tanzu-standard` package repository or from package repositories that you add to your target cluster. From the `tanzu-standard` package repository, you can install the Cert Manager, Contour, External DNS, Fluent Bit, Grafana, Harbor, Multus CNI, and Prometheus packages. For more information about user-managed packages, see [User-Managed Packages](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.4/vmware-tanzu-kubernetes-grid-14/GUID-packages-cli-reference-packages.html).

We recommend installing the following packages:

* [Installing Cert Manager](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.4/vmware-tanzu-kubernetes-grid-14/GUID-packages-cert-manager.html)

* [Implementing Ingress Control with Contour](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.4/vmware-tanzu-kubernetes-grid-14/GUID-packages-ingress-contour.html)

* [Implementing Log Forwarding with Fluent Bit](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.4/vmware-tanzu-kubernetes-grid-14/GUID-packages-logging-fluentbit.html)

* [Implementing Monitoring with Prometheus and Grafana](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.4/vmware-tanzu-kubernetes-grid-14/GUID-packages-monitoring.html)

* [Implementing Multiple Pod Network Interfaces with Multus](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.4/vmware-tanzu-kubernetes-grid-14/GUID-packages-cni-multus.html)

* [Implementing Service Discovery with ExternalDNS](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.4/vmware-tanzu-kubernetes-grid-14/GUID-packages-external-dns.html)

* [Deploying Harbor Registry as a Shared Service](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.4/vmware-tanzu-kubernetes-grid-14/GUID-packages-harbor-registry.html)
	
If Harbor is required to take on a heavy load and store large images into the registry, you can install Harbor into a separate workload cluster.
