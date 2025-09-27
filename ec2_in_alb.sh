#!/bin/bash
# set -x

INSTANCE_IDS=("i-029cf17c2e06df275" "i-07cbc6e6c91533f92" "i-041fc81335efc716d" "i-04d9ba4c983db901f" "i-0b91cf05812ef6383" "i-010cf5b9324838704" "i-0fdb8ee08591e38f0" "i-0ac88012511c5131f" "i-0182511c258e217f2")

for INSTANCE_ID in "${INSTANCE_IDS[@]}"; do
    echo "Checking instance ID: $INSTANCE_ID"

    FOUND_IN_ALB_NLB=false
    FOUND_IN_CLB=false

    echo "Checking ALB/NLB Target Groups..."

    for TG_ARN in $(aws elbv2 describe-target-groups --query 'TargetGroups[*].TargetGroupArn' --output text); do
        RESULT=$(aws elbv2 describe-target-health --target-group-arn "$TG_ARN" --query "TargetHealthDescriptions[?Target.Id=='$INSTANCE_ID']" --output text)

        if [[ -n "$RESULT" ]]; then
            FOUND_IN_ALB_NLB=true
            echo "✅ Instance $INSTANCE_ID found in Target Group: $TG_ARN"
        fi
    done

    if [[ "$FOUND_IN_ALB_NLB" == false ]]; then
        echo "❌ Instance $INSTANCE_ID was NOT found in any ALB/NLB Target Groups."
    fi

    echo "➔ Checking Classic Load Balancers (CLB)..."
    CLB_NAME=$(aws elb describe-load-balancers --query "LoadBalancerDescriptions[?Instances[?InstanceId=='$INSTANCE_ID']].LoadBalancerName" --output text)

    if [[ -n "$CLB_NAME" ]]; then
        FOUND_IN_CLB=true
        echo "✅ Instance $INSTANCE_ID found in Classic Load Balancer: $CLB_NAME"
    fi

    if [[ "$FOUND_IN_CLB" == false ]]; then
        echo "❌ Instance $INSTANCE_ID was NOT found in any Classic Load Balancers."
    fi

    echo "================================================================================"
    echo "================================================================================"
    echo "================================================================================"
    echo 
done
