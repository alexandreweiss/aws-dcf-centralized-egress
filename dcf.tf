resource "aviatrix_smart_group" "test_instance" {
  name = "test-ubuntu-instance"

  selector {
    match_expressions {
      type         = "vm"
      account_name = var.aws_account_name
      region       = var.aws_region
      tags = {
        Name = "test-ubuntu"
      }
    }
  }
}

resource "aviatrix_distributed_firewalling_policy_list" "egress" {
  policies {
    name     = "egress-web-allow-80"
    action   = "PERMIT"
    priority = 1000
    protocol = "TCP"

    src_smart_groups = [aviatrix_smart_group.test_instance.uuid]
    dst_smart_groups = [var.public_internet_smartgroup_uuid]
    web_groups       = [var.allweb_webgroup_uuid]

    port_ranges {
      lo = 80
      hi = 80
    }
  }

  policies {
    name     = "egress-web-allow-443"
    action   = "PERMIT"
    priority = 1001
    protocol = "TCP"

    src_smart_groups = [aviatrix_smart_group.test_instance.uuid]
    dst_smart_groups = [var.public_internet_smartgroup_uuid]
    web_groups       = [var.allweb_webgroup_uuid]

    port_ranges {
      lo  = 443
      hi  = 443
    }
  }
}
