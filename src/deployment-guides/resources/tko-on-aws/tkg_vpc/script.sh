#!/usr/bin/env bash

sudo apt-get -y update
sudo apt-get -y dist-upgrade
sudo apt-get -y install docker.io
sudo adduser ubuntu docker


cat <<'EOF' > /home/ubuntu/tkg-install/finish-install.sh
#!/usr/bin/env bash
# If you're not using vmw-cli to download,
# You need to have
# - tanzu-cli-bundle-linux-amd64.tar
# - tmc
# - kubectl-linux-amd64*.gz with kubectl in it

if [[ ! -f vmw-cli ]]; then 
    if [[ $1 == "" || $2 == "" ]]; then
        echo "Usage: $0 <myvmwuser> <myvmwpass> [or prepopulate /home/ubuntu/vmw-cli with the binaries]"
        exit 1
    fi
export VMWUSER="$1"
export VMWPASS="$2"
cd  /home/ubuntu
git clone https://github.com/z4ce/vmw-cli
cd vmw-cli
curl -o tmc 'https://tmc-cli.s3-us-west-2.amazonaws.com/tmc/0.4.0-fdabbe74/linux/x64/tmc'
./vmw-cli ls
./vmw-cli ls vmware_tanzu_kubernetes_grid
./vmw-cli cp tanzu-cli-bundle-linux-amd64.tar
./vmw-cli cp "$(./vmw-cli ls vmware_tanzu_kubernetes_grid | grep kubectl-linux | cut -d ' ' -f1)"
fi

sudo install tmc /usr/local/bin/tmc
tar -xvf tanzu-cli-bundle-linux-amd64.tar
gunzip kubectl-*.gz
sudo install kubectl-linux-* /usr/local/bin/kubectl
cd cli/
sudo install core/*/tanzu-core-linux_amd64 /usr/local/bin/tanzu
gunzip *.gz
sudo install imgpkg-linux-amd64-* /usr/local/bin/imgpkg
sudo install kapp-linux-amd64-* /usr/local/bin/kapp
sudo install kbld-linux-amd64-* /usr/local/bin/kbld
sudo install vendir-linux-amd64-* /usr/local/bin/vendir
sudo install ytt-linux-amd64-* /usr/local/bin/ytt
cd ..
tanzu plugin install --local cli all

tanzu config init
cat <<EEOF > ~/.config/tanzu/tkg/providers/ytt/03_customizations/internal_lb.yaml
#@ load("@ytt:overlay", "overlay")
#@ load("@ytt:data", "data")

#@overlay/match by=overlay.subset({"kind":"AWSCluster"})
---
apiVersion: infrastructure.cluster.x-k8s.io/v1alpha3
kind: AWSCluster
spec:
#@overlay/match missing_ok=True
    controlPlaneLoadBalancer:
#@overlay/match missing_ok=True
       scheme: "internal"

EEOF
# Management cluster creation will show successful with package errors
# This is because pinniped isn't configured yet, but this allows us to
# configure pinniped later, whereas if we don't enable it, it cannot
# do it later.
cd /home/ubuntu/tkg-install
tanzu management-cluster create --file ./mgmt.yaml
tanzu management-cluster kubeconfig get --admin

kubectl config use-context tkg-mgmt-aws-admin@tkg-mgmt-aws
kubectl get pods -A

CLUSTER_NAME=tkg-wl-aws tanzu cluster create tkg-wl-aws --file ./mgmt.yaml



tanzu cluster kubeconfig get tkg-wl-aws --admin
kubectl config use-context tkg-wl-aws-admin@tkg-wl-aws

# Start installing packages
kubectl create namespace tanzu-packages
# cert manager
tanzu package install cert-manager --package-name cert-manager.tanzu.vmware.com --namespace tanzu-packages --version 1.1.0+vmware.1-tkg.2


# contour ingress
tanzu package install contour \
--package-name contour.tanzu.vmware.com \
--version 1.17.1+vmware.1-tkg.1 \
--values-file contour-data-values.yaml \
--namespace tanzu-packages
# fluent-bit
tanzu package install fluent-bit --package-name fluent-bit.tanzu.vmware.com --namespace tanzu-packages --version 1.7.5+vmware.1-tkg.1 
# tanzu package installed list -A

# install prometheus 
tanzu package install prometheus \
--package-name prometheus.tanzu.vmware.com \
--version 2.27.0+vmware.1-tkg.1 \
--values-file prometheus-data-values.yaml \
--namespace tanzu-packages

# install grafana

tanzu package install grafana \
--package-name grafana.tanzu.vmware.com \
--version 7.5.7+vmware.1-tkg.1 \
--values-file grafana-data-values.yaml \
--namespace tanzu-packages


# Harbor installation - To set your own passwords and secrets, update the following entries in the harbor-data-values.yaml file:
# hostname , harborAdminPassword,secretKey,database.password,core.secret,core.xsrfKey,jobservice.secret,registry.secret

tanzu package install harbor \
--package-name harbor.tanzu.vmware.com \
--version 2.2.3+vmware.1-tkg.1 \
--values-file harbor-data-values.yaml \
--namespace tanzu-packages


if [[ "$TMC_API_TOKEN" != "" ]]; then

    # how to login to tmc with tmc token  
    tmc login --no-configure -name tkgaws-automation
    # cluster login
    tanzu cluster kubeconfig get tkg-wl-aws  --admin --export-file ./tkg-wl-aws_admin_conf.yaml
    kubectl config use-context tkg-wl-aws-admin@tkg-wl-aws --kubeconfig ./tkg-wl-aws_admin_conf.yaml
    # attached tmc cluster command
    tmc cluster attach --name tkg-wl-aws --cluster-group default -k ./tkg-wl-aws_admin_conf.yaml

    if [[ "$SKIP_TO" == "" ]]; then
        # install tanzu Observability steps - fill the template file tanzu-Observability-config.yaml config details
        tmc cluster integration create -f to-registration.yaml
        # check pod status 
        # kubectl get pods -n tanzu-observability-saas
        # validate TO integration status 
        # tmc cluster integration get tanzu-observability-saas --cluster-name tkg-wl-aws -m tkg-mgmt-aws -p tkg-mgmt-aws
    fi

    if [[ "$SKIP_TSM" == "" ]]; then
            tmc cluster integration create -f tsm-registration.yaml
    fi

fi




EOF

chmod a+x /home/ubuntu/tkg-install/finish-install.sh
