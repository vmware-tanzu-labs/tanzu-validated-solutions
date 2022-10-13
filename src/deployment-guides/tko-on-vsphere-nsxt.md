# Deploy VMware Tanzu for Kubernetes Operations on VMware vSphere with VMware NSX-T

This document provides step-by-step instructions for deploying Tanzu Kubernetes Operations in an Internet available vSphere environment backed by NSX-T Data Center networking.

The scope of the document is limited to providing deployment steps based on the reference design in [VMware Tanzu for Kubernetes Operations on vSphere with NSX-T](../reference-designs/tko-on-vsphere-nsx.md). It does not cover deployment procedures for the underlying SDDC components.

## Deploying with VMware Service Installer for Tanzu

You can use VMware Service Installer for VMware Tanzu to automate this deployment.

VMware Service Installer for Tanzu automates the deployment of the reference designs for Tanzu for Kubernetes Operations. It uses best practices for deploying and configuring the required Tanzu for Kubernetes Operations components.

To use Service Installer to automate this deployment, see [Deploying VMware Tanzu for Kubernetes Operations on vSphere with NSX-T Using Service Installer for VMware Tanzu](https://docs.vmware.com/en/Service-Installer-for-VMware-Tanzu/1.3/service-installer/GUID-vSphere%20-%20Backed%20by%20NSX-T-tkoVsphereNSXT.html).

Alternatively, if you decide to manually deploy each component, follow the steps provided in this document.

## Supported Component Matrix

The validated Bill of Materials that can be used to install Tanzu Kubernetes Grid on your vSphere with NSX environment is as follows:

|**Software Components**|**Version**|
| --- | --- |
|Tanzu Kubernetes Grid|1.6.0|
|VMware vSphere ESXi|7.0 U3d and later|
|VMware vCenter (VCSA)|7.0 U3d and later|
|NSX Advanced Load Balancer|21.1.4|
|VMware NSX-T|3.1.2|

For up-to-date information about which software versions can be used together, see the [Interoperability Matrix](https://interopmatrix.vmware.com/Interoperability?col=551,8803&row=789,%262,%26912,).

## Prepare Environment for Deploying Tanzu for Kubernetes Operations

Before deploying Tanzu for Kubernetes Operations on vSphere, ensure that your environment is set up as described in the following requirements:

- [General Requirements](#genreq)
- [Network Requirements](#netreq)
- [Firewall Requirements](#fwreq)

### <a id="genreq"> </a> General Requirements

- A vCenter with NSX-T backed environment.
- Ensure that following NSX-T configurations are in place:

  **Note:** The following provides only a high-level overview of the required NSX-T configuration. For more information, see [NSX-T Data Center Installation Guide](https://docs.vmware.com/en/VMware-NSX-T-Data-Center/3.2/installation/GUID-3E0C4CEC-D593-4395-84C4-150CD6285963.html) and [NSX-T Data Center Product Documentation](https://docs.vmware.com/en/VMware-NSX/index.html).

  - NSX-T manager instance is deployed and configured with Advanced or higher license.
  - vCenter Server that is associated with the NSX-T Data Center is configured as Compute Manager.
  - Required overlay and vLAN Transport Zones are created.
  - IP pools for host and edge tunnel endpoints (TEP) are created.
  - Host and edge uplink profiles are in place.
  - Transport node profiles are created. This is not required if configuring NSX-T data center on each host instead of the cluster.
  - NSX-T data center configured on all hosts part of the vSphere cluster or clusters.
  - Edge transport nodes and at least one edge cluster is created
  - Tier-0 uplink segments and tier-0 gateway is created.
  - Tier-0 router is peered with uplink L3 switch.
  - DHCP profile is created in NSX.
- SDDC environment has the following objects in place:
  - A vSphere cluster with at least three hosts on which vSphere DRS is enabled and NSX-T is successfully configured.
  - A dedicated resource pool to deploy the following Tanzu Kubernetes management cluster, shared services cluster, and workload clusters. The number of required resource pools depends on the number of workload clusters to be deployed.
  - VM folders to collect the Tanzu Kubernetes Grid VMs.
  - A datastore with sufficient capacity for the control plane and worker node VM files.
  - Network time protocol (NTP) service is running on all hosts and vCenter.
  - A host, server, or VM based on Linux, macOS, or Windows which acts as your bootstrap machine which has docker installed. For this deployment, a virtual machine based on Photon OS will be used.
  - Depending on the OS flavor of the bootstrap VM, download and configure the following packages from [VMware Customer Connect](https://customerconnect.vmware.com/en/downloads/details?downloadGroup=TKG-160&productId=988&rPId=93384). To configure required packages on the Cent OS machine, see [Deploy and Configure Bootstrap Machine](#configurebootstrap)."
    - Tanzu CLI
    - Kubectl cluster CLI 1.23.8
  - A vSphere account with permissions as described in [Required Permissions for the vSphere Account](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.6/vmware-tanzu-kubernetes-grid-16/GUID-mgmt-clusters-vsphere.html#required-permissions-for-the-vsphere-account-5).
  - Download and import NSX Advanced Load Balancer 21.1.4 OVA to Content Library.
  - Download the following OVA files from [VMware Customer Connect](https://customerconnect.vmware.com/en/downloads/details?downloadGroup=TKG-160&productId=988&rPId=93384) and import to vCenter. Convert the imported VMs to templates."
    - Photon v3 Kubernetes v1.23.8 OVA and/or
    - Ubuntu 2004 Kubernetes v1.23.8 OVA  

**Note**: You can also download supported older versions of Kubernetes from [VMware Customer Connect](https://customerconnect.vmware.com/en/downloads/details?downloadGroup=TKG-160&productId=988&rPId=93384) and import them to deploy workload clusters on the intended Kubernetes versions."

**Resource Pools and VM Folders:**

The sample entries of the resource pools and folders that need to be created are as follows.

|**Resource Type**|**Sample Resource Pool Name**|**Sample Folder Name**|
| --- | --- | --- |
|NSX ALB Components|`NSX-ALB`|`NSX-ALB-VMs`|
|TKG Management components|`TKG-Mgmt`|`TKG-Mgmt-VMs`|
|TKG Shared Service Components|`TKG-Shared-SVC`|`TKG-SS-VMs`|
|TKG Workload components|`TKG-WLD`|`TKG-Workload-VMs`|

### <a id="netreq"> </a> Network Requirements

Create separate logical segments in NSX-T for deploying TKO components as per [Network Requirements](../reference-designs/tko-on-vsphere-nsx.md#a-idnetreq-a-network-requirements) defined in the reference architecture.

### <a id="fwreq"> </a>  Firewall Requirements

Ensure that the firewall is set up as described in [Firewall Requirements](../reference-designs/tko-on-vsphere-nsx.md#a-idfwreq-a-firewall-requirements).

### <a id="cidrex"> </a>  Subnet and CIDR Example

For this demonstration, this document makes use of the following subnet CIDR for Tanzu for Kubernetes Operations deployment.

|**Network Type**|**Segment Name**|**Gateway CIDR**|**DHCP Pool in NSXT**|**NSX ALB IP Pool**|
| --- | --- | --- | --- | --- |
|NSX ALB Management Network|alb-mgmt-ls|172.19.71.1/27|N/A|172.19.71.6 - 172.19.71.30|
|TKG Cluster VIP Network|tkg-cluster-vip|172.19.75.1/26|N/A|172.19.75.2 - 172.19.75.60|
|TKG Management Network|tkg-mgmt-ls|172.19.72.1/27|172.19.72.2 - 172.19.72.30|N/A|
|TKG Shared Service Network|tkg-ss-ls|172.19.73.1/27|172.19.73.2 - 172.19.73.30|N/A|
|TKG Workload Network|tkg-workload-ls|172.19.77.1/24|172.19.77.2- 172.19.77.251|N/A|

## Deployment Overview

The steps for deploying Tanzu for Kubernetes Operations on vSphere backed by NSX-T are as follows:

1. [Configure T1 Gateway and Logical Segments in NSX-T Data Center](#configurensxt)
2. [Deploy and Configure NSX Advanced Load Balancer](#deploynsxalb)
3. [Deploy and Configure Bootstrap Machine](#configurebootstrap)
4. [Deploy Tanzu Kubernetes Grid Management Cluster](#deploy-mgmt-cluster)
5. [Register Tanzu Kubernetes Grid Management Cluster with Tanzu Mission Control](#tmc-integration)
6. [Deploy Tanzu Kubernetes Grid Shared Service Cluster](#createsharedsvc)
7. [Deploy Tanzu Kubernetes Grid Workload Cluster](#createworkload)
8. [Integrate Tanzu Kubernetes Clusters with Tanzu Observability](#integrate-to)
9. [Integrate Tanzu Kubernetes Clusters with Tanzu Service Mesh](#integrate-tsm)
10. [Deploy User-Managed Packages on Tanzu Kubernetes Grid Clusters](#packages)

## <a id="configurensxt"> </a> Configure T1 Gateway and Logical Segments in NSX-T Data Center

As a prerequisite, an NSX-T backed vSphere environment must be configured with at least one tier-0 gateway. A tier-0 gateway performs the functions of a tier-0 logical router. It processes traffic between the logical and physical networks. For more information on creating and configuring a tier-0 gateway, see [NSX-T documentation](https://docs.vmware.com/en/VMware-NSX-T-Data-Center/3.2/administration/GUID-E9E62E02-C226-457D-B3A6-FE71E45628F7.html).

This procedure comprises the following tasks:

1. Add a Tier-1 Gateway
1. Create Overlay-Backed Segments

### Add a Tier-1 Gateway

The tier-1 logical router must be connected to the tier-0 logical router to get the northbound physical router access. The following procedure provides the minimum required configuration to create a tier-1 gateway, which is adequate to successfully deploy the Tanzu for Kubernetes Operations stack. For a more advanced configuration, see [NSX-T documentation](https://docs.vmware.com/en/VMware-NSX/index.html).

1. With admin privileges, log in to NSX Manager.
1. Select **Networking** > **Tier-1 Gateways**.
1. Click **Add Tier-1 Gateway**.
1. Enter a name for the gateway.
1. Select a tier-0 gateway to connect to this tier-1 gateway to create a multi-tier topology.
1. Select an NSX Edge cluster. This is required for this tier-1 gateway to host stateful services such as NAT, load balancer, or firewall.
1. (Optional) In the **Edges** field, select **Auto Allocated** or manually set the edge nodes.
1. Select a failover mode or accept the default. The default option is Non-preemptive.
1. Select **Enable Standby Relocation**.
1. Click **Route Advertisement** and ensure that following routes are selected:
   * **All DNS Forwarder Routes**
   * **All Connected Segments and Service Ports**
   * **All IPSec Local Endpoints**
   * **All LB VIP Routes**
   * **All LB SNAT IP Routes**

    ![Add tier-1 gateway](img/tko-on-vsphere-nsxt/T1-gateway-01.png)

1. Click **Save**.
    
#### DHCP configuration on Tier-1 Gateway

Complete the following steps to set the DHCP configuration in the tier-1 gateway:

1. With admin privileges, log in to NSX Manager.
1. Select **Networking** > **Tier-1 Gateways**.
1. On the tier-1 gateway that you created earlier, click the three dots menu and select **Edit**.
1. Next to DHCP Config, click **Set**.

   ![Tier-1 gateway DHCP server and DHCP profile configuration](img/tko-on-vsphere-nsxt/T1-gateway-02.png)

1. In the Set DHCP Configuration dialog box, set **Type** to DHCP Server and select the DHCP profile that you created as part of the prerequisites.

   ![Tier-1 gateway DHCP configuration](img/tko-on-vsphere-nsxt/T1-gateway-03.png)

1. Click **Save**.

### Create Overlay-Backed Segments

VMware NSX provides the option to add two kinds of segments: overlay-backed segments and VLAN-backed segments. Segments are created as part of a transport zone. There are two types of transport zones: VLAN transport zones and overlay transport zones. A segment created in a VLAN transport zone is a VLAN-backed segment and a segment created in an overlay transport zone is an overlay-backed segment.

Create the overlay backed logical segments as shown in the [Overlay backed segments CIDR example](#cidrex). All these segments will be a part of the same overlay transport zone and they must be connected to the tier-1 gateway.

The following procedure provides required details to create one such network which is required for the Tanzu for Kubernetes Operations deployment:

1. With admin privileges, log in to NSX Manager

1. Select **Networking** > **Segments**.

1. Click **ADD SEGMENT** and enter a name for the segment. For example, `tkg-mgmt-ls`

1. Under **Connected Gateway**, select the tier-1 gateway that you created earlier.

1. Under **Transport Zone**, select a transport zone that will be an overlay transport zone.

1. Under **Subnets**, enter the gateway IP address of the subnet in the CIDR format. For example, `172.19.72.1/27`

   ![Segment configuration](img/tko-on-vsphere-nsxt/T1-gateway-04.png)

    **Note:** The following  step is required only for Tanzu Kubernetes Grid management network, shared services network, and workload network.

1. Click **SET DHCP CONFIG**.

    **DHCP Type** field is set to Gateway DHCP Server and **DHCP Profile** is set to the profile created while creating the tier-1 gateway.

   1. Click **Settings**, select **Enable DHCP Config**, and enter the DHCP range and DNS server information.

      ![DHCP configuration](img/tko-on-vsphere-nsxt/T1-gateway-05.png)

   1. Click **Options** and under **Select DHCP Options**, select **GENERIC OPTIONS**.

   1. Click **ADD GENERIC OPTION**, Add **NTP servers (42)** and **Domain Search (119)**.

      ![Apply DHCP configuration](img/tko-on-vsphere-nsxt/T1-gateway-06.png)

   1. Click **Save** to create the logical segment.

Repeat steps 1-7 to create all other required overlay-backed segments. Once completed, you should see an output similar to:

   ![List of created segments](img/tko-on-vsphere-nsxt/T1-gateway-07.png)

Additionally, you can create the required inventory groups and firewall rules. For more information, see [NSX-T Data Center Product Documentation](https://docs.vmware.com/en/VMware-NSX/index.html).

## <a id="deploynsxalb"> </a>   Deploy and Configure NSX Advanced Load Balancer

NSX Advanced Load Balancer (ALB) is an enterprise-grade integrated load balancer that provides L4- L7 load balancer support. It is recommended for vSphere deployments without NSX-T or when there are unique scaling requirements.

NSX Advanced Load Balancer is deployed in Write Access Mode in the vSphere Environment backed by NSX-T. This mode grants NSX Advanced Load Balancer controllers full write access to the vCenter or NSX which helps in automatically creating, modifying, and removing service engines (SEs) and other resources as needed to adapt to changing traffic needs.

For a production-grade deployment, it is recommended to deploy 3 instances of the NSX Advanced Load Balancer controller for high availability and resiliency.

The sample IP address and FQDN set for the NSX Advanced Load Balancer controllers is as follows:

|**Controller Node**|**IP Address**|**FQDN**|
| --- | --- | --- |
|Node 1 Primary|172.19.10.11|`alb01.tanzu.lab`|
|Node 2 Secondary|172.19.10.12|`alb02.tanzu.lab`|
|Node 3 Secondary |172.19.10.13|`alb03.tanzu.lab`|
|HA Address|172.19.10.10|`alb.tanzu.lab`|

### <a id="deploynsxalb"> </a> Deploy NSX Advanced Load Balancer

As part of the prerequisites, you must have the NSX Advanced Load Balancer 21.1.4 OVA downloaded and imported to the content library. Deploy the NSX Advanced Load Balancer under the resource pool **NSX-ALB**  and place it under the folder **NSX-ALB-VMs**.

To deploy NSX Advanced Load Balancer, complete the following steps.

1. Log in to **vCenter** and navigate to **Home** > **Content Libraries**.
1. Select the content library under which the NSX-ALB OVA is placed.
1. Click on **OVA & OVF Templates**.
1. Right-click the NSX Advanced Load Balancer image and select **New VM from this Template**.
1. On the Select name and folder page, enter a name and select a folder for the NSX Advanced Load Balancer VM as **NSX-ALB-VMs**.
1. On the Select a compute resource page, select the resource pool **NSX-ALB**.
1. On the Review details page, verify the template details and click **Next**.
1. On the Select storage page, select a storage policy from the VM Storage Policy drop-down menu and choose the  datastore location where you want to store the virtual machine files.
1. On the Select networks page, select the network **alb-mgmt-ls** and click **Next**.
1. On the Customize template page, provide the NSX Advanced Load Balancer management network details such as IP address, subnet mask, and gateway, and then click **Next**.
1. On the Ready to complete page, review the provided information and click **Finish**.

![NSX ALB deployment](img/tko-on-vsphere-nsxt/alb01.png)

A new task for creating the virtual machine appears in the **Recent Tasks** pane. After the task is complete, the NSX Advanced Load Balancer virtual machine is created on the selected resource. Power on the virtual machine and give it a few minutes for the system to boot. Upon successful boot up, navigate to NSX Advanced Load Balancer on your browser.  

**Note**: While the system is booting up, a blank web page or a 503 status code may appear.  

### <a id="nsx-alb-init"> </a>NSX Advanced Load Balancer: Initial Setup

Once NSX Advanced Load Balancer is successfully deployed and running, navigate to NSX Advanced Load Balancer on your browser using the URL https://<em><IP/FQDN></em> and configure the basic system settings:

1. Set admin password and click on **Create Account**.

    ![Set admin password and create account](img/tko-on-vsphere-nsxt/alb02.png)

1. On the Welcome page, under **System Settings**, set backup passphrase and provide DNS information, and then click **Next**.

    ![Set backup passphrase and provide DNS information](img/tko-on-vsphere-nsxt/alb03.png)

1. Under **Email/SMTP**, provide email and SMTP information, and then click **Next**.

    ![Provide email and SMTP information](img/tko-on-vsphere-nsxt/alb04.png)

1. Under **Multi-Tenant**, configure settings as follows and click **Save**.
    - IP Route Domain: Share IP route domain across tenants  
    - Service Engines are managed within the: Provider (Shared across tenants)  
    - Tenant Access to Service Engine: Read

    ![Configure multi-tenant settings](img/tko-on-vsphere-nsxt/alb05.png)

If you did not select the **Setup Cloud After** option before saving, the initial configuration wizard exits. The Cloud configuration window does not automatically launch, and you are directed to a dashboard view on the controller.

### NSX Advanced Load Balancer: NTP Configuration

To configure NTP, navigate to **Administration** > **Settings** > **DNS/NTP > Edit**.

![NTP server configuration](img/tko-on-vsphere-nsxt/alb06.png)

Add your NTP server details and then click **Save**.

**Note:** You may also delete the default NTP servers.

![NTP server configuration](img/tko-on-vsphere-nsxt/alb07.png)

### NSX Advanced Load Balancer: Licensing

This document focuses on enabling NSX Advanced Load Balancer using the license model: **Enterprise License (VMware NSX ALB Enterprise)**.

1. To configure licensing, navigate to the **Administration** > **Settings** > **Licensing**, and click on the gear icon to change the license type to Enterprise.

   ![License configuration 01](img/tko-on-vsphere-nsxt/alb08.png)

2. Select Enterprise Tier as the license type and click **Save**.

   ![License configuration 02](img/tko-on-vsphere-nsxt/alb09.png)

3. Once the license tier is changed, apply the NSX Advanced Load Balancer Enterprise license key. If you have a license file instead of a license key, apply the license by selecting the **Upload a License File** option.

   ![License configuration 03](img/tko-on-vsphere-nsxt/alb10.png)

### NSX Advanced Load Balancer: Controller High Availability

In a production environment, it is recommended to deploy additional controller nodes and configure the controller cluster for high availability and disaster recovery. Adding 2 additional nodes to create a 3-node cluster provides node-level redundancy for the controller and also maximizes performance for CPU-intensive analytics functions.

To run a 3-node controller cluster, you deploy the first node and perform the initial configuration, and set the cluster IP address. After that, you deploy and power on two more controller VMs, but you must not run the initial configuration wizard or change the admin password for these controllers VMs. The configuration of the first controller VM is assigned to the two new controller VMs.

The first controller of the cluster receives the Leader role. The second and third controllers work as Follower.

Complete the following steps to configure NSX Advanced Load Balancer cluster:

1. Log in to the primary NSX Advanced Load Balancer controller and navigate to **Administrator** > **Controller** > **Nodes**, and then click **Edit**.

1. Specify **Name** and **Controller Cluster IP**, and then click **Save**. This IP address must be from the NSX ALB management network.

    ![Specify NSX ALB controller node name and IP](img/tko-on-vsphere-nsxt/alb11.png)

1. Deploy the 2nd and 3rd NSX Advanced Load Balancer controller nodes by using steps in [Deploy NSX Advanced Load Balancer](#deploynsxalb).

1. Log into the primary NSX Advanced Load Balancer controller using the Controller Cluster IP/FQDN and navigate to **Administrator** > **Controller** >  **Nodes**, and then click **Edit**. The Edit Controller Configuration popup appears.

1. In the **Cluster Nodes** field, enter the IP address for the 2nd and 3rd controller, and then click **Save**.

    ![Cluster node IP address in controller configuration](img/tko-on-vsphere-nsxt/alb12.png)

    After you complete these steps, the primary NSX Advanced Load Balancer controller becomes the leader for the cluster and invites the other controllers to the cluster as members.

    NSX Advanced Load Balancer then performs a warm reboot of the cluster. This process can take approximately 10-15 minutes. You will be automatically logged out of the controller node where you are currently logged in. On entering the cluster IP address in the browser, you can see details about the cluster formation task.

    ![Controller initialization](img/tko-on-vsphere-nsxt/alb13.png)

The configuration of the primary (leader) controller is synchronized to the new member nodes when the cluster comes online following the reboot. Once the cluster is successfully formed, you can see the following status:

![Controller status](img/tko-on-vsphere-nsxt/alb14.png)

**Note:** In the following tasks, all NSX Advanced Load Balancer configurations are done by connecting to the NSX Advanced Load Balancer Controller Cluster IP/FQDN.

### NSX Advanced Load Balancer: Certificate Management

The default system-generated controller certificate generated for SSL/TSL connections will not have the required subject alternate name (SAN) entries. Complete the following steps to create a controller certificate:

1. Log in to the NSX Advanced Load Balancer controller and navigate to **Templates** > **Security** > **SSL/TLS Certificates**.

1. Click **Create** and select **Controller Certificate**. You can either generate a self-signed certificate, generate CSR, or import a certificate. For the purpose of this document, a self-signed certificate will be generated.

1. Provide all required details as per your infrastructure requirements and in the **Subject Alternate Name (SAN)** field, provide IP address and FQDN of all NSX Advanced Load Balancer controllers including NSX Advanced Load Balancer cluster IP and FQDN, and then click **Save**.

    ![Self-signed certificate generation](img/tko-on-vsphere-nsxt/alb15.png)

    ![Self-signed certificate generation](img/tko-on-vsphere-nsxt/alb16.png)

1. Once the certificate is created, capture the certificate contents as this is required while deploying the Tanzu Kubernetes Grid management cluster.
  To capture the certificate content, click on the Download icon next to the certificate, and then click **Copy to clipboard** under **Certificate**.

    ![Copy certificate contents](img/tko-on-vsphere-nsxt/alb17.png)

1. To replace the certificate, navigate to **Administration** > **Settings** > **Access Settings**, and click the pencil icon at the top right to edit the system access settings, and then replace the SSL/TSL certificate and click **Save**.

    ![Replace certificate](img/tko-on-vsphere-nsxt/alb18.png)

1. Log out and log in to NSX Advanced Load Balancer.

### Create Credentials

NSX Advanced Load Balancer requires credentials of VMware NSX and vCenter Server to authenticate with these endpoints. These credentials need to be created before configuring NSX Cloud.

To create a new credential, navigate to **Administration** > **User Credentials** and click **Create**.

1. Create NSX Credential: Select the credential type as NSX-T and provide a name for the credential. Under the section NSX-T Credentials, specify the username and password that NSX Advanced Load Balancer will use to authenticate with VMware NSX.

![NSX Credential](img/tko-on-vsphere-nsxt/alb19.png)

2. Create vCenter Credential: Select the credential type as vCenter and provide a name for the credential. Under the section vCenter Credentials, specify the username and password that NSX Advanced Load Balancer will use to authenticate with vCenter server.

![NSX Credential](img/tko-on-vsphere-nsxt/alb20.png)

### Create NSX Cloud and Service Engine Groups

NSX Advanced Load Balancer can be deployed in multiple environments for the same system. Each environment is called a cloud. The following procedure provides steps to create a VMware NSX cloud. As per the architecture, two service engine (SE) groups will be created.

**Service Engine Group 1**: Service engines associated with this service engine group hosts:

* Virtual services for all load balancer functionalities requested by Tanzu Kubernetes Grid management cluster and workload.
* Virtual services that load balances control plane nodes of all Tanzu Kubernetes Grid Kubernetes clusters.

**Service Engine Group 2**: Service engines associated with this service engine group hosts virtual services for all load balancer functionalities requested by Tanzu Kubernetes Grid workload clusters mapped to this SE group.  

**Note**:

* Based on your requirements, you can create additional SE groups for the workload clusters.
* Multiple workload clusters can be mapped to a single SE group.
* A Tanzu Kubernetes Grid cluster can be mapped to only one SE group for application load balancer services.

For information about mapping a specific service engine group to Tanzu Kubernetes Grid workload cluster, see [Configure NSX Advanced Load Balancer in Tanzu Kubernetes Grid Workload Cluster](#workloadako).

The following components are created in NSX Advanced Load Balancer.

<!-- /* cSpell:disable */ -->

| Object | Sample Name |
| --- | --- |
| NSX Cloud | tanzu-nsx |
| Service Engine Group 1 | tkg-mgmt-seg |
| Service Engine Group 2 | tkg-wld-seg |

<!-- /* cSpell:enable */ -->

1.  Log in to NSX Advanced Load Balancer and navigate to **Infrastructure** > **Clouds** > **Create** > **NSX-T Cloud**.

    ![Create NSX Cloud](img/tko-on-vsphere-nsxt/alb21.png)

2.  Enter cloud name and provide a object name prefix. Click **CHANGE CREDENTIALS** to connect NSX Advanced Load Balancer with VMware NSX.

    ![Enter cloud name](img/tko-on-vsphere-nsxt/alb22.png)

3.  Specify NSX-T Manager Address and select the NSX-T credential that you created earlier.

    ![Select NSX Credential](img/tko-on-vsphere-nsxt/alb23.png)

4.  Under the **Management Network** pane, select the following:

    - Transport Zone: Overlay transport zone where you connected your NSX Advanced Load Balancer management network.
    - Tier-1 Router: Tier-1 gateway where Advanced Load Balancer management network is connected.
    - Overlay Segment: Logical segment that you have created for Advanced Load Balancer management.

5.  Under the **Data Networks** pane, select the following:

    - Transport Zone: Overlay transport zone where you connected your Tanzu Kubernetes Grid VIP network.
    - Tier-1 Router: Tier-1 gateway where Tanzu Kubernetes Grid VIP network is connected.
    - Overlay Segment: Logical segment that you have created for Tanzu Kubernetes Grid VIP.

    ![Select Networks](img/tko-on-vsphere-nsxt/alb24.png)

6.  Under **vCenter Servers** pane, click **ADD**.

    ![Add vCenter Server ](img/tko-on-vsphere-nsxt/alb25.png)

7.  Specify a name for the vCenter server and click **CHANGE CREDENTIALS** to connect NSX Advanced Load Balancer with the vCenter server.

    ![Specify name to add vCenter Server and connect Advanced Load Balancer with vCenter server](img/tko-on-vsphere-nsxt/alb26.png)

8.  Select the vCenter server from the drop down and select the vCenter credential which you have created earlier.
    
    ![Select vCenter Credential](img/tko-on-vsphere-nsxt/alb27.png)

9.  Select the Content Library where Service Engine templates will be stored by NSX Advanced Load Balancer.
    
    ![Select content library for Advanced Load Balancer to store SE templates](img/tko-on-vsphere-nsxt/alb28.png)

10.  Leave the IPAM/DNS profile section empty as this will be populated later, once you have created the profiles. Click **SAVE** to finish the NSX-T cloud configuration.

     ![IPAM Profile](img/tko-on-vsphere-nsxt/alb29.png)

11. Ensure that status of the NSX-T cloud is Green post creation.

     ![NSX-T cloud status](img/tko-on-vsphere-nsxt/alb30.png)

12. Create a service engine group for Tanzu Kubernetes Grid management clusters: 
    1.  Click on the Service Engine Group tab. 
    2.  Under Select Cloud, choose the cloud created in the previous step, and click **Create**.

13. Enter a name for the Tanzu Kubernetes Grid management service engine group and set the following parameters:  

    | Parameter | Value |
    | --- | --- |
    | High availability mode | N+M |
    | Memory per Service Engine | 4 |
    | vCPU per Service Engine | 2 |

    Use the default values for the rest of the parameters.

    ![Create service engine group - basic settings](img/tko-on-vsphere-nsxt/alb31.png)

    For advanced configuration, click on the Advanced tab. Specify the vCenter server endpoint by clicking on the Add vCenter option.

    ![Create service engine group - advanced settings 01](img/tko-on-vsphere-nsxt/alb32.png)

    Select the vCenter server from the dropdown, vSphere cluster and datastore for service engine placement, and service engine name prefix, and then click **Save**.

    ![Create service engine group - advanced settings 02](img/tko-on-vsphere-nsxt/alb33.png)

14. Repeat steps 12 and 13 to create another service engine group for Tanzu Kubernetes Grid workload clusters. Once complete, there must be two service engine groups created.

    ![Service engine groups created](img/tko-on-vsphere-nsxt/alb34.png)

### Configure Network and IPAM Profile

As part of the cloud creation, NSX Advanced Load Balancer management and Tanzu Kubernetes Grid VIP networks have been configured in NSX Advanced Load Balancer. Since DHCP was not selected as the IP address management method in the cloud configuration, you have to specify pool of IP addresses that can be assigned to the service engine NICs and the virtual services that will be created in future.

To configure IP address pools for the networks, follow this procedure:

1. Navigate to **Infrastructure** > **Networks** and select the cloud that you have created earlier.

   ![Configure IP address pool](img/tko-on-vsphere-nsxt/alb35.png)

2. Click on the edit icon next for the network and configure as follows. Change the provided details as per your SDDC configuration.

   |**Network Name**|**DHCP** |**Subnet**|**Static IP Pool**|
   | --- | --- | --- | --- |
   |alb-mgmt-ls|No|172.19.71.0/24|172.19.71.6 - 172.19.71.30|
   |tkg-cluster-vip|No|172.19.75.0/26|172.19.75.2 - 172.19.75.60|

   The following snippet shows configuring one of the networks. For example: `alb-mgmt-ls`

   **Note**: Ensure that VRF Context for `alb-mgmt-ls` network is set to `Global`.

   ![Change network settings 01](img/tko-on-vsphere-nsxt/alb36.png)

   Edit the `tkg-cluster-vip` network and configure as following. The VRF Context for VIP network is set to NSX tier-1 gateway.

   ![Change network settings - VRF context of VIP network](img/tko-on-vsphere-nsxt/alb37.png)

   Once the networks are configured, the configuration must look like the following image.

   ![Network list after configuration](img/tko-on-vsphere-nsxt/alb38.png)

3. Once the networks are configured, set the default routes for the networks by navigating to **Infrastructure** > **Routing**.

   ![Configure default routes for networks](img/tko-on-vsphere-nsxt/alb39.png)

   The default gateway for the `alb-mgmt-ls` network is set in the global VRF context and for the `tkg-cluster-vip` network, the VRF Context is set to NSX tier-1 gateway.

   To set the default gateway for the `alb-mgmt-ls` network, click **CREATE** under the global VRF context and set the default gateway to gateway of the NSX Advanced Load Balancer management subnet.

   ![Configure default gateway of the Advanced Load Balancer management network](img/tko-on-vsphere-nsxt/alb40.png)

      To set the default gateway for the `tkg-cluster-vip` network, click **CREATE** under the tier-1 gateway VRF context and set the default gateway to gateway of the VIP network subnet.

   ![Configure default gateway of the VIP network subnet](img/tko-on-vsphere-nsxt/alb41.png)

   The final configuration is shown below:

   ![Settings after routing configuration](img/tko-on-vsphere-nsxt/alb42.png)

#### Create IPAM Profile in NSX Advanced Load Balancer and Attach to Cloud

At this point, all the required networks related to Tanzu functionality are configured in NSX Advanced Load Balancer. NSX Advanced Load Balancer provides IPAM service for Tanzu Kubernetes Grid cluster VIP network and NSX ALB management network.  

Complete the following steps to create an IPAM profile and once created, attach it to the NSX-T cloud created earlier.  

1. Log in to NSX Advanced Load Balancer and navigate to **Templates** > **IPAM/DNS Profiles** > **Create** > **IPAM Profile**.

   ![Create IPAM profile](img/tko-on-vsphere-nsxt/alb43.png)

   Provide the following details, and then click **Save**.

     |**Parameter**|**Value**|
     | --- | --- |
     |Name|tkg-ipam|
     |Type|AVI Vintage IPAM|
     |Cloud for Usable Networks|tanzu-nsx|
     |Usable Networks|alb-mgmt-ls<br>tkg-cluster-vip|

    ![Specify details for creating IPAM profile](img/tko-on-vsphere-nsxt/alb44.png)

2. Click **Create** > **DNS Profile** and provide the domain name.

   ![Enter domain name](img/tko-on-vsphere-nsxt/alb45.png)

3. Attach the IPAM and DNS profiles to the NSX-T cloud.
    1. Navigate to **Infrastructure** > **Clouds**.
    2. Edit the `tanzu-nsx` cloud.
    3. Under IPAM/DNS section, choose the IPAM and DNS profiles created earlier and save the updated configuration.  

     ![Select IPAM and DNS profiles](img/tko-on-vsphere-nsxt/alb46.png)

4. Under the section **DNS Resolvers**, click **ADD** to add the DNS server that NSX-T cloud will use to resolve the hostname or FQDN of the components that will be created later.

     ![Add DNS server under DNS resolvers](img/tko-on-vsphere-nsxt/alb47.png)

   Enter a name for the DNS and click **ADD** under **Name Servers** to add your infrastructure DNS servers. Optionally, you can specify the TTL for the DNS.

    ![Specify DNS server name and add](img/tko-on-vsphere-nsxt/alb48.png)

This completes the NSX Advanced Load Balancer configuration. The next step is to deploy and configure a bootstrap machine which will be used to deploy and manage Tanzu Kubernetes clusters.

## Configure Separate VIP Networks for Management and Workload Clusters Where NSX ALB Provides Control Plane HA

In Tanzu Kubernetes Grid v1.6, you can configure separate VIP networks for the control plane HA and for application load balancer and ingress service. This feature lets you ensure the security of the clusters by providing you an option to expose the endpoint of your management or the workload cluster and the load balancer service and ingress service in the cluster, in different networks. 

You can configure the following parameters to expose the endpoints or the services in the management cluster and the workload clusters in different VIP networks. 

For the workload cluster:

- AVI_DATA_NETWORK
- AVI_DATA_NETWORK_CIDR
- AVI_CONTROL_PLANE_NETWORK
- AVI_CONTROL_PLANE_NETWORK_CIDR

Where `AVI_DATA_NETWORK` is the network that you use load balancing (l4/l7) the application deployed in the workload cluster. The network `AVI_CONTROL_PLANE_NETWORK` is the network that provides L4 load balancing to the control plane nodes of the workload clusters. 

For the management cluster:

- AVI_MANAGEMENT_CLUSTER_VIP_NETWORK_NAME
- AVI_MANAGEMENT_CLUSTER_VIP_NETWORK_CIDR
- AVI_MANAGEMENT_CLUSTER_CONTROL_PLANE_VIP_NETWORK_NAME
- AVI_MANAGEMENT_CLUSTER_CONTROL_PLANE_VIP_NETWORK_CIDR

Where `AVI_MANAGEMENT_CLUSTER_VIP_NETWORK_NAME` is the network that you use for load balancing the application deployed in the management cluster. The network `AVI_MANAGEMENT_CLUSTER_CONTROL_PLANE_VIP_NETWORK_NAME` is the network that provides L4 load balancing to the control plane nodes of the workload clusters. 

As per the TKO architecture, the control plane VIP of the management cluster, shared services cluster and the workload clusters, is served from the same network. So, the network `AVI_CONTROL_PLANE_NETWORK` and `AVI_MANAGEMENT_CLUSTER_CONTROL_PLANE_VIP_NETWORK_NAME` points to the same portgroup/logical segment to implement TKO architecture.

**Note:** This document makes use of the single network `tkg-cluster-vip` for both control plane VIP and application load balancing of all TKG clusters.

## <a id="configurebootstrap"> </a> Deploy and Configure Bootstrap Machine

The deployment of the Tanzu Kubernetes Grid management and workload clusters is facilitated by setting up a bootstrap machine where you install the Tanzu CLI and Kubectl utilities which are used to create and manage the Tanzu Kubernetes Grid instance. This machine also keeps the Tanzu Kubernetes Grid and Kubernetes configuration files for your deployments. The bootstrap machine can be a laptop, host, or server running on Linux, macOS, or Windows that you deploy management and workload clusters from.

The bootstrap machine runs a local `kind` cluster when Tanzu Kubernetes Grid management cluster deployment is started. Once the `kind` cluster is fully initialized, the configuration is used to deploy the actual management cluster on the backend infrastructure. After the management cluster is fully configured, the local `kind` cluster is deleted and future configurations are performed with the Tanzu CLI.

For this deployment, a CentOS 7 based virtual machine is used as the bootstrap machine. For information on how to configure a macOS or Windows machine, see [Install the Tanzu CLI and Other Tools](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.6/vmware-tanzu-kubernetes-grid-16/GUID-install-cli.html).

The bootstrap machine must meet the following prerequisites:

- A minimum of 6 GB of RAM and a 2-core CPU.
- System time is synchronized with a Network Time Protocol (NTP) server.
- Docker and containerd binaries are installed. For instructions on how to install Docker, see the official [Docker documentation](https://docs.docker.com/engine/install/centos/).
- Ensure that the bootstrap VM is connected to Tanzu Kubernetes Grid management network `tkg-mgmt-ls`.

To install Tanzu CLI, Tanzu Plugins and Kubectl utility on the bootstrap machine, follow the instructions below:

1. Download and unpack the following packages from [VMware Tanzu Kubernetes Grid Download Product page](https://customerconnect.vmware.com/en/downloads/details?downloadGroup=TKG-160&productId=988&rPId=93384).

    - VMware Tanzu CLI 1.6.0 for Linux

    - kubectl cluster cli v1.23.8 for Linux

2. Execute the following commands to install Tanzu Kubernetes Grid CLI, Kubectl CLI, and Carvel tools.

    ```bash
    ## Install Tanzu Kubernetes Grid CLI
    tar -zxvf tanzu-cli-bundle-linux-amd64.tar.gz
    install cli/core/v0.25.0/tanzu-core-linux_amd64 /usr/local/bin/tanzu
    chmod +x /usr/local/bin/tanzu

    ## Verify Tanzu CLI version

    [root@tkg160-bootstrap ~]# tanzu version

     version: v0.25.0
     buildDate: 2022-08-25
     sha: 6288c751-dirty

    ## Install Tanzu Plugins

    [root@tkg160-bootstrap ~]# tanzu plugin sync

    Checking for required plugins...
    Installing plugin 'login:v0.25.0'
    Installing plugin 'management-cluster:v0.25.0'
    Installing plugin 'package:v0.25.0'
    Installing plugin 'pinniped-auth:v0.25.0'
    Installing plugin 'secret:v0.25.0'
    Installing plugin 'telemetry:v0.25.0'
    Successfully installed all required plugins
    ✔  Done

    ## Verify the plugins are installed

    [root@tkg160-bootstrap ~]# tanzu plugin list
    NAME                DESCRIPTION                                                        SCOPE       DISCOVERY  VERSION  STATUS
    login               Login to the platform                                              Standalone  default    v0.25.0  installed
    management-cluster  Kubernetes management-cluster operations                           Standalone  default    v0.25.0  installed
    package             Tanzu package management                                           Standalone  default    v0.25.0  installed
    pinniped-auth       Pinniped authentication operations (usually not directly invoked)  Standalone  default    v0.25.0  installed
    secret              Tanzu secret management                                            Standalone  default    v0.25.0  installed
    telemetry           Configure cluster-wide telemetry settings                          Standalone  default    v0.25.0  installed

    ## Install Kubectl CLI

    gunzip kubectl-linux-v1.23.8+vmware.2.gz
    mv kubectl-linux-v1.23.8+vmware.2 /usr/local/bin/kubectl
    chmod +x /usr/local/bin/kubectl

    # Install Carvel tools

    ##Install ytt
    cd ./cli
    gunzip ytt-linux-amd64-v0.35.1+vmware.1.gz
    chmod +x ytt-linux-amd64-v0.35.1+vmware.1.gz && mv ./ytt-linux-amd64-v0.35.1+vmware.1.gz /usr/local/bin/ytt

    ##Install kapp

    gunzip kapp-linux-amd64-v0.49.0+vmware.1
    chmod +x kapp-linux-amd64-v0.49.0+vmware.1 && mv ./kapp-linux-amd64-v0.49.0+vmware.1 /usr/local/bin/kapp

    ##Install kbld

    gunzip kbld-linux-amd64-v0.34.0+vmware.1
    chmod +x kbld-linux-amd64-v0.31.0+vmware.1 && mv ./kbld-linux-amd64-v0.31.0+vmware.1 /usr/local/bin/kbld

    ##Install impkg

    gunzip imgpkg-linux-amd64-v0.29.0+vmware.1
    chmod +x imgpkg-linux-amd64-v0.18.0+vmware.1 && mv ./imgpkg-linux-amd64-v0.18.0+vmware.1 /usr/local/bin/imgpkg
    ```

3. Validate Carvel tools installation using the following commands.
    ```bash
    ytt version
    kapp version
    kbld version
    imgpkg version
    ```
4. Install `yq`. `yq` is a lightweight and portable command-line YAML processor. `yq` uses `jq`-like syntax but works with YAML and JSON files.
    ```bash
    cd /root
    wget https://github.com/mikefarah/yq/releases/download/v4.24.5/yq_linux_amd64.tar.gz
    tar -xvf yq_linux_amd64.tar.gz && mv yq_linux_amd64 /usr/local/bin/yq
    ```
5. Install `kind`.
    ```bash
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.11.1/kind-linux-amd64
    chmod +x ./kind
    mv ./kind /usr/local/bin/kind
    ```
6. Create an SSH key pair.

   An SSH key pair is required for Tanzu CLI to connect to vSphere from the bootstrap machine.  

   The public key part of the generated key is passed during the Tanzu Kubernetes Grid management cluster deployment.
   ```bash
   ## Generate SSH key pair
   ## When prompted enter file in which to save the key (/root/.ssh/id_rsa): press Enter to accept the default and provide password
   ssh-keygen -t rsa -b 4096 -C "email@example.com"

   ## Add the private key to the SSH agent running on your machine and enter the password you created in the previous step
   ssh-add ~/.ssh/id_rsa
   ## If the above command fails, execute "eval $(ssh-agent)" and then rerun the command
   ```

All required packages are now installed, and the required configurations are in place in the bootstrap virtual machine. The next step is to deploy the Tanzu Kubernetes Grid management cluster.

### <a id="importbaseimage"> </a> Import Base Image Template for Tanzu Kubernetes Grid Cluster Deployment

Before you proceed with the management cluster creation, ensure that the base image template is imported into vSphere and is available as a template. To import a base image template into vSphere:

1. Go to the [Tanzu Kubernetes Grid downloads page](https://customerconnect.vmware.com/en/downloads/details?downloadGroup=TKG-160&productId=988&rPId=93384) and download a Tanzu Kubernetes Grid OVA for the cluster nodes.
    - For the management cluster, this must be either Photon or Ubuntu based Kubernetes v1.23.8 OVA.
    **Note:** Custom OVA with a custom Tanzu Kubernetes release (TKr) is also supported, as described in [Build Machine Images](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.6/vmware-tanzu-kubernetes-grid-16/GUID-build-images-index.html).
    - For workload clusters, OVA can have any supported combination of OS and Kubernetes version, as packaged in a Tanzu Kubernetes release.

    **Note**: Make sure you download the most recent OVA base image templates in the event of security patch releases. You can find updated base image templates that include security patches on the Tanzu Kubernetes Grid product download page.

1. In the vSphere client, right-click an object in the vCenter Server inventory and select **Deploy OVF template**.

1. Select Local file, click the button to upload files, and navigate to the downloaded OVA file on your local machine.

1. Follow the installer prompts to deploy a VM from the OVA.

1. Click **Finish** to deploy the VM. When the OVA deployment finishes, right-click the VM and select **Template** > **Convert to Template**.

    **Note:** Do not power on the VM before you convert it to a template.

1. **If using non administrator SSO account**: In the VMs and Templates view, right-click the new template, select **Add Permission**, and assign the **tkg-user** to the template with the **TKG role**.

For information about how to create the user and role for Tanzu Kubernetes Grid, see [Required Permissions for the vSphere Account](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.6/vmware-tanzu-kubernetes-grid-16/GUID-mgmt-clusters-vsphere.html#required-permissions-for-the-vsphere-account-5).

## <a id="deploy-mgmt-cluster"> </a> Deploy Tanzu Kubernetes Grid Management Cluster

The management cluster is a Kubernetes cluster that runs Cluster API operations on a specific cloud provider to create and manage workload clusters on that provider.

The management cluster is also where you configure the shared and in-cluster services that the workload clusters use.

You can deploy management clusters in two ways:

- Run the Tanzu Kubernetes Grid installer, a wizard interface that guides you through the process of deploying a management cluster. This is the recommended method.
- Create and edit YAML configuration files, and use them to deploy a management cluster with the CLI commands.

The following procedure provides the required steps to deploy Tanzu Kubernetes Grid management cluster using the installer interface.

1. To launch the UI installer wizard, run the following command on the bootstrap machine:  

    `tanzu management-cluster create --ui --bind <bootstrapper-ip>:<port> --browser none`  

    For example:  
    `tanzu management-cluster create --ui --bind 172.19.10.4:8000 --browser none` 

1. Access Tanzu UI wizard by opening a browser and entering: http://<bootstrapper-ip:port/  

 	 ![Tanzu Kubernetes Grid installer UI](img/tko-on-vsphere-nsxt/tkg-installer-01.png)

1. On the VMware vSphere tile, click **DEPLOY**.

1. In the IaaS Provider section, enter the IP address/FQDN and credentials of the vCenter server where the Tanzu Kubernetes Grid management cluster will be deployed. (Optional) you can skip the vCenter SSL thumbprint verification.

   ![IaaS provider details](img/tko-on-vsphere-nsxt/tkg-installer-02.png)

1. Click **CONNECT** and select "DEPLOY TKG MANAGEMENT CLUSTER".

     ![TKG Install Selection](img/tko-on-vsphere-nsxt/tkg-installer-03.png)

1. Select the data center and provide the SSH public Key generated while configuring the bootstrap VM.  
    If you have saved the SSH key in the default location, run the following command in your bootstrap machine to get the SSH public key.

    `cat /root/.ssh/id_rsa.pub`

1. Click **NEXT**.

    ![IaaS provider details after connection](img/tko-on-vsphere-nsxt/tkg-installer-04.png)

1. On the Management Cluster Settings section, provide the following details and click **Next**.

    * Based on the environment requirements, select appropriate deployment type for the Tanzu Kubernetes Grid management cluster:

        * Development: Recommended for Dev or POC environments

        * Production: Recommended for Production environments

        It is recommended to set the instance type to `Large` or above. For the purpose of this document, we will proceed with deployment type `Production` and instance type `Medium`.

    * Management Cluster Name: Name for your management cluster.
    * Control Plane Endpoint Provider: Select NSX Advanced Load Balancer for Control Plane HA.
    * Control Plane Endpoint: This is an optional field. If left blank, NSX Advanced Load Balancer will assign an IP address from the pool defined for the network "tkg-cluster-vip".  
        If you need to provide an IP address, pick an IP address from “tkg_cluster_vip_pg”  static IP pools configured in AVI and ensure that the IP address is unused.
    * Machine Health Checks: Enable
    * Enable Audit Logging: Enable for audit logging for Kubernetes API server and node VMs. Choose as per your environment needs. For more information, see [Audit Logging](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.6/vmware-tanzu-kubernetes-grid-16/GUID-troubleshooting-tkg-audit-logging.html).

    ![Management cluster settings](img/tko-on-vsphere-nsxt/tkg-installer-05.png)

1. On the NSX Advanced Load Balancer section, provide the following information and click **Next**.

    * Controller Host: NSX Advanced Load Balancer Controller IP/FQDN (ALB Controller cluster IP/FQDN of the controller cluster is configured)
    * Controller credentials: Username and Password of NSX Advanced Load Balancer
    * Controller certificate: Paste the contents of the Certificate Authority that is used to generate your controller certificate into the **Controller Certificate Authority** text box.

    ![NSX ALB settings for management cluster](img/tko-on-vsphere-nsxt/tkg-installer-06.png)

1. Once these details are provided, click **VERIFY CREDENTIALS** and choose the following parameters.

    * Cloud Name: Name of the cloud created while configuring NSX Advanced Load Balancer `tanzu-vcenter-01`.
    * Workload Cluster Service Engine Group Name: Name of the service engine group created for Tanzu Kubernetes Grid workload clusters created while configuring NSX Advanced Load Balancer `tkg-wld-seg`.
    * Workload Cluster Data Plane VIP Network Name: Select `tkg-cluster-vip` network and the subnet associated with it.
    * Workload Cluster Control Plane VIP Network Name: Select `tkg-cluster-vip` network and the subnet associated with it.
    * Management Cluster Service Engine Group Name: Name of the service engine group created for Tanzu Kubernetes Grid management cluster created while configuring NSX Advanced Load Balancer `tkg-mgmt-seg`.
    * Management Cluster Data Plane VIP network Name: Select `tkg-cluster-vip` network and the subnet associated with it.
    * Management Cluster Control Plane VIP network Name: Select `tkg-cluster-vip` network and the subnet associated with it.
    * Cluster Labels: To adhere to the architecture defining a label is mandatory. Provide required labels, for example, `type: management`.

		**Note:** Based on your requirements, you may specify multiple labels.

         ![NSX ALB settings for management cluster - verify credentials](img/tko-on-vsphere-nsxt/tkg-installer-07.png)

   **Note:** With above configurations, when Tanzu Kubernetes Grid clusters (shared services or workload) are tagged with label `type: management`, `ako` pod gets deployed on the cluster, and any applications hosted on the cluster that requires the load balancing service is exposed through network `tkg-cluster-vip` and the virtual service is placed on SE group `tkg-mgmt-seg`.
                
1. (Optional) On the Metadata page, you can specify location and labels and click **Next**.

    ![metadata page for management cluster](img/tko-on-vsphere-nsxt/tkg-installer-08.png)

1. On the Resources section, specify the resources to be consumed by the Tanzu Kubernetes Grid management cluster and click **NEXT**.

    ![Resources page for management cluster](img/tko-on-vsphere-nsxt/tkg-installer-09.png)

1. On the Kubernetes Network section, select the Tanzu Kubernetes Grid management network (`tkg-mgmt-ls`) where the control plane and worker nodes will be placed during management cluster deployment. Ensure that the network has DHCP service enabled. Optionally, change the pod and service CIDR.

    If the Tanzu environment is placed behind a proxy, enable proxy and provide proxy details:

    * If you set `http-proxy`, you must also set `https-proxy` and vice-versa.
    * For the `no-proxy` section:

      * For Tanzu Kubernetes Grid management and workload clusters, `localhost`, `127.0.0.1`, the values of `CLUSTER_CIDR` and `SERVICE_CIDR`, `.svc`, and `.svc.cluster.local` are appended along with the user specified values.
    * **Note**: If the Kubernetes cluster needs to communicate with external services and infrastructure endpoints in your Tanzu Kubernetes Grid environment, ensure that those endpoints are reachable by your proxies or add them to `TKG_NO_PROXY`. Depending on your environment configuration, this may include, but is not limited to, your OIDC or LDAP server, Harbor, NSX, NSX Advanced Load Balancer, and vCenter.
    * For vSphere, you must manually add the CIDR of Tanzu Kubernetes Grid management network and Cluster VIP networks that includes the IP address of your control plane endpoints, to `TKG_NO_PROXY`.

    ![Kubernetes Network page for management cluster](img/tko-on-vsphere-nsxt/tkg-installer-10.png)

1. (Optional) Specify identity management with OIDC or LDAP. For the purpose of this document, identity management integration is deactivated.

    If you would like to enable identity management, see **Enable and Configure Identity Management During Management Cluster Deployment** section in the Tanzu Kubernetes Grid Integration with Pinniped Deployment Guide.

    ![Identity management for management cluster](img/tko-on-vsphere-nsxt/tkg-installer-11.png)  

1. Select the OS image that will be used for the management cluster deployment.

    Note: This list will appear empty if you don’t have a compatible template present in your environment. Refer steps provided in [Import Base Image template for TKG Cluster deployment](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.6/vmware-tanzu-kubernetes-grid-16/GUID-mgmt-clusters-vsphere.html#import-a-base-image-template-into-vsphere-4).

    ![OS image for management cluster](img/tko-on-vsphere-nsxt/tkg-installer-12.png)

1. Select “Participate in the Customer Experience Improvement Program”, if you so desire.

   ![CEIP Selection](img/tko-on-vsphere-nsxt/tkg-installer-13.png)

1. Click **REVIEW CONFIGURATION**.

   ![CEIP Selection](img/tko-on-vsphere-nsxt/tkg-installer-14.png)

    As of now, it is not possible to deploy management cluster for NSX cloud from the Tanzu Kubernetes Grid installer UI as one of the required field for NSX cloud is not exposed in the UI and it needs to be manually inserted in the cluster deployment yaml.

1. Click on **EXPORT CONFIGURATION** to download the deployment yaml file.

   ![Deployment logs in installer UI](img/tko-on-vsphere-nsxt/tkg-installer-15.png)

1. Edit the file and insert the key `AVI_NSXT_T1LR`. The value of this key is the tier-1 gateway where you have connected the `tkg-mgmt-ls` network. In this example, the value is set to `tanzu-t1-gw`. 

A sample file used for the management cluster deployment is shown below.

```yaml
AVI_CA_DATA_B64: LS0tLS1CRUdJTiBDRVJUSU....z0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQ==
AVI_CLOUD_NAME: tkg-nsxt
AVI_CONTROL_PLANE_HA_PROVIDER: "true"
AVI_CONTROL_PLANE_NETWORK: tkg-cluster-vip
AVI_CONTROL_PLANE_NETWORK_CIDR: 172.19.75.0/26
AVI_CONTROLLER: alb.tanzu.lab
AVI_DATA_NETWORK: tkg-cluster-vip
AVI_DATA_NETWORK_CIDR: 172.19.75.0/26
AVI_ENABLE: "true"
AVI_LABELS: |
    'type': 'management'
AVI_MANAGEMENT_CLUSTER_CONTROL_PLANE_VIP_NETWORK_CIDR: 172.19.75.0/26
AVI_MANAGEMENT_CLUSTER_CONTROL_PLANE_VIP_NETWORK_NAME: tkg-cluster-vip
AVI_MANAGEMENT_CLUSTER_SERVICE_ENGINE_GROUP: tkg-mgmt-seg
AVI_MANAGEMENT_CLUSTER_VIP_NETWORK_CIDR: 172.19.75.0/26
AVI_MANAGEMENT_CLUSTER_VIP_NETWORK_NAME: tkg-cluster-vip
AVI_NSXT_T1LR: /infra/tier-1s/tanzu-t1-gw
AVI_PASSWORD: <encoded:Vk13YXJlMSE=>
AVI_SERVICE_ENGINE_GROUP: tkg-wld-seg
AVI_USERNAME: admin
CLUSTER_CIDR: 100.96.0.0/11
CLUSTER_NAME: tkg160-mgmt-nsxt
CLUSTER_PLAN: prod
ENABLE_AUDIT_LOGGING: "false"
ENABLE_CEIP_PARTICIPATION: "false"
ENABLE_MHC: "true"
IDENTITY_MANAGEMENT_TYPE: none
INFRASTRUCTURE_PROVIDER: vsphere
OS_ARCH: amd64
OS_NAME: photon
OS_VERSION: "3"
SERVICE_CIDR: 100.64.0.0/13
TKG_HTTP_PROXY_ENABLED: "false"
VSPHERE_CONTROL_PLANE_DISK_GIB: "40"
VSPHERE_CONTROL_PLANE_ENDPOINT: ""
VSPHERE_CONTROL_PLANE_MEM_MIB: "8192"
VSPHERE_CONTROL_PLANE_NUM_CPUS: "2"
VSPHERE_DATACENTER: /Tanzu-DC
VSPHERE_DATASTORE: /Tanzu-DC/datastore/vsanDatastore
VSPHERE_FOLDER: /Tanzu-DC/vm/TKG-Mgmt-VMs
VSPHERE_INSECURE: "true"
VSPHERE_NETWORK: /Tanzu-DC/network/tkg-mgmt-ls
VSPHERE_PASSWORD: <encoded:Vk13YXJlMSE=>
VSPHERE_RESOURCE_POOL: /Tanzu-DC/host/Tanzu-CL01/Resources/TKG-Mgmt
VSPHERE_SERVER: tanzu-vc01.tanzu.lab
VSPHERE_SSH_AUTHORIZED_KEY: ssh-rsa AAAAB3NzaC1yc2....zyr3RvifuokfrQ== manish@vmware
VSPHERE_TLS_THUMBPRINT: ""
VSPHERE_USERNAME: administrator@vsphere.local
VSPHERE_WORKER_DISK_GIB: "40"
VSPHERE_WORKER_MEM_MIB: "8192"
VSPHERE_WORKER_NUM_CPUS: "2"
CONTROL_PLANE_MACHINE_COUNT: "3"
WORKER_MACHINE_COUNT: "3"
DEPLOY_TKG_ON_VSPHERE7: true
```
While the cluster is being deployed, you will find that a virtual service is created in NSX Advanced Load Balancer and new service engines are deployed in vCenter by NSX Advanced Load Balancer and the service engines are mapped to the SE Group `tkg-mgmt-seg`.​​

The installer automatically sets the context to the Tanzu Kubernetes Grid management cluster on the bootstrap machine. Now, you can access the Tanzu Kubernetes Grid management cluster from the bootstrap machine and perform additional tasks such as verifying the management cluster health, deploying the workload clusters, etc.

To get the status of Tanzu Kubernetes Grid management cluster, run the following command:

`tanzu management-cluster get`

![Management cluster status CLI output - tanzu CLI](img/tko-on-vsphere-nsxt/tkg-mgmt-cl-status.png)

Use `kubectl get nodes` command to get the status of the Tanzu Kubernetes Grid management cluster nodes.

![Management cluster nodes status CLI output - kubectl](img/tko-on-vsphere-nsxt/tkg-mgmt-cl-nodes.png)

The Tanzu Kubernetes Grid management cluster is successfully deployed and now you can proceed with registering it with Tanzu Mission Control and creating shared services and workload clusters.

## What to Do Next

### <a id="tmc-integration"> </a> Register Management Cluster with Tanzu Mission Control

If you want to register your management cluster with Tanzu Mission Control, see [Register Your Management Cluster with Tanzu Mission Control](tko-saas-services.md#tmc-tkg-mgmt).

### <a id="createsharedsvc"> </a> Deploy Tanzu Kubernetes Grid Shared Services Cluster

Each Tanzu Kubernetes Grid instance can have only one shared services cluster. Create a shared services cluster if you intend to deploy Harbor.  

The procedures for deploying a shared services cluster and workload cluster are almost the same. A key difference is that you add the `tanzu-services` label to the shared services cluster as its cluster role. This label identifies the shared services cluster to the management cluster and workload clusters.  

Another difference between the shared services cluster and workload clusters is that shared services clusters will be applied with the “Cluster Labels” which were defined while deploying the management cluster. This is to enforce that only shared service cluster will make use of the Tanzu Kubernetes Grid cluster VIP or data network for application load balancing purposes and the virtual services are deployed on “Service Engine Group 1”.

After the management cluster is registered with Tanzu Mission Control, the deployment of the Tanzu Kubernetes clusters can be done in just a few clicks. The procedure for creating Tanzu Kubernetes clusters is as follows.

1. Navigate to the Clusters tab and click **Create Cluster**.

   ![Create cluster](img/tko-on-vsphere-nsxt/shared-svc-tmc01.png)

1. Under the Create cluster page, select the management cluster which you registered in the previous step and click **Continue to create cluster**.

    ![Select management cluster for shared services cluster](img/tko-on-vsphere-nsxt/shared-svc-tmc02.png)

1. Select the provisioner for creating the workload cluster (shared services cluster). Provisioner reflects the vSphere namespaces that you have created and associated with the management cluster.

    ![Select provisioner for shared services cluster](img/tko-on-vsphere-nsxt/shared-svc-tmc03.png)

1. Enter a name for the cluster and select the cluster group to which you want to attach your cluster. Cluster names must be unique within an organization. For the cluster group, you can optionally enter a description and apply labels.

    ![Cluster name and cluster group](img/tko-on-vsphere-nsxt/shared-svc-tmc04.png)

1. On the Configure page, specify the following items:

   * Select the vSphere data center where the shared services cluster will be deployed.
   * Select the Kubernetes version to use for the cluster. The latest supported version is preselected for you. You can choose the desired Kubernetes version by clicking on the down arrow button.
   * You can optionally define an alternative CIDR for the pod and the service. The pod CIDR and service CIDR cannot be changed after the cluster is created.
   * You can optionally specify a proxy configuration to use for this cluster.

     **Note:** The scope of this document doesn't cover the use of a proxy for Tanzu Kubernetes Grid deployment. If your environment uses a proxy server to connect to the internet, ensure that the proxy configuration object includes the CIDRs for the pod, ingress, and egress from the workload network of the Management Cluster in the **No proxy list**, as described in [Create a Proxy Configuration Object](https://docs.vmware.com/en/VMware-Tanzu-Mission-Control/services/tanzumc-using/GUID-B3416BFE-ED22-46CD-AFFE-E0A16FE18000.html).

     ![Kubernetes version, network and storage options](img/tko-on-vsphere-nsxt/shared-svc-tmc05.png)

1.  Select the resources for backing this cluster. Provide the resource pool, VM folder, and datastore information.

     ![Resources backing the cluster](img/tko-on-vsphere-nsxt/shared-svc-tmc06.png)

1. Select the high availability mode for the control plane nodes of the workload cluster. For a production deployment, it is recommended to deploy a highly available workload cluster.

    ![select between single node and HA mode for control plane](img/tko-on-vsphere-nsxt/shared-svc-tmc07.png)

1. Customize the default node pool for your workload cluster.

    * Specify the number of worker nodes to provision.
    * Select the instance type.

    ![select between single node and HA mode for control plane](img/tko-on-vsphere-nsxt/shared-svc-tmc08.png)

1. If you have deployed your management cluster with Avi_Labels, you can pass the same labels in the key:value format in the shared services cluster configuration to leverage the VIP network and service engine group that you have specified for the workload cluster in the management cluster configuration.
    Click **CREATE CLUSTER** to start provisioning your workload cluster.

    ![Start cluster provisioning](img/tko-on-vsphere-nsxt/shared-svc-tmc09.png)

1. Once the cluster is created, you can check the status from Tanzu Mission Control.

    ![Cluster status after provisioning](img/tko-on-vsphere-nsxt/shared-svc-tmc10.png)

	Cluster creation takes approximately 15-20 minutes to complete. After the cluster deployment completes, ensure that agent and extensions health shows green.

1. Connect to the Tanzu Management Cluster context and apply the following labels.

   ```bash
   ## Connect to tkg management cluster

   kubectl config use-context tkg160-mgmt-nsxt-admin@tkg160-mgmt-nsxt

   ## verify the shared service cluster creation

   tanzu cluster list
   NAME                  NAMESPACE  STATUS   CONTROLPLANE  WORKERS  KUBERNETES        ROLES   PLAN  TKR
   tkg160-sharedsvc-nsx  default    running  3/3           3/3      v1.23.8+vmware.2  <none>  prod  v1.23.8---vmware.2-tkg.1

   ## Add the tanzu-services label to the shared services cluster as its cluster role. In the following command “tkg-shared-svc” is the name of the shared service cluster

   kubectl label cluster.cluster.x-k8s.io/tkg160-sharedsvc-nsx cluster-role.tkg.tanzu.vmware.com/tanzu-services="" --overwrite=true
   ```

1. Get the admin context of the shared service cluster using the following commands and switch the context to the shared services cluster.

   ```bash
   ## Use the following command to get the admin context of shared services Cluster. In the following command “tkg-shared- svc” is the name of the shared services cluster

   tanzu cluster kubeconfig get tkg160-sharedsvc-nsx --admin

   ## Use the following command to use the context of shared services cluster

   kubectl config use-context tkg160-sharedsvc-nsx-admin@tkg160-sharedsvc-nsx

   # Verify that ako pod gets deployed in avi-system namespace

   kubectl get pods -n avi-system
   NAME    READY   STATUS    RESTARTS   AGE
   ako-0   1/1     Running   0          41s
   ```

Now that the shared services cluster is successfully created, you may proceed with creating the workload cluster.

### <a id="createworkload"> </a> Deploy Tanzu Kubernetes Grid Workload Cluster

Complete the following steps to deploy workload clusters from Tanzu Mission Control:

1.  Navigate to the Clusters tab and click **Create Cluster**.

1. Under the create cluster page, select the management cluster which you registered in the previous step and click **Continue to create cluster**.

1. Select the provisioner for creating the workload cluster. Provisioner reflects the vSphere namespaces that you have created and that are associated with the management cluster.

    ![Select provisioner to create workload cluster](img/tko-on-vsphere-nsxt/wld-tmc01.png)

1. Enter a name for the cluster and select the cluster group  to which you want to attach your cluster. Cluster names must be unique within an organization. For cluster groups, you can optionally enter a description and apply labels.

    ![Enter cluster name and select cluster group for workload cluster](img/tko-on-vsphere-nsxt/wld-tmc02.png)

1. On the Configure page, specify the following items:

    * Select the Kubernetes version to use for the cluster. The latest supported version is preselected for you. You can choose the appropriate Kubernetes version by clicking on the down arrow button.
    * You can optionally define an alternative CIDR for the pod and service. The Pod CIDR and Service CIDR cannot be changed after the cluster is created.
    * You can optionally specify a proxy configuration to use for this cluster.

      **Note:** The scope of this document doesn't cover the use of a proxy for Tanzu Kubernetes Grid deployment. If your environment uses a proxy server to connect to the internet, ensure that the proxy configuration object includes the CIDRs for the pod, ingress, and egress from the workload network of the Management Cluster in the **No proxy list**, as described in [Create a Proxy Configuration Object](https://docs.vmware.com/en/VMware-Tanzu-Mission-Control/services/tanzumc-using/GUID-B3416BFE-ED22-46CD-AFFE-E0A16FE18000.html).

     ![Kubernetes version, network and storage options for workload cluster](img/tko-on-vsphere-nsxt/wld-tmc03.png)

1. Select the resources for backing this cluster. Provide the Resource Pool, VM folder and Datastore information.

    ![Resources backing the workload cluster](img/tko-on-vsphere-nsxt/wld-tmc04.png)

1. Select the high availability mode for the control plane nodes of the workload cluster. For a production deployment, it is recommended to deploy a highly available workload cluster.

    ![Select between single node or HA mode for workload cluster](img/tko-on-vsphere-nsxt/wld-tmc05.png)

1. (Optional) Customize the default node pool for your workload cluster.

   * Specify the number of worker nodes to provision.
   * Select the instance type for workload clusters.

   ![Edit Node Pool](img/tko-on-vsphere-nsxt/wld-tmc06.png)

1. Click **CREATE CLUSTER** to start provisioning your workload cluster.

    ![Start cluster provisioning](img/tko-on-vsphere-nsxt/wld-tmc07.png)

1. You can monitor the workload cluster creation from the Tanzu Mission Control console.

    ![Cluster creation status](img/tko-on-vsphere-nsxt/wld-tmc08.png)

    Cluster creation takes approximately 15-20 minutes to complete.

1. After the cluster deployment completes, ensure that agent and extensions health shows green.

    ![Agent and extensions health status](img/tko-on-vsphere-nsxt/wld-tmc09.png)

#### <a id="workloadako"> </a> Configure NSX Advanced Load Balancer in Tanzu Kubernetes Grid Workload Cluster

Tanzu Kubernetes Grid v1.5.x management clusters with NSX Advanced Load Balancer are deployed with 2 AKODeploymentConfigs.

* `install-ako-for-management-cluster`: default config for management cluster
* `install-ako-for-all`:  default config for all Tanzu Kubernetes Grid clusters. By default, any clusters that match the cluster labels defined in `install-ako-for-all` will reference this file for their virtual IP networks, service engine (SE) groups, and L7 ingress. As part of this architecture, only shared service cluster makes use of the configuration defined in the default AKODeploymentConfig `install-ako-for-all`.

As per the defined architecture, workload clusters must make use of **tkg-wld-seg** and VIP Network **tkg-cluster-vip** for application load balancer services.

* Creating a new AKODeploymentConfig in the Tanzu Kubernetes Grid management cluster. This AKODeploymentConfig file dictates which specific SE group and VIP network that the workload clusters can use for load balancer functionalities  
* Apply the new AKODeploymentConfig:  Label the workload cluster to match the `AKODeploymentConfig.spec.clusterSelector.matchLabels` element in the AKODeploymentConfig file.
  Once the labels are applied on the workload cluster, Tanzu Kubernetes Grid management cluster will deploy AKO pod on the target workload cluster which has the configuration defined in the new AKODeploymentConfig.

The format of the AKODeploymentConfig yaml file is as follows.

```yaml
apiVersion: networking.tkg.tanzu.vmware.com/v1alpha1
kind: AKODeploymentConfig
metadata:
  generation: 2
  name: <Unique name of AKODeploymentConfig>
spec:
  adminCredentialRef:
    name: avi-controller-credentials
    namespace: tkg-system-networking
  certificateAuthorityRef:
    name: avi-controller-ca
    namespace: tkg-system-networking
  cloudName: <Name of the Cloud in NSX ALB>
  clusterSelector:
    matchLabels:
      <key>: <value>
  controlPlaneNetwork:
    cidr: <vip network cidr>
    name: <vip network name>
  controller: <nsx alb ip/fqdn>
  dataNetwork:
    cidr: <vip network cidr>
    name: <vip network name>
  extraConfigs:
    cniPlugin: antrea
    disableStaticRouteSync: true
    l4Config:
      autoFQDN: disabled
    layer7Only: false
    networksConfig:
      enableRHI: false
      nsxtT1LR: <tier-1 gateway where vip network is connected>
    ingress:
      defaultIngressController: true
      disableIngressClass: false
      nodeNetworkList:
      - networkName: <tkg workload network>
  serviceEngineGroup: <SERVICE ENGINE Group NAME>
```

The sample AKODeploymentConfig with sample values in place is as follows. As per the following configuration, Tanzu Kubernetes Grid management cluster will deploy AKO pod on any workload cluster that matches the label `type=workload` and the AKO configuration will be as follows:

```yaml
apiVersion: networking.tkg.tanzu.vmware.com/v1alpha1
kind: AKODeploymentConfig
metadata:
  generation: 2
  name: adc-workload
spec:
  adminCredentialRef:
    name: avi-controller-credentials
    namespace: tkg-system-networking
  certificateAuthorityRef:
    name: avi-controller-ca
    namespace: tkg-system-networking
  cloudName: tanzu-nsx
  clusterSelector:
    matchLabels:
      type: workload
  controlPlaneNetwork:
    cidr: 172.19.75.0/26
    name: tkg-cluster-vip
  controller: alb.tanzu.lab
  dataNetwork:
    cidr: 172.19.75.0/26
    name: tkg-cluster-vip
  extraConfigs:
    cniPlugin: antrea
    disableStaticRouteSync: true
    l4Config:
      autoFQDN: disabled
    layer7Only: false
    networksConfig:
      enableRHI: false
      nsxtT1LR: /infra/tier-1s/tanzu-t1-gw
    ingress:
      defaultIngressController: true
      disableIngressClass: false
      nodeNetworkList:
      - networkName: tkg-workload-ls
  serviceEngineGroup: tkg-wld-seg
```
Once you have the AKO configuration file ready, use the `kubectl` command to set the context to Tanzu Kubernetes Grid management cluster and use the following command to list the available AKODeploymentConfig:

<!-- /* cSpell:disable */ -->
```
kubectl apply -f <path_to_akodeploymentconfig.yaml>
```
<!-- /* cSpell:enable */ -->

Use the following command to list all AKODeploymentConfig created under the management cluster:

<!-- /* cSpell:disable */ -->
```
kubectl get adc  or

kubectl get akodeploymentconfig
```
<!-- /* cSpell:enable */ -->

![List of all AKODeploymentConfig created under management cluster](img/tko-on-vsphere-nsxt/default-adc.png)

Now that you have successfully created the AKO deployment config, you need to apply the cluster labels defined in the AKODeploymentConfig to any of the Tanzu Kubernetes Grid workload clusters. Once the labels are applied, Tanzu Kubernetes Grid management cluster will deploy AKO pod on the target workload cluster.

<!-- /* cSpell:disable */ -->
```bash
kubectl label cluster <Cluster_Name> <label>

Example: kubectl label cluster tkg160-wld01-nsx type=workload
```
<!-- /* cSpell:enable */ -->

#### Connect to Tanzu Kubernetes Grid Workload Cluster and Validate the Deployment

1. Now that the Tanzu Kubernetes Grid workload cluster is created and required AKO configurations are applied, use the following command to get the admin context of the Tanzu Kubernetes Grid workload cluster.

    ```bash
    tanzu cluster kubeconfig get <cluster-name> --admin
    ```
2. Connect to the Tanzu Kubernetes Grid workload cluster using the `kubectl` command and run the following commands to check the status of AKO and other components.

   - Switch context to the workload cluster: `kubectl config use-context tkg160-wld01-nsx-admin@tkg160-wld01-nsx`

   - List all nodes with status: `kubectl get nodes`

   - Check the status of AKO pod: `kubectl get pods -n avi-system`

   - Lists all pods and its status: `kubectl get pods -A`  

    ![Status of AKO and other components](img/tko-on-vsphere-nsxt/wld-cluster-nodes-pods.png)

You can see that the workload cluster is successfully deployed and AKO pod is deployed on the cluster. You can now configure SaaS services for the cluster and deploy user managed packages on this cluster.

## <a id="integrate-to"> </a> Integrate Tanzu Kubernetes clusters with Tanzu Observability

For instructions on enabling Tanzu Observability on your workload cluster, please see [Set up Tanzu Observability to Monitor a Tanzu Kubernetes Clusters](./tko-saas-services.md#set-up-tanzu-observability-to-monitor-a-tanzu-kubernetes-clusters)

## <a id="integrate-tsm"> </a> Integrate Tanzu Kubernetes clusters with Tanzu Service Mesh

For instructions on installing Tanzu Service Mesh on your workload cluster, please see [Onboard a Tanzu Kubernetes Cluster to Tanzu Service Mesh](./tko-saas-services.md#onboard-a-tanzu-kubernetes-cluster-to-tanzu-service-mesh)

## <a id="deploy-user-managed-packages"> </a> Deploy User-Managed Packages on Tanzu Kubernetes clusters

For instructions on installing user-Managed packages on the Tanzu Kubernetes clusters, see [Deploy User-Managed Packages in Workload Clusters](tkg-package-install.md).
