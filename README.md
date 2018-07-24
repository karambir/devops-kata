# Infra setup

Very basic infra setup using ansible, packer and terraform.

## For now, we do:

- Ansible
  1. Create a remote `ubuntu` user and group.
    a. This user has sudo access
    b. The current user's ssh key(typically `~/.ssh/id_rsa`) is copied to remote user.
  2. Add some helpful dotfiles.
  3. A basic nginx installation. Use `--skip-tags web` to not install it.
- Packer
  1. Make an AMI using above ansible playbook
  2. Print ami_id in `packer_manifest.json` and `terraform/packer.auto.tfvars`
- Terraform
  1. Pick `ami_id` from `terraform/packer.auto.tfvars`
  2. Create a VPC, Internet Gateway, Route and Subnet
  3. Create ELB, Auto-scaling groups and Launch configuration using above ami.
  4. Add separate security groups for ELB and our web server and print elb address to visit at the end.

## To start just with ansible

Change hosts in `hosts` file and run:

    ansible-playbook -i hosts site.yml

## To test out packer and terraform

- Configure AWS cli so that `~/.aws/credentials` has aws keys or use env vars.
- Build AMI `packer build packer.json`
- Verify an AMI is created `cat terraform/packer.auto.tfvars`
- Provision infrastructure using terraform `terraform plan` and `terraform apply`
- Run `terrafomr destroy` to delete everything unless you to keep all of that infra running

Happy Devops
