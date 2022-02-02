# Tanzu Application Platform Planning and Architecture Reference
## Architecture Overview
The goal of this reference document is to help provide a standard architecture for deploying Tanzu Application Platform (TAP). This reference will cover topics such as Kubernetes requirements and cluster layout for Tanzu Application Platform. For guidance on how to deploy your particular Kubernetes distribution you should refer to the reference architecture for that distribution.
This architecture should give you a path to creating a production deployment of Tanzu Application Platform, however you should not feel constrained by this exact path if your specific use cases lead you to architectural differences. Design decisions in this architecture reflect the main design issues and the rationale behind a chosen solution path and if necessary can help provide rationale for any deviation.

### Cluster Layout
For production deployments, we recommend that there be two fully independent instances of TAP. One instance will be simply for operators to conduct their own reliability tests and the other that will host development, test, qa, and production environments isolated by separate clusters.
![](img/tap-architecture-planning/overview.png)
<!-- https://lucid.app/lucidchart/313468a7-da40-4872-9075-cd37224c5e2f/ -->
| Decision ID   | Design Decision   | Justification | Implication
|---            |---                |---            |---
|TAP-001  | Install using multiple clusters         |  Utilizing multiple clusters allows you to separate your workloads and environments while still leveraging combined build infrastructure   |  Multiple cluster design requires more installation effort and possibly maintenance versus a single cluster design
|TAP-002  | Create an operator sandbox environment  |  An operator sandbox environment allows platform operators to test upgrades and architectural changes before introducing them to production |  Operator sandbox requires additional compute resources
|TAP-003  | Utilize a single build cluster and multiple run clusters  | Utilizing a single build cluster with multiple run clusters creates the correct production for the build system vs separating into dev/test/qa/prod build systems. Additionally, it raises confidence that the container image does not change between environments.  It also enhances manageability versus having separate components. |  Changes lower environments are not as separated as having separate build environments
|TAP-004  | Utilize a UI Cluster  | Utilizing a single build cluster with multiple run clusters creates the correct production perception for the build system vs separating into dev/test/qa/prod build systems. Additionally, it raises confidence that the container image does not change between environments.  It also enhances manageability versus having separate components. |  None

### Build Cluster Requirements
The build Cluster is responsible for taking a developer's source code commits and applying a supply chain that will produce a container image and Kubernetes manifests for deploying on a run cluster.
The Kubernetes build cluster will see bursty workloads as each build or series of builds kicks off. The build cluster will see very high pod scheduling loads as these events happen. The amount of resources assigned to the build cluster will directly correlate to how quickly parallel builds are able to be completed.
Kubernetes requirements:
* LoadBalancer for ingress controller (1 external IP)
* Default storage class
* Total of minimum 16GB memory allottable available across cluster, at least 8gb per node
* Logging enabled and targeting desired application logging platform
* Monitoring enabled and targeting desired application observability platform
Recommendations:
* Spread across three AZs for high availability
* TSM uninstalled or restricted to non-TAP namespaces

The Build cluster includes the following packages:
```
build.appliveview.tanzu.vmware.com
buildservice.tanzu.vmware.com
cartographer.tanzu.vmware.com
cert-manager.tanzu.vmware.com
contour.tanzu.vmware.com
controller.conventions.apps.tanzu.vmware.com
controller.source.apps.tanzu.vmware.com
fluxcd.source.controller.tanzu.vmware.com
grype.scanning.apps.tanzu.vmware.com
image-policy-webhook.signing.apps.tanzu.vmware.com
metadata-store.apps.tanzu.vmware.com
ootb-supply-chain-basic.tanzu.vmware.com
ootb-templates.tanzu.vmware.com
scanning.apps.tanzu.vmware.com
spring-boot-conventions.tanzu.vmware.com
tap-telemetry.tanzu.vmware.com
tap.tanzu.vmware.com
tekton.tanzu.vmware.com
```
To install a build cluster, use the following package definition:
```yaml
profile: full
excluded_packages:
 - accelerator.apps.tanzu.vmware.com
 - run.appliveview.tanzu.vmware.com
 - api-portal.tanzu.vmware.com
 - cnrs.tanzu.vmware.com
 - ootb-delivery-basic.tanzu.vmware.com
 - developer-conventions.tanzu.vmware.com
 - image-policy-webhook.signing.apps.tanzu.vmware.com
 - learningcenter.tanzu.vmware.com
 - workshops.learningcenter.tanzu.vmware.com
 - services-toolkit.tanzu.vmware.com
 - service-bindings.labs.vmware.com
 - tap-gui.tanzu.vmware.com
 ```
 ### Run Cluster Requirements

The run cluster will read the container image and Kubernetes resources created by the build cluster and run them as defined in the `Deliverable` object for each application.
The run clusters requirements will be mostly driven by the respective applications that it will be running.  Horizontal and vertical scale will be determined based on the type of applications being scheduled.

Kubernetes requirements:
* LoadBalancer for ingress controller (1 external IP)
* Default storage class
* Total of minimum 16GB memory allottable available across cluster, at least 8gb per node
* Logging enabled and targeting desired application logging platform
* Monitoring enabled and targeting desired application observability platform
Recommendations:
* Spread across three AZs for high availability
* TSM uninstalled or restricted to non-TAP namespaces

The run cluster includes the following packages:
```
cartographer.tanzu.vmware.com
cert-manager.tanzu.vmware.com
cnrs.tanzu.vmware.com
contour.tanzu.vmware.com
controller.source.apps.tanzu.vmware.com
fluxcd.source.controller.tanzu.vmware.com
image-policy-webhook.signing.apps.tanzu.vmware.com
ootb-delivery-basic.tanzu.vmware.com
ootb-templates.tanzu.vmware.com
run.appliveview.tanzu.vmware.com
service-bindings.labs.vmware.com
services-toolkit.tanzu.vmware.com
tap-telemetry.tanzu.vmware.com
tap.tanzu.vmware.com
tekton.tanzu.vmware.com
```
To install a run cluster, use the following package definition:
```yaml
profile: full
excluded_packages:
 - accelerator.apps.tanzu.vmware.com
 - api-portal.tanzu.vmware.com
 - build.appliveview.tanzu.vmware.com
 - buildservice.tanzu.vmware.com
 - controller.conventions.apps.tanzu.vmware.com
 - developer-conventions.tanzu.vmware.com
 - grype.scanning.apps.tanzu.vmware.com
 - learningcenter.tanzu.vmware.com
 - metadata-store.apps.tanzu.vmware.com
 - ootb-supply-chain-basic.tanzu.vmware.com
 - ootb-supply-chain-testing.tanzu.vmware.com
 - ootb-supply-chain-testing-scanning.tanzu.vmware.com
 - scanning.apps.tanzu.vmware.com
 - spring-boot-conventions.tanzu.vmware.com
 - tap-gui.tanzu.vmware.com
 - workshops.learningcenter.tanzu.vmware.com
```
### UI Cluster Requirements
The UI cluster is designed to run the web applications for TAP. Specifically Tanzu Learning Center, Tanzu Application Portal GUI, and Tanzu API Portal.
The UI cluster's requirements will be mostly driven by the respective applications that it will be running.
Kubernetes requirements:
* LoadBalancer for ingress controller (3 external IPs)
* Default storage class
* Total of minimum 16GB memory allottable available across cluster, at least 8gb per node
* Logging enabled and targeting desired application logging platform
* Monitoring enabled and targeting desired application observability platform
Recommendations:
* Spread across three AZs for high availability
* TSM uninstalled or restricted to non-TAP namespaces
* Utilize a PostgreSQL database for storing user preferences and manually created entities

The UI cluster includes the following packages:

```
api-portal.tanzu.vmware.com
cert-manager.tanzu.vmware.com
contour.tanzu.vmware.com
image-policy-webhook.signing.apps.tanzu.vmware.com
tap-gui.tanzu.vmware.com
tap-telemetry.tanzu.vmware.com
tap.tanzu.vmware.com
fluxcd.source.controller.tanzu.vmware.com
controller.source.apps.tanzu.vmware.com 
accelerator.apps.tanzu.vmware.com
```

To install a UI cluster, use the following package definition:
```yaml
profile: full
excluded_packages:
 - run.appliveview.tanzu.vmware.com
 - cnrs.tanzu.vmware.com
 - ootb-delivery-basic.tanzu.vmware.com
 - developer-conventions.tanzu.vmware.com
 - image-policy-webhook.signing.apps.tanzu.vmware.com
 - learningcenter.tanzu.vmware.com
 - workshops.learningcenter.tanzu.vmware.com
 - services-toolkit.tanzu.vmware.com
 - service-bindings.labs.vmware.com
 - build.appliveview.tanzu.vmware.com
 - buildservice.tanzu.vmware.com
 - controller.conventions.apps.tanzu.vmware.com
 - developer-conventions.tanzu.vmware.com
 - grype.scanning.apps.tanzu.vmware.com
 - metadata-store.apps.tanzu.vmware.com
 - ootb-supply-chain-basic.tanzu.vmware.com
 - ootb-supply-chain-testing.tanzu.vmware.com
 - ootb-supply-chain-testing-scanning.tanzu.vmware.com
 - scanning.apps.tanzu.vmware.com
 - spring-boot-conventions.tanzu.vmware.com
 - ootb-templates.tanzu.vmware.com
 - tekton.tanzu.vmware.com
 - image-policy-webhook.signing.apps.tanzu.vmware.com
 - cartographer.tanzu.vmware.com
 ```
### Workspace Cluster Requirements
The workspace cluster is for "inner loop" development iteration where developers are connecting via their IDE to rapidly iterate on new software features. The workspace cluster operates distinctly from the outer loop infrastructure. Each developer should be given their own namespace within the workspace cluster during their platform onboarding.

![](img/tap-architecture-planning/workspace-cluster.png)
<!-- https://lucid.app/lucidchart/40663cc1-55aa-4892-ae23-1f462d39f262 -->

Kubernetes requirements:
* LoadBalancer for ingress controller (2 external IPs)
* Default storage class
* Total of minimum 16GB memory allottable available across cluster, at least 8gb per node
* Logging enabled and targeting desired application logging platform
* Monitoring enabled and targeting desired application observability platform
Recommendations:
* Spread across three AZs for high availability
* TSM uninstalled or restricted to non-TAP namespaces

The workspace cluster includes the following packages:
```
build.appliveview.tanzu.vmware.com
buildservice.tanzu.vmware.com
cartographer.tanzu.vmware.com
cert-manager.tanzu.vmware.com
cnrs.tanzu.vmware.com
contour.tanzu.vmware.com
controller.conventions.apps.tanzu.vmware.com
controller.source.apps.tanzu.vmware.com
fluxcd.source.controller.tanzu.vmware.com
grype.scanning.apps.tanzu.vmware.com
image-policy-webhook.signing.apps.tanzu.vmware.com
metadata-store.apps.tanzu.vmware.com
ootb-delivery-basic.tanzu.vmware.com
ootb-supply-chain-basic.tanzu.vmware.com
ootb-templates.tanzu.vmware.com
run.appliveview.tanzu.vmware.com
scanning.apps.tanzu.vmware.com
service-bindings.labs.vmware.com
services-toolkit.tanzu.vmware.com
spring-boot-conventions.tanzu.vmware.com
tap-telemetry.tanzu.vmware.com
tap.tanzu.vmware.com
tekton.tanzu.vmware.com
```

To install a workspace cluster, use the following package definition:
```yaml
profile: full
excluded_packages:
 - accelerator.apps.tanzu.vmware.com
 - api-portal.tanzu.vmware.com
 - learningcenter.tanzu.vmware.com
 - metadata-store.apps.tanzu.vmware.com
 - ootb-supply-chain-testing.tanzu.vmware.com
 - ootb-supply-chain-testing-scanning.tanzu.vmware.com
 - tap-gui.tanzu.vmware.com
 - workshops.learningcenter.tanzu.vmware.com
```

## TAP Upgrade Approach
When a new version of TAP is released, it is recommended to first upgrade the operator sandbox environment. A sample subset of applications should live here and any applicable platform tests specific to your organization should take place here before progressing to the production instance. Such tests might include building some representative set of applications and verifying that they still deploy successfully to your sandbox run cluster.
The following upgrade order is recommended:
* sandbox
 * UI
 * build
 * run
* prod
 * workspace
 * UI
 * build
 * run dev
 * run test
 * run qa
 * run prod


| Decision ID   | Design Decision   | Justification | Implication
|---            |---                |---            |---
|TAP-006  | Follow the upgrade order specified         |  Upgrading in order promotes confidence in that software, configuration, and architecture is stable and reliable   |  None

## Services Architecture
There are three primary ways to consume services. Services are consumed by applications via the workload.yaml and that request is presented to the system as a ServiceClaim. The most preferred method of service integration is the external cluster which provides the services operations with their specific life cycle and performance requirements and separates the stateless and stateful workloads.
| Decision ID   | Design Decision   | Justification | Implication
|---            |---                |---            |---
|TAP-007  | Use services external services and service clusters         |  Utilizing external services allows the service operators to customize their cluster parameters for their specific services and manage their respective life cycles independently   | Utilizing external clusters adds some technical complexity

### In-Cluster
Services can be deployed directly into the same cluster running Tanzu Application Service. This kind of deployment is more suited to workspace environments. Two possible implementations include, 1) same namespace, 2) different namespaces. The diagram depicts the latter.
![](img/tap-architecture-planning/in-cluster.png)
<!-- slides 80-82 https://onevmw-my.sharepoint.com/:p:/g/personal/mijames_vmware_com/EYK5tKWk83RFia7QHHkaAj0BUnnhenCjlto4qpYDY_ZyFw?e=NhmLnZ -->

### External Cluster
External clusters allow services to have different infrastructural, security, and scaling requirements. External services clusters are the recommended way to provide rapid service provisioning to platform users.
![](img/tap-architecture-planning/external-cluster.png)

### External Injected
Applications that consume services that do not adhere to the Kubernetes service binding specification require the usage of a K8s secret, implemented in the same app deployment containing the necessary connection details. This method provides the ultimate in flexibility and allows you to consume legacy services.
![](img/tap-architecture-planning/external-injected.png)

## Monitoring
The following metrics should be observed and if the values exceed service level objectives, the clusters should be scaled or other actions taken
Build cluster:
* Number of pods waiting to be scheduled
* Number builds completed in the last 60 minutes
* Maximum number of seconds any pod has waited for scheduling
Run cluster:
* Number of pods waiting to be scheduled
* Maximum number of seconds any pod has waited for scheduling
* Remaining allottable memory and CPU
UI components:
* Response time
* Availability
| Decision ID   | Design Decision   | Justification | Implication
|---            |---                |---            |---
|TAP-008  | Monitor platform KPIs and setup alerts         |  An external monitoring platform will keep metrics for the duration of their retention window. Further alerts will allow rapid response to issues before they impact developers and users.   | None

## Logging
Logging for TAP is handled by the upstream Kubernetes integration for both applications and internal system components. An external logging platform should be used for storing and searching those logs.  For such integration, refer to the reference architecture of your platform or logging platform.
| Decision ID   | Design Decision   | Justification | Implication
|---            |---                |---            |---
|TAP-009  |Use external logging platform          |  An external logging platform will keep logs for the duration of their retention window and superior searching capabilities  | None