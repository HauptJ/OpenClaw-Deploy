terraform {
  required_version = ">= 1.3.0"

  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.54"
    }
  }
}

# ---------------------------------------------------------------------------
# Provider – credentials are read from variables (or OS_* env vars)
# ---------------------------------------------------------------------------
provider "openstack" {
    cloud = var.cloud_name
}

# ---------------------------------------------------------------------------
# Data sources
# ---------------------------------------------------------------------------
data "openstack_images_image_v2" "ubuntu_2404" {
  name        = var.image_name
  most_recent = true
}

data "openstack_compute_flavor_v2" "vm_flavor" {
  name = var.flavor_name
}

# ---------------------------------------------------------------------------
# Key pair
# ---------------------------------------------------------------------------
resource "openstack_compute_keypair_v2" "vm_keypair" {
  name       = "${var.instance_name}-keypair"
  public_key = file(var.ssh_public_key_path)
}

# ---------------------------------------------------------------------------
# Compute instance
# ---------------------------------------------------------------------------

resource "openstack_compute_instance_v2" "vm" {
  name            = var.instance_name
  image_id        = data.openstack_images_image_v2.ubuntu_2404.id
  flavor_id       = data.openstack_compute_flavor_v2.vm_flavor.id
  key_pair        = openstack_compute_keypair_v2.vm_keypair.name
  security_groups = ["default"]

  # Cloud-init: set hostname and configure SSH
  user_data = <<-EOF
    #cloud-config
    hostname: ${var.instance_name}
    manage_etc_hosts: true
    ssh_pwauth: false
    package_update: true
  EOF

  network {
    uuid = var.external_network_id
  }

  connection {
    type        = "ssh"
    host        = self.access_ip_v4
    user        = var.ssh_user
    private_key = file(var.ssh_private_key_path)
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      # ── Wait for cloud-init to finish ──────────────────────────────────
      "cloud-init status --wait || true",

      # ── Refresh package index ──────────────────────────────────────────
      "sudo apt-get update -y",

      # ── Install prerequisites ──────────────────────────────────────────
      "sudo apt-get install -y software-properties-common",

      # ── Add Ansible PPA and install ────────────────────────────────────
      "sudo add-apt-repository --yes --update ppa:ansible/ansible",
      "sudo apt-get install -y ansible",

      # ── Install git and vim and snap and jq─────────────────────────────
      "sudo apt-get install -y git vim snapd jq",

      # ── AWS CLI with snap ──────────────────────────────────────────────
      "sudo snap install aws-cli --classic",

      # ── Clone the OpenClaw installer ───────────────────────────────────
      "git clone https://github.com/openclaw/openclaw-ansible.git",
      
      # ── CD into the OpenClaw Ansible directory ─────────────────────────
      "cd openclaw-ansible",

      # ── Install OpenClaw ───────────────────────────────────────────────
      "echo 'openclaw_ssh_keys:\n - ${file(var.ssh_public_key_path)}' > vars.yml",

      # ── Install OpenClaw ───────────────────────────────────────────────
      "sudo ansible-playbook playbook.yml -e @vars.yml",
    ]
  }

  metadata = {
    environment = var.environment_tag
    managed_by  = "terraform"
  }
}