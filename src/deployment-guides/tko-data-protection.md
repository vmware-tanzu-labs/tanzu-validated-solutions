## **Tanzu Kubernetes Grid Data Protection**

Kubernetes maintains a lot of states stored in the cluster itself, not just your application state. There are config maps, custom resource definitions, and secrets stored in the Kubernetes control plane, all of which are critical to your clusters’ operations. Protecting that data is as critical as it is with any other element of your IT infrastructure, so it should be covered by data protection and your disaster recovery plan.

As Kubernetes matures and enterprises deploy more modern, containerized applications, providing adequate data protection in a multi-cloud, distributed environment becomes a challenge that must be addressed.

Data Protection for Tanzu Kubernetes Grid workloads is provided by Tanzu Mission Control data protection feature which is built upon an open-source foundation using the [Velero project](https://velero.io/), the most popular open-source project for Kubernetes data protection. 

Using Tanzu Mission Control Data protection, you can backup and restore both stateless and stateful applications. The backups can be either stored on AWS S3 or any compatible S3 storage and thus provides customers the flexibility to bring their own storage.

Tanzu Mission Control’s UI, CLI, or API allows you to centrally create backups and restores of all of your clusters regardless of where they are located. Backup is configured at cluster level and can include:

- Individual namespace.
- A group of namespaces or all namespaces.
- All resources in a cluster.

You can selectively restore the backups you have created, by specifying the following:

- the entire backup
- selected namespaces from the backup
- specific resources from the backup identified by a given label

Another configurable feature is backup scheduling. You can specify how often you want to backup the Kubernetes data and the retention period of a backup. When the retention period expires, Tanzu Mission Control data protection will automatically remove old backups from storage, lowering your overall storage cost.

When it's time to destroy a cluster, Tanzu Mission Control can either clear up your backup storage or save it for future data recoveries to a new cluster. 

When you enable data protection for a cluster, Tanzu Mission Control installs Velero with restic (an open-source backup tool), configured to use the opt-in approach. With this approach, you must annotate the pods whose volumes you want to include in backups.

- If a given pod is annotated to opt in to the backup, then persistent volume snapshots are included in the backup.
- If a pod is not so annotated, then restic does not include the persistent volume snapshots in the backup. However, Velero still creates snapshots if the specified target location for the backup is in the same cloud provider account as the cluster.

Tanzu Mission Control maintains the life-cycle management of Velero so that you don’t have to worry about updating/upgrading it to a newer version manually. 

You can also install Velero standalone directly on your Tanzu Kubernetes clusters if for some reason Tanzu Mission Control data protection is not meeting all requirements.  Installing and using Velero standalone is advisable in the following scenario.

- In an internet-restricted/airgap environment, where the Tanzu Kubernetes clusters are not connected to the internet. 
- When a Kubernetes workload recovery is intended to be conducted in a cluster other than the source cluster. 

To learn more about Tanzu Mission Control Data Protection features, please refer to the [product documentation](https://docs.vmware.com/en/VMware-Tanzu-Mission-Control/services/tanzumc-concepts/GUID-C16557BC-EB1B-4414-8E63-28AD92E0CAE5.html)