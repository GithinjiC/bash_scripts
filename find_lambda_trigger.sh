#!/bin/bash

BUCKET_NAME="mmcs-dpo.prd"

echo "Searching for Lambda functions with S3 triggers from bucket: $BUCKET_NAME"

# Get all Lambda function names
FUNCTIONS=$(aws lambda list-functions --query 'Functions[*].FunctionName' --output text)

for FUNCTION in $FUNCTIONS; do
    POLICY=$(aws lambda get-policy --function-name "$FUNCTION" 2>/dev/null)
    if [[ $? -eq 0 ]]; then
        echo "$POLICY" | jq --arg bucket "arn:aws:s3:::$BUCKET_NAME" '
        .Policy | fromjson | .Statement[] |
        select(.Principal.Service == "s3.amazonaws.com" and .Condition.ArnLike["AWS:SourceArn"] == $bucket)' >/dev/null

        if [[ $? -eq 0 ]]; then
            echo "Lambda function $FUNCTION is triggered by bucket $BUCKET_NAME"
        fi
    fi
done


# aws s3api get-bucket-notification-configuration --bucket mmcs-dpo.prd