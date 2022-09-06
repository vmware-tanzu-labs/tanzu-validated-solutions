# Tanzu Application Platform Deployment

This deployment outlines the deployment steps for VMware Tanzu Application Platform 1.1 on a Kubernetes workload cluster. In accordance with the [Tanzu Application Platform Reference Design](../reference-designs/tap-architecture-planning.md), four clusters will be created:

* Tanzu Application Platform Build Cluster
* Tanzu Application Platform Run Cluster
* Tanzu Application Platform View Cluster
* Tanzu Application Platform Iterate Cluster

## Prerequisites

Before deploying VMware Tanzu Application Platform, ensure that the following prerequisites are met:

* A [Tanzu Network](https://network.tanzu.vmware.com/) account is available for downloading Tanzu Application Platform packages.
* A container image registry with push and write access (such as Harbor, Docker Hub, or Azure Container Registry) is available. This will be used for application images and runtime dependencies.
* Network access to [VMware's image registry](https://registry.tanzu.vmware.com) is available.
<!-- /* cSpell:disable */ -->
* DNS Records for components like Cloud Native Runtimes (knative) i.e. cnrs, Tanzu Learning Center, Tanzu Application Platform GUI etc.
* A centralized git repository from GitHub, Gitlab or Azure DevOps for the Tanzu Application Platform GUI's software catalogs, along with a token allowing read access.
* A Kubernetes workload cluster versions 1.20, 1.21, or 1.22 on Azure Kubernetes Service, Amazon Elastic Kubernetes Service, Google Kubernetes Engine, or [minikube](https://minikube.sigs.k8s.io/docs/start/) providers.
<!-- /* cSpell:enable */ -->
* Accept the End User License Agreements (EULAs).
* The Kubernetes CLI, kubectl, v1.20, v1.21 or v1.22, installed and authenticated with administrator rights for your target cluster.

Additional details concerning prerequisites may be found in Tanzu Application Platform [documentation](https://docs.vmware.com/en/Tanzu-Application-Platform/1.1/tap/GUID-prerequisites.html).

*Note:* Use the Kubernetes defaults `serviceDomain` of `cluster.local` in workload clusters where Tanzu Application Platform is deployed.

## Overview of the Deployment Steps

The following provides an overview of the steps necessary to deploy Tanzu Application Platform. Each step links to a detailed information section.

1. [Set Up Tanzu Application Platform Build cluster](#tap-build)
1. [Set Up Tanzu Application Platform Run cluster](#tap-run)
1. [Set Up Tanzu Application Platform View cluster](#tap-ui)
1. [Set Up Tanzu Application Platform Iterate cluster](#tap-full)
1. [Deploy Sample Application](#tap-sample-app)


## <a id="tap-build"> </a>Set Up Tanzu Application Platform Build Cluster

The Build Cluster is responsible for taking a developer's source code commits and applying a supply chain that will produce a container image and Kubernetes manifests for deploying on a Run Cluster

### <a id="tanzu-essential"> </a> Step 1: Install Tanzu Cluster Essentials and Tanzu CLI

Provide following user inputs into commands and execute them to install Tanzu Cluster Essentials and Tanzu CLI on your bootstrap/jumpbox machine.

* `TAP_TAP_WORKLOAD_CONTEXT` - the `kubeconfig` context of the workload cluster
* `TANZU_NET_API_TOKEN` - an API token obtained from https://network.tanzu.vmware.com
* `INSTALL_REGISTRY_USERNAME` - the Tanzu username
* `INSTALL_REGISTRY_PASSWORD` - the Tanzu user's password

```bash
set -e

export TAP_WORKLOAD_CONTEXT=<workload cluster context>
export TANZU_NET_API_TOKEN=<tanzu refresh token>
export INSTALL_REGISTRY_HOSTNAME="registry.tanzu.vmware.com"
export INSTALL_REGISTRY_USERNAME=<tanzu username>
export INSTALL_REGISTRY_PASSWORD=<tanzu password>
export INSTALL_BUNDLE=registry.tanzu.vmware.com/tanzu-cluster-essentials/cluster-essentials-bundle@sha256:ab0a3539da241a6ea59c75c0743e9058511d7c56312ea3906178ec0f3491f51d

# login to kubernetes workload cluster using cluster config
kubectl config use-context "${TAP_WORKLOAD_CONTEXT}"

export token=$(curl -X POST https://network.pivotal.io/api/v2/authentication/access_tokens -d '{"refresh_token":"'${TANZU_NET_API_TOKEN}'"}')
access_token=$(echo ${token} | jq -r .access_token)

curl -i -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Bearer ${access_token}" -X GET https://network.pivotal.io/api/v2/authentication

# install tanzu cluster essentials(linux)
mkdir $HOME/tanzu-cluster-essentials
wget https://network.tanzu.vmware.com/api/v2/products/tanzu-cluster-essentials/releases/1077299/product_files/1191987/download --header="Authorization: Bearer ${access_token}" -O $HOME/tanzu-cluster-essentials/tanzu-cluster-essentials-linux-amd64-1.1.0.tgz
tar -xvf $HOME/tanzu-cluster-essentials/tanzu-cluster-essentials-linux-amd64-1.1.0.tgz -C $HOME/tanzu-cluster-essentials

cd $HOME/tanzu-cluster-essentials
./install.sh

sudo cp $HOME/tanzu-cluster-essentials/kapp /usr/local/bin/kapp

cd $HOME

# install tanzu cli v(0.11.2) and plug-ins (linux)
mkdir $HOME/tanzu
cd $HOME/tanzu
wget https://network.pivotal.io/api/v2/products/tanzu-application-platform/releases/1078790/product_files/1190781/download --header="Authorization: Bearer ${access_token}" -O $HOME/tanzu/tanzu-framework-linux-amd64.tar
tar -xvf $HOME/tanzu/tanzu-framework-linux-amd64.tar -C $HOME/tanzu

sudo install cli/core/v0.11.2/tanzu-core-linux_amd64 /usr/local/bin/tanzu

# tanzu plug-ins
export TANZU_CLI_NO_INIT=true
tanzu plugin install --local cli all
tanzu plugin list

cd $HOME


# install yq package
sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
sudo chmod a+x /usr/local/bin/yq
yq --version
```

### <a id=tap-package-repo> </a>Step 2: Add the Tanzu Application Platform Package Repository

To install kapp-controller on workload clusters that are deployed on vSphere with Tanzu (TKGS) using YAML files and Tanzu Kubernetes Grid API, see [Prepare a Tanzu Kubernetes Cluster Created by Using vSphere with Tanzu to Run Packages](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.4/vmware-tanzu-kubernetes-grid-14/GUID-packages-prep-tkgs-kapp.html).
<!-- /* cSpell:disable */ -->
After installing `kapp-controller`, install [carvel-secretgen-controller](https://github.com/vmware-tanzu/carvel-secretgen-controller). Use the following command:
<!-- /* cSpell:enable */ -->
```bash
kubectl apply -f https://github.com/vmware-tanzu/carvel-secretgen-controller/releases/latest/download/release.yml
```

Execute following commands to add TAP package.

```bash
set -e

export TAP_NAMESPACE="tap-install"
kubectl create ns "${TAP_NAMESPACE}"

# tanzu registry secret creation
tanzu secret registry add tap-registry \
  --username "${INSTALL_REGISTRY_USERNAME}" --password "${INSTALL_REGISTRY_PASSWORD}" \
  --server "${INSTALL_REGISTRY_HOSTNAME}" \
  --export-to-all-namespaces --yes --namespace "${TAP_NAMESPACE}"

# tanzu repo add
tanzu package repository add tanzu-tap-repository \
  --url registry.tanzu.vmware.com/tanzu-application-platform/tap-packages:1.1.0 \
  --namespace "${TAP_NAMESPACE}"

tanzu package repository get tanzu-tap-repository --namespace "${TAP_NAMESPACE}"

# tap available package list
tanzu package available list --namespace "${TAP_NAMESPACE}"
```

### <a id=tap-profile-build> </a>Step 3: Install Tanzu Application Platform Build Profile

Provide following user inputs to set environment variables into commands and execute them to install the build profile.

* `TAP_REGISTRY_SERVER` - uri of registry server
* `TAP_REGISTRY_USER` - registry user
* `TAP_REGISTRY_PASSWORD` - registry password
* `INSTALL_REGISTRY_USERNAME`- tanzu net username
* `INSTALL_REGISTRY_PASSWORD` - tanzu net password

 For more information, see [Build Profile](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.1/tap/GUID-multicluster-reference-tap-values-build-sample.html) in the Tanzu Application Platform product documentation.

```bash
set -e

export TAP_NAMESPACE="tap-install"
export TAP_REGISTRY_SERVER=<registry server uri>
export TAP_REGISTRY_USER=<registry user>
export TAP_REGISTRY_PASSWORD=<registry password>
export INSTALL_REGISTRY_USERNAME=<tanzu username>
export INSTALL_REGISTRY_PASSWORD=<tanzu password>

cat <<EOF | tee tap-values-build.yaml
profile: build
ceip_policy_disclosed: true
buildservice:
  kp_default_repository: "${TAP_REGISTRY_SERVER}/build-service"
  kp_default_repository_username: "${TAP_REGISTRY_USER}"
  kp_default_repository_password: "${TAP_REGISTRY_PASSWORD}"
  tanzunet_username: "${INSTALL_REGISTRY_USERNAME}"
  tanzunet_password: "${INSTALL_REGISTRY_PASSWORD}"
  descriptor_name: "full"
  enable_automatic_dependency_updates: true
supply_chain: basic
ootb_supply_chain_basic:    
  registry:
    server: "${TAP_REGISTRY_SERVER}"
    repository: "supply-chain"
  gitops:
    ssh_secret: ""
  cluster_builder: default
  service_account: default
grype:
  targetImagePullSecret: "tap-registry"
image_policy_webhook:
  allow_unmatched_images: true

EOF

tanzu package install tap -p tap.tanzu.vmware.com -v 1.1.0 --values-file tap-values-build.yaml -n "${TAP_NAMESPACE}"
tanzu package installed get tap -n "${TAP_NAMESPACE}"

# check all build cluster package installed succesfully
tanzu package installed list -A
```

### <a id=tap-dev-namespace> </a>Step 4: Configure developer namespaces to use installed packages

Execute the following commands to configure a developer namespace:

```bash
set -e

export TAP_DEV_NAMESPACE="default"
export TAP_REGISTRY_SERVER=<registry server uri>
export TAP_REGISTRY_USER=<registry user>
export TAP_REGISTRY_PASSWORD=<registry password>

tanzu secret registry add registry-credentials --server "${TAP_REGISTRY_SERVER}" --username "${TAP_REGISTRY_USER}" --password "${TAP_REGISTRY_PASSWORD}" --namespace "${TAP_DEV_NAMESPACE}"

cat <<EOF | kubectl -n "${TAP_DEV_NAMESPACE}" apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: tap-registry
  annotations:
    secretgen.carvel.dev/image-pull-secret: ""
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: e30K
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: default
secrets:
  - name: registry-credentials
imagePullSecrets:
  - name: registry-credentials
  - name: tap-registry
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: default-permit-deliverable
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: deliverable
subjects:
  - kind: ServiceAccount
    name: default
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: default-permit-workload
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: workload
subjects:
  - kind: ServiceAccount
    name: default
EOF


```


## <a id=tap-run> </a> Set Up Tanzu Application Platform Run Cluster

The Run Cluster utilizes the container image and Kubernetes resources created by the Build Cluster and runs them as defined in the Deliverable object for each application.

### Step 1: Install Tanzu Cluster Essentials and Tanzu CLI
Log in to your Kubernetes Run Cluster and perform steps outlined in [Install Tanzu Cluster Essentials and Tanzu CLI](#tanzu-essential).

### Step 2: Add the Tanzu Application Platform Package Repository
Perform the steps outlined in [Add the Tanzu Application Platform package repository](#tap-package-repo).

### <a id=tap-profile-run> </a>Step 3: Install Tanzu Application Platform Run Profile

Provide the following user inputs to set environments variables into commands and execute them to install run profile
<!-- /* cSpell:disable */ -->
* `TAP_REGISTRY_SERVER` - uri of the image registry
* `TAP_REGISTRY_USER` - registry user
* `TAP_REGISTRY_PASSWORD` - registry password
* `TAP_CNRS_DOMAIN` - cnrs app domain (could be sub domain  of main domain like example - run.customer0.io)
* `TAP_ALV_DOMAIN` -  app live view app domain 
<!-- /* cSpell:enable */ -->
**Note** - Contour settings in tap-values-run.yaml must be modified if you are not using AWS.

 For more information, see [Run Profile](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.1/tap/GUID-multicluster-reference-tap-values-run-sample.html) in the Tanzu Application Platform product documentation.

```bash
set -e

export TAP_NAMESPACE="tap-install"
export TAP_REGISTRY_SERVER=<registry uri>
export TAP_REGISTRY_USER=<registry user>
export TAP_REGISTRY_PASSWORD=<registry password>
export TAP_CNRS_DOMAIN=<cnrs domain>
export TAP_ALV_DOMAIN=< app live view app domain>

cat <<EOF | tee tap-values-run.yaml
profile: run
ceip_policy_disclosed: true
supply_chain: basic
contour:
  infrastructure_provider: aws
  envoy:
    service:
      aws:
        LBType: nlb
cnrs:
  domain_name: "${tap_run_cnrs_domain}"
appliveview_connector:
  backend:
    sslDisabled: true
    host: appliveview.$TAP_ALV_DOMAIN

EOF

tanzu package install tap -p tap.tanzu.vmware.com -v 1.1.0 --values-file tap-values-run.yaml -n "${TAP_NAMESPACE}"
tanzu package installed get tap -n "${TAP_NAMESPACE}"

# check all build cluster package installed succesfully
tanzu package installed list -A

# check ingress external ip
kubectl get svc -n tanzu-system-ingress

# pick external ip from service output  and configure DNS wild card(*) into your DNS server like aws route 53 etc.
# example - *.run.customer0.io ==> <ingress external ip/cname>
```

### Step 4: Configure Developer Namespaces to Use Installed Packages

Perform the steps outlined in [Configure developer namespaces to use installed packages](#tap-dev-namespace)

Execute steps 1-4 outlined in [Set Up Tanzu Application Platform Run cluster](#tap-run) to build Dev/Test/QA/Prod clusters.


## <a id=tap-ui> </a> Set Up Tanzu Application Platform View Cluster

The View cluster is designed to run the web applications for TAP; specifically Tanzu Learning Center, Tanzu Application Portal GUI, and Tanzu API Portal.

### Step 1: Install Tanzu Cluster Essentials and Tanzu CLI
Please ensure you login into your Kubernetes Run cluster and perform steps outlined in [Install Tanzu Cluster Essentials and Tanzu CLI](#tanzu-essential).

### Step 2: Add the Tanzu Application Platform Package Repository
Perform steps outlined in [Add the Tanzu Application Platform package repository](#tap-package-repo)

### <a id=tap-profile-ui> </a>Step 3: Install Tanzu Application Platform View Profile

Provide following user inputs to set environments variables into commands and execute them to install view profile

* `TAP_REGISTRY_SERVER` - uri of image registry
* `TAP_REGISTRY_USER` - registry user
* `TAP_REGISTRY_PASSWORD` - registry password
* `TAP_GITHUB_TOKEN` - GitHub personal access token
* `TAP_APP_DOMAIN`  - app domain you want to use for tap-gui
* `TAP_GIT_CATALOG_URL` - git catalog url.  
    See this [example](https://github.com/sendjainabhi/tap/blob/main/catalog-info.yaml)
* `TAP_RUN_CLUSTER_NAME` - Run cluster name

 See [View Profile](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.1/tap/GUID-multicluster-reference-tap-values-view-sample.html) for more details.



```bash
set -e
export TAP_NAMESPACE="tap-install"
export TAP_SERVICE_ACCOUNT_NAME="default"


cat <<EOF | tee tap-gui-viewer-service-account-rbac.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: tap-gui
---
apiVersion: v1
kind: ServiceAccount
metadata:
  namespace: tap-gui
  name: tap-gui-viewer
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: tap-gui-read-k8s
subjects:
- kind: ServiceAccount
  namespace: tap-gui
  name: tap-gui-viewer
roleRef:
  kind: ClusterRole
  name: k8s-reader
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: k8s-reader
rules:
- apiGroups: ['']
  resources: ['pods', 'services', 'configmaps']
  verbs: ['get', 'watch', 'list']
- apiGroups: ['apps']
  resources: ['deployments', 'replicasets']
  verbs: ['get', 'watch', 'list']
- apiGroups: ['autoscaling']
  resources: ['horizontalpodautoscalers']
  verbs: ['get', 'watch', 'list']
- apiGroups: ['networking.k8s.io']
  resources: ['ingresses']
  verbs: ['get', 'watch', 'list']
- apiGroups: ['networking.internal.knative.dev']
  resources: ['serverlessservices']
  verbs: ['get', 'watch', 'list']
- apiGroups: [ 'autoscaling.internal.knative.dev' ]
  resources: [ 'podautoscalers' ]
  verbs: [ 'get', 'watch', 'list' ]
- apiGroups: ['serving.knative.dev']
  resources:
  - configurations
  - revisions
  - routes
  - services
  verbs: ['get', 'watch', 'list']
- apiGroups: ['carto.run']
  resources:
  - clusterconfigtemplates
  - clusterdeliveries
  - clusterdeploymenttemplates
  - clusterimagetemplates
  - clusterruntemplates
  - clustersourcetemplates
  - clustersupplychains
  - clustertemplates
  - deliverables
  - runnables
  - workloads
  verbs: ['get', 'watch', 'list']
- apiGroups: ['source.toolkit.fluxcd.io']
  resources:
  - gitrepositories
  verbs: ['get', 'watch', 'list']
- apiGroups: ['source.apps.tanzu.vmware.com']
  resources:
  - imagerepositories
  verbs: ['get', 'watch', 'list']
- apiGroups: ['conventions.apps.tanzu.vmware.com']
  resources:
  - podintents
  verbs: ['get', 'watch', 'list']
- apiGroups: ['kpack.io']
  resources:
  - images
  - builds
  verbs: ['get', 'watch', 'list']
- apiGroups: ['scanning.apps.tanzu.vmware.com']
  resources:
  - sourcescans
  - imagescans
  - scanpolicies
  verbs: ['get', 'watch', 'list']
- apiGroups: ['tekton.dev']
  resources:
  - taskruns
  - pipelineruns
  verbs: ['get', 'watch', 'list']
- apiGroups: ['kappctrl.k14s.io']
  resources:
  - apps
  verbs: ['get', 'watch', 'list']
EOF

kubectl create -f tap-gui-viewer-service-account-rbac.yaml

CLUSTER_URL=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')

CLUSTER_TOKEN=$(kubectl -n tap-gui get secret $(kubectl -n tap-gui get sa tap-gui-viewer -o=json \
| jq -r '.secrets[0].name') -o=json \
| jq -r '.data["token"]' \
| base64 --decode)

  ```

  See [Backstage](https://backstage.io/docs/features/kubernetes/configuration#label-selector-query-annotation) documentation for multi-cluster/multi-tenant details.


```bash
set -e

# set the following variables
export TAP_NAMESPACE="tap-install"
export TAP_REGISTRY_SERVER=<registry server uri>
export TAP_REGISTRY_USER=<registry_user>
export TAP_REGISTRY_PASSWORD=<registry_password>
export TAP_GITHUB_TOKEN=<github_token>
export TAP_VIEW_APP_DOMAIN=<sub domain of view cluster>
export TAP_GIT_CATALOG_URL=<git_catalog_url>
export TAP_RUN_CLUSTER_NAME=<run cluster name>
export TAP_ALV_DOMAIN=< app live view app domain>


cat <<EOF | tee tap-values-view.yaml
profile: view
ceip_policy_disclosed: true
contour:
  envoy:
    service:
      type: LoadBalancer
learningcenter:
  ingressDomain: "learning.${TAP_VIEW_APP_DOMAIN}"
  ingressClass: contour
tap_gui:
  service_type: ClusterIP
  ingressEnabled: "true"
  ingressDomain: "${TAP_VIEW_APP_DOMAIN}"
  app_config:
    app:
      baseUrl: "http://tap-gui.${TAP_VIEW_APP_DOMAIN}"
    catalog:
      locations:
        - type: url
          target: ${TAP_GIT_CATALOG_URL}
    backend:
        baseUrl: "http://tap-gui.${TAP_VIEW_APP_DOMAIN}"
        cors:
          origin: "http://tap-gui.${TAP_VIEW_APP_DOMAIN}"
    kubernetes:
      serviceLocatorMethod:
        type: "multiTenant"
      clusterLocatorMethods:
        - type: "config"
          clusters:
            - url: ${CLUSTER_URL}
              name: ${TAP_RUN_CLUSTER_NAME}
              authProvider: "serviceAccount"
              skipTLSVerify: true
              skipMetricsLookup: true
              serviceAccountToken: "${CLUSTER_TOKEN}"
metadata_store:
  app_service_type: LoadBalancer
appliveview:
  ingressEnabled: true
  ingressDomain: "${TAP_ALV_DOMAIN}" 
EOF

tanzu package install tap -p tap.tanzu.vmware.com -v 1.1.0 --values-file tap-values-view.yaml -n "${TAP_NAMESPACE}"
tanzu package installed get tap -n "${TAP_NAMESPACE}"

# ensure all build cluster packages are installed succesfully
tanzu package installed list -A

kubectl get svc -n tanzu-system-ingress

# pick an external ip from service output and configure DNS wildcard records
# example - *.ui.customer0.io ==> <ingress external ip/cname>
```

### Step 4: Set Up Developer Namespaces to Use Installed Packages
Perform the steps outlined in [Configure developer namespaces to use installed packages](#tap-dev-namespace)

### Deploy Sample Application
See the steps to deploy and test the [sample application](#tap-sample-app).

For more information, also see [Getting started with the Tanzu Application Platform](https://docs.vmware.com/en/Tanzu-Application-Platform/1.1/tap/GUID-getting-started.html).


## <a id=tap-full> </a> Set Up Tanzu Application Platform Iterate Cluster

The Iterate Cluster is for "inner loop" development iteration where developers are connecting via their IDE to rapidly iterate on new software features

### Step 1: Install Tanzu Cluster Essentials and Tanzu CLI
Log in to the Kubernetes View Cluster and perform steps outlined in [Install Tanzu Cluster Essentials and Tanzu CLI](#tanzu-essential).

### Step 2: Add the Tanzu Application Platform Package Repository
Perform steps outlined in [Add the Tanzu Application Platform package repository](#tap-package-repo)


### <a id=tap-profile-full> </a>Step 3: Install Tanzu Application Platform Iterate Profile

Provide the following user inputs to set environment variables into commands and execute them to install Iterate profile

* `TAP_REGISTRY_SERVER` - uri of image registry
* `TAP_REGISTRY_USER` - registry user
* `TAP_REGISTRY_PASSWORD` - registry user
* `TAP_GITHUB_TOKEN` - GitHub personal access token
* `TAP_APP_DOMAIN` - app domain you want to use for tap-gui
* `INSTALL_REGISTRY_USERNAME`- tanzu net username
* `INSTALL_REGISTRY_PASSWORD` - tanzu net  password
* `TAP_ITERATE_CNRS_DOMAIN` - tap iterate cluster cnrs domain

For more information, see [Full Profile](https://docs.vmware.com/en/Tanzu-Application-Platform/1.1/tap/GUID-install.html#full-profile) in the Tanzu Application Platform product documentation.

```bash
set -e

# set following variables
export TAP_NAMESPACE="tap-install"
export TAP_REGISTRY_SERVER=<registry server uri>
export TAP_REGISTRY_USER=<registry user>
export TAP_REGISTRY_PASSWORD=<registry password>
export TAP_ITERATE_CNRS_DOMAIN=<tap iterate cnrs  domain>
export INSTALL_REGISTRY_USERNAME=<tanzu net username>
export INSTALL_REGISTRY_PASSWORD=<tanzu net  password>


cat <<EOF | tee tap-values-iterate.yaml

profile: iterate

ceip_policy_disclosed: true

buildservice:
  kp_default_repository: "${TAP_REGISTRY_SERVER}/build-service"
  kp_default_repository_username: "${TAP_REGISTRY_USER}"
  kp_default_repository_password: "${TAP_REGISTRY_PASSWORD}"
  tanzunet_username: "${INSTALL_REGISTRY_USERNAME}"
  tanzunet_password: "${INSTALL_REGISTRY_PASSWORD}"
  descriptor_name: "full"
  enable_automatic_dependency_updates: true

supply_chain: basic
ootb_supply_chain_basic:
  registry:
    server: "${TAP_REGISTRY_SERVER}"
    repository: "supply-chain"
  gitops:
    ssh_secret: ""

metadata_store:
  app_service_type: LoadBalancer

image_policy_webhook:
  allow_unmatched_tags: true

contour:
  envoy:
    service:
      type: LoadBalancer

cnrs:
  domain_name: "${TAP_ITERATE_CNRS_DOMAIN}"


tanzu package install tap -p tap.tanzu.vmware.com -v 1.1.0 --values-file tap-values-iterate.yaml -n "${TAP_NAMESPACE}"
tanzu package installed get tap -n "${TAP_NAMESPACE}"

#check all build cluster package installed succesfully
tanzu package installed list -A

kubectl get svc -n tanzu-system-ingress

#pick external ip from output and configure DNS wild card into your DNS server like aws route 53 etc.
```

### Step 4: Set Up Developer Namespaces to Use Installed Packages
Perform the steps outlined in [Set up developer namespaces to use installed packages](#tap-dev-namespace)


## <a id=tap-sample-app> Deploy Sample Application

Execute following command to see the demo of sample app deployment into Tanzu Application Platform.

```bash
set -e

# login to kubernetes workload build cluster
kubectl config get-contexts
kubectl config use-context <cluster config name>

export TAP_APP_NAME="tap-demo"
export TAP_APP_GIT_URL="https://github.com/sample-accelerators/spring-petclinic"

tanzu apps workload delete --all

tanzu apps workload list

# generate work load yml file
tanzu apps workload create "${TAP_APP_NAME}" --git-repo "${TAP_APP_GIT_URL}" --git-branch main --type web --label app.kubernetes.io/part-of="${TAP_APP_NAME}" --yes --dry-run

# create work load for app
tanzu apps workload create "${TAP_APP_NAME}" \
--git-repo "${TAP_APP_GIT_URL}" \
--git-branch main \
--git-tag tap-1.1 \
--type web \
--label app.kubernetes.io/part-of="${TAP_APP_NAME}" \
--label apps.tanzu.vmware.com/has-tests=true \
--yes

# app deployment logs#sam
tanzu apps workload tail "${TAP_APP_NAME}" --since 10m --timestamp

# get app workload list
tanzu apps workload list

# get app details
tanzu apps workload get "${TAP_APP_NAME}"

# saved deliverables yaml configuration into local directory. check below sample file below
kubectl get deliverables "${TAP_APP_NAME}" -o yaml |  yq 'del(.status)'  | yq 'del(.metadata.ownerReferences)' | yq 'del(.metadata.resourceVersion)' | yq 'del(.metadata.uid)' >  "${TAP_APP_NAME}-delivery.yaml"

# sample deliverable
##################################################
apiVersion: carto.run/v1alpha1
kind: Deliverable
metadata:
  creationTimestamp: "2022-02-01T20:19:19Z"
  generation: 1
  labels:
    app.kubernetes.io/component: deliverable
    app.kubernetes.io/part-of: tap-demo
    app.tanzu.vmware.com/deliverable-type: web
    carto.run/cluster-supply-chain-name: source-to-url
    carto.run/cluster-template-name: deliverable-template
    carto.run/resource-name: deliverable
    carto.run/template-kind: ClusterTemplate
    carto.run/workload-name: tap-demo
    carto.run/workload-namespace: default
  name: tap-demo
  namespace: default
spec:
  source:
    image: tapdemo2.azurecr.io/supply-chain/tap-demo-default-bundle:83c468d4-4fd0-4f3b-9e57-9cdfe57e730a

##################################################################

 # login to kubernetes workload run cluster
kubectl config get-contexts
kubectl config use-context <cluster config name>  

# apply app-delivery into run cluster

kubectl apply -f app-delivery.yaml

# check app status
kubectl get deliverables "${TAP_APP_NAME}"

# get app url
kubectl get ksvc

# copy app url and paste into browser to see the sample app

```

### Register Entity into tap-gui

* Open tap-gui URL and click the **Register Entity** button and provide the `catalog-info.yaml` file URL of your app. See [Example](https://github.com/sample-accelerators/tanzu-java-web-app/blob/main/catalog/catalog-info.yaml).

* Make sure you have set up `app.kubernetes.io/part-of=app name` correctly into your app catalog-info.yaml. and it should match with your app name.
**Example: `'backstage.io/kubernetes-label-selector': 'app.kubernetes.io/part-of=tap-demo2'`**

### Troubleshooting Tanzu Application Platform

In the event of failure, use the following command to obtain failure details:
`kubectl get packageinstall/<package> -n tap-install -o yaml`.

See [Troubleshooting Tanzu Application Platform Tips](https://docs.vmware.com/en/Tanzu-Application-Platform/1.1/tap/GUID-troubleshooting.html) for additional details.


### Service Bindings for Kubernetes

See [Service Bindings for Kubernetes](https://docs.vmware.com/en/Tanzu-Application-Platform/1.1/tap/GUID-service-bindings-about.html) for additional details.


### Tanzu Application Platform GUI Auth Provider

See [Setting up a Tanzu Application Platform GUI authentication provider](https://docs.vmware.com/en/Tanzu-Application-Platform/1.1/tap/GUID-tap-gui-auth.html) for additional details.
