#! /bin/bash

if aws logs describe-log-groups --log-group-name-prefix "/ecs/ecs-test" --region eu-west-1 --query "logGroups[].logGroupName" --output text >/dev/null 2>&1; then
       echo "log group exists"
      else
        aws logs create-log-group --log-group-name "/ecs/ecs-test" --region eu-west-1
      fi
