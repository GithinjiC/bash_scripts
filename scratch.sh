#! /bin/bash
# set -x 

start=$(date +%s)

if [ -z "$1" ]; then
    echo "Usage: $0 <region>"
    exit 1
fi

REGION=$1
USED_SG_ALL=()
UNUSED_SG=()

# All enabled regions
# ENABLED_REGIONS=$(aws ec2 describe-regions --all-regions --query 'Regions[?OptInStatus==`opt-in-not-required` || OptInStatus==`opted-in`].[RegionName]' --output text --region eu-west-1)

# All VPC IDs
# VPC_IDS=$(aws ec2 describe-vpcs --region $REGION --query 'Vpcs[*].VpcId' --output text)

# ALL security groups
ALL_SG_IDS=$(aws ec2 describe-security-groups --region $REGION --query 'SecurityGroups[*].GroupId' --output text | tr -s '\t' ' ' | tr ' ' '\n' | sort -u)
echo "All SGs for $REGION:  $(for sg in $ALL_SG_IDS; do echo $sg; done | wc -l)"

# Network Interfaces
USED_SG_NIC=$(aws ec2 describe-network-interfaces --region $REGION --query 'NetworkInterfaces[*].Groups[*].GroupId' --output text | tr -s '\t' ' ' | tr ' ' '\n' | sort -u)

# EC2 instances
USED_SG_EC2=$(aws ec2 describe-instances --region $REGION --query 'Reservations[*].Instances[*].SecurityGroups[*].GroupId' --output text)

# Classic LBs 
USED_SG_CLB=$(aws elb describe-load-balancers --region $REGION --query 'LoadBalancerDescriptions[*].SecurityGroups[*]' --output text)

# ALBs, NLBs
USED_SG_LB=$(aws elbv2 describe-load-balancers --region $REGION --query 'LoadBalancers[*].SecurityGroups[*]' --output text)

# ElastiCache
USED_SG_CACHE=$(aws elasticache describe-cache-clusters --region $REGION --query 'CacheClusters[*].SecurityGroups[*].SecurityGroupId' --output text)

# Lambda
USED_SG_LAMBDA=$(aws lambda list-functions --region $REGION --query 'Functions[?VpcConfig.SecurityGroupIds!=`null`].VpcConfig.SecurityGroupIds' --output text)

# RDS
USED_SG_RDS=$(aws rds describe-db-instances --region $REGION --query 'DBInstances[*].VpcSecurityGroups[*].VpcSecurityGroupId' --output text)

# Directory Service
USED_SG_DS=$(aws ds describe-directories --region $REGION --query 'DirectoryDescriptions[*].VpcSettings.SecurityGroupId' --output text)

# Transfer Family
SERVER_IDS=$(aws transfer list-servers --region $REGION --query "Servers[*].ServerId" --output text)
USED_SG_TRANSFER=$(
    for SERVER_ID in $SERVER_IDS; do
        # echo "Server ID: $SERVER_ID"
        SECURITY_GROUPS=$(aws transfer describe-server --server-id $SERVER_ID --region $REGION --query "Server.EndpointDetails.SecurityGroupIds" --output text)
        echo $SECURITY_GROUPS
    done
)
# echo $USED_SG_TRANSFER

# AWS EFS
FILE_SYSTEM_IDS=$(aws efs describe-file-systems --region $REGION --query 'FileSystems[*].FileSystemId' --output text)
USED_SG_EFS=$(
    for FILE_SYSTEM_ID in $FILE_SYSTEM_IDS; do
        # echo "File system ID: $FILE_SYSTEM_ID"
        # "EFS SGs are associated with EFS mount targets"
        SECURITY_GROUPS=$(aws efs describe-mount-targets --file-system-id $FILE_SYSTEM_ID --region $REGION --query 'MountTargets[*].SecurityGroups' --output text)
        echo $SECURITY_GROUPS
    done
)
# echo $USED_SG_EFS

USED_SG_ALL+="$USED_SG_NIC $USED_SG_EC2 $USED_SG_CLB $USED_SG_LB $USED_SG_CACHE $USED_SG_LAMBDA $USED_SG_RDS $USED_SG_DS $USED_SG_TRANSFER $USED_SG_EFS"
USED_SG_ALL=$(echo $USED_SG_ALL | tr -s '\t' ' ' | tr ' ' '\n'| grep -v '^None$' | sort -u)

echo "Used SGs for $REGION: $(for sg in $USED_SG_ALL; do echo $sg; done | wc -l)"

# ============================================================================================ #
# Compare and list unused SGs
# Find unused SGs
for SG_ID in $ALL_SG_IDS; do
    if [[ ! $USED_SG_ALL =~ $SG_ID ]]; then
        UNUSED_SG+=("$SG_ID")
    fi
done 

UNUSED_SG=$(printf "%s\n" "${UNUSED_SG[@]}" | grep -v '^None$' | sort -u)
UNUSED_SG_COUNT=$(echo "$UNUSED_SG" | wc -l)
echo "Unused SGs for $REGION: $UNUSED_SG_COUNT"

create_file=false
UNUSED_SG_FILE="unused_sg_without_rship_$REGION.csv"

for SG_ID in $UNUSED_SG; do
    SG_DETAILS=$(aws ec2 describe-security-groups --group-ids $SG_ID --region $REGION --query 'SecurityGroups[0]' --output json)

    if [[ -n $SG_DETAILS ]]; then
        VPC_ID=$(echo $SG_DETAILS | jq -r '.VpcId')
        SG_NAME=$(echo $SG_DETAILS | jq -r '.GroupName')

        # Check if the SG allows traffic from another SG
        SG_RULES=$(aws ec2 describe-security-groups --region "$REGION" --group-ids "$SG_ID" --query "SecurityGroups[*].IpPermissions[*].UserIdGroupPairs[*].GroupId" --output text)

        # If SG_NAME is "default" and it is the only unused SG, skip writing to file
        if [[ $UNUSED_SG_COUNT -eq 1 && $SG_NAME == "default" ]]; then
            echo "Only the default security group is unused in $REGION, no file will be written."
            break
        elif [[ $SG_NAME != "default" && -n $SG_RULES ]]; then
            # If it's a non-default SG and allows traffic from another SG, write to file
            create_file=true
            echo "VPC ID,Security Group ID,Security Group Name,Allowing Security Group" > $UNUSED_SG_FILE
            echo "$VPC_ID,$SG_ID,$SG_NAME,$SG_RULES" >> $UNUSED_SG_FILE
            break  # Exit the loop once a suitable SG is found
        fi
    else 
        echo "No details for SG_ID: $SG_ID"
    fi
done

# If a suitable security group was found, continue writing the rest to the file
if $create_file; then
    for SG_ID in $UNUSED_SG; do
        SG_DETAILS=$(aws ec2 describe-security-groups --group-ids $SG_ID --region $REGION --query 'SecurityGroups[0]' --output json)

        if [[ -n $SG_DETAILS ]]; then
            VPC_ID=$(echo $SG_DETAILS | jq -r '.VpcId')
            SG_NAME=$(echo $SG_DETAILS | jq -r '.GroupName')

            # Check if the SG allows traffic from another SG
            SG_RULES=$(aws ec2 describe-security-groups --region "$REGION" --group-ids "$SG_ID" --query "SecurityGroups[*].IpPermissions[*].UserIdGroupPairs[*].GroupId" --output text)

            if [[ $SG_NAME != "default" && -n $SG_RULES ]]; then
                echo "$VPC_ID,$SG_ID,$SG_NAME,$SG_RULES" >> $UNUSED_SG_FILE
            fi
        else 
            echo "No details for SG_ID: $SG_ID"
        fi
    done
fi 

# for SG_ID in $UNUSED_SG; do
#     SG_DETAILS=$(aws ec2 describe-security-groups --group-ids $SG_ID --region $REGION --query 'SecurityGroups[0]' --output json)

#     if [[ -n $SG_DETAILS ]]; then
#         VPC_ID=$(echo $SG_DETAILS | jq -r '.VpcId')
#         SG_NAME=$(echo $SG_DETAILS | jq -r '.GroupName')

#         if [[ $UNUSED_SG_COUNT -eq 1 && $SG_NAME == "default" ]]; then
#             echo "Only the default security group is unused in $REGION, no file will be written."
#             break
#         else
#             create_file=true  # Set the flag to true if a non-default SG is found
#             break  # Exit the loop once a non-default SG is found
#         fi
#     else 
#         echo "No details for SG_ID: $SG_ID"
#     fi
# done

# # Create and write to the file only if a non-default SG was found
# if $create_file; then
#     UNUSED_SG_FILE="unused_sg_$REGION.csv"
#     echo "VPC ID,Security Group ID,Security Group Name" > $UNUSED_SG_FILE

#     for SG_ID in $UNUSED_SG; do
#         SG_DETAILS=$(aws ec2 describe-security-groups --group-ids $SG_ID --region $REGION --query 'SecurityGroups[0]' --output json)
        
#         if [[ -n $SG_DETAILS ]]; then
#             VPC_ID=$(echo $SG_DETAILS | jq -r '.VpcId')
#             SG_NAME=$(echo $SG_DETAILS | jq -r '.GroupName')

#             if [[ $SG_NAME != "default" ]]; then
#                 echo "$VPC_ID,$SG_ID,$SG_NAME" >> $UNUSED_SG_FILE
#             fi
#         else 
#             echo "No details for SG_ID: $SG_ID"
#         fi
#     done
# fi

# ============================================================================================ #
# Get SG with inbound rule 0.0.0.0/0. Output to file.
INBOUND_FILE="sg_anywhere_inbound_$REGION.csv" 
ALL_SG_DATA=$(aws ec2 describe-security-groups --region $REGION --query 'SecurityGroups[*].[GroupId,GroupName,VpcId,IpPermissions]' --output json)
# echo "All SG Data:  $(echo $ALL_SG_DATA | jq '. | length')"
found_flag=false
echo $ALL_SG_DATA | jq -c '.[]' | while read -r sg; do
    SG_ID=$(echo $sg | jq -r '.[0]')
    SG_NAME=$(echo $sg | jq -r '.[1]')
    VPC_ID=$(echo $sg | jq -r '.[2]')
    
    SG_WITH_ANYWHERE_INBOUND=$(echo $sg | jq -c '.[3][] | select(.IpRanges[]?.CidrIp == "0.0.0.0/0") | {FromPort, ToPort, IpRanges: [.IpRanges[].CidrIp], IpProtocol}')

    if [[ -n $SG_WITH_ANYWHERE_INBOUND ]]; then
        if [[ $found_flag == false ]]; then
            echo "VPC ID,Security Group ID,From Port,To Port,IP Ranges,IP Protocol,Security Group Name" > $INBOUND_FILE
            found_flag=true
        fi
        echo $SG_WITH_ANYWHERE_INBOUND | jq -r --arg VPC_ID "$VPC_ID" --arg SG_ID "$SG_ID" --arg SG_NAME "$SG_NAME" '"\($VPC_ID),\($SG_ID),\(.FromPort),\(.ToPort),\(.IpRanges[]),\(.IpProtocol),\($SG_NAME)"' >> $INBOUND_FILE
    else
        echo "$SG_ID in $REGION doesn't have open inbound rule"
    fi
done

# ============================================================================================ #

echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="

end=$(date +%s)
echo "Total Elapsed for $REGION: $((end - start))s"
