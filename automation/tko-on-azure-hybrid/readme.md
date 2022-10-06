# TKGm Private Deployment on Azure Playbook

Based on the Reference Architecture, [TKO on Azure Hybrid-Cloud](../../src/reference-designs/tko-on-azure-hybrid.md)

## !!! UPDATES [08/19/2022]

The new home of this automation code is with [VMware's Service Installer (SIVT)](https://github.com/vmware-tanzu/service-installer-for-vmware-tanzu/tree/main/azure)

## !!! UPDATES [03/11/2022]

Without refactoring this guide, let the following playbook inform this deployment kit's usage (**validation testing**):

1. Apply Terraform code in 0_keepers
    - `terraform apply -var="sub_id=..." -var="tenant_id=..."`
    - _where ... above represent your respective values_

1. Execute the run_cmd output instructions from 0_keepers
    - OS requirements will vary
    - e.g. `$env:ARM_ACCESS_KEY=(terraform output -raw access_key)`

1. Apply Terraform code in 1_netsec
    - `terraform apply -var="sub_id=..."`
    - _where ... above represent your respective values_

1. Apply Terraform code in 2_dns (as-needed)
    - This option only applies if you need an non-Azure source to resolve Azure Private DNS
    - `terraform apply -var="sub_id=..."`
    - _where ... above represent your respective values_

1. Apply Terraform code in 3_bootstrap
    - `terraform apply -var="sub_id=..."`
    - _where ... above represent your respective values_
    - ssh_cmd output will vary by OS, so mind your rules (if you're on Windows, you'll probably have to fix the ACLs on this file)

## TLDR

Modify provider.tf and/or terraform.tfvars as necessary for each TF config directory. Carry values from outputs or Key Vault into resultant config.yaml to then execute a command line deployment of the management cluster and others.

## Terraform, Infrastructure as Code

The examples given were designed to use an Azure Storage Account as a remote backend for Terraform's state management. "Keepers" below, is a prerequisite and does not get stored in a remote state (in fact, it establishes a place remote state can be stored).

The following components are divided in such a way that steps can be skipped if the answers to those features are provided by another, either pre-existent service or Central IT-provided. Each component supplies a set of resources that are intended to be passed forward, ideally through secret storage within a secure vault.

The components are as follows:

> Terraform runtime:
>
>- _Terraform v1.0.9_
>- _hashicorp/azurerm v2.80.0_

- Keepers
- Network and Network Security
- DNS (Intermediate)
- Deployment Prerequisites
- Tanzu Bootstrap

**In most cases of automation, we are making some assumptions on the consumer's behalf. I have tried to highlight those (outside of variables) below in case you need to modify those opinions!**

### Assumptions

**Tag Names** - In addition to those listed within the terraform.tfvars files, "StartDate" is in use within the code as an _origin date_ in case it's important to track that for resources. It's set once when the resource is created, and it should never be changed thereafter (by Terraform). Additional tags can be added to the map var type in terraform.tfvars.

**Azure Cloud** - This has never been built for anything outside of the standard "AzureCloud." Your mileage may vary on China or Government types.

**Naming** - the naming practice used herein could follow [published Microsoft Cloud Adoption Framework](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming). In short, that's:  
> `<resource-type>-<app>-<env>-<region>-###`

You will likely have to modify this to fit your customer's needs. The liberties I've taken over this framework are as follows:  
> `<resource-type>-<bu>-<app>-<env>-<region-abbrv>-###`
where _###_ is useful where multiples are generated (automatic). Otherwise, it's not used. What's more, the naming standard is entirely based upon the various _prefix_ vars collected in terraform.tfvars. You are allowed to format those prefixes however you like, so the the rules above are just suggestions. The only enforcement takes place at the resource level where _\<resource-type\>_ is prepended to your prefix per Microsoft's guidelines where applicable, and suffixes are added in situations to maintain uniqueness.

- Resource-Type is aligned to [Microsoft published guidelines](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations) where possible
- region-abbrv can (and shoulbe) be an abbreviation. These examples are country-first and 4 characters:

> `East US 2 = use2`

**Modules** - Modules used herein are the epitome of assumptions. These modules have been constructed to perform a set of tasks against categorical resources to produce standardization. This is because they represent those parts of an organization that may perform work on the TKGm platform owner's behalf. For instance, the subnet modules can create route tables and associate NSGs as well. The important part of these modules is ultimately the output, and therefore you may arrive at these outputs in any number of ways.

### Keepers

> "Keepers" are those resources that preempt the state-managed resources deployed by Terraform for this solution. They do not need to be dedicated to the TKGm solution! Keepers currently include a **Storage Account** for state and an **Azure Key Vault** for secret storage.

**IMPORTANT** Update [terraform.tfvars](0_keepers/terraform.tfvars) for your environment

#### keepers - terraform.tfvars

- **sub\_id**: Azure Subscription ID
- **location**: Azure Region (_e.g. eastus2 or East US 2_)
- **prefix**: A prefix to resource names using your naming standards (_e.g. vmw-use2-svcname_)
- **prefix_short**: Some resources are limited in size and characters - this prefix solves for those (_e.g. vmwuse2svc_). **Can include 4-digits of randomized hexadecimal at the end**

> Tag values default to tags defined at the Subscription level, but are designed to be overriden by anything provided here

- **ServiceName**: Free text to name or describe your application, solution, or service
- **BusinessUnit**: Should align with a predetermined list of known BUs
- **Environment**: Should align with a predetermined list of environments
- **OwnerEmail**: A valid email for a responsible person or group of the resource(s)
- \<Optional Tags\>: _Such as RequestorEmail_

```Shell
**from the 0_keepers sub-directory**
terraform init
terraform validate
terraform apply
```

### Network and Security

> NetSec should be replaced by a solution wherein the Central IT team provides these details where necessary. Specifically, Central IT should build the VNET to be in compliance with ExpressRoute requirements and allow the development team to add their own subnets and Network Security Groups (see [Azure Landing Zones](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/enterprise-scale/architecture))

**IMPORTANT** Update `provider.tf` and `terraform.tfvars` for your environment. Assumes/Requires the existence of a Network Watcher resource group (NetworkWatcherRG) in advance!

#### netsec - provider.tf

- **storage\_account\_name:** Storage account named pulled from the keepers.json where terraform state will be stored in perpetuity
- **container\_name:** Like a folder - generally "terraform-state"
- **key:** Further pathing for the storage and filename of your terraform state - must be unique (e.g. `bu/product/use2-s-net.tfstate`)
- **access\_key:** This can be found in your `keepers.json` and is the access_key credential used to read and write against the keeper storage account - SENSITIVE

#### netsec - terraform.tfvars (In addition to others listed previously...)

- **tkg\_cluster\_name:** The name passed into naming pertaining to the tanzu cli
- **core\_address\_space:** The VNET address space - it's the largest CIDR block specified for a network
- **boot\_diag\_sa\_name:** This name is passed to a storage account that is used for boot diagnostics - it should conform to Azure's naming requirements for storage accounts
- **vault_resource_group_name:** A Resource Group name provided by the output of `0_keepers`
- **vault_name:** The AKV name provided by the output of `0_keepers`

#### netsec - user_subnets.tf

This file is used to define the subnets used for TKGm and configure the subnets within Azure. Examples are provided, but the results are as follows (as defined within the associated modules):

> Create a list of products (all subnet names to all CIDR ranges) from the passed in subnets list, so we can create VNetLocal routes for every subnet.
>
> This data structure will take: local.subnets = {"net1" = "10.0.1.0/24", "net2" = "10.0.2.0/24"}
>
> and create:
>```bash
> {
>   "net1-10.0.1.0/24" = {"cidr" = "10.0.1.0/24", "name" = "net1"},
>   "net2-10.0.2.0/24" = {"cidr" = "10.0.2.0/24", "name" = "net2"}
> }
> ```
>
> This can then be used to create a route for each vnet local subnet in each route table, along with managing their respective NSGs.

```Shell
**from the 1_netsec sub-directory**
terraform init
terraform validate
terraform apply
```

### DNS

> DNS, in this solution, represents a BIND9 forwarder for Azure Private DNS. In order for on-prem resources to resolve Private DNS resources, conditional or zone forwarding must be in place on-prem to point to these DNS servers.

**IMPORTANT** Update `provider.tf` and `terraform.tfvars` for your environment

#### dns - provider.tf (same as above)

#### dns - terraform.tfvars (In addition to others listed above...)

- **subnet\_name:** Subnet name where DNS Forwarders will allocate internal IP(s) (output from `1_netsec`)
- **vnet\_name:** The VNET name (pre-existing - is output from `1_netsec`)
- **netsec\_resource\_group:** The resource group name where the pre-existing VNET lives
- **bindvms:** Count of VMs to deploy to host BIND9
- **boot\_diag\_sa\_name:** Pre-generated boot diagnostics storage account name (output from `1_netsec`)

```bash
**from the 2_dns sub-directory**
terraform init
terraform validate
terraform apply
```

## Tanzu Kubernetes Grid Automation

### WIP: Bootstrap Pre-Reqs (3_prereqs)

> This is a placeholder directory where scripts live to perform the cluster deployment after Terraform has created the infrastructure. Values are stored in the Azure Key Vault produced in 0_keepers and can be referenced to fill in values for the cluster and other config files.

### Bootstrap VM (3_bootstrap)

> The Bootstrap VM is used for TKGm deployment activities and is setup from the start with the tanzu CLI and related binaries.
>
> **NOTE:** The bootstrap VM should be provided outbound access to the Internet during initial deployment to perform updates and pull software packages necessary for its role. [bootstrap.sh](3_bootstrap/bootstrap.sh) may be consulted for actions taken during initialization and you may opt to performe these steps after proxy configuration has been performed.
>
> [bootstrap.sh](3_bootstrap/bootstrap.sh) also contains vmw-cli environment values of VMWUSER and VMWPASS that need to be updated with your credentials prior to executing this step.

**IMPORTANT** Update `provider.tf` and `terraform.tfvars` for your environment

#### boot - provider.tf (same as above)

#### boot - terraform.tfvars (In addition to others listed above...)

- **subnet\_name:** Subnet name where the bootstrap VM will allocate an internal IP (output from `1_netsec`)
- **vnet\_name:** The VNET name (pre-existing - is output from `1_netsec`)
- **netsec\_resource\_group:** The resource group name where the pre-existing VNET lives
- **boot\_diag\_sa\_name:** Pre-generated boot diagnostics storage account name (output from `1_netsec`)

```Shell
**from the 3_bootstrap sub-directory**
terraform init
terraform validate
terraform apply
```

> Creating the first management cluster is done through "kind" on the bootstrap VM and outputs from IaC above (captured in Azure KeyVault) should be compiled for the resultant answer files.

### WIP: Final Steps

Shell environment variables will need to be set for proxy configuration:

```bash
export HTTP_PROXY="http://PROXY:PORT"
export HTTPS_PROXY="http://PROXY:PORT"
export NO_PROXY="CIDR_OR_DOMAIN_LIST"
```

Docker proxy config will need to be set. Add the following section to /etc/systemd/system/docker.service.d/http-proxy.conf:

```ini
[Service]
    Environment="HTTP_PROXY=http://PROXY:PORT"
    Environment="HTTPS_PROXY=http://PROXY:PORT"
    Environment="NO_PROXY=CIDR_OR_DOMAIN_LIST"
```

> **NOTE:** Docker will need to be restarted for this setting to take effect.

Apt does not use environmental proxy configurations, and instead uses its own file. You will need to modify (create as-needed) the file /etc/apt/apt.conf.d/proxy.conf with the following:

```shell
Acquire {
  HTTP::proxy "http://PROXY:PORT";
  HTTPS::proxy "http://PROXY:PORT";
}
```

1) parse output (**Key Vault**, outputs, or state)
   - Requires _key_ interpretation from dash to underline ( - ➡ _ )
1) moustache templating for config.tmpl, pinniped-annotate.tmpl
1) scp config.yaml [ssh_vm]
1) scp pinniped-annotate.yaml [ssh_vm]
1) scp tkgm-install.sh [ssh_vm]
1) rexec tkgm-install.sh
