data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "test" {
  key_name   = "non-prod-test"
  public_key = var.test_instance_key
}

resource "aws_security_group" "test_instance" {
  name        = "test-instance-sg"
  description = "Allow SSH inbound"
  vpc_id      = aviatrix_vpc.spoke.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "All traffic from RFC1918"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "test" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.small"
  key_name               = aws_key_pair.test.key_name
  subnet_id              = aviatrix_vpc.spoke.subnets[0].subnet_id
  vpc_security_group_ids = [aws_security_group.test_instance.id]

  user_data = templatefile("${path.module}/test-egress.sh.tftpl", {
    egress_eip1 = module.mc_firenet.aviatrix_firewall_instance[0].eip
    egress_eip2 = module.mc_firenet.aviatrix_firewall_instance[1].eip
  })

  tags = {
    Name = "test-ubuntu"
  }

  depends_on = [aviatrix_spoke_transit_attachment.workload]
}
