#!/bin/bash

# Check if the region is provided as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 <region>"
    exit 1
fi

# Extract the region from the command line argument
REGION=$1

# Get all security groups in the specified region
# ALL_SG=$(aws ec2 describe-security-groups --region $REGION --query 'SecurityGroups[*].GroupId' --output text)

# Get security groups in use by EC2 instances in the specified region
# USED_SG_EC2=$(aws ec2 describe-instances --region $REGION --query 'Reservations[*].Instances[*].SecurityGroups[*].GroupId' --output text)

# Get security groups in use by network interfaces in the specified region
# USED_SG_NIC=$(aws ec2 describe-network-interfaces --region $REGION --query 'NetworkInterfaces[*].Groups[*].GroupId' --output text)

# Get security groups in use by load balancers (ELB Classic) in the specified region
# USED_SG_ELB=$(aws elb describe-load-balancers --region $REGION --query 'LoadBalancerDescriptions[*].SecurityGroups[*]' --output text)


# USED_SG_ALB=$(aws elbv2 describe-load-balancers --region eu-west-1 --query 'LoadBalancers[*].SecurityGroups[*]' --output text)

# Get security groups in use by lambdas in the specified region
LAMBDA_FUNCTIONS=$(aws lambda list-functions --region $REGION --query 'Functions[*].FunctionName' --output text)
USED_SG_LAMBDA=""
for FUNCTION_NAME in $LAMBDA_FUNCTIONS; do
    SECURITY_GROUPS=$(aws lambda get-function-configuration --region $REGION --function-name $FUNCTION_NAME --query 'VpcConfig' --output json | jq -r '.SecurityGroupIds[]?')
    #echo "Security Groups for $FUNCTION_NAME:"
    for SG in $SECURITY_GROUPS; do
    	# echo "$SG"
        USED_SG_LAMBDA+="$SG "
    done
# else
#     echo "$FUNCTION_NAME is not associated with a VPC."
    #fi
done
echo -e $USED_SG_LAMBDA

USED_SG_LAMBDA=$(echo -e "$USED_SG_LAMBDA" | tr ' ' '\n' | sort -u | tr '\n' ' ')

# Get security groups in use by rds in the specified region
# RDS_INSTANCES=$(aws rds describe-db-instances --region $REGION --query 'DBInstances[*].DBInstanceIdentifier' --output text)
# USED_SG_RDS=""
# for DB_INSTANCE in $RDS_INSTANCES; do
#     SECURITY_GROUPS=$(aws rds describe-db-instances --region eu-west-1 --db-instance-identifier $DB_INSTANCE --query 'DBInstances[0].VpcSecurityGroups[*].VpcSecurityGroupId' --output json | jq -r '.[]')
#     for SG in $SECURITY_GROUPS; do
#         USED_SG_RDS+="$SG "
#     done
# done
# echo -e $USED_SG_RDS

# get_used_sq_ec2() {
#     local REGION=$1
#     local USED_SG_EC2=""
#     USED_SG_EC2=$(aws ec2 describe-instances --region $REGION --query 'Reservations[*].Instances[*].SecurityGroups[*].GroupId' --output text)
# }


# get_used_sg_lambda() {
#     local REGION=$1
#     local USED_SG_LAMBDA=""
#     LAMBDA_FUNCTIONS=$(aws lambda list-functions --region $REGION --query 'Functions[*].FunctionName' --output text)
#     for FUNCTION_NAME in $LAMBDA_FUNCTIONS; do
#         SECURITY_GROUPS=$(aws lambda get-function-configuration --region $REGION --function-name $FUNCTION_NAME --query 'VpcConfig' --output json | jq -r '.SecurityGroupIds[]?')
#         for SG in $SECURITY_GROUPS; do
#             USED_SG_LAMBDA+="$SG "
#         done
#     done
#     # echo -e $USED_SG_LAMBDA
# }

# get_used_sg_rds() {
#     local REGION=$1
#     local USED_SG_RDS=""
#     RDS_INSTANCES=$(aws rds describe-db-instances --region $REGION --query 'DBInstances[*].DBInstanceIdentifier' --output text)
    
#     for DB_INSTANCE in $RDS_INSTANCES; do
#         SECURITY_GROUPS=$(aws rds describe-db-instances --region eu-west-1 --db-instance-identifier $DB_INSTANCE --query 'DBInstances[0].VpcSecurityGroups[*].VpcSecurityGroupId' --output json | jq -r '.[]')
#         for SG in $SECURITY_GROUPS; do
#             USED_SG_RDS+="$SG "
#         done
#     done
#     # echo -e $USED_SG_RDS | uniq
# }

# # get_used_sg_rds "$REGION"
# # get_used_sg_lambda "$REGION"

# USED_SG_ALL="$(get_used_sg_rds "$REGION") $(get_used_sg_lambda "$REGION")"
# echo "FInal string: $USED_SG_ALL"
# Combine all used security groups
# USED_SG_ALL="$USED_SG_EC2 $USED_SG_ELB $USED_SG_LAMBDA $USED_SG_RDS $USED_SG_ALB"
# USED_SG_ALL="$USED_SG_LAMBDA $USED_SG_RDS"
# echo $USED_SG_ALL | uniq

# #Compare and list unused security groups
# for sg in $ALL_SG; do
#     if [[ ! $USED_SG_ALL =~ $sg ]]; then
#         echo "Unused Security Group: $sg"
#     fi
# done

