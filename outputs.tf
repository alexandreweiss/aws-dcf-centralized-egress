output "egress_gw_az1_public_ip" {
  description = "Aviatrix Egress GW AZ1 EIP — provide to partners for allowlisting"
  value       = module.mc_firenet.aviatrix_firewall_instance[0].eip
}

output "egress_gw_az2_public_ip" {
  description = "Aviatrix Egress GW AZ2 EIP — provide to partners for allowlisting"
  value       = module.mc_firenet.aviatrix_firewall_instance[1].eip
}

output "spoke_gw_public_ip" {
  description = "Spoke gateway EIP"
  value       = aviatrix_spoke_gateway.workload.eip
}

output "test_instance_private_ip" {
  description = "Test Ubuntu instance private IP"
  value       = aws_instance.test.private_ip
}

output "test_instance_public_ip" {
  description = "Test Ubuntu instance public IP (if assigned)"
  value       = aws_instance.test.public_ip
}
