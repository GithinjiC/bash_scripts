#! /bin/bash
# set -x


# PROFILES=$(aws configure list-profiles)
# ENABLED_REGIONS=$(aws ec2 describe-regions --all-regions --query 'Regions[?OptInStatus==`opt-in-not-required` || OptInStatus==`opted-in`].[RegionName]' --region eu-west-1 --output text --profile $1)
# ACCOUNT_NO=$(aws sts get-caller-identity --query "Account" --region eu-west-1 --output text --profile $1)

# find_nlb() {
#     # local region=$1
#     # account_no=$(aws sts get-caller-identity --query "Account" --output text --region $region --profile $p)
#     echo "checking in $region for $PROFILE"
# }

PROFILES=$(aws configure list-profiles)

for p in $PROFILES; do
    start=$(date +%s)
    ENABLED_REGIONS=$(aws ec2 describe-regions --all-regions --query 'Regions[?OptInStatus==`opt-in-not-required` || OptInStatus==`opted-in`].[RegionName]' --region eu-west-1 --output text --profile $p)
    ACCOUNT_NO=$(aws sts get-caller-identity --query "Account" --region eu-west-1 --output text --profile $p)
    nlb_name="dpo-mmc-processing-nlb"
    for region in $ENABLED_REGIONS; do
        # echo "Checking LBs in $region in $p"
        found=$(aws elbv2 describe-load-balancers --region $region --query "LoadBalancers[?contains(LoadBalancerName, '$nlb_name' )].LoadBalancerName" --output text --profile $p)
        if [[ -z $found ]]; then
            # echo "Checking $region in $p"
            # echo "Found nlb in $region in $p"
            continue
        elif [[ -n $found ]]; then
            echo "Found nlb in $region in $p"
            exit 0
        else
            echo "NLB not found"
        fi
    done
    end=$(date +%s)
    echo "Total Elapsed for $p: $((end - start))s"
    echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
    echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
done
