# Claude Code — Deployment Assistant Guide

This repository is Claude Code-compatible. You can use Claude Code to assist with deploying, customising, and troubleshooting this Terraform configuration against your Aviatrix controller.

## Quick Start with Claude Code

Install Claude Code and start an interactive session in this directory:

```bash
npm install -g @anthropic-ai/claude-code
cd aws-dcf-centralized-egress
claude
```

## What Claude Can Help With

### Initial deployment
```
Deploy this infrastructure against my Aviatrix controller at <hostname>, AWS account <name>, region <region>
```

### Customising CIDRs
```
Update transit and spoke VPC CIDRs to 172.16.0.0/23 and 172.17.0.0/23
```

### Adding spokes
```
Add a second spoke VPC at 10.30.0.0/23 attached to the same transit
```

### Extending DCF policy
```
Add a DCF rule allowing TCP 443 from smart group "payments-app" to the Public Internet webgroup
```

### Troubleshooting
```
terraform apply failed with error <paste error> — how do I fix it?
```

```
The egress test script returned FAIL — help me diagnose why traffic is not exiting via the egress gateways
```

## Context Claude Needs

When starting a session, tell Claude:

- Your Aviatrix controller hostname
- Your onboarded AWS account name (as shown in Controller > Accounts)
- The AWS region you are deploying into
- Any CIDR constraints (VPCs that must not overlap)

Keep your `terraform.tfvars` local — never paste passwords or AWS keys into the Claude conversation.

## What Claude Will Not Do

Claude Code will not commit or push changes without your explicit instruction, and will not apply Terraform without confirmation. Destructive operations (`terraform destroy`, force-push) require explicit approval.

## Provider and Module Versions

| Component | Version |
|---|---|
| Aviatrix Terraform Provider | `~> 8.2` |
| mc-transit module | `8.2.0` |
| mc-firenet module | `8.0.0` |
| AWS Provider | `~> 5.0` |
| Terraform | `>= 1.3.0` |

If your controller requires a different provider version, ask Claude to update `versions.tf` accordingly.
