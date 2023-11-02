# VMware Tanzu for Kubernetes Operations Network Port Diagram - Reference Sheet
 
Kubernetes is a great platform that provides development teams with a single API to deploy, manage, and run applications. However, running, maintaining, and securing Kubernetes is a complex task. VMware Tanzu for Kubernetes Operations (informally known as TKO) simplifies Kubernetes operations. It determines what base OS instances to use, which Kubernetes Container Network Interface (CNI) and Container Storage Interfaces (CSI) to use, how to secure the Kubernetes API, and much more. It monitors, upgrades, and backs up clusters and helps teams provision, manage, secure, and maintain Kubernetes clusters on a day-to-day basis.

The following diagram provides a high-level network ports requirement for deploying the components available with Tanzu for Kubernetes Operations as a solution.

![Tanzu Ports Diagram](img/tanzu-ports/tanzu-ports.png)

## Reference for Port Diagram

|**Product**| **Source** | **Destination** | **Ports** | **Protocols** | **Purpose** |
| --- | --- | --- | --- | --- | --- |
| NSX Advanced Load Balancer | Avi Controller| Syslog | 514 | TCP | Log Export|
| NSX Advanced Load Balancer | Avi Controller| Domain Name Server | 53 | UDP | DNS Requests |
| NSX Advanced Load Balancer | Avi Controller| NTP Server | 123 | UDP | Time Synchronization|
| NSX Advanced Load Balancer | Avi Controller | SecureLDAP Server | 636 | TCP | Authentication |
| NSX Advanced Load Balancer | Avi Controller | LDAP Server | 389 | UDP | Authentication |
| NSX Advanced Load Balancer | Management Client | Avi Controller | 22 | TCP | Secure shell login |
| NSX Advanced Load Balancer | Management Client | Avi Controller | 443 | TCP | NSX ALB UI/REST API |
| NSX Advanced Load Balancer | Management Client | Avi Controller | 80 | TCP | NSX ALB UI |
| NSX Advanced Load Balancer | Avi Controller | ESXi Host | 443 | TCP | Management Access for Service Engine Creation |
| NSX Advanced Load Balancer | Avi Controller | vCenter Server | 443 | TCP | APIs for vCenter Integration |
| NSX Advanced Load Balancer | Avi Controller | NSX Manager | 443 | TCP | For NSX Cloud creation |
| NSX Advanced Load Balancer | Avi Service Engine | Avi Controller | 123 | UDP | Time sync |
| NSX Advanced Load Balancer | Avi Service Engine | Avi Controller | 8443 | TCP | Secure channel key exchange |
| NSX Advanced Load Balancer | Avi Service Engine | Avi Controller | 22 | TCP | Secure channel SSH |
| NSX Advanced Load Balancer | Avi Service Engine | Avi Service Engine | 9001 | TCP | Inter-SE distributed object store for vCenter/NSX-T/No Orchestrator/Linux server clouds|
| NSX Advanced Load Balancer | Avi Service Engine | Avi Service Engine | 4001 | TCP | Inter-SE distributed object store for AWS/Azure/GCP/OpenStack clouds|
| Tanzu Kubernetes Grid | Bootstrap Machine | TKG Cluster Kubernetes API Server | 6443 | TCP |Kubernetes Cluster API Access|
| Tanzu Kubernetes Grid | Bootstrap Machine | NodePort Services | 30000-32767 | TCP | External access to hosted services via L7 ingress in NodePort mode|
| Tanzu Kubernetes Grid | Bootstrap Machine | NodePortLocal Services | 61000-62000(default) | TCP | External access to hosted services via L7 ingress in NodePortLocal mode|
| Tanzu Kubernetes Grid | Bootstrap Machine | vCenter Server | 443 | TCP | vCenter Server UI Access |
| Tanzu Kubernetes Grid | TKG Workload Cluster CIDR | TKG Management Cluster CIDR | 31234 | TCP | Allow Pinniped concierge on workload cluster to access Pinniped supervisor on management cluster|
| Tanzu Kubernetes Grid | TKG Workload Cluster CIDR | TKG Management Cluster CIDR | 31234 | TCP | To register Workload Cluster with Management Cluster|
| Tanzu Kubernetes Grid | TKG Management and Workload Cluster CIDR | Avi Controller | 443 | TCP | Allow Avi Kubernetes Operator (AKO) and AKO Operator (AKOO) access to Avi Controller |
| Tanzu Kubernetes Grid | TKG Management and Workload Cluster CIDR | vCenter Server | 443 | TCP | Allow components to access vCenter to create VMs and Storage volumes |
| Tanzu Kubernetes Grid | TKG Management and Workload Cluster CIDR | DNS Server | 53 | UDP | Allow components to look up for machine addresses |
| Tanzu Kubernetes Grid | TKG Management and Workload Cluster CIDR | NTP Server | 123 | UDP | Allow components to sync current time |
| Tanzu Kubernetes Grid | TKG Management and Workload Cluster CIDR | Harbor | 443 | TCP | Allow components to retrieve container images |
| Tanzu Kubernetes Grid | TKG Management and Workload Cluster CIDR | DHCP Server | 67 <br> 68 | TCP | Allow nodes to get DHCP addresses |
| Tanzu Kubernetes Grid | TKG Management and Workload Cluster CIDR | Tanzu Mission Control | 443 | TCP | To manage Tanzu Kubernetes Clusters with Tanzu Mission Control (TMC) |
| Tanzu Kubernetes Grid | TKG Management and Workload Cluster CIDR | Tanzu Service Mesh | 443 | TCP | To provide Service Mesh services to Tanzu Kubernetes Clusters with Tanzu Service Mesh (TSM) |
| Tanzu Kubernetes Grid | TKG Management and Workload Cluster CIDR | Tanzu Observability | 443 | TCP | To monitor Tanzu Kubernetes Clusters with Tanzu Observability (TO) |
| Tanzu Kubernetes Grid | TKG Management and Workload Cluster CIDR |vRealize Log Insight | 514 | UDP | To configure remote logging with fluentbit |
| Tanzu Kubernetes Grid | TKG Management and Workload Cluster CIDR | vRealzie Log Insight Cloud | 443 | TCP | To configure remote logging with fluentbit |




<!-- /* cSpell:enable */ -->