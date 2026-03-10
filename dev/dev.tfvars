# ---------------------------------------------------------------------------
# terraform.tfvars  –  fill in your environment-specific values
# Commit a .tfvars.example; add terraform.tfvars to .gitignore
# ---------------------------------------------------------------------------

# OpenStack credentials
cloud_name = "ovhbhs5"

# Instance
instance_name   = "openclaw-dev"
image_name      = "Ubuntu 24.04 - UEFI"
image_id        = "49ccfac7-cfc6-498c-8c89-a86df5e31db8"
flavor_name     = "d2-8"
flavor_id       = "dfc74d9b-e26b-4c07-a038-91e154041577"
environment_tag = "dev"

# Networking
external_network_id = "d7eaf2f8-d9d8-465b-9244-fd4736660570"   # openstack network list --external
dns_nameservers     = ["8.8.8.8", "8.8.4.4"]

# SSH access
ssh_user             = "ubuntu"
ssh_public_key_path  = "~/.ssh/do.pub"
ssh_private_key_path = "~/.ssh/do"
ssh_allowed_cidr     = "0.0.0.0/0"   # restrict to your IP in production