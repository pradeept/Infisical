terraform {
  required_providers {
    # hcloud = {
    #   source = "hetznercloud/hcloud"
    #   version = "~> 1.45"
    # }

    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    digitalocean = {
        source  = "digitalocean/digitalocean"
        version = "~> 2.0"
    }
  }
}
# provider "hcloud" {
#   token = var.pat
# }

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
  access_key = var.access_key
  secret_key = var.secret_key
}

#------------------For Hetzner cloud------------------

# resource "hcloud_server" "infisical-server" {
#   name = var.basic_configurations.name
#   datacenter  = var.basic_configurations.datacenter
#   server_type = var.basic_configurations.server_type
#   image = var.basic_configurations.image
#   ssh_keys = var.ssh_keys
#   public_net {
#     ipv4_enabled = true
#     ipv6_enabled = false
#   }

#   connection {
#     type = "ssh"
#     user = "root"
#     host = self.ipv4_address
#     timeout = "4m"
#     private_key = file(var.pvt_key)
#   }

#   provisioner "file" {
#     source = var.scripts_path
#     destination = "/tmp/"
#   }
#   provisioner "remote-exec" {
#     inline = [ 
#       "chmod +x /tmp/script.sh",
#       "/tmp/script.sh"
#     ]
#   } 
  
# }

# ------------------For AWS ------------------


resource "aws_instance" "infisical-instance" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name = aws_key_pair.infisical-key-pair.key_name
  user_data = <<-EOF
    #!/bin/bash
    echo 'ubuntu ALL=(ALL:ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/ubuntu
  EOF
  tags = {
    Name = "Infisical"
  }

  connection {
    type = "ssh"
    user = "ubuntu"
    host = self.public_ip
    private_key = file(var.private_key_path)
  }

  provisioner "file" {
    source = var.aws_script_path
    destination = "/tmp/script-aws.sh"
  }

  provisioner "remote-exec" {
    inline = [ 
      "chmod +x /tmp/script-aws.sh",
      "/tmp/script-aws.sh",
     ]
  }
}

resource "aws_security_group" "infisical-firewall" {
  name = "infisical"
  description = "Rules to limit the traffic to VPN only"
  ingress {
    from_port = 22
    to_port = 22
    cidr_blocks = [ "13.127.106.156/32" ]
    description = "Allow SSH from VPN IP only."
    protocol = "tcp"
  }

   ingress{
    from_port = 443
    to_port = 443
    cidr_blocks = [ "13.127.106.156/32" ]
    description = "Allow requests from VPN IP only."
    protocol = "tcp"
  }
  ingress{
    from_port = 80
    to_port = 80
    cidr_blocks = [ "13.127.106.156/32" ]
    description = "Allow requests from VPN IP only."
    protocol = "tcp"
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
resource "aws_key_pair" "infisical-key-pair" {
  key_name = var.key_pair_name
  public_key = file(var.public_key_path)
}

provider "digitalocean" {
  token = var.do_token
}

resource "digitalocean_record" "infisical_domain_mapping" {
  domain = "abc.com"
  type   = "A"
  name   = var.subdomain_name
  value  = aws_instance.infisical-instance.public_ip
  ttl = 369

  # provisioner "local-exec" {
  #     command = "ansible-playbook -i ${hcloud_server.infisical-server.ipv4_address}, --ssh-extra-args='-o StrictHostKeyChecking=no' -e 'hetzner_pat=${var.pat}' playbook.yaml "
  #     working_dir = "${path.module}/ansible"
  # }
  
   provisioner "local-exec" {
      command = "ansible-playbook -i ${aws_instance.infisical-instance.public_ip}, --ssh-extra-args='-o StrictHostKeyChecking=no' -e 'instance_id=${aws_instance.infisical-instance.id}' -e 'security_group_id=${aws_security_group.infisical-firewall.id}' playbook-aws.yaml"
      working_dir = "${path.module}/ansible"
  }

  provisioner "local-exec" {
    command = "aws ec2 modify-instance-attribute --instance-id ${aws_instance.infisical-instance.id} --groups ${aws_security_group.infisical-firewall.id}" 

  } 
}

