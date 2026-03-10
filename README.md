# openclaw-deploy

Infrastructure-as-code and configuration repository for deploying an [OpenClaw](https://github.com/openclaw/openclaw-ansible) AI agent environment on OpenStack. This repo contains a Terraform module for provisioning a Ubuntu 24.04 VM and a curated set of OpenClaw skills and MCP integrations.

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
        ├── career-coach/       # Structured career coaching skill
        │   └── SKILL.md
        ├── daily-mood-checkin/ # Daily mood check-in skill
        │   └── SKILL.md
        ├── gmail/              # Gmail MCP integration
        │   ├── SKILL.md
        │   └── mcp.json
        ├── google-calendar/    # Google Calendar MCP integration
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
- An external network ID for VM attachment

---

## Infrastructure: `dev/`

The dev environment provisions a single Ubuntu 24.04 VM on OpenStack and bootstraps it with Ansible, Git, and Vim via a `remote-exec` provisioner. It then clones and runs the `openclaw-ansible` playbook to install OpenClaw.

### What gets provisioned

1. An SSH keypair resource uploaded to OpenStack
2. A compute instance (`d2-8` flavor by default) attached to the specified external network
3. Cloud-init configuration to set hostname, disable password auth, and run `apt update`
4. A `remote-exec` provisioner that:
   - Waits for cloud-init to finish
   - Installs Ansible (via PPA), Git, and Vim
   - Clones `https://github.com/openclaw/openclaw-ansible`
   - Runs `ansible-playbook playbook.yml`

### Configuration

Copy `dev.tfvars` and fill in your values, or set variables as environment variables or via `-var` flags.

Key variables:

| Variable | Description | Default |
|---|---|---|
| `cloud_name` | OpenStack cloud name from `clouds.yaml` | `ovhbhs5` |
| `instance_name` | Name of the VM instance | `ubuntu-2404-vm` |
| `image_name` | Glance image name | `Ubuntu 24.04 - UEFI` |
| `image_id` | Glance image UUID | _(required)_ |
| `flavor_name` | Compute flavor name | `d2-8` |
| `flavor_id` | Compute flavor UUID | _(required)_ |
| `external_network_id` | External network UUID for VM attachment | _(required)_ |
| `ssh_public_key_path` | Path to SSH public key | `~/.ssh/id_rsa.pub` |
| `ssh_private_key_path` | Path to SSH private key | `~/.ssh/id_rsa` |
| `ssh_allowed_cidr` | CIDR for inbound SSH access | `0.0.0.0/0` |

> **Security note:** Restrict `ssh_allowed_cidr` to your IP address in production.

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

- **Model:** `anthropic/claude-sonnet-4-6` (primary)
- **Max concurrent agents:** 4 (subagents: 8)
- **Compaction mode:** `safeguard`
- **Tool profile:** `coding`
- **Gateway:** Local mode on port `18789`, loopback bind, token auth
- **Auth profile:** Anthropic API key mode

Copy this file to `~/.openclaw/openclaw.json` on the provisioned VM (or let the Ansible playbook place it).

### Skills

Skills are placed in the OpenClaw skills directory (typically `~/.openclaw/skills/<skill-name>/`). Each skill includes a `SKILL.md` that describes when the skill triggers and how the agent should behave.

| Skill | Description |
|---|---|
| `career-coach` | Structured, memory-aware career coaching with daily focus and accountability |
| `daily-mood-checkin` | Prompts the user for a mood check-in at the start of each new conversation day |
| `gmail` | Gmail read/compose integration via MCP |
| `google-calendar` | Google Calendar read/write integration via MCP |
| `trello` | Dual-board Trello integration (events + applications) via MCP |

### MCP Integrations

MCP integrations require credentials configured in each skill's `mcp.json`. Copy the relevant file to the OpenClaw MCP config location and fill in the placeholder values.

**Gmail** — requires a Google Cloud OAuth2 client:
```json
"CLIENT_ID": "<your-client-id>.apps.googleusercontent.com",
"CLIENT_SECRET": "<your-client-secret>"
```

**Google Calendar** — requires a Google Cloud OAuth2 client:
```json
"GOOGLE_CLIENT_ID": "<your-client-id>.apps.googleusercontent.com",
"GOOGLE_CLIENT_SECRET": "<your-client-secret>",
"GOOGLE_REDIRECT_URI": "http://localhost:4153/oauth2callback"
```

**Trello** — requires Trello API credentials and two board IDs (events and applications):
```json
"trelloApiKey": "<your-api-key>",
"trelloToken": "<your-token>",
"trelloBoardId": "<board-id>"
```

> Trello board IDs can be found by appending `.json` to your board URL and reading the `id` field.

---

## Security

- `*.tfstate*` and `*.terraform*` are gitignored — never commit state files.
- `dev.tfvars` contains environment-specific values including UUIDs. Treat it like a secrets file and add it to `.gitignore` or use a `.tfvars.example` pattern for sharing.
- MCP credential fields in `mcp.json` files use placeholder strings — replace them with real values only on the target host, never in version control.

---

## Contributing

1. Fork the repository and create a feature branch.
2. Test Terraform changes with `terraform plan` before opening a PR.
3. Keep `mcp.json` credential fields as placeholders in all commits.
4. Follow existing naming conventions for new skills (`kebab-case` directory names, `SKILL.md` entrypoint).