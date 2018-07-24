rm -f terraform/packer.auto.tfvars

echo aws_ami=\"`jq -r '.builds[-1].artifact_id' packer_manifest.json | cut -d':' -f2`\" >> terraform/packer.auto.tfvars
