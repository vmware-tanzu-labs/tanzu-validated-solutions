output "bindvms" {
  value = { for n in range(var.bindvms) : module.bindvm[n].vm.name => module.bindvm[n].vnic.private_ip_address }
}