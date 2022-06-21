# Deploy VMware Tanzu for Kubernetes Operations on VMware vSphere with VMware NSX-T

VMware Tanzu simplifies operation of Kubernetes for multi-cloud deployment by centralizing management and governance for clusters and teams across on-premises, public clouds and edge.

It delivers an open source aligned Kubernetes distribution with consistent operations and management to support infrastructure and app modernization.

The scope of the document is limited to providing deployment steps based on the reference design in [VMware Tanzu for Kubernetes Operations on vSphere with NSX-T](https://docs.vmware.com/en/VMware-Tanzu/services/tanzu-reference-architecture/GUID-reference-designs-tko-on-vsphere-nsx.html) and does not cover any deployment procedures for the underlying SDDC components.

# **Tanzu Kubernetes Grid Bill Of Materials**

Below is the validated Bill of Materials that can be used to install TKG on your vSphere environment today:

|**Software Components**|**Version**|
| :- | :- |
|Tanzu Kubernetes Grid|1.5.1|
|VMware vSphere ESXi|7.0 U2 and later|
|VMware vCenter (VCSA)|7.0 U2 and later|
|VMware vSAN|7.0 U2 and later|
|VMware NSX-T Datacenter|3.2.0.1 |
|NSX Advanced LB|20.1.7|

The Interoperability Matrix can be verified at all times [here](https://interopmatrix.vmware.com/#/Interoperability?isHideGenSupported=true&isHideTechSupported=true&isHideCompatible=false&isHideIncompatible=false&isHideNTCompatible=true&isHideNotSupported=true&isCollection=false&col=551,5305&row=551,5305%262,5088,3457%26789,5823).

# **Prepare the Environment for Deployment of the Tanzu Kubernetes Operations**  

Before deploying Tanzu Kubernetes Operations in vSphere environment, ensure that your environment is set up as described in the following:

- [General Requirements](#genreq)
- [Network Requirements](#netreq)
- [Firewall Requirements](#fwreq)

## <a id="genreq"> </a> **General Requirements**

- A vCenter with NSX-T backed environment. 
- Ensure below NSX-T configurations are in place
  **Note:** Below steps provides only high level overview of the required NSX-T configuration to be in place, for more details refer [NSX-T Datacenter Installation Guide](https://docs.vmware.com/en/VMware-NSX-T-Data-Center/3.1/installation/GUID-3E0C4CEC-D593-4395-84C4-150CD6285963.html) and [NSX-T Datacenter Product Documentation](https://docs.vmware.com/en/VMware-NSX-T-Data-Center/index.html) 
  - NSX-T manager instance is deployed and configured with Advanced or higher license
  - vCenter Server that is associated with the NSX-T Data Center is configured as Compute Manager 
  - Required overlay and vLAN Transport Zones are created
  - IP pools for Host and Edge tunnel endpoints(TEP) are created
  - Host and Edge uplink profiles are in place
  - Transport Node profiles are created. This step is not required if configuring NSX-T datacenter on each hosts instead of cluster
  - NSX-T datacenter configured on all hosts part of the vSphere cluster or clusters. 
  - Edge transport nodes and at least one Edge cluster is created
  - Tier-0 uplink segments and Tier-0 Gateway is created
  - Tier-0 router is peered with uplink L3 switch
- SDDC environment has the following objects in place: 
  - A vSphere cluster with at least three hosts, on which vSphere DRS is enabled and NSX-T is successfully configured 
  - Dedicated resource pool in which to deploy the following Tanzu Kubernetes Grid Instance 
    - TKGm Management Cluster
    - TKGm Shared Service Cluster
    - TKGm Workload Clusters - The number of required resource pools depends on the number of workload clusters to be deployed
  - VM folders in which to collect the Tanzu Kubernetes Grid VMs 
  - A datastore with sufficient capacity for the control plane and worker node VM files 
  - Network Time Protocol (NTP) service is running on all hosts and vCenter
  - A host/server/VM based on Linux/MAC/Windows which acts as your bootstrap machine which has docker installed. For the purpose of this document, we will be making use of a virtual machine based on Photon OS.
  - Depending on the OS flavor of the bootstrap VM, [download](https://customerconnect.vmware.com/en/downloads/details?downloadGroup=TKG-151&productId=988&rPId=49705) and configure the below packages. As part of this documentation, refer to the section “[Deploy and Configure bootstrap machine](#_o613gidjwbxt)” to configure required packages on Photon Machine
    - Tanzu CLI 1.5.1
    - kubectl cluster CLI 1.22.5
  - A vSphere account with permissions at least described in [Required Permissions for the vSphere Account](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.5/vmware-tanzu-kubernetes-grid-15/GUID-mgmt-clusters-vsphere.html#vsphere-permissions).
  - If working in an Internet-Restricted environment with a centralized image repository is required, see [prepare an Internet-Restricted Environment](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.5/vmware-tanzu-kubernetes-grid-15/GUID-mgmt-clusters-airgapped-environments.html) for more information on setting up a centralized image repository
  - Download and import NSX ALB 20.1.7 OVA to Content Library
  - [Download](https://customerconnect.vmware.com/en/downloads/details?downloadGroup=TKG-151&productId=988&rPId=49705) below OVA and import it to vCenter, once imported convert these VM as templates. 
    - Photon v3 Kubernetes v1.22.5 OVA and/or
    - Ubuntu 2004 Kubernetes v1.22.5 OVA  

**Note**: You can also [download](https://customerconnect.vmware.com/en/downloads/details?downloadGroup=TKG-151&productId=988&rPId=49705) and import supported older versions of Kubernetes in order to deploy workload clusters on the intended Kubernetes versions.

**Resource Pools and VM Folders:**

Below are the sample entries of the resource pools and folders that need to be created.

|**Resource Type**|**Sample Resource Pool Name**|**Sample Folder Name**|
| :-: | :-: | :-: |
|NSX ALB Components|`nsx-alb-components`|`nsx-alb-components`|
|TKG Management components|`tkg-management-components`|`tkg-management-components`|
|TKG Shared Service Components|`tkg-sharedsvc-components`|`tkg-sharedsvc-components`|
|TKG Workload components|`tkg-workload01-components`|`tkg-workload01-components`|

## <a id="netreq"> </a> **Network Requirements**

Create separate logical segments in NSX-T for deploying TKO components as per [Network Requirements](https://docs.vmware.com/en/VMware-Tanzu/services/tanzu-reference-architecture/GUID-reference-designs-tko-on-vsphere-nsx.html#network-recommendations-9) defined in the reference architecture. 

## <a id="fwreq"> </a>  **Firewall Requirements**

Ensure that the firewall is set up as described in [Firewall Requirements](https://docs.vmware.com/en/VMware-Tanzu/services/tanzu-reference-architecture/GUID-reference-designs-tko-on-vsphere-nsx.html#firewall-recommendations-10). 

## <a id="cidrex"> </a>  **Subnet and CIDR Example**

For the purpose of demonstration, this document makes use of the following Subnet CIDR for TKO deployment.

|**Network Type**|**Segment Name**|**Gateway CIDR**|**DHCP Pool in NSXT**|**NSX ALB IP Pool**|
| :- | :- | :- | :- | :- |
|NSX ALB Mgmt Network|alb-management-segment|172.19.10.1/24|N/A|172.19.10.100- 172.19.10.200|
|TKG Management Network|tkg-mgmt-segment|172.19.40.1/24|172.19.40.100- 172.19.40.200|N/A|
|TKG Shared Service Network|tkg-ss-segment|172.19.41.1/24|172.19.41.100 - 172.19.41.200|N/A|
|TKG Mgmt VIP Network|tkg-mgmt-vip-segment|172.19.50.1/24|N/A|172.19.50.100- 172.19.50.200|
|TKG Cluster VIP Network|tkg-cluster-vip-segment|172.19.80.1/24|N/A|172.19.80.100- 172.19.80.200|
|TKG Workload VIP Network|tkg-workload-vip-segment|172.19.70.1/24|N/A|172.19.70.100- 172.19.70.200|
|TKG Workload Network|tkg-workload-segment|172.19.60.1/24|172.19.60.100- 172.19.60.200|N/A|


# **Tanzu Kubernetes Operations: Deployment Procedure**

At this stage, it’s assumed that you have met all the required prerequisites.
The steps for deploying Tanzu Kubernetes Operations on vSphere backed by NSX-T is as follows:

1. [Configure T1 Gateway and Logical Segments in NSX-T Data Center](#configurensxt)
2. [Deploy and Configure NSX Advanced Load Balancer](#deploynsxalb)
3. [Configure Bootstrap Virtual machine](#configurebootstrap)
4. [Deploy TKGm Management Cluster](#createmgmt)
5. [Register TKGm Management Cluster with Tanzu Mission Control](#regtmc)
6. [Deploy TKGm Shared Service Cluster](#createsharedsvc)
7. [Deploy TKGm Workload Cluster](#createworkload)
8. [Deploy User-Managed packages on TKG clusters](#packages)

## <a id="configurensxt"> </a> **Configure T1 Gateway and Logical Segments in NSX-T Data Center**

As part of the pre-requisite, an NSX-T backed vSphere environment must be configured with at least one tier-0 Gateway. 
A tier-0 gateway performs the functions of a tier-0 logical router. It processes traffic between the logical and physical networks. For more information on creating and configuring Tier-0 gateway refer [NSX-T documentation](https://docs.vmware.com/en/VMware-NSX-T-Data-Center/3.2/administration/GUID-E9E62E02-C226-457D-B3A6-FE71E45628F7.html)

This sections provides details on: 

1) Add a Tier-1 Gateway 
1) Create Overlay backed Segments

### **Add a Tier-1 Gateway** 
The tier-1 logical router must be connected to the tier-0 logical router to get the northbound physical router access. Below procedure provides minimum required configuration to create a Tier-1 Gateway which is good enough to successfully deploy TKO stack, for more advanced configuration refer [NSX-T documentation](https://docs.vmware.com/en/VMware-NSX-T-Data-Center/index.html).

1) With admin privileges, log in to NSX Manager
1) Select **Networking** -> **Tier-1 Gateways**
1) Click Add Tier-1 Gateway.
1) Enter a name for the gateway.
1) Select a tier-0 gateway to connect to this tier-1 gateway to create a multi-tier topology.
1) Select an NSX Edge cluster, this is required for this tier-1 gateway to host stateful services such as NAT, load balancer, or firewall.
1) (Optional) In the Edges field, you can leave the Auto allocated option or manually set the Edge nodes.
1) Select a failover mode or accept the default, the default option is “Non-preemptive”
1) **Enable** **Standby Relocation**
1) Click **Route Advertisement** and ensure below routes are enabled:
   1. **All DNS Forwarder Routes** 
   1. **All Connected Segments and Service Ports** 
   1. **All IPSec Local Endpoints**
   1. **All LB VIP Routes**
   1. **All LB SNAT IP Routes**
1) Click **Save**

    ![](img/tko-on-vsphere-nsxt/1-T1-gateway-1.png)

### **Create Overlay-backed Segments**

NSX-T datacenter provides the option to add two kinds of segments: overlay-backed segments and VLAN-backed segments.
Segments are created as part of a transport zone. There are two types of transport zones: VLAN transport zones and overlay transport zones. A segment created in a VLAN transport zone is a VLAN-backed segment, and a segment created in an overlay transport zone is an overlay-backed segment. 

As shown in the [Subnet and CIDR example](#cidrex), a couple of networks require DHCP service, you can make use of NSX-T to provide DHCP services for these networks.
NSX-T Data Center supports three types of DHCP on a segment: DHCP local server, Gateway DHCP, and DHCP relay. For the purpose of this document we will be making use of type “Gateway DHCP”

Before creating Overlay-backed segments, you must set DHCP configuration on the Tier-1 Gateway.

**DHCP configuration on Tier-1 gateway** 

Follow below procedure to set the DHCP configuration on Tier-1 gateway

1) With admin privileges, log in to NSX Manager
1) Select **Networking** > **Tier-1 Gateways**
1) On the Tier-1 gateway created earlier, Click the **menu** icon (3 dots) and select **Edit** and** Click on **Set DHCP Configuration

   ![](img/tko-on-vsphere-nsxt/2-T1-gateway-2.png)

1) In the “Set DHCP Configuration” pop-up window, set the “Type” to “DHCP Server” 

   ![](img/tko-on-vsphere-nsxt/3-T1-gateway-dhcp-3.png)

1) If you have no DHCP profile created, click on the **menu** icon (3 dots) and select **Create New**

   ![](img/tko-on-vsphere-nsxt/4-T1-gateway-dhcp-4.png)

1) In the “Create DHCP Profile” page, provide a **name** for DHCP profile, **select** the **edge cluster** and click on **Save**

   ![](img/tko-on-vsphere-nsxt/5-T1-gateway-dhcp-5.png)

1) Click Save again in “”Set DHCP Configuration” window

   ![](img/tko-on-vsphere-nsxt/6-T1-gateway-dhcp-6.png)

1) Now you would see that the DHCP configuration in the Tier-1 is set to Local, click on save and close editing

   ![](img/tko-on-vsphere-nsxt/7-T1-gateway-dhcp-7.png)

**Create Overlay-Backed Segments**

Now you need to create the overlay backed logical segments as shown in the [Overlay backed segments CIDR example](#cidrex). All these segments will be part of the same overlay transport zone and must be connected to Tier-1 gateway. 
Below procedure provides required details to create one such network which is required for TKO deployment:

1) With admin privileges, log in to NSX Manager 

1) Select **Networking** > **Segments** 

1) Click **Add Segment**, enter a name for the segment, for example: “tkg-mgmt-segment” 

1) Under “**Connected Gateway**”, select the Tier-1 Gateway created earlier 

1) Select a transport zone, which will be an **overlay Transport Zone** 

1) Enter the **Gateway IP address** of the subnet in a CIDR format, for example “172.16.40.1/24”

   ![](img/tko-on-vsphere-nsxt/8-segments-1.png)

1) Click on “**SET DHCP CONFIG**”

   **Note:** This is required only for “TKG Management Network”, “TKG Shared  Network” and “TKG Workload Network”

   1. You may note that the “DHCP type” is set to “Gateway DHCP Server” and DHCP Profile is set to the profile created while creating Tier-1 gateway

   1. Under **Settings**, **Enable DHCP Config** and provide the **DHCP range** and **DNS server** info

      ![](img/tko-on-vsphere-nsxt/9-segments-2.png)

   1. Click on **Options**

   1. Under “**Select DHCP Option**n” choose “**GENERIC OPTIONS**”

   1. Click on “**ADD GENERIC OPTION**” and choose “**NTP servers (42)**”, provide the details of NTP server and click on **ADD**

   1. Review the details, and click **Apply** to close the “Set DHCP Config” page 

      ![](img/tko-on-vsphere-nsxt/10-segments-3.png)

   1. Click on **Save** to create the logical segment

Repeat the steps from 1-7 to create all other required overlay-backed segments, once complete you should see something like below:** 

![](img/tko-on-vsphere-nsxt/11-segments-4.png)

Additionally, you can create required Inventory groups and Firewall rules for more details, refer [NSX-T Datacenter Product Documentation](https://docs.vmware.com/en/VMware-NSX-T-Data-Center/index.html)

## <a id="deploynsxalb"> </a>   **Deploy and Configure NSX Advanced Load Balancer**
NSX ALB is an Enterprise-grade integrated Load balancer, provides L4- L7 Load Balancer support, recommended for vSphere deployments without NSX-T, or when there are unique scaling requirements.

NSX ALB is deployed in Write Access Mode mode in the vSphere Environment. This mode grants NSX ALB Controllers full write access to the vCenter which helps in automatically creating, modifying, and removing SEs and other resources as needed to adapt to changing traffic needs.

For a production-grade deployment, it is recommended to deploy 3 instances of the NSX ALB Controller for high availability and resiliency.** 

Below is the sample IP and FQDN set for the NSX ALB controllers:

|**Controller Node**|**IP Address**|**FQDN**|
| :- | :- | :- |
|Node 1 Primary|172.19.10.11|`alb-ctlr01.lab.vmw`|
|Node 2 Secondary|172.19.10.12|`alb-ctlr02.lab.vmw`|
|Node 3 Secondary |172.19.10.13|`alb-ctlr03.lab.vmw`|
|HA Address|172.19.10.10|`alb-ha.lab.vmw`|

### <a id="deploynsxalb"> </a> **Deploy NSX Advanced Load Balancer**

As part of the pre-requisites, you must have the NSX ALB 20.1.7 OVA downloaded and imported to the content library. Deploy the NSX ALB under the **resource pool “nsx-alb-components”**  and place it under the **folder** **“nsx-alb-components”** .
To deploy NSX ALB, 

- Login to **vCenter** > **Home** > **Content** **Libraries** 
- **Select the Content Library** under which the NSX-ALB OVA is placed
- Click on **OVA & OVF Templates** 
- Right-click on **NSX ALB Image** and select **New VM from this Template**
- On the Select name and Folder page, enter a **name** and select a **Folder** for the NSX ALB VM as “**nsx-alb-components”**
- On the Select a Compute resource page, select the **resource** **pool** “**nsx-alb-components**”
- On the Review details page, verify the template details and click **Next**.
- On the **Select** **storage** page, select a storage policy from the VM Storage Policy drop-down menu and choose the  datastore location where you want to store the virtual machine files
- On the Select **networks** page, select the network “**alb-management-segment**” and click **Next**
- On the Customize Template page, provide the NSX ALB Management **network** **details**, such as IP Address, Subnet Mask, and Gateway, and click on **Next**
- On the Ready to complete page, review the page and click Finish

![](img/tko-on-vsphere-nsxt/12-ALB-1.png)

A new task for creating the virtual machine appears in the Recent Tasks pane. After the task is complete, the NSX ALB virtual machine is created on the selected resource. Power on the Virtual Machine and give it few minutes for the system to boot, upon successful boot up navigate to NSX ALB on your browser.
**Note:** While the system is booting up, a blank web page or a 503 status code may appear.

### **NSX Advanced Load Balancer: Initial setup** 
Once the NSX ALB is successfully deployed and boots up, navigate to NSX ALB on your browser using the URL “https://<AVI\_IP/FQDN>” and configure the basic system settings:

- Administrator account setup. 
  Set admin password and click on **Create Account**

  ![](img/tko-on-vsphere-nsxt/13-ALB-2.png)

- Under System Settings: Set backup **Passphrase** and provide **DNS** information and click **Next**

  ![](img/tko-on-vsphere-nsxt/14-ALB-3.png)

  - Under Email/SMTP: Provide **Email** or **SMTP** information

  ![](img/tko-on-vsphere-nsxt/15-ALB-4.png)

  - Under Multi-Tenant: Configure settings as shown below and click on Save

    - **IP Route Domain**: Share IP route domain across tenants.

    - **Service Engines are managed within the**: Provider (Shared across tenants)

    - **Tenant Access to Service Engine**: Read

    ![](img/tko-on-vsphere-nsxt/16-ALB-5.png)

If you did not select the Setup Cloud After option before saving, the initial configuration wizard exits. The Cloud configuration window does not automatically launch and you are directed to a Dashboard view on the controller.

### **NSX Advanced Load Balancer: NTP Configuration**

To Configure NTP, navigate to **Administration** > **Settings** > **DNS/NTP > Edit** and add your NTP server details and **Save**

**Note:** You may also delete the default NTP servers 

![](img/tko-on-vsphere-nsxt/17-ALB-6.png)

### **NSX Advanced Load Balancer: Licensing**

This document focuses on enabling NSX ALB using the **license model: Enterprise License**

To configure licensing, navigate to the **Administration** > **Settings** > **Licensing** and apply the license key. If you have a license file instead of a license key, apply the license by clicking on the Upload from computer option.

![](img/tko-on-vsphere-nsxt/18-ALB-7.png)

### **NSX Advanced Load Balancer: Controller High Availability**

In a production environment, it is recommended to deploy additional controller nodes and configure the controller cluster for high availability and disaster recovery. Adding 2 additional nodes to create a 3-node cluster provides node-level redundancy for the controller and also maximizes performance for CPU-intensive analytics functions. 

To run a 3 node controller cluster, you deploy the first node and perform the initial configuration, and set the Cluster IP. After that, you deploy and power on two more Controller VMs, but you must not run the initial configuration wizard or change the admin password for these controllers VMs. The configuration of the first controller VM is assigned to the two new Controller VMs.

The first controller of the cluster receives the "Leader" role. The second and third controllers will work as "Follower".

Perform the below steps to configure NSX ALB cluster:

- Log in to the primary NSX ALB controller > Navigate to **Administrator** > **Controller** > **Nodes,** and click **Edit**

  ![](img/tko-on-vsphere-nsxt/19-ALB-8.png)

- Specify the **Name** and set the **Controller Cluster IP** and click on **Save**. This IP address should be from the NSX ALB management network. 

  ![](img/tko-on-vsphere-nsxt/20-ALB-9.png)

- Now deploy 2nd and 3rd NSX ALB Node, using steps provided [Deploy and configure NSX ALB](#deloynsxalb)

- Log into the Primary NSX ALB controller using the Controller Cluster IP/FQDN, navigate to **Administrator** > **Controller** >  **Nodes,** and click **Edit**. The Edit Controller Configuration popup appears.

- In the Cluster Nodes field, enter the IP address for the 2nd and 3rd controller and click on **Save**

  ![](img/tko-on-vsphere-nsxt/21-ALB-10.png)

After these steps, the primary NSX ALB Controller becomes the leader for the cluster and invites the other controllers to the cluster as members. 

NSX ALB then performs a warm reboot of the cluster. This process can take approximately 10-15 minutes. You will be automatically logged out of the controller node where you are currently logged in. On entering the cluster IP in the browser, you can see details about the cluster formation task.

![](img/tko-on-vsphere-nsxt/22-ALB-initialization.png)

The configuration of the primary (leader) Controller is synchronized to the new member nodes when the cluster comes online following the reboot. Once the cluster is successfully formed we should see the below status:

![](img/tko-on-vsphere-nsxt/22-ALB-11.png)

**Note:** Going forward all NSX ALB configurations will be configured by connecting to the NSX ALB Controller Cluster IP/FQDN

### **NSX Advanced Load Balancer: Certificate Management**

The default system-generated controller certificate generated for SSL/TSL connections will not have required SAN entries. Follow the below steps to create a Controller certificate

- Login to NSX ALB Controller > **Templates** > **Security** > **SSL/TLS Certificates**

- Click on **Create** and Select **Controller Certificate**

- You can either generate a Self-Signed certificate, generate CSR or import a certificate.For the purpose of this document, a self-signed certificate will be generated. 

- Provide all required details as per your infrastructure requirements, and under the Subject Alternate Name (SAN) section, provide IP and FQDN of all NSX ALB controllers including NSX ALB cluster IP and FQDN, and click on Save

  ![](img/tko-on-vsphere-nsxt/23-ALB-12.png)

- Once the certificate is created, capture the certificate contents as this is required while deploying the TKG management cluster. To capture the certificate content, click on the “Download” icon next to the certificate, and then click on “Copy to clipboard” under the certificate section

  ![](img/tko-on-vsphere-nsxt/24-ALB-13.png)

- To replace the certificate navigate to **Administration** > **Settings** > **Access** **Settings**, and click the pencil icon at the top right to **edit** the System Access Settings, replace the SSL/TSL certificate and click on **Save**

  ![](img/tko-on-vsphere-nsxt/25-ALB-14.png)

  Now, logout and login back to the NSX ALB

### NSX Advanced Load Balancer: Create vCenter Cloud and SE Groups

NSX ALB may be deployed in multiple environments for the same system. Each environment is called a “cloud”. Below procedure provides steps on how to create a VMware vCenter cloud, and as shown in the architecture two Service Engine Groups will be created

**Service Engine Group 1**: Service engines part of this Service Engine group hosts:

- Virtual services for all load balancer functionalities requested by TKG Management Cluster and Shared services cluster.
- Virtual services that load balances control plane nodes of all TKG Kubernetes clusters

**Service Engine Group 2**: Service engines part of this Service Engine group, hosts virtual services for all load balancer functionalities requested by TKG Workload clusters mapped to this SE group.

**Note:** 

- Based on your requirements, you can create additional Service Engine groups for the workload clusters. 
- Multiple Workload clusters can be mapped to a single SE group
- A TKG cluster can be mapped to only one SE group for Application load balancer services  
  Refer [Configure NSX Advanced Load Balancer in TKG Workload Cluster](#workloadalb) for more details on mapping a specific Service engine group to TKG workload cluster 

Below are the components that will be created in NSX ALB

|Object|Sample Name|
| :- | :- |
|vCenter Cloud|`tanzu-vcenter01`|
|Service Engine Group 1|`tanzu-mgmt-segroup-01`|
|Service Engine Group 2|`tanzu-wkld-segroup-01`|

1. Login to NSX ALB > Infrastructure > Clouds > Create > VMware vCenter/vSphere ESX 
   ![](img/tko-on-vsphere-nsxt/26-ALB-15.png)

1. Provide Cloud Name and click on Next
   ![](img/tko-on-vsphere-nsxt/27-ALB-16.png)

1. Under the **Infrastructure** pane, provide **vCenter Address**, **username**, and **password** and set **Access** **Permission** to "**Write**" and click on Next

   ![](img/tko-on-vsphere-nsxt/28-ALB-17.png)

1. Under the **Datacenter** pane, Choose the Datacenter for NSX ALB to discover Infrastructure resources

   ![](img/tko-on-vsphere-nsxt/29-ALB-18.png)

1. Under the **Network** pane, choose the NSX ALB **Management** **Network** : “**alb-management-segment**” for Service Engines and provide a **Static** **IP** **pool** for SEs and VIP and click on Save

   ![](img/tko-on-vsphere-nsxt/30-ALB-19.png)

1. Wait for the status of the Cloud to configure and status to turn Green 

   ![](img/tko-on-vsphere-nsxt/31-ALB-20.png)

1. To create a Service Engine group for TKG management clusters, click on the **Service Engine Group** tab, under Select Cloud, choose the Cloud created in the previous step, and click Create. Provide a name for the TKG management Service Engine group and set below parameters

    |**Parameter**|**Value**|
    | :- | :- |
    |High availability mode|N+M|
    |Memory per Service Engine|4|
    |vCPU per Service Engine|2|

    The rest of the parameters can be left as default

    ![](img/tko-on-vsphere-nsxt/32-ALB-21.png)

    For advanced configuration click on the Advanced tab, to specify a specific cluster for service engine placement, to change the AVI SE folder name and Service engine name prefix and, click on **Save**

    ![](img/tko-on-vsphere-nsxt/33-ALB-22.png)

8. Follow steps 7 and 8 to create another Service Engine group for TKG workload clusters. Once complete, there must be two service engine groups created.

    ![](img/tko-on-vsphere-nsxt/34-ALB-23.png)

### **NSX Advanced Load Balancer: Configure Network and IPAM Profile**

#### **Configure TKG Networks in NSX ALB** 

As part of the Cloud creation, only ALB management Network has been configured in NSX ALB, follow the below procedure to configure the following networks:

- TKG Management Network 
- TKG Shared Services Network
- TKG Workload Network 
- TKG Cluster VIP/Data Network 
- TKG Management VIP/Data Network 
- TKG Workload VIP/Data Network 

Login to NSX ALB > **Infrastructure** > **Networks** and Select the appropriate Cloud.

- All the networks available in vCenter will be listed

- Click on the edit icon next for the network and configure as below. Change the details provided below as per your SDDC configuration 
  
**Note:** Not all networks will be auto-discovered and for those networks, manually add the subnet.

|**Network Name**|**DHCP** |**Subnet**|**Static IP Pool**|
| :- | :- | :- | :- |
|tkg-mgmt-segment|Yes|172.19.40.0/24|NA|
|tkg-ss-segment|Yes|172.19.41.0/24|NA|
|tkg-workload-segment|Yes|172.19.60.0/24|NA|
|tkg-cluster-vip-segment|No|172.19.80.0/24|172.19.80.100 - 172.19.80.200|
|tkg-mgmt-vip-segment|No|172.19.50.0/24|172.19.50.100 - 172.19.50.200|
|tkg-workload-vip-segment|No|172.19.70.0/24|172.19.70.100 - 172.19.70.200|

Below is the snippet of configuring one of the networks, for example: “tkg-workload-vip-segment”

![](img/tko-on-vsphere-nsxt/35-ALB-24.png)

Once the networks configured, the configuration must look like below

![](img/tko-on-vsphere-nsxt/36-ALB-25.png)

Once the networks are configured, set the default routes for all VIP/Data networks, click on **Routing** > Create and add default routes for below networks and Change the gateway for VIP networks as per your network configurations

|**Network Name**|**Gateway Subnet**|**Next Hop**|
| :- | :- | :- |
|tkg\_cluster\_vip\_pg|0.0.0.0/0|172.19.80.1|
|tkg\_mgmt\_vip\_pg|0.0.0.0/0|172.19.50.1|
|tkg\_workload\_vip\_pg|0.0.0.0/0|172.19.70.1|

![](img/tko-on-vsphere-nsxt/37-ALB-26.png)

#### **Create IPAM Profile in NSX ALB and attach it to Cloud** 

At this point all the required networks related to Tanzu functionality are configured in NSX ALB, expect for TKG Management and Workload Network which uses DHCP, NSX ALB provides IPAM service for TKG Cluster VIP Network, TKG Mgmt VIP Network and TKG Workload VIP Network.

Follow below procedure to create IPAM & DNS profiles and attach them to the vCenter cloud created earlier

Login to NSX ALB > **Infrastructure** > **Templates** > **IPAM/DNS Profiles** > **Create** > **IPAM Profile** and provide below details and click on **Save**

|**Parameter**|**Value**|
| :- | :- |
|Name|tanzu-vcenter-ipam-01|
|Type|AVI Vintage IPAM|
|Cloud for Usable Networks|Tanzu-vcenter-01|
|Usable Networks|tkg-cluster-vip-segment<br>tkg-mgmt-vip-segment<br>tkg-workload-vip-segment|

![](img/tko-on-vsphere-nsxt/38-ALB-27.png)

Login to NSX ALB >  **Templates** > **Profiles** >  **IPAM/DNS Profiles** > **Create** > **DNS Profile** and provide the **Domain Name** and click on Save

![](img/tko-on-vsphere-nsxt/39-ALB-28.png)

Attach the IPAM & DNS profiles to the “tanzu-vcenter-01” cloud. Navigate to **Infrastructure** > **Clouds** > Edit the **tanzu-vcenter-01** cloud > Under **IPAM/DNS section**  choose the IPAM and DNS profiles that we created above and **Save** the configuration.

![](img/tko-on-vsphere-nsxt/40-ALB-29.png)

This completes NSX ALB configuration. Next is to deploy and configured Bootstrap Machine which will be used to deploy and management Tanzu Kubernetes clusters


## <a id="configurebootstrap"> </a> Deploy and Configure Bootstrap Machine

The bootstrap machine can be a laptop, host, or server (running on Linux/MAC/Windows platform) that you deploy management and workload clusters from, and that keeps the Tanzu and Kubernetes configuration files for your deployments, the bootstrap machine is typically local.

For this deployment, we use a Photon-based virtual machine as the bootstrap machine. For information on how to configure for a Mac or Windows machine, see [Install the Tanzu CLI and Other Tools](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.5/vmware-tanzu-kubernetes-grid-15/GUID-install-cli.html).

1. Ensure that the bootstrap VM is connected to Tanzu Kubernetes Grid Management network `tkg-mgmt-segment`.

1. [Configure NTP](https://kb.vmware.com/s/article/76088) on your bootstrap machine.

1. Download and unpack the following Linux CLI packages from [VMware Tanzu Kubernetes Grid Download Product](https://customerconnect.vmware.com/en/downloads/details?downloadGroup=TKG-151&productid="988&rPId=49705)."

    - VMware Tanzu CLI 1.5.1 for Linux

    - kubectl cluster cli v1.22.5 for Linux

1. Execute the following commands to install Tanzu Kubernetes Grid CLI, Kubectl CLIs, and Carvel tools
    ```bash
    ## Install required packages
    tdnf install tar zip unzip wget -y

    ## Install Tanzu Kubernetes Grid CLI
    tar -xvf tanzu-cli-bundle-linux-amd64.tar.gz
    cd ./cli/
    sudo install core/v0.11.1/tanzu-core-linux_amd64 /usr/local/bin/tanzu 
    chmod +x /usr/local/bin/tanzu

    ## Install Tanzu Kubernetes Grid CLI Plugins
    tanzu plugin sync

    ##verify the plugins are installed

    tanzu plugin list

    ## Install Kubectl CLI
    gunzip kubectl-linux-v1.22.5+vmware.1.gz
    mv kubectl-linux-v1.22.5+vmware.1 /usr/local/bin/kubectl && chmod +x /usr/local/bin/kubectl

    # Instal Carvel tools

    ##Install ytt
    cd ./cli
    gunzip ytt-linux-amd64-v0.35.1+vmware.1.gz
    chmod ugo+x ytt-linux-amd64-v0.35.1+vmware.1 && mv ./ytt-linux-amd64-v0.35.1+vmware.1 /usr/local/bin/ytt

    ##Install kapp

    cd ./cli
    gunzip kapp-linux-amd64-v0.42.0+vmware.1.gz
    chmod ugo+x kapp-linux-amd64-v0.42.0+vmware.1 && mv ./kapp-linux-amd64-v0.42.0+vmware.1 /usr/local/bin/kapp

    ##Install kbld

    cd ./cli
    gunzip kbld-linux-amd64-v0.31.0+vmware.1.gz
    chmod ugo+x kbld-linux-amd64-v0.31.0+vmware.1 && mv ./kbld-linux-amd64-v0.31.0+vmware.1 /usr/local/bin/kbld

    ##Install impkg

    cd ./cli
    gunzip imgpkg-linux-amd64-v0.18.0+vmware.1.gz
    chmod ugo+x imgpkg-linux-amd64-v0.18.0+vmware.1 && mv ./imgpkg-linux-amd64-v0.18.0+vmware.1 /usr/local/bin/imgpkg
    ```

1. Validate Carvel tools installation using the following commands:
    ```bash
    ytt version
    kapp -version
    kbld version
    imgpkg version
    ```
1. Install `yq`. `yq` is a lightweight and portable command-line YAML processor. `yq` uses `jq`-like syntax but works with YAML and JSON files.
    ```bash
    wget https://github.com/mikefarah/yq/releases/download/v4.2.0/yq_linux_amd64.tar.gz

    tar -xvf yq_linux_amd64.tar.gz && mv yq_linux_amd64 /usr/local/bin/yq
    ```
1. Install kind
    ```bash
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.11.1/kind-linux-amd64
    chmod +x ./kind
    mv ./kind /usr/local/bin/kind
    ```
1. Photon OS has Docker installed by default. Execute the following commands to start the service and enable it to start at boot.
    ```bash
    ## Check Docker service status
    systemctl status docker

    ## Start Docker Service
    systemctl start docker

    ## To start Docker Service at boot
    systemctl enable docker
    ```
1. Execute the following commands to ensure that the bootstrap machine uses [cgroup v1](https://man7.org/linux/man-pages/man7/cgroups.7.html).
    ```bash
    docker info | grep -i cgroup

    ## You should see the following
    Cgroup Driver: cgroupfs
    ```
1. Create an SSH key pair.

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
1. If your bootstrap machine runs Linux or Windows Subsystem for Linux, and it has a Linux kernel built after the May 2021 Linux security patch, for example Linux 5.11 and 5.12 with Fedora, run the following command:

    `sudo sysctl net/netfilter/nf_conntrack_max=131072`

All required packages are now installed and the required configurations are in place in the bootstrap virtual machine. The next step is to deploy the Tanzu Kubernetes Grid management cluster.

## <a id="importbaseimage"> </a> **Import Base Image template for TKG Cluster Deployment:**

Before you proceed with the management cluster creation, ensure that the base image template is imported into vSphere and is available as a template. To import a base image template into vSphere:

- Go to the [Tanzu Kubernetes Grid downloads](https://customerconnect.vmware.com/en/downloads/details?downloadGroup=TKG-151&productid="988&rPId=49705) page, and download a Tanzu Kubernetes Grid OVA for the cluster nodes. "
  - For the **management cluster**, this must be either Photon or Ubuntu based Kubernetes v1.22.5 OVA  
    Note: Custom OVA with a custom Tanzu Kubernetes release (TKr) is also support, as described in [Build Machine Images](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.5/vmware-tanzu-kubernetes-grid-15/GUID-build-images-index.html)
  - For **workload clusters,** OVA can have any supported combination of OS and Kubernetes version, as packaged in a Tanzu Kubernetes release 

  **Note**: Make sure you download the most recent OVA base image templates in the event of security patch releases. You can find updated base image templates that include security patches on the Tanzu Kubernetes Grid product download page. 

- In the vSphere Client, right-click an object in the vCenter Server inventory, select Deploy OVF template. 

- Select Local file, click the button to upload files, and navigate to the downloaded OVA file on your local machine. 

- Follow the installer prompts to deploy a VM from the OVA. 

- Click Finish to deploy the VM. When the OVA deployment finishes, right-click the VM and select **Template** > **Convert to Template**. 

  **NOTE:** Do not power on the VM before you convert it to a template.

- **If using non administrator SSO account**: In the VMs and Templates view, right-click the new template, select **Add Permission**, and assign the **tkg-user** to the template with the **TKG role**

For information about how to create the user and role for Tanzu Kubernetes Grid, see [Required Permissions for the vSphere Account](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.5/vmware-tanzu-kubernetes-grid-15/GUID-mgmt-clusters-vsphere.html#required-permissions-for-the-vsphere-account-5).

## <a id="createmgmt"> </a> Deploy Tanzu Kubernetes Grid (TKG) Management Cluster

The management cluster is a Kubernetes cluster that runs Cluster API operations on a specific cloud provider to create and manage workload clusters on that provider. The management cluster is also where you configure the shared and in-cluster services that the workload clusters use.

You can deploy management clusters in two ways: 

- Run the Tanzu Kubernetes Grid installer, a wizard interface that guides you through the process of deploying a management cluster. This is the recommended method. 
- Create and edit YAML configuration files, and use them to deploy a management cluster with the CLI commands.

Below procedure provides all required steps to deploy TKG management cluster using Installer Interface

1. To launch the UI installer wizard, run the following command on the bootstrapper machine:
    ```bash
    tanzu management-cluster create --ui --bind <bootstrapper-ip>:<port> --browser none

    ## For example

    tanzu management-cluster create --ui --bind 172.19.40.100:8000 --browser none
    ```

2. Access Tanzu UI wizard by opening a browser and entering http://<bootstrapper-ip:port/

    ![](img/tko-on-vsphere-nsxt/41-mgmt-cluster-1.png)

3. Click **Deploy** on the **VMware vSphere** tile

4. On the "**IaaS Provider**" section, enter the IP/FQDN and credentials of the vCenter server where the TKG management cluster will be deployed.

5. Click on connect and accept the vCenter Server SSL thumbprint. Optionally, you can disable the SSL thumbprint verification by selecting the Disable verification option.

    ![](img/tko-on-vsphere-nsxt/42-mgmt-cluster-2.png)

6. You would get the below popup after the vCenter details validation, then select “DEPLOY TKG MANAGEMENT CLUSTER” to proceed further
  would get below popup.

    ![](img/tko-on-vsphere-nsxt/43-mgmt-cluster-3.png)

7. Select the **Datacenter** and provide the **SSH Public Key** generated while configuring the Bootstrap VM.

8. Add your SSH public key. To add your SSH public key, use the **Browse File** option or manually paste the contents of the key into the text box. Click **Next**.

    **Note**: If you have saved the SSH key in the default location, execute the  following command in you bootstrap machine to get the SSH public key
      ` `“**cat /root/.ssh/id\_rsa.pub**”

    ![](img/tko-on-vsphere-nsxt/44-mgmt-cluster-4.png)

9. On the **Management cluster settings** section provide below details, 
      - Based on the environment requirements select appropriate **deployment type** for the TKG Management cluster
        - **Development**: Recommended for Dev or POC environments
        - **Production**: Recommended for Production environments

        Recommended to set the **instance** **type** to **Large** or above.

        For the purpose of this document, we will proceed with deployment type Development and instance type Large

    - **Management Cluster Name**: Name for your management cluster.
    - **Control Plane Endpoint Provider**: Select NSX ALB for the Control Plane HA.
    - **Control Plane Endpoint**: This is an optional field, if left blank NSX ALB will assign an IP from the pool “tkg-cluster-vip-segment” we created earlier. 
      If you need to provide an IP, pick an IP address from “**tkg-cluster-vip-segment**”  static IP pools configured in NSX ALB and ensure that the IP address is unused.
    - **Machine Health Checks**: Enable
    - **Enable Audit Logging**: Enables to audit logging for Kubernetes API server and node VMs, choose as per environmental needs. For more information see [Audit Logging](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.4/vmware-tanzu-kubernetes-grid-14/GUID-troubleshooting-tkg-audit-logging.html)
    - Click **Next**

      ![](img/tko-on-vsphere-nsxt/45-mgmt-cluster-5.png)

10. On the **NSX Advanced Load Balancer** section, provide the following: 
      - **Controller Host**: NSX ALB Controller IP/FQDN (ALB Controller cluster IP/FQDN of the controller cluster is configured) 
      - Controller credentials: **Username** and **Password** of NSX ALB 
      - **Controller certificate**

        Once the above details are provided, click on “**Verify Credentials**” and choose the below parameters

    - **Cloud Name**: Name of the cloud created while configuring NSX ALB “**tanzu-vcenter-01**”
    - **Service Engine Group Name**: Name of the Service Engine Group created for TKG management clusters created while configuring NSX ALB “**`tanzu-mgmt-segroup-01`**”
    - **Workload VIP Network Name**: Select TKG Management VIP/Data Network network “**`tkg-mgmt-vip-segment`**” and select the discovered subnet
    - **Workload VIP network CIDR**:  Select the discovered subnet, in our case “172.19.50.0/24”​
    - **Management VIP network Name**: Select TKG Cluster VIP/Data Network network “**`tkg-cluster-vip-segment`**”
    - **Cluster Labels**: To adhere to the architecture defining a label is **mandatory**. Provide required labels, for example, **type**:**management
      Note:** Based on your requirements you may specify multiple labels** 
    - Click **Next**

      ![](img/tko-on-vsphere-nsxt/46-mgmt-cluster-6.png)

    **Note**: With above configurations, when a TKG clusters (Shared service/workload) are tagged with label **“type=management”**, “**ako**” pod gets deployed on the cluster,** and any applications hosted on the cluster that requires Load Balancing service will be exposed via network “**tkg-mgmt-vip-segment**” and the virtual service will be placed on SE group **`tanzu-mgmt-segroup-01`**

    As per the defined architecture, **Cluster Labels** specified here will be applied **only on shared service cluster.  If no labels are specified in the “Cluster Labels” section, ako pod gets deployed on all the clusters without any labeling requirement and this deviates from the defined architecture

11. On the **Metadata** page, you can specify location and labels and click **Next**, this is **optional**

    ![](img/tko-on-vsphere-nsxt/47-mgmt-cluster-7.png)

12. On the **Resources** section, specify the resources to be consumed by TKG management cluster and click on **Next**

    ![](img/tko-on-vsphere-nsxt/48-mgmt-cluster-8.png)

13. On the Kubernetes Network section, select the **TKG Management Network (“tkg-mgmt-segment”)** where the control plane and worker nodes will be placed during management cluster deployment. Optionally, change the **Pod** and **Service CIDR** if the default provided network is already in use in your environment.

    - If the tanzu environment is placed behind a proxy, enable proxy and provide proxy details
      If using **proxy** details below are the **key points**:
    - If you set http-proxy., you must also set https-proxy and vice-versa
    - For the no-proxy section:
      - For TKG Mgmt and workload clusters, localhost, 127.0.0.1, the values of CLUSTER\_CIDR and SERVICE\_CIDR, .svc, and .svc.cluster.local values are appended along with the user specified values
      - **Note**: If the kubernetes cluster needs to communicate with external services and infrastructure endpoints in your Tanzu Kubernetes Grid environment, ensure that those endpoints are reachable by your proxies or add them to TKG\_NO\_PROXY. Depending on your environment configuration, this may include, but is not limited to,  your OIDC or LDAP server, Harbor, NSX-T, and NSX Advanced Load Balancer, vCenter.
      - For vSphere, you must manually add the CIDR of TKG Management Network and Cluster VIP networks which includes the IP address of your control plane endpoints, to TKG\_NO\_PROXY.

        ![](img/tko-on-vsphere-nsxt/49-mgmt-cluster-9.png)

14. Optionally Specify **Identity Management with OIDC or LDAPS** -  For the purpose of this document, Identity management integration has been **disabled**

    If you would like to enable Identity Management, see **Enable and Configure Identity Management During Management Cluster Deployment** section in Pinniped Deployment Guide

    ![](img/tko-on-vsphere-nsxt/50-mgmt-cluster-10.png)

15. Select the **OS image** that will be used for the management cluster deployment. We have selected the Photon os for this demonstration purpose.
  
    **Note**: This list will appear empty if you don’t have a compatible template present in your environment. Refer steps provided in [Import Base Image template for TKG Cluster deployment](#importbaseimage)

      ![](img/tko-on-vsphere-nsxt/51-mgmt-cluster-11.png)

16. Check the “**Participate in the Customer Experience Improvement Program**”, if you so desire and click **Review Configuration**

17. Review all the configuration, once reviewed, you can either copy the command provided and execute it in CLI or proceed with UI to **Deploy Management Cluster**.
  When the deployment is triggered from the UI, the installer wizard displays the deployment logs on the screen.

    ![](img/tko-on-vsphere-nsxt/52-mgmt-cluster-12.png)

While the cluster is being deployed, you will find that a Virtual service will be created in NSX Advanced Load Balancer and new service engines will be deployed in vCenter by NSX ALB and the service engines will be mapped to the SE Group `tanzu-mgmt-segroup-01`​​

Behind the scenes when TKG management Cluster is being deployed:

- NSX ALB Service engines gets deployed in vCenter and this task is orchestrated by NSX ALB controller.

- Service engine status in NSX ALB: Below snippet shows the service engines status. They are in initializing status for sometime and the changes to Up.

  ![](img/tko-on-vsphere-nsxt/53-mgmt-cluster-13.png)

- Service Engine Group Status in NSX ALB: As per our configuration, we can see that the virtual service required for TKG clusters control plane HA will be hosted on service engine group “**`tkg-mgmt-segroup-01`**”

  ![](img/tko-on-vsphere-nsxt/54-mgmt-cluster-14.png)

- VIrtual Service status in NSX ALB. Currently it shows only 1 control plane IP as the control plane is still being deployed. It will show 3 IPs once other node control plane nodes deployed.

  ![](img/tko-on-vsphere-nsxt/54-mgmt-cluster-13.png)

- Once the TKG management cluster is successfully deployed, you will find this in the Tanzu Bootstrap UI

  ![](img/tko-on-vsphere-nsxt/55-mgmt-cluster-15.png)

- Now you can access the TKG management cluster from the bootstrap machine and perform additional tasks such as verifying the management cluster health and deploy the workload clusters etc.

To get the status of TKG Management cluster execute below command

  ```bash
  tanzu management-cluster get
  ```

![](img/tko-on-vsphere-nsxt/56-mgmt-cluster-16.png)

Retrieve management cluster `kubeconfig` and switch to the cluster context to run kubectl commands.

```bash
# tanzu management-cluster kubeconfig get --admin
```

![](img/tko-on-vsphere-nsxt/57-mgmt-cluster-17.png)


The TKG management cluster is successfully deployed and now you can proceed with registering it with TMC and creating Shared Service and workload clusters.

## What to Do Next

Register your management cluster with Tanzu Mission Control: If you want to register your management cluster with Tanzu Mission Control, see Register Your Management Cluster with Tanzu Mission Control

## <a id="createsharedsvc"> </a> Deploy Tanzu Shared Service Cluster

Each Tanzu Kubernetes Grid instance can have only one shared services cluster. Create a shared services cluster if you intend to deploy Harbor.

Deploying a Shared service cluster and workload cluster is exactly the same, the only difference is, for the shared service cluster you will be adding tanzu-services label to the shared services cluster, as its cluster role. This label identifies the shared services cluster to the management cluster and workload clusters.


Another **major difference** with shared service cluster when compared with Workload clusters is that, Shared service cluster will be applied with the “**Cluster Labels**” which were defined while deploying Management Cluster. This is to enforce only Shared Service Cluster will make use of the **TKG Cluster VIP/Data Network** for application load balancing purposes and the virtual services are deployed on “**Service Engine Group 1**”

After the Management Cluster is registered with Tanzu Mission Control, deployment of the Tanzu Kubernetes clusters can be done in just a few clicks. The procedure for creating Tanzu Kubernetes clusters is shown below.

1. Navigate to the Clusters tab and click on the Create Cluster button.

    Under the create cluster page, select the Management cluster which you registered in the previous step and click on the continue to create cluster button.

    ![](img/tko-on-vsphere-nsxt/63-ss-1.png)

2. Select the provisioner for creating the workload cluster(shared services cluster). Provisioner reflects the vSphere namespaces that you have created and associated with the Management cluster.

    ![](img/tko-on-vsphere-nsxt/64-ss-2.png)

3.  Enter a name for the cluster. Cluster names must be unique within an organization.

    Select the cluster group to which you want to attach your cluster. You can optionally enter a description and apply labels.

    ![](img/tko-on-vsphere-nsxt/65-ss-3.png)

4.  On the configure page, specify the following:

    - Select the Kubernetes version to use for the cluster. The latest supported version is preselected for you. You can choose the appropriate Kubernetes version by clicking on the down arrow button. 
    - You can optionally define an alternative CIDR for the pod and service. The Pod CIDR and Service CIDR cannot be changed after the cluster is created. 
    - You can optionally specify a proxy configuration to use for this cluster.

    Please note that the scope of this document doesn't cover the use of a proxy for TKG deployment.. If your environment uses a proxy server to connect to the internet, please ensure the proxy configuration object includes the CIDRs for the pod, ingress, and egress from the workload network of the Management Cluster in the **No proxy list**, as described [here](https://docs.vmware.com/en/VMware-Tanzu-Mission-Control/services/tanzumc-using/GUID-B4760775-388A-45B5-A707-2191E9E4F41F.html#GUID-B4760775-388A-45B5-A707-2191E9E4F41F)

    ![](img/tko-on-vsphere-nsxt/66-ss-4.png)

5.  Select the resources for backing this cluster. Provide the Resource Pool, VM folder and Datastore information. 

    ![](img/tko-on-vsphere-nsxt/67-ss-5.png)

6. Select the High Availability mode for the control plane nodes of the workload cluster. For a production deployment, it is recommended to deploy a highly available workload cluster. 

    ![](img/tko-on-vsphere-nsxt/68-ss-6.png)

7.  Customize the default node pool for your workload cluster.

    - Specify the number of worker nodes to provision.
    - Select the instance type.

    Click on the Create Cluster button to start provisioning your workload cluster. 

    ![](img/tko-on-vsphere-nsxt/69-ss-7.png)

8. You can monitor the workload cluster creation from the TMC console. 

    ![](img/tko-on-vsphere-nsxt/69-ss-8.png)

9. Once the cluster is created, you can check the status from TMC. 

    ![](img/tko-on-vsphere-nsxt/70-ss-8.png)

Cluster creation roughly takes 15-20 minutes to complete. After the cluster deployment completes, ensure that Agent and extensions health shows green.

Now, connect to the Tanzu Management Cluster context and apply below labels.

```bash
## Connect to tkg management cluster

kubectl config use-context tkg-mgmt01-admin@tkg-mgmt01

## verify the shared service cluster creation

 tanzu cluster list
  NAME            NAMESPACE  STATUS   CONTROLPLANE  WORKERS  KUBERNETES        ROLES   PLAN
  tkg-shared-svc  default    running  3/3           3/3      v1.22.5+vmware.1  <none>  prod

## Add the tanzu-services label to the shared services cluster as its cluster role, in below command “tkg-shared-svc” is the name of the shared service cluster

kubectl label cluster.cluster.x-k8s.io/tkg-shared-svc cluster-role.tkg.tanzu.vmware.com/tanzu-services="" --overwrite=true

## Tag shared service cluster with all “Cluster Labels” defined while deploying Management Cluster, once the “Cluster Labels” are applied AKO pod will be deployed on the Shared Service Cluster

kubectl label cluster tkg-shared-svc type=management 
```

Get the admin context of the shared service cluster using the below commands and switch the context to the Shared Service cluster

```bash
## Use below command to get the admin context of Shared Service Cluster,in below command “tkg-shared-svc” is the name of the shared service cluster 

tanzu cluster kubeconfig get tkg-shared-svc --admin

## Use below to use the context of Shared Service Cluster

kubectl config use-context tkg-shared-svc-admin@tkg-shared-svc

## Verify that ako pod gets deployed in avi-system namespace

kubectl get pods -n avi-system
NAME    READY   STATUS    RESTARTS   AGE
ako-0   1/1     Running   0          41s
```

Now the shared service cluster is successfully created, you may proceed with deploying the Harbor package. 

## <a id="createworkload"> </a> Deploy Tanzu Kubernetes Cluster (Workload Cluster)

As per the architecture, workload clusters make use of a separate SE group (**Service Engine Group 2)** and VIP Network (**TKG Workload VIP/Data Network**) for application load balancing, this can be controlled by creating a new **AKODeploymentConfig**. For more details refer [Create and deploy AKO Deployment Config for TKG Workload Cluster](#workloadako)

Deployment of Workload clusters can be done from TMC by following the below steps:

1. Navigate to the Clusters tab and click on the Create Cluster button.

    Under the create cluster page, select the Management cluster which you registered in the previous step and click on the continue to create cluster button.

2. Select the provisioner for creating the workload cluster. Provisioner reflects the vSphere namespaces that you have created and associated with the Management cluster.

    ![](img/tko-on-vsphere-nsxt/71-workload-0.png)

3.  Enter a name for the cluster. Cluster names must be unique within an organization.

    Select the cluster group to which you want to attach your cluster. You can optionally enter a description and apply labels.

    ![](img/tko-on-vsphere-nsxt/71-workload-1.png)

4.  On the configure page, specify the following:

    - Select the Kubernetes version to use for the cluster. The latest supported version is preselected for you. You can choose the appropriate Kubernetes version by clicking on the down arrow button. 
    - You can optionally define an alternative CIDR for the pod and service. The Pod CIDR and Service CIDR cannot be changed after the cluster is created. 
    - You can optionally specify a proxy configuration to use for this cluster.

    Please note that the scope of this document doesn't cover the use of a proxy for vSphere with Tanzu. If your environment uses a proxy server to connect to the internet, please ensure the proxy configuration object includes the CIDRs for the pod, ingress, and egress from the workload network of the Supervisor Cluster in the **No proxy list**, as described [here](https://docs.vmware.com/en/VMware-Tanzu-Mission-Control/services/tanzumc-using/GUID-B4760775-388A-45B5-A707-2191E9E4F41F.html#GUID-B4760775-388A-45B5-A707-2191E9E4F41F)

    ![](img/tko-on-vsphere-nsxt/72-workload-2.png)

5.  Select the resources for backing this cluster. Provide the Resource Pool, VM folder and Datastore information. 

    ![](img/tko-on-vsphere-nsxt/73-workload-3.png)

6.  Select the High Availability mode for the control plane nodes of the workload cluster. For a production deployment, it is recommended to deploy a highly available workload cluster. 

    ![](img/tko-on-vsphere-nsxt/74-workload-4.png)

7. You can optionally define the default node pool for your workload cluster.

    - Select the instance type for workload clusters.
    - Specify the number of worker nodes to provision.
    - Select the storage class.

    Click on the Create Cluster button to start provisioning your workload cluster. 

    ![](img/tko-on-vsphere-nsxt/75-workload-5.png)

8. You can monitor the workload cluster creation from the TMC console. 
    ![](img/tko-on-vsphere-nsxt/75-workload-6.png)

9. Cluster creation roughly takes 15-20 minutes to complete. After the cluster deployment completes, ensure that Agent and extensions health shows green.

    ![](img/tko-on-vsphere-nsxt/76-workload-6.png)

### <a id="workloadako"> </a> Configure NSX Advanced Load Balancer in TKG Workload Cluster

Tanzu Kubernetes Grid v1.5.x management clusters with NSX Advanced Load Balancer are deployed with 2 AKODeploymentConfigs. 

1. Install-ako-for-management-cluster: default config for management cluster
1. Install-ako-for-all:  default config for all TKG clusters. By default, any clusters that match the cluster labels defined in install-ako-for-all will reference this file for their virtual IP networks, service engine (SE) groups, and L7 ingress. As part of our architecture, only shared service cluster makes use of the configuration defined in the default AKODeploymentConfig “install-ako-for-all”

    As per the defined **architecture**, workload clusters must **not** make **use** of **Service Engine Group 1** and VIP Network **TKG Cluster VIP/Data Network** for application load balancer services. A separate SE group (**Service Engine Group 2)** and VIP Network (**TKG Workload VIP/Data Network**) will be used by the workload clusters, These configurations can be enforced on workload clusters by:

    - Creating a new AKODeploymentConfig in the TKG management cluster. This AKODeploymentConfig file dictates which specific SE group and VIP network that the workload clusters can use for load balancer functionalities  
    - Apply the new AKODeploymentConfig:  Label the workload cluster to match the AKODeploymentConfig.spec.clusterSelector.matchLabels element in the AKODeploymentConfig file. 
      Once the labels are applied on the workload cluster, TKG management cluster will deploy AKO pod on the target workload cluster which has the configuration defined in the new AKODeploymentConfig 

        Below is the format of the AKODeploymentConfig yaml file. 

    ```yaml
    apiVersion: networking.tkg.tanzu.vmware.com/v1alpha1
    kind: AKODeploymentConfig
    metadata:
      finalizers:
        - ako-operator.networking.tkg.tanzu.vmware.com
      generation: 1
      labels:
      name: <Unique name of AKODeploymentConfig>
    spec:
      adminCredentialRef:
        name: nsx-alb-controller-credentials
        namespace: tkg-system-networking
      certificateAuthorityRef:
        name: nsx-alb-controller-ca
        namespace: tkg-system-networking
      cloudName: <NAME OF THE CLOUD in ALB> 
      clusterSelector:
        matchLabels:
          <KEY>: <VALUE>
      controlPlaneNetwork:
        cidr: <WORKLOAD NETWORK CIDR>
        Name: <WORKLOAD NETWORK NAME>
      controller: <NSX ALB CONTROLLER IP/FQDN>
      dataNetwork:
        cidr: <VIP NETWORK CIDR> 
        name: <VIP NETWORK NAME> 
      extraConfigs:
      cniPlugin: antrea
      disableStaticRouteSync: true
      enableEVH: false
      ingress:
          defaultIngressController: false
          disableIngressClass: true
          noPGForSNI: false
        l4Config:
          advancedL4: false
          autoFQDN: disabled
        layer7Only: false
        networksConfig:
          enableRHI: false
        servicesAPI: false
      serviceEngineGroup: <SERVICE ENGINE NAME>
    ```

    Below is the sample AKODeploymentConfig with sample values in place, as per the below configuration, TKG management cluster will deploy AKO pod on any workload cluster that matches the **label** “**`type=workloadset01`”** and the AKO configuration will be as below

    - cloud: ​**`tanzu-vcenter-01`​**
    - service engine Group: **`tanzu-wkld-segroup-01`**
    - Control plane network: **`tkg-workload-segment`**
    - VIP/data network: **`tkg-workload-vip-segment`** 

    ```yaml
    apiVersion: networking.tkg.tanzu.vmware.com/v1alpha1
    kind: AKODeploymentConfig
    metadata:
      finalizers:
      - ako-operator.networking.tkg.tanzu.vmware.com
      generation: 1
      labels:
      name: tanzu-ako-workload-set01
    spec:
      adminCredentialRef:
        name: avi-controller-credentials
        namespace: tkg-system-networking
      certificateAuthorityRef:
        name: avi-controller-ca
        namespace: tkg-system-networking
      cloudName: tanzu-vcenter01
      clusterSelector:
        matchLabels:
          type: workloadset01
      controlPlaneNetwork:
        cidr: 172.19.60.0/24
        name: tkg-workload-segment
      controller: alb-ha.lab.vmw
      dataNetwork:
        cidr: 172.19.70.0/24
        name: tkg-workload-vip-segment
      extraConfigs:
        cniPlugin: antrea
        disableStaticRouteSync: true
        enableEVH: false
        ingress:
          defaultIngressController: false
          disableIngressClass: true
          noPGForSNI: false
        l4Config:
          advancedL4: false
          autoFQDN: disabled
        layer7Only: false
        networksConfig:
          enableRHI: false
        servicesAPI: false
      serviceEngineGroup: tanzu-wkld-segroup-01
    ```

Once you have the AKO configuration file ready, use kubectl command to set the context to TKG management cluster and use below command to list the available AKODeploymentConfig

```bash
kubectl apply -f <path_to_akodeploymentconfig.yaml>
```

Use below command to list all AKODeploymentConfig created under management cluster

```bash
kubectl get adc  or 

kubectl get akodeploymentconfig
```

![](img/tko-on-vsphere-nsxt/77-workload-ako-1.png)

Now that you have successfully created the AKO deployment config, you need to apply the cluster labels defined in the AKODeploymentConfig to any of the TKG workload clusters , once the labels are applied TKG management cluster will deploy  AKO pod on the target workload cluster.

```bash
kubectl label cluster <Cluster_Name> <label>
```

![](img/tko-on-vsphere-nsxt/78-workload-ako-2.png)

### Connect to TKG Workload Cluster and validate the deployment

Now that you have the TKG workload cluster is created and required AKO configurations are applied, use the below command to get the admin context of the TKG workload cluster.

```bash
tanzu cluster kubeconfig get <cluster-name> --admin
```

![](img/tko-on-vsphere-nsxt/79-workload-ako-3.png)

Now connect to the TKG workload cluster using the kubectl command and run below commands to check the status of AKO and other components

```bash
kubectl get nodes  ## List all nodes with status
kubectl get pods -n avi-system ## To check the status of AKO pod
kubectl get pods -A   ## Lists all pods and it’s status
```

![](img/tko-on-vsphere-nsxt/80-workload-ako-4.png)

You can see that the workload cluster is successfully deployed and AKO pod is deployed on the cluster. You can now configure SaaS services for the cluster and/or deploy user managed packages on this cluster.
