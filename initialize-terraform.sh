#!/bin/zsh

bold=$(tput bold)
normal=$(tput sgr0)

export DOMAIN_NAME="${DOMAIN_NAME:-default djoo.org}"
echo "Domain Name set to : ${bold}$DOMAIN_NAME${normal}"
export SUB_DOMAIN_NAME="${SUB_DOMAIN_NAME:-default test}"
echo "SubDomain Name set to : ${bold}$SUB_DOMAIN_NAME${normal}"

echo "> Set configuration variables"
export AWS_REGION=`aws --profile default configure get region`
export AWS_ACCESS_KEY_ID=`aws --profile default configure get aws_access_key_id`
export AWS_SECRET_ACCESS_KEY=`aws --profile default configure get aws_secret_access_key`

# echo $AWS_ACCESS_KEY_ID
echo  "AWS_ACCESS_KEY_ID: ***"
# echo $AWS_SECRET_ACCESS_KEY
echo  "AWS_SECRET_ACCESS_KEY: ***"
echo "AWS_REGION: $AWS_REGION"

export TF_VAR_GANDI_API_KEY=`cat ~/.gandi/API_KEY`
#echo $GANDI_API_KEY
echo  "GANDI_API_KEY: ***"
echo "> run terraform with attributes"

terraform $@
