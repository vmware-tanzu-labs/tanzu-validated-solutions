## Deploy User-Managed Packages in Workload Clusters

User-managed packages are installed after workload cluster creation. These packages extend the core functionality of Kubernetes clusters created by Tanzu Kubernetes Grid. 

For example, you can install the Contour package to implement ingress control, the Harbor package to configure a private container registry, or the Fluent Bit, Grafana, and Prometheus packages to collect logs and metrics from your clusters.

Tanzu packages can be installed via CLI by invoking the **tanzu package install** command or directly from the Tanzu Mission Control utilizing the [**TMC Catalog**](https://docs.vmware.com/en/VMware-Tanzu-Mission-Control/services/tanzumc-using/GUID-EF35646D-8762-41F1-95E5-D2F35ED71BA1.html) feature.

Installing user-managed packages from Tanzu Mission Control is the recommended method of package installation in Tanzu Kubernetes clusters. 

Log in to the Tanzu Mission Control portal and go to the Catalog page to install user-managed packages on a Tanzu Kubernetes cluster. Select the cluster on which packages will be installed from the Available category.

![](img/tanzu-pkgs/tanzu-pkgs01.png)

### **Install cert-manager**

The first package that you should install on your cluster is the [**cert-manager**](https://github.com/cert-manager/cert-manager) package which adds certificates and certificate issuers as resource types in Kubernetes clusters and simplifies the process of obtaining, renewing, and using those certificates.

Click on the cert-manager package to navigate to the install package page. Click on the Install package button to navigate to the package details page. The package detail page shows the metadata provided by the package author.

On the package detail page, click Install Package.

![](img/tanzu-pkgs/tanzu-pkgs02.png)

On the Install page, provide a name for the installed instance of the package, select the version to install. You can customize the package installation by editing the configuration parameters using the pencil icon under the option Table View. 

After the custom parameters have been supplied, click on the Install package button to initiate the installation.

![](img/tanzu-pkgs/tanzu-pkgs03.png)

The installation of the package roughly takes 5-10 minutes to complete and after successful installation, the status of the package reconciliation reads Succeeded.

![](img/tanzu-pkgs/tanzu-pkgs04.png)

### **Install Contour**

[Contour](https://projectcontour.io/) is an open-source Kubernetes ingress controller providing the control plane for the Envoy edge and service proxy.​ Tanzu Mission Control catalog includes signed binaries for Contour and Envoy, which you can deploy into Tanzu Kubernetes (workload) clusters to provide ingress control services in those clusters.

To install the contour package, click on the browse packages button and select Contour package.

Click on the install package button to initiate the installation.

![](img/tanzu-pkgs/tanzu-pkgs05.png)

Provide a name for the installed package and select the version that you want to install. Package installation can be customized by entering the user-configurable values in yaml format under the option Overlay YAML. 

An example yaml for customizing contour installation is shown below.

<!-- /* cSpell:disable */ -->
```yaml
infrastructure_provider: vsphere
contour:
 configFileContents: {}
 useProxyProtocol: false
 pspNames: "vmware-system-privileged"
envoy:
 service:
   type: LoadBalancer
   disableWait: false
 hostPorts:
   enable: true
 hostNetwork: false
 pspNames: "vmware-system-privileged"
```
<!-- /* cSpell:enable */ -->

For a full list of user-configurable values, please see official [documentation](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.5/vmware-tanzu-kubernetes-grid-15/GUID-packages-ingress-contour.html#optional-configuration-6)

**Note:** You can leave the default settings if don’t intend to customize package installation. 

![](img/tanzu-pkgs/tanzu-pkgs06.png)

Please ensure that the reconcile status for the contour package reflects succeed after installing the package.

![](img/tanzu-pkgs/tanzu-pkgs07.png)

### **Install Harbor**

[Harbor](https://goharbor.io/) is an open-source container registry. Harbor Registry may be used as a private registry for container images that you want to deploy to Tanzu Kubernetes clusters.

To install the harbor package, repeat the steps for package installation. An example yaml for customizing harbor deployment is shown below.

<!-- /* cSpell:disable */ -->
```yaml
hostname: registry.tanzu.lab
enableContourHttpProxy: true
harborAdminPassword: VMware1!
secretKey: aLx51NYPCe32WTbP
database:
  password: Vk13YXJlMSE=
core:
  secret: 37hn3B18aHiK7B9y
  xsrfKey: yJMf2aPfuBlbA80
jobservice:
  secret: xIPQNFnz4PZbAmQ1
registry:
  secret: 4ajswnj9eSBCMny8
notary:
  enabled: true
trivy:
  enabled: true
  skipUpdate: false
metrics:
  enabled: false
```
<!-- /* cSpell:enable */ -->

For a full of user-configurable values, please see official [documentation](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.5/vmware-tanzu-kubernetes-grid-15/GUID-packages-harbor-registry.html#harbordatavalues-file-for-vsphere-7-11)

An example screenshot is shown below for customized harbor installation. 

![](img/tanzu-pkgs/tanzu-pkgs08.png)

Please ensure that the reconcile status for the harbor package reflects succeed after installing the package.

![](img/tanzu-pkgs/tanzu-pkgs09.png)

### **Install Prometheus**

[Prometheus](https://prometheus.io/) is a system and service monitoring system. It collects metrics from configured targets at given intervals, evaluates rule expressions, displays the results, and can trigger alerts if some condition is observed to be true. Alertmanager handles alerts generated by Prometheus and routes them to their receiving endpoints.

To install the Prometheus package, repeat the steps for package installation. An example yaml for customizing Prometheus deployment is shown below.

<!-- /* cSpell:disable */ -->
```yaml
namespace: tanzu-system-dashboards
prometheus:
  service:
    type: LoadBalancer
  pvc:
    storageClassName: "vsan-default-storage-policy"
ingress:
  enabled: true
  virtual_host_fqdn: "prometheus.tanzu.lab"
node_exporter:
  daemonset:
    hostNetwork: false
alertmanager:
  pvc:
    storageClassName: "vsan-default-storage-policy"
```
<!-- /* cSpell:enable */ -->

For a full of user-configurable values, please see official [documentation](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.5/vmware-tanzu-kubernetes-grid-15/GUID-packages-prometheus.html#review-configuration-parameters-9)

An example screenshot is shown below for customized Prometheus installation. 

![](img/tanzu-pkgs/tanzu-pkgs10.png)

Please ensure that the reconcile status for the Prometheus package reflects succeed after installing the package.

![](img/tanzu-pkgs/tanzu-pkgs11.png)

### **Install Grafana**

[Grafana](https://grafana.com/) allows you to query, visualize, alert on, and explore metrics no matter where they are stored. Grafana provides tools to form graphs and visualizations from application data. 

To install the Grafana package, repeat the steps for the package installation. An example yaml for customizing Grafana deployment is shown below.

**Note:** Grafana is configured with Prometheus as a default data source. If you have customized the Prometheus deployment namespace and it is not deployed in the default namespace, **tanzu-system-monitoring**, you need to change the Grafana datasource configuration in the code shown below.

<!-- /* cSpell:disable */ -->
```yaml
ingress:
  virtual_host_fqdn: grafana.tanzu.lab
namespace: tanzu-system-dashboards
```
<!-- /* cSpell:enable */ -->

For a full of user-configurable values, please see official [documentation]https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.5/vmware-tanzu-kubernetes-grid-15/GUID-packages-grafana.html#grafana-package-configuration-parameters-5)

An example screenshot is shown below for customized Grafana installation. 

![](img/tanzu-pkgs/tanzu-pkgs12.png)

Please ensure that the reconcile status for the Grafana package reflects succeed after installing the package.

![](img/tanzu-pkgs/tanzu-pkgs13.png)

### **Install Fluent-Bit**

[Fluent Bit](https://fluentbit.io/) is a lightweight log processor and forwarder that allows you to collect data and logs from different sources, unify them, and send them to multiple destinations.

The current release of Fluent Bit allows you to gather logs from management clusters or Tanzu Kubernetes clusters running in vSphere, Amazon EC2, and Azure. You can then forward them to a log storage provider such as [Elastic Search](https://www.elastic.co/), [Kafka](https://www.confluent.io/confluent-operator/), [Splunk](https://www.splunk.com/), or an HTTP endpoint.

The example shown in this document uses HTTP endpoint [vRealize Log Insight Cloud](https://docs.vmware.com/en/VMware-vRealize-Log-Insight-Cloud/index.html) for forwarding logs from Tanzu Kubernetes clusters.

A sample yaml for configuring an http endpoint with fluent-bit is provided as reference here. For a full of user-configurable values, please see official [documentation](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.5/vmware-tanzu-kubernetes-grid-15/GUID-packages-logging-fluentbit.html#fluent-bit-package-configuration-parameters-4)

Please note that before you add the below yaml in TMC for installing fluent-bit, you have to create an API key as described [here](https://vmc.techzone.vmware.com/resource/implement-centralized-logging-tanzu-kubernetes-grid-fluent-bit)

<!-- /* cSpell:disable */ -->
```yaml
namespace: "tanzu-system-logging"
fluent_bit:
  config:
    service: |
      [Service]
        Flush         1
        Log_Level     info
        Daemon        off
        Parsers_File  parsers.conf
        HTTP_Server   On
        HTTP_Listen   0.0.0.0
        HTTP_Port     2020
    outputs: |
      [OUTPUT]
        Name            http
        Match           *
        Host            data.mgmt.cloud.vmware.com
        Port            443
        URI             /le-mans/v1/streams/ingestion-pipeline-stream
        Header          Authorization Bearer Sl0dzovlCKArhgyGdbvC8M9C7tfvT9Y5
        Format          json
        tls             On
        tls.verify      off
    inputs: |
      [INPUT]
        Name tail
        Path /var/log/containers/*.log
```
<!-- /* cSpell:enable */ -->

An example screenshot is shown below for fluent-bit installation. 

![](img/tanzu-pkgs/tanzu-pkgs14.png)

Please ensure that the reconcile status for the fluent-bit package reflects succeed after installing the package.

![](img/tanzu-pkgs/tanzu-pkgs15.png)

### **Install Multus CNI**

[Multus CNI](https://github.com/k8snetworkplumbingwg/multus-cni) is a container network interface (CNI) plugin for Kubernetes that enables attaching multiple network interfaces to pods. With Multus you can create a multi-homed pod that has multiple interfaces. 

To install the Multus package, repeat the steps for the package installation.  An example screenshot is shown below for multus-cni installation. 

![](img/tanzu-pkgs/tanzu-pkgs16.png)

Please ensure that the reconcile status for the multus-cni package reflects succeed after installing the package.

![](img/tanzu-pkgs/tanzu-pkgs17.png)