
# Overview
VMware Tanzu for Kubernetes Operations simplifies operation of Kubernetes for multi-cloud deployment by centralizing management and governance for clusters and teams across on-premises, public clouds and edge.

It delivers an open source aligned Kubernetes distribution with consistent operations and management to support infrastructure and app modernization.

This document lays out a reference architecture related for VMware Tanzu for Kubernetes Operations** when deployed on a vSphere environment backed by vSphere Networking(VDS) and offers a high-level overview of the different components.
## **Tanzu for Kubernetes Operations:** 

The following is a list of the components that comprise Tanzu for Kubernetes Operations:

- **Tanzu Kubernetes Grid (TKG)** - Enables creation and lifecycle management of Kubernetes clusters.
- **Tanzu Mission Control (TMC)** - A centralized management platform for consistently operating and securing Kubernetes infrastructure and modern applications across multiple teams and clouds, and allows for centralized policy management across all deployed and attached clusters.
- **Tanzu Observability (TO)** - Provides enterprise-grade observability and analytics at scale with granular controls, which allows to achieve higher levels of application health and availability for an overall improved end user experience
- **Tanzu Service Mesh (TSM)** - Provides end-to-end connectivity, continuity, resiliency, security, compliance, and observability for modern applications running in single and multi-cloud environments. Global Namespace can be used to leverage the power of the hybrid cloud.
- **NSX Advanced Load Balancer** - An enterprise grade integrated Load balancer, provides Layer 4 Load Balancer support, recommended for vSphere deployments without NSX-T, or when there are unique scaling requirements.
- **Tanzu User-Managed Packages:**
  - [**Cert Manager**](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.4/vmware-tanzu-kubernetes-grid-14/GUID-packages-cert-manager.html) - Provides automated certificate management. It runs by default in management clusters.
  - [**Contour**](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.4/vmware-tanzu-kubernetes-grid-14/GUID-packages-ingress-contour.html) - Provides layer 7 ingress control to deployed HTTP(S) applications. Tanzu Kubernetes Grid includes signed binaries for Contour. Deploying Contour is a prerequisite for deploying the Prometheus, Grafana, and Harbor extensions.
  - [**ExternalDNS**](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.4/vmware-tanzu-kubernetes-grid-14/GUID-packages-external-dns.html) - Publishes DNS records for applications to DNS servers. It uses a declarative Kubernetes-native interface.
  - [**Fluent Bit**](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.4/vmware-tanzu-kubernetes-grid-14/GUID-packages-logging-fluentbit.html) - Collects data and logs from different sources, unify them, and sends them to multiple destinations. Tanzu Kubernetes Grid includes signed binaries for Fluent Bit.
  - [**Prometheus**](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.4/vmware-tanzu-kubernetes-grid-14/GUID-packages-monitoring.html) - Provides out-of-the-box health monitoring of Kubernetes clusters. The Tanzu Kubernetes Grid implementation of Prometheus includes an Alert Manager. You can configure Alert Manager to notify you when certain events occur.
  - [**Grafana**](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.4/vmware-tanzu-kubernetes-grid-14/GUID-packages-monitoring.html) - Provides monitoring dashboards for displaying key health metrics of Kubernetes clusters. Tanzu Kubernetes Grid includes an implementation of Grafana.
  - [**Harbor Image Registry**](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.4/vmware-tanzu-kubernetes-grid-14/GUID-packages-harbor-registry.html) - Provides a centralized location to push, pull, store, and scan container images used in Kubernetes workloads. It supports storing artifacts such as Helm Charts and includes enterprise-grade features such as RBAC, retention policies, automated garbage clean up, and docker hub proxying.
  - **Multus CNI** - Enables attaching multiple network interfaces to pods. Multus CNI is a container network interface (CNI) plugin for Kubernetes that lets you attach multiple network interfaces to a single pod and associate each with a different address range.

Tanzu for Kubernetes Operations puts all these components together into a coherent solution as shown below:

![](img/tko-on-vsphere-vds/TKO-Ref-Arch.jpg)

Figure 1 - Tanzu for Kubernetes Operations

## **TKG Bill Of Materials**
Below is the validated Bill of Materials that can be used to install TKG on your vSphere environment today:

|**Software Components**|**Version**|
| :- | :- |
|Tanzu Kubernetes Grid|1.5.1|
|VMware vSphere ESXi|7.0 U2 |
|VMware vCenter (VCSA)|7.0 U2 and later|
|VMware vSAN|7.0 U2 and later|
|NSX Advanced LB|20.1.7|
The Interoperability Matrix can be verified at all times [here](https://interopmatrix.vmware.com/#/Interoperability?isHideGenSupported=true&isHideTechSupported=true&isHideCompatible=false&isHideIncompatible=false&isHideNTCompatible=true&isHideNotSupported=true&isCollection=false&col=551,5305&row=551,5305%262,5088,3457%26789,5823).
## **Tanzu Kubernetes Grid  components**

VMware Tanzu Kubernetes Grid (TKG) provides organizations with a consistent, upstream-compatible, regional Kubernetes substrate that is ready for end-user workloads and ecosystem integrations. You can deploy Tanzu Kubernetes Grid across software-defined datacenters (SDDC) and public cloud environments, including vSphere, Microsoft Azure, and Amazon EC2.

Tanzu Kubernetes Grid comprises of the following components:

**Management Cluster -** A management cluster is the first element that you deploy when you create a Tanzu Kubernetes Grid instance. The management cluster is a Kubernetes cluster that performs the role of the primary management and operational center for the Tanzu Kubernetes Grid instance. The management cluster is purpose-built for operating the platform and managing the lifecycle of Tanzu Kubernetes clusters.

**Cluster API -** TKG functions through the creation of a Management Kubernetes cluster which houses [Cluster API](https://cluster-api.sigs.k8s.io/). The Cluster API then interacts with the infrastructure provider to service workload Kubernetes cluster lifecycle requests.

**Tanzu Kubernetes Cluster -** Tanzu Kubernetes clusters are the Kubernetes clusters in which your application workloads run. These clusters are also referred to as workload clusters. Tanzu Kubernetes clusters can run different versions of Kubernetes, depending on the needs of the applications they run.

**Shared Service Cluster -**  Each Tanzu Kubernetes Grid instance can only have one shared services cluster. You will deploy this cluster only if you intend to deploy shared services such as Contour and Harbor. 

**Tanzu Kubernetes Cluster Plans -** A cluster plan is a blueprint that describes the configuration with which to deploy a Tanzu Kubernetes cluster. It provides a set of configurable values that describe settings like the number of control plane machines, worker machines, VM types, and so on.

This current release of Tanzu Kubernetes Grid provides two default templates, dev and prod.

**Tanzu Kubernetes Grid Instance -** A Tanzu Kubernetes Grid instance is the full deployment of Tanzu Kubernetes Grid, including the management cluster, the workload clusters, and the shared services cluster that you configure.

**Tanzu CLI -** A command-line utility that provides the necessary commands to build and operate Tanzu management and tanzu Kubernetes clusters. 

**Bootstrap Machine -** The bootstrap machine is the laptop, host, or server on which you download and run the Tanzu CLI. This is where the initial bootstrapping of a management cluster occurs before it is pushed to the platform where it will run.

**Tanzu Kubernetes Grid Installer -** The Tanzu Kubernetes Grid installer is a graphical wizard that you launch by running the tanzu management-cluster create --ui command. The installer wizard runs locally on the bootstrap machine and provides a user interface to guide you through the process of deploying a management cluster.
## **Tanzu Kubernetes Grid Storage**
Tanzu Kubernetes Grid integrates with shared datastores available in the vSphere infrastructure. The following types of shared datastores are supported:

- vSAN
- VMFS
- NFS
- vVols 

TKG Cluster Plans can be defined by operators to use a certain vSphere Datastore when creating new workload clusters. All developers would then have the ability to provision container-backed persistent volumes from that underlying datastore.

Tanzu Kubernetes Grid is agnostic about which option you choose. For Kubernetes stateful workloads, TKG installs the [vSphere Container Storage interface (vSphere CSI)](https://cloud-provider-vsphere.sigs.k8s.io/container_storage_interface.html) to automatically provision Kubernetes persistent volumes for pods. 

[VMware vSAN](https://docs.vmware.com/en/VMware-vSAN/index.html) is a recommended storage solution for deploying Tanzu Kubernetes Grid clusters on vSphere. 

|**Decision ID**|**Design Decision**|**Design Justification**|**Design Implications**|
| :- | :- | :- | :- |
|TKO-STG-001|Use vSAN storage for TKO|vSAN supports NFS volumes in ReadWriteMany access modes.|vSAN File Services need to be configured to leverage this. vSAN File Service is available only in vSAN Enterprise and Enterprise Plus editions|

While the default vSAN storage policy can be used, administrators should evaluate the needs of their applications and craft a specific [vSphere Storage Policy](https://docs.vmware.com/en/VMware-vSphere/6.7/com.vmware.vsphere.storage.doc/GUID-89091D59-D844-46B2-94C2-35A3961D23E7.html). vSAN storage policies describe classes of storage (e.g. SSD, NVME, etc.) along with quotas for your clusters.

![](img\tko-on-vsphere-vds/tko-on-vsphere-vds-2.png)

Figure 2  - TKG Storage integration example with vSAN

## **Tanzu Kubernetes Clusters Networking**
A Tanzu Kubernetes cluster provisioned by the Tanzu Kubernetes Grid supports two Container Network Interface (CNI) options: 

- [Antrea](https://antrea.io/) 
- [Calico](https://www.tigera.io/project-calico/)

Both are open-source software that provides networking for cluster pods, services, and ingress.

When you deploy a Tanzu Kubernetes cluster using Tanzu Mission Control or Tanzu CLI, Antrea CNI is automatically enabled in the cluster. 

Tanzu Kubernetes Grid also supports [Multus](https://github.com/k8snetworkplumbingwg/multus-cni) CNI which can be installed through Tanzu user-managed packages. Multus CNI lets you attach multiple network interfaces to a single pod and associate each with a different address range.

To provision a Tanzu Kubernetes cluster using a non-default CNI, please see the below instructions:

[Deploy Tanzu Kubernetes clusters with calico](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.5/vmware-tanzu-kubernetes-grid-15/GUID-tanzu-k8s-clusters-networking.html#calico)

[Implement Multiple Pod Network Interfaces with Multus](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.5/vmware-tanzu-kubernetes-grid-15/GUID-packages-cni-multus.html)

Each CNI is suitable for a different use case. The below table lists some common use cases for the three CNI’s that Tanzu Kubernetes Grid supports. This table will help you with information on selecting the right CNI in your Tanzu Kubernetes Grid implementation.

|**CNI**|**Use Case**|**Pros and Cons**|
| :- | :- | :- |
|Antrea|<p>Enable Kubernetes pod networking with IP overlay networks using VXLAN or Geneve for encapsulation. Optionally encrypt node-to-node communication using IPSec packet encryption.</p><p></p><p>Antrea supports advanced network use cases like kernel bypass and network service mesh.</p>|<p>Pros</p><p>- Provide an option to Configure Egress IP Pool or Static Egress IP for the Kubernetes Workloads.</p>|
|Calico|<p>Calico is used in environments where factors like network performance, flexibility, and power are essential.</p><p></p><p>For routing packets between nodes, Calico leverages the BGP routing protocol instead of an overlay network. This eliminates the need to wrap packets with an encapsulation layer resulting in increased network performance for Kubernetes workloads.</p>|<p>Pros</p><p>- Support for Network Policies</p><p>- High network performance</p><p>- SCTP Support</p><p>Cons</p><p>- No multicast support</p><p></p>|
|Multus|Multus CNI can give us multiple interfaces per each Kubernetes pod. Using Multus CRD's you can specify which pods get which interfaces and allow different interfaces depending on the use case.|<p>Pros</p><p>- Separation of data/control planes.</p><p>- Separate security policies can be used for separate interfaces. </p><p>- Supports SRIOV, DPDK, OVS-DPDK & VPP workloads in Kubernetes with both cloud native and NFV based applications in Kubernetes.</p>|

## **Tanzu Kubernetes Grid Infrastructure Networking**
Tanzu Kubernetes Grid on vSphere can be deployed on various networking stacks including

- VMware NSX-T Data Center Networking.
- vSphere Networking (VDS).

**Note:** The scope of this document is limited to vSphere Networking.
## **TKG on vSphere Networking with NSX ALB**
Tanzu Kubernetes Grid when deployed on the vSphere networking uses the distributed port groups to provide connectivity to Kubernetes control plane VMs, worker nodes, services, and applications. All hosts from the cluster where Tanzu Kubernetes clusters are deployed are connected to the distributed switch that provides connectivity to the Kubernetes environment. 

Tanzu Kubernetes Grid leverages NSX Advanced Load Balancer to provide L4 load balancing for the Tanzu Kubernetes Clusters Control-Plane HA and L7 ingress to the applications deployed in the Tanzu Kubernetes Clusters. Users access the applications by connecting to the Virtual IP address (VIP) of the applications provisioned by NSX ALB. 
# **NSX Advanced Load Balancer Components**
NSX ALB is deployed in Write Access Mode mode in vSphere Environment. This mode grants NSX ALB Controllers full write access to the vCenter which helps in automatically creating, modifying, and removing SEs and other resources as needed to adapt to changing traffic needs. The following are the core components of NSX ALB:

- **NSX ALB Controller** - NSX ALB Controller manages Virtual Service objects and interacts with the vCenter Server infrastructure to manage the lifecycle of the service engines (SEs). It is the central repository for the configurations and policies related to services and management and provides the portal for viewing the health of VirtualServices and SEs and the associated analytics that NSX Advanced Load Balancer provides.
- **NSX ALB Service Engine** - The Service Engines (SEs) are lightweight VMs that handle all data plane operations by receiving and executing instructions from the controller. The SEs perform load balancing and all client and server-facing network interactions.
- **Avi Kubernetes Operator (AKO)** - It is a Kubernetes operator that runs as a pod in the Supervisor Cluster and Tanzu Kubernetes clusters and provides ingress and load balancing functionality. AKO translates the required Kubernetes objects to NSX ALB objects and automates the implementation of ingresses/routes/services on the Service Engines (SE) via the NSX ALB Controller.
- **AKO Operator (AKOO)** - This is an operator which is used to deploy, manage and remove AKO Pod in Kubernetes clusters. This operator when deployed creates an instance of the AKO controller and installs all the relevant objects like
- AKO statefulset
- Clusterrole and Clusterrolbinding
- Configmap required for the AKO controller and other artifacts.

TKG management clusters have an ako-operator installed out of the box during cluster deployment. By default, a TKG management cluster has a couple of AkoDeploymentConfig created which dictates when and how ako pods are created in the workload clusters. For more information please see the official [documentation](https://github.com/vmware/load-balancer-and-ingress-services-for-kubernetes/tree/master/ako-operator).

Each environment configured in NSX ALB is referred to as Cloud. Each cloud in NSX ALB maintains networking and NSX ALB Service Engine settings. The cloud is configured with one or more VIP networks to provide IP addresses to load balancing (L4/L7) virtual services created under that cloud.

The virtual services can be spanned across multiple Service Engines if the associated Service Engine Group is configured in Active/Active HA mode. A Service Engine can belong to only one Service Engine group at a time. 

IP address allocation for virtual services can be over DHCP or via NSX ALB in-built IPAM functionality.  The VIP networks created/configured in NSX ALB are associated with the IPAM profile.
# **Network Architecture**
For deployment of TKG in the vSphere environment, we build separate networks for the TKG management cluster, TKG workload clusters, NSX ALB management, Cluster-VIP network for Control plane HA, TKG Mgmt VIP/Data network, and TKG workload Data/VIP Network. 

The network reference design can be mapped into this general framework.

![](img\tko-on-vsphere-vds/tko-on-vsphere-vds-3.png)

Figure 3 - TKG General Network Layout

This topology enables the following benefits:

- Isolate and separate SDDC management components (vCenter, ESX) from the TKG components. This reference design only allows the minimum connectivity between the TKG clusters and NSX ALB to the vCenter Server.
- Isolate and separate NSX ALB management network from the TKG management segment and the TKG workload segments.
- Depending on the workload cluster type and use case, multiple workload clusters may leverage the same workload network or new networks can be used for each workload cluster. 
  To isolate and separate TKG workload cluster networking from each other it’s recommended to make use of separate networks for each workload cluster and configure the required firewall between these networks. Refer to Firewall Recommendations for more details
- Separate provider and tenant access to the TKG environment.
  - Only provider administrators need access to the TKG management cluster. This prevents tenants from attempting to connect to the TKG management cluster.
- Only allow tenants to access their TKG workload cluster(s) and restrict access to this cluster from other tenants.
## **Network Requirements**
As per the defined architecture, below are the list of required networks:


|**Network Type**|**DHCP Service**|<p>**Description & Recommendations**</p><p></p>|
| :- | :- | :- |
|NSX ALB Management Network|Optional|<p>NSX ALB controllers and SEs will be attached to this network. </p><p></p><p>DHCP is not a mandatory requirement on this network as NSX ALB can take care of IPAM </p>|
|TKG Management Network|Yes|Control plane and worker nodes of TKG Management Cluster and Shared service clusters  will be attached to this network<br><br>Creating shared service cluster on a separate network is also supported.|
|TKG Workload Network|Yes|Control plane and worker nodes of TKG Workload Clusters will be attached to this network|
|TKG Cluster VIP/Data Network|No|Virtual services for Control plane HA of all TKG clusters (Management, Shared service, and Workload)<br>Reserve sufficient IPs depending on the number of TKG clusters planned to be deployed in the environment, NSX ALB takes care of IPAM on this network.|
|TKG Management VIP/Data Network|No|Virtual services for all user-managed packages (such as Contour, Harbor, Contour, Prometheus, Grafana) hosted on the Shared service cluster. Refer [User-Managed Packages](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.4/vmware-tanzu-kubernetes-grid-14/GUID-packages-user-managed-index.html) for mode details|
|TKG Workload VIP/Data Network|No|Virtual services for all applications hosted on the Workload clusters<br>Reserve sufficient IPs depending on the number of applications that are planned to be hosted on the Workload clusters along with scalability considerations.|

## **Subnet and CIDR Examples**
For the purpose of this demonstration, this document makes use of the following CIDR for TKO deployment. 

|**Network Type**|**Port Group Name**|**Gateway CIDR**|**DHCP Pool**|**NSX ALB IP Pool**|
| :- | :- | :- | :- | :- |
|NSX ALB Mgmt Network|nsx\_alb\_management\_pg|172.16.10.1/24|N/A|172.16.10.100- 172.16.10.200|
|TKG Management Network|tkg\_mgmt\_pg|172.16.40.1/24|172.16.40.100- 172.16.40.200|N/A|
|TKG Mgmt VIP Network|tkg\_mgmt\_vip\_pg|172.16.50.1/24|N/A|172.16.50.100- 172.16.50.200|
|TKG Cluster VIP Network|tkg\_cluster\_vip\_pg|172.16.80.1/24|N/A|172.16.80.100- 172.16.80.200|
|TKG Workload VIP Network|tkg\_workload\_vip\_pg|172.16.70.1/24|N/A|172.16.70.100 - 172.16.70.200|
|TKG Workload Segment|tkg\_workload\_pg|172.16.60.1/24|172.16.60.100- 172.16.60.200|N/A|

## **Firewall Requirements**
To prepare the firewall, you need to gather the following:

1. NSX Advanced Load Balancer Management Network CIDR
1. TKG Management Cluster Network CIDR
1. TKG Cluster VIP Network CIDR
1. TKG Management VIP Network CIDR
1. TKG Workload Cluster CIDR
1. VMware Harbor registry IP
1. vCenter Server IP
1. DNS server IP(s)
1. NTP Server(s)


|**Source**|**Destination**|**Protocol:Port**|**Description**|
| :- | :- | :- | :- |
|TKG Management and TKG Workload Networks|DNS Server<br>NTP Server|UDP:53<br>UDP:123|DNS Service <br>Time Synchronization|
|TKG Management and TKG Workload Networks|DHCP Server|UDP: 67, 68|Allows hosts to get DHCP addresses|
|TKG Management and TKG Workload Networks|vCenter IP|TCP:443|Allows components to access vCenter to create VMs and Storage Volumes|
|TKG Management, shared service  and Workload Cluster CIDR|Harbor Registry|TCP:443|<p>Allows components to retrieve container images. </p><p>This registry can be a local or a public image registry (projects.registry.vmware.com)</p>|
|TKG Management Cluster Network|TKG Cluster VIP Network |TCP:6443|For Management cluster to configure Shared service and Workload Cluster.|
|TKG Shared Service Cluster Network<br>(Required only if using a separate network for Shared Service Cluster)|TKG Cluster VIP Network|TCP:6443|Allow Shared cluster to register with management cluster|
|TKG Workload Cluster Network|TKG Cluster VIP Network|TCP:6443|Allow Workload cluster to register with management cluster|
|TKG Management, TKG Shared service and TKG Workload Networks|AVI Controllers (NSX ALB Management Network)|TCP:443|Allow Avi Kubernetes Operator (AKO) and AKO Operator (AKOO) access to Avi Controller|
|AVI Controllers (NSX ALB Management Network)|vCenter and ESXi Hosts|TCP:443|Allow AVI to discover vCenter objects and deploy SEs as required|
|Admin network|Bootstrap VM|SSH:22|To deploy, manage  and configure TKG clusters|
|deny-all|any|any|deny|
**Installation Experience**

===========================
TKG management cluster is the first component that you deploy to get started with Tanzu Kubernetes Grid.

You can deploy the Management cluster in two ways:

- Run the Tanzu Kubernetes Grid installer, a wizard interface that guides you through the process of deploying a management cluster. This is the recommended method if you are installing a TKG Management cluster for the first time. 
- Create and edit YAML configuration files, and use them to deploy a management cluster with the CLI commands.

The TKG Installation user interface shows that, in the current version, it is possible to install TKG on vSphere (including VMware Cloud on AWS), AWS EC2, and Microsoft Azure. The UI provides a guided experience tailored to the IaaS, in this case on VMware vSphere.

![](img\tko-on-vsphere-vds/tko-on-vsphere-vds-4.png)

The installation of TKG on vSphere is done through the same UI as mentioned above but tailored to a vSphere environment.

![](img\tko-on-vsphere-vds/tko-on-vsphere-vds-5.png)

Figure 5 - TKG installer user interface for vSphere.


This installation process will take you through the setup of a **Management Cluster** on your vSphere environment. Once the management cluster is deployed you can make use of [Tanzu Mission Control](https://tanzu.vmware.com/mission-control) or Tanzu CLI to deploy Tanzu Kubernetes Shared Service and workload clusters.
##
# **Design Recommendations**
## **NSX ALB Recommendations**
The below table provides the recommendations for configuring NSX ALB in a vSphere with Tanzu environment.


|**Decision ID**|**Design Decision**|**Design Justification**|**Design Implications**|
| :- | :- | :- | :- |
|TKO-ALB-001|Deploy NSX ALB controller cluster nodes on a network dedicated to NSX-ALB|Isolate NSX ALB traffic from infrastructure management traffic and Kubernetes workloads.|Using the same network for NSX ALB Controller Cluster nodes allows for configuring a floating cluster IP address that will be assigned to the cluster leader.|
|TKO-ALB-002|Deploy 3 NSX ALB controllers nodes.|To achieve high availability for the NSX ALB platform.|In clustered mode, NSX ALB availability is not impacted by an individual controller node failure. The failed node can be removed from the cluster and redeployed if recovery is not possible. |
|TKO-ALB-003|Use static IPs for the NSX ALB controllers if DHCP cannot guarantee a permanent lease.|NSX ALB Controller cluster uses management IPs to form and maintain quorum for the control plane cluster. Any changes would be disruptive.|NSX ALB Controller control plane might go down if the management IPs of the controller node changes.|
|TKO-ALB-004|Use NSX ALB IPAM for Service Engine data network and virtual services. |Guarantees IP address assignment for Service Engine Data NICs and Virtual Services.|Removes the corner case scenario when the DHCP server runs out of the lease or is down.|
|TKO-ALB-005|Reserve an IP in the NSX ALB management subnet to be used as the Cluster IP for the Controller Cluster.|NSX ALB portal is always accessible over Cluster IP regardless of a specific individual controller node failure.|NSX ALB administration is not affected by an individual controller node failure.|
|TKO-ALB-006|Use separate VIP networks for application load balancing and L7 services in TKG clusters|Separate dev/test and prod workloads L7 load balancer traffic from each other.|Install AKO in TKG clusters manually using helm charts. Reference the VIP network to use in the AKO configuration.|
|TKO-ALB-007|Create separate Service Engine Groups for TKG management and workload clusters.|This allows isolating load balancing traffic of the management and shared services cluster from workload clusters.|Create dedicated Service Engine Groups under the vCenter cloud configured manually.|
|TKO-ALB-008|Share Service Engines for the same type of workload (dev/test/prod)clusters.|Minimize the licensing cost|<p>Each Service Engine contributes to the CPU core capacity associated with a license.</p><p></p><p>Sharing Service Engines can help reduce the licensing cost. </p>|




##
## **Network Recommendations**
The following are the key network recommendations for a production-grade Tanzu Kubernetes Grid deployment with NSX-T Data Center Networking:

|**Decision ID**|**Design Decision**|**Design Justification**|**Design Implications**|
| :- | :- | :- | :- |
|TKO-NET-001|Use separate networks for Management cluster and workload clusters|To have a flexible firewall and security policies|Sharing the same network for multiple clusters can complicate firewall rules creation. |
|TKO-NET-002|Use separate networks for workload clusters based on their usage.|Isolate production Kubernetes clusters from dev/test clusters.|<p>A separate set of Service Engines can be used for separating dev/test workload clusters from prod clusters.</p><p></p>|
|TKO-NET-003|Configure DHCP  for each TKG Cluster Network|Tanzu Kubernetes Grid does not support static IP assignments for Kubernetes VM components|IP Pool can be used for the TKG clusters in absence of the DHCP.|

## **TKG Clusters Recommendations**


|**Decision ID**|**Design Decision**|**Design Justification**|**Design Implications**|
| :- | :- | :- | :- |
|TKO-TKG-001|Deploy TKG Management cluster from TKG Installer UI|Simplified method of installation.|<p>When you deploy a management cluster by using the installer interface, it populates a cluster configuration file for the management cluster with the required parameters. </p><p></p><p>You can use the configuration file as a model for future deployments from the CLI.</p>|
|TKO-TKG-002|Register Management cluster with Tanzu Mission Control|Tanzu Mission Control automates the creation of the Tanzu Kubernetes clusters and manages the life cycle of all clusters centrally.|Tanzu Mission Control also automates the deployment of Tanzu Packages in all Tanzu Kubernetes clusters associated with TMC.|
|TKO-TKG-003|Use NSX Advanced Load Balancer as your Control Plane Endpoint Provider and for application load balancing|Eliminates the requirement for an external load balancer and additional configuration changes on your Tanzu Kubernetes Grid clusters|NSX ALB is a true SDN solution and offers a flexible deployment model and automated way of scaling load balancer objects when needed.|
|TKO-TKG-004|Deploy Tanzu Kubernetes clusters in large form factor|Allow TKG clusters integration with Tanzu SaaS components (Tanzu Mission Control, Tanzu Observability, and Tanzu Service Mesh)|<p>When TKG is integrated with SaaS endpoints, new pods/services, etc are created in the target cluster and the pods have specific CPU requirements which can’t be fulfilled with medium and small-sized control plane/worker nodes</p><p></p>|
|TKO-TKG-005|Deploy Tanzu Kubernetes clusters with Prod plan.|This deploys multiple control plane nodes and provides High Availability for the control plane.|TKG infrastructure is not impacted by single node failure. |
|TKO-TKG-006|Enable identity management for Tanzu Kubernetes Grid clusters.|To avoids usage of administrator credentials and ensure that required users with right roles have access to Tanzu Kubernetes Grid clusters|<p>Pinniped package helps with integrating TKG Management cluster with LDAPS/OIDC Authentication.</p><p></p><p>Workload cluster inherits the authentication configuration from the management cluster</p>|
|TKO-TKG-007|Enable Machine Health Checks for TKG clusters|vSphere HA and Machine Health Checks interoperably work together to enhance workload resiliency|A MachineHealthCheck is a resource within the Cluster API which allows users to define conditions under which Machines within a Cluster should be considered unhealthy. Remediation actions can be taken when MachineHealthCheck has identified a node as unhealthy.|
|TKO-TKG-008|Use Photon based image for TKG clusters  |TMC supports only Photon based images for deploying TKG clusters.|Provisioning clusters from TMC with Ubuntu or any custom images is still in development|

# **Kubernetes Ingress Routing**
Default installation of Tanzu Kubernetes Grid does not have any ingress controller installed. Users can use Contour (available for installation through Tanzu Packages) or any Third-party ingress controller of their choice. 

Contour is an open-source controller for Kubernetes Ingress routing. Contour can be installed in the Shared Services cluster on any Tanzu Kubernetes Cluster. Deploying Contour is a prerequisite if you want to deploy the Prometheus, Grafana, and Harbor Packages on a workload cluster. 

For more information about Contour, see [Contour](https://projectcontour.io/) site and [Implementing Ingress Control with Contour](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.5/vmware-tanzu-kubernetes-grid-15/GUID-packages-ingress-contour.html).

Another option is to use the NSX Advanced Load Balancer Kubernetes ingress controller which offers an advanced L7 ingress for containerized applications that are deployed in the Tanzu Kubernetes workload cluster. 

![](img\tko-on-vsphere-vds/tko-on-vsphere-vds-6.png)

Figure 6 - NSX Advanced Load Balancing capabilities for VMware Tanzu

For more information about the NSX ALB ingress controller, please see the [official documentation](https://avinetworks.com/docs/ako/1.5/avi-kubernetes-operator/).

[Tanzu Service Mesh](https://tanzu.vmware.com/service-mesh), which is a SaaS offering for modern applications running across multi-cluster, multi-clouds, also offers an Ingress controller based on [Istio](https://istio.io/). 

Each ingress controller has pros and cons of their own. The below table provides general recommendations on when you should use a specific ingress controller for your Kubernetes environment.

|**Ingress Controller**|**Use Cases**|
| :- | :-: |
|Contour|<p>Use contour when only north-south traffic is needed in a Kubernetes cluster. You can apply security policies for the north-south traffic by defining the policies in the applications manifest file.</p><p></p><p>It's a reliable solution for simple kubernetes workloads. </p>|
|Istio|use Istio ingress controller when you intended to provide security, traffic direction, and insight within the cluster (east-west traffic) and between the cluster and the outside world (north-south traffic)|
|NSX ALB Ingress controller|<p>Use NSX ALB ingress controller when a containerized application requires features like local and global server load balancing (GSLB), web application firewall (WAF), performance monitoring, direct routing from LB to pod etc. </p><p></p>|

# **NSX ALB Sizing Guidelines**
## **NSX ALB Controller Sizing Guidelines**
Regardless of NSX ALB Controller configuration, each Controller cluster can achieve up to 5,000 virtual services, this is a hard limit. For further details, please refer to this [guide](https://avinetworks.com/docs/20.1/avi-controller-sizing/#cpuandmemalloc).

|**Controller Size**|**VM Configuration**|**Virtual Services**|**Avi SE Scale**|
| :- | :- | :- | :- |
|Small|4 vCPUS, 12 GB RAM|0-50|0-10|
|Medium|8 vCPUS, 24 GB RAM|0-200|0-100|
|Large|16 vCPUS, 32 GB RAM|200-1000|100-200|
|Extra Large|24 vCPUS, 48 GB RAM|1000-5000|200-400|

## **Service Engine Sizing Guidelines**
See [Sizing Service Engines](https://avinetworks.com/docs/20.1/sizing-service-engines/) for guidance on sizing your SEs. 

|**Performance metric**|**1 vCPU core**|
| :- | :- |
|Throughput|4 Gb/s|
|Connections/s|40k|
|SSL Throughput|1 Gb/s|
|SSL TPS (RSA2K)|~600|
|SSL TPS (ECC)|2500|

Multiple performance vectors or features may have an impact on performance.  For instance, to achieve 1 Gb/s of SSL throughput and 2000 TPS of SSL with EC certificates, NSX ALB recommends two cores.

NSX ALB Service Engines may be configured with as little as 1 vCPU core and 1 GB RAM, or up to 36 vCPU cores and 128 GB RAM. Service Engines can be deployed in Active/Active or Active/Standby mode depending on the license tier used. NSX ALB Essentials license doesn’t support Active/Active HA mode for SE. 


|**Decision ID**|**Design Decision**|**Design Justification**|**Design Implications**|
| :- | :- | :- | :- |
|TKO-ALB-SE-001|Configure the High Availability mode for SEs|To mitigate a single point of failure for the NSX ALB data plane.|High Availability** for Service Engines is configured via setting the Elastic HA mode to Active/Active or N+M in the Service Engine Group.|

# **Container Registry**
VMware Tanzu for Kubernetes Operations using Tanzu Kubernetes Grid include Harbor as a container registry. Harbor provides a location for pushing, pulling, storing, and scanning container images used in your Kubernetes clusters. 

Harbor registry is used for day2 operations of the Tanzu Kubernetes workload clusters. Typical day-2 operations include tasks such as pulling images from the harbor for application deployment, pushing custom images to Harbor, etc. 

There are three main supported installation methods for Harbor:

- [**TKG Package deployment**](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.5/vmware-tanzu-kubernetes-grid-15/GUID-packages-harbor-registry.html) on a TKG Shared service cluster - Tanzu Kubernetes Grid includes signed binaries for Harbor, which you can deploy into a shared services cluster to provide container registry services for other Tanzu Kubernetes (workload) clusters. This installation method is recommended for general use cases. 
- [**Helm-based deployment**](https://goharbor.io/docs/2.1.0/install-config/harbor-ha-helm/) to a Kubernetes cluster - this installation method may be preferred for customers already invested in Helm.
- [**VM-based deployment](https://goharbor.io/docs/2.1.0/install-config/installation-prereqs/) **using docker-compose** - this installation method is recommended in cases where Tanzu Kubernetes Grid is installed in an air-gapped environment and no pre-existing Kubernetes clusters exist on which to install Harbor.

![](img\tko-on-vsphere-vds/tko-on-vsphere-vds-7.png)

Figure 7 - Harbor Container Registry


# **Logging**
Fluent Bit is a lightweight log processor and forwarder that allows you to collect data and logs from different sources, unify them, and send them to multiple destinations. Tanzu Kubernetes Grid includes signed binaries for Fluent Bit, that you can deploy on management clusters and on Tanzu Kubernetes clusters to provide a log-forwarding service.

Tanzu for Kubernetes Operations include [Fluent Bit](https://fluentbit.io/) as a user managed package for integration with logging platforms such as **vRealize LogInsight, Elasticsearch, Splunk or other logging solutions**. Details on configuring Fluent Bit to your logging provider can be found in the documentation [here](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.5/vmware-tanzu-kubernetes-grid-15/GUID-packages-logging-fluentbit.html).

You can deploy Fluent Bit on any management cluster or Tanzu Kubernetes clusters from which you want to collect logs. First, you configure an output plugin on the cluster from which you want to gather logs, depending on the endpoint that you use. Then, you deploy Fluent Bit on the cluster as a package. 

vRealize Log Insight (vRLI) provides real-time log management and log analysis with machine learning based intelligent grouping, high-performance searching, and troubleshooting across physical, virtual, and cloud environments. vRLI already has a deep integration with the vSphere platform where you can get key actionable insights, and it can be extended to include the cloud native stack as well. 

vRealize Log Insight appliance is available as a separate on-prem deployable product. You can also choose to go with the SaaS version **vRealize Log Insight Cloud**.


# **Appendix**
## **Configure Node Sizes**
The Tanzu CLI creates the individual nodes of management clusters and Tanzu Kubernetes clusters according to the settings that you provide in the configuration file. 

On vSphere, you can configure all node VMs to have the same predefined configurations, set different predefined configurations for control plane and worker nodes, or customize the configurations of the nodes. By using these settings, you can create clusters that have nodes with different configurations to the management cluster nodes. You can also create clusters in which the control plane nodes and worker nodes have different configurations.

**Use Predefined Node Configurations**

The Tanzu CLI provides the following predefined configurations for cluster nodes:

|**Size**|**CPU**|**Memory (in GB)**|**Disk (in GB)**|
| :- | :- | :- | :- |
|Small|2|4|20|
|Medium|2|8|40|
|Large|4|16|40|
|Extra-large|8|32|80|
To create a cluster in which all of the control plane and worker node VMs are the same size, specify the SIZE variable. If you set the SIZE variable, all nodes will be created with the configuration that you set.

- SIZE: "large"

To create a cluster in which the control plane and worker node VMs are different sizes, specify the CONTROLPLANE\_SIZE and WORKER\_SIZE options.

- CONTROLPLANE\_SIZE: "medium"
- WORKER\_SIZE: "large"

You can combine the CONTROLPLANE\_SIZE and WORKER\_SIZE options with the SIZE option. For example, if you specify SIZE: "large" with WORKER\_SIZE: "extra-large", the control plane nodes will be set to large and worker nodes will be set to extra-large.

- SIZE: "large"
- WORKER\_SIZE: "extra-large"

**Define Custom Node Configurations**

You can customize the configuration of the nodes rather than using the predefined configurations. 

To use the same custom configuration for all nodes, specify the VSPHERE\_NUM\_CPUS, VSPHERE\_DISK\_GIB, and VSPHERE\_MEM\_MIB options.

- VSPHERE\_NUM\_CPUS: 2
- ` `VSPHERE\_DISK\_GIB: 40
- ` `VSPHERE\_MEM\_MIB: 4096

To define different custom configurations for control plane nodes and worker nodes, specify the VSPHERE\_CONTROL\_PLANE\_\* and VSPHERE\_WORKER\_\* 

- VSPHERE\_CONTROL\_PLANE\_NUM\_CPUS: 2
- ` `VSPHERE\_CONTROL\_PLANE\_DISK\_GIB: 20
- ` `VSPHERE\_CONTROL\_PLANE\_MEM\_MIB: 8192
- ` `VSPHERE\_WORKER\_NUM\_CPUS: 4
- ` `VSPHERE\_WORKER\_DISK\_GIB: 40

` `VSPHERE\_WORKER\_MEM\_MIB: 4096
# Summary
TKG on vSphere on hyper-converged hardware offers high-performance potential, convenience, and addresses the challenges of **creating, testing, and updating on-premise Kubernetes platforms** in a consolidated production environment. This validated approach will result in a near-production quality installation with all the application services needed to **serve combined or uniquely separated workload types** via a combined infrastructure solution.

This plan meets many Day 0 needs for quickly aligning product capabilities to full stack infrastructure, including **networking, firewalling, load balancing, workload compute alignment** and other capabilities. 

Observability is quickly established and easily consumed with **Tanzu Observability**.

