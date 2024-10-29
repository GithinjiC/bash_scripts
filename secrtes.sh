aws secretsmanager list-secrets --query 'SecretList[*].ARN' --profile onz --region eu-west-1 | while read arn; do
  secret_value=$(aws secretsmanager get-secret-value --secret-id "$arn" --query 'SecretString' --profile onz --region eu-west-1)
  
  # Ensure that the secret is a valid JSON object before processing
  if echo "$secret_value" | jq -e . >/dev/null 2>&1; then
    if echo "$secret_value" | jq -e '."cache.host" == "sessions-001.egiiw5.0001.euw1.cache.amazonaws.com"' >/dev/null 2>&1; then
      echo "Found in $arn"
    fi
  fi
done
