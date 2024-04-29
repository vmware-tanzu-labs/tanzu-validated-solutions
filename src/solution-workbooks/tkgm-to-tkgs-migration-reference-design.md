# Reference Design for Migration from TKGm to TKGs (vSphere with Tanzu)

Currently over 120+ customers are currently utilising VMware Tanzu Multi-Cloud Grid TKGm. With the proposed roadmap on TKGm continuity, existing customers need to have a mechanism to migrate to vSphere with Tanzu to retain the business continuity. The mechanism should enable seamless migration of Core Applications, utilizing their existing Infrastructure, Storage, Network, Security Policies, RBAC, authentication policies. The mechanism should also address very minimal or no additional purchase of software and solutions but utilize the existing solutions offerings from VMware.

## Audience

This document is intended for individuals and teams involved in planning, designing, implementing, and managing the current Tanzu Kubernetessss Grid infrastructure. The audience includes the following roles:
- Project executive sponsor.
- Virtualization architects.
- Business decision makers.
- Architects and planners responsible for driving architecture-level decisions
- Core technical teams, such as product development, server, storage, networking, security, backup and recovery, and application support teams.
- IT operational teams (VMware Resident Engineers), responsible for the day-to-day operations of the new solution to be deployed and managed.

It is assumed that the reader has knowledge of and familiarity with Virtualization, Kubernetes (Tanzu/TKG), and related topics (including compute, storage, and networking)


## Process Overview

Prior to engaging, it is important to adhere to the following process to plan the migration procedure from TKGm to vSphere with Tanzu.
1. Checklist preparation on multiple aspects. 
1. vSphere with Tanzu environment preparation.
1. Downtime planning and preparation.

## Checklists Overview

Prior to engaging on the migration plan, it is vital to understand the requirements of the customer from multiple aspects. This provides a clear understanding and prepares the order for the migration plan. These requirements are majorly classified in the following aspects:

### End Application Requirement

Customer ultimate target is to have the Production Applications continue to operate post migration.  The application is continuing to use the features and requirements. These requirements vary from

|**Aspect**|**Checklist (To be collected from TKGm running environment**)|
| --- | --- |
|Security policies, Access policies|list any existing policies present|
|Network Policies like LB|list network policies at present in place|
|Registry Integrations|Registry at present in use in the environment|
|Database/Microservices integration|Integration with any Specific data services, please list the same|
|Application Scalability|Details on Application Architecture|
|Application utilising specific tools like csi drivers|Any Specific tool support required , please list|
|Microservices access from other instances like NPC|details on Application Architecture|
|Air Gapped availability of the Application|Internet restricted app or public facing app?|
|Application downtime <br> SaaS Integration for application <br> AI/ML usage |how much downtime can be tolerated while migration|


## Detailed Comparison overview of TKGm and TKGS

Once you have prepared the above checklist, please refer below to a detailed comparison between TKGM and TKGS to make sure all features required are present in TKGS.

### Datacenter Overview

TKGM and TKGS Overview at datacenter level is described in below table:

|**TKGm**|**TKGS**|
| --- | --- |
|Recommended for customers with specific use cases on Edge Telco. <br> Supports TKG 2.5 Standalone management cluster.| Recommended for vSphere 7 or 8 environment(Support TKG 2.2 Supervisor cluster) |
| Can work with Single host in vSphere Environments | Minimum 3 hosts are required to deploy TKGS |
| Supports Host based or cluster based multi zone topology for workload clusters. | Supports three zone Supervisor cluster level deployment from vSphere 8.0 |
| TKGM and TKGS coexist in the same datacenter? [Reference](https://williamlam.com/2021/06/can-i-deploy-both-tanzu-kubernetes-grid-tkg-and-vsphere-with-tanzu-on-same-vsphere-cluster.html) <br> But officially it is not recommended to have both TKGm and TKGS SUpervisor and management cluster in the same environment. | TKGS supervisor cluster can be leveraged along with tanzu CLI to deploy TKG workload clusters |
| Doesn’t support vSphere pods|vSphere pods are supported|
| Required TKR OVA template in vsphere environment | use Subscribed content library for deployment |
| Supports Windows MultiOS cluster in non air gapped environment | Still no support for Windows based MultiOS clusters. |
| Authentication: Integration with OIDC/LDAP endpoint. | Authentication: vSphere SSO and Pinniped. |
| TKR images version is dependent on TKG releases and independent of underlying vSphere Environment. | At present TKR image releases have more binding to vSphere version in use, to upgrade TKR version, need to update vSphere environment. |

### RBAC and Authentication

|**TKGm**|**TKGS**|
| --- | --- |
| Supports Authentication with OIDC and LDAP Endpoint | vSphere SSO and Pinniped Authentication <br> Support External IDP  |

### Storage Overview

TKGm and TKGS Storage Comparison overview is described below:

|**TKGm**|**TKGS**|
| --- | --- |
| By Default comes with Container Storage Interface | By Default comes with Container Storage Interface |
| CSI Components run as pods on cluster | CSI components run as pods on cluster |
| Only supports External Tree Storage provider, no support for in-tree Storage provider | Only supports External Tree Storage provider, no support for in-tree Storage provider |
| Support Storage types: vSphere Cloud Native Storage(CNS), iSCSI, NFS, FC. | Support Storage types: vSphere Cloud Native Storage(CNS), iSCSI, NFS, FC. |
| Storage usage depends on underlying infrastructure(datastore) | Use vSphere Storage based Policy |


Multi Zone Storage requirements for TKGS and TKGM is listed below:

|**TKGm**|**TKGS(Multi zone cluster supported on vSphere 8.0)**|
| --- | --- |
| Storage Across host based or cluster based zones doesn’t have any specific limitations and can be of any type  Cloud Native Storage(CNS), iSCSI, NFS.| Storage Across three zones of supervisor can be of different types like VMFS for Zone 1 , vSAN for Zone 2 but it is recommended to have the same type of storage across zones to achieve consistency.|
|| Storage policy used for namespace must be compliant with shared storage across zones and must be topology aware. |
|| Local datastores to a single zone should not be mounted to other zones. |
|| Three zone Supervisor doesn’t support: <br> - Cross Zonal Volumes. <br> - vSAN File volumes (ReadWriteMany Volumes). <br> - Static volume provisioning using register volume API. <br> -  Workloads that use  vSAN data Persistence platform. <br> -  vSAN Stretched cluster. <br> - VMs with vGPU and instance Storage. |

### Networking Overview

This topic provides a network overview for TKG clusters deployed with Supervisor (TKGs) and Standalone Management Cluster (TKGm).

| | **Tanzu Kubernetes Grid** <br> TKG with Management Cluster| **vSphere with Tanzu** <br> TKG with Supervisor Cluster  |
| --- | --- | --- |
| Network topology | Tanzu Kubernetes Grid on vSphere with vSphere networking <br> Tanzu Kubernetes Grid on vSphere with NSX-T networking  <br> [Ref link](https://docs.vmware.com/en/VMware-Tanzu-for-Kubernetes-Operations/2.3/tko-reference-architecture/GUID-tko-vsphere-section.html) | Supervisor Networking with VDS <br> Supervisor Networking with NSX <br> Supervisor networking with NSX and NSX Advanced Load Balancer (**Applicable for vSphere 8.0U2 or later,NSX 4.1.1 or later, NSX ALB 22.1.4 or later) <br> [Ref link](https://docs.vmware.com/en/VMware-vSphere/8.0/vsphere-with-tanzu-installation-configuration/GUID-B156CDA6-B056-4D1C-BBC5-07D1A701E402.html#supervisor-networking-with-nsx-and-nsx-advanced-load-balancer-2) |
| Pod Networking | Antrea, Calico, or secondary Multus CNI | Antrea or Calico for Tanzu Kubernetes clusters (TKC) <br> NSX-T/VDS for vSphere Pod Service |
| Control plane LB options | Kube-vip <br> NSX-ALB | NSX-ALB <br> HA Proxy <br> NSX-T |
| Application LB (L4) | NSX-ALB <br> Other networking providers like MetalLB, HA Proxy, F5 LB etc | NSX-ALB <br> NSX-T|
| Application LB (L7) | Contour <br> NSX ALB Enterprise | Contour <br> NSX ALB Enterprise |


### Application Overview

It depends on the different application customers deployed on current TKG infrastructure.


## TKGs Migration Planning/Suggestions

To date, there is no migration tool available from the product team, but this might change in the future. The vSphere version that will support TKGm to TKGS migration is unknown at this time. The PVE team will work with the TKGS product management team to get this information.
The following topics provide an overview of key considerations that must be taken into account and planned accordingly.

### Resource Planning

- Enabling WCP on a vSphere cluster demands careful attention to resource planning. 
- Thorough resource planning is essential for the new supervisor plane components and new TKCs, and the sizing of the control plane and worker nodes needs to be taken into account.
- Resource planning must also ensure that both the TKGm and TKGs environments can operate in parallel until all applications are successfully migrated to the TKGs environment and all application traffic is seamlessly switched over to the new environment

### Network Planning

Generally, there are three supported models of Supervisor deployment:
1. Supervisor Deployment with VDS Networking
1. Supervisor Deployment with NSX Networking
1. Supervisor Deployment with NSX Advanced Load Balancer and NSX Networking

> **Note**: Support for the NSX Advanced Load Balancer for a Supervisor configured with NSX networking is only available in vCenter 8.0u2 and later, NSX 4.1.1 or later, NSX ALB 22.1.4 or later .

#### Supervisor Deployment with VDS Networking

In a Supervisor that is backed by VDS as the networking stack, all hosts from the vSphere clusters backing the Supervisor must be connected to the same VDS. The Supervisor uses distributed port groups as workload networks for Kubernetes workloads and control plane traffic. You assign workload networks to namespaces in the Supervisor.

Depending on the topology that you implement for the Supervisor, you can use one or more distributed port groups as workload networks. The network that provides connectivity to the Supervisor control plane VMs is called Primary workload network. You can assign this network to all the namespaces on the Supervisor, or you can use different networks for each namespace. The Tanzu Kubernetes Grid clusters connect to the Workload Network that is assigned to the namespace where the clusters reside.

- NSX Advanced Load Balancer or the HAProxy load balancer provides L4 LoadBalancing services for control planes.
- In NSX ALB, only the Default-Cloud and Default SE group can be used.
- AKO must be deployed manually for each TKC to leverage L7 functionalities.
- The CIDR block for `Internal Network for Kubernetes Services` needs to be specified, with a minimum size /23. This list of IPs is used to allocate Kubernetes services of type ClusterIP. These IP addresses are internal to the cluster, but should not conflict with any other IP range.
- In a three-zone Supervisor, you deploy the Supervisor on three vSphere zones, each mapped to a vSphere cluster. All hosts from these vSphere clusters must be connected to the same VDS. All physical servers must be connected to a L2 device

##### Key Network Considerations/Requirements

This section provides key network requirements and considerations. For more information, see [Requirements for Cluster Supervisor Deployment with NSX Advanced Load Balancer and VDS Networking](https://docs.vmware.com/en/VMware-vSphere/8.0/vsphere-with-tanzu-concepts-planning/GUID-7FF30A74-DDDD-4231-AAAE-0A92828B93CD.html).

| **Component** | **Minimum Quantity** | **Required Configuration** |
| --- | --- | --- |
| Supervisor Management Network | 1 | A Management Network that is routable to the ESXi hosts, vCenter Server, the Supervisor Cluster, and load balancer. The network must be able to access an image registry and have Internet connectivity if the image registry is on the external network. The image registry must be resolvable through DNS. <br> You can make use of the existing TKGm Management Network or create a new one based on the requirements and IP availability on the existing network. <br> If needed, NSX ALB can be deployed on the same network. |
| Static IPs for Kubernetes control plane VMs | Block of 5 IPs | A block of 5 consecutive static IP addresses is to be assigned from the Supervisor Management Network to the Kubernetes control plane VMs in the Supervisor Cluster |
| Kubernetes services CIDR range | /16 Private IP addresses | A private CIDR range to assign IP addresses to Kubernetes services. You must specify a unique Kubernetes services CIDR range for each Supervisor Cluster. |
| Workload Network  | 1 | At least one distributed port group must be created on the vSphere Distributed Switch that you configure as the Primary Workload Network. Depending on the topology of choice, you can use the same distributed port group as the Workload Network of namespaces or create more port groups and configure them as Workload Networks. Workload Networks must meet the following requirements: <br> - Workload Networks that are used for Tanzu Kubernetes cluster traffic must be routable between each other and the Supervisor Cluster Primary Workload Network. Routability between any Workload Network with the network that the NSX Advanced Load Balancer uses for virtual IP allocation.  <br> - No overlapping of IP address ranges across all Workload Networks within a Supervisor Cluster. |
| NSX ALB Management Network  | 1 | The Management Network is where the Avi Controller, also called the Controller, resides. <br> It is also where the Service engine’s management interface is connected. The Avi Controller must be reachable to the vCenter Server and ESXi management IPs from this network. <br> This network is not required if you deploy NSX ALB on the Supervisor Management Network or existing infrastructure management network. |
| VIP Network Subnet | 1 | The data interface of the Avi Service Engines connects to this network. Configure a pool of IP addresses for the Service Engines. The load balancer Virtual IPs (VIPs) are assigned from this network. |
| VIP IPAM range | N/A | A private CIDR range to assign IP addresses to Kubernetes services. The IPs must be from the data network subnet. You must specify a unique Kubernetes services CIDR range for each Supervisor Cluster. |


#### Supervisor Deployment with NSX Networking

A Supervisor that is configured with NSX, uses the software-based networks of the solution and an NSX Edge Load Balancer to provide connectivity to external services and DevOps users.  Review the system requirements for configuring vSphere with Tanzu on a vSphere cluster by using the NSX networking stack. For more information, see [Requirements for Cluster Supervisor Deployment with NSX](https://docs.vmware.com/en/VMware-vSphere/8.0/vsphere-with-tanzu-concepts-planning/GUID-B1388E77-2EEC-41E2-8681-5AE549D50C77.html).

You can distribute vSphere zones across different physical sites as long as the latency between the sites doesn't exceed 100 ms. For example, you can distribute the vSphere zones across two physical sites - one vSphere zone on the first site, and two vSphere zones on the second site.  For more information, see [Requirements for Zonal Supervisor with NSX](https://docs.vmware.com/en/VMware-vSphere/8.0/vsphere-with-tanzu-concepts-planning/GUID-E95C685A-4774-4562-87AA-C6196CBB27AB.html).

##### Key Network Considerations/Requirements

This section provides key network requirements and considerations; For more information, see [Requirements for Cluster Supervisor Deployment with NSX](https://docs.vmware.com/en/VMware-vSphere/8.0/vsphere-with-tanzu-concepts-planning/GUID-B1388E77-2EEC-41E2-8681-5AE549D50C77.html)

| **Component** | **Minimum Quantity** | **Required Configuration** |
| --- | --- | --- |
| Supervisor Management Network| 1 | A management network that is routable to the ESXi hosts, vCenter Server, and load balancer. The network must be able to access an image registry and have Internet connectivity if the image registry is on the external network. The image registry must be resolvable through DNS. <br> You can make use of the existing TKGm management network or create a new one based on the requirements and IP availability of the existing network. |
| Static IPs for Kubernetes control plane VMs | Block of 5 IPs | A block of 5 consecutive static IP addresses is to be assigned from the management network to the Kubernetes control plane VMs in the Supervisor Cluster. |
| Management network VLAN/CIDR | 1 | This must be a VLAN-backed network. The management network CIDR should be of size (min) /28 |
| NSX ALB Management Network | 1 | This is the network where the NSX Advanced Load Balancer controller nodes will be placed. Any existing network can be used, or a new network can be created based on the requirements and IP availability of the existing network. This network can be both a VLAN-backed network and an overlay network. |
| Service Engine Management Network | 1 | A new overlay network must be created in NSX and associated with the Overlay Transport Zone. A dedicated Tier-1 router also needs to be created in NSX. <br> This network should be reachable from the NSX ALB controller management network. |
| Kubernetes services CIDR range | /16 Private IP addresses | A private CIDR range to assign IP addresses to Kubernetes services. You must specify a unique Kubernetes services CIDR range for each Supervisor Cluster. |
| vSphere Pod CIDR range | /23 Private IP address | A private CIDR range that provides IP addresses for vSphere Pods. These addresses are also used for the Tanzu Kubernetes Grid cluster nodes. You must specify a unique vSphere Pod CIDR range for each cluster.  <br> **Note:** The vSphere Pod CIDR and Service CIDR ranges must not overlap. |
| Egress CIDR range | /27 Static IP Addresses | A private CIDR to determine the egress IP for Kubernetes services. Only one egress IP address is assigned for each namespace in the Supervisor. The egress IP is the address that external entities use to communicate with the services in the namespace. <br> The number of egress IP addresses limits the number of egress policies the Supervisor can have. <br> The Egress subnet CIDR is dependent on the number of Egresses SBI wants to use. <br> **Note:** Egress and ingress IP addresses must not overlap. |
| Ingress CIDR | /26 Static IP Addresses | A private CIDR range to be used for IP addresses of ingresses. Ingress lets you apply traffic policies to requests entering the Supervisor from external networks. <br> The number of ingress IP addresses limits the number of ingresses the cluster can have. Ingress subnet CIDR is dependent on the number of ingresses that SBI wants to use. <br> **Note:** Egress and ingress IP addresses must not overlap. |
| Data Network Subnet | 1 | This network must not be created manually and configured in NSX ALB. The supervisor uses the IP address from the Ingress CIDR to assign the load balancer IP to the K8 objects. |


#### Supervisor Deployment with NSX Advanced Load Balancer and NSX Networking

In a Supervisor environment that uses NSX as the networking stack, you can use the NSX Advanced Load Balancer for load balancing services. We recommend that any new TKG setups incorporating NSX within the infrastructure proceed with this option. This approach offers network segregation at the Supervisor Namespace level, utilises Distributed Firewall (DFW), employs overlays for East-West communication, and utilises other NSX-T functionalities. 

You can distribute vSphere zones across different physical sites as long as the latency between the sites doesn't exceed 100 ms. For example, you can distribute the vSphere zones across two physical sites - one vSphere zone on the first site, and two vSphere zones on the second site. For more information on Requirements for Zonal Supervisor with NSX and NSX Advanced Load Balancer, see [VMware Tanzu Documentation](https://docs.vmware.com/en/VMware-vSphere/8.0/vsphere-with-tanzu-concepts-planning/GUID-DA06BCAC-EB07-45B1-BDBB-3DEF2D831CC5.html).

Key Points with this approach
1. NSX ALB must be 22.1.X; refer to the VMware compatibility matrix depending on the finalised vSphere version.
1. NSX ALB must be configured with the NSX-T cloud. 
1. Only the Default-Cloud and Default SE group can be used.

##### Key Network Considerations/Requirements

This section provides key network requirements and considerations; For more information, see [Requirements for Cluster Supervisor Deployment with NSX and NSX Advanced Load Balancer](https://docs.vmware.com/en/VMware-vSphere/8.0/vsphere-with-tanzu-concepts-planning/GUID-55DFA68B-9FA5-4A48-93A5-C3FCD15EF27D.html)


| **Component** | **Minimum Quantity** | **Required Configuration** |
| --- | --- | --- |
| Supervisor Management Network| 1 | A management network that is routable to the ESXi hosts, vCenter Server, and load balancer. The network must be able to access an image registry and have Internet connectivity if the image registry is on the external network. The image registry must be resolvable through DNS. <br> You can make use of the existing TKGm management network or create a new one based on the requirements and IP availability of the existing network. |
| Static IPs for Kubernetes control plane VMs | Block of 5 IPs | A block of 5 consecutive static IP addresses is to be assigned from the management network to the Kubernetes control plane VMs in the Supervisor Cluster. |
| Management network VLAN/CIDR | 1 | This must be a VLAN-backed network. The management network CIDR should be of size (min) /28 |
| NSX ALB Management Network | 1 | This is the network where the NSX Advanced Load Balancer controller nodes will be placed. Any existing network can be used, or a new network can be created based on the requirements and IP availability of the existing network. This network can be both a VLAN-backed network and an overlay network. |
| Service Engine Management Network | 1 | A new overlay network must be created in NSX and associated with the Overlay Transport Zone. A dedicated Tier-1 router also needs to be created in NSX. <br> This network should be reachable from the NSX ALB controller management network. |
| Kubernetes services CIDR range | /16 Private IP addresses | A private CIDR range to assign IP addresses to Kubernetes services. You must specify a unique Kubernetes services CIDR range for each Supervisor Cluster. |
| vSphere Pod CIDR range | /23 Private IP address | A private CIDR range that provides IP addresses for vSphere Pods. These addresses are also used for the Tanzu Kubernetes Grid cluster nodes. You must specify a unique vSphere Pod CIDR range for each cluster.  <br> **Note:** The vSphere Pod CIDR and Service CIDR ranges must not overlap. |
| Egress CIDR range | /27 Static IP Addresses | A private CIDR to determine the egress IP for Kubernetes services. Only one egress IP address is assigned for each namespace in the Supervisor. The egress IP is the address that external entities use to communicate with the services in the namespace. <br> The number of egress IP addresses limits the number of egress policies the Supervisor can have. <br> The Egress subnet CIDR is dependent on the number of Egresses SBI wants to use. <br> **Note:** Egress and ingress IP addresses must not overlap. |
| Ingress CIDR | /26 Static IP Addresses | A private CIDR range to be used for IP addresses of ingresses. Ingress lets you apply traffic policies to requests entering the Supervisor from external networks. <br> The number of ingress IP addresses limits the number of ingresses the cluster can have. Ingress subnet CIDR is dependent on the number of ingresses that SBI wants to use. <br> **Note:** Egress and ingress IP addresses must not overlap. |
| Data Network Subnet | 1 | This network must not be created manually and configured in NSX ALB. The supervisor uses the IP address from the Ingress CIDR to assign the load balancer IP to the K8 objects. |


### Network limitation with TKGs:

- Multi nic configuration for K8s node with Multus CNI is not supported with TKGs
- TKGm supports multiple Cloud configurations and Service Engine groups, whereas TKGs supports only default Cloud.
- vSphere with Tanzu only supports the Default-Group Service Engine. You cannot create other Service Engine Groups
- TKGm supports using separate Data VIP Networks for Management cluster and workload cluster, however TKGs supports a single Data VIP Network.

## vSphere with Tanzu Preparation Overview

The ultimate goal being Applications hosted on vSphere with Tanzu environment, it is vital to consider the preparation of the vSphere with Tanzu environment to be promoted to the production environment.

This process has to be aligned with the internal teams on the procedure approvals and approvals on the deployment of vSphere with Tanzu environment. 

This section addresses the scenarios where the bringup of vSphere with Tanzu could be adopted and covers the critical aspects to be noted during the deployment. There are two main scenarios where the vSphere with Tanzu environment could be deployed:

1. An entirely new TKGS environment to be provisioned on a different infrastructure.
    1. Configurations on Datacenter, Network, Storage to be completed.
    1. Enable TKGS and Workload cluster deployment.
    1. Onboard Application with the features and microservices integration
    1. Downtime planning of TKGm production applications. 
    1. Bringup of Application on TKGS as production point. 
1. Utilization of current TKGm infrastructure to deploy TKGS.
    1. In Pre-Prod or UAT environments, the environment of TKGm is utilised for deploying TKGs.
    1. TKGS will require vibs to be pushed to the ESXi hosts to enable WCP
    1. If AVI is being used on TKGm, then:
        - Usage of AVI will be needing to add the same vCenter instance to default cloud. 
        - Implementation of IPAM/DNS on AVI for TKGS
        - SEGroups to be differentiated between TKGS and TKGm deployments.
    1. Enable TKGS and Workload cluster deployment.
    1. Onboard Application with the features and microservices integration
    1. Downtime planning of TKGm production applications. 
    1. Bringup of Application on TKGS as production point. 


## Backup Procedure Overview

Once the vSphere environment is planned for TKGS bringup,  Backup procedure to be followed through before proceeding on the migration process.

Backup Procedure of the following components are critical following the best practices respectively:
- Backup of vCenter
- Backup of TKGm clusters
- Backup of AVI  / Backup of NSX-T
- Backup of Application 

## Summarised Comparison of TKGm and TKGS Feature parity

| **Aspect** | **Tanzu Kubernetes Grid Multicloud TKGm** | **vSphere with Tanzu TKGS**|
| --- | --- | --- |
| High Level Overview | Consistent multi-cloud experience, with flexible deployment options. | Native and Best in class integrated experience with vSphere. |
| LCM Control Plane |  Standalone management cluster is a management cluster that runs as dedicated VMs to support TKG on multiple cloud infrastructures | Supervisor cluster, is a management cluster that is deeply integrated into vSphere with Tanzu|
| General Aspects | A unified experience across any infrastructure <br>  More customizable cluster configurations such as tuning the api-server, kubelet flags, cni choice, etc. <br> IPv6-only networking environment on vSphere, Lightweight Kube-Vip support, and no dependency on NSX. <br>  Full lifecycle management and integration with TMC. CIS Benchmark inspection by TMC <br> Workload cluster autoscaling. <br>  Authentication is optional but can be integrated with an OIDC/LDAP endpoint. <br>  Additional FIPS 140-2 compliant binaries and Photon OS STIGs available. <br> ROBO/Edge use cases with a small number (1 or 2) of ESXi hosts | A tight integration with vSphere 7+ and provides native use of vSphere components. <br> Manage VMs, vSphere Pods, and Kubernetes clusters through a common API and toolset. <br> Can utilize existing investments in NSX-T. <br> Full lifecycle management and integration with TMC. CIS Benchmark inspection by TMC. <br> Uses the vSphere catalog feature to automatically download new images of Photon or Ubuntu. <br>  Authentication is natively done with vSphere SSO and Pinniped. <br> Tenancy model is enforced using vSphere Namespace. <br> |
| Integration with Tanzu Mission Control| Full Lifecycle management for Workload Clusters by TMC  | Full Lifecycle management for Guest Clusters by TMC | 
| KubernetesVersions | One Supervisor cluster could support 3 Kubernetes versions for guest clusters | One management cluster could support 3 Kubernetes versions for workload clusters |
| Kubernetes Node OS and Container Runtime| vSphere: Photon OS, Ubuntu 20.04 <br> AWS: Amazon Linux 2, Ubuntu 20.04 <br> Azure: Ubuntu 18.04, Ubuntu 20.04 <br> OS Customization by BOYI Containerd as runtime in workload clusters | OS: Photon OS / Ubuntu <br> Containerd as runtime in workload clusters <br> vSphere Pod Service in supervisor when used with NSX-T |
| Cluster Upgrade  | Upgrade the management cluster then upgrade the workload clusters  <br> upgrade TKG without being tied to the vCenter version or via Tanzu Mission Control | vCenter upgrades will upgrade the supervisor and can also trigger workload cluster upgrades or via Tanzu Mission Control |
| Multi-AZ | workload clusters that run in multiple availability zones (AZs) | Support 3 Availability Zone (vSphere Clusters) in TKG 2.0. Supervisor and Guest cluster spread to 3 vSphere Clusters.|
| Storage CSI Driver  | vSphere CSI |pvCSI (compatible with any vSphere datastore) | 
| Pod Networking | Antrea, Calico, or secondary Multus CNI | Antrea or Calico for Tanzu Kubernetes clusters (TKC) <br> NSX-T/VDS for vSphere Pod Service |
| LB options | NSX-ALB, NSX-T, HAProxy, or F5 for vSphere, AWS ELB for AWS, and Azure Load Balancer for Azure | NSX-ALB, NSX-T |
| Pod L7 LB | Contour <br> NSX-ALB Enterprise | Contour <br> NSX-ALB Enterprise |
| Workload backup and restore  | Velero for workload clusters | Velero for workload clusters |
