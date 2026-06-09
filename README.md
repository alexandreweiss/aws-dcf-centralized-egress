# AWS DCF Centralized Egress — Aviatrix

## Business Context

PYO operates payment infrastructure that makes outbound HTTPS calls to third-party partner APIs (payment processors, banks, fraud detection services). Those partners require PYO to declare a fixed set of source IP addresses that they whitelist on their firewalls.

Without centralized egress, every workload in every AWS spoke VPC exits the internet through its own Elastic IP or an unpredictable NAT Gateway address, making it impossible to give partners a stable, auditable IP allowlist.

This deployment solves that by routing **all spoke internet traffic through a pair of dedicated Aviatrix Egress Gateways** with static Elastic IPs. PYO provides those two EIPs to each partner once — they never change unless PYO explicitly decommissions and rebuilds the egress gateways.

```
Partner API allowlist:  <egress-gw-az1-EIP>  <egress-gw-az2-EIP>
                                 ▲                    ▲
                    ┌────────────┴────────────────────┘
                    │     Aviatrix Egress Gateways
                    │     (FireNet, AZ1 + AZ2)
                    │
              Transit VPC
              Transit GW ◄──── spoke-to-transit peering
                    │
              Spoke VPC
              Spoke GW ◄──── workload EC2s
```

**All internet-bound traffic from any spoke exits exclusively via the egress gateway EIPs.** The transit gateway itself does not SNAT — it only forwards. The egress gateways are the sole source IPs visible to external partners.

---

## Architecture

```
┌──────────────────────────────────────────────┐
│  Transit VPC (Aviatrix FireNet)               │
│                                               │
│  ┌─────────────────┐   ┌──────────────────┐  │
│  │  Transit GW      │   │ Egress GW AZ1    │◄─┼── EIP-1 (give to partners)
│  │  transit-egress  │   │ Egress GW AZ2    │◄─┼── EIP-2 (give to partners)
│  │  (primary + HA)  │   └──────────────────┘  │
│  └────────┬─────────┘                         │
└───────────┼───────────────────────────────────┘
            │ Aviatrix encrypted tunnel
┌───────────┼───────────────────────────────────┐
│  Spoke VPC                                    │
│  ┌──────────────┐   ┌─────────────────────┐   │
│  │  Spoke GW    │   │  Ubuntu test EC2    │   │
│  │  (no HA)     │   │  10.20.0.x          │   │
│  └──────────────┘   └─────────────────────┘   │
└───────────────────────────────────────────────┘
```

**Traffic flow:** EC2 → Spoke GW → Transit GW → Aviatrix Egress GW → Internet

**DCF policy:** permits TCP 80 and 443 from the `test-ubuntu-instance` smart group to the Public Internet smart group, enforced through the AllWeb webgroup (FQDN-based filtering).

---

## Prerequisites

- Terraform >= 1.3.0
- AWS credentials (access key + secret) with permissions to create VPCs, subnets, EC2 instances, security groups, and IAM instance profiles in the target region
- Aviatrix Controller (>= 7.1) with:
  - AWS account already onboarded (note the account name as shown in Controller > Accounts)
  - DCF enabled — if not already active, go to `CoPilot > Security > Distributed Cloud Firewall` and click **Enable**. This is a one-time operation per controller and cannot be undone.
- AWS EIP quota >= 5 in the target region (see [EIP Quota](#aws-eip-quota))

---

## Quick Start

### 1. Clone and initialise

```bash
git clone <this-repo>
cd aws-dcf-centralized-egress
terraform init
```

### 2. Create `terraform.tfvars`

```hcl
# --- Required ---
aviatrix_controller_ip = "your-controller.example.com"   # controller hostname or IP
aviatrix_password      = "YourControllerPassword"
aws_account_name       = "your-onboarded-aws-account"    # as shown in Controller > Accounts
test_instance_key      = "ssh-rsa AAAA... your-key"      # SSH public key for the test VM

# --- Optional: override defaults to fit PYO's addressing plan ---
aws_region       = "eu-west-1"        # any region where the AWS account is onboarded
transit_vpc_cidr = "10.10.0.0/23"     # must not overlap existing VPCs in the controller
spoke_vpc_cidr   = "10.20.0.0/23"     # must not overlap existing VPCs in the controller
transit_gw_size  = "c5.xlarge"        # minimum recommended for FireNet with egress
spoke_gw_size    = "t3.small"
```

### 3. Deploy

```bash
terraform plan
terraform apply
```

Deployment takes approximately 15–20 minutes. Gateway creation is the bottleneck.

### 4. Retrieve egress IPs for partner allowlisting

After `apply` completes, retrieve the egress gateway EIPs:

```bash
terraform output spoke_gw_public_ip

# Transit GW EIP is marked sensitive — retrieve explicitly:
terraform output -raw transit_gw_public_ip
```

The two egress gateway EIPs are visible in the Aviatrix Controller under:
`CoPilot > Cloud Fabric > Gateways > transit-egress-az1-egress-gw1` and `transit-egress-az2-egress-gw1`

Provide these two IPs to each partner that needs to allowlist PYO's outbound traffic.

### 5. Test egress

SSH to the Ubuntu test instance from a host that can reach the spoke VPC (e.g. via PYO's OOB network):

```bash
ssh ubuntu@<test_instance_private_ip>
```

Run the bundled validation script:

```bash
/home/ubuntu/test-egress.sh
```

Expected output confirming traffic exits via the egress gateways:
```
=== Aviatrix Centralized Egress Test ===
Expected egress IP (transit GW EIP): <egress EIP>
Actual public IP seen by ipify:       <same EIP>
PASS: traffic exits via Aviatrix egress gateway
```

Boot-time result is logged at `/var/log/egress-test.log`.

---

## Variables Reference

| Variable | Required | Default | Description |
|---|---|---|---|
| `aviatrix_controller_ip` | yes | — | Controller hostname or IP |
| `aviatrix_username` | no | `admin` | Controller admin username |
| `aviatrix_password` | yes | — | Controller admin password (sensitive) |
| `aws_region` | no | `eu-west-1` | AWS region to deploy into |
| `aws_account_name` | yes | — | Aviatrix-onboarded AWS account name |
| `transit_vpc_cidr` | no | `10.10.0.0/23` | Transit/FireNet VPC CIDR — must not overlap existing VPCs |
| `spoke_vpc_cidr` | no | `10.20.0.0/23` | Spoke VPC CIDR — must not overlap existing VPCs |
| `transit_gw_size` | no | `c5.xlarge` | Transit gateway instance size |
| `spoke_gw_size` | no | `t3.small` | Spoke gateway instance size |
| `test_instance_key` | yes | — | SSH public key for the Ubuntu test instance |
| `allweb_webgroup_uuid` | no | `def000ad-0000-0000-0000-000000000002` | AllWeb webgroup UUID (controller built-in) |
| `anywhere_smartgroup_uuid` | no | `def000ad-0000-0000-0000-000000000000` | Aviatrix Anywhere smart group UUID (controller built-in) |
| `public_internet_smartgroup_uuid` | no | `def000ad-0000-0000-0000-000000000001` | Aviatrix Public Internet smart group UUID (controller built-in) |

> The three UUID variables are Aviatrix controller built-ins and do not need to change across deployments.

---

## Outputs

| Output | Description |
|---|---|
| `transit_gw_public_ip` | Transit gateway EIP (sensitive — use `terraform output -raw`) |
| `spoke_gw_public_ip` | Spoke gateway EIP |
| `test_instance_private_ip` | Ubuntu test instance private IP |
| `test_instance_public_ip` | Ubuntu test instance public IP (empty — no EIP assigned to instance) |

---

## AWS EIP Quota

This deployment allocates **5 Elastic IPs** in the target region:

| Resource | EIPs |
|---|---|
| Transit GW primary + HA | 2 |
| Aviatrix Egress GW AZ1 + AZ2 | 2 |
| Spoke GW | 1 |

The default AWS EIP quota is 5 per region per account. If the target account already has EIPs allocated, request a quota increase before deploying:

```
AWS Console > Service Quotas > Amazon EC2 > EC2-VPC Elastic IPs > Request quota increase
```

---

## Extending to Production

To attach PYO's existing spoke VPCs to this transit and route their internet traffic through the same egress EIPs:

1. In the Aviatrix Controller, attach each existing spoke gateway to `transit-egress` via `CoPilot > Cloud Fabric > Topology > Attach`.
2. Extend DCF policy in `dcf.tf` — add smart groups matching production workloads as additional `src_smart_groups` entries on the existing policy rules, or create new policy blocks per application team.
3. No changes to egress gateway EIPs are required — partners' allowlists remain valid.

---

## Teardown

```bash
terraform destroy
```

Aviatrix-created EIPs are tagged `Aviatrix-Created-Resource` and released automatically on destroy. Partner allowlists referencing these EIPs should be updated before teardown.
