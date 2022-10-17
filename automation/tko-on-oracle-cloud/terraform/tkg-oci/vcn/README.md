<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_subnet_addrs"></a> [subnet\_addrs](#module\_subnet\_addrs) | hashicorp/subnets/cidr | n/a |
| <a name="module_vcn"></a> [vcn](#module\_vcn) | github.com/oracle-terraform-modules/terraform-oci-vcn | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_subnets"></a> [additional\_subnets](#input\_additional\_subnets) | Additional subnets to create | `any` | `{}` | no |
| <a name="input_attached_drg_id"></a> [attached\_drg\_id](#input\_attached\_drg\_id) | the ID of DRG attached to the VCN | `string` | `null` | no |
| <a name="input_compartment_id"></a> [compartment\_id](#input\_compartment\_id) | OCID for the compartment to use | `string` | n/a | yes |
| <a name="input_create_bastion_vm"></a> [create\_bastion\_vm](#input\_create\_bastion\_vm) | Create a bastion VM in the public services subnet | `bool` | `false` | no |
| <a name="input_create_instance_principals"></a> [create\_instance\_principals](#input\_create\_instance\_principals) | Create instance principals for the Kubernetes cluster | `bool` | `true` | no |
| <a name="input_create_internet_gateway"></a> [create\_internet\_gateway](#input\_create\_internet\_gateway) | Allow any connectivity to the internet | `bool` | `true` | no |
| <a name="input_create_nat_gateway"></a> [create\_nat\_gateway](#input\_create\_nat\_gateway) | Allow TKG cluster to have internet access | `bool` | `true` | no |
| <a name="input_create_public_services_subnet"></a> [create\_public\_services\_subnet](#input\_create\_public\_services\_subnet) | Create public facing subnet for Kubernetes service load balancers | `bool` | `false` | no |
| <a name="input_create_service_gateway"></a> [create\_service\_gateway](#input\_create\_service\_gateway) | Create a service gateway for the VCN | `bool` | `true` | no |
| <a name="input_defined_tags"></a> [defined\_tags](#input\_defined\_tags) | Defined tags to apply to the resources | `map(string)` | `{}` | no |
| <a name="input_enable_tanzu_freeform_tags"></a> [enable\_tanzu\_freeform\_tags](#input\_enable\_tanzu\_freeform\_tags) | Enable tanzu freeform tags | `bool` | `true` | no |
| <a name="input_freeform_tags"></a> [freeform\_tags](#input\_freeform\_tags) | Defined tags to apply to the resources | `map(string)` | `{}` | no |
| <a name="input_ignore_defined_tags"></a> [ignore\_defined\_tags](#input\_ignore\_defined\_tags) | Ignore defined tags | `list(string)` | <pre>[<br>  "Oracle-Tags.CreatedBy",<br>  "Oracle-Tags.CreatedOn",<br>  "Owner.Creator"<br>]</pre> | no |
| <a name="input_internet_gateway_display_name"></a> [internet\_gateway\_display\_name](#input\_internet\_gateway\_display\_name) | (Updatable) Name of Internet Gateway. Does not have to be unique. | `string` | `"internet-gateway"` | no |
| <a name="input_internet_gateway_route_rules"></a> [internet\_gateway\_route\_rules](#input\_internet\_gateway\_route\_rules) | (Updatable) List of routing rules to add to Internet Gateway Route Table | `list(map(string))` | `null` | no |
| <a name="input_label_prefix"></a> [label\_prefix](#input\_label\_prefix) | Label prefix for all resources | `string` | `"tkg.cloud.vmware.com"` | no |
| <a name="input_local_peering_gateways"></a> [local\_peering\_gateways](#input\_local\_peering\_gateways) | Map of Local Peering Gateways to attach to the VCN. | `map(any)` | `null` | no |
| <a name="input_lockdown_default_seclist"></a> [lockdown\_default\_seclist](#input\_lockdown\_default\_seclist) | whether to remove all default security rules from the VCN Default Security List | `bool` | `true` | no |
| <a name="input_nat_gateway_display_name"></a> [nat\_gateway\_display\_name](#input\_nat\_gateway\_display\_name) | (Updatable) Name of NAT Gateway. Does not have to be unique. | `string` | `"nat-gateway"` | no |
| <a name="input_nat_gateway_public_ip_id"></a> [nat\_gateway\_public\_ip\_id](#input\_nat\_gateway\_public\_ip\_id) | OCID of reserved IP address for NAT gateway. The reserved public IP address needs to be manually created. | `string` | `"none"` | no |
| <a name="input_nat_gateway_route_rules"></a> [nat\_gateway\_route\_rules](#input\_nat\_gateway\_route\_rules) | (Updatable) list of routing rules to add to NAT Gateway Route Table | `list(map(string))` | `null` | no |
| <a name="input_public_control_plane_endpoint"></a> [public\_control\_plane\_endpoint](#input\_public\_control\_plane\_endpoint) | Expose Kubernetes control plane endpoint on public internet | `bool` | `false` | no |
| <a name="input_region"></a> [region](#input\_region) | Region to use to create the resources | `string` | n/a | yes |
| <a name="input_service_gateway_display_name"></a> [service\_gateway\_display\_name](#input\_service\_gateway\_display\_name) | (Updatable) Name of Service Gateway. Does not have to be unique. | `string` | `"service-gateway"` | no |
| <a name="input_vcn_cidr"></a> [vcn\_cidr](#input\_vcn\_cidr) | CIDR block for the VCN | `string` | `"10.0.0.0/20"` | no |
| <a name="input_vcn_dns_label"></a> [vcn\_dns\_label](#input\_vcn\_dns\_label) | A DNS label for the VCN, used in conjunction with the VNIC's hostname and subnet's DNS label to form a fully qualified domain name (FQDN) for each VNIC within this subnet | `string` | `"vcnmodule"` | no |
| <a name="input_vcn_name"></a> [vcn\_name](#input\_vcn\_name) | Name of the VCN that will be created | `string` | `"vcn"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_subnet_ids"></a> [subnet\_ids](#output\_subnet\_ids) | n/a |
| <a name="output_vcn_id"></a> [vcn\_id](#output\_vcn\_id) | id of vcn that is created |
<!-- END_TF_DOCS -->