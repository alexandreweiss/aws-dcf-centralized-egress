resource "aviatrix_vpc" "spoke" {
  cloud_type           = 1
  account_name         = var.aws_account_name
  region               = var.aws_region
  name                 = "spoke-workload-vpc"
  cidr                 = var.spoke_vpc_cidr
  aviatrix_transit_vpc = false
  aviatrix_firenet_vpc = false
}

resource "aviatrix_spoke_gateway" "workload" {
  cloud_type   = 1
  account_name = var.aws_account_name
  gw_name      = "spoke-workload-gw"
  vpc_id       = aviatrix_vpc.spoke.vpc_id
  vpc_reg      = var.aws_region
  gw_size      = var.spoke_gw_size
  subnet     = aviatrix_vpc.spoke.public_subnets[0].cidr
}

resource "aviatrix_spoke_transit_attachment" "workload" {
  spoke_gw_name   = aviatrix_spoke_gateway.workload.gw_name
  transit_gw_name = module.mc_transit.transit_gateway.gw_name
}
