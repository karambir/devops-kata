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
  description = "developer key"
  default     = "edx-av"
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
  default = "edx-av"
}

# project_short should be less than 6 chars
variable "project_short" {
  default = "edx"
}

variable "project_environment" {
  default = "production"
}

variable "edx_domain" {
  default = "trainings.aifest.org"
}

variable "instance_type" {
  default = "m5.xlarge"
}
