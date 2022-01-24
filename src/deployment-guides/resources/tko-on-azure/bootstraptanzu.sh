#VMW CLI for Customer Connect
# export VMWUSER='username'
# export VMWPASS='password'

#VM Ware Marketplace CLI Variable
export CSP_API_TOKEN=<VMWare Marketplace API Token> 

# Azure Subscription and Service Principal Variables
export AZURECLIENTID='CLIENTID'
export AZURECLIENTSECRET='CLIENTKEY'
export AZURETENANTID='AADTENANTID'
export AZURESUBSCRIPTION='SUBSCRIPTIONID'

# Tanzu TMC Variables
export TMC_API_TOKEN='ALLROLESTOKEN'
export CLUSTERGROUP='TMCLUSTERGROUPNAME'
export CLUSTERNAME='WORKLOADCLUSTERNAME'

# Download & Install Tanzu CLI and Kubectl
wget https://github.com/vmware-labs/marketplace-cli/releases/download/v0.7.1/mkpcli-linux-amd64 
sudo install mkpcli-linux-amd64 /usr/local/bin/mkpcli
mkpcli product get -p tanzu-kubernetes-grid-1-1-1211
mkpcli download -p tanzu-kubernetes-grid-1-1-1211 --filter kubectl
mkpcli download -p tanzu-kubernetes-grid-1-1-1211 --filter tanzu-cli
tar -xvf tanzu-cli-bundle-linux-amd64-tar-tar.tar
gzip -d kubectl-linux-v1-21-2-vmware-1-gz-gz.gz
sudo install cli/core/v1.4.1/tanzu-core-linux_amd64 /usr/local/bin/tanzu

# TMC API Download
curl -o tmc 'https://tmc-cli.s3-us-west-2.amazonaws.com/tmc/0.4.0-fdabbe74/linux/x64/tmc'
sudo install tmc /usr/local/bin/tmc

tanzu plugin install --local cli all
sudo install kubectl-linux-v1-21-2-vmware-1-gz-gz /usr/local/bin/kubectl

# Azure CLI Install and VM Acceptance
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

az login --service-principal --username $AZURECLIENTID --password $AZURECLIENTSECRET --tenant $AZURETENANTID
az vm image terms accept --publisher vmware-inc --offer tkg-capi --plan k8s-1dot21dot2-ubuntu-2004 --subscription $AZURESUBSCRIPTION

tanzu management-cluster create --file management-config.yaml -v 6

tanzu cluster create --file workload-config.yaml -v 6

# Connect Workload Cluster to TMC
tanzu cluster kubeconfig get $CLUSTERNAME --admin --export-file ./workloadkube.yaml
kubectl config use-context $CLUSTERNAME-admin@$CLUSTERNAME --kubeconfig ./workloadkube.yaml
  
tmc login -name workloadCluster

tmc cluster attach --cluster-group $CLUSTERGROUP --name $CLUSTERNAME -k ./workloadkube.yaml