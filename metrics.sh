#! /bin/bash
# set -x 

# if [ -z "$1" ]; then
#     echo "Usage: $0 <profile>"
#     exit 1
# fi

PROFILES=$(aws configure list-profiles)
# ENABLED_REGIONS=$(aws ec2 describe-regions --all-regions --query 'Regions[?OptInStatus==`opt-in-not-required` || OptInStatus==`opted-in`].[RegionName]' --region eu-west-1 --output text)
for profile in $PROFILES; do
    ENABLED_REGIONS=$(aws ec2 describe-regions --profile $profile --all-regions --query 'Regions[?OptInStatus==`opt-in-not-required` || OptInStatus==`opted-in`].[RegionName]' --region eu-west-1 --output text)
    echo -e "Enabled regions in $profile are `for region in $ENABLED_REGIONS; do echo $region; done | wc -l`\n"
    for region in $ENABLED_REGIONS; do
        instances=`aws ec2 describe-instances --query "Reservations[*].Instances[*].InstanceId"   --region $region --profile $profile --output text | wc -l`
        if [[ $instances -gt 0 ]]; then
            found_instances=$(aws ec2 describe-instances --profile $profile --query "Reservations[*].Instances[?State.Name=='running' && not_null(PrivateIpAddress) && contains(PrivateIpAddress, '192.168.124')].{InstanceId:InstanceId, PrivateIp:PrivateIpAddress}" --region $region --output text)
            if [[ -n "$found_instances" ]]; then
                echo -e "Instances with criteria in $region:"
                echo $found_instances
            elif [[ -z $found_instances ]]; then
                echo "$instances Instances found in $region but none meet the search criteria"
            fi
        else
            echo "Zero instances in $region"
        fi
    done
    echo "$profile complete."
    echo "################################################"
done

