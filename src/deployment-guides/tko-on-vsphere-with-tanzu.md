# Deploy VMware Tanzu for Kubernetes Operations using vSphere with Tanzu

This document outlines the steps for deploying Tanzu for Kubernetes Operations (informally known as TKO) using vSphere with Tanzu in a vSphere environment backed by a Virtual Distributed Switch (VDS) and leveraging NSX Advanced Load Balancer (ALB) Enterprise Edition for L4/L7 load balancing and ingress.

The scope of the document is limited to providing deployment steps based on the reference design in [VMware Tanzu for Kubernetes Operations using vSphere with Tanzu Reference Design](../reference-designs/tko-on-vsphere-with-tanzu.md). This document does not cover any deployment procedures for the underlying SDDC components.

## Deploying with VMware Service Installer for Tanzu
 
You can use VMware Service Installer for VMware Tanzu to automate this deployment.
 
VMware Service Installer for Tanzu automates the deployment of the reference designs for Tanzu for Kubernetes Operations. It uses best practices for deploying and configuring the required Tanzu for Kubernetes Operations components.
 
To use Service Installer to automate this deployment, see [Deploying VMware Tanzu for Kubernetes Operations on vSphere with Tanzu and vSphere Distributed Switch Using Service Installer for VMware Tanzu](https://docs.vmware.com/en/Service-Installer-for-VMware-Tanzu/2.1/service-installer/GUID-index.html).
 
Alternatively, if you decide to manually deploy each component, follow the steps provided in this document.

## Prerequisites

Before deploying Tanzu Kubernetes Operations using vSphere with Tanzu on vSphere networking, ensure that your environment is set up as described in the following:

*   [General Requirements](#general-requirements)
*   [Network Requirements](#network-requirements)
*   [Firewall Requirements](#firewall-requirements)
*   [Resource Pools](#resource-pools)

### <a id=general-requirements> </a> General Requirements

Ensure that your environment meets the following general requirements:

- vSphere 8.0 instance with an Enterprise Plus license.
- Your vSphere environment has the following objects in place:
  - A vSphere cluster with at least 3 hosts on which vSphere HA & DRS is enabled. If you are using vSAN for shared storage, it is recommended that you use 4 ESXi hosts.
  - A distributed switch with port groups for TKO components. See [Network Requirements](#network-requirements) for the required port groups.
  - All ESXi hosts of the cluster on which vSphere with Tanzu will be enabled should be part of the distributed switch.
  - Dedicated resource pools and VM folder for collecting NSX Advanced Load Balancer VMs.
  - A shared datastore with sufficient capacity for the control plane and worker node VM files.
- Network Time Protocol (NTP) service running on all hosts and vCenter.
- A user account with **Modify cluster-wide configuration** permissions.
- NSX Advanced Load Balancer 22.1.2 OVA downloaded from [customer connect](https://customerconnect.vmware.com/) portal and readily available for deployment.

> **Note** Tanzu Kubernetes Grid nodes will unable to resolve hostname with the “.local” domain suffix. For more information, see [KB article](https://kb.vmware.com/s/article/83623).

For additional information on general prerequisites, see [vSphere with Tanzu product documentation](https://docs.vmware.com/en/VMware-vSphere/8.0/vsphere-with-tanzu-concepts-planning/GUID-7FF30A74-DDDD-4231-AAAE-0A92828B93CD.html).

### <a id=network-requirements> </a> Network Requirements

The following table provides example entries for the required port groups. Create network entries with the port group name, VLAN ID, and CIDRs that are specific to your environment.

| Network Type                 | DHCP Service              | Description & Recommendations            |
| ---------------------------- | ------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| NSX ALB Management Network   | Optional                  | NSX ALB controllers and SEs will be attached to this network. <br> Use static IPs for the NSX ALB controllers. <br>                                                                       |
| TKG Management Network       | IP Pool | Supervisor Cluster nodes will be attached to this network. <br> When an IP Pool is used, ensure that the block has 5 consecutive free IPs.                                                                                                                          |
| TKG Workload Network         | IP Pool | Control plane and worker nodes of TKG Workload Clusters will be attached to this network.                                                                                                                                                                        |
| TKG Cluster VIP/Data Network | No                        | Virtual services for Control plane HA of all TKG clusters (Supervisor and Workload). <br>Reserve sufficient IPs depending on the number of TKG clusters planned to be deployed in the environment, NSX ALB handles IP address management on this network via IPAM. |

This document uses the following port groups, subnet CIDRs, and VLANs. Replace these with values that are specific to your environment.  Plan network subnet sizes according to applications need and future requirement.

| Network Type               | Port Group Name | VLAN | Gateway CIDR   | DHCP Enabled | IP Pool for SE/VIP in NSX ALB       |
| -------------------------- | --------------- | ---- | -------------- | ------------ | ----------------------------------- |
| NSX ALB Management Network | sfo01-w01-vds01-albmanagement   | 1680 | 172.16.80.1/27 | No           | 172.16.80.6 - 172.16.80.30          |
| TKG Management Network     | sfo01-w01-vds01-tkgmanagement   | 1681 | 172.16.81.1/27 | Yes          | No                                  |
| TKG Workload Network01     | sfo01-w01-vds01-tkgworkload     | 1682 | 172.16.82.1/24 | Yes          | No                                  |
| TKG VIP Network            | sfo01-w01-vds01-tkgclustervip   | 1683 | 172.16.83.1/26 | No           | 172.16.83.2 - 172.16.83.62|

### <a id=firewall-requirements> </a> Firewall Requirements

Ensure that the firewall is set up as described in [Firewall Requirements](../reference-designs/tko-on-vsphere-with-tanzu.md#firewall-requirements).

### <a id=resource-pools> </a>Resource Pools

Ensure that resource pools and folders are created in vCenter. The following table shows a sample entry for the resource pool and folder. Customize the resource pool and folder name for your environment.

| Resource Type      | Resource Pool name                    | Sample Folder name                |
| ------------------ | ------------------------------------- | --------------------------------- |
| NSX ALB Components | tkg-vsphere-alb-components            | tkg-vsphere-alb-components        |

## Deployment Overview

Here are the high-level steps for deploying Tanzu Kubernetes operations on vSphere networking backed by VDS:

1.  [Deploy and Configure NSX Advanced Load Balancer](#config-nsxalb)
2.  [Deploy Tanzu Kubernetes Grid Supervisor Cluster](#deployTKGS)
3.  [Create and Configure vSphere Namespaces](#create-namespace)
4.  [Register Supervisor Cluster with Tanzu Mission Control](#integrate-supervisor-tmc)
5.  [Deploy Tanzu Kubernetes Clusters (Workload Clusters)](#deploy-workload-cluster)
6.  [Integrate Tanzu Kubernetes Clusters with Tanzu Observability](#integrate-to)
7.  [Integrate Tanzu Kubernetes Clusters with Tanzu Service Mesh](#integrate-tsm)
8.  [Deploy User-Managed Packages on Tanzu Kubernetes Grid Clusters](#deploy-user-managed-packages)

> **Note** Starting with vSphere 8, when you enable vSphere with Tanzu, you can configure either one-zone Supervisor mapped to one vSphere cluster or three-zone Supervisor mapped to three vSphere clusters.
This document covers One-Zone supervisor deployment with VDS Networking and NSX Advanced Load Balancer. [Requirements for Cluster Supervisor Deployment with NSX Advanced Load Balancer and VDS Networking](https://docs.vmware.com/en/VMware-vSphere/8.0/vsphere-with-tanzu-concepts-planning/GUID-7FF30A74-DDDD-4231-AAAE-0A92828B93CD.html).

## <a id="config-nsxalb"> </a> Deploy and Configure NSX Advanced Load Balancer

NSX Advanced Load Balancer is an enterprise-grade integrated load balancer that provides L4-L7 load balancer support. VMware recommends deploying NSX Advanced Load Balancer for vSphere deployments without NSX-T, or when there are unique scaling requirements.

NSX Advanced Load Balancer is deployed in write access mode in the vSphere environment. This mode grants NSX Advanced Load Balancer controllers full write access to the vCenter. Full write access allows automatically creating, modifying, and removing Service Engines and other resources as needed to adapt to changing traffic needs.

For a production-grade deployment, VMware recommends deploying three instances of the NSX Advanced Load Balancer controller for high availability and resiliency.

The following table provides a sample IP address and FQDN set for the NSX Advanced Load Balancer controllers:

| Controller Node    | IP Address  | FQDN                               |
| ------------------ | ------------| -----------------------------------|
| Node01 (Primary)   | 172.16.80.3 | sfo01albctlr01a.sfo01.rainpole.vmw |
| Node02 (Secondary) | 172.16.80.4 | sfo01albctlr01b.sfo01.rainpole.vmw |
| Node03 (Secondary) | 172.16.80.5 | sfo01albctlr01c.sfo01.rainpole.vmw |
| Controller Cluster | 172.16.80.2 | sfo01albctlr01.sfo01.rainpole.vmw  |

### Deploy NSX Advance Load Balancer Controller Node

Do the following to deploy NSX Advanced Load Balancer controller node:

1.  Log in to the vCenter Server by using the vSphere Client.
2.  Select the cluster where you want to deploy the NSX Advanced Load Balancer controller node.
3.  Right-click on the cluster and invoke the Deploy OVF Template wizard.
4.  Follow the wizard to configure the following:

   - VM Name and Folder Location.
   - Select the tkg-vsphere-alb-components resource pool as a compute resource.
   - Select the datastore for the controller node deployment.
   - Select the sfo01-w01-vds01-albmanagement port group for the Management Network.
   - Customize the configuration by providing Management Interface IP Address, Subnet Mask, and Default Gateway. The remaining fields are optional and can be left blank.

   The following example shows the final configuration of the NSX Advanced Load Balancer controller node.

   ![Completed configuration of the NSX Advanced Load Balancer controller node](img/tko-on-vsphere-with-tanzu/TKO-VWT01.png)

 For more information, see the product documentation [Deploy the Controller](https://docs.vmware.com/en/VMware-vSphere/8.0/vsphere-with-tanzu-installation-configuration/GUID-CBA041AB-DC1D-4EEC-8047-184F2CF2FE0F.html).

### Configure the Controller Node for your vSphere with Tanzu Environment

After the controller VM is deployed and powered-on, configure the controller VM for your vSphere with Tanzu environment. The controller requires several post-deployment configuration parameters.

On a browser, go to https://<https://<alb-ctlr01.tanzu.lab>/.

1. Configure an **Administrator Account** by setting up a password and optionally, an email address.

  ![Screenshot of Create Account screen](img/tko-on-vsphere-with-tanzu/TKO-VWT02.png)

2. Configure **System Settings** by specifying the backup passphrase and DNS information.

  ![Screenshot of System Settings screen](img/tko-on-vsphere-with-tanzu/TKO-VWT03.png)

3. (Optional) Configure **Email/SMTP**.

  ![Screenshot of Email/SMTP screen](img/tko-on-vsphere-with-tanzu/TKO-VWT04.png)

4. Configure **Multi-Tenant** settings as follows:

   - IP Route Domain: Share IP route domain across tenants.
   - Service Engine Context: Service Engines are managed within the tenant context, not shared across tenants.

![Screenshot of Multi-Tenant screen](img/tko-on-vsphere-with-tanzu/TKO-VWT05.png)

5. Click on **Save** to finish the post-deployment configuration wizard.

If you did not select the **Setup Cloud After** option before saving, the initial configuration wizard exits. The Cloud configuration window does not automatically launch and you are directed to a Dashboard view on the controller.

### Configure Default-Cloud

1. Navigate to **Infrastructure > Clouds** and edit **Default-Cloud**.

  ![Screenshot of Infrastructure screen showing tabs](img/tko-on-vsphere-with-tanzu/TKO-VWT06.png)

2. Select **VMware vCenter/vSphere ESX** as the infrastructure type and click **Next**.

  ![Screenshot of the **Edit Clouds** screen](img/tko-on-vsphere-with-tanzu/TKO-VWT07.png)

3. On the **vCenter/vSphere** tab, click **SET CREDENTIALS** and configure the following:

  - vCenter Address: vCenter IP address or fqdn.
  - vCenter Credentials: Username/password of the vCenter account to use for NSX ALB integration.
  - Access Permission: Write

  ![Screenshot of Infrastructure tab on Edit Cloud screen](img/tko-on-vsphere-with-tanzu/TKO-VWT08.png)

4. Select the **Data Center** and configure the following:

   - Select the vSphere **Data Center** where you want to enable **Workload Management**.
   - Select Content library which holds tanzu kubernetes release ova templates.
   - Click **SAVE & RELAUNCH**

![Screenshot of Data Center tab on Edit Cloud screen](img/tko-on-vsphere-with-tanzu/TKO-VWT09.png)

11. Configure the **Network** settings as follows:

   - Select the **sfo01-w01-vds01-albmanagement** as **Management Network**. This network interface is used by the Service Engines to connect with the controller.
   - **IP Address Management for Management Network**: Select **DHCP Enabled** if DHCP is available on the vSphere port groups.
   - If DHCP is not available, enter the **IP Subnet**, IP address range (**Add Static IP Address Pool**), **Default Gateway** for the Management Network, then click **Save**.

   ![Screenshot of Network tab on Edit Cloud screen](img/tko-on-vsphere-with-tanzu/TKO-VWT10.png)

2. Ensure that the health of the Default-Cloud is green after configuration.

![Screenshot of Clouds tab on Infrastructure screen](img/tko-on-vsphere-with-tanzu/TKO-VWT11.png)

### Configure Licensing

Tanzu for Kubernetes Operations requires an NSX Advanced Load Balancer Enterprise license. 

1. Go to **Administration > Licensing**.
2. Click **gear** icon. 

  ![Screenshot of Licensing tab](img/tko-on-vsphere-with-tanzu/TKO-VWT12.png)

3. Select Enterprise Tier

  ![Screenshot of License Tier](img/tko-on-vsphere-with-tanzu/TKO-VWT12-a.png)

4. Provide the license key and click **Apply Key**.

  ![Screenshot of Apply License Key section of Licensing tab](img/tko-on-vsphere-with-tanzu/TKO-VWT13.png)

### Configure NTP Settings

  Configure NTP settings if you want to use an internal NTP server.

 1. Go to the **Administration > Settings > DNS/NTP** page.

    

 2. Click the pencil icon on the upper right corner to enter edit mode. 

3. .  On the **Update System Settings** dialog, edit the settings for the NTP server that you want to use.

![Screenshot of Update System Settings dialog](img/tko-on-vsphere-with-tanzu/TKO-VWT14.png)

4.  Click **Save** to save the settings.

### Deploy NSX Advanced Load Balancer Controller Cluster

In a production environment, VMware recommends that you deploy additional controller nodes and configure the controller cluster for high availability and disaster recovery.

To run a three-node controller cluster, you deploy the first node and perform the initial configuration, and set the Cluster IP. After that, you deploy and power on two more controller VMs. However, do not run the initial configuration wizard or change the administrator password for the two additional controllers VMs. The configuration of the first controller VM is assigned to the two new controller VMs.

To configure the Controller cluster:

1. Navigate to **Administration > Controller**

1. Select **Nodes** and click **Edit**.

1. Specify a name for the controller cluster and set the cluster IP address. This IP address should be from the NSX Advanced Load Balancer management network.

   ![Screenshot of Controller tab on the Administration screen](img/tko-on-vsphere-with-tanzu/TKO-VWT16.png)

2. In **Cluster Nodes**, specify the IP addresses of the two additional controllers that you have deployed.

   Leave the name and password fields empty.

   ![Screenshot of Edit Controller Configuration dialog](img/tko-on-vsphere-with-tanzu/TKO-VWT17.png)

3. Click **Save**.

The controller cluster setup starts. The controller nodes are rebooted in the process. It takes approximately 10-15 minutes for cluster formation to complete.

You are automatically logged out of the controller node you are currently logged in. Enter the cluster IP address in a browser to see the cluster formation task details.

   ![Screenshot of Controller Initializing screen](img/tko-on-vsphere-with-tanzu/TKO-VWT18.png)

The first controller of the cluster receives the "Leader" role. The second and third controllers will work as "Follower".

   ![Controller Role](img/tko-on-vsphere-with-tanzu/TKO-VWT19.png)

After the controller cluster is deployed, use the controller cluster IP address for doing any additional configuration. Do not use the individual controller node IP address.

  For additional product documentation, see [Deploy a Controller Cluster](https://docs.vmware.com/en/VMware-vSphere/8.0/vsphere-with-tanzu-installation-configuration/GUID-CBA041AB-DC1D-4EEC-8047-184F2CF2FE0F.html).

### Change NSX Advanced Load Balancer Portal Default Certificate

The controller must send a certificate to clients to establish secure communication. This certificate must have a Subject Alternative Name (SAN) that matches the NSX Advanced Load Balancer controller cluster hostname or IP address.

The controller has a default self-signed certificate. But this certificate does not have the correct SAN. You must replace it with a valid or self-signed certificate that has the correct SAN. You can create a self-signed certificate or upload a CA-signed certificate.

> **Note** This document makes use of a self-signed certificate.

To replace the default certificate:

1. Navigate to the **Templates > Security > SSL/TLS Certificate >** and click **Create** and select **Controller Certificate**.

   ![Screenshot of the SSL/TSL Certificates tab](img/tko-on-vsphere-with-tanzu/TKO-VWT20.png)

1. The **New Certificate (SSL/TLS)** window appears. Enter a name for the certificate.

To add a self-signed certificate:

1. For **Type** select **Self Signed** and enter the following details:

   - **Common Name:** Specify the fully-qualified name of the site **sfo01albctlr01.sfo01.rainpole.vmw**. For the site to be considered trusted, this entry must match the hostname that the client entered in the browser.

   - **Subject Alternate Name (SAN):** Enter the cluster IP address or FQDN of the controller cluster and all controller nodes.

   - **Algorithm:** Select either EC or RSA.

   - **Key Size**

2. Click **Save**.

    ![Controller New Certificate](img/tko-on-vsphere-with-tanzu/TKO-VWT21.png)

3. Change the NSX Advanced Load Balancer portal certificate.

   - Navigate to the **Administration > Settings > Access Settings**.

   - Clicking the pencil icon to edit the access settings.

   - Verify that **Allow Basic Authentication** is enabled.

   - From **SSL/TLS Certificate**, remove the existing default portal certificates

   - From the drop-down list, select the newly created certificate

   - Click **Save**.

   ![Screenshot of the New Certificate (SSL/TLS) window](img/tko-on-vsphere-with-tanzu/TKO-VWT22.png)

For additional product documentation, see [Assign a Certificate to the Controller](https://docs.vmware.com/en/VMware-vSphere/8.0/vsphere-with-tanzu-installation-configuration/GUID-CBA041AB-DC1D-4EEC-8047-184F2CF2FE0F.html).

### Export NSX Advanced Load Balancer Certificate

You need the newly created certificate when you configure the Supervisor cluster to enable **Workload Management**.

To export the certificate, navigate to the **Templates > Security > SSL/TLS Certificate** page and export the certificate by clicking **Export**.

On the **Export Certificate** page, click **Copy to clipboard** against the certificate. Do not copy the key. Save the copied certificate to use when you enable workload management.

### Configure a Service Engine Group

vSphere with Tanzu uses the Default Service Engine Group. Ensure that the HA mode for the default-Group is set to N + M (buffer).

Optionally, you can reconfigure the Default-Group to define the placement and number of Service Engine VMs settings.

This document uses the Default Service Engine Group without modification.

For more information, see the product documentation [Configure a Service Engine Group](https://docs.vmware.com/en/VMware-vSphere/8.0/vsphere-with-tanzu-installation-configuration/GUID-14A98969-3115-45AC-9F0D-AA5A8EA6E16D.html).

### <a id=config-vip> </a> Configure a Virtual IP Subnet for the Data Network

You can configure the virtual IP (VIP) range to use when a virtual service is placed on the specific VIP network. You can configure DHCP for the Service Engines.

Optionally, if DHCP is unavailable, you can configure a pool of IP addresses to assign to the Service Engine interface on that network.

This document uses an IP pool for the VIP network.

To configure the VIP network:

1. Navigate to **Infrastructure > Cloud Resources > Networks** and locate the network that provides the virtual IP addresses.

2. Click the edit icon to edit the network settings.

3. Click **Add Subnet**.

4. In **IP Subnet**, specify the VIP network subnet CIDR.

5. Click **Add Static IP Address Pool** to specify the IP address pool for the VIPs and Service Engine. The range must be a subset of the network CIDR configured in **IP Subnet**.

   ![Screenshot of Edit Network Settings screen](img/tko-on-vsphere-with-tanzu/TKO-VWT23.png)

6. Click **Save** to close the VIP network configuration wizard.

For more information, see the product documentation [Configure a Virtual IP Network](https://docs.vmware.com/en/VMware-vSphere/8.0/vsphere-with-tanzu-installation-configuration/GUID-14A98969-3115-45AC-9F0D-AA5A8EA6E16D.html).

### Configure Default Gateway

A default gateway enables the service engine to route traffic to the pool servers on the Workload Network. You must configure the VIP Network gateway IP address as the default gateway.

To configure the default gateway:

1. Navigate to **Infrastructure > Cloud Resources > VRF Context** 

2. Click **Create**.

  ![Screenshot of Infrastructure tabs](img/tko-on-vsphere-with-tanzu/TKO-VWT24.png)

3. Under **Static Route**, click **ADD**

4. In **Gateway Subnet**, enter 0.0.0.0/0

4. In **Next Hop**, enter the gateway IP address of the VIP network.

5. Click **Save**.

  ![Screenshot of Edit Static Route screen](img/tko-on-vsphere-with-tanzu/TKO-VWT25.png)

For additional product documentation, see [Configure Default Gateway](https://docs.vmware.com/en/VMware-vSphere/8.0/vsphere-with-tanzu-installation-configuration/GUID-14A98969-3115-45AC-9F0D-AA5A8EA6E16D.html)

### Configure IPAM and DNS Profile

IPAM is required to allocate virtual IP addresses when virtual services get created. Configure IPAM for the NSX Advanced Load Balancer controller and assign it to the Default-Cloud.

1. Navigate to the **Templates > Profiles > IPAM/DNS Profiles**.

2. Click **Create** and select **IPAM Profile** from the dropdown menu.

  ![Screenshot of the IPAM/DNS Profiles tab](img/tko-on-vsphere-with-tanzu/TKO-VWT26.png)

1. Enter the following to configure the IPAM profile:  

   - A name for the IPAM Profile.
   - Select type as **AVI Vantage IPAM**.
   - Deselect the **Allocate IP in VRF** option.

1. Click **Add Usable Network**.

   - Select **Default-Cloud**.
   - Choose the VIP network that you have created in [Configure a Virtual IP Subnet for the Data Network](#config-vip).

   ![Screenshot of New IPAM/DNS Profile screen](img/tko-on-vsphere-with-tanzu/TKO-VWT27.png)

5. Click **Save**.
 
6. Click on the Create button again and select DNS Profile

   - Provide a name for the profile.
   - Add your domain name under **Domain Name**
   - (Optionally) set the TTL for the domain.

   ![DNS Profile](img/tko-on-vsphere-with-tanzu/TKO-VWT27-1.png)

7. Assign the IPAM and DNS profile to the Default-Cloud configuration.
    - Navigate to the **Infrastructure > Cloud**
    - Edit the **Default-Cloud** configuration as follows:
       -  **IPAM Profile**: Select the newly created profile.
       -  **DNS Profile**: Select the newly created profile.
    - Click **Save**

   ![Screenshot of Edit Cloud window](img/tko-on-vsphere-with-tanzu/TKO-VWT28.png)

8. Verify that the status of the Default-Cloud configuration is green.

For additional product documentation, see [Configure IPAM](https://docs.vmware.com/en/VMware-vSphere/8.0/vsphere-with-tanzu-installation-configuration/GUID-14A98969-3115-45AC-9F0D-AA5A8EA6E16D.html).

## <a id=deployTKGS> </a> Deploy Tanzu Kubernetes Grid Supervisor Cluster

As a vSphere administrator, you enable a vSphere cluster for Workload Management by creating a Supervisor Cluster. After you deploy the Supervisor Cluster, you can use the vSphere Client to manage and monitor the cluster.

Before deploying the Supervisor Cluster, ensure the following:

*   You have created a vSphere cluster with at least three ESXi hosts. If you are using vSAN you need a minimum of four ESXi hosts.
*   The vSphere cluster is configured with shared storage such as vSAN.
*   The vSphere cluster has HA & DRS enabled and DRS is configured in the fully-automated mode.
*   The required port groups have been created on the distributed switch to provide networking to the Supervisor and workload clusters.
*   Your vSphere cluster is licensed for Supervisor Cluster deployment.
*   You have created a [Subscribed Content Library](https://docs.vmware.com/en/VMware-vSphere/8.0/vsphere-with-tanzu-installation-configuration/GUID-6519328C-E4B7-46DE-BE2D-FC9CA0994C39.html) to automatically pull the latest Tanzu Kubernetes releases from the VMware repository.
*   You have created a [storage policy](https://docs.vmware.com/en/VMware-vSphere/8.0/vsphere-with-tanzu-installation-configuration/GUID-544286A2-A403-4CA5-9C73-8EFF261545E7.html) that will determine the datastore placement of the Kubernetes control plane VMs, containers, and images.
* A user account with **Modify cluster-wide configuration** permissions is available.
* NSX Advanced Load Balancer is deployed and configured as per instructions provided earlier.

To deploy the Supervisor Cluster:

1. Log in to the vSphere client and navigate to **Menu > Workload Management** and click **Get Started**.

  ![Screenshot of Workload Management screen](img/tko-on-vsphere-with-tanzu/TKO-VWT29.png)

2. Select the vCenter Server and Networking stack.

   - Select a vCenter server system.
   - Select **vSphere Distributed Switch (VDS)** for the networking stack.

   ![Screenshot of Networking Stack](img/tko-on-vsphere-with-tanzu/TKO-VWT30.png)

3. Select **CLUSTER DEPLOYMENT** and a cluster from the list of compatible clusters and click **Next**.

   ![Screenshot of Cluster Selection](img/tko-on-vsphere-with-tanzu/TKO-VWT31.png)

4. Select the **Control Plane Storage Policy** for the nodes from the drop-down menu and click **Next**.

   ![Screenshot of storage settings](img/tko-on-vsphere-with-tanzu/TKO-VWT32.png)

5. On the **Load Balancer** screen, select **Load Balancer Type** as **NSX Advanced Load Balancer** and provide the following details:

   - **Name**: Friendly name for the load balancer. Only small letters are supported in the name field.

   - **NSX Advanced Load Balancer Controller IP**: If the NSX Advanced Load Balancer self-signed certificate is configured with the hostname in the SAN field, use the same hostname here. If the SAN is configured with an IP address, provide the controller cluster IP address. The default port of NSX Advanced Load Balancer is 443.

   - **NSX Advanced Load Balancer Credentials**: Provide the NSX Advanced Load Balancer administrator credentials.

   - **Server Certificate**: Use the content of the controller certificate that you exported earlier while configuring certificates for the controller.

    ![Screenshot of load balancer settings](img/tko-on-vsphere-with-tanzu/TKO-VWT33.png)  

6. Click **Next**.   

7. On the **Management Network** screen, select the port group that you created on the distributed switch and provide the required networking details.

   - If DHCP is enabled for the port group, set the **Network Mode** to **DHCP**.

    Ensure that the DHCP server is configured to hand over the DNS server address, DNS search domain, and NTP server address via DHCP.

    ![Screenshot of Management Network screen](img/tko-on-vsphere-with-tanzu/TKO-VWT34.png)

8. Click **Next**.   

9. On the **Workload Network** screen, select the network that will handle the networking traffic for Kubernetes workloads running on the Supervisor cluster.

    - Set the **Network Mode**  to **DHCP** if the port group is configured for DHCP.

   ![Screenshot of the Workload Network screen](img/tko-on-vsphere-with-tanzu/TKO-VWT35.png)

10. Click **Next**.   

11. On the **Review and Confirm** screen, select the size for the Kubernetes control plane VMs that are created on each host from the cluster. For production deployments, VMware recommends a large form factor.

     ![Screenshot of Review and Conform](img/tko-on-vsphere-with-tanzu/TKO-VWT36.png)

12. Click **Finish**. This triggers the Supervisor Cluster deployment.

     ![Screenshot of Review and Confirm screen](img/tko-on-vsphere-with-tanzu/TKO-VWT37.png)

The Workload Management task takes approximately 30 minutes to complete. After the task completes, three Kubernetes control plane VMs are created on the hosts that are part of the vSphere cluster.

The Supervisor Cluster gets an IP address from the VIP network that you configured in the NSX Advanced Load Balancer. This IP address is also called the Control Plane HA IP address.


In the backend, three supervisor Control Plane VMs are deployed in the vSphere namespace. A Virtual Service is created in the NSX Advanced Load Balancer with three Supervisor Control Plane nodes that are deployed in the process.

For additional product documentation, see [Enable Workload Management with vSphere Networking](https://docs.vmware.com/en/VMware-vSphere/8.0/vsphere-with-tanzu-installation-configuration/GUID-8D7D292B-43E9-4CB8-9E20-E4039B80BF9B.html).

### Download and Install the Kubernetes CLI Tools for vSphere

You can use Kubernetes CLI Tools for vSphere to view and control vSphere with Tanzu namespaces and clusters.

The Kubernetes CLI Tools download package includes two executables: the standard open-source kubectl and the vSphere Plugin for kubectl. The vSphere Plugin for kubectl extends the commands available to kubectl so that you connect to the Supervisor Cluster and to Tanzu Kubernetes clusters using vCenter Single Sign-On credentials.

To download the Kubernetes CLI tool, connect to the URL https://<_control-plane-vip_>/

![Screenshot of the download page for Kubernetes CLI Tools](img/tko-on-vsphere-with-tanzu/TKO-VWT38-1.png)

For additional product documentation, see [Download and Install the Kubernetes CLI Tools for vSphere](https://docs.vmware.com/en/VMware-vSphere/8.0/vsphere-with-tanzu-installation-configuration/GUID-0F6E45C4-3CB1-4562-9370-686668519FCA.html).

### Connect to the Supervisor Cluster

After installing the CLI tool of your choice, connect to the Supervisor Cluster by running the following command:

```
kubectl vsphere login --vsphere-username=administrator@vsphere.local --server=<control-plane-vip>
```

The command prompts for the vSphere administrator password.

After your connection to the Supervisor Cluster is established you can switch to the Supervisor context by running the command:

```
kubectl config use-context <supervisor-context-name>
```

where the `<supervisor-context-name>` is the IP address of the control plane VIP.

## <a id=create-namespace> </a> Create and Configure vSphere Namespaces

A vSphere Namespace is a tenancy boundary within vSphere with Tanzu and allows for sharing vSphere resources (computer, networking, storage) and enforcing resources limits with the underlying objects such as Tanzu Kubernetes Clusters. It also allows you to attach policies and permissions.

Every workload cluster that you deploy runs in a Supervisor namespace. To learn more about namespaces, see the [vSphere with Tanzu documentation](https://docs.vmware.com/en/VMware-vSphere/8.0/vsphere-with-tanzu-installation-configuration/GUID-1544C9FE-0B23-434E-B823-C59EFC2F7309.html)

To create a new Supervisor namespace:

1. Log in to the vSphere Client.

2. Navigate to **Home > Workload Management > Namespaces**.

3. Click **Create Namespace**.

  ![Screenshot of the Namespaces tab](img/tko-on-vsphere-with-tanzu/TKO-VWT39.png)

4. Select the **Cluster** that is enabled for **Workload Management**.

5. Enter a name for the namespace and select the workload network for the namespace.

   > **Note** The **Name** field accepts only lower case letters and hyphens.

6. Click **Create**. The namespace is created on the Supervisor Cluster.

   ![Screenshot of the Create Namespace screen](img/tko-on-vsphere-with-tanzu/TKO-VWT40.png)

For additional product documentation, see [Create and Configure a vSphere Namespace](https://docs.vmware.com/en/VMware-vSphere/8.0/vsphere-with-tanzu-installation-configuration/GUID-177C23C4-ED81-4ADD-89A2-61654C18201B.html).   

### Configure Permissions for the Namespace

To access a namespace, you have to add permissions to the namespace. To configure permissions, click on the newly created namespace, navigate to the **Summary** tab, and click **Add Permissions**.

![Screenshot of Configure Permissions for the Namespace](img/tko-on-vsphere-with-tanzu/TKO-VWT41.png)

Choose the **Identity source**, search for the User/Group that will have access to the namespace, and define the **Role** for the selected User/Group.

![Screenshot of Add Permissions window](img/tko-on-vsphere-with-tanzu/TKO-VWT42.png)

### Set Persistent Storage to the Namespace

Certain Kubernetes workloads require persistent storage to store data permanently. Storage policies that you assign to the namespace control how persistent volumes and Tanzu Kubernetes cluster nodes are placed within datastores in the vSphere storage environment.

To assign a storage policy to the namespace, on the **Summary** tab, click **Add Storage**.

From the list of storage policies, select the appropriate storage policy and click **OK**.

![Screenshot of the Select Storage Policies](img/tko-on-vsphere-with-tanzu/TKO-VWT43.png)

After the storage policy is assigned to a namespace, vSphere with Tanzu creates a matching Kubernetes storage class in the vSphere Namespace.

### Specify Namespace Capacity Limits

When initially created, the namespace has unlimited resources within the Supervisor Cluster. The vSphere administrator defines the limits for CPU, memory, storage, as well as the number of Kubernetes objects that can run within the namespace. These limits are configured for each vSphere Namespace.

To configure resource limitations for the namespace, on the **Summary** tab, click **Edit Limits** for **Capacity and Usage**.

![Screenshot of the Resource Limits window](img/tko-on-vsphere-with-tanzu/TKO-VWT44.png)

The storage limit determines the overall amount of storage that is available to the namespace.

### Associate VM Class with Namespace

The VM class is a VM specification that can be used to request a set of resources for a VM. The VM class defines parameters such as the number of virtual CPUs, memory capacity, and reservation settings.

vSphere with Tanzu includes several default VM classes and each class has two editions: guaranteed and best effort. A guaranteed edition fully reserves the resources that a VM specification requests. A best-effort class edition does not and allows resources to be overcommitted.

More than one VM Class can be associated with a namespace. To learn more about VM classes, see the [vSphere with Tanzu documentation](https://docs.vmware.com/en/VMware-vSphere/8.0/vsphere-with-tanzu-tkg/GUID-5AC24EB3-30B2-4C9B-8AA5-9918665AD451.html).

To add a VM class to a namespace,

1. Click **Add VM Class** for **VM Service.**

   ![Screenshot of VM Service window](img/tko-on-vsphere-with-tanzu/TKO-VWT45.png)

1. From the list of the VM Classes, select the classes that you want to include in your namespace.

   ![Screenshot of Add VM Class screen 1](img/tko-on-vsphere-with-tanzu/TKO-VWT46.png)

   ![Tanzu Kubernetes Grid Service** screen 2](img/tko-on-vsphere-with-tanzu/TKO-VWT47.png)

1. Click **Ok**.  

The namespace is fully configured now. You are ready to register your supervisor cluster with Tanzu Mission Control and deploy your first Tanzu Kubernetes Cluster.

## <a id=integrate-supervisor-tmc> </a> **Register Supervisor Cluster with Tanzu Mission Control**

Tanzu Mission Control is a centralized management platform for consistently operating and securing your Kubernetes infrastructure and modern applications across multiple teams and clouds.

By integrating Supervisor Cluster with Tanzu Mission Control (TMC) you are provided a centralized administrative interface that enables you to manage your global portfolio of Kubernetes clusters. It also allows you to deploy Tanzu Kubernetes clusters directly from Tanzu Mission Control portal and install user-managed packages leveraging the [TMC Catalog](https://docs.vmware.com/en/VMware-Tanzu-Mission-Control/services/tanzumc-using/GUID-EF35646D-8762-41F1-95E5-D2F35ED71BA1.html) feature.

> **Note** This section uses the terms **Supervisor Cluster** and **management cluster** interchangeably.

Ensure that the following are configured before you integrate Tanzu Kubernetes Grid with Tanzu Mission Control:

- A cluster group in Tanzu Mission Control.

- A workspace in the Tanzu Mission Control portal.

- Policies that are appropriate for your Tanzu Kubernetes Grid deployment.

- A provisioner. A provisioner helps you deploy Tanzu Kubernetes Grid clusters across multiple/different platforms, such as AWS and VMware vSphere.

Do the following to register the Supervisor cluster with Tanzu Mission Control:

1. Log in to Tanzu Mission Control console.
2. Go to **Administration > Management clusters > Register Management Cluster** tab and select vSphere with Tanzu.

   ![Screenshot of Tanzu Mission Control console](img/tko-on-vsphere-with-tanzu/TKO-VWT48.png)

3. On the Register management cluster page, provide a name for the management cluster, and choose a cluster group.

   You can optionally provide a description and labels for the management cluster.

   ![Screenshot of Register management cluster](img/tko-on-vsphere-with-tanzu/TKO-VWT49.png)

4. If you are using a proxy to connect to the Internet, you can configure the proxy settings by toggling the Set proxy option to yes.

   ![Screenshot of proxy settings](img/tko-on-vsphere-with-tanzu/TKO-VWT50.png)

5. On the Register page, Tanzu Mission Control generates a YAML file that defines how the management cluster connects to Tanzu Mission Control for registration. The credential provided in the YAML expires after 48 hours.

   Copy the URL provided on the Register page. This URL is needed to install the TMC agent on your management cluster and complete the registration process.

   ![Screenshot of Register screen](img/tko-on-vsphere-with-tanzu/TKO-VWT51.png)

6. Login to vSphere Client and select the cluster which is enabled for Workload Management and navigate to the **Workload Management > Supervisors > sfo01w01supervisor01 > Configure > Tanzu Mission Control** and enter the registration URL in the box provided and click **Register**.

   ![Screenshot of Tanzu Mission Control Registration screen](img/tko-on-vsphere-with-tanzu/TKO-VWT52.png)

   When the Supervisor Cluster is registered with Tanzu Mission Control, the TMC agent is installed in the svc-tmc-cXX namespace, which is included with the Supervisor Cluster by default.

   Once the TMC agent is installed on the Supervisor cluster and all pods are running in the svc-tmc-cXX namespace, the registration status shows “Installation successful”.

   ![Screenshot Tanzu Mission Control Registration success screen](img/tko-on-vsphere-with-tanzu/TKO-VWT55.png)

7. Return to the Tanzu Mission Control console and click **Verify Connection**.

   ![Screenshot of Tanzu Mission Control console](img/tko-on-vsphere-with-tanzu/TKO-VWT53.png)

8. Clicking **View Management Cluster** takes you to the overview page which displays the health of the cluster and its components.

   ![Screenshot of the component health screen](img/tko-on-vsphere-with-tanzu/TKO-VWT54.png)

   After installing the agent, you can use the Tanzu Mission Control web interface to provision and manage Tanzu Kubernetes clusters.

For additional product documentation, see [Integrate the Tanzu Kubernetes Grid Service on the Supervisor Cluster with Tanzu Mission Control](https://docs.vmware.com/en/VMware-vSphere/8.0/vsphere-with-tanzu-installation-configuration/GUID-ED4417DC-592C-454A-8292-97F93BD76957.html).

## <a id=deploy-workload-cluster> </a>Deploy Tanzu Kubernetes Clusters (Workload Cluster)

After Supervisor Cluster is registered with Tanzu Mission Control, deployment of the Tanzu Kubernetes clusters can be done in just a few clicks. The procedure for creating Tanzu Kubernetes clusters is shown below.

1. Go to the **Clusters** tab and click **Create Cluster**.

   ![Screenshot of Step 1: Creating a cluster](img/tko-on-vsphere-with-tanzu/TKO-VWT56.png)

2. On the **Create cluster** page, select the Supervisor cluster that you registered in the previous step and click on Continue to create cluster.

   ![Screenshot of Create cluster screen](img/tko-on-vsphere-with-tanzu/TKO-VWT57.png)

3. Select the provisioner for creating the workload cluster. Provisioner reflects the vSphere namespaces that you have created and associated with the Supervisor cluster.

   ![Screenshot of cluster provisioning screen](img/tko-on-vsphere-with-tanzu/TKO-VWT58.png)

4. Enter a name for the cluster. Cluster names must be unique within an organization.

5. Select the cluster group to which you want to attach your cluster and cluster class and click **next**. You can optionally enter a description and apply labels.

   ![Screenshot of Step 2: Name and Assign](img/tko-on-vsphere-with-tanzu/TKO-VWT59.png)
    > **Note** You cannot change the cluster class after the workload cluster created.
6. On next page, you can optionally specify a proxy configuration to use for this cluster.

   ![Screenshot of Step 2: Name and Assign](img/tko-on-vsphere-with-tanzu/TKO-VWT59-a.png)

   > **Note** This document doesn't cover the use of a proxy for vSphere with Tanzu. If your environment uses a proxy server to connect to the Internet, ensure the proxy configuration object includes the CIDRs for the pod, ingress, and egress from the workload network of the Supervisor Cluster in the **No proxy list**, as explained in [Create a Proxy Configuration Object for a Tanzu Kubernetes Grid Service Cluster Running in vSphere with Tanzu](https://docs.vmware.com/en/VMware-Tanzu-Mission-Control/services/tanzumc-using/GUID-B4760775-388A-45B5-A707-2191E9E4F41F.html#GUID-B4760775-388A-45B5-A707-2191E9E4F41F).
    
       
7. Configure the Cluster network setting

   - On the configure page, leave the default service domain.

   - You can optionally define an alternative CIDR for pod and service. The Pod CIDR and Service CIDR cannot be changed after the cluster is created.

   
   ![Screenshot of Step 3: Configure](img/tko-on-vsphere-with-tanzu/TKO-VWT60.png)

8. Select the control plane.

   - Select the Kubernetes version to use for the cluster. The latest supported version is preselected for you. You can choose the appropriate Kubernetes version by clicking on the down arrow button.

   - Select OS version.

   - Select the High Availability mode for the control plane nodes of the workload cluster. For a production deployment, it is recommended to deploy a highly available workload cluster.

   - Select the default storage class for the cluster. The list of storage classes that you can choose from is taken from your vSphere namespace.

   - You can optionally select a different instance type for the cluster's control plane node. Control plane endpoint and API server port options are not customizable here as they will be retrieved from the management cluster.

   ![Step 4: Select control plane](img/tko-on-vsphere-with-tanzu/TKO-VWT61.png)

9. Click **Next**.

10. Configure default volumes

   - Optionally add storage volumes for the control plane.

   - You can optionally add storage volumes for node pools.

      ![Step 4: Configure default volumes](img/tko-on-vsphere-with-tanzu/TKO-VWT61-a.png)
11. Configure node pool

   - Specify the number of worker nodes to provision.
   - Select the instance type.
   - Optionally select the instance type for worker nodes.
   - Optionally select the storage class.
   - OS version for worker nodes.

   - Click **Create Cluster** to start provisioning your workload cluster.

      ![Step 5: Configure node pool](img/tko-on-vsphere-with-tanzu/TKO-VWT62.png)
   - click **next**

12. Additional cluster configuration

      ![Step 5: Additional custer configuration](img/tko-on-vsphere-with-tanzu/TKO-VWT62-a.png)

Cluster creation approximately takes 15-20 minutes to complete. After the cluster deployment completes, ensure that Agent and extensions health shows green.

   ![Health screen for agent and extensions](img/tko-on-vsphere-with-tanzu/TKO-VWT63.png)

## <a id=integrate-to> </a> Integrate Tanzu Kubernetes clusters with Tanzu Observability

For instructions on enabling Tanzu Observability on your workload cluster, see [Set up Tanzu Observability to Monitor a Tanzu Kubernetes Cluster](./tko-saas-services.md#set-up-tanzu-observability-to-monitor-a-tanzu-kubernetes-clusters)

## <a id=integrate-tsm> </a> Integrate Tanzu Kubernetes Clusters with Tanzu Service Mesh

For instructions on installing Tanzu Service Mesh on your workload cluster, see [Onboard a Tanzu Kubernetes Cluster to Tanzu Service Mesh](./tko-saas-services.md#onboard-a-tanzu-kubernetes-cluster-to-tanzu-service-mesh)

## <a id=integrate-to> </a> Integrate Tanzu Kubernetes clusters with Tanzu Observability

For instructions on enabling Tanzu Observability on your workload cluster, please see [Set up Tanzu Observability to Monitor a Tanzu Kubernetes Clusters](./tko-saas-services.md#set-up-tanzu-observability-to-monitor-a-tanzu-kubernetes-clusters)

## <a id=deploy-user-managed-packages> </a> Deploy User-Managed Packages on Tanzu Kubernetes clusters

For instructions on how to install user-managed packages on the Tanzu Kubernetes clusters, see [Deploy User-Managed Packages in Workload Clusters](tkg-package-install.md).

## Self-Service Namespace in vSphere with Tanzu

Typically creating and configuring vSphere namespaces (permissions, limits, etc.) is a task performed by a vSphere Administrator. But this model doesn’t allow flexibility in a DevOps model. Every time a developer/cluster-admin needs a new namespace for deploying Kubernetes clusters, the task of creating a namespace has to be completed by the vSphere Administrator. Only after permissions, authentication, etc. are configured for the namespace can be consumed.

A self-service namespace is a new feature that is available with vSphere 7.0 U2 and later versions and allows users with DevOps persona to create and consume vSphere namespaces in a self-service fashion.

Before a DevOps user can start creating a namespace, the vSphere Administrator must enable Namespace service on the supervisor cluster; this will build a template that will be used over and over again whenever a developer requests a new Namespace.

The workflow for enabling Namespace service on the supervisor cluster is as follows:

1. Log in to the vSphere client and select the cluster configured for workload management.

2. Go to the **Workload Management> Supervisors > sfo01w01supervisor01 > General > Namespace Service** page and enable the Namespace Service using the toggle button and setting the status to **Active**.

   ![Screenshot of enabling Namespace Service](img/tko-on-vsphere-with-tanzu/TKO-VWT64.png)

3. Configure the quota for the CPU/Memory/Storage, storage policy for the namespace, Network, VM Classes and Content Library.

   ![Screenshot of Namespace Service configuration](img/tko-on-vsphere-with-tanzu/TKO-VWT65.png)

4. On the permissions page, select the identity source (AD, LDAP, etc) where you have created the users and groups for the Developer/Cluster Administrator. On selecting the identity source, you can search for the user/groups in that identity source.

   ![Screenshot of Permissions page](img/tko-on-vsphere-with-tanzu/TKO-VWT66.png)

5. Review the settings and click **Finish** to complete the namespace service enable wizard.

   ![Screenshot of Review and Confirm page](img/tko-on-vsphere-with-tanzu/TKO-VWT67.png)

   The Namespace Self-Service is now activated and ready to be consumed.

   ![Screenshot of Namespace Service activation confirmation](img/tko-on-vsphere-with-tanzu/TKO-VWT68.png)
