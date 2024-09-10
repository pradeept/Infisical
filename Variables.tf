variable "pat" {
  type = string
  description = "API token"
}
variable "ssh_keys" {
  type = list(string)
  description = "ssh_keys to inject into the server"
}

variable "basic_configurations" {
  type = object({
    name = string,
    datacenter = string,
    server_type = string,
    image = string
  })
  description = "Contains basic configurations for the server"
}

variable "pvt_key" {
  type = string
  description = "Path to the private key"
}

variable "scripts_path" {
  type = string
}

variable "do_token" {
  type = string
}

variable "subdomain_name" {
  type = string
  description = "Sub-domain name to map to the infisical server ip"
}



# ---------------- AWS ----------------

variable "ami_id" {
  type = string
  description = "Amazon Machine Image id"
}

variable "instance_type" {
  type = string
  description = "AWS instance type"
}

variable "access_key" {
  type = string
  description = "AWS access key from IAM"
}

variable "secret_key" {
  type = string
  description = "AWS secret key from IAM"
}

variable "key_pair_name" {
  type = string
  description = "Name for the Key-Pair resource"
}

variable "public_key_path" {
  type = string
  description = "Path of your public key"
}

variable "private_key_path" {
  type = string
  description = "Path to your private key"
}

variable "aws_script_path" {
  type = string
  description = "Shell script to install and configure infisical"
}