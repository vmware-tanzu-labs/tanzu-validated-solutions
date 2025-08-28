# Management and Monitoring

This topic introduces the primary tools for managing and monitoring VMware Tanzu GemFire clusters: the gfsh command-line interface and the browser-based VMware Tanzu GemFire Management Console. Together, they enable administrators to efficiently configure, observe, and maintain cluster operations.

## gfsh Command-Line Tool

The Tanzu GemFire Shell (gfsh) is the recommended command-line interface for configuring, managing, and monitoring the Tanzu GemFire cluster. It allows you to:

* Start and stop locators and cache servers
* Create, modify, or destroy regions
* Deploy and manage application JARs
* Execute user-defined functions
* Manage disk stores and perform data import/export
* Monitor members and system metrics
* Launch monitoring tools and shut down the cluster
* Save and manage shared cluster configurations

Run gfsh in its own interactive shell or invoke commands directly from the operating system command line. Use scripting to automate tasks and connect to remote clusters over HTTP. With shared configuration support, use gfsh to define reusable settings across the cluster. Locators store and synchronize these settings in files such as `cluster.xml` and `cluster.properties`.

For more information about gfsh, see:

* [Running gfsh Commands on the OS Command Line](https://techdocs.broadcom.com/us/en/vmware-tanzu/data-solutions/tanzu-gemfire/10-1/gf/tools_modules-gfsh-os_command_line_execution.html)
* [Using gfsh to Manage a Remote Cluster Over HTTP or HTTPS](https://techdocs.broadcom.com/us/en/vmware-tanzu/data-solutions/tanzu-gemfire/10-1/gf/configuring-cluster_config-gfsh_remote.html)
* [Creating and Running gfsh Command Scripts](https://techdocs.broadcom.com/us/en/vmware-tanzu/data-solutions/tanzu-gemfire/10-1/gf/tools_modules-gfsh-command_scripting.html#concept_9B2F7550F16C4717831AD40A56922259)

## Tanzu GemFire Management Console

The Tanzu GemFire Management Console is a browser-based interface that simplifies day-to-day operations and provides visual insights into your Tanzu GemFire clusters. Use Tanzu GemFire Management Console to:

* Monitor multiple clusters in a single UI
* View and manage regions and disk stores
* Deploy or remove JARs
* Search and analyze cluster logs
* Execute commands with the built-in web-based gfsh
* Manage WAN components like Gateway Senders
* Visualize cluster topology in real time

The console is ideal for both routine operations and troubleshooting, providing an intuitive experience for administrators.

For more information, see the [VMware Tanzu GemFire Management Console documentation](https://techdocs.broadcom.com/us/en/vmware-tanzu/data-solutions/tanzu-gemfire-management-console/1-3/gf-mc/index.html).