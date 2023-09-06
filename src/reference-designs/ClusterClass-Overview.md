# ClusterClass Overview

ClusterClass is a feature in the Kubernetes Cluster API project that allows you to define the shape of your clusters once and reuse it many times. It consists of collection of templates that define the topology and configuration of a Kubernetes cluster. The templates can be used to create new clusters, or to update existing clusters. 

This can help you to simplify the process of creating and managing multiple Kubernetes clusters, and to make your clusters more consistent and reliable.

![ClusterClass Components](./img/clusterclass/ClusterClass_Components.png)

At a high level the [ClusterClass CRD](https://doc.crds.dev/github.com/kubernetes-sigs/cluster-api/cluster.x-k8s.io/ClusterClass/v1beta1) contains:

- ControlPlane: This includes the reference to the VSphereMachineTemplate used when creating the machines for the cluster’s control plane and the KubeadmControlPlaneTemplate contains the KubeadmConfigSpec for initializing the control plane machines.
- Workers: This includes the reference to the VSphereMachineTemplate used when creating the machines for the cluster’s worker machines and the KubeadmConfigTemplate contains the KubeadmConfigSpec for initializing and joining the worker machines to the control plane.
- Infrastructure: This includes the reference to the VSphereClusterTemplate that contains the vCenter details(vCenter Server endpoint, SSL thumbprint etc) used when creating the cluster 
- Variables: A list of variable definitions, where each variable is defined using [OpenAPI Schema definition](https://github.com/kubernetes/apiextensions-apiserver/blob/master/pkg/apis/apiextensions/types_jsonschema.go).
- Patches: A list of patches, used to change the above mentioned templates for each specific cluster. Varibales definitions defined in the Variables section can also be used in the patches section.

Some of the benefits of using ClusterClass:

- Simplified cluster creation: ClusterClass templates can be used to create new clusters with a single command. This can save you time and effort.
- Consistent clusters: All clusters that are created from the same ClusterClass will have the same topology and configuration. This can help to ensure that your clusters are reliable and predictable.
- Extensible cluster templates: ClusterClass templates can be customized to create clusters that meet the specific needs of your applications.
- Managed clusters: ClusterClass can be used to manage the lifecycle of your clusters. This can help you to automate the process of creating, updating, and deleting clusters.

[Cluster CRD](https://doc.crds.dev/github.com/kubernetes-sigs/cluster-api/cluster.x-k8s.io/Cluster/v1beta1) is used to create, manage the cluster's configuration and state, and delete Kubernetes clusters. For example, you can use the cluster object to update the Kubernetes version, the network configuration, or the number of nodes in the cluster.


At a high level, the configuration of the cluster topology is as follows:

- A reference to the Cluster Class CRD.
- Defining the attributes governing the Cluster's control plane, containing parameters such as the count of replicas, alongside provisions for overriding or appending values to control plane metadata, nodeDrainTimeout, and control plane's MachineHealthCheck.
- A list of machine deployments slated for creation, with each deployment uniquely characterized by:
  - The reference to the MachineDeployment class, which defines the templates to be used this specific MachineDeployment.
  - The number of replicas designated for this MachineDeployment, along with other parameters such as node deployment strategy, machineHealthCheck, nodeDrainTimeout values.
- Specification of the intended Kubernetes version for both the Cluster, encompassing both the control plane and worker nodes.
- The Cluster Topology and MachineDeployments can also be customised using a set of variables through patches as defined the ClusterClass CRD. 


## ClusterClass and Cluster CRD use cases in TKGm:
- ### Private Image Repo Configuration
  - **For New Clusters**: 
    - <https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/2.2/using-tkg-22/workload-clusters-secret.html#custom-ca>
  - **For Existing Clusters**: 
    - <https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/2.2/using-tkg-22/workload-clusters-secret.html#add-custom-ca>
- ### Node Resizing/Vertical Scaling(CPU, Memory)

  - <https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/2.2/using-tkg-22/workload-clusters-scale.html#class-topology>

- ### Creating Clusters using Custom ClusterClass
  -  <https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/2.1/using-tkg-21/workload-clusters-cclass.html>



