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
      # Wait for cloud-init to finish 
      "cloud-init status --wait || true",

      # Refresh package index 
      "sudo apt-get update -y",

      # Install prerequisites 
      "sudo apt-get install -y software-properties-common",

      # Add Ansible PPA
      "sudo add-apt-repository --yes --update ppa:ansible/ansible",

      # Refresh package index 
      "sudo apt-get update -y",

      # Install Ansible
      "sudo apt-get install -y ansible",

      # Install git and vim and snap and jq
      "sudo apt-get install -y git vim snapd jq",

      # AWS CLI with snap
      "sudo snap install aws-cli --classic",

      # Clone the OpenClaw installer 
      "git clone https://github.com/openclaw/openclaw-ansible.git",

      # Refresh package index 
      "sudo apt-get update -y",
      
      # CD into the OpenClaw Ansible directory 
      "cd openclaw-ansible",

      # Install OpenClaw 
      "echo 'openclaw_ssh_keys:\n - ${file(var.ssh_public_key_path)}' > vars.yml",

      # Install OpenClaw 
      "sudo ansible-playbook playbook.yml -e @vars.yml",

      # Make OpenClaw scripts directory
      "sudo mkdir -p /home/openclaw/.openclaw/scripts",

      # Download Get AWS Secret script
      "sudo curl -L -o /home/openclaw/.openclaw/scripts/get_aws_secret.sh https://gist.githubusercontent.com/HauptJ/107023f40e22a3c536ad8a3f80065fe0/raw/aed782e81503d6b9ff89e90c9fa96268a9c41ab7/get_aws_secret.sh",

      # Download Fill MCP Secret script
      "sudo curl -L -o /home/openclaw/.openclaw/scripts/fill_mcp_secrets.sh https://gist.githubusercontent.com/HauptJ/0ad93f015ac6ee9f514657dfea3778cc/raw/d75ae2aca27c92a23a9b97837d158ad41ae3b61f/fill_mcp_secrets.sh",

      # Download uv_install script
      "sudo curl -L -o /home/openclaw/.openclaw/scripts/uv_install.sh https://astral.sh/uv/install.sh",

      # set script permissions
      "sudo chown -R openclaw:openclaw /home/openclaw/.openclaw/scripts",

      # set permissions for scripts
      "sudo chmod -R 711 /home/openclaw/.openclaw/scripts",

      # execute uv_install as openclaw user
      "sudo /bin/su -c '/home/openclaw/.openclaw/scripts/uv_install.sh' - openclaw",
    ]
  }

  metadata = {
    environment = var.environment_tag
    managed_by  = "terraform"
  }
}