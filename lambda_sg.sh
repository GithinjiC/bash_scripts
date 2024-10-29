#!/bin/bash
# set -x

# Extract the region from the command line argument
# REGION=$1

# # List all Lambda functions
# LAMBDA_FUNCTIONS=$(aws lambda list-functions --region $REGION --query 'Functions[*].FunctionName' --output text)

# # Iterate over each Lambda function
# for FUNCTION_NAME in $LAMBDA_FUNCTIONS; do
#     #echo "Checking Lambda function: $FUNCTION_NAME"

#     # Get the VPC configuration for the Lambda function
#     #VPC_CONFIG=$(aws lambda get-function-configuration --region $REGION --function-name "$FUNCTION_NAME" --query 'VpcConfig' --output json)
    
#     # Check if VPCConfig is not empty
#     #if [ -n "$VPC_CONFIG" ]; then
#         # Extract Security Groups
#         #SECURITY_GROUPS=$(echo $VPC_CONFIG | jq -r .SecurityGroupsIds[]?)
#     SECURITY_GROUPS=$(aws lambda get-function-configuration --region eu-west-1 --function-name $FUNCTION_NAME --query 'VpcConfig' --output json | jq -r .SecurityGroupIds[]?)
#     #echo "Security Groups for $FUNCTION_NAME:"
#     for SG in $SECURITY_GROUPS; do
#     	echo "$SG"
#     done
#     #else
#         #echo "$FUNCTION_NAME is not associated with a VPC."
#     #fi
    
#     #echo "-----------------------------"
# done


# LAMBDA_FUNCTIONS=$(aws lambda list-functions --region $REGION --query 'Functions[*].FunctionName' --output text)
# USED_SG_LAMBDA=""
# # Iterate over each Lambda function
# for FUNCTION_NAME in $LAMBDA_FUNCTIONS; do
#     SECURITY_GROUPS=$(aws lambda get-function-configuration --region $REGION --function-name $FUNCTION_NAME --query 'VpcConfig' --output json | jq -r .SecurityGroupIds[]?)
#     #echo "Security Groups for $FUNCTION_NAME:"
#     for SG in $SECURITY_GROUPS; do
#     	# echo "$SG"
#         USED_SG_LAMBDA+="$SG "
#     done
#     # echo $USED_SG_LAMBDA
#     #else
#         #echo "$FUNCTION_NAME is not associated with a VPC."
#     #fi
# done
# echo -e $USED_SG_LAMBDA

# RDS_INSTANCES=$(aws rds describe-db-instances --region $REGION --query 'DBInstances[*].DBInstanceIdentifier' --output text)
# USED_SG_RDS=""
# for DB_INSTANCE in $RDS_INSTANCES; do
#     SECURITY_GROUPS=$(aws rds describe-db-instances --region eu-west-1 --db-instance-identifier $DB_INSTANCE --query 'DBInstances[0].VpcSecurityGroups[*].VpcSecurityGroupId' --output json | jq -r '.[]')
#     for SG in $SECURITY_GROUPS; do
#         if echo "$USED_SG_RDS" | grep -qw "$SG"; then
#             echo "exists"
#         else
#             USED_SG_RDS="$USED_SG_RDS $SG"
#         fi
#     done
# done
# echo $USED_SG_RDS

# Define function to get used security groups for RDS instances
# get_used_sg_rds() {
#     local REGION=$1
#     local USED_SG_RDS=""

#     # Fetch RDS instances
#     local RDS_INSTANCES
#     RDS_INSTANCES=$(aws rds describe-db-instances --region "$REGION" --query 'DBInstances[*].DBInstanceIdentifier' --output text)

#     # Declare associative array to track security groups
#     declare -A SG_MAP

#     # Process each RDS instance
#     for DB_INSTANCE in $RDS_INSTANCES; do
#         # Fetch security groups for the current RDS instance
#         local SECURITY_GROUPS
#         SECURITY_GROUPS=$(aws rds describe-db-instances --region $REGION --db-instance-identifier $DB_INSTANCE --query 'DBInstances[*].VpcSecurityGroups[*].VpcSecurityGroupId' --output json | jq -r '.[]')

#         # Add security groups to associative array if not already present
#         for SG in $SECURITY_GROUPS; do
#             if [[ -z ${SG_MAP[$SG]} ]]; then
#                 SG_MAP[$SG]=1
#                 USED_SG_RDS+="$SG "
#             fi
#         done
#     done

#     # Output the collected security groups
#     echo "$USED_SG_RDS"
# }

# # Example usage
# REGION="eu-west-1"  # Replace with your region
# USED_SG=$(get_used_sg_rds "$REGION")
# echo "Used Security Groups: $USED_SG"

# # Define function to get the used security groups for RDS instances
# get_used_sg_rds() {
#     local REGION=$1
#     local USED_SG_RDS=""
#     local SECURITY_GROUPS
#     local SG
#     local RDS_INSTANCES
    
#     RDS_INSTANCES=$(aws rds describe-db-instances --region "$REGION" --query 'DBInstances[*].DBInstanceIdentifier' --output text)

#     for DB_INSTANCE in $RDS_INSTANCES; do
#         # SECURITY_GROUPS=$(aws rds describe-db-instances --region "$REGION" --db-instance-identifier "$DB_INSTANCE" --query 'DBInstances[*].VpcSecurityGroups[*].VpcSecurityGroupId' --output json | jq -r '.[]')
#         SECURITY_GROUPS=$(aws rds describe-db-instances --region "$REGION" --db-instance-identifier "$DB_INSTANCE" --query 'DBInstances[*].VpcSecurityGroups[*].VpcSecurityGroupId' --output text)

#         # Append each security group ID to USED_SG_RDS if not already present
#         while read -r SG; do
#             if ! echo "$USED_SG_RDS" | grep -Fq "$SG" ; then
#                 USED_SG_RDS+="$SG "
#             fi
#         done <<< "$SECURITY_GROUPS"
#     done

#     # Output the collected security groups
#     echo "$USED_SG_RDS"
# }

# get_used_sg_lambda() {
#     local REGION=$1
#     local USED_SG_LAMBDA=""
#     local SECURITY_GROUPS
#     local SG
#     local LAMBDA_FUNCTIONS
    
#     LAMBDA_FUNCTIONS=$(aws lambda list-functions --region $REGION --query 'Functions[*].FunctionName' --output text)

#     for FUNCTION_NAME in $LAMBDA_FUNCTIONS; do
#         # SECURITY_GROUPS=$(aws lambda get-function-configuration --region $REGION --function-name $FUNCTION_NAME --query 'VpcConfig' --output json | jq -r '.SecurityGroupIds[]?')
#         SECURITY_GROUPS=$(aws lambda get-function-configuration --region $REGION --function-name $FUNCTION_NAME --query 'VpcConfig.SecurityGroupIds' --output text)

#         for SG in $SECURITY_GROUPS; do
#     	# echo "$SG"
#             USED_SG_LAMBDA+="$SG "
#         done
#     done
#     # echo -e $USED_SG_LAMBDA

#         # Append each security group ID to USED_SG_LAMBDA if not already present
#         # while read -r SG; do
#         #     if ! echo "$USED_SG_LAMBDA" | grep -Fq "$SG" ; then
#         #         USED_SG_LAMBDA+="$SG "
#         #     fi
#         # # done <<< "$SECURITY_GROUPS"
#         # done <<< "$SECURITY_GROUPS"
#     # done

#     # Output the collected security groups
#     echo "$USED_SG_LAMBDA"
# }

# # USED_SG_RDS=$(get_used_sg_rds $REGION)
# USED_SG_LAMBDA=$(get_used_sg_lambda $REGION)
# USED_SG="$USED_SG_LAMBDA"
# # convert space-generated list to newline-separated, sort and remove duplicates, convert back to space-separated list
# USED_SG=$(echo -e "$USED_SG" | tr ' ' '\n' | sort -u | tr '\n' ' ')
# # USED_SG=$(echo -e "$USED_SG" | tr ' ' '\n' | sort -u)
# # USED_SG=$(echo -e "$USED_SG" | tr ' ' '\n')
# echo "Used Security Groups: $USED_SG"


# REGIONS=$(aws ec2 describe-regions --all-regions --query 'Regions[?OptInStatus==`opt-in-not-required` || OptInStatus==`opted-in`].[RegionName]' --output text --region <any_region>)
# for region in ${REGIONS[@]};do ./scratch.sh $region; done


# get_enabled_regions() {
#     aws ec2 describe-regions --all-regions --query 'Regions[?OptInStatus==`opt-in-not-required` || OptInStatus==`opted-in`].[RegionName]' --output text --region eu-west-1
# }

# get_all_sg_ids() {
#     local region=$1
#     aws ec2 describe-security-groups --region $region --query 'SecurityGroups[*].GroupId' --output text | tr -s '\t' ' ' | tr ' ' '\n' | sort -u
# }

# get_used_sg_ids() {
#     local region=$1
#     local used_sg_all=()
#     used_sg_all+=$(aws ec2 describe-network-interfaces --region $region --query 'NetworkInterfaces[*].Groups[*].GroupId' --output text | tr -s '\t' ' ' | tr ' ' '\n' | sort -u)
#     used_sg_all+=$(aws ec2 describe-instances --region $region --query 'Reservations[*].Instances[*].SecurityGroups[*].GroupId' --output text)
#     used_sg_all+=$(aws elb describe-load-balancers --region $region --query 'LoadBalancerDescriptions[*].SecurityGroups[*]' --output text)
#     used_sg_all+=$(aws elbv2 describe-load-balancers --region $region --query 'LoadBalancers[*].SecurityGroups[*]' --output text)
#     used_sg_all+=$(aws elasticache describe-cache-clusters --region $region --query 'CacheClusters[*].SecurityGroups[*].SecurityGroupId' --output text)
#     used_sg_all+=$(aws lambda list-functions --region $region --query 'Functions[?VpcConfig.SecurityGroupIds!=`null`].VpcConfig.SecurityGroupIds' --output text)
#     used_sg_all+=$(aws rds describe-db-instances --region $region --query 'DBInstances[*].VpcSecurityGroups[*].VpcSecurityGroupId' --output text)
#     used_sg_all+=$(aws ds describe-directories --region $region --query 'DirectoryDescriptions[*].VpcSettings.SecurityGroupId' --output text)
    
#     # Transfer Family
#     server_ids=$(aws transfer list-servers --region $region --query "Servers[*].ServerId" --output text)
#     for server_id in $server_ids; do
#         used_sg_all+=$(aws transfer describe-server --server-id $server_id --region $region --query "Server.EndpointDetails.SecurityGroupIds" --output text)
#     done

#     # AWS EFS
#     file_system_ids=$(aws efs describe-file-systems --region $region --query 'FileSystems[*].FileSystemId' --output text)
#     for file_system_id in $file_system_ids; do
#         used_sg_all+=$(aws efs describe-mount-targets --file-system-id $FILE_SYSTEM_ID --region $REGION --query 'MountTargets[*].SecurityGroups' --output text)
#     done

#     echo $used_sg_all | tr -s '\t' ' ' | tr ' ' '\n'| grep -v '^None$' | sort -u
# }

# find_unused_sgs() {
#     local region=$1
#     shift
#     local all_sg_ids=("$@")
#     local used_sg_ids=$(get_used_sg_ids $region)
#     local unused_sg=()

#     for sg_id in ${all_sg_ids[@]}; do  
#         if [[ ! $used_sg_ids =~ $sg_id ]]; then
#             unused_sg+=($sg_id)
#         fi
#     done

#     echo ${unused_sg[@]}
# }

# process_region() {
#     local region=$1
#     echo "Processing region: $region"

#     all_sg_ids=($(get_all_sg_ids $region))
#     unused_sg=($(find_unused_sgs $region ${all_sg_ids[@]}))

#     unused_sg_count=${#unused_sg[@]}
#     echo "Unused SGs for $region: $unused_sg_count"

#     if [[ $unused_sg_count -eq 1 ]]; then
#         sg_id=${unused_sg[0]}
#         sg_name=$(aws ec2 describe-security-groups --group-ids $sg_id --region $region --query 'SecurityGroups[0].GroupName' --output text)

#         if [[ $sg_name == "default" ]]; then
#             echo "Only the default security group is unused in $region, no file will be written."
#             echo "#################################################################"
#             echo "#################################################################"
#             return
#         fi
#     fi

#     unused_sg_file="unused_sg_$region.csv"
#     echo "VPC ID,Security Group ID,Security Group Name" > $unused_sg_file

#     for sg_id in ${unused_sg[@]}; do
#         sg_details=$(aws ec2 describe-security-groups --group-ids $sg_id --region $region --query 'SecurityGroups[0]' --output json)

#         if [[ -n $sg_details ]]; then
#             vpc_id=$(echo $sg_details | jq -r '.VpcId')
#             sg_name=$(echo $sg_details | jq -r '.GroupName')

#             echo "$vpc_id,$sg_id,$sg_name" >> $unused_sg_file
#         else 
#             echo "No details for SG_ID: $sg_id"
#         fi
#     done
# }

# enabled_regions=$(get_enabled_regions)

# for region in ${enabled_regions[@]}; do
#     process_region $region
# done

# echo "Script completed"