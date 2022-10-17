# TKG-OCI Terraform module

## About

This module sets up an Oracle VCN and instance principals to use with VMware Tanzu Kubernetes Grid for Oracle Cloud Infrastructure.

## Use

Declare the following dependencies in your Terraform:

```hcl
terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
    }
  }
}

provider "oci" {
  region              = "region"
}


provider "oci" {
  alias               = "home"
  region              = var.home_region
  ignore_defined_tags = var.ignore_defined_tags
}
```

and then declare the module (this isn't tested yet, so maybe better just copying the directory and applying directly)

```hcl
module "vcn" {
  source                        = "./tkg-oci"
  region                        = "us-sanjose-1"
  compartment_id                = var.compartment_id
  create_internet_gateway       = true
  create_nat_gateway            = true
  create_service_gateway        = true
  vcn_name                      = "my-test"
  ...
}
```

and then set values. For the easiest topology, select

```tfvars
compartment_id = "ocid1.blah"
region         = "us-sanjose-1"
home_region    = "us-phoenix-1"
ignore_defined_tags = [
  "Owner.Creator",
  "Oracle-Tags.CreatedBy",
  "Oracle-Tags.CreatedOn",
]

public_control_plane_endpoint = true
create_public_services_subnet = true
```


### What you get

You should end up with the following:

* A VCN with public subnets and a public control plane endpoint
* A NAT gateway to provider outbound connectivity for compute
* A service gateway for direct access to Oracle APIs
* A load balancer ready to use for an appropriate cluster
* Network security groups for use with an appropriate clusterclass
* A new TKG defined tag
* Compartment specific policies to be used with a dynamic group

Optionally:
* Dynamic groups for TKG (requires tenant admin privileges)

## TODO

* To use instance principals, we need to create dynamic groups (create_dynamic_groups=true), but this requires tenant admin permissions. Need workaround for now. You may need to temporarily pass credentials into the CPI directly.

* Better variable validation.

* NSG rules need to be verified. Need to check destination ports in particular.

* Mode where just the LB and NSGs get created for a new cluster within an already
  prepared VCN.

* Optional bastion?

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name                                                             | Version |
| ---------------------------------------------------------------- | ------- |
| <a name="provider_oci"></a> [oci](#provider\_oci)                | 4.94.0  |
| <a name="provider_oci.home"></a> [oci.home](#provider\_oci.home) | 4.94.0  |

## Modules

| Name                                          | Source | Version |
| --------------------------------------------- | ------ | ------- |
| <a name="module_vcn"></a> [vcn](#module\_vcn) | ./vcn  | n/a     |

## Resources

| Name                                                                                                                                                                                                          | Type     |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- |
| [oci_core_network_security_group.control_plane](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group)                                                         | resource |
| [oci_core_network_security_group.control_plane_endpoint](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group)                                                | resource |
| [oci_core_network_security_group.workers](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group)                                                               | resource |
| [oci_core_network_security_group_security_rule.control_plane_to_control_plane_antrea](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group_security_rule)     | resource |
| [oci_core_network_security_group_security_rule.control_plane_to_control_plane_geneve](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group_security_rule)     | resource |
| [oci_core_network_security_group_security_rule.control_plane_to_control_plane_kubelet](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group_security_rule)    | resource |
| [oci_core_network_security_group_security_rule.control_plane_to_internet](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group_security_rule)                 | resource |
| [oci_core_network_security_group_security_rule.control_plane_to_load_balancer_kubernetes](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group_security_rule) | resource |
| [oci_core_network_security_group_security_rule.control_plane_to_workers_antrea](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group_security_rule)           | resource |
| [oci_core_network_security_group_security_rule.control_plane_to_workers_kubelet](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group_security_rule)          | resource |
| [oci_core_network_security_group_security_rule.etcd_client](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group_security_rule)                               | resource |
| [oci_core_network_security_group_security_rule.etcd_peer](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group_security_rule)                                 | resource |
| [oci_core_network_security_group_security_rule.everywhere_to_apiserver](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group_security_rule)                   | resource |
| [oci_core_network_security_group_security_rule.load_balancer_to_apiserver](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group_security_rule)                | resource |
| [oci_core_network_security_group_security_rule.load_balancer_to_control_plane_kubernetes](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group_security_rule) | resource |
| [oci_core_network_security_group_security_rule.node_port_services_tcp](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group_security_rule)                    | resource |
| [oci_core_network_security_group_security_rule.worker_to_worker_geneve](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group_security_rule)                   | resource |
| [oci_core_network_security_group_security_rule.workers_to_apiserver](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group_security_rule)                      | resource |
| [oci_core_network_security_group_security_rule.workers_to_control_plane_antrea](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group_security_rule)           | resource |
| [oci_core_network_security_group_security_rule.workers_to_control_plane_geneve](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group_security_rule)           | resource |
| [oci_core_network_security_group_security_rule.workers_to_internet](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group_security_rule)                       | resource |
| [oci_core_network_security_group_security_rule.workers_to_load_balancer_kubernetes](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group_security_rule)       | resource |
| [oci_identity_dynamic_group.control_plane](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/identity_dynamic_group)                                                                   | resource |
| [oci_identity_dynamic_group.workers](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/identity_dynamic_group)                                                                         | resource |
| [oci_identity_policy.tkg](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/identity_policy)                                                                                           | resource |
| [oci_identity_tag.instance_role](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/identity_tag)                                                                                       | resource |
| [oci_identity_tag_namespace.tkg_namespace](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/identity_tag_namespace)                                                                   | resource |
| [oci_network_load_balancer_network_load_balancer.tkg](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/network_load_balancer_network_load_balancer)                                   | resource |

## Inputs

| Name                                                                                                                                                 | Description                                                                                                                                                                | Type                | Default                                                                                            | Required |
| ---------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------- | -------------------------------------------------------------------------------------------------- | :------: |
| <a name="input_additional_control_plane_permissions"></a> [additional\_control\_plane\_permissions](#input\_additional\_control\_plane\_permissions) | Additional statements to add to the control plane policy                                                                                                                   | `list(string)`      | `[]`                                                                                               |    no    |
| <a name="input_additional_subnets"></a> [additional\_subnets](#input\_additional\_subnets)                                                           | Additional subnets to create                                                                                                                                               | `any`               | `{}`                                                                                               |    no    |
| <a name="input_additional_worker_permissions"></a> [additional\_worker\_permissions](#input\_additional\_worker\_permissions)                        | Additional statements to add to the control plane policy                                                                                                                   | `list(string)`      | `[]`                                                                                               |    no    |
| <a name="input_attached_drg_id"></a> [attached\_drg\_id](#input\_attached\_drg\_id)                                                                  | the ID of DRG attached to the VCN                                                                                                                                          | `string`            | `null`                                                                                             |    no    |
| <a name="input_compartment_id"></a> [compartment\_id](#input\_compartment\_id)                                                                       | OCID for the compartment to use                                                                                                                                            | `string`            | n/a                                                                                                |   yes    |
| <a name="input_control_plane_endpoint_subnet_id"></a> [control\_plane\_endpoint\_subnet\_id](#input\_control\_plane\_endpoint\_subnet\_id)           | Subnet ID for the control plane endpoint when not creating a VCN                                                                                                           | `string`            | `""`                                                                                               |    no    |
| <a name="input_controlplane_ingress_cidr"></a> [controlplane\_ingress\_cidr](#input\_controlplane\_ingress\_cidr)                                    | CIDR block for the control plane ingress                                                                                                                                   | `string`            | `"0.0.0.0/0"`                                                                                      |    no    |
| <a name="input_create_dynamic_groups"></a> [create\_dynamic\_groups](#input\_create\_dynamic\_groups)                                                | Create dynamic groups used to match instances                                                                                                                              | `bool`              | `false`                                                                                            |    no    |
| <a name="input_create_internet_gateway"></a> [create\_internet\_gateway](#input\_create\_internet\_gateway)                                          | Allow any connectivity to the internet                                                                                                                                     | `bool`              | `true`                                                                                             |    no    |
| <a name="input_create_nat_gateway"></a> [create\_nat\_gateway](#input\_create\_nat\_gateway)                                                         | Allow TKG cluster to have internet access                                                                                                                                  | `bool`              | `true`                                                                                             |    no    |
| <a name="input_create_policies"></a> [create\_policies](#input\_create\_policies)                                                                    | Create policies for use with instance principals                                                                                                                           | `bool`              | `true`                                                                                             |    no    |
| <a name="input_create_public_services_subnet"></a> [create\_public\_services\_subnet](#input\_create\_public\_services\_subnet)                      | Create public facing subnet for Kubernetes service load balancers                                                                                                          | `bool`              | `false`                                                                                            |    no    |
| <a name="input_create_service_gateway"></a> [create\_service\_gateway](#input\_create\_service\_gateway)                                             | Create a service gateway for the VCN                                                                                                                                       | `bool`              | `true`                                                                                             |    no    |
| <a name="input_create_tags"></a> [create\_tags](#input\_create\_tags)                                                                                | Create VMware Tanzu Kubernetes Grid tags                                                                                                                                   | `bool`              | `true`                                                                                             |    no    |
| <a name="input_create_vcn"></a> [create\_vcn](#input\_create\_vcn)                                                                                   | Create a new VCN                                                                                                                                                           | `bool`              | `true`                                                                                             |    no    |
| <a name="input_defined_tags"></a> [defined\_tags](#input\_defined\_tags)                                                                             | Defined tags to apply to the resources                                                                                                                                     | `map(string)`       | `{}`                                                                                               |    no    |
| <a name="input_enable_tanzu_freeform_tags"></a> [enable\_tanzu\_freeform\_tags](#input\_enable\_tanzu\_freeform\_tags)                               | Enable tanzu freeform tags                                                                                                                                                 | `bool`              | `true`                                                                                             |    no    |
| <a name="input_existing_vcn_id"></a> [existing\_vcn\_id](#input\_existing\_vcn\_id)                                                                  | OCID of an existing VCN to use                                                                                                                                             | `string`            | `""`                                                                                               |    no    |
| <a name="input_freeform_tags"></a> [freeform\_tags](#input\_freeform\_tags)                                                                          | Defined tags to apply to the resources                                                                                                                                     | `map(string)`       | `{}`                                                                                               |    no    |
| <a name="input_home_region"></a> [home\_region](#input\_home\_region)                                                                                | Region to use to create global resources                                                                                                                                   | `string`            | n/a                                                                                                |   yes    |
| <a name="input_ignore_defined_tags"></a> [ignore\_defined\_tags](#input\_ignore\_defined\_tags)                                                      | Ignore defined tags                                                                                                                                                        | `list(string)`      | <pre>[<br>  "Oracle-Tags.CreatedBy",<br>  "Oracle-Tags.CreatedOn",<br>  "Owner.Creator"<br>]</pre> |    no    |
| <a name="input_internet_gateway_display_name"></a> [internet\_gateway\_display\_name](#input\_internet\_gateway\_display\_name)                      | (Updatable) Name of Internet Gateway. Does not have to be unique.                                                                                                          | `string`            | `"internet-gateway"`                                                                               |    no    |
| <a name="input_internet_gateway_route_rules"></a> [internet\_gateway\_route\_rules](#input\_internet\_gateway\_route\_rules)                         | (Updatable) List of routing rules to add to Internet Gateway Route Table                                                                                                   | `list(map(string))` | `null`                                                                                             |    no    |
| <a name="input_is_management_cluster"></a> [is\_management\_cluster](#input\_is\_management\_cluster)                                                | Whether this is a management cluster                                                                                                                                       | `bool`              | `true`                                                                                             |    no    |
| <a name="input_label_prefix"></a> [label\_prefix](#input\_label\_prefix)                                                                             | Label prefix for all resources                                                                                                                                             | `string`            | `"tkg.cloud.vmware.com"`                                                                           |    no    |
| <a name="input_local_peering_gateways"></a> [local\_peering\_gateways](#input\_local\_peering\_gateways)                                             | Map of Local Peering Gateways to attach to the VCN.                                                                                                                        | `map(any)`          | `null`                                                                                             |    no    |
| <a name="input_lockdown_default_seclist"></a> [lockdown\_default\_seclist](#input\_lockdown\_default\_seclist)                                       | whether to remove all default security rules from the VCN Default Security List                                                                                            | `bool`              | `true`                                                                                             |    no    |
| <a name="input_nat_gateway_display_name"></a> [nat\_gateway\_display\_name](#input\_nat\_gateway\_display\_name)                                     | (Updatable) Name of NAT Gateway. Does not have to be unique.                                                                                                               | `string`            | `"nat-gateway"`                                                                                    |    no    |
| <a name="input_nat_gateway_public_ip_id"></a> [nat\_gateway\_public\_ip\_id](#input\_nat\_gateway\_public\_ip\_id)                                   | OCID of reserved IP address for NAT gateway. The reserved public IP address needs to be manually created.                                                                  | `string`            | `"none"`                                                                                           |    no    |
| <a name="input_nat_gateway_route_rules"></a> [nat\_gateway\_route\_rules](#input\_nat\_gateway\_route\_rules)                                        | (Updatable) list of routing rules to add to NAT Gateway Route Table                                                                                                        | `list(map(string))` | `null`                                                                                             |    no    |
| <a name="input_public_control_plane_endpoint"></a> [public\_control\_plane\_endpoint](#input\_public\_control\_plane\_endpoint)                      | Expose Kubernetes control plane endpoint on public internet                                                                                                                | `bool`              | `false`                                                                                            |    no    |
| <a name="input_region"></a> [region](#input\_region)                                                                                                 | Region to use to create the resources                                                                                                                                      | `string`            | n/a                                                                                                |   yes    |
| <a name="input_service_gateway_display_name"></a> [service\_gateway\_display\_name](#input\_service\_gateway\_display\_name)                         | (Updatable) Name of Service Gateway. Does not have to be unique.                                                                                                           | `string`            | `"service-gateway"`                                                                                |    no    |
| <a name="input_tenancy_id"></a> [tenancy\_id](#input\_tenancy\_id)                                                                                   | Tenancy ID                                                                                                                                                                 | `string`            | `""`                                                                                               |    no    |
| <a name="input_vcn_cidr"></a> [vcn\_cidr](#input\_vcn\_cidr)                                                                                         | CIDR block for the VCN                                                                                                                                                     | `string`            | `"10.0.0.0/20"`                                                                                    |    no    |
| <a name="input_vcn_dns_label"></a> [vcn\_dns\_label](#input\_vcn\_dns\_label)                                                                        | A DNS label for the VCN, used in conjunction with the VNIC's hostname and subnet's DNS label to form a fully qualified domain name (FQDN) for each VNIC within this subnet | `string`            | `"vcnmodule"`                                                                                      |    no    |
| <a name="input_vcn_name"></a> [vcn\_name](#input\_vcn\_name)                                                                                         | Name of the VCN that will be created                                                                                                                                       | `string`            | `"vcn"`                                                                                            |    no    |

## Outputs

| Name                                                                                           | Description                       |
| ---------------------------------------------------------------------------------------------- | --------------------------------- |
| <a name="output_load_balancer_id"></a> [load\_balancer\_id](#output\_load\_balancer\_id)       | ID of the load balancer           |
| <a name="output_security_group_ids"></a> [security\_group\_ids](#output\_security\_group\_ids) | mapping of security groups to use |
| <a name="output_subnet_ids"></a> [subnet\_ids](#output\_subnet\_ids)                           | mapping of subnets to use         |
| <a name="output_vcn_id"></a> [vcn\_id](#output\_vcn\_id)                                       | ID of vcn that is created         |
<!-- END_TF_DOCS -->
