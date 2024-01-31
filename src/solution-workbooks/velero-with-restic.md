Install Velero with Restic in Tanzu Kubernetes Cluster

 [Velero](https://velero.io/docs), is an open source community standard tool to back up and restore TKG standalone management cluster infrastructure and workloads.

 A Tanzu Kubernetes Grid subscription includes support for VMware’s tested, compatible distribution of Velero available from the Tanzu Kubernetes Grid downloads page.

To back up and restore TKG clusters, you need:

- The Velero CLI running on your local client machine.
- A storage provider with locations to save the backups to.
- A Velero server running on the clusters that you are backing up.

## Install the Velero CLI

To install the Velero CLI on your client machine, do the following:

- Go to the [Tanzu Kubernetes Grid downloads page](https://customerconnect.vmware.com/en/web/vmware/downloads/info/slug/infrastructure_operations_management/vmware_tanzu_kubernetes_grid/2_x) and log in with your VMware Customer Connect credentials.
- Under **Product Downloads**, click **Go to Downloads**.
- Select the respective Tanzu Kubernetes Grid version, scroll down to the Velero entries and download the Velero CLI .gz file your client machine OS. 
- Extract the binary.
    ```bash
    gunzip velero-linux-v1.11.1+vmware.1.gz
    ```
- Rename the CLI binary for your platform to `velero`, make sure that it is executable, and add it to your PATH. <br>
For linux:
    ```bash
    mv velero /usr/local/bin/velero
    chmod +x /usr/local/bin/velero
    ```

## Set Up a Storage Provider
Velero supports a variety of [storage providers](https://velero.io/docs/main/supported-providers), which can be either:

- An online cloud storage provider.
- An on-premises object storage service such as MinIO, for proxied or air-gapped environments.

Its recommended to dedicate a unique storage bucket to each cluster.

For this demonstration purpose, we deployed Minio which makes use of aws plugin
1.  Deploy the Minio by applying the configuration file minio.yaml.
    ```bash
    kubectl apply -f minio.yaml
    ```
1. Connecto Minio console and create a S3 bucket to store the backups. 
1. Save the credentials to a local file(`minio.creds`) to pass to the `--secret-file` option of velero install, for example:
    ```bash
    [default]
    aws_access_key_id = root
    aws_secret_access_key = VMware1!
    ```

## Deploy Velero Server to Workload Clusters

To deploy the Velero Server to a workload cluster, you run the `velero install` command. This command creates a namespace called `velero` on the cluster, and places a deployment named `velero` in it.

To install Velero, run velero install with the following options:
- `--provider $PROVIDER`: For example, aws
- `--plugins`: projects.registry.vmware.com/tkg/velero/velero-plugin-for-aws:v1.7.1_vmware.1
- `--use-volume-snapshots false` to install velero with restic
- `--secret-file $file-name`  for passing the S3 credentials
- `--bucket $BUCKET`: The name of your S3 bucket
- `--backup-location-config region=$REGION`: The AWS region the bucket is in
 

Run the below command to Install Velero with Restic:
```bash
velero install --plugins projects.registry.vmware.com/tkg/velero/velero-plugin-for-aws:v1.7.1_vmware.1 \
--provider aws \
--bucket maria-db-02 \
--use-volume-snapshots false \
--use-node-agent \
--secret-file /root/minio/minio.creds \
--default-volumes-to-fs-backup \
--use-volume-snapshots=false \
--backup-location-config region=minio,s3ForcePathStyle="true",s3Url=http://172.30.40.47:9000
```

For an airgapped environments, ensure that required images are pulled from below locations and pushed to your Local Repo
```bash
docker pull projects.registry.vmware.com/tkg/velero-plugin-for-aws:v1.7.1_vmware.1
docker pull projects.registry.vmware.com/tkg/velero:v1.11.1_vmware.1
```

Run the below command to Install Velero with Restic in airgapped environments:
```bash
velero install --image <local-image-repo-fqdn>/vmware-tanzu/velero:v1.11.1_vmware.1 \
--plugins <local-image-repo-fqdn>/vmware-tanzu/velero-plugin-for-aws:v1.7.1_vmware.1 \
--provider aws \
--bucket maria-db-02 \
--use-volume-snapshots false \
--use-node-agent \
--secret-file /root/minio/minio.creds \
--default-volumes-to-fs-backup \
--use-volume-snapshots=false \
--backup-location-config region=minio,s3ForcePathStyle="true",s3Url=http://172.30.40.47:9000
```


## Conclusion:

This document covers the steps to install Velero with restic on Tanzu Kubernetes Grid clusters. Once you install Velero, you can use it to backup and restore your Kubernetes workloads.