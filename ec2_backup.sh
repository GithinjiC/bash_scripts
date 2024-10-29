#! /bin/bash
# set -x 

# start=$(date +%s)

# if [ -z "$1" ]; then
#     echo "Usage: $0 <region>"
#     exit 1
# fi

# BACKUP_PERIOD=7
PROFILE=$1

ENABLED_REGIONS=$(aws ec2 describe-regions --all-regions --query 'Regions[?OptInStatus==`opt-in-not-required` || OptInStatus==`opted-in`].[RegionName]' --region eu-west-1 --output text)
ACCOUNT_NO=$(aws sts get-caller-identity --query "Account" --region eu-west-1 --output text)

backup_status() {
    # local region="eu-west-1"
    local region="ap-south-1"
    # local region=$1

    # instance_ids=$(aws ec2 describe-instances --region $region --query 'Reservations[*].Instances[*].InstanceId' --output text)
    account_no=$(aws sts get-caller-identity --query "Account" --output text --region $region)
    running_instances_ids=$(aws ec2 describe-instances --region $region --filters "Name=instance-state-name,Values=running"  --query 'Reservations[*].Instances[*].{InstanceId:InstanceId}' --output text)
    backup_plan_ids=$(aws backup list-backup-plans --query 'BackupPlansList[*].BackupPlanId'  --region $region --output text)

    # get resource selection
    if [[ -z $backup_plan_ids && -z $running_instances_ids ]]; then
        echo "No running instances and backup plans in $region"
    elif [[ -n $backup_plan_ids && -n $running_instances_ids ]]; then
        # echo "backup plans and running instances exist"
        for backup_plan_id in $backup_plan_ids; do
            selection_id=$(aws backup list-backup-selections --query 'BackupSelectionsList[*].SelectionId' --backup-plan-id $backup_plan_id --region $region --output text)
            # resources_assigned=$(aws backup get-backup-selection --selection-id 9ecb080d-c6a5-4833-bc35-8124e3a34235 --backup-plan-id a3b3d9e4-c97b-438f-b742-55bb91a877fc --region eu-west-1)
            for s_id in $selection_id; do
                resources_assigned=$(aws backup get-backup-selection --query 'BackupSelection.Resources[*]' --selection-id $s_id --backup-plan-id $backup_plan_id --region $region --output text)
                found=0
                for resource in $resources_assigned; do
                    if [[ $resource == "*" || $resource == "arn:aws:ec2:*:*:instance/*" ]]; then
                        found=1
                            # backup_jobs=$(aws backup list-backup-jobs --region $region --query "BackupJobs[?ResourceArn=='$resource_arn'].[BackupJobId,CreationDate]" --output json)
                        break
                    fi
                done
                if [[ $found -eq 1 ]]; then
                    for instance_id in $running_instances_ids; do
                        resource_arn="arn:aws:ec2:$region:$account_no:instance/$instance_id"
                        current_epoch=$(date -j -f "%a %b %d %T %Z %Y" "`LC_ALL=C date`" "+%s")
                        less_seven_days=$((current_epoch - 604800))
                        # backup_jobs=$(aws backup list-backup-jobs --region $region --query "BackupJobs[?ResourceArn=='$resource_arn'].[BackupJobId,CreationDate]" --output json)
                        # backup_jobs=$(aws backup list-backup-jobs --by-resource-arn $resource_arn --region $region --query "BackupJobs[*].[BackupJobId,CreationDate]" --output json)
                        # filtered_jobs=$(echo $backup_jobs | jq -c --argjson less_seven_days "$less_seven_days" '
                        #     .[] | select((.CreationDate | fromdateiso8601) > $less_seven_days) | .[0]')
                        backup_jobs=$(aws backup list-backup-jobs --by-resource-arn $resource_arn --region $region --query "BackupJobs[*]" --output json)
                        filtered_jobs=$(jq -c --argjson less_seven_days "$less_seven_days" '
                            .[] | select((.CreationDate | sub("\\+\\d\\d:\\d\\d$"; "Z") | sub("\\-\\d\\d:\\d\\d$"; "Z") | fromdateiso8601) > $less_seven_days) | .BackupJobId' <<< "$backup_jobs")
                        # echo $filtered_jobs

                        if [[ -z $filtered_jobs ]]; then
                            echo "$instance_id in region $region is not backed up within the last $BACKUP_PERIOD days."
                        else
                            echo "All EC2 instances in $region are accounted for."
                            break
                        fi
                    done
                fi
            done
        done
    elif [[ -z $backup_plan_ids && -n $running_instances_ids ]]; then
        echo "Something needs to be done in $region"
        vault_name="EC2"
        backup_plan_name="Weekly-35DayRetention-Production"
        selection_name="onz-ec2-all-instances"
        iam_role="arn:aws:iam::$account_no:role/service-role/AWSBackupDefaultServiceRole"
        vault_exists=$(aws backup list-backup-vaults --region $region --query "BackupVaultList[?BackupVaultName=='$vault_name'] | length(@)" --output text)
        if [[ $vault_exists -eq 0 ]]; then
            echo "Creating backup vault $vault_name in $region"
            aws backup create-backup-vault --backup-vault-name $vault_name --region $region
            aws backup create-backup-plan --backup-plan --region $region '{
                "BackupPlanName": "'$backup_plan_name'",
                "Rules": [
                    {
                        "RuleName": "'$backup_plan_name'",
                        "TargetBackupVaultName": "'$vault_name'",
                        "ScheduleExpression": "cron(0 1 ? * 1 *)",
                        "StartWindowMinutes": 60,
                        "CompletionWindowMinutes": 300,
                        "Lifecycle": {
                            "MoveToColdStorageAfterDays": 90,
                            "DeleteAfterDays": 36500
                        },
                        "EnableContinuousBackup": false
                    }
                ],
                "AdvancedBackupSettings": [
                    {
                        "ResourceType": "EC2",
                        "BackupOptions": {
                            "WindowsVSS": "disabled"
                        }
                    }
                ]
            }'
            created_plan_id=$(aws backup list-backup-plans --region ap-south-1 | jq -r --arg plan_name "$backup_plan_name" '.BackupPlansList[] | select(.BackupPlanName == "'$backup_plan_name'") | .BackupPlanId')
            aws backup create-backup-selection --backup-plan-id $created_plan_id --region $region --backup-selection '{
                "SelectionName": "'$selection_name'",
                "IamRoleArn": "'$iam_role'",
                
            }'

        else
            echo "$vault_name exists"
        fi
        
    else
        echo "All good"
    fi
            
    
    # for instance_id in $instance_ids; do
    #     resource_id="arn:aws:ec2:$region::instance/$instance_id"
    #     backup_plans=$(aws backup list-protected-resources --resource-type EC2 --region "$region" --query "Results[?ResourceArn=='$resource_id'].BackupPlanArn" --output text)

    #     if [ -z "$backup_plans" ]; then
    #         echo "$instance_id in region $region is not backed up."
    #     else
    #         backup_job=$(aws backup list-backup-jobs --by-resource-arn "$resource_id" --region "$region" --query "BackupJobs[?CreationDate>=$(date -d "-$BACKUP_PERIOD days" +%FT%T)].BackupJobId" --output text)
    #         if [ -z "$backup_job" ]; then
    #             echo "$instance_id in region $region is not backed up within the last $BACKUP_PERIOD days."
    #         else
    #             echo "$instance_id in region $region is properly backed up."
    #         fi
    #     fi
    # done
}

# for region in $ENABLED_REGIONS; do
#     start=$(date +%s)
#     echo "Checking EC2s in $region"
#     backup_status $region $PROFILE
#     end=$(date +%s)
#     echo "Total Elapsed for $REGION: $((end - start))s"
#     echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
#     echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="

# done

backup_status $region