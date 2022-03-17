# VMW CLI for Customer Connect
export VMWUSER='username'
export VMWPASS='password' 

# Azure Subscription and Service Principal Variables
export AZURECLIENTID='CLIENTID'
export AZURECLIENTSECRET='CLIENTKEY'
export AZURETENANTID='AADTENANTID'
export AZURESUBSCRIPTION='SUBSCRIPTIONID'

# Tanzu TMC Variables
export TMC_API_TOKEN='ALLROLESTOKEN'
export CLUSTERGROUP='TMCLUSTERGROUPNAME'
export CLUSTERNAME='WORKLOADCLUSTERNAME'

# Customer Connect Downloads
git clone https://github.com/z4ce/vmw-cli
cd vmw-cli
./vmw-cli ls
./vmw-cli ls vmware_tanzu_kubernetes_grid
./vmw-cli cp tanzu-cli-bundle-linux-amd64.tar
./vmw-cli cp kubectl-linux-v1.21.2+vmware.1.gz

tar -xvf tanzu-cli-bundle-linux-amd64.tar
gzip -d kubectl-linux-v1.21.2+vmware.1.gz
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