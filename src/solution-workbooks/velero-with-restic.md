# Installing Velero in Tanzu Kubernetes Cluster

 [Velero](https://velero.io/docs), is an open source community standard tool to back up and restore Tanzu Kubernetes Grid (informally known as TKG) standalone management cluster infrastructure and workloads.

 Velero Filesystem backups can be crash-consistent only if configured correctly. Crash consistency ensures that the backed-up data reflects a consistent state of the application and filesystem at a specific point in time, even in the event of a system crash or failure.

Starting from Velero v1.10, except for using restic to do file-system level backup and restore, kopia is been integrated. Kopia provides snapshot-like functionality, allowing you to capture the state of your application at a specific point in time. These snapshots can be used for both backup and restore operations, providing a consistent view of your application state.

To enhance crash consistency of the applications while in Velero filesystem backups, we highly recommend considering Application Quiescence. This can be achieved either by manually pausing the application or by utilizing Pre and Post-Backup Hooks.

- **Manual Approach**:

    - With a manual approach, achieving application quiescence typically involves stopping or pausing the application's processes or workloads.
    - This can be done by manually halting incoming traffic, shutting down pods or containers, or pausing application-specific processes to ensure data consistency during the backup operations.
    - It often requires scripting or manual intervention to coordinate the quiescence process with the backup operation.

- **Pre and Post-Backup Hooks**:

    Velero provides hooks to automate the application quiescence process before initiating a backup. These hooks allow you define pre-backup and post-backup actions to be performed on the application workloads. Before starting a backup, Velero can execute pre-backup hooks to quiesce the application by gracefully stopping processes, flushing caches, or any other necessary actions to ensure data consistency. After the backup is complete, post-backup hooks can be executed to resume normal application operations.

Using hooks for application quiescence offers the following advantages:

- **Automation**: Hooks automate the quiescence process, reducing the need for manual intervention and scripting.
- **Consistency**: By defining pre- and post-backup actions, you ensure consistency in the backup process across different environments.
- **Integration**: Hooks integrate seamlessly with Velero's backup workflow, making it easier to manage backups and ensure data integrity.

In summary, while a manual approach to application quiescence requires more effort and coordination, using hooks provided by Velero can automate and streamline the process. This also improves efficiency and consistency in Kubernetes backup operations.


## Install Velero on Tanzu Kubernetes Grid Cluster


 A TKG subscription includes support for VMware’s tested, compatible distribution of Velero available from the Tanzu Kubernetes Grid downloads page.

To back up and restore TKG clusters, you must ensure the following parameters:

- The Velero CLI running on your local client machine.
- A storage provider with locations to save the backups.
- A Velero server running on the clusters that you are backing up.



### Install the Velero CLI

To install the Velero CLI on your client machine, perform the following steps:

1. Go to the [Tanzu Kubernetes Grid downloads page](https://customerconnect.vmware.com/en/web/vmware/downloads/info/slug/infrastructure_operations_management/vmware_tanzu_kubernetes_grid/2_x), and log in with your VMware Customer Connect credentials.
1. Under **Product Downloads**, click **Go to Downloads**.
3. Select the respective Tanzu Kubernetes Grid version. 
</br>Scroll down to the Velero entries and download the `Velero CLI.gz` file on your client machine OS. 
1. Extract the binary.

    ```bash
    gunzip velero-linux-v1.11.1+vmware.1.gz
    ```
1. Rename the CLI binary for your platform to `velero`. You must ensure that this binary is executable, and add it to your PATH. <br>
For Linux:

    ```bash
    mv velero /usr/local/bin/velero
    chmod +x /usr/local/bin/velero
    ```

### Set Up a Storage Provider
Velero supports one of the following [storage providers](https://velero.io/docs/main/supported-providers):

- An online cloud storage provider.
- An on-premises object storage service such as `MinIO`, for proxied or air-gapped environments.

It's recommended to dedicate a unique storage bucket to each cluster. 

For this demonstration purpose, we deployed Minio that uses an AWS plug-in.
1.  Deploy the Minio by applying the configuration file [minio.yaml](./resources/velero-with-restic/minio.yml).

    ```bash
    kubectl apply -f minio.yaml
    ```
1. Connect to the Minio console, and create a S3 bucket to store the backups. 
1. Save the credentials to a local file(`minio.creds`) to pass to the `--secret-file` option of velero install. </br>For example:

    ```bash
    [default]
    aws_access_key_id = root
    aws_secret_access_key = VMware1!
    ```

### Deploy Velero Server to Workload Clusters

To deploy the Velero Server to a workload cluster, you run the `velero install` command. This command creates a namespace called `velero` on the cluster, and places a deployment named `velero` in it.

1. To install Velero, run the `velero install` command with the following options:

    - `--provider $PROVIDER`: For example, aws
    - `--plugins`: projects.registry.vmware.com/tkg/velero/velero-plugin-for-aws:v1.7.1_vmware.1
    - `--secret-file $file-name`  for passing the S3 credentials
    - `--bucket $BUCKET`: The name of your S3 bucket
    - `--backup-location-config region=$REGION`: The AWS region the bucket is in
 

1. To Install Velero, run the following command:

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

3. For an airgapped environments, ensure that required images are pulled from below locations and pushed to your local repository:

    ```bash
    docker pull projects.registry.vmware.com/tkg/velero-plugin-for-aws:v1.7.1_vmware.1
    docker pull projects.registry.vmware.com/tkg/velero:v1.11.1_vmware.1
    ```

4. To Install Velero in air-gapped environments, run the following command:


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

This document walks you through the procedure to install Velero on Tanzu Kubernetes Grid clusters. Once you install Velero, you can use it to backup and restore your Kubernetes workloads.

By configuring Velero filesystem backup appropriately and following the best practices, you can achieve crash-consistent filesystem backups that accurately reflect the state of your applications and data, even in the event of an unexpected failure or crash. It's essential to thoroughly test your backup and recovery processes to validate their crash consistency and effectiveness in restoring data.
