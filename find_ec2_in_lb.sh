INSTANCE_ID=i-0c3dd34dd37468e92
REGION=us-east-1

aws elbv2 describe-target-groups --region $REGION \
  --query 'TargetGroups[].TargetGroupArn' --output text | \
  tr '\t' '\n' | \
  while read tg; do
    if aws elbv2 describe-target-health --region $REGION \
         --target-group-arn "$tg" \
         --query "TargetHealthDescriptions[?Target.Id=='$INSTANCE_ID']" \
         --output text | grep -q .; then
      echo "Instance found in target group: $tg"
      aws elbv2 describe-target-groups --region $REGION \
        --target-group-arns "$tg" \
        --query 'TargetGroups[].LoadBalancerArns[]' \
        --output text | tr '\t' '\n' | \
        while read lb; do
          aws elbv2 describe-load-balancers --region $REGION \
            --load-balancer-arns "$lb" \
            --query 'LoadBalancers[].[LoadBalancerName,Type,DNSName]' \
            --output table
        done
    fi
  done
