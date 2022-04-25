# Deploy Tanzu for Kubernetes Operations on VMware Cloud on AWS
This document provides step-by-step instructions for deploying Tanzu Kubernetes Operations on VMware Cloud on AWS.

The scope of the document is limited to providing the deployment steps based on the reference design in [VMware Tanzu Standard on VMware Cloud on AWS Reference Design](../reference-designs/tko-on-vmc-aws.md)

## Prerequisites
The instructions provided in this document assumes that you have the following setup:

* VMware Cloud subscription
* SDDC deployment
* Access to vCenter over HTTPs
* NTP configured on all ESXi hosts and vCenter server

## Overview
The following are the high-level steps for deploying Tanzu Standard on VMware Cloud on AWS:

1. [Create and Configure Network Segment](#create-config-network-segment).
2. [Create Inventory Groups and Firewall Configuration](#inventory_groups_firewall).
3. [Request Public IP for Tanzu Kubernetes Nodes](#request_IP).
4. [Configure Resource pools and VM Folders in vCenter](#config-resource-pool).
5. [Deploy and Configure NSX Advanced Load Balancer](#dep-config-nsxalb).
6. [Configure Bootstrap Environment](#config-bootstrap).
7. [Deploy Management Cluster](#deploy-mgmt-cluster).
8. [Set up a Shared Services Workload Cluster](#set-up-shared-cluster).

## <a id="create-config-network-segment"></a> Create and Configure Network Segment

1. In the VMware Cloud Console, open the SDDC pane and click **Networking & Security** > **Network** > **Segments**.

1. Click **Add Segment** to create a new network segment with a unique subnet for Tanzu Kubernetes Grid management network.

	- For this deployment, we will create a new segment for each one of the following:  management cluster, workload cluster, and NSX Advanced Load Balancer.
	- Ensure that the new subnet CIDR does not overlap with `sddc-cgw-network-1` or any other existing segments.
	- The bootstrap VM and the Tanzu Kubernetes Grid Management cluster nodes will be attached to this segment.
	- For network isolation, we recommend creating new segments for each workload cluster.

		<!-- /* cSpell:disable */ -->

		**Configuration for TKG Management Cluster** | **Values**
		-----|-----
		Type|Routed
		Segment-name|m01tkg01-seg01
		Network/Subnets|172.17.10.0/24

		**Configuration for TKG Workload Cluster**| **Values**
		-----|-----
		Segment-name|w01tkg01-seg01
		Type|Routed
		Network/Subnets|172.17.11.0/24

		**Configuration for NSX ALB Management Network**| **Values**
		-----|-----
		Segment-name|m01avimgmt-seg01
		Type|Routed
		Network/Subnets|172.17.11.0/24
		<!-- /* cSpell:enable */ -->

1. For the management and workload cluster segments, click **Edit DHCP Config**.  A **Set DHCP Config** pane appears.

1. In the **Set DHCP Config** pane:

   - Set **DHCP Config** to **Enabled**.
   - Set **DHCP Ranges** to an IP address range or CIDR within the segment's subnet, which leaves a pool of addresses free to serve as static IP addresses for Tanzu Kubernetes clusters.
   Each management cluster and workload cluster that Tanzu Kubernetes Grid creates will require a unique static IP address from this pool.

   For this deployment set the DHCP Range as 172.17.10.2 - 172.17.10.33. The available static IPs will be in the range of 172.17.10.34 - 172.17.10.254. We will use the first IP 172.17.10.34 for Cluster IP addressing and the rest for the NSX Advanced Load Balancer VIP network.

   - Set the DNS Server details. For this deployment, set 8.8.8.8.

   The following show the DHCP configuration for a management and a workload cluster.
   ![](img/tanzu-standard-on-vmc-aws/vmcAwsDHCPconfigMcluster.png)
   ![](img/tanzu-standard-on-vmc-aws/vmcAwsDHCPconfigWcluster.png)


## <a id="inventory_groups_firewall"> </a> Create Inventory Groups and Firewall Configuration
Set up the following firewall rules. You will first create management and compute inventory groups. Then, you will configure the firewall rules for the inventory groups.

<!-- /* cSpell:disable */ -->

**Source**| **Destination**| **Protocol and Port**| **Description**| **Configured on**
-----|-----|-----|-----|-----
TKG Management and Workload Network|DNS Server|UDP:53|Name Resolution|Compute Gateway
TKG Management and Workload Network|NTP Server|UDP:123|Time Synchronization|Compute Gateway
TKG Management and Workload Network|vCenter Server|TCP:443|To access vCenter create VMs and Storage Volumes|Compute and Management Gateway
TKG Management and Workload Network|Internet|TCP:443|Allow components to retrieve container images required for cluster building from repos listed under ~/.tanzu/tkg/bom/|Compute Gateway
TKG Management Cluster Network|TKG Workload Cluster HAProxy|TCP:6443, 5556|Allow management cluster to configure workload cluster|Compute Gateway
TKGWorkload Cluster Network|TKG Management Cluster HAProxy|TCP 6443|Allow Workload cluster to register with management cluster|Compute Gateway
AVI Management Network|vCenter Server|TCP 443|Allow AVI to read vCenter and PG information|Compute and Management Gateway
TKG Management and Workload Network|AVI Management Network|TCP 443|Allow TKG clusters to communicate with AVI for LB and Ingress Configuration|Compute Gateway
<!-- /* cSpell:enable */ -->

1. Create and configure the following inventory groups in **Networking & Security > Inventory > Groups > Compute Groups**.

	**Group Name**| **Members**
	-----|-----
	TKG\_Management\_Network|IP range of the TKG Management Cluster
	TKG\_Workload\_Networks|IP range of the TKG workload Cluster
	TKG\_Management\_ControlPlaneIPs|IP address of the TKG Management Control Plane
	TKG\_Workload\_ControlPlaneIPs|IP address of the TKG Workload Control Plane
	AVI\_Management\_Network|IP range of the AVI Management Cluster
	vCenter\_IP|IP of the Management vCenter
	DNS\_IPs|IPs of the DNS server
	NTP\_IPs|IPs of the NTP server

	![](img/tanzu-standard-on-vmc-aws/vmcAwsInventComputeGroups.png)

2. Create and configure the following inventory groups in **Networking & Security > Inventory > Groups > Management Groups**.

	**Note:** Because a vCenter group is already created by the system, we do not need to create a separate group for vCenter.

	<!-- /* cSpell:disable */ -->

	**Group Name**|**Members**
	-----|-----
	TKG\_Workload\_Networks|IP range of the TKG workload Cluster
	TKG\_Management\_Network|IP range of the TKG Management Cluster
	AVI\_Management\_Network|IP range of the AVI Management Cluster
	<!-- /* cSpell:enable */ -->

	![](img/tanzu-standard-on-vmc-aws/vmcAwsInventMgmtGroups.png)

3. Create the following firewall rules in **Networking & Security > Security > Gateway Firewall > Compute Groups**.

	<!-- /* cSpell:disable */ -->

	**Rule Name**| **Source Group Name**| **Destination Group Name**| **Protocol and Port**
	-----|-----|-----|-----
	TKG\_AVI\_to\_DNS|TKG\_Management\_Network TKG\_Workload\_Networks AVI\_Management\_Network|DNS\_IPs|UDP:53
	TKG\_AVI\_to\_NTP|TKG\_Management\_Network TKG\_Workload\_Networks AVI\_Management\_Network|NTP\_IPs|UDP:123
	TKG\_AVI\_to\_vCenter|TKG\_Management\_Network TKG\_Workload\_Networks AVI\_Management\_Network|vCenter\_IP|TCP:443
	TKG\_to\_Internet|TKG\_Management\_Network TKG\_Workload\_Networks|image repositories listed under ~/.tanzu/tkg/bom/|TCP:443
	TKGMgmt\_to\_TKGWorkloadVIP|TKG\_Management\_Network|TKG\_Workload\_ControlPlaneIPs|TCP:6443, 5556
	TKGWorkload\_to\_TKGMgmtVIP|TKG\_Workload\_Networks|TKG\_Management\_ControlPlaneIPs|TCP:6443
	TKG\_to\_AVI|TKG\_Management\_Network TKG\_Workload\_Networks|AVI\_Management\_Network| TCP:443
	<!-- /* cSpell:enable */ -->

	![](img/tanzu-standard-on-vmc-aws/vmcAwsGatewayFirewall.png)

	Optionally, you can also add the following firewall rules:

   - External to Bootstrap VM over Port 22 (Configure required SNAT)
   - External to AVI Controller over Port 22 (Configure required SNAT)
   - External to Tanzu Kubernetes Grid Management and Workload Cluster KubeVIP over port 6443 (Configure required SNAT)

4. Create the following firewall rules in **Networking & Security > Security > Gateway Firewall > Management Groups**.

	<!-- /* cSpell:disable */ -->

	**Rule Name**|**Source Group Name**|**Destination Group Name**|**Protocol and Port**
	-----|-----|-----|-----
	TKG\_AVI\_to\_vCenter|TKG\_Management\_Network TKG\_Workload\_Networks AVI\_Management\_Network|vCenter\_IP|TCP:443
	<!-- /* cSpell:enable */ -->

	![](img/tanzu-standard-on-vmc-aws/vmcAwsGatewayFirewallMgmt.png)

## <a id="request_IP"> </a>Request Public IP for Tanzu Kubernetes Nodes
Request public IP for Tanzu Kubernetes nodes to talk to the Internet nodes. You request the public IP in **Networking & Security > System > Public IPs > REQUEST NEW IP**.

The source NAT (SNAT) is automatically applied to all workloads in the SDDC to enable Internet access, and we have the firewall rules in place for Tanzu Kubernetes Grid components to talk to the Internet.

## <a id="config-resource-pool"> </a> Configure VM Folders and Resource Pools in vCenter

1. Create the required VM folders to collect the Tanzu Kubernetes Grid VMs and AVI Components. We recommend creating new folders for each TKG cluster.  

	![](img/tanzu-standard-on-vmc-aws/vmcAwsVmFolders.png)  

2. Create the required resource pools to deploy the Tanzu Kubernetes Grid and NSX Advanced Load Balancer components. We recommend deploying Tanzu Kubernetes Grid and NSX Advanced Load Balancer components on a separate resource pools.  

	![](img/tanzu-standard-on-vmc-aws/vmcAwsResPools.png)

3. Download and import Base OS templates to vCenter. [Download link](https://my.vmware.com/en/web/vmware/downloads/details?downloadGroup=TKG-131&productId=988&rPId=65946).  

    - Download and import all required Kubernetes versions. Ensure that the latest version is available in vCenter: "Photon v3 Kubernetes v1.20.5 vmware.2 OVA" is imported.
    - As of 1.3.1 TKG Management cluster will make use of the kube version "Photon v3 Kubernetes v1.20.5 vmware.2 OVA".
    - For the purpose of creating Tanzu Kubernetes Grid workload clusters on the required versions, import the additional OVAs available in the Download link.  
    - For the purpose of automation we could make use of Marketplace to push those images to vCenter.  

  	![](img/tanzu-standard-on-vmc-aws/vmcAwsImpBase.png)

## <a id="dep-config-nsxalb"></a>Deploy and Configure NSX Advanced Load Balancer

The following is an overview of the steps for deploying and configuring NSX Advanced Load Balancer:

1. [Deploy AVI Controller](#deploy-avi-control)
2. [AVI Controller Initial Setup](#avi-control-init-setup)
3. [Create Certificate for AVI using AVI Controller IP](#create-cert-avi)
4. [Create a VIP network in NSX Load Balancer](#create-vip-net-alb)
4. [Create IPAM Profile and Attach it to Default-Cloud](#create-ipam-profile)
5. [Deploy AVI Service Engines](#depl-nsxalb-se)

### <a id="deploy-avi-control"></a>Deploy AVI Controller

We will deploy NSX Advanced Load Balancer as a cluster of three nodes. We will deploy the first, complete the required configuration, then deploy two more nodes to form the cluster. We will reserve the following IP addresses for deploying NSX Advanced Load Balancer:

<!-- /* cSpell:disable */ -->

|Nodes|IPs (GatewayCIDR: 172.17.13.1/24)|
|--- |--- |
|1st Node(Leader)|172.17.13.2|
|2nd Node|172.17.13.3|
|3rd Node|172.17.3.4|
|Cluster IP|172.17.13.5|
<!-- /* cSpell:enable */ -->

1.  Download the NSX Advanced Load Balancer OVA and deploy it in the resource pool created for NSX Advanced Load Balancer components. For this deployment, we will use the NSX Advanced Load Balancer version 20.1.5.
2.  During deployment select the network segment, `m01avimgmt-seg01`, created for AVI Management.

    ![](img/tanzu-standard-on-vmc-aws/vmcAwsDepAvi.png)

3.  **(Optional)** In order to access NSX Advance Load Balancer from the Internet, request a new public IP from **Networking & Security** > **System** > **Public IPs** \> **REQUEST NEW IP**.  

    ![](img/tanzu-standard-on-vmc-aws/vmcAwsAviPubIP.png)  

4. Create the required NAT rule in **Networking & Security** > **Networking & Security** \>  **ADD NAT RULE**.

    ![](img/tanzu-standard-on-vmc-aws/vmcAwsAviNatRule.png)  

5. Create the following firewall rules in **Networking & Security** > **Security** > **Gateway Firewall** > **Compute Groups**.  

    ![](img/tanzu-standard-on-vmc-aws/vmAwsAviFirewallRules.png)


### <a id="avi-control-init-setup"></a>AVI Controller Initial Setup

1.  Go to https://*AVI\_Controller\_IP*.
2.  Create a new administrator account.

	![](img/tanzu-standard-on-vmc-aws/vmcAwsAviNewAcct.png)

3.  In the next page enter the following parameters and click **Save**.

    |Parameters|Settings|Sample Value|
    |--- |--- |--- |
    |System Settings|PassphraseConfirm PassphraseDNS Name|VMware123!VMware123!8.8.8.8|
    |Email/SMTP|Local Host|admin@avicontroller.net (default)|
    |Multi-Tenant|IP Route DomainService Engines are managed within the|Per tenant IP route domainTenant(Tenant (Not shared across tenants)|

    ![](img/tanzu-standard-on-vmc-aws/vmcAwsAviAcctSample.png)

### <a id="create-cert-avi"></a>Create Certificate Using the AVI Controller IP

1.  Log in to **AVI Controller > Click the Menu tile > Templates > Security > SSL/TLS Certificates > Create**.

    ![](img/tanzu-standard-on-vmc-aws/vmcAwsAviCertCreate.png)  

2.  Provide the details as shown in the following screenshot and **Save**. The values provided in the screen capture are sample values. Change the values for your environment. Ensure that you provide all the IPs under SAN details.  
    ![](img/tanzu-standard-on-vmc-aws/vmcAwsAviCertSample.png)  

3.  After the certificate is created, click the download icon and copy the certificate string.

	The certificate is required when you set up Tanzu Kubernetes Grid.  

    ![](img/tanzu-standard-on-vmc-aws/vmcAwsAviCopyCert.png)
4.  Go to **Administration** \> **Settings** \> **Access Settings**, and click the **pencil** icon at the top right to edit the **System Access Settings** and replace the certificate.

### <a id="create-vip-net-alb"></a> Create a VIP network in NSX Load Balancer

In NSX Advanced Load Balancer, create a network for VIP interfaces.

1. Click the **Menu** tile **> Infrastructure > Networks > Create**.
1. Provide the required values as shown in following screen capture and click **Save**.  

 	**Note:** For this deployment use the network in **m01tkg01-seg01**.

	![](img/tanzu-standard-on-vmc-aws/vmcAwsAviVipNetCreate.png)  

### <a id="create-ipam-profile"></a>Create IPAM Profile and Attach it to Default-Cloud

1.  Log in to AVI Controller.
2.  Click on **Menu Tile > Template > Profiles > IPAM/DNS Profiles > Create > IPAM Profile**.

    ![](img/tanzu-standard-on-vmc-aws/vmcAwsAviIpamCreate.png)  

3.  Enter the values provided in the following table and click **Save**.

    |Key|Value|
    |--- |--- |
    |Name|Profile_Name|
    |Type|Avi Vantage IPAM|
    |Cloud for Usable Network|Default-Cloud|
    |Usable Network|VIP Network created in previous step|

    ![](img/tanzu-standard-on-vmc-aws/vmcAwsAviIpamEdit.png)

4. Click **Menu Tile > Infrastructure > Clouds > Default-Cloud > Create**.
5. In **DHCP Settings**, click the **Edit icon**, select the IPAM profile we created, and click **Save**.

    ![](img/tanzu-standard-on-vmc-aws/vmcAwsAviEditCloudDHCP.png)

### <a id="depl-nsxalb-se"></a>Deploy NSX Advanced Load Balancer Service Engines
To deploy the NSX Advance Load Balancer service engines, download the OVA from the Avi Controller and deploy in SDDC.

1.  In the AVI Controller, go to  
	**Menu** tile **> Infrastructure > Clouds > Default-Cloud**.
1. Click the download icon and select **OVA**.
2. Click the key icon and copy the **UUID** and **Token**.
    ![](img/tanzu-standard-on-vmc-aws/vmcAwsAviUuidToken.png)
3. Deploy the OVA in SDDC in the resource pool **AVI\_components** and configure the interfaces:
    *  **Select Networks**
        *  1st Interface: AVI Management
        *  2nd to 10th Interface: Data Networks  
            ![](img/tanzu-standard-on-vmc-aws/vmcAwsAviSEconfig.png)  
            **Note:** Do not connect the Tanzu Kubernetes workload Segment (**w01tkg01-seg01**) if you intend to use separate service engines for the workload cluster.
    *  **Customize template**
        *  IP Address of the Avi Controller: Cluster IP of AVI
        *  Avi Service Engine Type: NETWORK\_ADMIN
        *  Authentication token for Avi Controller: Token from previous step
        *  Controller Cluster UUID for Avi Controller: Cluster ID from previous step
        *  Management Interface IP Address: Management IP for SE01
        *  Management Interface Subnet Mask
        *  Default Gateway
        *  DNS details
        *  Sysadmin login authentication key  
            ![](img/tanzu-standard-on-vmc-aws/vmcAwsAviSEconfig2.png)  

4.  To verify the deployment, power on the VM. The service engine is visible in the AVI Controller UI.  

    ![](img/tanzu-standard-on-vmc-aws/vmcAwsAviVerifySeDeployment.png)  

5.  In vCenter, navigate to **Summary of the SE > VM Hardware >** expand **Network adaptor 2** and copy the MAC address.

	![](img/tanzu-standard-on-vmc-aws/vmcAwsAviMacAdd.png)  

6.  In NSX Advanced Load Balancer, navigate to **Infrastructure > Service Engine** and edit the service engine.

1. Find the interface that matches the MAC addresses obtained from vCenter, enable **IPv4 DHCP** for the MAC address, and **Save**.  

    ![](img/tanzu-standard-on-vmc-aws/vmcAwsAviMacAddDhcp.png)   


7.  Repeat the steps to deploy the second service engine.  

    ![](img/tanzu-standard-on-vmc-aws/vmcAwsAviNsx2Se.png)

## <a id="config-bootstrap"></a>Configure Bootstrap Environment

The bootstrap machine is the laptop, host, or server on which you download and run the Tanzu
CLI. This is where the initial bootstrapping of a management cluster occurs, before it is pushed to the platform where it will run.

For the purpose of this deployment, we will use of CentOS 8. (From an automation point of view, we can have all the required dependencies installed on the Photon OS, package it as OVA, and push the OVA to vCenter from Marketplace.)

1.  Deploy a VM (under the resource pools created for Tanzu Kubernetes Grid management) and install CentOS 8.

2.  To connect to the bootstrap VM over SSH from the Internet, create the following Inventory Group and Firewall rules:  

    **Create Inventory Group:**  

    |Group Name|Members|
    |--- |--- |
    |Bootstrap_IP|IP of the bootstrap machine VM|

    ![](img/tanzu-standard-on-vmc-aws/vmcAwsBootstrapVmGroup.png)

    **Create a Firewall rule to allow SSH access to bootstrap machine VM from the Internet**  

    |Rule Name|Source Group Name|Destination Group Name|Protocol and Port|
    |--- |--- |--- |--- |
    |Ext_to_Bootstrap_IP|Any|Bootstrap_IP|TCP:22|

    ![](img/tanzu-standard-on-vmc-aws/vmcAwsBootstrapRules.png)

    **Optional**: Create the following DNAT rule in  **Networking & Security > Networking & Security > ADD NAT RULE**. Creating the DNAT rule allows you to access the bootstrap machine VM from the Internet. The bootstrap machine VM in this deployment has the IP address 172.17.10.2, which is connected to network segment m01tkg01-seg01.

    ![](img/tanzu-standard-on-vmc-aws/vmcAwsBootstrapDNAT.png)


3.  Ensure that NTP is configured on the bootstrap machine VM.  

    ![](img/tanzu-standard-on-vmc-aws/vmcAwsBootstrapNTP.png)  


4.  Install Tanzu CLI, Docker, and kubectl on the bootstrap machine VM. The following steps are for CentOS.  

    1.  **Install Tanzu CLI:**

        *   Download the Tanzu CLI bundle, **tanzu-cli-bundle-v1.3.1-linux-amd64.tar**, from [here](https://my.vmware.com/en/web/vmware/downloads/details?downloadGroup=TKG-131&productId=988&rPId=65946).
        *   Import the Tanzu CLI bundle to the bootstrap VM (you may use SCP) and execute the following commands to install it.

            ```bash
            # Install TKG CLI
            tar -xvf tanzu-cli-bundle-v1.3.1-linux-amd64.tar
            cd ./cli/
            sudo install core/v1.3.1/tanzu-core-linux_amd64 /usr/local/bin/tanzu

            # Install TKG CLI Plugins
            cd ..
            tanzu plugin install --local cli all
            rm -rf ~/.tanzu/tkg/bom
            export TKG_BOM_CUSTOM_IMAGE_TAG="v1.3.1-patch1"
            tanzu management-cluster create   # This command produces an error but results in the BOM files being downloaded to ~/.tanzu/tkg/bom.

            # Install Carvel Tools
            cd ./cli

            # Install ytt
            gunzip ytt-linux-amd64-v0.31.0+vmware.1.gz
            chmod ugo+x ytt-linux-amd64-v0.31.0+vmware.1 && mv ./ytt-linux-amd64-v0.31.0+vmware.1 /usr/local/bin/ytt

            # Install kapp
            gunzip kapp-linux-amd64-v0.36.0+vmware.1.gz
            chmod ugo+x kapp-linux-amd64-v0.36.0+vmware.1 && mv ./kapp-linux-amd64-v0.36.0+vmware.1 /usr/local/bin/kapp

            # Install kbld
            gunzip kbld-linux-amd64-v0.28.0+vmware.1.gz
            chmod ugo+x kbld-linux-amd64-v0.28.0+vmware.1 && mv ./kbld-linux-amd64-v0.28.0+vmware.1 /usr/local/bin/kbld

            # Install imgpkg
            gunzip imgpkg-linux-amd64-v0.5.0+vmware.1.gz
            chmod ugo+x imgpkg-linux-amd64-v0.5.0+vmware.1 && mv ./imgpkg-linux-amd64-v0.5.0+vmware.1 /usr/local/bin/imgpkg

            # Install yq
            wget https://github.com/mikefarah/yq/releases/download/v4.13.3/yq_linux_amd64.tar.gz
            gunzip yq_linux_amd64.tar.gz
            tar -xvf yq_linux_amd64.tar
            chmod ugo+x yq_linux_amd64 && mv yq_linux_amd64 /usr/local/bin/yq
            ```

    2.  **Install Docker:**

        ```bash
        sudo yum install -y yum-utils
        sudo yum-config-manager \
            --add-repo \
            https://download.docker.com/linux/centos/docker-ce.repo
        sudo yum install -y docker-ce docker-ce-cli containerd.io
        systemctl enable docker
        systemctl start docker
        ```  

    3.  **Install kubectl:**

        *   Download the "kubectl cluster cli v1.20.5 for Linux" (for TKG 1.3.1) from [here](https://my.vmware.com/en/web/vmware/downloads/details?downloadGroup=TKG-131&productId=988&rPId=65946).

        *   Import it to the Bootstrap VM and execute the following commands.

            ```bash
            gunzip kubectl-linux-v1.20.5-vmware.1.gz
            mv kubectl-linux-v1.20.5-vmware.1 /usr/local/bin/kubectl
            chmod +x /usr/local/bin/kubectl
            ```

5.  Create an SSH key pair. This is required for Tanzu CLI to connect to vSphere from the bootstrap machine. The public key part of the generated key will be passed during the Tanzu Kubernetes Grid management cluster deployment.  

    1. Execute the following command.

        ```bash
        ssh-keygen -t rsa -b 4096 -C "email@example.com"
        ```
    2. At the prompt, enter the file name to save the key (/root/.ssh/id\_rsa).
    3. At the promo, press Enter to accept the default.
    3. Enter and repeat a password for the key pair.
    4. Add the private key to the SSH agent running on your machine, and enter the password you created in the previous step.  

        ```bash
        ssh-add ~/.ssh/id_rsa
        ```

        If the above command fails, execute `eval $(ssh-agent)` and then rerun it.

    5.  Open **.ssh/id\_rsa.pub** and copy the public key contents. You will use it to create the config file for deploying the Tanzu Kubernetes Grid management cluster.

## <a id="deploy-mgmt-cluster"></a>Deploy Management Cluster

You will deploy the management cluster from the Tanzu Kubernetes Grid Installer UI.

1. To access the installer UI from external machines, execute the following command on the bootstrap VM:

    ```bash
    tanzu management-cluster create --ui --bind <IP_Of_BootstrapVM>:8080 --browser none
    ```

    With firewall rules in place, you should be able to access the UI from the Internet.

    ![](img/tanzu-standard-on-vmc-aws/883815969.png)  


2.  On the **VMware vSphere** tile, click **Deploy**.
3.  For **IaaS Provider** enter the following information and click **Next**:
	For **SSH Public Key**, copy and paste the contents of `.ssh/id\_rsa.pub` from the bootstrap machine VM.  
    ![](img/tanzu-standard-on-vmc-aws/894262129.png)  

4.  For **Management Cluster Settings**, enter the following and click **Next**.

    Type: Prod  
    Instance Type: Large  
		
    ![](img/tanzu-standard-on-vmc-aws/894262136.png)  

5.  For **VMware NSX Advanced Load Balancer**,   
    1. Obtain the AVI Controller certificate using: 
    	```
    	echo -n | openssl s\_client -connect <AVI\_Controller\_IP:443>  
    	```
    2. Enter the following information and and click **Next**.

			For **Cluster Labels**, enter

    	- **Key**: type
    	- **Value**: `tkg-mgmt-cluster`

    	![](img/tanzu-standard-on-vmc-aws/894262239.png)  

    **Note:** Ensure that the **Cluster Label** is set. This is required because the Tanzu Kubernetes Grid workload cluster will not make use of the AKO config.

6.  For **Metadata**,  **Specify Labels for the Management Cluster**, and click **Next**. Use the same label provided for the VMware NSX Advanced Load Balancer settings.  

    ![](img/tanzu-standard-on-vmc-aws/894262266.png)  


7.  For **Resource Settings**, enter the following and click **Next**:
    ![](img/tanzu-standard-on-vmc-aws/883816111.png)  


8.  For **Kubernetes Network Settings**, enter the following and click **Next**.

    ![](img/tanzu-standard-on-vmc-aws/883816124.png)  

9.  Disable Identity Management and click **Next**.
10. For **OS Image**, select the OS image which you imported earlier and click **Next**.

    ![](img/tanzu-standard-on-vmc-aws/883816444.png)
11. For **Register with Tanzu Mission Control**, enter the Registration URL and and click **Next**.  

	![](img/tanzu-standard-on-vmc-aws/883816481.png)

    To get the Registration URL,

	1. Log in to Tanzu Mission Control from the CSP portal.
	2. Go to **Administration > Management Clusters > Register Management Cluster > Tanzu Kubernetes Grid** .

     ![](img/tanzu-standard-on-vmc-aws/883816465.png)  
	3. Under the **Register Management Cluster** pane, enter **Name**, select the cluster group, click **Next**, and copy the registration link.  

     ![](img/tanzu-standard-on-vmc-aws/883816476.png)       

12. Accept the EULA and click **Next**.
13. Review the configuration and copy the CLI. You will use the CLI to initiate the deployment from bootstrap machine VM.  

    ![](img/tanzu-standard-on-vmc-aws/883816490.png)  

    Alternatively, use of the following sample configuration file to deploy the management cluster.

    **Sample `mgmtconfig.yaml`**  

    <!-- /* cSpell:disable */ -->    
    ```yaml
    AVI_CA_DATA_B64: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURqVENDQW5XZ0F3SUJBZ0lVWG5EbkJkMlRVWHpBVExibUVjdVBUTC9HMW5Jd0RRWUpLb1pJaHZjTkFRRUwKQlFBd2RqRUxNQWtHQTFVRUJoTUNWVk14Q3pBSkJnTlZCQWdNQWtOQk1SSXdFQVlEVlFRSERBbFFZV3h2SUVGcwpkRzh4RXpBUkJnTlZCQW9NQ2xaTmQyRnlaU0JKVGtNeEd6QVpCZ05WQkFzTUVsWk5kMkZ5WlNCRmJtZHBibVZsCmNtbHVaekVVTUJJR0ExVUVBd3dMTVRjeUxqRTNMakV6TGpJd0hoY05NakV3TnpJek1UazBNekE0V2hjTk1qSXcKTnpJek1UazBNekE0V2pCMk1Rc3dDUVlEVlFRR0V3SlZVekVMTUFrR0ExVUVDQXdDUTBFeEVqQVFCZ05WQkFjTQpDVkJoYkc4Z1FXeDBiekVUTUJFR0ExVUVDZ3dLVmsxM1lYSmxJRWxPUXpFYk1Ca0dBMVVFQ3d3U1ZrMTNZWEpsCklFVnVaMmx1WldWeWFXNW5NUlF3RWdZRFZRUUREQXN4TnpJdU1UY3VNVE11TWpDQ0FTSXdEUVlKS29aSWh2Y04KQVFFQkJRQURnZ0VQQURDQ0FRb0NnZ0VCQU4rUkQrSEZmdzBXdkxPZldsS25ydjl1SnlZRjNIeFNWYnEyUXlMMApDR3hsMHpFdEZYa3BTdnl6TjVlVlNnZzJZSlpmUVFmUWVFeGxTNmtvYlk5dmN0Q1dqd3NLL1U0KzBTK1B4NjNZCjhVcURkL2xLRVM4aTMvMTlSRXNOYUFPZ1lyaHNMUGd5dlNYYnpQQ1pOcWVMbEg4SFVPQ3lvQzVmWXpLeFRKaGsKMmROOWtUaC9VNXlmQkhVRTlyakRYeFlZMnhZTi9hT29vbldQYW1lTGhBYWZ5Q1JsQjRtRFN1elk4MGNCTGs4bgp4MFdNSFVsbWlVZE1OM3RyeDUwenoxaDFjelJGVmhPbzhVZC85Z05HM0h3VDhHSURpMkUyY3JUV1lWN2p5akhvCjNnNjN2MVFrS3VGbWpRREtTN01YUkJ0MVBLc3hZMjNTNm84RHc4bHhRV2c5ZHJNQ0F3RUFBYU1UTUJFd0R3WUQKVlIwUkJBZ3dCb2NFckJFTkFqQU5CZ2txaGtpRzl3MEJBUXNGQUFPQ0FRRUFocHZjN0s4ZUszV0dYdEFBdE5KegpkanB6a0g1N21mMm1WQkRiNWVWV3RvTkhVSXdoT2s4QUVhTnlQdFBoYlVtbklmSy94VDFZWUVEdkxVMzB5VnVzCnl5U3Y0TzZxUVgrUDZsQXV3L0g5NEtJaXgra3BtRU9RaDJyR2xZYlJWNy9RTklveHJJeW5XRllyUmJPajdUU0QKL2JQTUNoQ1JNT3Y3dUVoL0FMd0Ntbnpjamg5SlhXQ0ZYMHJTT0RvUk5ucWxYRG5nazRLcmFRaktxQkdRUlhOWQo1R1pXNTJocDVldFdmYTl3THJGMmZzWlVkRStwTFk5Z2ZoMjRtbXhGNGoxeUMzbnM5d2JkbDZ3V3A4aDdEdlhMCmZQZ01ma1A3THBwR3FheUMrUDNhU2NhdkVMR2IrZTNzNGwxeFlaWWJZeGkwKzZob3lEYTBYOXYycmx2RkprY3gKdGc9PQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==
    AVI_CLOUD_NAME: tkgvmc-cloud01
    AVI_CONTROLLER: 172.17.13.2
    AVI_DATA_NETWORK: tkgvmc-tkgmgmt-data-network01
    AVI_DATA_NETWORK_CIDR: 172.17.14.0/24
    AVI_ENABLE: "true"
    AVI_LABELS: |
        'type': 'management'
    AVI_PASSWORD: <encoded:Vk13YXJlMTIzIQ==>
    AVI_SERVICE_ENGINE_GROUP: tkgvmc-tkgmgmt-group01
    AVI_USERNAME: admin
    CLUSTER_CIDR: 100.96.0.0/11
    CLUSTER_NAME: vmc-tkg-mgmt-01
    CLUSTER_PLAN: dev
    ENABLE_CEIP_PARTICIPATION: "true"
    ENABLE_MHC: "true"
    IDENTITY_MANAGEMENT_TYPE: none
    INFRASTRUCTURE_PROVIDER: vsphere
    SERVICE_CIDR: 100.64.0.0/13
    TKG_HTTP_PROXY_ENABLED: "false"
    VSPHERE_CONTROL_PLANE_DISK_GIB: "40"
    VSPHERE_CONTROL_PLANE_ENDPOINT: 172.17.10.100
    VSPHERE_CONTROL_PLANE_MEM_MIB: "16384"
    DEPLOY_TKG_ON_VSPHERE7: "true"
    VSPHERE_CONTROL_PLANE_NUM_CPUS: "4"
    VSPHERE_DATACENTER: /SDDC-Datacenter
    VSPHERE_DATASTORE: /SDDC-Datacenter/datastore/WorkloadDatastore
    VSPHERE_FOLDER: /SDDC-Datacenter/vm/TKGVMC-TKG-Mgmt
    VSPHERE_NETWORK: TKGm-Mgmt-Seg01
    VSPHERE_PASSWORD: <encoded:dioyU1I3ck5DSmRGZXAt>
    VSPHERE_RESOURCE_POOL: /SDDC-Datacenter/host/Cluster-1/Resources/TKGVMC-TKG-Mgmt
    VSPHERE_SERVER: 10.2.224.4
    VSPHERE_SSH_AUTHORIZED_KEY: ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDGxNWes6xJO6o/OzW7uE7eH4ndKFy717dbHuv5Z7WKmqz5igw/SnY3VK+nPtGK4NonnFlVfNSRpjTy/aWhl2EfM0pPwOEdglqa0HivxbsgjSHG8dxDzYmh8/ekTJwhgmqJgLrkxvPpyYxKCY+/IoG5Y3I73yfVJxpIWrtTlZXJsMYOcQZQQhwkJp3UyfwRwi0ZEN7JvmGFWeKetQLQfJrfkLKcH/nsO+HXteQFsOvIdNjwN3QG475DpO6epTQaXMPiVGfBabo/lPgVj7NLwbDPTuLVWryrv+FJQgXJb/D1xvEPhlHICqOyvJilKfmuuYnQST8VCU7Kpem8qD+YrK0iiCS31Ea9Y9b+wD21q4acjCN2vAIsWfNtLmmtrEXSR9pyypv0SRLOAnDkatpF6PxMUZZgm+iMsjbOQ0r/DD5c40nYcse65ioi5HQTGUhwFv8HcA/QgXiQQnTdN35NHNTQlyKj/zXugJP7Pe4jASQA7MGEuH4SxvHm7tQ6lYCGq7/yI+d2Fl67101cemKw2U5UcWuhBgWIdZ8434pSSQn776c3y73SsPGhN0RkoGwj82NGIPFkDLXet98JO4DP4M78S1qscQccBDt0qnmMQ9ViD4Pn3NLck7uuXwMb9jIp3BJj1WtajaC0ZXPPVDa9Kxt7fF/CjDnWGMP32qnCYbx0iQ== cloudadmin@vmc.local

    VSPHERE_USERNAME: cloudadmin@vmc.local
    VSPHERE_WORKER_DISK_GIB: "40"
    VSPHERE_WORKER_MEM_MIB: "16384"
    VSPHERE_WORKER_NUM_CPUS: "4"
    ```
    <!-- /* cSpell:enable */ -->

    **For Automation, use the following:**

    <!-- /* cSpell:disable */ -->
    ```bash
    export DEPLOY_TKG_ON_VSPHERE7=true
    tanzu management-cluster create -y --file /path_to/config.yaml -v 6
    tanzu management-cluster kubeconfig get m01tkg01 --admin --export-file /path_to/kubeconfig.yaml
    export TMC_API_TOKEN="zeQHS8pVk5Y1ub9htejsYt3AyMY8022Hg3VzJGv3A2qfv7dZbxw1fM5tNgXS2ssd"
    tmc login --no-configure -name demo
    tmc managementcluster register vmc-m01tkg01 -c default -p TKG -k /path_to/kubeconfig.yaml
    ```
    <!-- /* cSpell:enable */ -->  

14. On the bootstrap machine VM, execute the following command to start the cluster creation:
    ![](img/tanzu-standard-on-vmc-aws/883816547.png)

15. After the Tanzu Kubernetes Grid Management Cluster is deployed, you can verify the cluster on the bootstrap machine VM, vCenter, and Tanzu Mission Control.  

    **On the Bootstrap Machine VM:**  
    ![](img/tanzu-standard-on-vmc-aws/883816608.png)  

    Execute the following commands to check the status of the management cluster:   

    <!-- /* cSpell:disable */ -->
    ```bash
    tanzu management-cluster get
    kubectl config use-context <mgmt_cluster_name>-admin@<mgmt_cluster_name>
    kubectl get nodes
    kubectl get pods -A
    ```
    <!-- /* cSpell:enable */ -->

    **On vCenter:**  

    ![](img/tanzu-standard-on-vmc-aws/894264199.png)  

    **On Tanzu Mission Control**  

    ![](img/tanzu-standard-on-vmc-aws/894264239.png)  


    You can now create Tanzu Kubernetes Grid workload clusters and make use of the backup services from Tanzu Mission Control.  
    Refer [10\. Attach an existing TKG Guest Cluster to TMC, Enable and test Data Protection](https://vmc.techzone.vmware.com/resource/protect-tanzu-kubernetes-grid-workloads-tanzu-mission-control-data-protection) for enabling data protection    

## <a id="set-up-shared-cluster"></a>Set up a Shared Workload Cluster
Follow these steps to set up a shared workload cluster:

1. [Create a Shared Workload Cluster](#create-shared-cluster)
2. [Deploy Contour on Shared Service Cluster](#deploy_contour)
3. [Deploy Harbor on Shared Service Cluster](#deploy-harbor)


### <a id="create-shared-cluster"> </a>Create a Shared Workload Cluster

1.  Create Shared cluster using TMC CLI:

    <!-- /* cSpell:disable */ -->
    ```bash
    tmc cluster create -t tkg-vsphere -n tkg-shared -m vmc-tkg-mgmt01 -p default --cluster-group default --control-plane-endpoint 172.17.15.41 --ssh-key "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDH3HkX/32YEWigW6wcez65KFxjkkYP1Qn8NWLK7rs+/CXmVfmV8RnVcfpFu9VERe1j5UQEQXW9p15KMeCZ2s+omoo2dCsakKVIU7OlQcEko2gSYKmSNcnxwcFr7BWho9E278iIaHsDnV+N1CpjqUeWPzDxuLuuAc0EPHzgnz2lWQKknR68N9SWmWP108jnkHQP+ATybKeop57+mP9k5wNo1OOSbSooiPMdBGPlfZIQ+WaGSdNLPUUuzfic2fONJdE5OWRezPuCWRGR8rFsYZQ/O6zf7Y3zdv9ZU6NYnpGRkKVdDUDhusvaD58HlbW4nJ4PmP7hpsmEKH3QqH8DOpIA8ZxLR7YCqdPHRJEKLUuBtaUmb3NC3cDgwMiDWVF0s3OspDUYso+OpX8lk1etiLnSeCcpwC68GP17G/dmu9dEKAynfma7blfSETVCboY/FPCAllAqtfR/zohoE8iFHyRwW26O4wtMX0jhhXvl/1HgJlykycvHdoBKv2UEP2NGh4uaLSPaSLuh3IZZaceQWm3yKqPFhZwYqFM7Kp2OJBC2ilweNd4oG65ocfWPznngqBkVu65j+Z0pOsXF+xLtxVxZsqtQI+pE+Wi21VS+hR8Qzy0NW+glZ8m63LdCDSkESN8iYdUQBgbDmtdYw0o6HusGMNbCjie6fqIU4suZYlECjw== tanzu@vmc.com" --version v1.20.5+vmware.2-tkg.1 --datacenter /SDDC-Datacenter --datastore /SDDC-Datacenter/datastore/WorkloadDatastore --folder /SDDC-Datacenter/vm/m01tkg01 --resource-pool /SDDC-Datacenter/host/Cluster-1/Resources/m01tkg01 --workspace-network /SDDC-Datacenter/network/TKG-SharedService-Segment --control-plane-cpu 8 --control-plane-disk-gib 80 --control-plane-memory-mib 16384 --worker-node-count 1  --worker-cpu 4 --worker-disk-gib 40 --worker-memory-mib 32768
    ```
    <!-- /* cSpell:enable */ -->

2.  Obtain admin credentials for the Shared Cluster:

    <!-- /* cSpell:disable */ -->
    ```bash
    tanzu cluster kubeconfig get <Shared_Cluster_Name> --admin

    # Run command:
    tanzu cluster kubeconfig get tkg-shared --admin

    # Sample output:
    #  Credentials of cluster 'tkg-shared' have been saved
    #  You can now access the cluster by running 'kubectl config use-context tkg-shared-admin@tkg-shared'
    ```
    <!-- /* cSpell:enable */ -->

3.  Connect to the management cluster using TKG CLI and add the following tags:

    <!-- /* cSpell:disable */ -->
    ```bash
    kubectl config use-context tkg-mgmt01-admin@tkg-mgmt01   					# Connect to TKG Management Cluster

    kubectl label cluster.cluster.x-k8s.io/<Shared_Cluster_Name> cluster-role.tkg.tanzu.vmware.com/tanzu-services="" --overwrite=true
    kubectl label cluster <Shared_Cluster_Name> type=workload   				# Based on the match labels provided in AKO config file

    # Run command:
    tanzu cluster list --include-management-cluster

    # Sample output:
    #  NAME        NAMESPACE   STATUS   CONTROLPLANE  WORKERS  KUBERNETES        ROLES           PLAN  
    #  tkg-shared  default     running  1/1           1/1      v1.20.5+vmware.2  tanzu-services  dev   
    #  tkg-mgmt01  tkg-system  running  1/1           1/1      v1.20.5+vmware.2  management      dev
    ```
    <!-- /* cSpell:enable */ -->

4. Download VMware Tanzu Kubernetes Grid Extensions Manifest 1.3.1 from [here](https://my.vmware.com/en/web/vmware/downloads/details?downloadGroup=TKG-131&productId=988&rPId=65946).
5. Unpack the manifest using the following command.

    ```bash
    tar -xzf tkg-extensions-manifests-v1.3.1-vmware.1.tar.gz
    ```

5. Connect to the shared services cluster using the credentials obtained in step 2 and install cert-manager.  

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

### <a id="deploy_contour"> </a> Deploy Contour on the Shared Services Cluster  

Execute the following commands to deploy Contour on the shared services cluster.

```bash
cd ./tkg-extensions-v1.3.1+vmware.1/extensions/ingress/contour
kubectl apply -f namespace-role.yaml
cp ./vsphere/contour-data-values-lb.yaml.example ./vsphere/contour-data-values.yaml
kubectl create secret generic contour-data-values --from-file=values.yaml=vsphere/contour-data-values.yaml -n tanzu-system-ingress
kubectl apply -f contour-extension.yaml

# Validate
kubectl get app contour -n tanzu-system-ingress

# Note: Once the Contour app is deployed successfully, the status should change from Reconciling to Reconcile Succeeded

# Sample output:
#  kubectl get app contour -n tanzu-system-ingress
#  NAME      DESCRIPTION   SINCE-DEPLOY   AGE
#  contour   Reconciling   2m40s          2m40s

# Wait till we see "Reconciling succeeded" (can take 3-5mins)
#  NAME      DESCRIPTION           SINCE-DEPLOY   AGE
#  contour   Reconcile succeeded   112s           5m46s

# Capture the envoy external IP:
kubectl get svc -A | grep envoy

# Sample output:
#   kubectl get svc -A | grep envoy
#   tanzu-system-ingress    envoy    LoadBalancer   10.96.217.200   172.17.75.10   80:31343/TCP,443:31065/TCP   12h
```

To access Envoy Administration:  
```bash
ENVOY_POD=$(kubectl -n tanzu-system-ingress get pod -l app=envoy -o name | head -1)  
kubectl -n tanzu-system-ingress port-forward --address 0.0.0.0 $ENVOY_POD 80:9001  
```

When you have started running workloads in your Tanzu Kubernetes cluster, you can visualize the traffic information in Contour.  
```bash
CONTOUR_POD=$(kubectl -n tanzu-system-ingress get pod -l app=contour -o name | head -1)  
kubectl -n tanzu-system-ingress port-forward $CONTOUR_POD 6060  
curl localhost:6060/debug/dag | dot -T png > contour-dag.png
```

### <a id="deploy-harbor"> </a>Deploy Harbor on the Shared Services Cluster  

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
