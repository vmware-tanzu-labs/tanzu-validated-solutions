output "bindvm_name" {
  value = module.bindvm[*].vm.name
}

output "bindvm_ip" {
  value = module.bindvm[*].vnic.private_ip_address
}