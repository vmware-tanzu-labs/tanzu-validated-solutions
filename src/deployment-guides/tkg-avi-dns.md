# AVI DNS Virtual Service with TKGM

The Purpose of thie Document is to demonstrate how we can leverage AVI DNS Virtual Service to as a DNS Server for workload application.For More information Please refer [**Product Documentation**](https://docs.vmware.com/en/VMware-Tanzu-Mission-Control/services/tanzumc-using/GUID-EF35646D-8762-41F1-95E5-D2F35ED71BA1.html) .

AVI DNS Virtual Service is available only in AVI Enterprice license or more. 

## General Instructions for Installing AVI DNS and L7 Ingress Service Provider.

NSX ALB as in L7 Ingress Service Provider

We will be Deploying NSX ALB L7 ingress in NodePortLocal mode in our infrastructure, For more information please refer NSX ALB as in L4+L7 Ingress Service Provider Session in Referance Architecture.


Link will be given here to our RA 

L7 functionality will be enabled using AKO configuration files as part of the Management cluster deployment. 

Deployment file will given here for referance.
### Create a Service Engine Group.
To create or edit an SE group:

1. Select Infrastructure > Clouds and click on the cloud name (for example, Default-Cloud).
2. Select Service Engine Group to open the Service Engine Groups page, which lists the SE groups currently configured in Vantage.
3. Click New Service Engine Group or click on an SE group name in the table.

The create and edit popups for SE groups have identical properties. This popup includes the following tabs:

* Upate the Service Engine Group Name.
* Select High Availability to Active/Active.
* VS Placement across Service Engines should be Compact.

### Configuring DNS

DNS Virtual Service
Starting with release 18.1.2, the DNS virtual service can be configured with IPv4 VIP, IPv6 VIP, or a dual VIP.

Navigate to Applications > Virtual Services and click on Create Virtual Service (Advanced Setup) Select the Cloud. Configuration tabs associated with DNS are as explained below.

Settings
*  Update **Name**
*  VS 
*  **TCP/UDP Profile** Select System-UDP-Per-Pkt.
*  **Application Profiles** Select Select System-DNS.
*  In **VS VIP**  Select **Create VS VIP** Enter Name & under **VIP** Select **ADD** 

   * **Private IP** > **Auto-Allocate**
   * **IP Protocol** > **V4 Only**
   * **VIP Address Allocation Network** > **sfo01-w01-vds01-tkgmanagementvip**
   * **IPv4 Subnet** > Select the Defined network
* Click **SAVE**

### Configuring DNS Name

DNS Profile will be created as part of the Managment cluster creation.

Navigate to **Templates** > **IPAM/DNS Profiles** and Select the DNS **Virtual Service**
by using the drop-down option.

* Update the DNS Name for AVI DNS by Selecting **ADD** > **SAVE**

### Update AVI DNS Service

Navigate to **Administration** > **DNS Service** and Select the DNS profile **Click** on pencil icon to **EDIT**.

