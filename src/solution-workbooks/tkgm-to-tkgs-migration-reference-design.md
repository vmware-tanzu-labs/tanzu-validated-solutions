# Reference Design for Migration from TKGm to TKGs (vSphere with Tanzu)

With the proposed roadmap on Tanzu Kubernetes Grid with a Management Cluster (informally known as TKGm) continuity, existing customers need to have a mechanism to migrate to Tanzu Kubernetes Grid Service (part of vSphere with Tanzu, informally known as TKGs) to retain the business continuity. The mechanism should enable seamless migration of Core Applications, utilizing their existing Infrastructure, Storage, Network, Security Policies, RBAC, and Authentication policies. The mechanism should also address very minimal or no additional purchase of software and solutions but utilize the existing solutions offerings from VMware.

## Intended Audience

This document is intended for individuals and teams involved in planning, designing, implementing, and managing the current Tanzu Kubernetes Grid infrastructure. The audience includes the following roles:
- Project executive sponsor
- Virtualization architects
- Business decision makers
- Architects and planners responsible for driving architecture-level decisions
- Core technical teams, such as product development, server, storage, networking, security, backup and recovery, and application support teams
- IT operations teams (VMware Resident Engineers), responsible for day-to-day operations of the new solution to be deployed and managed

> **Note** It is assumed that the end user has knowledge and familiarity with Virtualization, Kubernetes (Tanzu/TKG), and related topics including compute, storage, and networking.


## Overview of the Process

The following are the main steps to plan migration from TKGm to vSphere with Tanzu:

1. Prepare the migration checklist. 
1. Prepare the vSphere with Tanzu environment.
1. Plan and prepare for the downtime.

## Checklist Overview

Before starting the migration, you must understand the requirements of the customers. This provides a clear understanding of the order of the migration. These requirements are majorly classified in the following aspects:

### End Application Requirement

You must ensure that customer's production applications continue to operate post migration. Also, ensure that the applications continue to use the features and requirements. These requirements are explained in the following table:

|**Aspect**|**Checklist (to be collected from the TKGm environment**)|
| --- | --- |
|Security policies, Access policies|List any existing policies present|
|Network Policies like LB|List network policies at present in place|
|Registry integrations|The registry that is at present in use in the environment|
|Database/Microservices integration|List of the integration with any Specific data services|
|Application Scalability|Details about the application architecture|
|Application utilizing specific tools, such as csi drivers|List of any required specific tool support|
|Microservices access from other instances, such as NPC|Details about the application architecture|
|Air-Gapped availability of the application|Internet restricted app or public facing app|
|Application downtime <br> SaaS Integration for application <br> AI/ML usage |The downtime that can be sustained while migration|


## Detailed Comparison overview of TKGm and TKGs

Once you have prepared the above checklist, refer to the following comparison between TKGM and TKGs to make sure all features required are present in TKGs.

### Datacenter Overview

TKGm and TKGs overview at the datacenter level is described in the following table:

|**TKGm**|**TKGs**|
| --- | --- |
|Recommended for customers with specific use cases on Edge Telco. <br> Supports TKG 2.5 Standalone management cluster.| Recommended for vSphere 7 or 8 environment (Supports TKG 2.2 Supervisor cluster). |
| Works with Single host in the vSphere environments | Three hosts are required to deploy TKGs at a minimum. |
| Supports Host based or cluster based multi-zone topology for workload clusters. | Supports three-zone Supervisor cluster level deployment from vSphere 8.0. |
| TKGm and TKGs coexist in the same datacenter. For more information, see [here](https://williamlam.com/2021/06/can-i-deploy-both-tanzu-kubernetes-grid-tkg-and-vsphere-with-tanzu-on-same-vsphere-cluster.html). <br> However, officially it is not recommended to have both TKGm and TKGs supervisor and management clusters in the same environment. | TKGs supervisor cluster can be leveraged along with tanzu CLI to deploy TKG workload clusters. |
| Does not support vSphere pods.|Supports vSphere pods.|
| Requires TKR OVA template in the vSphere environment. | Use the subscribed content library for deployment. |
| Supports Windows MultiOS cluster in non air-gapped environment. | There is no support for Windows based MultiOS clusters. |
| Authentication occurs through integration with OIDC/LDAP endpoint. | Authentication occurs with vSphere SSO and Pinniped. |
| TKR images version is dependent on TKG releases and independent of underlying vSphere environment. | At present, TKR image releases have more binding to vSphere version that is in use. To upgrade the TKR version, you must update the vSphere environment. |

### RBAC and Authentication

|**TKGm**|**TKGs**|
| --- | --- |
| Supports Authentication with OIDC and LDAP endpoints. | Supports vSphere SSO and Pinniped Authentication. <br> Supports External IDP.  |

### Storage Overview

The TKGm and TKGs storage comparison overview is described below:

|**TKGm**|**TKGs**|
| --- | --- |
| By Default, TKGm comes with Container Storage Interface. | By Default, TKGs comes with Container Storage Interface. |
| The CSI Components run as pods on cluster. | The CSI components run as pods on cluster. |
| Only supports External Tree storage provider. Does not support in-tree storage provider. | Only supports External Tree Storage provider. Does not support in-tree storage provider. |
| Supports vSphere Cloud Native Storage (CNS), iSCSI, NFS, and FC storage types. | Supports vSphere Cloud Native Storage (CNS), iSCSI, NFS, and FC storage types. |
| The storage usage depends on the underlying infrastructure (datastore). | Uses the vSphere storage based policy. |


The multi-zone storage requirements for TKGm and TKGs are listed below:

|**TKGm**|**TKGs(Multi zone cluster supported on vSphere 8.0)**|
| --- | --- |
| Storage Across host-based or cluster-based zones don't have any specific limitations and can be of any type, such as Cloud Native Storage (CNS), iSCSI, and NFS.| Storage Across three zones of supervisor can be of different types like VMFS for Zone 1 , vSAN for Zone 2. However, it is recommended to have the same type of storage across zones to achieve consistency.|
|| Storage policy used for namespace must be compliant with shared storage across zones and must be topology aware. |
|| Local datastores to a single zone should not be mounted to other zones. |
|| Doesn't support three-zone supervisor:<br> - Cross-zonal volumes. <br> - vSAN file volumes (ReadWriteMany Volumes). <br> - Static volume provisioning using the register volume API. <br> -  Workloads that use vSAN data Persistence platform. <br> -  vSAN Stretched cluster. <br> - VMs with vGPU and instance storage. |

### Networking Overview

This section provides a network overview for TKG clusters deployed with Supervisor (TKGs) and Standalone Management Cluster (TKGm).

| | **Tanzu Kubernetes Grid** <br> (TKG with Management Cluster)| **vSphere with Tanzu** <br> (TKG with Supervisor Cluster)  |
| --- | --- | --- |
| Network topology | Tanzu Kubernetes Grid on vSphere with vSphere networking. <br> Tanzu Kubernetes Grid on vSphere with NSX-T networking.  <br> For more information, see [here](https://techdocs.broadcom.com/us/en/vmware-tanzu/reference-architectures/tanzu-for-kubernetes-operations-reference-architecture/2-3/tko-ref-arch/tko-vsphere-section.html). | Supervisor networking with VDS. <br> Supervisor Networking with NSX. <br> Supervisor networking with NSX and NSX Advanced Load Balancer (applicable for vSphere 8.0U2 or later, NSX 4.1.1 or later, NSX ALB 22.1.4 or later). <br> For more information, see [here](https://techdocs.broadcom.com/us/en/vmware-cis/vsphere/vsphere-supervisor/8-0/vsphere-iaas-control-plane-concepts-and-planning-8-0/supervisor-architecture-and-components/supervisor-networking.html). |
| Pod networking | Antrea, Calico, or secondary Multus CNI | Antrea or Calico for Tanzu Kubernetes clusters (TKC). <br> NSX-T/VDS for vSphere Pod Service. |
| Control plane LB options | Kube-vip <br> NSX-ALB | NSX-ALB <br> HA Proxy <br> NSX-T |
| Application LB (L4) | NSX-ALB <br> Other networking providers like MetalLB, HA Proxy, F5 LB etc | NSX-ALB <br> NSX-T|
| Application LB (L7) | Contour <br> NSX ALB Enterprise | Contour <br> NSX ALB Enterprise |


### Application Overview

The application overview depends on various applications that are deployed in the customer environment on current TKG infrastructure.


## TKGs Migration Planning/Suggestions

There is no migration tool available at this moment. Also, the vSphere version that will support TKGm to TKGs migration is unknown at the moment.
The following topics provide an overview of key considerations that must be taken into account and planned accordingly:

### Resource Planning

- Enabling WCP on a vSphere cluster demands careful attention to resource planning. 
- Thorough resource planning is essential for the new supervisor plane components and new TKCs, and the sizing of the control plane and worker nodes needs to be taken into account.
- Resource planning must also ensure that both the TKGm and TKGs environments can operate in parallel until all applications are successfully migrated to the TKGs environment, and all application traffic is seamlessly switched over to the new environment.

### Network Planning

Generally, there are three supported models of Supervisor deployment:
1. Supervisor deployment with VDS Networking.
1. Supervisor deployment with NSX Networking.
1. Supervisor deployment with NSX Advanced Load Balancer and NSX Networking.

> **Note** Support for the NSX Advanced Load Balancer for a Supervisor configured with NSX networking is only available in vCenter 8.0u2 and later, NSX 4.1.1 or later, and NSX ALB 22.1.4 or later .

#### Supervisor Deployment with VDS Networking

In a Supervisor that is backed by VDS as the networking stack, all hosts from the vSphere clusters backing the Supervisor must be connected to the same VDS. The Supervisor uses distributed port groups as workload networks for Kubernetes workloads and control plane traffic. You assign workload networks to namespaces in the Supervisor.

Depending on the topology that you implement for the Supervisor, you can use one or more distributed port groups as workload networks. The network that provides connectivity to the Supervisor control plane VMs is called the Primary workload network. You can assign this network to all the namespaces on the Supervisor, or you can use different networks for each namespace. The Tanzu Kubernetes Grid clusters connect to the Workload Network that is assigned to the namespace where the clusters reside.

- NSX Advanced Load Balancer or the HAProxy load balancer provides L4 LoadBalancing services for control planes.
- In NSX ALB, only the Default-Cloud and Default SE group can be used.
- AKO must be deployed manually for each TKC to leverage L7 functionalities.
- The CIDR block for `Internal Network for Kubernetes Services` needs to be specified, with a minimum size /23. This list of IPs is used to allocate Kubernetes services of type ClusterIP. These IP addresses are internal to the cluster, but should not conflict with any other IP range.
- In a three-zone Supervisor, you deploy the Supervisor on three vSphere zones, each mapped to a vSphere cluster. All hosts from these vSphere clusters must be connected to the same VDS. All physical servers must be connected to an L2 device.

##### Key Network Considerations/Requirements

This section provides key network requirements and considerations. For more information, see [Requirements for Cluster Supervisor Deployment with NSX Advanced Load Balancer and VDS Networking](https://techdocs.broadcom.com/us/en/vmware-cis/vsphere/vsphere-supervisor/8-0/vsphere-iaas-control-plane-concepts-and-planning-8-0/requirements-for-enabling-a-single-cluster-supervisor/requirements-for-cluster-supervisor-deployment-with-nsx-advanced-load-balancer-and-vds-networking.html).

| **Component** | **Minimum Quantity** | **Required Configuration** |
| --- | --- | --- |
| Supervisor Management Network | 1 | A Management Network that is routable to the ESXi hosts, vCenter Server, the Supervisor Cluster, and load balancer. The network must be able to access an image registry and have Internet connectivity if the image registry is on the external network. The image registry must be resolvable through DNS. <br> You can make use of the existing TKGm Management Network or create a new one based on the requirements and IP availability on the existing network. <br> If needed, NSX ALB can be deployed on the same network. |
| Static IPs for Kubernetes control plane VMs | Block of 5 IPs | A block of 5 consecutive static IP addresses is to be assigned from the Supervisor Management Network to the Kubernetes control plane VMs in the Supervisor cluster. |
| Kubernetes services CIDR range | /16 Private IP addresses | A private CIDR range to assign IP addresses to Kubernetes services. You must specify a unique Kubernetes services CIDR range for each Supervisor cluster. |
| Workload Network  | 1 | At least one distributed port group must be created on the vSphere Distributed Switch that you configure as the Primary Workload Network. Depending on the topology of choice, you can use the same distributed port group as the Workload Network of namespaces or create more port groups and configure them as Workload Networks. Workload Networks must meet the following requirements: <br> - Workload Networks that are used for Tanzu Kubernetes cluster traffic must be routable between each other and the Supervisor Cluster Primary Workload Network. Routability between any Workload Network with the network that the NSX Advanced Load Balancer uses for virtual IP allocation.  <br> - No overlapping of IP address ranges across all Workload Networks within a Supervisor cluster. |
| NSX ALB Management Network  | 1 | The Management Network is where the Avi Controller, also called the Controller, resides. <br> It is also where the Service engine’s management interface is connected. The Avi Controller must be reachable to the vCenter Server and ESXi management IPs from this network. <br> This network is not required if you deploy NSX ALB on the Supervisor Management Network or existing infrastructure management network. |
| VIP Network Subnet | 1 | The data interface of the Avi Service Engines connects to this network. Configure a pool of IP addresses for the Service Engines. The load balancer Virtual IPs (VIPs) are assigned from this network. |
| VIP IPAM range | N/A | A private CIDR range to assign IP addresses to Kubernetes services. The IPs must be from the data network subnet. You must specify a unique Kubernetes services CIDR range for each Supervisor cluster. |


#### Supervisor Deployment with NSX Networking

A Supervisor that is configured with NSX, uses the software-based networks of the solution and an NSX Edge Load Balancer to provide connectivity to external services and DevOps users.  Review the system requirements for configuring vSphere with Tanzu on a vSphere cluster by using the NSX networking stack. For more information, see [Requirements for Cluster Supervisor Deployment with NSX](https://techdocs.broadcom.com/us/en/vmware-cis/vsphere/vsphere-supervisor/8-0/vsphere-iaas-control-plane-concepts-and-planning-8-0/requirements-for-enabling-a-single-cluster-supervisor/requirements-for-cluster-supervisor-deployment-with-nsx.html).

You can distribute vSphere zones across different physical sites as long as the latency between the sites doesn't exceed 100 ms. For example, you can distribute the vSphere zones across two physical sites - one vSphere zone on the first site, and two vSphere zones on the second site.  For more information, see [Requirements for Zonal Supervisor with NSX](https://techdocs.broadcom.com/us/en/vmware-cis/vsphere/vsphere-supervisor/8-0/vsphere-iaas-control-plane-concepts-and-planning-8-0/requirements-for-enabling-a-single-cluster-supervisor/requirements-for-cluster-supervisor-deployment-with-nsx.html).

##### Key Network Considerations/Requirements

This section provides key network requirements and considerations; For more information, see [Requirements for Cluster Supervisor Deployment with NSX](https://techdocs.broadcom.com/us/en/vmware-cis/vsphere/vsphere-supervisor/8-0/vsphere-iaas-control-plane-concepts-and-planning-8-0/requirements-for-enabling-a-single-cluster-supervisor/requirements-for-cluster-supervisor-deployment-with-nsx.html).

| **Component** | **Minimum Quantity** | **Required Configuration** |
| --- | --- | --- |
| Supervisor Management Network| 1 | A management network that is routable to the ESXi hosts, vCenter Server, and load balancer. The network must be able to access an image registry and have Internet connectivity if the image registry is on the external network. The image registry must be resolvable through DNS. <br> You can make use of the existing TKGm management network or create a new one based on the requirements and IP availability of the existing network. |
| Static IPs for Kubernetes control plane VMs | Block of 5 IPs | A block of 5 consecutive static IP addresses is to be assigned from the management network to the Kubernetes control plane VMs in the Supervisor Cluster. |
| Management network VLAN/CIDR | 1 | This must be a VLAN-backed network. The management network CIDR should be of size (min) /28 |
| NSX ALB Management Network | 1 | This is the network where the NSX Advanced Load Balancer controller nodes will be placed. Any existing network can be used, or a new network can be created based on the requirements and IP availability of the existing network. This network can be both a VLAN-backed network and an overlay network. |
| Service Engine Management Network | 1 | A new overlay network must be created in NSX and associated with the Overlay Transport Zone. A dedicated Tier-1 router also needs to be created in NSX. <br> This network should be reachable from the NSX ALB controller management network. |
| Kubernetes services CIDR range | /16 Private IP addresses | A private CIDR range to assign IP addresses to Kubernetes services. You must specify a unique Kubernetes services CIDR range for each Supervisor Cluster. |
| vSphere Pod CIDR range | /23 Private IP address | A private CIDR range that provides IP addresses for vSphere Pods. These addresses are also used for the Tanzu Kubernetes Grid cluster nodes. You must specify a unique vSphere Pod CIDR range for each cluster.  <br> **Note**: The vSphere Pod CIDR and Service CIDR ranges must not overlap. |
| Egress CIDR range | /27 Static IP Addresses | A private CIDR to determine the egress IP for Kubernetes services. Only one egress IP address is assigned for each namespace in the Supervisor. The egress IP is the address that external entities use to communicate with the services in the namespace. <br> The number of egress IP addresses limits the number of egress policies the Supervisor can have. <br> The Egress subnet CIDR is dependent on the number of Egresses SBI wants to use. <br> **Note**: Egress and ingress IP addresses must not overlap. |
| Ingress CIDR | /26 Static IP Addresses | A private CIDR range to be used for IP addresses of ingresses. Ingress lets you apply traffic policies to request entering the Supervisor from external networks. <br> The number of ingress IP addresses limits the number of ingresses the cluster can have. Ingress subnet CIDR is dependent on the number of ingresses that the end user wants to use. <br> **Note:** Egress and ingress IP addresses must not overlap. |
| Data Network Subnet | 1 | This network must not be created manually and configured in NSX ALB. The supervisor uses the IP address from the Ingress CIDR to assign the load balancer IP to the K8 objects. |


#### Supervisor Deployment with NSX Advanced Load Balancer and NSX Networking

In a Supervisor environment that uses NSX as the networking stack, you can use the NSX Advanced Load Balancer for load balancing services. We recommend that any new TKG setup incorporating NSX within the infrastructure, might use this approach. This approach offers network segregation at the Supervisor Namespace level, utilises Distributed Firewall (DFW), employs overlays for East-West communication, and utilizes other NSX-T functionalities. 

You can distribute vSphere zones across different physical sites as long as the latency between the sites doesn't exceed 100 ms. For example, you can distribute the vSphere zones across two physical sites - one vSphere zone on the first site, and two vSphere zones on the second site. For more information on Requirements for Zonal Supervisor with NSX and NSX Advanced Load Balancer, see [VMware Tanzu Documentation](https://techdocs.broadcom.com/us/en/vmware-cis/vsphere/vsphere-supervisor/8-0/vsphere-iaas-control-plane-concepts-and-planning-8-0/requirements-for-enabling-a-single-cluster-supervisor/requirements-for-cluster-supervisor-deployment-with-nsx-and-nsx-advanced-load-balancer.html).

Key Points with this approach
1. NSX ALB must be 22.1.X; refer to the VMware compatibility matrix depending on the finalised vSphere version.
1. NSX ALB must be configured with the NSX-T cloud. 
1. Only the Default-Cloud and Default SE group can be used.

##### Key Network Considerations/Requirements

This section provides key network requirements and considerations. For more information, see [Requirements for Cluster Supervisor Deployment with NSX and NSX Advanced Load Balancer](https://techdocs.broadcom.com/us/en/vmware-cis/vsphere/vsphere-supervisor/8-0/vsphere-iaas-control-plane-concepts-and-planning-8-0/requirements-for-enabling-a-single-cluster-supervisor/requirements-for-cluster-supervisor-deployment-with-nsx-and-nsx-advanced-load-balancer.html).


| **Component** | **Minimum Quantity** | **Required Configuration** |
| --- | --- | --- |
| Supervisor Management Network| 1 | A management network that is routable to the ESXi hosts, vCenter Server, and load balancer. The network must be able to access an image registry and have Internet connectivity if the image registry is on the external network. The image registry must be resolvable through DNS. <br> You can make use of the existing TKGm management network or create a new one based on the requirements and IP availability of the existing network. |
| Static IPs for Kubernetes control plane VMs | Block of 5 IPs | A block of 5 consecutive static IP addresses is to be assigned from the management network to the Kubernetes control plane VMs in the Supervisor Cluster. |
| Management network VLAN/CIDR | 1 | This must be a VLAN-backed network. The management network CIDR should be of size (min) /28 |
| NSX ALB Management Network | 1 | This is the network where the NSX Advanced Load Balancer controller nodes will be placed. Any existing network can be used, or a new network can be created based on the requirements and IP availability of the existing network. This network can be both a VLAN-backed network and an overlay network. |
| Service Engine Management Network | 1 | A new overlay network must be created in NSX and associated with the Overlay Transport Zone. A dedicated Tier-1 router also needs to be created in NSX. <br> This network should be reachable from the NSX ALB controller management network. |
| Kubernetes services CIDR range | /16 Private IP addresses | A private CIDR range to assign IP addresses to Kubernetes services. You must specify a unique Kubernetes services CIDR range for each Supervisor Cluster. |
| vSphere Pod CIDR range | /23 Private IP address | A private CIDR range that provides IP addresses for vSphere Pods. These addresses are also used for the Tanzu Kubernetes Grid cluster nodes. You must specify a unique vSphere Pod CIDR range for each cluster.  <br> **Note**: The vSphere Pod CIDR and Service CIDR ranges must not overlap. |
| Egress CIDR range | /27 Static IP Addresses | A private CIDR to determine the egress IP for Kubernetes services. Only one egress IP address is assigned for each namespace in the Supervisor. The egress IP is the address that external entities use to communicate with the services in the namespace. <br> The number of egress IP addresses limits the number of egress policies the Supervisor can have. <br> The Egress subnet CIDR is dependent on the number of Egresses SBI wants to use. <br> **Note**: Egress and ingress IP addresses must not overlap. |
| Ingress CIDR | /26 Static IP Addresses | A private CIDR range to be used for IP addresses of ingresses. Ingress lets you apply traffic policies to requests entering the Supervisor from external networks. <br> The number of ingress IP addresses limits the number of ingresses the cluster can have. Ingress subnet CIDR is dependent on the number of ingresses that the end user wants to use. <br> **Note**: Egress and ingress IP addresses must not overlap. |
| Data Network Subnet | 1 | This network must not be created manually and configured in NSX ALB. The supervisor uses the IP address from the Ingress CIDR to assign the load balancer IP to the K8 objects. |


### Network limitation with TKGs

- Multi-NIC configuration for K8s node with Multus CNI is not supported with TKGs.
- TKGm supports multiple Cloud configurations and Service Engine groups, whereas TKGs supports only default Cloud.
- vSphere with Tanzu only supports the Default-Group Service Engine. You cannot create other Service Engine Groups.
- TKGm supports using separate Data VIP Networks for Management cluster and workload cluster. However, TKGs supports a single Data VIP Network.

## vSphere with Tanzu Preparation Overview

Ensuring the seamless transition of applications onto a vSphere with Tanzu environment requires careful preparation of the environment before promotion to production.

This procedure must align with internal teams for approval processes and deployment of the vSphere with Tanzu environment. 

This section explores the potential scenarios for implementing vSphere with Tanzu and highlights essential considerations for deployment. There are two primary deployment scenarios for the vSphere with Tanzu environment:

1. An entirely new TKGs environment to be provisioned on a different infrastructure:
    1. Configure Datacenter, Network, and Storage.
    1. Enable TKGs and Workload cluster deployment.
    1. Onboard Application with the features and microservices integration.
    1. Plan downtime of TKGm production applications. 
    1. Bring up the application on TKGs as production point. 
1. Utilization of current TKGm infrastructure to deploy TKGs:
    1. In pre-prod or UAT environments, the environment of TKGm is utilised for deploying TKGs.
    1. TKGs will require vibs to be pushed to the ESXi hosts to enable WCP.
    1. If AVI is being used on TKGm, then:
        - To utilize AVI, you'll need to integrate the same vCenter instance into the default cloud configuration. 
        - Implement IPAM/DNS on AVI for TKGs.
        - Differentiate the SE Groups between TKGs and TKGm deployments.
    1. Enable TKGs and Workload cluster deployment.
    1. Onboard application with the features and microservices integration.
    1. Plan downtime of the TKGm production applications. 
    1. Bring up of application on TKGs as production point. 


## Backup Procedure Overview

Before initiating the migration process for TKGs bringup on the vSphere environment, it's crucial to adhere to the backup procedure.

It's crucial to follow best practices and ensure the backup procedure for the following components is executed meticulously:

- Backup of vCenter
- Backup of TKGm clusters
- Backup of AVI/Backup of NSX-T
- Backup of Application

## Summarised Comparison of TKGm and TKGs Feature Parity

| **Aspect** | **Tanzu Kubernetes Grid Multicloud TKGm** | **vSphere with Tanzu TKGs**|
| --- | --- | --- |
| High Level Overview | Consistent multi-cloud experience with flexible deployment options. | Native and best-in-class integrated experience with vSphere. |
| LCM Control Plane |  Standalone management cluster is a management cluster that runs as dedicated VMs to support TKG on multiple cloud infrastructures. | Supervisor cluster is a management cluster that is deeply integrated into vSphere with Tanzu.|
| General Aspects | A unified experience across any infrastructure. <br>  More customizable cluster configurations such as tuning the API server, kubelet flags, cni choice, and so on. <br> IPv6-only networking environment on vSphere, Lightweight Kube-Vip support, and no dependency on NSX. <br>  Full lifecycle management and integration with TMC. CIS Benchmark inspection by TMC <br> Autoscaling of the Workload cluster. <br>  Authentication (optional) can be integrated with an OIDC/LDAP endpoint. <br>  Additional FIPS 140-2 compliant binaries and Photon OS STIGs are available. <br> ROBO/Edge use cases with minimum number (1 or 2) of ESXi hosts. | A seamless integration with vSphere 7+ and provides native use of vSphere components. <br> Manage VMs, vSphere Pods, and Kubernetes clusters through a common API and toolset. <br> Utilize existing investments in NSX-T. <br> Full lifecycle management and integration with TMC. CIS Benchmark inspection by TMC. <br> Uses the vSphere catalog feature to automatically download new images of Photon or Ubuntu. <br>  Authentication is natively done with vSphere SSO and Pinniped. <br> Tenancy model is enforced using vSphere Namespace. <br> |
| Integration with Tanzu Mission Control| Full Lifecycle management for Workload Clusters by TMC.  | Full Lifecycle management for Guest Clusters by TMC. | 
| Kubernetes Versions | One Supervisor cluster supports 3 Kubernetes versions for guest clusters. | One management cluster supports 3 Kubernetes versions for workload clusters. |
| Kubernetes Node OS and Container Runtime| vSphere: Photon OS, Ubuntu 20.04 <br> AWS: Amazon Linux 2, Ubuntu 20.04 <br> Azure: Ubuntu 18.04, Ubuntu 20.04 <br> OS Customization by BOYI Containerd as runtime in workload clusters. | OS: Photon OS / Ubuntu <br> Containerd as runtime in workload clusters. <br> vSphere Pod Service in supervisor when used with NSX-T. |
| Cluster Upgrade  | Upgrade the management cluster then upgrade the workload clusters.  <br> Upgrade TKG without being tied to the vCenter version or via Tanzu Mission Control. | vCenter upgrades will upgrade the supervisor and can also trigger workload cluster upgrades or via Tanzu Mission Control. |
| Multi-AZ | workload clusters that run in multiple availability zones (AZs). | Support 3 Availability Zone (vSphere Clusters) in TKG 2.0. Supervisor and Guest cluster spread to 3 vSphere Clusters.|
| Storage CSI Driver  | vSphere CSI |pvCSI (compatible with any vSphere datastore). | 
| Pod Networking | Antrea, Calico, or secondary Multus CNI. | Antrea or Calico for Tanzu Kubernetes clusters. (TKC) <br> NSX-T/VDS for vSphere Pod Service. |
| LB options | NSX-ALB, NSX-T, HAProxy, or F5 for vSphere, AWS ELB for AWS, and Azure Load Balancer for Azure. | NSX-ALB, NSX-T |
| Pod L7 LB | Contour <br> NSX-ALB Enterprise | Contour <br> NSX-ALB Enterprise |
| Workload backup and restore  | Velero for workload clusters. | Velero for workload clusters. |
