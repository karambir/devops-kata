#!/bin/bash

export PACKER_LOG=1
export PACKER_LOG_PATH=./packer.log

export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-ap-southeast-1}
export AWS_REGION=$AWS_DEFAULT_REGION

export AWS_EC2_INSTANCE=${AWS_EC2_INSTANCE:-m5.xlarge}
export EDX_VERSION=${EDX_VERSION:-open-release/ginkgo.master}
export EDX_DOMAIN=${EDX_DOMAIN:-trainings.aifest.org}
export EDX_PLATFORM_VERSION=av.ginkgo

# edx_platform_version should be given here explicitly as native.sh check for it separately
export EDX_VARS="-e EDXAPP_LMS_SITE_NAME=$EDX_DOMAIN -e EDXAPP_CMS_SITE_NAME=studio.$EDX_DOMAIN -e edx_platform_version=$EDX_PLATFORM_VERSION -e ECOMMERCE_VERSION=$EDX_PLATFORM_VERSION"
if [[ -f edx_vars.yml ]]; then
    export EDX_VARS="-e@/home/ubuntu/edx_vars.yml $EDX_VARS"
fi

echo "Using packer log level: ${PACKER_LOG}
Using packer log: ${PACKER_LOG_PATH}
Using region: ${AWS_REGION}
Using EC2 instance type: ${AWS_EC2_INSTANCE}"

packer build packer-initial.json
rm -f terraform/packer.auto.tfvars

echo aws_app_ami=\"`jq -r '.builds[-1].artifact_id' packer_manifest.json | cut -d':' -f2`\" >> terraform/packer.auto.tfvars

echo aws_region=\"$AWS_REGION\" >> terraform/packer.auto.tfvars

echo edx_domain=\"$EDX_DOMAIN\" >> terraform/packer.auto.tfvars

echo app_instance_type=\"$AWS_EC2_INSTANCE\" >> terraform/packer.auto.tfvars