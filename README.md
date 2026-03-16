# openclaw-deploy

Infrastructure-as-code and configuration repository for deploying an [OpenClaw](https://github.com/openclaw/openclaw-ansible) AI agent environment on OpenStack. This repo contains a Terraform module for provisioning a Ubuntu 24.04 VM and a curated set of OpenClaw skills and MCP server integrations.

---

## Repository Structure

```
.
├── dev/                        # Terraform configuration for the dev environment
│   ├── main.tf                 # Provider, data sources, instance, and remote-exec provisioner
│   ├── variables.tf            # All input variable declarations
│   ├── dev.tfvars              # Dev-specific variable values (do not commit secrets)
│   └── outputs.tf              # Output definitions
└── openclaw/
    ├── openclaw.json           # OpenClaw runtime configuration (agent, gateway, tools, auth)
    └── skills/
        ├── gmail/              # Gmail read/compose integration via MCP
        │   ├── SKILL.md
        │   └── mcp.json
        └── trello/             # Trello MCP integration (events + applications boards)
            ├── SKILL.md
            └── mcp.json
```

---

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.3.0
- An OpenStack cloud with a configured `clouds.yaml` (e.g. OVH Public Cloud)
- An SSH key pair accessible on the machine running Terraform
- An OpenStack image named `Ubuntu 24.04 - UEFI` available in Glance
- An external network UUID for VM attachment
- An [Anthropic API key](https://console.anthropic.com/) for the OpenClaw agent runtime

---

## Infrastructure: `dev/`

The `dev/` environment provisions a single Ubuntu 24.04 VM on OpenStack and bootstraps it using a `remote-exec` provisioner. After boot, it clones and runs the [`openclaw-ansible`](https://github.com/openclaw/openclaw-ansible) playbook to install and configure OpenClaw.

### What gets provisioned

1. An SSH keypair resource uploaded to OpenStack
2. A compute instance (`d2-8` flavor by default) attached to the specified external network
3. Cloud-init configuration to set the hostname, disable password authentication, and run `apt update`
4. A `remote-exec` provisioner that:
   - Waits for cloud-init to complete
   - Installs Ansible (via PPA), Git, and Vim
   - Clones `https://github.com/openclaw/openclaw-ansible`
   - Runs `ansible-playbook playbook.yml`

### Configuration

Copy `dev.tfvars.example` to `dev.tfvars` and fill in your values, or pass variables via `-var` flags or environment variables.

| Variable | Description | Default |
|---|---|---|
| `cloud_name` | OpenStack cloud name from `clouds.yaml` | `ovhbhs5` |
| `instance_name` | Name of the VM instance | `ubuntu-2404-vm` |
| `image_name` | Glance image name | `Ubuntu 24.04 - UEFI` |
| `image_id` | Glance image UUID | *(required)* |
| `flavor_name` | Compute flavor name | `d2-8` |
| `flavor_id` | Compute flavor UUID | *(required)* |
| `external_network_id` | External network UUID for VM attachment | *(required)* |
| `ssh_public_key_path` | Path to SSH public key | `~/.ssh/id_rsa.pub` |
| `ssh_private_key_path` | Path to SSH private key | `~/.ssh/id_rsa` |
| `ssh_allowed_cidr` | CIDR block for inbound SSH access | `0.0.0.0/0` |

> **Security note:** Restrict `ssh_allowed_cidr` to your IP address in production environments.

### Deploy

```bash
cd dev/

# Initialize providers
terraform init

# Preview changes
terraform plan -var-file=dev.tfvars

# Apply
terraform apply -var-file=dev.tfvars
```

### Destroy

```bash
terraform destroy -var-file=dev.tfvars
```

---

## OpenClaw Configuration: `openclaw/`

### `openclaw.json`

The runtime configuration file for the OpenClaw agent. Key settings:

| Setting | Value |
|---|---|
| **Primary model** | `anthropic/claude-sonnet-4-6` |
| **Max concurrent agents** | 4 (subagents: 8) |
| **Compaction mode** | `safeguard` |
| **Tool profile** | `coding` |
| **Gateway mode** | Local, port `18789`, loopback bind, token auth |
| **Auth profile** | Anthropic API key |

Copy this file to `~/.openclaw/openclaw.json` on the provisioned VM, or let the Ansible playbook place it automatically.

### Skills

Skills live in the OpenClaw skills directory (typically `~/.openclaw/skills/<skill-name>/`). Each skill includes a `SKILL.md` that defines trigger conditions and agent behavior.

| Skill | Description |
|---|---|
| `email` | Email send/read integration via the Email MCP server (SMTP/IMAP) |
| `trello` | Dual-board Trello integration (events board + applications board) via the `mcp-trello` MCP server |
gi
### MCP Integrations

Each MCP skill ships with an `mcp.json` that must be populated with real credentials **only on the target host** — never in version control. Placeholder values are used in all committed files.

#### Email MCP server

Invocation via `uvx`. Requires SMTP/IMAP credentials:

```json
{
  "SMTP_HOST": "<your-smtp-host>",
  "SMTP_PORT": "<your-smtp-port>",
  "IMAP_HOST": "<your-imap-host>",
  "IMAP_PORT": "<your-imap-port>",
  "EMAIL_USER": "<your-email-address>",
  "EMAIL_PASSWORD": "<your-password>"
}
```

#### Trello (`mcp-trello`)

Invocation via `npx`. Requires Trello API credentials and a board ID. This repo uses two separate board configurations — one for events and one for applications:

```json
{
  "trelloApiKey": "<your-api-key>",
  "trelloToken": "<your-token>",
  "trelloBoardId": "<board-id>"
}
```

> **Finding your board ID:** Append `.json` to your Trello board URL and read the top-level `id` field.

---

## Secrets Management

This project is designed to work with **AWS Secrets Manager** for storing and retrieving sensitive credentials (API keys, OAuth secrets, tokens) at runtime on the provisioned VM. The OpenClaw agent process requires an IAM role or instance profile with `secretsmanager:GetSecretValue` permissions on the relevant secret ARNs.

Ensure the following IAM permission is granted to the instance role:

```json
{
  "Effect": "Allow",
  "Action": "secretsmanager:GetSecretValue",
  "Resource": "arn:aws:secretsmanager:<region>:<account-id>:secret:<secret-name>-*"
}
```

---

## Security

- `*.tfstate*` and `*.terraform*` are gitignored — never commit Terraform state files.
- `dev.tfvars` contains environment-specific values including UUIDs and should be treated as a secrets file. Use a `dev.tfvars.example` pattern for sharing non-sensitive defaults.
- MCP `mcp.json` credential fields use placeholder strings in version control. Replace them with real values only on the target host, via secrets manager injection or manual configuration.
- Rotate OAuth tokens and API keys periodically and revoke any credentials that may have been accidentally exposed.

---

## Contributing

1. Fork the repository and create a feature branch.
2. Test all Terraform changes with `terraform plan` before opening a PR.
3. Keep all `mcp.json` credential fields as placeholder strings in commits.
4. Follow existing naming conventions for new skills: `kebab-case` directory names with a `SKILL.md` entrypoint.
5. Do not commit `dev.tfvars`, `*.tfstate`, or any file containing real API keys, tokens, or secrets.

---

## Related Repositories

- [openclaw-ansible](https://github.com/openclaw/openclaw-ansible) — Ansible playbook for OpenClaw installation and configuration