## Deploy User-Managed Packages in Workload Clusters

After creating workload clusters, you can install user-managed packages. These packages extend the core functionality of Kubernetes clusters created by Tanzu Kubernetes Grid.

For example, you can install the Contour package to implement ingress control, the Harbor package to configure a private container registry, or the Fluent Bit, Grafana, and Prometheus packages to collect logs and metrics from your clusters.

You can install Tanzu packages via the CLI by invoking the `tanzu package install` command or directly from Tanzu Mission Control by utilizing the [**TMC Catalog**](https://docs.vmware.com/en/VMware-Tanzu-Mission-Control/services/tanzumc-using/GUID-EF35646D-8762-41F1-95E5-D2F35ED71BA1.html) feature.

The recommended method for installing packages in Tanzu Kubernetes clusters is through Tanzu Mission Control.

Log in to the Tanzu Mission Control portal and go to the Catalog page to install user-managed packages on a Tanzu Kubernetes cluster. Select the cluster on which packages will be installed from the Available category.

![Tanzu Mission Control Catalog page showing available packages](img/tanzu-pkgs/tanzu-pkgs01.png)

### **Install cert-manager**

The first package that you should install on your cluster is the [**cert-manager**](https://github.com/cert-manager/cert-manager) package which adds certificates and certificate issuers as resource types in Kubernetes clusters and simplifies the process of obtaining, renewing, and using those certificates.

Click the cert-manager package tile on the Catalog page to navigate to the install package page. Click the Install Package button to navigate to the package details page. The package details page shows the metadata provided by the package author.

On the package details page, click Install Package.

![Screenshot of package details page for cert-manager](img/tanzu-pkgs/tanzu-pkgs02.png)

On the Install page, provide a name for the installed instance of the package and select the version to install. You can customize the package installation by using the pencil icon under the Table View option to edit the configuration parameters. 

After supplying any custom parameters, click the Install Package button to initiate the installation.

![Screenshot of the Install cert-manager screen](img/tanzu-pkgs/tanzu-pkgs03.png)

Installing the package takes roughly 5-10 minutes to complete. After a successful installation, the status of the package reconciliation reads Succeeded.

![Screenshot of page showing list of installed packages](img/tanzu-pkgs/tanzu-pkgs04.png)

### Install Contour

[Contour](https://projectcontour.io/) is an open-source Kubernetes ingress controller providing the control plane for the Envoy edge and service proxy.​ The Tanzu Mission Control catalog includes signed binaries for Contour and Envoy, which you can deploy into Tanzu Kubernetes (workload) clusters to provide ingress control services in those clusters.

To install the Contour package, click the Browse Packages button and select the Contour package.

Click the Install Package button to initiate the installation.

![Screenshot of Contour installation screen](img/tanzu-pkgs/tanzu-pkgs05.png)

Provide a name for the installed package and select the version that you want to install. You can customize your installation by entering the user-configurable values in YAML format under the Overlay YAML option. 

An example YAML file for customizing the installation of Contour follows.

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

For a full list of user-configurable values, see the official Contour [documentation](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.5/vmware-tanzu-kubernetes-grid-15/GUID-packages-ingress-contour.html#optional-configuration-6)

**Note:** You can leave the default settings if you don’t need to customize the package installation. 

![Screenshot of the Contour installation screen showing a YAML overlay file](img/tanzu-pkgs/tanzu-pkgs06.png)

After installing Contour, ensure that the status for the Contour package one the Installed Packages screen has changed to Succeeded.

![Screenshot of the Installed Packages screen showing that installation was successful](img/tanzu-pkgs/tanzu-pkgs07.png)

### Install Harbor

[Harbor](https://goharbor.io/) is an open-source container registry. The Harbor registry may be used as a private registry for container images that you want to deploy to Tanzu Kubernetes clusters.

To install the Harbor package, repeat the steps for package installation. An example YAML file for customizing Harbor deployment follows.

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

For a full list of user-configurable values, see the official [Harbor documentation](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.5/vmware-tanzu-kubernetes-grid-15/GUID-packages-harbor-registry.html#harbordatavalues-file-for-vsphere-7-11)

A screenshot of the Harbor installation page showing a YAML file for customizing Harbor installation follows. 

![Screenshot of Harbor installation page showing a sample YAML customization file](img/tanzu-pkgs/tanzu-pkgs08.png)

After installing Harbor, ensure that the status of the installation has changed to Succeeded on the Installed Packages page.

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