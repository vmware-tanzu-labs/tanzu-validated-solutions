# NOTE: RUNNING AS ROOT
echo ~~~~~~ SETUP ENV
export VMWUSER='REDACTED'
export VMWPASS='REDACTED'
# export HOME='./'
echo ~~~~~~ SYSTEM UPDATES
apt-get install -y wget apt-transport-https software-properties-common
wget -q https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb
apt update
apt upgrade
echo ~~~~~~ INSTALL SYSTEM COMPONENTS
apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
apt-cache policy docker-ce
apt install -y docker-ce
usermod -aG docker azureuser
# install Node 12
apt -y install curl dirmngr apt-transport-https lsb-release ca-certificates
curl -sL https://deb.nodesource.com/setup_12.x | bash -
apt -y  install nodejs gcc g++ make
mkdir .npm
# chown -R azureuser ~/.npm
# Added chown for .config [ogradin]
mkdir .config
chown -R azureuser /usr/lib/node_modules
# sudo touch /usr/bin/vmw-cli [ogradin]
echo ~~~~~~ INSTALL TANZU CLI
npm install vmw-cli --global
vmw-cli ls vmware_tanzu_kubernetes_grid
vmw-cli cp tanzu-cli-bundle-linux-amd64.tar
vmw-cli cp kubectl-linux-v1.21.2+vmware.1.gz
# rm -rf ./tanzu
mkdir -p /home/azureuser
chown -R azureuser /home/azureuser
mkdir -p /home/azureuser/tanzu
tar -xvf tanzu-cli-bundle-linux-amd64.tar -C /home/azureuser/tanzu
install /home/azureuser/tanzu/cli/core/v*/tanzu-core-linux_amd64 /usr/local/bin/tanzu
gunzip kubectl-linux-v1.21.2+vmware.1.gz
install kubectl-linux-v1.21.2+vmware.1 /usr/local/bin/kubectl
# sudo apt-get install -y powershell
# pwsh -c Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
# pwsh -c Install-Module Poshstache
curl -sL https://aka.ms/InstallAzureCLIDeb | bash
# echo ~~~~~~ INSTALL TANZU CLI PLUGINS
# tanzu plugin install --local tanzu/cli all
# tanzu plugin list
# echo ~~~~~~ CREATE TANZU MANAGEMENT CLUSTER
# tanzu management-cluster create --file config.yaml -v 9
exit 0