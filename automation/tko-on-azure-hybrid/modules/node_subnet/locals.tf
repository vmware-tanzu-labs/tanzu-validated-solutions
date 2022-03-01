locals {
  subnets = { for key, value in var.subnet_settings : key => value.network }

  /*
  Create a list of products (all subnet names to all CIDR ranges) from the passed in subnets list, so we can
  create VNetLocal routes for every subnet.

  This data structure will take: local.subnets = {"net1" = "10.0.1.0/24", "net2" = "10.0.2.0/24"}
    
  and create:
  {
  "net1-10.0.1.0/24" = {"cidr" = "10.0.1.0/24", "name" = "net1"},
  "net2-10.0.2.0/24" = {"cidr" = "10.0.2.0/24", "name" = "net2"}
  }
  
  This can then be used to create a route for each vnet local subnet in each route table.
  */

  vnetlocal_list = { for x in setproduct(keys(local.subnets), values(local.subnets)) : "${x[0]}-${x[1]}" => {
    name = x[0],
    cidr = x[1] }
  }
}