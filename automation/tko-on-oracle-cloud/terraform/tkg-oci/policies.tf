locals {

  control_plane_group_id = var.create_dynamic_groups ? oci_identity_dynamic_group.control_plane[0].id : ""
  workers_group_id       = var.create_dynamic_groups ? oci_identity_dynamic_group.workers[0].id : ""

  tanzu_control_plane_policies = [
    # "Allow dynamic-group id ${local.control_plane_group_id} to inspect instance-images in compartment id ${var.compartment_id}",
    # "Allow dynamic-group id ${local.control_plane_group_id} to manage instances in compartment id ${var.compartment_id}",
    # "Allow dynamic-group id ${local.control_plane_group_id} to manage volume-family in compartment id ${var.compartment_id}",
    # "Allow dynamic-group id ${local.control_plane_group_id} to use load-balancers in compartment id ${var.compartment_id}",
    "Allow dynamic-group id ${local.control_plane_group_id} to inspect instance-images",
    "Allow dynamic-group id ${local.control_plane_group_id} to manage instances",
    "Allow dynamic-group id ${local.control_plane_group_id} to manage volume-family",
    "Allow dynamic-group id ${local.control_plane_group_id} to use load-balancers",
  ]
  tanzu_management_control_plane_policies = [
    # "Allow dynamic-group id ${local.control_plane_group_id} to inspect instance-images in compartment id ${var.compartment_id}",
    # "Allow dynamic-group id ${local.control_plane_group_id} to manage instances in compartment id ${var.compartment_id}",
    # "Allow dynamic-group id ${local.control_plane_group_id} to manage virtual-network-family in compartment id ${var.compartment_id}",

    "Allow dynamic-group id ${local.control_plane_group_id} to inspect instance-images",
    "Allow dynamic-group id ${local.control_plane_group_id} to manage instances",
    "Allow dynamic-group id ${local.control_plane_group_id} to manage virtual-network-family",

  ]

  control_plane_policies                     = var.is_management_cluster ? concat(local.tanzu_control_plane_policies, local.tanzu_management_control_plane_policies) : local.tanzu_control_plane_policies
  additional_control_plane_policy_statements = formatlist("Allow dynamic-group id ${local.control_plane_group_id} to %s in compartment id ${var.compartment_id}", var.additional_control_plane_permissions)
  additional_worker_policy_statements        = formatlist("Allow dynamic-group id ${local.workers_group_id} to %s in compartment id ${var.compartment_id}", var.additional_worker_permissions)
  policies                                   = concat(local.control_plane_policies, local.additional_control_plane_policy_statements, local.additional_worker_policy_statements)
}

resource "oci_identity_policy" "tkg" {
  count          = var.create_dynamic_groups ? 1 : 0
  compartment_id = var.compartment_id
  description    = "VMware Tanzu Kubernetes Grid policy for compartment id ${var.compartment_id}"
  name           = "${local.compartment_hash}.tkg.vmware.cloud.vmware.com"
  statements     = local.policies

  #Optional
  defined_tags  = var.defined_tags
  freeform_tags = local.freeform_tags
  version_date  = "2022/09/26"
}

resource "oci_identity_dynamic_group" "control_plane" {
  count          = var.create_dynamic_groups ? 1 : 0
  compartment_id = var.tenancy_id
  description    = "Dynamic group for TKG control plane nodes"
  matching_rule  = "tag.tkg-cloud-vmware-com.instance-role.value='control-plane'"
  # matching_rule  = "All {instance.compartment.id = '${var.compartment_id}', tag.tkg-cloud-vmware-com.instance-role.value='control-plane'}"
  name = "control-plane.${local.compartment_hash}.tkg.cloud.vmware.com"

  #Optional
  defined_tags  = var.defined_tags
  freeform_tags = local.freeform_tags
}

resource "oci_identity_dynamic_group" "workers" {
  count          = var.create_dynamic_groups ? 1 : 0
  compartment_id = var.tenancy_id
  description    = "Dynamic group for TKG worker nodes"
  # matching_rule  = "All {instance.compartment.id = '${var.compartment_id}', tag.tkg-cloud-vmware-com.instance-role.value='worker'}"
  matching_rule = "tag.tkg-cloud-vmware-com.instance-role.value='worker'"
  name          = "workers.${local.compartment_hash}.tkg.cloud.vmware.com"

  #Optional
  defined_tags  = var.defined_tags
  freeform_tags = local.freeform_tags
}
