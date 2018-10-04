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


variable "aws_nginx_ami" {
  default = "ami-05d8e8a721306bd5e"
}

# Ubuntu 16.04 LTS (x64)
variable "aws_app_ami" {
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

variable "edx_nginx_ip" {
  default = "eipalloc-0ee83c9edcf49a5b8"
}

variable "edx_app_ip" {
  default = "eipalloc-086f75095a3de7a4e"
}

variable "nginx_instance_type" {
  default = "t2.medium"
}

variable "app_instance_type" {
  default = "m5.xlarge"
}
