# Tanzu Kubernetes Grid Data Protection

Kubernetes maintains many states stored in the cluster itself in addition to your application state. Config maps, custom resource definitions, and secrets are all stored in the Kubernetes control plane. All of these are critical to your clusters’ operations. Protecting this data is just as critical as protecting any other element of your IT infrastructure, so it should be covered by data protection and your disaster recovery plan.

Data Protection for Tanzu Kubernetes Grid workloads is provided by the Tanzu Mission Control data protection feature which is built upon an open-source foundation using the [Velero project](https://velero.io/), the most popular open-source project for Kubernetes data protection.

Using Tanzu Mission Control Data protection, you can back up and restore both stateless and stateful applications. Backups can be stored on AWS S3 or on any compatible S3 storage, giving you the flexibility to bring your own storage.

Using the Tanzu Mission Control UI, CLI, or API, you can create backups and restores for all of your clusters, regardless of where they are located, from a central management platform. Backups are configured at the cluster level and can include:

- an individual namespace
- a group of namespaces or all namespaces
- all resources in a cluster
- specific resources in a cluster identified by a given label

You can selectively restore the backups you have created by specifying any of the following:

- the entire backup
- selected namespaces from the backup
- specific resources from the backup identified by a given label

You can also configure backup scheduling. You can specify how often to back up the Kubernetes data and how long to retain your backups. When the retention period for a backup expires, Tanzu Mission Control data protection automatically removes the expired backup from storage, lowering your overall storage usage.

When it's time to destroy a cluster, Tanzu Mission Control gives you the choice of deleting your backup storage for that cluster or saving it for future data recoveries to a new cluster.

When you enable data protection for a cluster, Tanzu Mission Control installs Velero with restic (an open-source backup tool), configured to use the opt-in approach. With this approach, you must annotate the pods whose volumes you want to include in backups. 

- If a given pod is annotated to be backed up, persistent volume snapshots are included in the backup.
- If a pod is not annotated to be backed up, restic does not include the persistent volume snapshots in the backup. However, Velero still creates snapshots if the specified target location for the backup is in the same cloud provider account as the cluster.

Tanzu Mission Control manages the entire Valero lifecycle automatically, eliminating the need for you to manually update or upgrade it when newer software releases are available.

If Tanzu Mission Control data protection does not handle all of your backup requirements, there is also a standalone version of Velero that you can install on your Tanzu Kubernetes clusters. Using the Velero standalone is advisable in the following scenarios:

- In an internet-restricted or air-gapped environment, where the Tanzu Kubernetes clusters are not connected to the internet.
- When a Kubernetes workload recovery is intended to be conducted in a cluster other than the source cluster.

To learn more about Tanzu Mission Control data protection features, see the [Tanzu Mission Control product documentation](https://docs.vmware.com/en/VMware-Tanzu-Mission-Control/services/tanzumc-concepts/GUID-C16557BC-EB1B-4414-8E63-28AD92E0CAE5.html)
