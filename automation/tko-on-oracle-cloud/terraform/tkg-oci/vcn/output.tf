output "vcn_id" {
  description = "id of vcn that is created"
  value       = module.vcn.vcn_id
}

output "subnet_ids" {
  value = module.vcn.subnet_id
}
