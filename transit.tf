module "mc_transit" {
  source  = "terraform-aviatrix-modules/mc-transit/aviatrix"
  version = "8.2.0"

  cloud             = "aws"
  region            = var.aws_region
  account           = var.aws_account_name
  cidr              = var.transit_vpc_cidr
  name              = "transit-egress"
  instance_size     = var.transit_gw_size
  ha_gw             = true
  enable_transit_firenet = true
  connected_transit = true
}

module "mc_firenet" {
  source  = "terraform-aviatrix-modules/mc-firenet/aviatrix"
  version = "8.0.0"

  transit_module     = module.mc_transit
  firewall_image     = "aviatrix"
  egress_enabled     = true
  inspection_enabled = false
}
