#!/bin/bash

if aws s3 ls s3://dpo-configurations/payouts/payouts-management-ui/staging/ --region eu-west-1 | grep -q '^'; then
    aws s3 cp s3://dpo-configurations/payouts/payouts-management-ui/staging/.env . --region eu-west-1
else
    # echo "S3 folder does not exist. Skipping sync."
    :
fi


# S3_CONFIG_PREFIX}