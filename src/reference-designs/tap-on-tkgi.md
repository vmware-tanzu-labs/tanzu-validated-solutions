# TKGi Cluster Preparation for Installing Tanzu Application Platform (applicable for POC deployments only)

While Tanzu Application Platform (informally known as TAP) works on any conformant Kubernetes cluster, every Kubernetes distribution can have certain unexpected quirks. While deploying TAP on TKGi clusters, you might come across the following issues. In this document, we'll outline the following issues and learn about the workarounds: 

- NSX Tags limitation for TAP workload deployment on TKGi clusters.
- TAP installation fails with Contour package error as IPv6 is not enabled on TKGi clusters.

>**Note** These workaround steps are recommended only for the POC deployments, and should not be applied in production environments. You must also review the TAP and TKGi release notes for workarounds of these issues.


## NSX Tags Limitation for TAP Workload Deployment on TKGi Clusters:

While using NCP as CNI on TKGi cluster, TAP workload pod creation is stopped at `containercreating` state as NCP fails to create the logical port/logical segment for the pod due to the NSX tags limit.

TAP adds certain labels on the workload pods to trigger workflows during build/run phase. NCP translates each label information as tags on various NSX objects, such as logical segments, logical ports, and so on. Additionally, TKGi adds a few tags on these NSX objects with unique information related TKGi Cluster, Namespace, and Pod. These NSX Tags are used to enforce firewall rules in NSX Manager when K8s Admin created Security Policies using respective labels. Currently, NCP has a mechanism for limiting the number of labels which are translated to NSX tags, which is set to 29(+1 reserved). If the number of tags exceeds the limit, NCP fails to create the NSX objects, and the pod creation fails. You can see the following logs message in `/var/vcap/sys/log/ncp/ncp.stdout.log` on the Master node which confirms the tags limit has breached:

```bash
Unexpected error from backend manager (['nsxmgr.tanzu.lab']) for PATCH  policy/api/v1/infra/segments/seg_b4ec3c10-c7d0-4d66-a02f-c99db10d783d_0/ports/port_62d9ebb9-913b-4407-bf56-d887ff6dea5c: In the /infra/
 
segments/seg_b4ec3c10-c7d0-4d66-a02f-c99db10d783d_0/ports/port_62d9ebb9-913b-4407-bf56-d887ff6dea5c : tags, field 30 count exceeds max number allowed 29.

```

TAP has a pre-defined list of system generated labels which are applied on TAP workloads. For more information about the list of TAP generated labels, see [Appendix A](#appendix-a--tap-generated-labels-on-workload-pods). Many of these labels are not necessarily useful for Security Policy creation in K8s. You can skip the translation of these labels as NSX tags to avoid breaching the limit on NSX. This can be achieved by using the `label_filtering_regex_list` parameter with [TKGI network profile](https://techdocs.broadcom.com/us/en/vmware-tanzu/standalone-components/tanzu-kubernetes-grid-integrated-edition/1-20/tkgi/network-profiles-define.html), which allows us to add a list of regex expressions defining the labels that must not be converted to NSX tags.

To apply this configuration to TKGi clusters:

1. Connect to TKGi API and create the Network profile using the configuration similar to: <br>
    `#  tkgi create-network-profile network-profile-tap.json`

    ```
    # cat network-profile-tap.json

    {
        "name": "networkprofile-tags-filter",
        "description": "Network profile for filtering the tags to be applied on NSX objects",
        "parameters": {
            "cni_configurations": {
                "type": "nsxt",
                "parameters": {
                    "extensions":{
                        "ncp":{
                            "k8s":{
                                "label_filtering_regex_list": "^app.kubernetes.io.*, ^app.tanzu.vmware.com.*, ^carto.run.*, ^image.kpack.io.*, ^kapp.k14s.io.*, ^networking.internal.knative.dev.*, ^networking.knative.dev.*, .*scanning.apps.tanzu.vmware.com.*, ^services.conventions.carto.run.*, ^serving.knative.dev.*, ^statefulset.kubernetes.io.*, ^target.*, ^tanzu.app.live.view.*, ^tekton.dev.*"
                            }
                        }
                    }
                }
            }
        }
    }
    ```
    > **Note:** The above regex list contains the keywords for most of the TAP generated labels. You must customize this list based on your requirement.
    
1. Create the TKGi cluster by using the Network Profile created above. <br>
    `# tkgi create-cluster tap-run-cluster --external-hostname tap-run-cluster.tanzu.lab --plan production --network-profile networkprofile-tags-filter`
    
    Alternately, you can apply the Network Profile on an existing TKGi cluster by running the below command:
    
    `# tkgi update-cluster tap-run-cluster --network-profile networkprofile-tags-filter`

1. Validate that the Network Profile has been applied to the TKGi cluster by running the command below:

    ```bash
    # tkgi cluster tap-run-cluster

    PKS Version:              1.17.0-build.62
    Name:                     tap-run-cluster
    K8s Version:              1.26.5
    Plan Name:                tap-plan-2
    UUID:                     d0c74ace-0413-4eb6-bd16-1cc1672ac512
    Last Action:              UPDATE
    Last Action State:        succeeded
    Last Action Description:  Instance update completed
    Kubernetes Master Host:   tap-run-api.tanzu.lab
    Kubernetes Master Port:   8443
    Worker Nodes:             2
    Kubernetes Master IP(s):  192.168.210.32
    Network Profile Name:     networkprofile-tags-filter
    Kubernetes Profile Name:
    Compute Profile Name:
    NSX Policy:               true
    Tags:
    ```

1. Validate that NCP config (`/var/vcap/jobs/ncp/config/ncp.ini`) under the TKGi cluster's control plane is updated with valid `label_filtering_regex_list`.

    ```bash
    label_filtering_regex_list = ^app.kubernetes.io.*, ^app.tanzu.vmware.com.*, ^carto.run.*, ^image.kpack.io.*, ^kapp.k14s.io.*, ^networking.internal.knative.dev.*, ^networking.knative.dev.*, .*scanning.apps.tanzu.vmware.com.*, ^services.conventions.carto.run.*, ^serving.knative.dev.*, ^statefulset.kubernetes.io.*, ^target.*, ^tanzu.app.live.view.*, ^tekton.dev.*

    ```
1. TKGi validates the Network profile and ensures to skip the required tags on the NSX objects. You will now be able to create the TAP workloads. 
<br>

> **Note:**
> - Ensure to use the required filters in the `label_filtering_regex_list` to skip the label to tags conversion. 
> - You can not use the labels mentioned in the `label_filtering_regex_list` for K8S Network Policies/Security Policies as the respective tags are not available for firewall rule creation in NSX.
> - Some of the Network profile parameters cannot be updated once you apply the Network Profile on the TKGi cluster. Ensure to review the network parameters list and create the network profile with all the required parameters in addition to `label_filtering_regex_list`. For more information about network parameters list that can be updated, see the [TKGi Network Profiles](https://techdocs.broadcom.com/us/en/vmware-tanzu/standalone-components/tanzu-kubernetes-grid-integrated-edition/1-20/tkgi/network-profiles-define.html#network-profile-parameters-11) documentation. 


## TAP Installation Fails with Contour Package Error as IPv6 is Not Enabled on TKGi Clusters

When you deploy TAP onto the TKGi clusters, the envoy pods of Contour would not start. The Contour package provided in TAP does not work out-of-the-box with clusters that have their nodes configured to only support IPv4 networking, and have disabled IPv6 networking at the node level. 

While debugging the issue, in the envoy pod logs, you can find the following entries:

```bash
[warning][config] [source/common/config/grpc_subscription_impl.cc:126] gRPC config for type.googleapis.com/envoy.config.listener.v3.Listener rejected: Error adding/updating listener(s) ingress_http: malformed IP address: ::
ingress_https: malformed IP address: ::
stats-health: malformed IP address: ::

```
This was a change made in the Tanzu packaging of Contour, where as of TAP 1.3, the behavior of Contour was changed, and it’s defaulting to IPv6 with IPv4 compatibility now. However, TKGi currently does not support IPv6.

To resolve this, add an overlay which will change the flags passed to the Contour deployment, and switch it to use IPv4 instead of IPv6.

1. Create an overlay file `contour-overlay-fix-ipv6.yaml` as below to use IPv4 instead of IPv6:

    ```bash
    apiVersion: v1
    kind: Secret
    metadata:
    name: overlay-fix-contour-ipv6
    namespace: tap-install
    stringData:
    overlay-contour-fix-ipv6.yml: |
        #@ load("@ytt:overlay", "overlay")
        #@overlay/match by=overlay.subset({"kind": "Deployment"}),expects=1
        ---
        spec:
        template:
            spec:
            containers:
            #@overlay/match by=overlay.map_key("name")
            - name: contour
                #@overlay/replace
                args:
                - serve
                - --incluster
                - '--xds-address=0.0.0.0'
                - --xds-port=8001
                - '--stats-address=0.0.0.0'
                - '--http-address=0.0.0.0'
                - '--envoy-service-http-address=0.0.0.0'
                - '--envoy-service-https-address=0.0.0.0'
                - '--health-address=0.0.0.0'
                - --contour-cafile=/certs/ca.crt
                - --contour-cert-file=/certs/tls.crt
                - --contour-key-file=/certs/tls.key
                - --config-path=/config/contour.yaml
    ```
1. Run the below command to create the secret with above overlay config in `tap-install` namespace: <br>
    `kubectl apply -f contour-overlay-fix-ipv6.yaml`

1. Update the `package_overlays` section in TAP values file to instruct TAP to use this overlay, and apply it to the contour package. 

    ```bash
    package_overlays:
    - name: contour
    secrets:
    - name: overlay-fix-contour-ipv6
    ```
1. Install tap by running the following command: <br>
    `tanzu package install tap --values-file tap-values.yaml -p tap.tanzu.vmware.com -v <TAP:VERSION> -n tap-install`

1. The above contour overlay will be applied during TAP installation and the envoy pods will enter into a running state successfully deploying Contour. Verify the Contour deployment post TAP installation by running the below command: <br>

    `kubectl get deploy contour -n tanzu-system-ingress -o yaml`


## Appendix A : TAP Generated labels on workload pods: 

```bash
app
app.kubernetes.io/component
app.kubernetes.io/managed-by
app.kubernetes.io/name
app.kubernetes.io/part-of
app.tanzu.vmware.com/deliverable-type
apps.tanzu.vmware.com/auto-configure-actuators
apps.tanzu.vmware.com/has-tests
apps.tanzu.vmware.com/pipeline
apps.tanzu.vmware.com/workload-type
carto.run/cluster-template-name
carto.run/resource-name
carto.run/run-template-name
carto.run/runnable-name
carto.run/supply-chain-name
carto.run/template-kind
carto.run/template-lifecycle
carto.run/workload-name
carto.run/workload-namespace
controller-revision-hash
conventions.carto.run/framework
headless-service
image.kpack.io/buildNumber
image.kpack.io/image
image.kpack.io/imageGeneration
kapp.k14s.io/app
kapp.k14s.io/association
kpack.io/build
monitor-instance
networking.internal.knative.dev/serverlessservice
networking.internal.knative.dev/serviceType
networking.knative.dev/visibility
pod-template-hash
postgres-instance
role
scanpolicies.scanning.apps.tanzu.vmware.com
scantemplates.scanning.apps.tanzu.vmware.com
service
services.conventions.carto.run/kafka
services.conventions.carto.run/postgres
services.conventions.carto.run/rabbitmq
serving.knative.dev/configuration
serving.knative.dev/configurationGeneration
serving.knative.dev/configurationUID
serving.knative.dev/revision
serving.knative.dev/revisionUID
serving.knative.dev/route
serving.knative.dev/routingState
serving.knative.dev/service
serving.knative.dev/serviceUID
statefulset.kubernetes.io/pod-name
tanzu.app.live.view
tanzu.app.live.view.application.actuator.path
tanzu.app.live.view.application.actuator.port
tanzu.app.live.view.application.flavours
tanzu.app.live.view.application.name
targetGeneration
targetKind
targetName
targetScanPolicyGeneration
targetScanPolicyUID
targetScanTemplateGeneration
targetScanTemplateUID
targetUID
tekton.dev/clusterTask
tekton.dev/memberOf
tekton.dev/pipeline
tekton.dev/pipelineRun
tekton.dev/pipelineTask
tekton.dev/taskRun
type

```



