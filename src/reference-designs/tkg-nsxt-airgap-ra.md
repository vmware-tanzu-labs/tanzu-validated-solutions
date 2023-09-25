﻿# VMware Tanzu Kubernetes Grid on vSphere with NSX-T Networking in Air-Gapped Environment Reference Design

VMware Tanzu Kubernetes Grid (informally known as TKG) (multi-cloud) provides organizations with a consistent, upstream-compatible, regional Kubernetes substrate that is ready for end-user workloads and ecosystem integrations.

An air-gapped environment is a network security measure employed to ensure a computer or computer network is secure by physically isolating it from unsecured networks, such as the public Internet or an unsecured local area network. This means a computer or network is disconnected from all other systems.

This document lays out a reference design for deploying Tanzu Kubernetes Grid (informally known as TKG) on NSX-T Data Center Networking in an air-gapped environment and offers a high-level overview of the different components required for setting up a Tanzu Kubernetes Grid environment.

## Supported Component Matrix

The following table provides the component versions and interoperability matrix supported with the reference design:

|**Software Components**|**Version**|
| --- | --- |
|Tanzu Kubernetes Grid|2.3.0|
|VMware vSphere ESXi|8.0 U1 or later|
|VMware vCenter Server|8.0 U1 or later|
|VMware NSX |4.1.0.2|

For the latest interoperability information about other VMware products and versions, see the [VMware Interoperability Matrix](https://interopmatrix.vmware.com/Interoperability?col=551,17100&row=1,%262,%26175,).

## Components

The following components are used in the reference architecture:

- **Tanzu Kubernetes Grid (TKG)** - Enables creation and lifecycle management of Kubernetes clusters.

- **NSX Advanced Load Balancer Enterprise Edition** - Provides layer 4 service type load balancer and layer 7 ingress support.

- **Tanzu User-Managed Packages:** User-managed packages are distributed through package repositories. The `tanzu-standard` package repository includes the following user-managed packages:

  - [**Cert Manager**](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/2.3/using-tkg/workload-packages-cert-mgr.html) - Provides automated certificate management. It runs by default in management clusters.

  - [**Contour**](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/2.3/using-tkg/workload-packages-contour.html) - Provides layer 7 ingress control to deployed HTTP(S) applications. Tanzu Kubernetes Grid includes signed binaries for Contour. Deploying Contour is a prerequisite for deploying Prometheus, Grafana, and Harbor extensions.

  - [**Fluent Bit**](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/2.3/using-tkg/workload-packages-fluentbit.html) - Collects data and logs from different sources, unifies them, and sends them to multiple destinations. Tanzu Kubernetes Grid includes signed binaries for Fluent Bit.

  - [**Prometheus**](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/2.3/using-tkg/workload-packages-prometheus.html) - Provides out-of-the-box health monitoring of Kubernetes clusters. The Tanzu Kubernetes Grid implementation of Prometheus includes an Alert Manager. You can configure Alert Manager to notify you when certain events occur.

  - [**Grafana**](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/2.3/using-tkg/workload-packages-grafana.html) - Provides monitoring dashboards for displaying key health metrics of Kubernetes clusters. Tanzu Kubernetes Grid includes an implementation of Grafana.

  - [**Harbor Image Registry**](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/2.3/using-tkg/workload-packages-harbor.html) - Provides a centralized location to push, pull, store, and scan container images used in Kubernetes workloads. It supports storing artifacts and includes enterprise-grade features such as RBAC, retention policies, automated garbage clean up, and Docker hub proxying.

  - [**Multus CNI**](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/2.3/using-tkg/workload-packages-multus.html) - Enables attaching multiple network interfaces to pods. Multus CNI is a container network interface (CNI) plugin for Kubernetes that lets you attach multiple network interfaces to a single pod and associate each interface with a different address range.

- **Bastion Host** - Bastion host is the physical/virtual machine where you download the required installation images/binaries (for Tanzu Kubernetes Grid installation) from the Internet. This machine needs to be outside the air-gapped environment. The downloaded items then need to be shipped to the bootstrap machine which is inside the air-gapped environment.

- **Jumpbox/Bootstrap Machine** - The bootstrap machine is where you run the Tanzu CLI and other utilities such as [Kubectl](https://kubernetes.io/docs/reference/kubectl/kubectl/), [Kind](https://kind.sigs.k8s.io/). Here is the initial bootstrapping of a management cluster occurs before it is pushed to the platform where it runs.

The binaries for Tanzu Kubernetes Grid installation are made available in ISO or tarball format on this machine. This machine should have access to the infrastructure components such as the vCenter server and the components that are deployed during the installation of Tanzu Kubernetes Grid. This machine should have a browser installed to access the UI of the components described above.

With TKG 2.1.0, instead of custom script, a new Tanzu CLI plugin isolated-cluster has been provided which will pre-populate air gapped internal registry.

This new Tanzu CLI plug-in contains two separate commands :

- **Download-bundle** - Downloads the images and bundles as tar files. Along with the downloads, a YAML file gets created that contains the mapping from the image name to the tar location.

- **Upload-bundle** -  Upload images to private repository. Bootstrap VM should have access to this private repository for Tanzu installation.

- **Local Image Registry** - An image registry provides a location for pushing, pulling, storing, and scanning container images used in the Tanzu Kubernetes Grid environment. The image registry is also used for day-2 operations of the Tanzu Kubernetes clusters. Typical day-2 operations include tasks such as storing application images, upgrading Tanzu Kubernetes clusters, etc.

In an air-gapped environment, there are a couple of possible solutions for using an image registry:

- **Existing Image Registry** - An image registry pre-existing in the environment with a project created for storing Tanzu Kubernetes Grid binaries and the bootstrap machine has access to this registry. The operator unzip the TAR file present in the bootstrap machine and pushes the Tanzu Kubernetes Grid binaries to the Tanzu Kubernetes Grid project using the script present in the TAR file. This registry can be a [Harbor](https://goharbor.io/) registry or any other container registry solution.

- **New Image Registry** - If there is no pre-existing image registry in the environment, a new registry instance can be deployed. The easiest way to create a new image registry instance is [VM-based deployment using OVA ](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/2.3/tkg-deploy-mc/mgmt-reqs-harbor.html), and then push the TKG binaries to the appropriate project. VM-based deployments are only supported by VMware Global Support Services to host the system images for air-gapped or Internet-restricted deployments. Do not use this method for hosting application images.

## Tanzu Kubernetes Grid Components

VMware Tanzu Kubernetes Grid provides organizations with a consistent, upstream-compatible, regional Kubernetes substrate that is ready for end-user workloads and ecosystem integrations. You can deploy Tanzu Kubernetes Grid across software-defined datacenters (SDDC) and public cloud environments, including vSphere, Microsoft Azure, and Amazon EC2.

Tanzu Kubernetes Grid comprises the following components:

- **Management Cluster** - A management cluster is the first element that you deploy when you create a Tanzu Kubernetes Grid instance. The management cluster is a Kubernetes cluster that performs the role of the primary management and operational center for the Tanzu Kubernetes Grid instance. The management cluster is purpose-built for operating the platform and managing the lifecycle of Tanzu Kubernetes clusters.

- **ClusterClass API** - Tanzu Kubernetes Grid 2 functions through the creation of a management Kubernetes cluster which holds [ClusterClass API](https://cluster-api.sigs.k8s.io/introduction.html). The ClusterClass API then interacts with the infrastructure provider to service workload Kubernetes cluster lifecycle requests. The earlier primitives of Tanzu Kubernetes clusters will still exist for Tanzu Kubernetes Grid 1.X . The Cluster API also contains ClusterClass which reduces the need for redundant templating, and enables powerful customization of clusters. The process for creating a cluster using ClusterClass is same as before with a set of different parameters. 

- **Tanzu Kubernetes Cluster** - Tanzu Kubernetes clusters are the Kubernetes clusters in which your application workloads run. These clusters are also referred to as workload clusters. Tanzu Kubernetes clusters can run different versions of Kubernetes, depending on the needs of the applications they run.

- **Shared Services Cluster** - Each Tanzu Kubernetes Grid instance can only have one shared services cluster. You deploy this cluster only if you intend to deploy shared services such as Contour and Harbor.

- **Tanzu Kubernetes Cluster Plans** - A cluster plan is a blueprint that describes the configuration with which to deploy a Tanzu Kubernetes cluster. It provides a set of configurable values that describe settings like the number of control plane machines, worker machines, VM types, and so on.

  This release of Tanzu Kubernetes Grid provides two default templates; dev, and prod. You can create and use custom plans to meet your requirements.

- **Tanzu Kubernetes Grid Instance** - A Tanzu Kubernetes Grid instance is the full deployment of Tanzu Kubernetes Grid, including the management cluster, the workload clusters, and the shared services cluster that you configure.

- **Tanzu CLI** - A command-line utility that provides the necessary commands to build and operate Tanzu management and Tanzu Kubernetes clusters. Starting with TKG 2.3.0, [Tanzu Core CLI](https://customerconnect.vmware.com/downloads/details?downloadGroup=TCLI-0901&productId=1431) is now distributed separately from Tanzu Kubernetes Grid. For more information about installing the Tanzu CLI for use with Tanzu Kubernetes Grid, see [Install the Tanzu CLI](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/2.3/tkg-deploy-mc/install-cli.html).

- **Bootstrap Machine** - The bootstrap machine is the laptop, host, or server on which you download and run the Tanzu CLI. This is where the initial bootstrapping of a management cluster occurs before it is pushed to the platform where it runs. This machine also houses a Harbor instance where all the required Tanzu Kubernetes Grid installation binaries are pushed.

- **Carvel Tools** - An open-source suite of tools. Carvel provides a set of reliable, single-purpose, composable tools that aid in your application building, configuration, and deployment to Kubernetes. Tanzu Kubernetes Grid uses the following tools from the Carvel open-source project:

  - **ytt** - A command-line tool for templating and patching YAML files. You can also use `ytt` to collect fragments and piles of YAML into modular chunks for reuse.
  - **kapp** - The application deployment CLI for Kubernetes. It allows you to install, upgrade, and delete multiple Kubernetes resources as one application.
  - **kbld** - An image-building and resolution tool.
  - **imgpkg** - A tool that enables Kubernetes to store configurations and the associated container images as OCI images, and to transfer these images.
  - **yq** - A lightweight and portable command-line YAML, JSON, and XML processor. `yq` uses `jq`-like syntax but works with YAML files as well as JSON and XML.

- **Tanzu Kubernetes Grid Installer** - The Tanzu Kubernetes Grid installer is a CLI/graphical wizard that provides an option to deploy a management cluster. You launch this installer locally on the bootstrap machine by running the `tanzu management-cluster create` command.

## Tanzu Kubernetes Grid Storage

Tanzu Kubernetes Grid integrates with shared datastores available in the vSphere infrastructure. The following types of shared datastores are supported:

- vSAN
- VMFS
- NFS
- vVols

Tanzu Kubernetes Grid uses storage policies to integrate with shared datastores. The policies represent datastores and manage the storage placement of such objects as control plane VMs, container images, and persistent storage volumes.

Tanzu Kubernetes Grid Cluster Plans can be defined by operators to use a certain vSphere Datastore when creating new workload clusters. All developers would then have the ability to provision container-backed persistent volumes from that underlying datastore.

Tanzu Kubernetes Grid is agnostic about which option you choose. For Kubernetes stateful workloads, Tanzu Kubernetes Grid installs the [vSphere Container Storage interface (vSphere CSI)](https://github.com/container-storage-interface/spec/blob/master/spec.md) to automatically provision Kubernetes persistent volumes for pods.


## Tanzu Kubernetes Clusters Networking

A Tanzu Kubernetes cluster provisioned by the Tanzu Kubernetes Grid supports two Container Network Interface (CNI) options:

- [Antrea](https://antrea.io/)
- [Calico](https://www.tigera.io/project-calico/)

Both are open-source softwares that provide networking for cluster pods, services, and ingress.

When you deploy a Tanzu Kubernetes cluster using Tanzu CLI, Antrea CNI is automatically enabled in the cluster.

To provision a Tanzu Kubernetes cluster using a non-default CNI, see [Deploy Tanzu Kubernetes clusters with Calico](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/2.3/using-tkg/workload-clusters-networking.html).

Each CNI is suitable for a different use case. The following table lists common use cases for the three CNIs that Tanzu Kubernetes Grid supports. This table helps you with information on selecting the right CNI in your Tanzu Kubernetes Grid implementation.

|**CNI**|**Use Case**|**Pros and Cons**|
| --- | --- | --- |
|Antrea  |<p>Enable Kubernetes pod networking with IP overlay networks using VXLAN or Geneve for encapsulation. Optionally, encrypt node-to-node communication using IPSec packet encryption.</p><p></p><p>Antrea supports advanced network use cases like kernel bypass and network service mesh.</p>|<p>Pros:</p><p>- Provide an option to configure egress IP address pool or static egress IP address for the Kubernetes workloads.</p>|
|Calico  |<p>Calico is used in environments where factors like network performance, flexibility, and power are essential.</p><p></p><p>For routing packets between nodes, Calico leverages the BGP routing protocol instead of an overlay network. This eliminates the need to wrap packets with an encapsulation layer resulting in increased network performance for Kubernetes workloads.</p>|<p>Pros:</p><p>- Support for network policies</p><p>- High network performance</p><p>- SCTP support</p><p>Cons:</p><p>- No multicast support</p>|

## Tanzu Kubernetes Grid Infrastructure Networking

Tanzu Kubernetes Grid on vSphere can be deployed on various networking stacks including

- VMware NSX-T Data Center Networking
- vSphere Networking (VDS)

>**Note** The scope of this document is limited to NSX-T Data Center Networking with NSX Advanced load balancer Enterprise Edition.

## Tanzu Kubernetes Grid on NSX-T Networking with NSX Advanced Load Balancer

When deployed on VMware NSX-T Networking, Tanzu Kubernetes Grid uses the NSX-T logical segments and gateways to provide connectivity to Kubernetes control plane VMs, worker nodes, services, and applications. All hosts from the cluster where Tanzu Kubernetes clusters are deployed are configured as NSX-T transport nodes, which provide network connectivity to the Kubernetes environment.

You can configure NSX Advanced Load Balancer in Tanzu Kubernetes Grid as:

- L4 load balancer for application hosted on the TKG cluster.

- The L7 ingress service provider for the applications in the clusters that are deployed on vSphere.

- L4 load balancer for the control plane API server.

Each workload cluster integrates with NSX Advanced Load Balancer by running an Avi Kubernetes Operator (AKO) on one of its nodes. The cluster’s AKO calls the Kubernetes API to manage the lifecycle of load balancing and ingress resources for its workloads.

## NSX Advanced Load Balancer Components

NSX Advanced Load Balancer is deployed in Write Access Mode in VMware NSX Environment. This mode grants NSX Advanced Load Balancer controllers full write access to vCenter which helps in automatically creating, modifying, and removing service engines (SEs) and other resources as needed to adapt to changing traffic needs. The core components of NSX Advanced Load Balancer are as follows:

- **NSX Advanced Load Balancer Controller** - NSX Advanced Load Balancer controller manages virtual service objects and interacts with the vCenter Server infrastructure to manage the lifecycle of the service engines (SEs). It is the central repository for the configurations and policies related to services and management, and it provides the portal for viewing the health of VirtualServices and SEs and the associated analytics that NSX Advanced Load Balancer provides.
- **NSX Advanced Load Balancer Service Engine** - The service engines (SEs) are lightweight VMs that handle all data plane operations by receiving and executing instructions from the controller. The SEs perform load balancing and all client- and server-facing network interactions.
- **Service Engine Group -** Service engines are created within a group, which contains the definition of how the SEs should be sized, placed, and made highly available. Each cloud has at least one SE group.
- **Cloud -** Clouds are containers for the environment that NSX Advanced Load Balancer is installed or operating within. During the initial setup of NSX Advanced Load Balancer, a default cloud, named `Default-Cloud`, is created. This is where the first controller is deployed into Default-Cloud. Additional clouds may be added containing SEs and virtual services.
- **Avi Kubernetes Operator (AKO)** - It is a Kubernetes operator that runs as a pod in the Supervisor Cluster and Tanzu Kubernetes clusters, and it provides ingress and load balancing functionality. AKO translates the required Kubernetes objects to NSX Advanced Load Balancer objects and automates the implementation of ingresses, routes, and services on the service engines (SE) through the NSX Advanced Load Balancer Controller.
- **AKO Operator (AKOO)** - This is an operator which is used to deploy, manage, and remove the AKO pod in Kubernetes clusters. This operator when deployed creates an instance of the AKO controller and installs all the relevant objects like:
  - AKO `Statefulset`
  - `Clusterrole` and `Clusterrolebinding`
  - `Configmap` (required for the AKO controller and other artifacts).

Tanzu Kubernetes Grid management clusters have an AKO operator installed out-of-the-box during cluster deployment. By default, a Tanzu Kubernetes Grid management cluster has a couple of `AkoDeploymentConfig` created which dictates when and how AKO pods are created in the workload clusters. For more information, see [AKO Operator documentation](https://github.com/vmware/load-balancer-and-ingress-services-for-kubernetes/tree/master/ako-operator).

Optionally, you can enter one or more cluster labels to identify clusters on which to selectively enable NSX ALB or to customize NSX ALB settings for different groups of clusters. This is useful in the following scenarios:
  - You want to configure different sets of workload clusters to different Service Engine Groups to implement isolation or to support more Service type Load Balancers than one Service Engine Group’s capacity.
  - You want to configure different sets of workload clusters to different Clouds because they are deployed in different sites.

To enable NSX ALB selectively rather than globally, add labels in the format **key: value** pair in the management cluster config file. This will create a default AKO Deployment Config (ADC) on management cluster with the NSX ALB settings provided. Labels that you define here will be used to create a label selector. Only workload cluster objects that have the matching labels will have the load balancer enabled. 

To customize the NSX ALB settings for different groups of clusters, create an AKO Deployment Config (ADC) on management cluster by customizing the NSX ALB settings, and providing a unique label selector for the ADC. Only the workload cluster objects that have the matching labels will have these custom settings applied. 

You can label the cluster during the workload cluster deployment or label it manually post cluster creation. If you define multiple key-values, you need to apply all of them.
  - Provide an AVI_LABEL in the below format in the workload cluster deployment config file, and it will automatically label the cluster and select the matching ADC based on the label selector during the cluster deployment.
    ```
    AVI_LABELS: |
    'type': 'tkg-workloadset01'
    ```
  - Optionally, you can manually label the cluster object of the corresponding workload cluster with the labels defined in ADC.
    ```
    kubectl label cluster <cluster-name> type=tkg-workloadset01
    ```

Each environment configured in NSX Advanced Load Balancer is referred to as a cloud. Each cloud in NSX Advanced Load Balancer maintains networking and service engine settings. The cloud is configured with one or more VIP networks to provide IP addresses to load balancing (L4/L7) virtual services created under that cloud.

The virtual services can be spanned across multiple service engines if the associated SE group is configured in Active/Active HA mode. A service engine can belong to only one SE group at a time.

IP address allocation for virtual services can be over DHCP or through the in-built IPAM functionality of NSX Advanced Load Balancer. The VIP networks created or configured in NSX Advanced Load Balancer are associated with the IPAM profile.

## Network Architecture

For the deployment of Tanzu Kubernetes Grid in the VMware NSX-T environment, it is required to build separate networks for the Tanzu Kubernetes Grid management cluster and workload clusters, NSX Advanced Load Balancer management, and cluster-VIP network for control plane HA.

The network reference design can be mapped into this general framework. This design uses a single VIP network for control plane L4 load balancing and application L4/L7. This design is mostly suited for dev/test environment.

![TKG General Network Layout](img/tkg-nsxt-airgap/tkg-nsxt-airgap02.jpg)

Another reference design that can be implemented in production environment is shown below, and it uses separate VIP network for the applications deployed in management/shared services and the workload cluster.

![TKG General Network Layout](./img/tkg-nsxt-airgap/tkg-nsxt-airgap02a.png)

This topology enables the following benefits:

- Isolate and separate SDDC management components (vCenter, ESX) from the Tanzu Kubernetes Grid components. This reference design allows only the minimum connectivity between the Tanzu Kubernetes Grid clusters and NSX Advanced Load Balancer to the vCenter server.

- Isolate and separate the NSX Advanced Load Balancer management network from the Tanzu Kubernetes Grid management segment and workload segments.

- Depending on the workload cluster type and use case, multiple workload clusters may leverage the same workload network or new networks can be used for each workload cluster. To isolate and separate Tanzu Kubernetes Grid workload cluster networking from each other, it is recommended to make use of separate networks for each workload cluster and configure the required firewall between these networks. For more information, see [Firewall Recommendations](#ra-firewall-requirements).

- Separate provider and tenant access to the Tanzu Kubernetes Grid environment.

  - Only provider administrators need access to the Tanzu Kubernetes Grid management cluster. This prevents tenants from attempting to connect to the Tanzu Kubernetes Grid management cluster.

- Only allow tenants to access their Tanzu Kubernetes Grid workload clusters and restrict access to this cluster from other tenants.

## <a id=ra-network-requirements> </a> Network Requirements

As per the defined architecture, the list of required networks follows:

|**Network Type**|**DHCP Service**|<p>**Description & Recommendations**</p><p></p>|
| --- | --- | --- |
|NSX ALB Management Logical Segment|Optional|<p>NSX ALB controllers and SEs are attached to this network. </p><p></p><p>DHCP is not a mandatory requirement on this network as NSX ALB can handle IPAM services for the management network.</p>|
|TKG Management Logical Segment|Yes|Control plane and worker nodes of TKG management cluster are attached to this network.|
|TKG Shared Service Logical Segment|Yes|Control plane and worker nodes of TKG shared services cluster are attached to this network.|
|TKG Workload Logical Segment|Yes|Control plane and worker nodes of TKG workload clusters are attached to this network.|
|TKG Management VIP Logical Segment|No|Virtual services for control plane HA of all TKG clusters (management, shared services, and workload).<br>Reserve sufficient IP addresses depending on the number of TKG clusters planned to be deployed in the environment. <br> NSX Advanced Load Balancer takes care of IPAM on this network.|
|TKG Workload VIP Logical Segment|No|Virtual services for applications deployed in the workload cluster. The applications can be of type Load balancer or Ingress.<br>Reserve sufficient IP addresses depending on the number of applications planned to be deployed in the environment. <br> NSX Advanced Load Balancer takes care of IPAM on this network.|

>**Note** You can also select `TKG Workload VIP` network for control plane HA of the workload cluster if you wish so. 

## Subnet and CIDR Examples

This document uses the following CIDRs for Tanzu Kubernetes Grid deployment:

|**Network Type**|**Segment Name**|**Gateway CIDR**|**DHCP Pool in NSX-T**|**NSX ALB IP Pool**|
| --- | --- | --- | --- | --- |
|NSX ALB Management Network|sfo01-w01-vds01-albmanagement|172.16.10.1/24|N/A|172.16.10.100 - 172.16.10.200|
|TKG Management VIP Network|sfo01-w01-vds01-tkgclustervip|172.16.80.1/24|N/A|172.16.80.100 - 172.16.80.200|
|TKG Management Network|sfo01-w01-vds01-tkgmanagement|172.16.40.1/24|172.16.40.100 - 172.16.40.200|N/A|
|TKG Shared Service Network|sfo01-w01-vds01-tkgshared|172.16.50.1/24|172.16.50.100- 172.16.50.200|N/A|
|TKG Workload Network|sfo01-w01-vds01-tkgworkload|172.16.60.1/24|172.16.60.100- 172.16.60.200|N/A|
|TKG Workload VIP Network|sfo01-w01-vds01-workloadvip|172.16.70.1/24|172.16.70.100- 172.16.70.200|N/A|

## <a id=ra-firewall-requirements> </a> Firewall Requirements

To prepare the firewall, you must collect the following information:

1. NSX ALB Controller nodes and Cluster IP address.
2. NSX ALB Management Network CIDR.
3. TKG Management Network CIDR
4. TKG Shared Services Network CIDR
5. TKG Workload Network CIDR
6. TKG Cluster VIP Address Range
7. Client Machine IP Address
8. Bootstrap machine IP Address
9. Harbor registry IP address
10. vCenter Server IP.
11. DNS server IP(s).
12. NTP Server(s).
13. NSX-T nodes and VIP address.

The following table provides a list of firewall rules based on the assumption that there is no firewall within a subnet/VLAN:

|**Source**|**Destination**|**Protocol:Port**|**Description**|**Configured On**|
| --- | --- | --- | --- |---|
|NSX Advanced Load Balancer controllers and Cluster IP address|vCenter and ESXi hosts|TCP:443|Allows NSX ALB to discover vCenter objects and deploy SEs as required.|NSX ALB Tier-1 Gateway|
|NSX Advanced Load Balancer controllers and Cluster IP address|NSX nodes and VIP address.|TCP:443|Allows NSX ALB to discover NSX Objects (logical routers and logical segments, and so on).|NSX ALB Tier-1 Gateway|
|NSX Advanced Load Balancer management network CIDR|<p>DNS Server.</p><p>NTP Server</p>|<p>UDP:53</p><p>UDP:123</p>|<p>DNS Service</p><p>Time synchronization</p>|NSX ALB Tier-1 Gateway|
|Client Machine|NSX Advanced Load Balancer controllers and Cluster IP address|TCP:443|To access NSX Advanced Load Balancer portal.|NSX ALB Tier-1 Gateway|
|Client Machine|Bootstrap VM IP address|SSH:22|To deploy,configure and manage TKG clusters.|TKG Mgmt Tier-1 Gateway|
|<p>TKG management network CIDR</p><p></p><p>TKG shared services network CIDR</p><p>|DNS Server<br>NTP Server|UDP:53<br>UDP:123|DNS Service <br>Time Synchronization|TKG Mgmt Tier-1 Gateway|
|<p>TKG management network CIDR</p><p></p><p>TKG shared services network CIDR</p><p>|vCenter Server|TCP:443|Allows components to access vCenter to create VMs and storage volumes|TKG Mgmt Tier-1 Gateway|
|<p>TKG management network CIDR</p><p></p><p>TKG shared services network CIDR</p><p>|Harbor Registry|TCP:443|<p>Allows components to retrieve container images. </p><p>This registry can be a local or a public image registry. </p>|TKG Mgmt Tier-1 Gateway|
|<p>TKG management network CIDR</p><p></p><p>TKG shared services network CIDR</p><p>|TKG Management VIP Network |TCP:6443|For management cluster to configure workload cluster.<br><br>Allows shared cluster to register with management cluster.|TKG Mgmt Tier-1 Gateway|
|<p>TKG management network CIDR</p><p></p><p>TKG shared services network CIDR</p><p>|NSX Advanced Load Balancer management network CIDR|TCP:443|Allow Avi Kubernetes Operator (AKO) and AKO Operator (AKOO) access to NSX ALB controller.|TKG Mgmt Tier-1 Gateway|
|TKG workload network CIDR|DNS Server<br>NTP Server|UDP:53<br>UDP:123|DNS Service <br>Time Synchronization|TKG Workload Tier-1 Gateway|
|TKG workload network CIDR|vCenter Server|TCP:443|Allows components to access vCenter to create VMs and storage volumes.|TKG Workload Tier-1 Gateway|
|TKG workload network CIDR|Harbor Registry|TCP:443|<p>Allows components to retrieve container images. </p><p>This registry can be a local or a public image registry. </p>|TKG Workload Tier-1 Gateway|
|TKG workload network CIDR|TKG Management VIP Network |TCP:6443|Allow TKG workload clusters to register with TKG management cluster.|TKG Workload Tier-1 Gateway|
|TKG workload network CIDR|NSX Advanced Load Balancer management network CIDR|TCP:443|Allow Avi Kubernetes Operator (AKO) and AKO Operator (AKOO) access to NSX ALB controller.|TKG Workload Tier-1 Gateway|
|deny-all|any|any|deny|All Tier-1 gateways|

## Design Recommendations

### NSX Advanced Load Balancer Recommendations

The following table provides the recommendations for configuring NSX Advanced Load Balancer in a Tanzu Kubernetes Grid environment:

|**Decision ID**|**Design Decision**|**Design Justification**|**Design Implications**|
| --- | --- | --- | --- |
|TKO-ALB-001|Deploy NSX ALB controller cluster nodes on a network dedicated to NSX ALB.|Isolate NSX ALB traffic from infrastructure management traffic and Kubernetes workloads.|Allows ease of management for the controllers.<br> Additional Network (VLAN) is required.|
|TKO-ALB-002|Deploy 3 NSX ALB controller nodes.|To achieve high availability for the NSX ALB platform.In clustered mode, NSX ALB availability is not impacted by an individual controller node failure. The failed node can be removed from the cluster and redeployed if recovery is not possible.|<br> Clustered mode requires more compute and storage resources.</br>|
|TKO-ALB-003|Initial setup should be done only on one NSX ALB controller VM out of the three deployed, to create an NSX ALB controller cluster.|NSX ALB controller cluster is created from an initialized NSX ALB controller which becomes the cluster leader.<br> Follower NSX ALB controller nodes need to be uninitialized to join the cluster.|NSX ALB controller cluster creation fails if more than one NSX ALB controller is initialized.|
|TKO-ALB-004|Use static IP addresses for the NSX ALB controllers.|NSX ALB controller cluster uses management IP addresses to form and maintain quorum for the control plane cluster. Any changes to management IP addresses are disruptive.|NSX ALB Controller control plane might go down if the management IP addresses of the controller node changes.|
|TKO-ALB-005|Use NSX ALB IPAM for service engine data network and virtual services. |Guarantees IP address assignment for service engine data NICs and virtual services.|Removes the corner case scenario when the DHCP server runs out of the lease or is down.|
|TKO-ALB-006|Reserve an IP address in the NSX ALB management subnet to be used as the cluster IP address for the controller cluster.|NSX ALB portal is always accessible over cluster IP address regardless of a specific individual controller node failure.|NSX ALB administration is not affected by an individual controller node failure.|
|TKO-ALB-007|Shared service engines for the same type of workload (dev/test/prod) clusters.|Minimize the licensing cost|<p>Each service engine contributes to the CPU core capacity associated with a license.</p><p></p><p>Sharing service engines can help reduce the licensing cost. </p>|
|TKO-ALB-008|Configure anti-affinity rules for the NSX ALB controller cluster.|This is to ensure that no two controllers end up in same ESXi host and thus avoid single point of failure.|Anti-Affinity rules need to be created manually.|
|TKO-ALB-009|Configure backup for the NSX ALB Controller cluster.|Backups are required if the NSX ALB Controller becomes inoperable or if the environment needs to be restored from a previous state.|To store backups, a SCP capable backup location is needed. SCP is the only supported protocol currently.|
|TKO-ALB-010|Create an NSX-T Cloud connector on NSX ALB controller for each NSX transport zone requiring load balancing.|An NSX-T Cloud connector configured on the NSX ALB controller provides load balancing for workloads belonging to a transport zone on NSX-T.|None|
|TKO-ALB-011|Configure Remote logging for NSX ALB Controller to send events on Syslog.|For operations teams to be able to centrally monitor NSX ALB and escalate alerts events must be sent from the NSX ALB Controller|  Additional Operational Overhead.<br> Additional infrastructure Resource.|
|TKO-ALB-012|Use LDAP/SAML based Authentication for NSX ALB| Helps to maintain Role based Access Control | Additional Configuration is required.|

### NSX Advanced Load Balancer Service Engine Recommendations

|**Decision ID**|**Design Decision**|**Design Justification**|**Design Implications**|
| --- | --- | --- | --- |
|TKO-ALB-SE-001|Configure SE Group for Active/Active HA mode.|Provides optimum resiliency, performance, and utilization.|Certain applications might not work in Active/Active mode. For instance, applications that require preserving client IP address. In such cases, use the legacy Active/Standby HA mode.|
|TKO-ALB-SE-002|Configure anti-affinity rule for the SE VMs.|This is ensure that no two SEs in the same SE group end up on same ESXi Host and thus avoid single point of failure.|Anti-Affinity rules need to be created manually.|
|TKO-ALB-SE-003|Configure CPU and memory reservation for the SE VMs.|This is to ensure that service engines don't compete with other VMs during resource contention.|CPU and memory reservation is configured at SE group level.|
|TKO-ALB-SE-004|Enable 'Dedicated dispatcher CPU' on SE groups that contain the SE VMs of 4 or more vCPUs.<br>Note: This setting must be enabled on SE groups that are servicing applications that have high network requirement.|This enables a dedicated core for packet processing enabling high packet pipeline on the SE VMs.|None.|
|TKO-ALB-SE-005|Dedicated Service Engine Group for the TKG Management|SE resources are guaranteed for TKG Management Stack and provides data path segregation for Management and Tenant Application |Dedicated service engine Groups increase licensing cost. </p>||
|TKO-ALB-SE-006|Dedicated Service Engine Group for the TKG Workload Clusters Depending on the nature and type of workloads (dev/prod/test)|SE resources are guaranteed for single or set of workload clusters and provides data path segregation for Tenant Application hosted on workload clusters |Dedicated service engine Groups increase licensing cost. </p>|
|TKO-ALB-SE-007|Set 'Placement across the Service Engines' setting to 'distributed'.|This allows for maximum fault tolerance and even utilization of capacity.| None
|TKO-ALB-SE-008|Set the SE size to a minimum 2vCPU and 4GB of Memory|This configuration should meet the most generic use case | For services that require higher throughput, these configuration needs to be investigated and modified accordingly.
|TKO-ALB-SE-009|Enable ALB Service Engine Self Elections|Enable SEs to elect a primary amongst themselves in the absence of connectivity to the NSX ALB controller|None|
## Installation Experience

Tanzu Kubernetes Grid management cluster is the first component that you deploy to get started with Tanzu Kubernetes Grid.

You can deploy the management cluster in one of the following ways:

- Run the Tanzu Kubernetes Grid installer, a wizard interface that guides you through the process of deploying a management cluster.

- Create and edit YAML configuration files, and use them to deploy a management cluster with the CLI commands. This is the recommended method if you are installing a Tanzu Kubernetes Grid management cluster in an air-gapped environment.

By using the current version of the The Tanzu Kubernetes Grid Installation user interface, you can install Tanzu Kubernetes Grid on VMware vSphere, AWS, and Microsoft Azure. The UI provides a guided experience tailored to the IaaS, in this case on VMware vSphere backed by NSX-T Data Center networking.

![TKG Supported IaaS Platforms](img/tkg-nsxt-airgap/tkg-nsxt-airgap03.png)

The installation process takes you through the setup of a `management cluster` on your vSphere with NSX-T environment. Once the management cluster is deployed, you can make use of Tanzu CLI to deploy Tanzu Kubernetes shared services and workload clusters.

To deploy the Tanzu Kubernetes Grid management cluster directly from CLI, see the supplemental information [Cluster Deployment Parameters](#deployment-parameters) for a sample yaml file used for deployment.

## Kubernetes Ingress Routing

The default installation of Tanzu Kubernetes Grid does not have any default ingress controller deployed. Users can use Contour (available for installation through Tanzu Packages), or any third-party ingress controller of their choice.

Contour is an open-source controller for Kubernetes ingress routing. Contour can be installed in the shared services cluster on any Tanzu Kubernetes cluster. Deploying Contour is a prerequisite if you want to deploy the Prometheus, Grafana, and Harbor packages on a workload cluster.

For more information about Contour, see the [Contour](https://projectcontour.io/) website and [Implementing Ingress Control with Contour](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/2.3/using-tkg/workload-packages-contour.html).

Another option is to use the NSX Advanced Load Balancer Kubernetes ingress controller (available only with the NSX ALB Enterprise license) which offers an advanced L7 ingress for containerized applications that are deployed in the Tanzu Kubernetes workload cluster.

![NSX ALB Ingress Capabilities](img/tkg-nsxt-airgap/tkg-nsxt-airgap04.png)

For more information about the NSX ALB ingress controller, see [Configuring L7 Ingress with NSX Advanced Load Balancer](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/2.3/tkg-deploy-mc/mgmt-reqs-network-nsx-alb-ingress.html).

The following table provides general recommendations on when you should use a specific ingress controller for your Kubernetes environment.

|**Ingress Controller**|**Use Cases**|
| --- | --- |
|Contour|<p>Use Contour when only north-south traffic is needed in a Kubernetes cluster. You can apply security policies for north-south traffic by defining the policies in the applications manifest file.</p><p></p><p>It's a reliable solution for simple Kubernetes workloads. </p>|
|NSX Advanced Load Balancer ingress controller|<p>Use NSX Advanced Load Balancer ingress controller when a containerized application requires features like local and global server load balancing (GSLB), web application firewall (WAF), performance monitoring, direct routing from LB to pod, etc. </p><p></p>|

### NSX Advanced Load Balancer as an L4+L7 Ingress Service Provider

NSX Advanced Load Balancer provides an L4+L7 load balancing solution for vSphere. It includes a Kubernetes operator that integrates with the Kubernetes API to manage the lifecycle of load balancing and ingress resources for workloads.

Legacy ingress services for Kubernetes include multiple disparate solutions. The services and products contain independent components that are difficult to manage and troubleshoot. The ingress services have reduced observability capabilities with little analytics, and they lack comprehensive visibility into the applications that run on the system. Cloud-native automation is difficult in the legacy ingress services.

In comparison to the legacy Kubernetes ingress services, NSX Advanced Load Balancer has comprehensive load balancing and ingress services features. As a single solution with a central control, NSX Advanced Load Balancer is easy to manage and troubleshoot. NSX Advanced Load Balancer supports real-time telemetry with an insight into the applications that run on the system. The elastic auto-scaling and the decision automation features highlight the cloud-native automation capabilities of NSX Advanced Load Balancer.

NSX Advanced Load Balancer also lets you configure L7 ingress for your workload clusters by using one of the following options:

- L7 ingress in ClusterIP mode
- L7 ingress in NodePortLocal mode
- L7 ingress in NodePort mode
- NSX Advanced Load Balancer L4 ingress with Contour L7 ingress

#### L7 Ingress in ClusterIP Mode

This option enables NSX Advanced Load Balancer L7 ingress capabilities, including sending traffic directly from the service engines (SEs) to the pods, preventing multiple hops that other ingress solutions need when sending packets from the load balancer to the right node where the pod runs. The NSX Advanced Load Balancer controller creates a virtual service with a backend pool with the pod IP addresses which helps send the traffic directly to the pods.

However, each workload cluster needs a dedicated SE group for Avi Kubernetes Operator (AKO) to work, which could increase the number of SEs you need for your environment. This mode is used when you have a small number of workload clusters.

#### L7 Ingress in NodePort Mode

The NodePort mode is the default mode when AKO is installed on Tanzu Kubernetes Grid. This option allows your workload clusters to share SE groups and is fully supported by VMware. With this option, the services of your workloads must be set to NodePort instead of ClusterIP even when accompanied by an ingress object. This ensures that NodePorts are created on the worker nodes and traffic can flow through the SEs to the pods via the NodePorts. Kube-Proxy, which runs on each node as DaemonSet, creates network rules to expose the application endpoints to each of the nodes in the format “NodeIP:NodePort”. The NodePort value is the same for a service on all the nodes. It exposes the port on all the nodes of the Kubernetes Cluster, even if the pods are not running on it.

#### L7 Ingress in NodePortLocal Mode

This feature is supported only with Antrea CNI. You must enable this feature on a workload cluster before its creation. The primary difference between this mode and the NodePort mode is that the traffic is sent directly to the pods in your workload cluster through node ports without interfering Kube-proxy. With this option, the workload clusters can share SE groups. Similar to the ClusterIP Mode, this option avoids the potential extra hop when sending traffic from the NSX Advanced Load Balancer SEs to the pod by targeting the right nodes where the pods run.

Antrea agent configures NodePortLocal port mapping rules at the node in the format “NodeIP:Unique Port” to expose each pod on the node on which the pod of the service is running. The default range of the port number is 61000-62000. Even if the pods of the service are running on the same Kubernetes node, Antrea agent publishes unique ports to expose the pods at the node level to integrate with the load balancer.

#### NSX ALB L4 Ingress with Contour L7 Ingress

This option does not have all the NSX Advanced Load Balancer L7 ingress capabilities but uses it for L4 load balancing only and leverages Contour for L7 ingress. This also allows sharing SE groups across workload clusters. This option is supported by VMware and it requires minimal setup.



### NSX Advanced Load Balancer L7 Ingress Recommendations

|**Decision ID**|**Design Decision**|**Design Justification**|**Design Implications**|
| --- | --- | --- | --- |
|TKO-ALB-L7-001|Deploy NSX ALB L7 ingress in NodePortLocal mode.| 1. Network hop efficiency is gained by bypassing the kube-proxy to receive external traffic to applications.<br>2. TKG clusters can share SE groups, optimizing or maximizing capacity and license consumption.<br>3. Pod's node port only exist on nodes where the Pod is running, and it helps to reduce the east-west traffic and encapsulation overhead.<br>4. Better session persistence. |1. This is supported only with Antrea CNI.<br>2. `NodePortLocal` mode is currently only supported for nodes running Linux or Windows with IPv4 addresses. Only TCP and UDP service ports are supported (not SCTP). For more information, see [Antrea NodePortLocal Documentation](https://antrea.io/docs/v1.11.1/docs/node-port-local/).|

VMware recommends using NSX Advanced Load Balancer L7 ingress with the NodePortLocal mode as it gives you a distinct advantage over other modes as mentioned below:

- Although there is a constraint of one SE group per Tanzu Kubernetes Grid cluster, which results in increased license capacity, ClusterIP provides direct communication to the Kubernetes pods, enabling persistence and direct monitoring of individual pods.

- NodePort resolves the issue for needing a SE group per workload cluster, but a kube-proxy is created on each and every workload node even if the pod doesn’t exist in it, and there’s no direct connectivity. Persistence is then broken.

- NodePortLocal is the best of both use cases. Traffic is sent directly to the pods in your workload cluster through node ports without interfering with kube-proxy. SE groups can be shared and load balancing persistence is supported.

### Network Recommendations

The key network recommendations for a production-grade Tanzu Kubernetes Grid deployment with NSX-T Data Center Networking are as follows:

|**Decision ID**|**Design Decision**|**Design Justification**|**Design Implications**|
| --- | --- | --- | --- |
|TKO-NET-001|Use separate logical segments for management cluster, shared services cluster, workload clusters, and VIP network.|To have a flexible firewall and security policies.|Sharing the same network for multiple clusters can complicate firewall rules creation.|
|TKO-NET-002|Configure DHCP  for each TKG cluster network.|Tanzu Kubernetes Grid does not support static IP address assignments for Kubernetes VM components.|IP address pool can be used for the TKG clusters in absence of the DHCP.|
|TKO-NET-003|Use NSX for configuring DHCP|This avoids setting up dedicated DHCP server for TKG.|For a simpler configuration, make use of the DHCP local server to provide DHCP services for required segments.|
|TKO-NET-004|Create a overlay-backed NSX segment connected to a Tier-1 gateway for the SE management for the NSX-T Cloud of overlay type.|This network is used for the controller to the SE connectivity.|None|
|TKO-NET-005|Create a overlay-backed NSX segment as data network for the NSX-T Cloud of overlay type.|The SEs are placed on overlay segments created on Tier-1 gateway.|None|

With Tanzu Kubernetes Grid 2.3 and above, you can use Node IPAM, which simplifies the allocation and management of IP addresses for cluster nodes within the cluster. This eliminates the need for external DHCP configuration.

The Node IPAM can be configured for standalone management clusters on vSphere, and the associated class-based workload clusters that they manage. In the Tanzu Kubernetes Grid Management configuration file, a dedicated Node IPAM pool is defined for the management cluster only.

The following types of Node IPAM pools are available for workload clusters:

- **InClusterIPPool -** Configures IP pools that are only available to workload clusters in the same management cluster namespace. For example, default.

- **GlobalInClusterIPPool -** Configures IP pools with addresses that can be allocated to workload clusters across multiple namespaces.

Node IPAM in TKG provides flexibility in managing IP addresses for both management and workload clusters that allows efficient IP allocation and management within the cluster environment.

### Tanzu Kubernetes Grid Clusters Recommendations

|**Decision ID**|**Design Decision**|**Design Justification**|**Design Implications**|
| --- | --- | --- | --- |
|TKO-TKG-001|Use NSX ALB as your control plane endpoint provider and for application load balancing.|Eliminates the requirement for an external load balancer and additional configuration changes on your Tanzu Kubernetes Grid clusters.|Add NSX ALB License cost to the solution.|
|TKO-TKG-002|Use NSX Advanced Load Balancer as your control plane endpoint provider and for application load balancing.|Eliminates the requirement for an external load balancer and additional configuration changes on your Tanzu Kubernetes Grid clusters.|Adds NSX Advanced Load Balancer License cost to the solution.|
|TKO-TKG-003|Deploy Tanzu Kubernetes Management cluster in large form factor.|Large form factor should suffice to integrate TKG Management cluster with TMC, pinniped and Velero. This must be capable of accommodating 100+ Tanzu Workload Clusters.|<p>Consume more resources from infrastructure.</p>|
|TKO-TKG-004|Deploy the Tanzu Kubernetes Cluster with prod plan(Management and Workload Clusters).|Deploying three control plane nodes ensures the state of your Tanzu Kubernetes Cluster control plane stays healthy in the event of a node failure.|<p>Consume more resources from infrastructure.</p>|
|TKO-TKG-005|Enable identity management for Tanzu Kubernetes Grid clusters.|To avoid usage of administrator credentials and ensure that required users with right roles have access to Tanzu Kubernetes Grid clusters.|<p>Required external Identity Management.</p>
|TKO-TKG-006|Enable MachineHealthCheck for TKG clusters.|vSphere HA and MachineHealthCheck interoperability work together to enhance workload resiliency.|NA|

## Tanzu Kubernetes Grid Monitoring

In an air-gapped environment, monitoring for the Tanzu Kubernetes clusters is provided through [Prometheus](https://prometheus.io/) and [Grafana](https://grafana.com/).

- Prometheus is an open-source system monitoring and alerting toolkit. It can collect metrics from target clusters at specified intervals, evaluate rule expressions, display the results, and trigger alerts if certain conditions arise. The Tanzu Kubernetes Grid implementation of Prometheus includes **Alert Manager**, which you can configure to notify you when certain events occur.
- Grafana is open-source visualization and analytics software. It allows you to query, visualize, alert on, and explore your metrics no matter where they are stored.

Both Prometheus and Grafana are installed through user-managed Tanzu packages by creating the deployment manifests and invoking the `tanzu package install` command to deploy the packages in the Tanzu Kubernetes clusters.

The following diagram shows how the monitoring components on a cluster interact.

![TKG Monitoring using Prometheus and Grafana](img/tkg-nsxt-airgap/tkg-nsxt-airgap05.png)

You can use out-of-the-box Kubernetes dashboards or you can create new dashboards to monitor compute, network, and storage utilization of Kubernetes objects such as Clusters, Namespaces, Pods, etc. See the sample dashboards shown below:

### Namespace (Pods) Compute Resources Utilization Dashboard

![Namespace Resource Utilization Dashboard](img/tkg-nsxt-airgap/tkg-nsxt-airgap06.png)

### Namespace (Pods) Networking Utilization Dashboard

![Namespace Network Utilization Dashboard](img/tkg-nsxt-airgap/tkg-nsxt-airgap07.png)

### API Server Availability Dashboard

![API Server Availability Dashboard](img/tkg-nsxt-airgap/tkg-nsxt-airgap08.png)

### Cluster Compute Resources Utilization Dashboard

![Cluster Compute Resources Utilization Dashboard](img/tkg-nsxt-airgap/tkg-nsxt-airgap09.png)

## Container Registry

Tanzu Kubernetes Grid includes Harbor as a container registry. Harbor provides a location for pushing, pulling, storing, and scanning container images used in your Kubernetes clusters.

Harbor registry is used for day-2 operations of the Tanzu Kubernetes workload clusters. Typical day-2 operations include tasks such as pulling images from Harbor for application deployment, pushing custom images to Harbor, etc.

You may use one of the following methods to install Harbor:

- [**Tanzu Kubernetes Grid Package deployment**](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/2.3/using-tkg/workload-packages-harbor.html) - VMware recommends this installation method for general use cases. The Tanzu packages, including Harbor, must either be pulled directly from VMware or be hosted in an internal registry.
 
- [**VM-based deployment using OVA**](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/2.3/tkg-deploy-mc/mgmt-reqs-harbor.html) - VMware recommends this installation method in cases where Tanzu Kubernetes Grid is being installed in an air-gapped or Internet-restricted environment, and no pre-existing image registry exists to host the Tanzu Kubernetes Grid system images. VM-based deployments are only supported by VMware Global Support Services to host the system images for air-gapped or Internet-restricted deployments. Do not use this method for hosting application images.

If you are deploying Harbor without a publicly signed certificate, you must include the Harbor root CA in your Tanzu Kubernetes Grid clusters. To do so, follow the procedure in [Trust Custom CA Certificates on Cluster Nodes](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/2.3/using-tkg/workload-clusters-secret.html).

![Harbor Container Registry](img/tkg-nsxt-airgap/tkg-nsxt-airgap10.jpg)

## Tanzu Kubernetes Grid Logging

Metrics and logs are critical for any system or application as they provide insights into the activities of the system or the application. It is important to have a central place to observe a multitude of metrics and log sources from multiple endpoints.
 
Log processing and forwarding in Tanzu Kubernetes Grid is provided via [Fluent Bit](https://fluentbit.io/). Fluent bit binaries are available as part of extensions and can be installed on management cluster or in workload cluster. Fluent Bit is a light-weight log processor and forwarder that allows you to collect data and logs from different sources, unify them, and send them to multiple destinations. VMware Tanzu Kubernetes Grid includes signed binaries for Fluent Bit that you can deploy on management clusters and on Tanzu Kubernetes clusters to provide a log-forwarding service.
 
Fluent Bit makes use of the Input Plug-ins, the filters, and the Output Plug-ins. The Input Plug-ins define the source from where it can collect data, and the
Output plug-ins define the destination where it should send the information. The Kubernetes filter will enrich the logs with Kubernetes metadata, specifically labels and annotations. Once you configure Input and Output plug-ins on the Tanzu Kubernetes Grid cluster. Fluent Bit is installed as a user-managed package.
 
Fluent Bit integrates with logging platforms such as VMware Aria Operations for Logs, Elasticsearch, Kafka, Splunk, or an HTTP endpoint. For more details about configuring Fluent Bit to your logging provider, see [Implement Log Forwarding with Fluent Bit](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/2.3/using-tkg/workload-packages-fluentbit.html).

## Bring Your Own Images for Tanzu Kubernetes Grid Deployment

You can build custom machine images for Tanzu Kubernetes Grid to use as a VM template for the management and Tanzu Kubernetes (workload) cluster nodes that it creates. Each custom machine image packages a base operating system (OS) version and a Kubernetes version, along with any additional customizations, into an image that runs on vSphere, Microsoft Azure infrastructure, and AWS (EC2) environments.

A custom image must be based on the operating system (OS) versions that are supported by Tanzu Kubernetes Grid. The table below provides a list of the operating systems that are supported for building custom images for Tanzu Kubernetes Grid.

|**vSphere**|**AWS**|**Azure**|
| --- | --- | --- |
|Ubuntu 20.04</p><p>Ubuntu 18.04</p><p>RHEL 8</p><p>Photon OS 3</p><p>Windows 2019</p>|<p>Ubuntu 20.04</p><p>Ubuntu 18.04</p><p>Amazon Linux 2</p>|<p>Ubuntu 20.04</p><p>Ubuntu 18.04</p>|

For additional information on building custom images for Tanzu Kubernetes Grid, see [Build Machine Images](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/2.3/tkg-deploy-mc/mgmt-byoi-index.html).

- [Linux Custom Machine Images](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/2.3/tkg-deploy-mc/mgmt-byoi-linux.html)

- [Windows Custom Machine Images](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/2.3/tkg-deploy-mc/mgmt-byoi-windows.html)

## Compliance and Security

VMware published Tanzu Kubernetes releases (TKrs), along with compatible versions of Kubernetes and supporting components, use the latest stable and generally-available update of the OS version that they package. They contain all current CVE and USN fixes, as of the day that the image is built. The image files are signed by VMware and have file names that contain a unique hash identifier.

VMware provides FIPS-capable Kubernetes OVA, which can be used to deploy FIPS compliant Tanzu Kubernetes Grid management and workload clusters. Tanzu Kubernetes Grid core components such as Kubelet, Kube-apiserver, Kube-controller manager, Kube-proxy, Kube-scheduler, Kubectl, Etcd, Coredns, Containerd, and Cri-tool are made FIPS compliant by compiling them with the [BoringCrypto](https://csrc.nist.gov/projects/cryptographic-module-validation-program/certificate/2964) FIPS modules, an open-source cryptographic library that provides [FIPS 140-2](https://www.nist.gov/standardsgov/compliance-faqs-federal-information-processing-standards-fips) approved algorithms.

## Supplemental Information

### <a id=deployment-parameters> </a> Cluster Deployment Parameters

<!-- /* cSpell:disable */ -->

```yaml
# NSX Advanced Load Balancer details

AVI_CA_DATA_B64: # NSX Advanced Load Balancer Controller Certificate in base64 encoded format.
AVI_CLOUD_NAME: # Name of the cloud that you created in your NSX Advanced Load Balancer deployment.
AVI_CONTROL_PLANE_HA_PROVIDER: "true" # Set to true to enable NSX Advanced Load Balancer as the control plane API server endpoint
AVI_CONTROL_PLANE_NETWORK: # Optional. Defines the VIP network of the workload cluster’s control plane. Use when you want to configure a separate VIP network for the workload clusters. This field is optional, and if it is left empty, it will use the same network as AVI_DATA_NETWORK.
AVI_CONTROL_PLANE_NETWORK_CIDR: # Optional. The CIDR of the subnet to use for the workload cluster’s control plane. Use when you want to configure a separate VIP network for the workload clusters. This field is optional, and if it is left empty, it will use the same network as AVI_DATA_NETWORK_CIDR.
AVI_CONTROLLER: # The IP or hostname of the NSX Advanced Load Balancer controller.
AVI_DATA_NETWORK:  # The network which you want to use a VIP network for the applications deployed in the workload cluster.
AVI_DATA_NETWORK_CIDR: # The CIDR of the network that you have chosen for the application load balancing in the workload cluster.
AVI_ENABLE: "true" # Enables NSX Advanced Load Balancer as a load balancer for workloads.
AVI_LABELS: # Optional labels in the format key: value. When set, NSX Advanced Load Balancer is enabled only on workload clusters that have this label.
AVI_MANAGEMENT_CLUSTER_CONTROL_PLANE_VIP_NETWORK_NAME: # The CIDR of the subnet to use for the management cluster’s control plane. Use when you want to configure a separate VIP network for the management cluster’s control plane. This field is optional, and if it is left empty, it will use the same network as AVI_DATA_NETWORK_CIDR.
AVI_MANAGEMENT_CLUSTER_CONTROL_PLANE_VIP_NETWORK_CIDR: # The CIDR of the network that you have chosen for the control plane HA of the management cluster.
AVI_MANAGEMENT_CLUSTER_SERVICE_ENGINE_GROUP: # Optional. Specifies the name of the Service Engine group that is to be used by AKO in the management cluster. This field is optional, and if it is left empty, it will use the same network as AVI_SERVICE_ENGINE_GROUP.
AVI_MANAGEMENT_CLUSTER_VIP_NETWORK_NAME: # The network that you want to use as load balancer network for any applications deployed in the shared services or management cluster.
AVI_MANAGEMENT_CLUSTER_VIP_NETWORK_CIDR: # Subnet CIDR of the VIP network choosen for application load balancing in the shared services or management cluster.
AVI_NSXT_T1LR: # UUID of the tier-1 gateway in NSX where the logical segment chosen for TKG management network is connected.
AVI_PASSWORD: # Password of the NSX ALB Controller admin user in th base 64 encoded format
AVI_SERVICE_ENGINE_GROUP: # Name of the Service Engine Group configured in NSX ALB
AVI_SERVICE_ENGINE_GROUP: # Service Engine group name for the workload clusters.
AVI_USERNAME: admin

# Common Variables

CLUSTER_CIDR: # The CIDR range to use for pods.
SERVICE_CIDR: # The CIDR range to use for the Kubernetes services.
CLUSTER_NAME: # The name of the TKG Management Cluster that must comply with DNS hostname requirements as outlined in https://datatracker.ietf.org/doc/html/rfc952
CLUSTER_PLAN: # Can be set to dev, prod or custom. The dev plan deploys a cluster with a single control plane node. The prod plan deploys a highly available cluster with three control plane nodes.
ENABLE_AUDIT_LOGGING: # Audit logging for the Kubernetes API server. The default value is false. To enable audit logging, set the variable to true.
ENABLE_CEIP_PARTICIPATION: #The default value is true. false opts out of the VMware Customer Experience Improvement Program.
ENABLE_MHC: "true/false" # When set to true, machine health checks are enabled for management cluster control plane and worker nodes. 
IDENTITY_MANAGEMENT_TYPE: <none/oidc/ldap> # Set oidc or ldap when enabling centralized authentication for management cluster access.
INFRASTRUCTURE_PROVIDER: # For vSphere platform set this value to vsphere.
DEPLOY_TKG_ON_VSPHERE7: "true" # Set this to true to deploy TKGm on vSphere.

# Node Configuration

OS_ARCH: amd64
OS_NAME: # Defaults to ubuntu for Ubuntu LTS. Can also be photon for Photon OS on vSphere
OS_VERSION: "3"

# Proxy Configuration

TKG_HTTP_PROXY_ENABLED: "true/false" # To send outgoing HTTP(S) traffic from the management cluster to a proxy, for example in an internet-restricted environment, set this to true.
TKG_IP_FAMILY: ipv4
VSPHERE_CONTROL_PLANE_ENDPOINT: # If you use NSX Advanced Load Balancer, leave this field blank.

# Control Plane and Worker VM sizing

VSPHERE_CONTROL_PLANE_DISK_GIB: "40" # The size in gigabytes of the disk for the control plane node VMs. Include the quotes ("")
VSPHERE_CONTROL_PLANE_MEM_MIB: "16384" # The amount of memory in megabytes for the control plane node VMs
VSPHERE_CONTROL_PLANE_NUM_CPUS: "4" # The number of CPUs for the control plane node VMs. Include the quotes (""). Must be at least 2.
VSPHERE_WORKER_DISK_GIB: "40" # The size in gigabytes of the disk for the worker node VMs. Include the quotes ("")
VSPHERE_WORKER_MEM_MIB: "16384" # The amount of memory in megabytes for the worker node VMs. Include the quotes ("")
VSPHERE_WORKER_NUM_CPUS: "4" # The number of CPUs for the worker node VMs. Include the quotes (””). Must be at least 2.

# vSphere Infrastructure details

VSPHERE_DATACENTER: # The name of the datacenter in which to deploy the TKG management cluster.
VSPHERE_DATASTORE: # The name of the vSphere datastore where TKG cluster VMs will be stored.
VSPHERE_FOLDER: # The name of an existing VM folder in which to place TKG VMs.
VSPHERE_INSECURE: # Optional. Set to true or false to bypass thumbprint verification. If false, set VSPHERE_TLS_THUMBPRINT
VSPHERE_NETWORK: # The name of an existing vSphere network where TKG management cluster control plane and worker VMs will be connected.
VSPHERE_PASSWORD: # The password for the vSphere user account in base64 encoded format.
VSPHERE_RESOURCE_POOL: # The name of an existing resource pool in which to place TKG cluster.
VSPHERE_SERVER: # The IP address or FQDN of the vCenter Server instance on which to deploy the Tanzu Kubernetes cluster.
VSPHERE_SSH_AUTHORIZED_KEY: # Paste in the contents of the SSH public key that you created in on the bootstrap machine.
VSPHERE_TLS_THUMBPRINT: # if VSPHERE_INSECURE is false. The thumbprint of the vCenter Server certificate.
VSPHERE_USERNAME: # A vSphere user account, including the domain name, with the required privileges for Tanzu Kubernetes Grid operation
TKG_CUSTOM_IMAGE_REPOSITORY: # IP address or FQDN of your private registry.
TKG_CUSTOM_IMAGE_REPOSITORY_CA_CERTIFICATE: # Set if your private image registry uses a self-signed certificate. Provide the CA certificate in base64 encoded format.
TKG_CUSTOM_IMAGE_REPOSITORY_SKIP_TLS_VERIFY: "rue/false" # Optional. Set to true if your private image registry uses a self-signed certificate and you do not use TKG_CUSTOM_IMAGE_REPOSITORY_CA_CERTIFICATE. Because the Tanzu connectivity webhook injects the Harbor CA certificate into cluster nodes, TKG_CUSTOM_IMAGE_REPOSITORY_SKIP_TLS_VERIFY should always be set to false when using Harbor.
```
<!-- /* cSpell:enable */ -->

For a full list of configurable values, see [Tanzu CLI Configuration File Variable Reference](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/2.3/tkg-deploy-mc/mgmt-deploy-config-ref.html).

## Configure Node Sizes

The Tanzu CLI creates the individual nodes of management clusters and Tanzu Kubernetes clusters according to the settings that you provide in the configuration file. 

On vSphere, you can configure all node VMs to have the same predefined configurations, set different predefined configurations for control plane and worker nodes, or customize the configurations of the nodes. By using these settings, you can create clusters that have nodes with different configurations from the management cluster nodes. You can also create clusters in which the control plane nodes and worker nodes have different configurations.

### Use Predefined Node Configurations

The Tanzu CLI provides the following predefined configurations for cluster nodes:

|**Size**|**CPU**|**Memory (in GB)**|**Disk (in GB)**|
| --- | --- | --- | --- |
|Small|2|4|20|
|Medium|2|8|40|
|Large|4|16|40|
|Extra-large|8|32|80|

To create a cluster in which all of the control plane and worker node VMs are the same size, specify the `SIZE` variable. If you set the `SIZE` variable, all nodes are created with the configuration that you set.

- `SIZE: "large"`

To create a cluster in which the control plane and worker node VMs are of different sizes, specify the `CONTROLPLANE_SIZE` and `WORKER_SIZE` options.

- `CONTROLPLANE_SIZE: "medium"`
- `WORKER_SIZE: "large"`

You can combine the `CONTROLPLANE_SIZE` and `WORKER_SIZE` options with the `SIZE` option. For example, if you specify `SIZE: "large"` with `WORKER_SIZE: "extra-large"`, the control plane nodes are set to `large` and worker nodes are set to `extra-large`.

- `SIZE: "large"`
- `WORKER_SIZE: "extra-large"`

### Define Custom Node Configurations

You can customize the configuration of the nodes rather than using the predefined configurations.

To use the same custom configuration for all nodes, specify the `VSPHERE_NUM_CPUS`, `VSPHERE_DISK_GIB`, and `VSPHERE_MEM_MIB` options.

- `VSPHERE_NUM_CPUS: 2`
- `VSPHERE_DISK_GIB: 40`
- `VSPHERE_MEM_MIB: 4096`

To define different custom configurations for control plane nodes and worker nodes, specify the `VSPHERE_CONTROL_PLANE_*` and `VSPHERE_WORKER_*`

- `VSPHERE_CONTROL_PLANE_NUM_CPUS: 2`
- `VSPHERE_CONTROL_PLANE_DISK_GIB: 20`
- `VSPHERE_CONTROL_PLANE_MEM_MIB: 8192`
- `VSPHERE_WORKER_NUM_CPUS: 4`
- `VSPHERE_WORKER_DISK_GIB: 40`
- `VSPHERE_WORKER_MEM_MIB: 4096`

## NSX Advanced Load Balancer Sizing Guidelines

### NSX ALB Controller Sizing Guidelines

Regardless of NSX Advanced Load Balancer Controller configuration, each controller cluster can achieve up to 5000 virtual services, which is a hard limit. For more information, see [Sizing Compute and Storage Resources for NSX Advanced Load Balancer Controller(s)](https://avinetworks.com/docs/22.1/avi-controller-sizing/).

|**Controller Size**|**VM Configuration**|**Virtual Services**|**NSX Advanced Load Balancer SE Scale**|
| --- | --- | --- | --- |
|Essentials|4 vCPUs, 24 GB RAM|0-50|0-10|
|Small|6 vCPUs, 24 GB RAM|0-200|0-100|
|Medium|10 vCPUs, 32 GB RAM|200-1000|100-200|
|Large|16 vCPUs, 48 GB RAM|1000-5000|200-400|

### Service Engine Sizing Guidelines

For guidance on sizing your service engines (SEs), see [Sizing Compute and Storage Resources for NSX Advanced Load Balancer Service Engine(s)](https://avinetworks.com/docs/22.1/sizing-service-engines/).

|**Performance metric**|**1 vCPU core**|
| --- | --- |
|Throughput|4 Gb/s|
|Connections/s|40k|
|SSL Throughput|1 Gb/s|
|SSL TPS (RSA2K)|~600|
|SSL TPS (ECC)|2500|

Multiple performance vectors or features may have an impact on performance.  For instance, to achieve 1 Gb/s of SSL throughput and 2000 TPS of SSL with EC certificates, NSX ALB recommends two cores.

NSX ALB Service Engines may be configured with as little as 1 vCPU core and 1 GB RAM, or up to 36 vCPU cores and 128 GB RAM. Service Engines can be deployed in Active/Active or Active/Standby mode depending on the license tier used. NSX ALB Essentials license doesn’t support Active/Active HA mode for SE. 

## Summary

Tanzu Kubernetes Grid on vSphere on hyper-converged hardware offers high-performance potential, convenience, and addresses the challenges of creating, testing, and updating on-premises Kubernetes platforms in a consolidated production environment. This validated approach will result in a near-production quality installation with all the application services needed to serve combined or uniquely separated workload types through a combined infrastructure solution.

This plan meets many Day-0 needs for quickly aligning product capabilities to full stack infrastructure, including networking, firewalling, load balancing, workload compute alignment, and other capabilities.
