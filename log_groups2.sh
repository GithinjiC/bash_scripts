if [ "$(aws logs describe-log-groups --log-group-name-prefix "/ecs/ecs-test" --region eu-west-1 --query "logGroups[?logGroupName=='/ecs/ecs-test'] | length(@)" --output text)" -gt 0 ]; then
    echo "Log group exists"
else
    if aws logs create-log-group --log-group-name "/ecs/ecs-test" --region eu-west-1; then
        echo "Log group created successfully"
    else
        echo "Failed to create log group" && exit 1
    fi
fi
