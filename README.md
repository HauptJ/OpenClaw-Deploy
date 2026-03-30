
Create a new README.md based on the contents of the mcp_porter branch in this repository.  https://github.com/HauptJ/OpenClaw-Deploy/tree/mcporter_demo

5:01 PM

Pivoted to correct repository source and pursued alternative data retrieval method
Pivoted to correct repository source and pursued alternative data retrieval method
Those results are unrelated. Let me try fetching the raw content directly from your repo.


Encountered access barriers; pivoted toward requesting user assistance
Encountered access barriers; pivoted toward requesting user assistance
Unfortunately I'm hitting a wall — GitHub's robots.txt blocks direct fetching, and the raw content URL for your private/personal repo isn't reachable through the tool's permissions model.

To move forward, could you help me get the content one of these ways?

Paste the key files directly into chat — at minimum README.md (if one exists on the branch) plus any top-level config files like main.tf, inventory.yml, Makefile, etc. that describe what the branch does.
Share a raw GitHub URL — if the repo is public, pasting a raw.githubusercontent.com link for a specific file lets me fetch it directly.
Export the file tree — run git ls-tree -r --name-only mcporter_demo and paste the output so I know what's in the branch, then we can work from there.
Once I can see what's actually on that branch, I'll write a solid README for it.


OpenClaw-Deploy-mcporter_demo.zip
zip

Attached is a zip archive of the repository and branch.

5:02 PM

Analyzed repository structure and identified discrepancies with existing documentation
Analyzed repository structure and identified discrepancies with existing documentation
Now I have a complete picture of the branch. The key differences from the existing README are significant — the openclaw/ directory now uses mcporter.json instead of individual skill mcp.json files and openclaw.json, plus the provisioner now installs uv, the AWS CLI (via snap), and deploys the secrets injection scripts. Let me write an accurate README.


Created a file, read a file
Created a file, read a file

New README for mcporter_demo branch
README.md

Presented file
Done
Here's the updated README, written specifically from what's actually in the mcporter_demo branch. The main differences from the existing README it replaces:

Corrected repo structure — the old README described openclaw/openclaw.json and openclaw/skills/gmail|trello/ with per-skill mcp.json files. The branch has none of that — only openclaw/workspace/config/mcporter.json.
Added scripts/ documentation — fill_mcp_secrets.sh, get_aws_secret.sh, and keys.txt are all new to this branch and weren't documented before.
Updated provisioner steps — main.tf now installs snapd, jq, the AWS CLI via snap, and uv as the openclaw user, plus deploys the two scripts via file provisioners.
mcporter server table — documents all three configured servers (zerolib-email, trello-events, trello-applications) with their transports and packages.
Placeholder injection pattern — explains the ${secret-id} syntax in mcporter.json and how fill_mcp_secrets.sh resolves them at runtime.
Readme
Document · MD 
Add this YouTube Video at the end.  https://youtu.be/C4Rtn_pwVaA

5:13 PM

Resolved video title retrieval limitation pragmatically
Resolved video title retrieval limitation pragmatically
I wasn't able to retrieve the video title since YouTube blocks fetching. I'll add it as a demo video section — you can drop in the actual title if you'd like. Appending it now:


Edited a file, read a file
Edited a file, read a file
Done. The Demo section is appended at the end using a clickable thumbnail badge — the standard GitHub pattern for embedding YouTube links in a README (since GitHub doesn't allow actual video embeds). Clicking the thumbnail image will open the video. If you want to replace "mcporter_demo walkthrough" with the actual video title, just let me know what it is.

Readme
Document · MD 





Claude is AI and can make mistakes. Please double-check cited sources.
Readme · MD
Copy

# openclaw-deploy
 
Infrastructure-as-code and configuration repository for deploying an [OpenClaw](https://github.com/openclaw/openclaw-ansible) AI agent environment on OpenStack. This branch (`mcporter_demo`) extends the base deployment with [mcporter](https://github.com/steipete/mcporter) — a CLI-driven MCP gateway — replacing per-skill `mcp.json` files with a single unified `mcporter.json` configuration backed by AWS Secrets Manager.
 
---
 
## Repository Structure
 
```
.
├── dev/                                  # Terraform configuration for the dev environment
│   ├── main.tf                           # Provider, instance, and remote-exec/file provisioners
│   ├── variables.tf                      # All input variable declarations
│   ├── dev.tfvars                        # Dev-specific variable values (do not commit secrets)
│   ├── outputs.tf                        # Output definitions
│   └── scripts/
│       ├── fill_mcp_secrets.sh           # Injects AWS Secrets Manager values into mcporter.json
│       ├── get_aws_secret.sh             # Retrieves a single secret value from AWS Secrets Manager
│       ├── keys.txt                      # List of AWS secret IDs to inject (one per line)
│       └── uv_install.sh                 # uv Python package manager installer (downloaded from astral.sh)
└── openclaw/
    └── workspace/
        └── config/
            └── mcporter.json             # mcporter MCP server gateway configuration
```
 
---
 
## Prerequisites
 
- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.3.0
- An OpenStack cloud with a configured `clouds.yaml` (e.g. OVH Public Cloud)
- An SSH key pair accessible on the machine running Terraform
- An OpenStack image named `Ubuntu 24.04 - UEFI` available in Glance
- An external network UUID for VM attachment
- An [Anthropic API key](https://console.anthropic.com/) for the OpenClaw agent runtime
- AWS credentials with `secretsmanager:GetSecretValue` permission on the relevant secrets (used at runtime on the VM — not required locally)
 
---
 
## Infrastructure: `dev/`
 
The `dev/` environment provisions a single Ubuntu 24.04 VM on OpenStack and bootstraps it using Terraform `remote-exec` and `file` provisioners. After boot, it clones and runs the [`openclaw-ansible`](https://github.com/openclaw/openclaw-ansible) playbook, installs tooling, and deploys the secrets injection scripts.
 
### What gets provisioned
 
1. An SSH keypair resource uploaded to OpenStack
2. A compute instance (`d2-8` flavor by default) attached to the specified external network
3. Cloud-init configuration to set the hostname, disable password auth, and run `apt update`
4. A `remote-exec` provisioner that:
   - Waits for cloud-init to complete
   - Installs `ansible` (via PPA), `git`, `vim`, `snapd`, and `jq`
   - Installs the AWS CLI via `snap install aws-cli --classic`
   - Clones `https://github.com/openclaw/openclaw-ansible` and runs `ansible-playbook playbook.yml`
   - Creates `/home/openclaw/.openclaw/scripts/` and installs [`uv`](https://docs.astral.sh/uv/) as the `openclaw` user
5. Two `file` provisioners that copy `get_aws_secret.sh` and `fill_mcp_secrets.sh` to `/home/openclaw/.openclaw/scripts/`
6. A final `remote-exec` that sets ownership and `711` permissions on all scripts
 
### Variables
 
| Variable | Description | Default |
|---|---|---|
| `cloud_name` | OpenStack cloud name from `clouds.yaml` | `ovhbhs5` |
| `instance_name` | Name of the VM instance | `ubuntu-2404-vm` |
| `image_name` | Glance image name | `Ubuntu 24.04 - UEFI` |
| `image_id` | Glance image UUID | *(required)* |
| `flavor_name` | Compute flavor name | `d2-8` |
| `flavor_id` | Compute flavor UUID | *(required)* |
| `external_network_id` | External network UUID for VM attachment | *(required)* |
| `ssh_user` | Default SSH user for Ubuntu cloud images | `ubuntu` |
| `ssh_public_key_path` | Path to SSH public key | `~/.ssh/id_rsa.pub` |
| `ssh_private_key_path` | Path to SSH private key | `~/.ssh/id_rsa` |
| `ssh_allowed_cidr` | CIDR block for inbound SSH access | `0.0.0.0/0` |
| `environment_tag` | Value for the `environment` metadata tag | `dev` |
| `dns_nameservers` | DNS servers assigned to the subnet | `["8.8.8.8", "8.8.4.4"]` |
 
> **Security note:** Restrict `ssh_allowed_cidr` to your own IP address in production environments.
 
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
 
## mcporter Configuration: `openclaw/workspace/config/mcporter.json`
 
This branch introduces a unified `mcporter.json` that declares all MCP servers in a single file. Place it at `~/.openclaw/workspace/config/mcporter.json` on the provisioned VM (or let Ansible do so automatically).
 
Secret values are stored as placeholder strings using `${secret-id}` syntax and must be injected at runtime via `fill_mcp_secrets.sh` — see [Secrets Management](#secrets-management) below.
 
### Configured MCP servers
 
| Server key | Transport | Package | Purpose |
|---|---|---|---|
| `zerolib-email` | stdio | `uvx mcp-email-server@latest stdio` | Email send/read via IMAP/SMTP |
| `trello-events` | stdio | `npx @Hint-Services/mcp-trello` | Trello events board integration |
| `trello-applications` | stdio | `npx @Hint-Services/mcp-trello` | Trello applications board integration |
 
### Email (`zerolib-email`)
 
Uses [`mcp-email-server`](https://pypi.org/project/mcp-email-server/) via `uvx`. Requires IMAP and SMTP credentials:
 
```json
{
  "MCP_EMAIL_SERVER_ACCOUNT_NAME": "<display-name>",
  "MCP_EMAIL_SERVER_FULL_NAME": "<full-name>",
  "MCP_EMAIL_SERVER_EMAIL_ADDRESS": "<email-address>",
  "MCP_EMAIL_SERVER_USER_NAME": "<email-address>",
  "MCP_EMAIL_SERVER_PASSWORD": "${dev/OpenClaw/Email}",
  "MCP_EMAIL_SERVER_IMAP_HOST": "<imap-host>",
  "MCP_EMAIL_SERVER_IMAP_PORT": "993",
  "MCP_EMAIL_SERVER_SMTP_HOST": "<smtp-host>",
  "MCP_EMAIL_SERVER_SMTP_PORT": "465"
}
```
 
### Trello (`trello-events` / `trello-applications`)
 
Uses [`@Hint-Services/mcp-trello`](https://www.npmjs.com/package/@hint-services/mcp-trello) via `npx`. Two separate server entries allow OpenClaw to treat the events board and applications board as distinct tools.
 
```json
{
  "trelloApiKey": "${dev/openclaw/trello_key}",
  "trelloToken":  "${dev/openclaw/trello}",
  "trelloBoardId": "<board-id>"
}
```
 
> **Finding your board ID:** Append `.json` to your Trello board URL and read the top-level `id` field.
 
---
 
## Secrets Management
 
Secret credentials are stored in **AWS Secrets Manager** and injected into `mcporter.json` at runtime using two scripts deployed to `/home/openclaw/.openclaw/scripts/`.
 
### `keys.txt`
 
A plain-text file listing the AWS Secrets Manager secret IDs to inject, one per line. Comments (`#`) and blank lines are ignored.
 
```
dev/openclaw/trello_key
dev/openclaw/trello
dev/OpenClaw/Email
```
 
### `get_aws_secret.sh`
 
Retrieves a single secret value from AWS Secrets Manager using the AWS CLI and `jq`:
 
```bash
get_aws_secret.sh <secret-id>
```
 
Requires the AWS CLI to be installed at `/usr/bin/aws` and valid credentials in the environment (instance role, environment variables, or `~/.aws/credentials`).
 
### `fill_mcp_secrets.sh`
 
Iterates over `keys.txt`, calls `get_aws_secret.sh` for each secret ID, and replaces the corresponding `${secret-id}` placeholder in the target file in-place using `sed`:
 
```bash
fill_mcp_secrets.sh <target-file> <secrets-list-file> <secret-retrieval-script>
 
# Example
fill_mcp_secrets.sh \
  ~/.openclaw/workspace/config/mcporter.json \
  ~/.openclaw/scripts/keys.txt \
  ~/.openclaw/scripts/get_aws_secret.sh
```
 
Special characters in both the secret ID and secret value are properly escaped before being passed to `sed`, so credentials containing `/`, `&`, `\`, and similar characters are handled safely.
 
### Required IAM permissions
 
The VM's IAM role or the credentials in scope must have:
 
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
- `dev.tfvars` contains environment-specific UUIDs and should be treated as sensitive. Use a `dev.tfvars.example` pattern for sharing non-sensitive defaults; add the real file to `.gitignore`.
- `mcporter.json` uses `${secret-id}` placeholder strings in version control. Real values are injected only at runtime on the target host via `fill_mcp_secrets.sh`. Never commit a `mcporter.json` with real credentials.
- Rotate OAuth tokens and API keys periodically and revoke any credentials that may have been accidentally exposed.
- The `fill_mcp_secrets.sh` script modifies the config file in-place. Ensure file permissions on `mcporter.json` are restricted to the `openclaw` user after injection.
 
---
 
## Contributing
 
1. Fork the repository and create a feature branch.
2. Test all Terraform changes with `terraform plan` before opening a PR.
3. Keep all credential fields in `mcporter.json` as `${secret-id}` placeholders in commits.
4. Do not commit `dev.tfvars`, `*.tfstate`, or any file containing real API keys, tokens, or secrets.
 
---
 
## Related Repositories
 
- [openclaw-ansible](https://github.com/openclaw/openclaw-ansible) — Ansible playbook for OpenClaw installation and configuration
- [mcporter](https://github.com/steipete/mcporter) — MCP server CLI gateway used in this branch
 
---
 
## Demo
 
[![mcporter_demo walkthrough](https://img.youtube.com/vi/C4Rtn_pwVaA/maxresdefault.jpg)](https://youtu.be/C4Rtn_pwVaA)
 


