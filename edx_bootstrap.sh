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

EDX_STATELESS='stateless'
EDX_DBS='dbs'
EDX_SANDBOX='sandbox'
PACKER_CONF='stateless'

if [ -z $1 ]
then
  echo "No option given. Use option ${EDX_SANDBOX}, ${EDX_STATELESS} or ${EDX_DBS} with script."
  exit 1;
elif [ -n $1 ]
then
  PACKER_CONF=$1
fi


echo "Creating machine: edx-${PACKER_CONF}
Using packer log level: ${PACKER_LOG}
Using packer log: ${PACKER_LOG_PATH}
Using region: ${AWS_REGION}
Using EC2 instance type: ${AWS_EC2_INSTANCE}"

case $PACKER_CONF in
    $EDX_STATELESS|$EDX_SANDBOX)
        packer build packer-edx-$PACKER_CONF.json
        rm -f terraform/packer.auto.tfvars
        echo aws_app_ami=\"`jq -r '.builds[-1].artifact_id' packer_manifest.json | cut -d':' -f2`\" >> terraform/packer.auto.tfvars
        echo aws_region=\"$AWS_REGION\" >> terraform/packer.auto.tfvars
        echo edx_domain=\"$EDX_DOMAIN\" >> terraform/packer.auto.tfvars
        echo app_instance_type=\"$AWS_EC2_INSTANCE\" >> terraform/packer.auto.tfvars
        ;;
    $EDX_DBS)
        export AWS_EC2_INSTANCE="t2.large"
        packer build packer-edx-dbs.json
        echo aws_app_ami=\"`jq -r '.builds[-1].artifact_id' packer_manifest.json | cut -d':' -f2`\" >> terraform/packer.auto.tfvars
        ;;
esac

