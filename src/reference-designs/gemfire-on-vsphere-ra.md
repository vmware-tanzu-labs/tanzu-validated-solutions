# Deploy and Manage VMware Tanzu GemFire on vSphere

The *Deploy and Manage VMware Tanzu GemFire on vSphere* reference architecture describes the deployment and management of VMware Tanzu GemFire on self-managed, multi-region vSphere infrastructure. It leverages vSphere Distributed Switch (vDS) for network virtualization and NSX Advanced Load Balancer (NSX ALB) for traffic distribution and high availability. The guide provides architectural best practices, deployment strategies and operational recommendations to support a scalable, high-performance and fault-tolerant GemFire deployment within an enterprise-grade vSphere environment.

## Audience

This document is intended for a broad range of stakeholders involved in the adoption and management of Tanzu GemFire, including:

* Executives and IT Decision-Makers seeking to align in-memory data management strategies with business objectives and digital transformation initiatives.

* Infrastructure and Cloud Architects responsible for designing resilient, scalable, and secure platforms to support distributed caching, real-time analytics, and data replication across environments.

* Platform Engineering and DevOps Teams tasked with deploying, operating, and maintaining Tanzu GemFire on Kubernetes and virtualized infrastructure.

* Application Owners and Developers focused on leveraging in-memory data grids to enhance application speed, fault tolerance, and horizontal scalability.

* Enterprise Modernization Teams engaged in transforming legacy architectures by introducing low-latency, high-availability data layers to support modern, cloud-native workloads.

This document also supports individuals driving strategic efforts to improve data availability, performance and operational efficiency across hybrid and multi-site deployments.

## Bill Of Materials

Below is the validated Bill of Materials (BoM) that can be used to install Tanzu GemFire on your vSphere environment today:

| Software Components  | Version  |
| :---- | :---- |
| vSphere ESXi | 8.0.3 |
| vCenter | 8.0.3 |
| NSX Advanced Load balancer | 22.1.5 |
| GemFire | 10.1.3 |

## In this document

- [Introduction to Tanzu GemFire](./gemfire/intro.md)
- [Perform Tanzu GemFire Operations](./gemfire/operations.md)

##  General References

* [Tanzu GemFire Overview](https://techdocs.broadcom.com/us/en/vmware-tanzu/data-solutions/tanzu-gemfire/10-1/gf/getting_started-gemfire_overview.html)
* [Install GemFire Using a Compressed TAR](https://techdocs.broadcom.com/us/en/vmware-tanzu/data-solutions/tanzu-gemfire/10-1/gf/getting_started-installation-install_standalone.html)
* [Tanzu GemFire Management Console Installation Guide](https://techdocs.broadcom.com/us/en/vmware-tanzu/data-solutions/tanzu-gemfire-management-console/1-3/gf-mc/install.html)
* [Java Manual Installation](https://www.java.com/en/download/help/windows_manual_download.html)
* [Installing Apache Maven](https://maven.apache.org/install.html)