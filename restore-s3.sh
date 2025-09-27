aws s3api list-object-versions \
  --bucket paygate-artifacts-beta \
  --prefix "dev-assets/dumapay-merchant-app-libs/" \
  --query 'DeleteMarkers[*].[Key,VersionId]' \
  --output text | while read Key VersionId; do
    echo "Restoring $Key"
    aws s3api delete-object \
      --bucket paygate-artifacts-beta \
      --key "$Key" \
      --version-id "$VersionId"
done

aws s3api list-object-versions \
  --bucket paygate-artifacts-beta \
  --prefix "dev-assets/dumapay-merchant-app-libs/app/" \
  --query 'Versions[*].{Key:Key,VersionId:VersionId}' \
  --output text | while read Key VersionId; do
    echo "Requesting restore for $Key"
    aws s3api restore-object \
      --bucket paygate-artifacts-beta \
      --key "$Key" \
      --version-id "$VersionId" \
      --restore-request '{"Days":7,"GlacierJobParameters":{"Tier":"Expedited"}}'
done

aws s3api list-object-versions \
  --bucket paygate-artifacts-beta \
  --prefix "dev-assets/dumapay-merchant-app-libs/mposAndroidLibrary/" \
  --query 'Versions[*].{Key:Key,VersionId:VersionId}' \
  --output text | while read Key VersionId; do
    echo "Requesting restore for $Key"
    aws s3api restore-object \
      --bucket paygate-artifacts-beta \
      --key "$Key" \
      --version-id "$VersionId" \
      --restore-request '{"Days":7,"GlacierJobParameters":{"Tier":"Expedited"}}'
done
