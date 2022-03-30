# Deploy Tanzu for Kubernetes Operations using vSphere with Tanzu

This document provides step-by-step instructions for installing and configuring Tanzu for Kubernetes Operations for vSphere with Tanzu in a vSphere environment backed by a Virtual Distributed Switch (VDS) and leveraging NSX Advanced Load Balancer for load balancing. 

The scope of the document is limited to providing deployment steps based on the reference design in [VMware Tanzu for Kubernetes Operations using vSphere with Tanzu](https://docs.vmware.com/en/VMware-Tanzu/services/tanzu-reference-architecture/GUID-reference-designs-index.html) and does not cover any deployment procedures for the underlying SDDC components.

# vSphere with Tanzu Bill Of Materials

Below is the validated Bill of Materials (latest) that can be used to install vSphere with Tanzu on your vSphere environment today.

|**Software Components**|**Version**|
| :- | :- |
|Tanzu Kubernetes Release|1.21.x|
|VMware vSphere ESXi|7.0 U3|
|VMware vCenter (VCSA)|7.0 U3|
|NSX Advanced Load Balancer|20.1.7|

The Interoperability Matrix can be verified at all times [here](https://interopmatrix.vmware.com/Interoperability?col=680,&row=1,%262,%26789,)

# Prepare the Environment for Deployment of the Tanzu Kubernetes Operations

Before deploying Tanzu Kubernetes Operations using vSphere with Tanzu on vSphere networking, ensure that your environment is set up as described in the following:

- [General Requirements](#genreq)
- [Network Requirements](#netreq)
- [Firewall Requirements](#fwreq)

### <a id=genreq> </a> **General Requirements**

The following are general requirements that your environment should have:

- vSphere 7.0 u3 instance with an Enterprise Plus license.
- Your vSphere environment has the following objects in place:
  - A vSphere cluster with at least 3 hosts, on which vSphere HA & DRS is enabled. If you are using vSAN for shared storage, it is recommended that you use 4 ESXi hosts.
  - A distributed switch with port groups for TKO components. Please refer to the [Network Requirements](#_heading=h.2et92p0) section for the required port groups. 
  - All ESXi hosts of the cluster on which vSphere with Tanzu will be enabled should be part of the distributed switch. 
  - Dedicated resource pools and VM folder for collecting NSX Advanced Load Balancer VMs.
  - A shared datastore with sufficient capacity for the control plane and worker node VM files.
- Network Time Protocol (NTP) service running on all hosts and vCenter.
- A user account with **Modify cluster-wide configuration** permissions. 
- NSX Advanced Load Balancer 20.1.7 ova downloaded from [customer connect](https://customerconnect.vmware.com/) portal and readily available for deployment.  

For additional information on general prerequisites, please refer to vSphere with Tanzu official [documentation](https://docs.vmware.com/en/VMware-vSphere/7.0/vmware-vsphere-with-tanzu/GUID-EE236215-DA4D-4579-8BEB-A693D1882C77.html)

### <a id=netreq> </a> **Network Requirements**

The following table provides example entries for the required port groups. Create network entries with the port group name, VLAN ID, and CIDRs that are specific to your environment. 


|**Network Type**|**DHCP Service**|**Description & Recommendations**|
| :- | :- | :- |
|NSX ALB Management Network|Optional|<p>NSX ALB controllers and SEs will be attached to this network. </p><p>Use static IPs for the NSX ALB controllers. </p><p>The Service Engine’s management network can obtain IP from DHCP. </p>|
|TKG Management Network|IP Pool/DHCP can be used. |<p>Supervisor Cluster nodes will be attached to this network.</p><p>When an IP Pool is used, ensure that the block has 5 consecutive free IPs.</p>|
|TKG Workload Network|IP Pool/DHCP can be used. |Control plane and worker nodes of TKG Workload Clusters will be attached to this network|
|TKG Cluster VIP/Data Network|No|<p>Virtual services for Control plane HA of all TKG clusters (Supervisor and Workload).</p><p>Reserve sufficient IPs depending on the number of TKG clusters planned to be deployed in the environment, NSX ALB handles IP address management on this network via IPAM.</p>|

For the purpose of demonstration, this document makes use of the following port groups, Subnet CIDR and VLANs. Please change the values as per your environment.


|**Port Group Name**|**VLAN**|**Gateway CIDR**|**DHCP Enabled**|**IP Pool for SE/VIP in NSX ALB**|
| :- | :- | :- | :- | :- |
|NSX-ALB-Mgmt|1980|172.19.80.1/27|No|172.19.80.11 - 172.19.80.30|
|TKG-Management|1981|172.16.81.1/27|Yes|No|
|TKG-Workload|1982|172.16.82.1/24|Yes|No|
|TKG-Cluster-VIP|1983|172.16.83.1/24|No|172.16.83.11 - 172.16.83.100|

### <a id=fwreq> </a> Firewall Requirements

Ensure that the firewall is set up as described in [Firewall Recommendations](https://docs.google.com/document/d/1W6gX7JP27WZ-RCL-eO-L1FZos-6Ns4L3wgJGxX1IiJU/edit#heading=h.uy7bv9mg12kp)

**Resource Pools**

Ensure that resource pools and folders are created in vCenter. The following table shows sample entries of the resource pools and folders. Customize the Resource Pool and Folder name for your environment.

|**Resource Type**|**Resource Pool name**|**Sample Folder name**|
| :- | :- | :- |
|NSX ALB Components|<p>NSX-ALB</p><p></p>|NSX-ALB-VMS|

## **[Deploy and Configure NSX Advanced Load Balancer](#deployalb)**

NSX ALB is an enterprise-grade integrated load balancer that provides L4- L7 Load Balancer support. It is recommended for vSphere deployments without NSX-T, or when there are unique scaling requirements.

NSX ALB is deployed in Write Access Mode mode in the vSphere Environment. This mode grants NSX ALB Controllers full write access to the vCenter which helps in automatically creating, modifying, and removing SEs and other resources as needed to adapt to changing traffic needs.

For a production-grade deployment, we recommend deploying three instances of the NSX ALB Controller for high availability and resiliency. To know more about how NSX ALB provides load balancing in a vSphere with Tanzu environment, please see the official [documentation](https://docs.vmware.com/en/VMware-vSphere/7.0/vmware-vsphere-with-tanzu/GUID-8908FAD7-9343-491B-9F6B-45FA8893C8CC.html)

The following table provides a sample IP and FQDN used for the NSX ALB controllers deployment:

|**Controller Node**|**IP Address**|**FQDN**|
| :- | :- | :- |
|Node01 (Primary)|<p>172.19.80.3</p><p></p>|alb-01.tanzu.lab|
|Node02 (Secondary)|<p>172.19.80.4</p><p></p>|alb02.tanzu.lab|
|Node03 (Secondary)|<p>172.19.80.5</p><p></p>|alb03.tanzu.lab|
|Controller Cluster|<p>172.19.80.2</p><p></p>|alb.tanzu.lab|

To deploy NSX ALB controller nodes:

1. Log in to the vCenter Server by using the vSphere Client.
1. Select the cluster where you want to deploy the NSX ALB controller node.
1. Right-click on the cluster and invoke the **Deploy OVF Template** wizard. 
1. Follow the wizard to configure the following:
   - VM Name and Folder Location.
   - Select the **NSX-ALB** resource pool as a compute resource.
   - Select the datastore for the controller node deployment.
   - Select the **NSX-ALB-Mgmt** port group for the Management Network.
   - Customize the configuration by providing Management Interface IP Address, Subnet Mask, and Default Gateway. The rest of the fields are optional and can be left blank.

The below screenshot is provided for reference only and shows the final configuration of the NSX ALB Controller node.

![](img/tko-on-vsphere-with-tanzu/TKO-VWT01.png)

Once the controller VM is deployed and powered-on, perform the post-deployment  configuration of the controller node by connecting to URL *https://<alb-ctlr01.tanzu.lab>/*

Configure the controller node for your vSphere with Tanzu environment as follows:

- Configure the administrator account by setting up password and email (optional).

![](img/tko-on-vsphere-with-tanzu/TKO-VWT02.png)

- Configure System Settings by specifying the backup passphrase and DNS information.

![](img/tko-on-vsphere-with-tanzu/TKO-VWT03.png)

- (Optional) Configure **Email/SMTP**

![](img/tko-on-vsphere-with-tanzu/TKO-VWT04.png)

- Configure Multi-Tenant settings as follows:
    - **IP Route Domain:** Share IP route domain across tenants.
    - **Service Engine Context:** Service Engines are managed within the tenant context, not shared across tenants.

![](img/tko-on-vsphere-with-tanzu/TKO-VWT05.png)

Click on the Save button to finish the post-deployment configuration wizard. 

If you did not select the Setup Cloud After option before saving, the initial configuration wizard exits. The Cloud configuration window does not automatically launch and you are directed to a Dashboard view on the controller.

### Configure Default-Cloud

To configure the Default-Cloud, navigate to the **Infrastructure > Clouds** and edit the **Default-Cloud**

![](img/tko-on-vsphere-with-tanzu/TKO-VWT06.png)

Select VMware vCenter/vSphere ESX as the infrastructure type and click on Next.

![](img/tko-on-vsphere-with-tanzu/TKO-VWT07.png)

Under the Infrastructure tab, configure the following:

- vCenter Address: vCenter IP address or fqdn.
- vCenter Credentials: Username/password of the vCenter account to use for NSX ALB integration.
- Access Permission: Write

![](img/tko-on-vsphere-with-tanzu/TKO-VWT08.png)

Configure the Data Center settings.

1. Select the vSphere Data Center where you want to enable Workload Management.
1. Select the Default Network IP Address Management mode.
   - Select DHCP Enabled if DHCP is available on the vSphere port groups.
   - Leave the option unselected if you want the Service Engine interfaces to use only static IP addresses. You can configure them individually for each network.
1. Unselect **Prefer Static Routes vs Directly Connected Network** for Virtual Service Placement.

![](img/tko-on-vsphere-with-tanzu/TKO-VWT09.png)

Configure the Network settings as follows:

1. Select the NSX ALB Management Network - This network interface is used by the Service Engines to connect with the Controller.
1. Leave the Template Service Engine Group empty.
1. Management Network IP Address Management:
- Select DHCP if DHCP is available on the vSphere port groups. 
- If DHCP is not available, Enter the IP subnet, IP address range, Default Gateway for the Management Network.

![](img/tko-on-vsphere-with-tanzu/TKO-VWT10.png)

Ensure that the health of the Default-Cloud is green post configuration.

![](img/tko-on-vsphere-with-tanzu/TKO-VWT11.png)

### Configure Licensing

TKO includes NSX ALB Enterprise license. To configure licensing, navigate to the Administration > Settings > Licensing and apply the license key. If you have a license file instead of a license key, apply the license by clicking on the Upload from computer option. 

![](img/tko-on-vsphere-with-tanzu/TKO-VWT12.png)

![](img/tko-on-vsphere-with-tanzu/TKO-VWT13.png)

### Configure NTP Settings

Configure NTP settings if you want to use an internal NTP server.

![](img/tko-on-vsphere-with-tanzu/TKO-VWT14.png)

Edit the settings using the pencil icon to specify the NTP server that you want to use and save the settings.

![](img/tko-on-vsphere-with-tanzu/TKO-VWT15.png)

### Deploy NSX ALB Controller Cluster

In a production environment, it is recommended to deploy additional controller nodes and configure the controller cluster for high availability and disaster recovery. 

To run a 3 node controller cluster, you deploy the first node and perform the initial configuration, and set the Cluster IP. After that, you deploy and power on two more Controller VMs, but you must not run the initial configuration wizard or change the admin password for these controllers VMs. The configuration of the first controller VM is assigned to the two new Controller VMs.

To configure the Controller Cluster, navigate to the **Administration > Controller > Nodes** page and click on the edit button.

![](img/tko-on-vsphere-with-tanzu/TKO-VWT16.png)

Specify the name for the controller cluster and set the Cluster IP. This IP address should be from the NSX ALB management network. 

Under Cluster Nodes, specify the IP addresses of the 2 additional controllers that you have deployed and click on the Save button. Leave the name and password fields empty.

![](img/tko-on-vsphere-with-tanzu/TKO-VWT17.png)

After hitting the save button, the controller cluster setup kicks in, and the controller nodes are rebooted in the process. It takes approximately 10-15 minutes for cluster formation to complete.

You will be automatically logged out of the controller node where you are currently logged in. On entering the cluster IP in the browser, you can see details about the cluster formation task.

![](img/tko-on-vsphere-with-tanzu/TKO-VWT18.png)

The first controller of the cluster receives the "Leader" role. The second and third controllers will work as "Follower". 

![](img/tko-on-vsphere-with-tanzu/TKO-VWT19.png)

Please note that once the controller cluster is deployed, you must use the controller cluster IP for any further configuration and not the individual controller node IP.

### Change NSX ALB Portal Certificate

The Controller must send a certificate to clients to establish secure communication. This certificate must have a Subject Alternative Name (SAN) that matches the NSX ALB Controller cluster hostname or IP address.

The Controller has a default self-signed certificate. But this certificate does not have the correct SAN. You must replace it with a valid or self-signed certificate that has the correct SAN. You can create a self-signed certificate or upload a CA-signed certificate. 

For the purpose of the demonstration, this document makes use of a self-signed certificate. 

To replace the default certificate, navigate to the **Templates > Security > SSL/TLS Certificate > Create** and select Controller Certificate.

![](img/tko-on-vsphere-with-tanzu/TKO-VWT20.png)

In the New Certificate (SSL/TLS) window, select Type as Self Signed and enter a name for the certificate.

Enter the following details:

- **Common Name** - Specify the fully-qualified name of the site. For the site to be considered trusted, this entry must match the hostname that the client entered in the browser.
- **Subject Alternate Name (SAN)** - Enter the cluster IP and node address or FQDN of the Controller cluster and individual controller nodes.
- **Algorithm** - Select either EC or RSA. 
- Key Size

Click on the Save button to save the certificate.

![](img/tko-on-vsphere-with-tanzu/TKO-VWT21.png)

To change the NSX ALB portal certificate, navigate to the **Administration > Settings > Access Settings** page and edit the System Access Settings by clicking on the pencil icon.

From SSL/TLS Certificate, remove the existing default certificates and from the drop-down menu, select the newly created certificate and click on the Save button.

![](img/tko-on-vsphere-with-tanzu/TKO-VWT22.png)

**Export NSX ALB certificate**

You need the newly created certificate when you configure the Supervisor Cluster to enable the Workload Management functionality.

To export the certificate, navigate to the **Templates > Security > SSL/TLS Certificate** page and export the certificate by clicking on the export button.

In the Export Certificate page that appears, click Copy to clipboard against the certificate. Do not copy the key. Save the copied certificate for later use when you enable workload management.

### Configure a Service Engine Group

vSphere with Tanzu uses the Default Service Engine Group. Ensure that the HA mode for the default-Group is set to N + M (buffer). 

Optionally, you can reconfigure the **Default-Group** to define the placement and number of Service Engine VMs settings. 

This document demonstrates the use of Default Service Engine Group as is.

**Configure a Virtual IP Network**

Configure a virtual IP (VIP) subnet for the Data Network. You can configure the VIP range to use when a virtual service is placed on the specific VIP network. You can configure DCHP for the Service Engines. 

Optionally, if DHCP is unavailable, you can configure a pool of IP addresses that will get assigned to the Service Engine interface on that network. 

This document demonstrates the use of an IP pool for the VIP network.

To configure the VIP Network, navigate to the **Infrastructure > Networks** page and locate the Network that provides the virtual IP addresses and click the edit icon to edit the network settings.

Click on the **Add Subnet** button to specify the VIP Network subnet CIDR. 

Also, specify the IP address pool for the VIPs and SE by clicking on the  **Add Static IP Address Pool** button. The range must be a subset of the network CIDR in IP Subnet.

Click on the Save button to close the VIP Network configuration wizard.

![](img/tko-on-vsphere-with-tanzu/TKO-VWT23.png)


**Configure Default Gateway**

A default gateway enables the Service Engine to route traffic to the pool servers on the Workload Network. You must configure the VIP Network gateway IP as the default gateway.

To configure the Default gateway, navigate to the **Infrastructure > Routing > Static Route** page and click on the Create button.

![](img/tko-on-vsphere-with-tanzu/TKO-VWT24.png)

In Gateway Subnet, enter 0.0.0.0/0 and point the Next Hop to the gateway IP address of the VIP network.

Click on the Save button to complete the Default Gateway creation wizard. 

![](img/tko-on-vsphere-with-tanzu/TKO-VWT25.png)

**Configuring IPAM**

IPAM is required to allocate virtual IP addresses when virtual services get created. Configure IPAM for the NSX ALB Controller and assign it to the Default-Cloud.

To create an IPAM profile, navigate to the **Templates > Profiles > IPAM/DNS Profiles** page and click on the **Create** button, and select IPAM Profile. 

![](img/tko-on-vsphere-with-tanzu/TKO-VWT26.png)

- Provide a name for the IPAM Profile and select type as AVI Vantage IPAM. 
- Deselect Allocate IP in VRF option.
- Click Add Usable Network and select the Default-Cloud and choose the VIP Network that you have created in the previous step. 

Click on the Save button to finish the IPAM creation wizard.

![](img/tko-on-vsphere-with-tanzu/TKO-VWT27.png)

To assign the IPAM profile to the Default-Cloud, navigate to the Infrastructure > Cloud page and edit the Default-Cloud configuration.

Under IPAM Profile, select the newly created profile and save the settings. 

![](img/tko-on-vsphere-with-tanzu/TKO-VWT28.png)

Verify that the status of the Default-Cloud is green after configuring the IPAM Profile.

## **Deploy Tanzu Kubernetes Grid Supervisor Cluster**

As a vSphere Administrator, you enable a vSphere cluster for Workload Management by creating a Supervisor Cluster. After you deploy the Supervisor Cluster, you can use the vSphere Client to manage and monitor the cluster.

Before deploying the Supervisor cluster, ensure that the following pre-requisites have been met: 

- You have created a vSphere cluster with at least three ESXi hosts. If you are using vSAN you need a minimum of four ESXi hosts. 

- The vsphere cluster is configured with shared storage such as vSAN. 

- The vSphere Cluster has HA & DRS enabled and DRS is configured in the fully-automated mode.

- The required port groups have been created on the distributed switch to provide networking to the Supervisor & Workload clusters. 

- Your vSphere Cluster is licensed for Supervisor cluster deployment. 

- You have created a [Subscribed Content Library](https://docs.vmware.com/en/VMware-vSphere/7.0/vmware-vsphere-with-tanzu/GUID-209AAB32-B2ED-4CDF-AE62-B0FAD9D34C2F.html) to automatically pull the latest Tanzu Kubernetes releases from the VMware repository.

- You have created a [storage policy](https://docs.vmware.com/en/VMware-vSphere/7.0/vmware-vsphere-with-tanzu/GUID-544286A2-A403-4CA5-9C73-8EFF261545E7.html#GUID-544286A2-A403-4CA5-9C73-8EFF261545E7) that will determine the datastore placement of the Kubernetes control plane VMs, containers, and images.

- A user account with **Modify cluster-wide configuration** permissions. 

- NSX Advanced Load Balancer is deployed and configured as per instructions provided earlier. 

To deploy the Supervisor Cluster, login to the vSphere Client and navigate to **Menu > Workload Management,** and click on the Get Started page.

![](img/tko-on-vsphere-with-tanzu/TKO-VWT29.png)

Select the vCenter Server and choose vSphere Distributed Switch for the networking stack and click Next.

![](img/tko-on-vsphere-with-tanzu/TKO-VWT30.png)

Select a cluster from the list of compatible clusters and click Next.

![](img/tko-on-vsphere-with-tanzu/TKO-VWT31.png)

Select the Storage Policy for the Control Plane nodes from the drop-down menu and click Next.

![](img/tko-on-vsphere-with-tanzu/TKO-VWT32.png)

On the Load Balancer screen, select type as NSX Advanced Load Balancer and provide the following details:

- **Name:** Friendly name for the load balancer. Only small letters are supported in the name field.

- **NSX ALB Controller IP:** If the NSX ALB self-signed certificate is configured with the hostname in the SAN field, use the same hostname here. If the SAN is configured with an IP address, provide the Controller cluster IP address. The default port of NSX ALB is 443. 

- **NSX ALB Credentials:** Provide the NSX ALB admin credentials.

- **Server Certificate:** Use the content of the Controller certificate that you exported earlier while configuring certificates for the Controller. 

![](img/tko-on-vsphere-with-tanzu/TKO-VWT33.png)

For configuring Management Network for the Supervisor cluster, select the port group that you have created on the distributed switch. If DHCP is enabled for the port group, set the Network Mode to DHCP. 

Ensure that the DHCP Server is configured to hand over DNS server address, DNS search domain, and NTP server address via DHCP. 

![](img/tko-on-vsphere-with-tanzu/TKO-VWT34.png)

In the Workload Network page, select the network that will handle the networking traffic for Kubernetes workloads running on the Supervisor Cluster and set the IP mode to DHCP if the port group is configured for DHCP. 

![](img/tko-on-vsphere-with-tanzu/TKO-VWT35.png)

On the Tanzu Kubernetes Grid Service page, select the Subscribed Content Library which is hosting the VMware released Kubernetes images. 

![](img/tko-on-vsphere-with-tanzu/TKO-VWT36.png)

On the Review and Confirm page, select the size for the Kubernetes control plane VMs that will be created on each host from the cluster. For production deployments, a large form factor is recommended. 

Clicking on the finish button will trigger the Supervisor Cluster deployment. 

![](img/tko-on-vsphere-with-tanzu/TKO-VWT37.png)

Workload Management task roughly takes 30 minutes to complete. Once the task completes, three Kubernetes control plane VMs are created on the hosts that are part of the vSphere cluster.

The Supervisor Cluster gets an IP address from the VIP network that you have configured in the NSX ALB. This IP is also called Control Plane HA IP.

![](img/tko-on-vsphere-with-tanzu/TKO-VWT38.png)

In the backend, 3 supervisor Control Plane VMs are deployed in the vSphere namespace. A Virtual Service is created in the NSX ALB with 3 Supervisor Control Plane nodes that are deployed in the process. 

**Connecting to Supervisor Clusters**

You can use Kubernetes CLI Tools for vSphere to view and control vSphere with Tanzu namespaces and clusters.

The Kubernetes CLI Tools download package includes two executables: the standard open-source kubectl and the vSphere Plugin for kubectl. The vSphere Plugin for kubectl extends the commands available to kubectl so that you connect to the Supervisor Cluster and to Tanzu Kubernetes clusters using vCenter Single Sign-On credentials.

To download the Kubernetes CLI tool, connect to the URL https://<control-plane-vip>/

Download the CLI tool for the operating system of your choice.

![](img/tko-on-vsphere-with-tanzu/TKO-VWT38-1.png)

Once you have installed the CLI tool of your choice, connect to the supervisor Cluster by running the below command: 

<!-- /* cSpell:disable */ -->
```
kubectl vsphere login --vsphere-username=administrator@vsphere.local --server=<control-plane-vip>
```
<!-- /* cSpell:enable */ -->

The command prompts for the vSphere Administrator password. 

After your connection to the Supervisor Cluster is established you can switch to the Supervisor context by running the command: 

<!-- /* cSpell:disable */ -->
```
kubectl config use-context <supervisor-context-name>
```
<!-- /* cSpell:enable */ -->

Please note that the supervisor context name is the IP address of the control plane VIP.

## **Create and Configure Namespace**

A vSphere Namespace is a tenancy boundary within vSphere with Tanzu and allows for sharing vSphere resources (computer, networking, storage) and enforcing resources limits with the underlying objects such as Tanzu Kubernetes Clusters. It also allows you to attach policies and permissions.

Every Tanzu Kubernetes cluster that you deploy runs in a supervisor namespace. To learn more about namespaces, please refer to the vSphere with Tanzu [documentation](https://docs.vmware.com/en/VMware-vSphere/7.0/vmware-vsphere-with-tanzu/GUID-1544C9FE-0B23-434E-B823-C59EFC2F7309.html)

To create a new supervisor namespace, login to vSphere Client and navigate to **Home > Workload Management > Namespaces**, and click on the Create Namespace button.

![](img/tko-on-vsphere-with-tanzu/TKO-VWT39.png)

Select the vSphere Cluster that is enabled for the Workload Management. 

Enter a name for the namespace and select the workload network for the namespace.

**Note:** Namespace's name accepts only small letters and hyphens. 

Click on the create button to finish the create namespace wizard.

![](img/tko-on-vsphere-with-tanzu/TKO-VWT40.png)

The namespace is created on the Supervisor Cluster.

**Configure Permissions for the Namespace**

To access a namespace, you have to add permissions to it. To configure permissions, click on the newly created namespace and navigate to the summary tab and click on Add Permissions button. 

![](img/tko-on-vsphere-with-tanzu/TKO-VWT41.png)

Choose the identity source and look for the User/Group that will have access to the namespace, then define the role for the selected User/Group.

![](img/tko-on-vsphere-with-tanzu/TKO-VWT42.png)


**Set Persistent Storage to the Namespace**

Certain Kubernetes workloads require persistent storage to store data permanently. Storage policies that you assign to the namespace control how persistent volumes and Tanzu Kubernetes cluster nodes are placed within datastores in the vSphere storage environment. 

To assign a storage policy to the namespace, click on the **Add Storage** button in the storage button. 

A list of storage policies will be displayed; choose the appropriate storage policy and click OK.

![](img/tko-on-vsphere-with-tanzu/TKO-VWT43.png)

After the storage policy is assigned to a namespace, vSphere with Tanzu creates a matching Kubernetes storage class in the vSphere Namespace.

**Specify Namespace Capacity Limits**

When initially created, the namespace has unlimited resources within the Supervisor Cluster. vSphere administrator defines the limits for CPU, memory, storage, as well as the number of Kubernetes objects that can run within the namespace. These limits are configured per vSphere Namespace.

Select **Edit Limits** from the Capacity and Usage pane to configure resource limitations for the namespace.

![](img/tko-on-vsphere-with-tanzu/TKO-VWT44.png)

The storage limitation determines the overall amount of storage that is available to the namespace.

**Associate VM Class with Namespace**

The VM class is a VM specification that can be used to request a set of resources for a VM. The VM class defines parameters such as the number of virtual CPUs, memory capacity, and reservation settings. 

vSphere with Tanzu includes several default VM classes and each class has two editions: **guaranteed and best effort**. A guaranteed edition fully reserves the resources that a VM specification requests. A best-effort class edition does not and allows resources to be overcommitted.

More than one VM Class can be associated with a namespace. To learn more about VM classes, please refer to the vSphere with Tanzu [documentation](https://docs.vmware.com/en/VMware-vSphere/7.0/vmware-vsphere-with-tanzu/GUID-7351EEFF-4EF0-468F-A19B-6CEA40983D3D.html)

To add a VM class to a namespace, click on the Add VM Class under the VM Service pane. 

![](img/tko-on-vsphere-with-tanzu/TKO-VWT45.png)

From the list of the VM Classes, select the classes that you want to include in your namespace and click on ok. If you want to include all VM Classes, go to the next page in the UI and select all classes. 

![](img/tko-on-vsphere-with-tanzu/TKO-VWT46.png)

![](img/tko-on-vsphere-with-tanzu/TKO-VWT47.png)

The namespace is fully configured now. You are ready to deploy your first Tanzu Kubernetes Cluster.

## **Register Supervisor Cluster with Tanzu Mission Control**

Tanzu Mission Control is a centralized management platform for consistently operating and securing your Kubernetes infrastructure and modern applications across multiple teams and clouds. 

By integrating Supervisor Cluster with Tanzu Mission Control (TMC) you are provided a centralized administrative interface that enables you to manage your global portfolio of Kubernetes clusters. It also allows you to deploy Tanzu Kubernetes clusters directly from Tanzu Mission Control portal and install user-managed packages leveraging the [TMC Catalog](https://docs.vmware.com/en/VMware-Tanzu-Mission-Control/services/tanzumc-using/GUID-EF35646D-8762-41F1-95E5-D2F35ED71BA1.html) feature. 

Please follow the steps below to register the supervisor cluster with Tanzu Mission Control.

Please note that this section uses Supervisor Cluster and management cluster terms interchangeably.

**Prerequisites**

There are a few items that need to be configured in advance before attempting to integrate Tanzu Kubernetes grid clusters with TMC. 

- A cluster group is created in TMC. 

- A workspace has been created in the TMC portal.

- You must create the policies that are appropriate for your TKG deployment. 

- Create a provisioner. A provisioner helps you to deploy TKG clusters across multiple/different platforms, such as AWS, VMware vSphere, etc. 

1: Login to Tanzu Mission Control console and navigate to **Administration > Management clusters > Register Management Cluster** tab and select vSphere with Tanzu.

![](img/tko-on-vsphere-with-tanzu/TKO-VWT48.png)

2: On the Register management cluster page, provide a name for the management cluster, and choose a cluster group.

You can optionally provide a description and labels for the management cluster.

![](img/tko-on-vsphere-with-tanzu/TKO-VWT49.png)

3: If you are using a proxy to connect to the internet, you can configure the proxy settings by toggling the Set proxy option to yes. 

![](img/tko-on-vsphere-with-tanzu/TKO-VWT50.png)

4: On the Register page, Tanzu Mission Control generates a YAML file that defines how the management cluster connects to Tanzu Mission Control for registration. The credential provided in the YAML expires after 48 hours.

Copy the URL provided on the Register page. This URL is needed to install the TMC agent on your management cluster and complete the registration process.

![](img/tko-on-vsphere-with-tanzu/TKO-VWT51.png)

5: Login to vSphere Client and select the Cluster which is enabled for Workload Management and navigate to the **Configure > TKG Service > Tanzu Mission Control** tab and enter the registration URL in the box provided and click on the Register button.

![](img/tko-on-vsphere-with-tanzu/TKO-VWT52.png)

When the Supervisor Cluster is registered with Tanzu Mission Control, the TMC agent is installed in the svc-tmc-cXX namespace, which is included with the Supervisor Cluster by default. 

Once the tmc agent is installed on the Supervisor cluster and all pods are running in the svc-tmc-cXX namespace, the registration status shows “Installation successful”.

![](img/tko-on-vsphere-with-tanzu/TKO-VWT55.png)

6: Return to the Tanzu Mission Control console and click on the Verify Connection button.

![](img/tko-on-vsphere-with-tanzu/TKO-VWT53.png)

8: Clicking on the View Management Cluster button, takes you to the overview page which displays the health of the cluster and its components. 

![](img/tko-on-vsphere-with-tanzu/TKO-VWT54.png)

After installing the agent, you can use the Tanzu Mission Control web interface to provision and manage Tanzu Kubernetes clusters.

## **Deploy Tanzu Kubernetes Clusters (Workload Cluster)**

After Supervisor Cluster is registered with Tanzu Mission Control, deployment of the Tanzu Kubernetes clusters can be done in just a few clicks. The procedure for creating Tanzu Kubernetes clusters is shown below.

Step 1: Navigate to the Clusters tab and click on the Create Cluster button.

![](img/tko-on-vsphere-with-tanzu/TKO-VWT56.png)

Under the create cluster page, select the Supervisor cluster which you registered in the previous step and click on the continue to create cluster button.

![](img/tko-on-vsphere-with-tanzu/TKO-VWT57.png)

Step 2: Select the provisioner for creating the workload cluster. Provisioner reflects the vSphere namespaces that you have created and associated with the Supervisor cluster.

![](img/tko-on-vsphere-with-tanzu/TKO-VWT58.png)

Step 3: Enter a name for the cluster. Cluster names must be unique within an organization.

Select the cluster group to which you want to attach your cluster. You can optionally enter a description and apply labels.

![](img/tko-on-vsphere-with-tanzu/TKO-VWT59.png)

Step 4: On the configure page, specify the following:

- Select the Kubernetes version to use for the cluster. The latest supported version is preselected for you. You can choose the appropriate Kubernetes version by clicking on the down arrow button. 

- You can optionally define an alternative CIDR for the pod and service. The Pod CIDR and Service CIDR cannot be changed after the cluster is created. 

- You can optionally specify a proxy configuration to use for this cluster.

- You can optionally select the default storage class for the cluster and allowed storage classes. The list of storage classes that you can choose from is taken from your vSphere namespace.

Please note that the scope of this document doesn't cover the use of a proxy for vSphere with Tanzu. If your environment uses a proxy server to connect to the internet, please ensure the proxy configuration object includes the CIDRs for the pod, ingress, and egress from the workload network of the Supervisor Cluster in the **No proxy list**, as described [here](https://docs.vmware.com/en/VMware-Tanzu-Mission-Control/services/tanzumc-using/GUID-B4760775-388A-45B5-A707-2191E9E4F41F.html#GUID-B4760775-388A-45B5-A707-2191E9E4F41F)

![](img/tko-on-vsphere-with-tanzu/TKO-VWT60.png)

Step 5: Select the High Availability mode for the control plane nodes of the workload cluster. For a production deployment, it is recommended to deploy a highly available workload cluster. 

You can optionally select a different instance type for the cluster's control plane node and its storage class. Control plane endpoint and API server port options are not customizable here as they will be retrieved from the management cluster. 

![](img/tko-on-vsphere-with-tanzu/TKO-VWT61.png)

Step 6: You can optionally define the default node pool for your workload cluster.

- Specify the number of worker nodes to provision.
- Select the instance type.

Click on the Create Cluster button to start provisioning your workload cluster. 

![](img/tko-on-vsphere-with-tanzu/TKO-VWT62.png)

Cluster creation roughly takes 15-20 minutes to complete. After the cluster deployment completes, ensure that Agent and extensions health shows green.

![](img/tko-on-vsphere-with-tanzu/TKO-VWT63.png)

## **Integrate Workload clusters with Tanzu Observability**

Tanzu Observability delivers full-stack observability across containerized cloud applications, Kubernetes health, and cloud infrastructure. The solution is consumed through a Software-as-a-Service (SaaS) subscription model, managed by VMware. This SaaS model allows the solution to scale to meet metrics requirements without the need for customers to maintain the solution itself.

Please follow the instructions provided in the [Tanzu SaaS Services](./tko-saas-services-2.0.md#set-up-tanzu-observability-to-monitor-a-tanzu-kubernetes-clusters) page to enable Tanzu Observability on the Workload cluster. 

## **Integrate Tanzu Kubernetes clusters with Tanzu Service Mesh**

Please follow the instructions provided in the [Tanzu SaaS Services](./tko-saas-services-2.0.md#tanzu-service-mesh) page to enable Tanzu Service Mesh on the Workload cluster.

## **Appendix A**

### **Self-Service Namespace in vSphere with Tanzu**

Typically creating and configuring vSphere namespaces (permissions, limits, etc) is a vSphere Administrator task. But this model doesn’t allow flexibility in a DevOps model. Every time a developer/cluster-admin needs a new namespace for deploying Kubernetes clusters, the task of creating a namespace has to be completed by the vSphere Administrator, and once permissions, authentication, etc are configured for the namespace, then only it can be consumed. 

A self-Service namespace is a new feature that is available with vSphere 7.0 U2 and later versions and allows users with DevOps persona to create and consume vSphere namespaces in a self-service fashion.

But before a DevOps user can start creating namespace on his own, the vSphere Administrator has to enable Namespace service on the supervisor cluster; this will build a template that will be used over and over again whenever a developer requests a new Namespace.

The below steps demonstrate the workflow for enabling Namespace service on the supervisor cluster.

1: Login to the vSphere client and select the cluster configured for workload management.

Navigate to the **Configure > Supervisor Cluster > General** page and enable the Namespace Service using the toggle button and setting the status to Active. 

![](img/tko-on-vsphere-with-tanzu/TKO-VWT64.png)

2: Configure the quota for the CPU/Memory/Storage and select the storage policy for the namespace.

![](img/tko-on-vsphere-with-tanzu/TKO-VWT65.png)

3: On the permissions page, select the identity source (AD, LDAP, etc) where you have created the users and groups for the Developer/Cluster Administrator. On selecting the identity source, you can search for the user/groups in that identity source. 

![](img/tko-on-vsphere-with-tanzu/TKO-VWT66.png)

4: Review the settings and click on the finish button to complete the namespace service enable wizard. 

![](img/tko-on-vsphere-with-tanzu/TKO-VWT67.png)

The Namespace Self-Service is now activated and ready to be consumed. 

![](img/tko-on-vsphere-with-tanzu/TKO-VWT68.png)