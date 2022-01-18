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
* Tanzu User Managed Packages:
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
* Network Security Group for each of the Cluster Subnets
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

### Deployment (TKG)
The last piece of a TKG deployment is to leverage the installed Tanzu CLI to deploy both a Management Cluster and Workload Cluster into the deployed Azure infrastructure that was deployed at the beginning. To make this possible, you will need to have a YAML config file that tells the CLI where the clusters will be deployed with respect to your Azure infrastructure. A minimal config file can be seen below based on the default values used in the ARM template.

<!-- cSpell:disable -->
```bash
AZURE_ENVIRONMENT: "AzurePublicCloud"
AZURE_CLIENT_ID: <AZURE_CLIENT_ID>
AZURE_CLIENT_SECRET: <AZURE_CLIENT_SECRET>
AZURE_CONTROL_PLANE_MACHINE_TYPE: Standard_D2s_v3
AZURE_CONTROL_PLANE_SUBNET_CIDR: 10.0.1.0/26
AZURE_CONTROL_PLANE_SUBNET_NAME: mgmt-control-subnet
AZURE_ENABLE_PRIVATE_CLUSTER: "true"
AZURE_FRONTEND_PRIVATE_IP: 10.0.1.4
AZURE_LOCATION: eastus2
AZURE_NODE_MACHINE_TYPE: Standard_D2s_v3
AZURE_NODE_SUBNET_CIDR: 10.0.1.64/26
AZURE_NODE_SUBNET_NAME: mgmt-worker-subnet
AZURE_RESOURCE_GROUP: bch-tkg-east
AZURE_SSH_PUBLIC_KEY_B64: <BASE64-SSH-PUBLIC>
AZURE_SUBSCRIPTION_ID: <AZURE_SUBSCRIPTION_ID>
AZURE_TENANT_ID: <AZURE_TENANT_ID>
AZURE_VNET_CIDR: 10.0.0.0/16
AZURE_VNET_NAME: bch-vnet-tkg
AZURE_VNET_RESOURCE_GROUP: bch-tkg-east
CLUSTER_CIDR: 100.96.0.0/11
CLUSTER_NAME: <CLUSTER_NAME>
CLUSTER_PLAN: prod
ENABLE_AUDIT_LOGGING: "true"
ENABLE_CEIP_PARTICIPATION: "false"
ENABLE_MHC: "true"
INFRASTRUCTURE_PROVIDER: azure
OS_ARCH: amd64
OS_NAME: ubuntu
OS_VERSION: "20.04"
SERVICE_CIDR: 100.64.0.0/13
TKG_HTTP_PROXY_ENABLED: "false"
```
<!-- cSpell:enable -->

**IMPORTANT:** Please be aware that you will need to create an SSH key so that you can pass the necessary Base 64 encoded value of the public key within the AZURE_SSH_PUBLIC_KEY_B64 parameter of the configuration file. How you generate your SSH key and how you then encode the entire Public key is up to you, but you will need to encode it before storing it within configuration file.

Once you have put in all of the values that are going to be relevant to your deployment, you will need to run the following commands from your Bootstrap VM.

```bash
tanzu management-cluster create --file config.yaml -v 0-9

tanzu cluster create –file config.yaml -v 0-9
```

**NOTE:** Please note that the same configuration file can be used for both the Management and Workload cluster deployments. You will need to specify a different cluster name for each one, but many of the same values can be leveraged. However, due to the way that the Tanzu CLI maintains its configuration information for each deployment, keeping different files with different CLUSTER_NAME parameter values is a recommended approach.

### (OPTIONAL) Deploy Packages
Once your clusters have been deployed, you may want to deploy some of the available out-of-the-box packages that come with Tanzu. Most of them will not be needed because of the existence of the SaaS services that are part of TKO, but for those functions and features that are not part of the TKO bundle, here are some steps for how to deploy packages such as Harbor or Pinniped. These packages are available for deployment within each Workload Cluster that you deploy, but they are not actually installed and working as Pods within the cluster until you perform the steps below.

**NOTE:** Please keep in mind that any cluster can be used to run the available packages. For the purposes of this document, we will use the name "Shared Services Cluster" to denote the cluster where these packages are to be installed.

Before you deploy any of the available optional packages, you will need to install the Cert Manager, which can be done using the following code:

1.  Obtain admin credentials for the Shared Services Cluster:
    <!-- /* cSpell:disable */ -->
    ```bash
    # Run command
    tanzu cluster kubeconfig get <Shared_Cluster_Name> --admin
    
    # Sample output:
    #  Credentials of cluster 'tkg-shared' have been saved 
    #  You can now access the cluster by running 'kubectl config use-context tkg-shared-admin@tkg-shared'
    ```
    <!-- /* cSpell:enable */ -->
2.  Download VMware Tanzu Kubernetes Grid Extensions Manifest 1.3.1 from [here](https://my.vmware.com/en/web/vmware/downloads/details?downloadGroup=TKG-131&productId=988&rPId=65946).
3.  Connect to the management cluster using TKG CLI and add the following tags:
    <!-- /* cSpell:disable */ -->
    ```bash
    kubectl config use-context tkg-mgmt01-admin@tkg-mgmt01   # Connect to TKG Management Cluster
    
    kubectl label cluster.cluster.x-k8s.io/<Shared_Cluster_Name> cluster-role.tkg.tanzu.vmware.com/tanzu-services="" --overwrite=true
    kubectl label cluster <Shared_Cluster_Name> type=workload   # Based on the match labels provided in AKO config file
    
    # Run command:
    tanzu cluster list --include-management-cluster
    
    # Sample output:
    #  NAME        NAMESPACE   STATUS   CONTROLPLANE  WORKERS  KUBERNETES        ROLES           PLAN  
    #  tkg-shared  default     running  1/1           1/1      v1.20.5+vmware.2  tanzu-services  dev   
    #  tkg-mgmt01  tkg-system  running  1/1           1/1      v1.20.5+vmware.2  management      dev 
    ```
    <!-- /* cSpell:enable */ -->
4.  Unpack the manifest using the following command.
    ```bash
    tar -xzf tkg-extensions-manifests-v1.3.1-vmware.1.tar.gz
    ```
5.  Connect to the shared services cluster using the credentials obtained in step 2 and install cert-manager
    <!-- /* cSpell:disable */ -->
    ```bash
    kubectl config use-context tkg-shared-admin@tkg-shared    ##Connect to the Shared Cluster
     
    cd ./tkg-extensions-v1.3.1+vmware.1/
    kubectl apply -f cert-manager/
     
    # Ensure required pods are running
    # Sample output:
    #   [root@bootstrap tkg-extensions-v1.3.1+vmware.1]# kubectl get pods -A | grep cert-manager
    #   cert-manager        cert-manager-7c58cb795-b8n4b                                   1/1     Running     0          42s
    #   cert-manager        cert-manager-cainjector-765684c9d6-mzdqs                       1/1     Running     0          42s
    #   cert-manager        cert-manager-webhook-ccc946479-dxlcw                           1/1     Running     0          42s
    
    #  [root@bootstrap tkg-extensions-v1.3.1+vmware.1]# kubectl get pods -A | grep kapp
    #  tkg-system          kapp-controller-6d7855d4dd-zn4rs                               1/1     Running     0          106m
    ```
    <!-- /* cSpell:enable */ -->

#### Harbor
Harbor is a compliant container registry that can be used to store the images that will eventually be used within the scope of your Workload clusters. Due to the nature of how it is installed, by default this registry would be made available only to those clusters that are within or connected to the network where the cluster is that has Harbor deployed.

**NOTE:** Please keep in mind that Harbor is only one option for a private compliant registry. Azure Container Registry can also be leveraged in this scenario. So can many different registry based virtual appliances. Please see the Reference Architecture for more information.

Once you are ready to deploy Harbor into one of your Workload clusters, then please perform the following steps:

1.  Execute the following commands to deploy Harbor not the shared services cluster.
    <!-- /* cSpell:disable */ -->
    ```bash
    cd ./tkg-extensions-v1.3.1+vmware.1/extensions/registry/harbor
    kubectl apply -f namespace-role.yaml
    cp harbor-data-values.yaml.example harbor-data-values.yaml
    ./generate-passwords.sh harbor-data-values.yaml           ## Generates Random Passwords for "harborAdminPassword", "secretKey", "database.password", "core.secret", "core.xsrfKey", "jobservice.secret", and "registry.secret" ##
    
    # Update the "hostname" value in "harbor-data-values.yaml" file with the FQDN for accessing Harbor 
    
    # (Optional)If using custome or CA certs: Before executing the below steps, update "harbor-data-values.yaml" with the certs, refer step 2 (Updating certs is optional, if certs are not provided, Cert-Manager will generate required certs)
    
    kubectl create secret generic harbor-data-values --from-file=values.yaml=harbor-data-values.yaml -n tanzu-system-registry
    kubectl apply -f harbor-extension.yaml
     
    # Validate
    kubectl get app contour -n tanzu-system-ingress
    
    # Note: Once the Harbor app is deployed successfully, the status should change from Reconciling to Reconcile Succeeded
    
    # Sample output:
    #  kubectl get app harbor -n tanzu-system-registry
    #  NAME     DESCRIPTION           SINCE-DEPLOY   AGE
    #  harbor   Reconciling           1m50s          1m50s
    
    # Wait until we see "Reconciling succeeded" (can take 3-5mins)
    #  NAME     DESCRIPTION           SINCE-DEPLOY   AGE
    #  harbor   Reconcile succeeded   5m45s          81m
    ```
    <!-- /* cSpell:enable */ -->

2.  (Optional) Update the `harbor-data-values.yaml` file with the hostname and certificates. Following is an example of the YAML file.
    
    **Sample harbor-data-values.yaml**

    <!-- /* cSpell:disable */ -->
    ```bash
    #@data/values
    #@overlay/match-child-defaults missing_ok=True
    ---
    
    # Docker images setting
    image:
      repository: projects.registry.vmware.com/tkg/harbor
      tag: v2.1.3_vmware.1
      pullPolicy: IfNotPresent
    # The namespace to install Harbor
    namespace: tanzu-system-registry
    # The FQDN for accessing Harbor admin UI and Registry service.
    hostname: harbor.tanzu.cc
    # The network port of the Envoy service in Contour or other Ingress Controller.
    port:
      https: 443
    # [Optional] The certificate for the ingress if you want to use your own TLS certificate.
    # We will issue the certificate by cert-manager when it's empty.
    tlsCertificate:
      # [Required] the certificate
      tls.crt: |
            -----BEGIN CERTIFICATE-----
            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
            8kEsxgvnXDz4y/Uj
            -----END CERTIFICATE-----
            -----BEGIN CERTIFICATE-----
            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
            nLRbwHOoq7hHwg==
            -----END CERTIFICATE-----
            -----BEGIN CERTIFICATE-----
            MIIFYDCCBEigAwIBAgIQQAF3ITfU6UK47naqPGQKtzANBgkqhkiG9w0BAQsFADA/
            MSQwIgYDVQQKExtEaWdpdGFsIFNpZ25hdHVyZSBUcnVzdCBDby4xFzAVBgNVBAMT
            DkRTVCBSb290IENBIFgzMB4XDTIx12BNr6E5MTQwM1oXDTI0MDkzMDE4MTQwM1ow
            TzELMAkGA1UEBhMCVVMxKTAnBgNVBAoTIEludGVybmV0IFNlY3VyaXR5IFJlc2Vh
            cmNoIEdyb3VwMRUwEwYDVQQDEwxJU1JHIFJvb3QgWDEwggIiMA0GCSqGSIb3DQEB
            AQUAA4ICDwAwggIKAoICAQCt6CRz9BQ385ueK1coHIe+3LffOJCMbjzmV6B493XC
            ov71am72AE8o295ohmxEk7axY/0UEmu/H9LqMZshftEzPLpI9d1537O4/xLxIZpL
            wYqGcWlKZmZsj348cL+tKSIG8+TA5oCu4kuPt5l+lAOf00eXfJlII1PoOK5PCm+D
            LtFJV4yAdLbaL9A4jXsDcCEbdfIwPPqPrt3aY6vrFk/CjhFLfs8L6P+1dy70sntK
            4EwSJQxwjQMpoOFTJOwT2e4ZvxCzSow/rBhads6shweU9GNx7C7ib1uYgeGJXDR5
            bHbvO5BieebbpJovJsXQEOEO3tkQjhb7t/eo98flAgeYjzYIlefiN5YNNnWe+w5y
            sR2bvAP5SQXYgd0FtCrWQemsAXaVCg/Y39W9Eh81LygXbNKYwagJZHduRze6zqxZ
            Xmidf3LWicUGQSk+WT7dJvUkyRGnWqNMQB9GoZm1pzpRboY7nn1ypxIFeFntPlF4
            FQsDj43QLwWyPntKHEtzBRL8xurgUBN8Q5N0s8p0544fAQjQMNRbcTa0B7rBMDBc
            SLeCO5imfWCKoqMpgsy6vYMEG6KDA0Gh1gXxG8K28Kh8hjtGqEgqiNx2mna/H2ql
            PRmP6zjzZN7IKw0KKP/32+IVQtQi0Cdd4Xn+GOdwiK1OtmLOsbdJ1Fdu/7xk9TND
            TwIDAQABo4IBRjCCAUIwDwYDVR0TAQH/BAUwAwEB/zAOBgNVHQ8BAf8EBAMCAQYw
            SwYIKwYBBQUHAQEEPzA9MDsGCCsGAQUFBzAChi9odHRwOi8vYXBwcy5pZGVudHJ1
            c3QuY29tL3Jvb3RzL2RzdHJvb3RjYXgzLnA3YzAfBgNVHSMEGDAWgBTEp7Gkeyxx
            +tvhS5B1/8QVYIWJEDBUBgNVHSAETTBLMAgGBmeBDAECATA/BgsrBgEEAYLfEwEB
            ATAwMC4GCCsGAQUFBwIBFiJodHRwOi8vY3BzLnJvb3QteDEubGV0c2VuY3J5cHQu
            b3JnMDwGA1UdHwQ1MDMwMaAvoC2GK2h0dHA6LyjcmwuaWRlbnRydXN0LmN9vbS9E
            U1RST09UQ0FY1ENSTC5jcmwwHQYDVR0OBBYEFHm0WeZ7tuXkAXOACIjIGlj26Ztu
            MA0GCSqGSIb3DQEBCwUAA4IBAQAKcwBslm7/DlLQrt2M51oGrS+o44+/yQoDFVDC
            5WxCu2+b9LRPwkSICHXM6webFGJueN7sJ7o5XPWioW5WlHAQU7G75K/QosMrAdSW
            9MUgNTP52GE24HGNtLi1qoJFlcDyqSMo59ahy2cI2qBDLKobkx/J3vWraV0T9VuG
            WCLKTVXkcGdtwlfFRjlBz4phtmf5X6DYO8A4jqv2Il9DjXA6USbW1FzXSLr9YG1O
            he8Y4IWS6wY7bCkjCWDcRQJMEhg76fsO3txE+FiYruq9RUWhiF1myv4Q6W+CyBFC
            Dfvp7OOGAN6dEOM4+qR9sdjoSYKEBp6GtPAQw4dy753easc5
            -----END CERTIFICATE-----
      # [Required] the private key
      tls.key: |
            -----BEGIN PRIVATE KEY-----
            MIIEvwIBADANBgkqhkiG9w0BAQEFAASCBKkwggSlAgEAAoIBAQC0EC1ihOO2nBUH
            4lOjn4EnURm/wIDcQA/1XsDzlnSxBLXeP9+uSb1SJckzdPTpJIEbGuakFkiafLfk
            MnR9rCc7M0KtPQ/qHdLGp3Jz7T4/bzAqLckZfn0fkomaKo8Ku+GoqitZe9CNGsGO
            UkifzcPDeBLdU9+oSRXTXiDgSe5txa0OLLrzJRZZ/UBGPDO2LFqxO4/POPiRduqB
            obbrya0eCq4zjpKIDWA90K9nKxTphpFioswdgP0P/tIskNkt7sQOeTbQcVwJ+SsO
            nnXKAD7oTAJti2Z3dRCABpjNqIaOVsadqQ16j18QRP/KB57piDiCocoChVlBbAmk
            YRakx1SLAgMBAAECggEBAKJNpqsT/7G9NNO7dQqanq8S0jPeUAi3kerpMuEd8CcT
            iN9BEd0myIjAWICSXqO77MfC0rx6/YyK+LKvrAMPZvlctjAzRyIPKcs4adkGssJk
            Oh6rEIZzVlNcIb4duHvDaJ9Aa/yntw9JW8hucNnifh+2HsLzdDlbT1oLkXS6DzlP
            nwsHBuXQ91j11csPvA7HG+maLw6HO1rmLoHeweTJ7IfR2PvRhVEGEIqXG7EvrBrH
            q3KXKWW+9cNLH/ty27XKzjpa1oPm5K8yUFi+4ZCEZa2NYBidpa+8ZZ1+bQ0rkbqh
            SiYdhy3qAQ4B6PD8nCMdavNW8v99KXBZwXBDbxl7yKkCgYEA26Y+Um929mcW3S8X
            8tef83b6w1P6TQs47HxVPFZUXUZtBCQs0mO1dlGQfsQWvm93UTkFJTZZqPm4hkBh
            07b6jIEWVHiq6hTESu313ojI03PxWGOMGZ3wp/1VR2l9gv7J6taYosXE6WBzxVHl
            pPj21WV65EfExA8w+cLkxtroEp0CgYECZmfNBQtUiNBkeAgCtlYIegx84tUasAQs
            8zVFUhr9rBa83gI2z/zXPwCDDnlMI/z3W7/P6dGcEdZ9DzFtTa+cCDTv0GceZvD+
            iKumWVjlQxmcu1bCgty9tutQk35mrOD4YGkgKNrcZY6XcbFrubDOEPVIdtJSeFqO
            /OQLANSRZ0cCgYEAttUymzvdMk2tYn+I18NUiTxIj76fYvIsd+0mpgrWPq4YoJHc
            HWSR7+ME/AANTodKMnncJpWPHHCBgH6m76wn8jyhcb7fxelzW0uolYwWXqzsAD8c
            p1YotCzTh5Xvu9KKEMiAVT16Iya-scdtlvmWssV+F8lEm3yvnPUKxKciqECgYAAp
            TU2p1AQTGc15ltq2vOdRe0jvE2WRSuCjJN7Js+osziTJhKII+PfbvFwOoyyrAIQm
            GG/w0oHmuNHQBag/W8pXiyOPXlwLYm6Vs0J/3xDvzcCc1gxd+NeVgmZPQNcwOu5m
            +wmLQNeTXSbNB1/uIa/MgpmKWQZGDXyKpM7NkQg0zQKBgQCyq93ZUekz/cgE5AAn
            9Xp1H45DqX2nMxRknerU/wzAKEebAAxH172VIpyuFHXJhLuQl4nNEdIQ4SRX6ZLd
            ucUTe6ORWzSI3fcszk9RDui90bYKUmefGX9v/MgdwmB6dS5FpSaKDFgNlESFHjJY
            1i9Hpt7D0w4eKwvXX11MABcs/A==
            -----END PRIVATE KEY-----
      # [Optional] the certificate of CA, this enables the download
      # link on portal to download the certificate of CA
      ca.crt:
    # Use contour http proxy instead of the ingress when it's true
    enableContourHttpProxy: true
    # [Required] The initial password of Harbor admin.
    harborAdminPassword: VMware123!
    # [Required] The secret key used for encryption. Must be a string of 16 chars.
    secretKey: 44z5mmTRiDAd3r7o
    database:
      # [Required] The initial password of the postgres database.
      password: L92Lwf92x4nkh2XB
    core:
      replicas: 1
      # [Required] Secret is used when core server communicates with other components.
      secret: VmMoXdxVJ00PLmoD
      # [Required] The XSRF key. Must be a string of 32 chars.
      xsrfKey: DnvQN508M97mGmtK9248sCQ0pFD82BhV
    jobservice:
      replicas: 1
      # [Required] Secret is used when job service communicates with other components.
      secret: HtRDVOswYgsOoSV7
    registry:
      replicas: 1
      # [Required] Secret is used to secure the upload state from client
      # and registry storage backend.
      # See: https://github.com/docker/distribution/blob/master/docs/configuration.md#http
      secret: r9MYJfjMVRrzpkiT
    notary:
      # Whether to install Notary
      enabled: true
    clair:
      # Whether to install Clair scanner
      enabled: true
      replicas: 1
      # The interval of clair updaters, the unit is hour, set to 0 to
      # disable the updaters
      updatersInterval: 12
    trivy:
      # enabled the flag to enable Trivy scanner
      enabled: true
      replicas: 1
      # gitHubToken the GitHub access token to download Trivy DB
      gitHubToken: ""
      # skipUpdate the flag to disable Trivy DB downloads from GitHub
      #
      # You might want to set the value of this flag to `true` in test or CI/CD environments to avoid GitHub rate limiting issues.
      # If the value is set to `true` you have to manually download the `trivy.db` file and mount it in the
      # `/home/scanner/.cache/trivy/db/trivy.db` path.
      skipUpdate: false
    # The persistence is always enabled and a default StorageClass
    # is needed in the k8s cluster to provision volumes dynamicly.
    # Specify another StorageClass in the "storageClass" or set "existingClaim"
    # if you have already existing persistent volumes to use
    #
    # For storing images and charts, you can also use "azure", "gcs", "s3",
    # "swift" or "oss". Set it in the "imageChartStorage" section
    persistence:
      persistentVolumeClaim:
        registry:
          # Use the existing PVC which must be created manually before bound,
          # and specify the "subPath" if the PVC is shared with other components
          existingClaim: ""
          # Specify the "storageClass" used to provision the volume. Or the default
          # StorageClass will be used(the default).
          # Set it to "-" to disable dynamic provisioning
          storageClass: ""
          subPath: ""
          accessMode: ReadWriteOnce
          size: 10Gi
        jobservice:
          existingClaim: ""
          storageClass: ""
          subPath: ""
          accessMode: ReadWriteOnce
          size: 1Gi
        database:
          existingClaim: ""
          storageClass: ""
          subPath: ""
          accessMode: ReadWriteOnce
          size: 1Gi
        redis:
          existingClaim: ""
          storageClass: ""
          subPath: ""
          accessMode: ReadWriteOnce
          size: 1Gi
        trivy:
          existingClaim: ""
          storageClass: ""
          subPath: ""
          accessMode: ReadWriteOnce
          size: 5Gi
      # Define which storage backend is used for registry and chartmuseum to store
      # images and charts. Refer to
      # https://github.com/docker/distribution/blob/master/docs/configuration.md#storage
      # for the detail.
      imageChartStorage:
        # Specify whether to disable `redirect` for images and chart storage, for
        # backends which not supported it (such as using minio for `s3` storage type), please disable
        # it. To disable redirects, simply set `disableredirect` to `true` instead.
        # Refer to
        # https://github.com/docker/distribution/blob/master/docs/configuration.md#redirect
        # for the detail.
        disableredirect: false
        # Specify the "caBundleSecretName" if the storage service uses a self-signed certificate.
        # The secret must contain keys named "ca.crt" which will be injected into the trust store
        # of registry's and chartmuseum's containers.
        # caBundleSecretName:
    
        # Specify the type of storage: "filesystem", "azure", "gcs", "s3", "swift",
        # "oss" and fill the information needed in the corresponding section. The type
        # must be "filesystem" if you want to use persistent volumes for registry
        # and chartmuseum
        type: filesystem
        filesystem:
          rootdirectory: /storage
          #maxthreads: 100
        azure:
          accountname: accountname # required
          accountkey: base64encodedaccountkey # required
          container: containername # required
          realm: core.windows.net # optional
        gcs:
          bucket: bucketname # required
          # The base64 encoded json file which contains the key
          encodedkey: base64-encoded-json-key-file # optional
          rootdirectory: null # optional
          chunksize: 5242880 # optional
        s3:
          region: us-west-1 # required
          bucket: bucketname # required
          accesskey: null # eg, awsaccesskey
          secretkey: null # eg, awssecretkey
          regionendpoint: null # optional, eg, http://myobjects.local
          encrypt: false # optional
          keyid: null # eg, mykeyid
          secure: true # optional
          v4auth: true # optional
          chunksize: null # optional
          rootdirectory: null # optional
          storageclass: STANDARD # optional
        swift:
          authurl: https://storage.myprovider.com/v3/auth
          username: username
          password: password
          container: containername
          region: null # eg, fr
          tenant: null # eg, tenantname
          tenantid: null # eg, tenantid
          domain: null # eg, domainname
          domainid: null # eg, domainid
          trustid: null # eg, trustid
          insecureskipverify: null # bool eg, false
          chunksize: null # eg, 5M
          prefix: null # eg
          secretkey: null # eg, secretkey
          accesskey: null # eg, accesskey
          authversion: null # eg, 3
          endpointtype: null # eg, public
          tempurlcontainerkey: null # eg, false
          tempurlmethods: null # eg
        oss:
          accesskeyid: accesskeyid
          accesskeysecret: accesskeysecret
          region: regionname
          bucket: bucketname
          endpoint: null # eg, endpoint
          internal: null # eg, false
          encrypt: null # eg, false
          secure: null # eg, true
          chunksize: null # eg, 10M
          rootdirectory: null # eg, rootdirectory
    # The http/https network proxy for clair, core, jobservice, trivy
    proxy:
      httpProxy:
      httpsProxy:
      noProxy: 127.0.0.1,localhost,.local,.internal
    ```
    <!-- /* cSpell:enable */ -->
