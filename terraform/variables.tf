variable "public_key_path" {
  description = <<DESCRIPTION
Path to the SSH public key to be used for authentication.
Ensure this keypair is added to your local SSH agent so provisioners can
connect.

Example: ~/.ssh/terraform.pub
DESCRIPTION

  default = "~/.ssh/id_rsa.pub"
}

variable "key_name" {
  description = "Desired name of AWS key pair"
  default     = "ubuntu-init"
}

variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "us-west-2"
}

# Ubuntu 16.04 LTS (x64)
variable "aws_ami" {
  default = "ami-ba602bc2"
}

variable "project" {
  default = "aws-init"
}

# project_short should be less 6 chars long
variable "project_short" {
  default = "aws"
}
