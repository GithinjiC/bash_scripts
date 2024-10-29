#!/bin/bash
# set -x

# Check if AWS CLI and jq are installed
if ! command -v aws &> /dev/null || ! command -v jq &> /dev/null; then
    echo "Please ensure both AWS CLI and jq are installed."
    exit 1
fi

# Check if an IP is passed as an argument
if [ -z "$1" ]; then
  echo "Usage: ./find_ip_resources.sh <IP_ADDRESS>"
  exit 1
fi

IP_ADDRESS=$1

# Retrieve all enabled regions
regions=$(aws ec2 describe-regions --all-regions --query 'Regions[?OptInStatus==`opt-in-not-required` || OptInStatus==`opted-in`].[RegionName]' --region eu-west-1 --output text)

for region in $regions; do
  echo "Checking resources in region: $region"
  
    ### NAT Gateways
  echo "Checking NAT Gateways..."
  
  # Retrieve all NAT Gateways in the region
  nat_result=$(aws ec2 describe-nat-gateways --region "$region" --query "NatGateways[].[NatGatewayId, NatGatewayAddresses[].PrivateIp, NatGatewayAddresses[].PublicIp]" --output json)

  found_public_ips=()
  found_private_ips=()

  # Loop through NAT results to check for matching IPs
  for nat in $(echo "$nat_result" | jq -c '.[]'); do
    nat_id=$(echo "$nat" | jq -r '.[0]')
    nat_private_ips=$(echo "$nat" | jq -r '.[1][]?')
    nat_public_ips=$(echo "$nat" | jq -r '.[2][]?')

    # Check for matches
    if [[ "$nat_public_ips" == *"$IP_ADDRESS"* ]]; then
      found_public_ips+=("NAT Gateway: $nat_id")
    fi

    if [[ "$nat_private_ips" == *"$IP_ADDRESS"* ]]; then
      found_private_ips+=("NAT Gateway: $nat_id")
    fi
  done

  # Check if any resources were found in the region
  if [[ ${#found_public_ips[@]} -eq 0 && ${#found_private_ips[@]} -eq 0 ]]; then
    echo "No matching resources found in region $region."
    echo "###########################################################################################"
    echo
    continue
  fi

  # Output results for resources with matching public IPs
  if [[ ${#found_public_ips[@]} -gt 0 ]]; then
    echo "Found resources with public IP $IP_ADDRESS in region $region:"
    printf '%s\n' "${found_public_ips[@]}"
    echo "###########################################################################################"
    echo
  fi

  # Output results for resources with matching private IPs
  if [[ ${#found_private_ips[@]} -gt 0 ]]; then
    echo "Found resources with private IP $IP_ADDRESS in region $region:"
    printf '%s\n' "${found_private_ips[@]}"
    echo "###########################################################################################"
    echo
  fi
done

# find an IP from AWS Cliudfront edge locations
# curl https://ip-ranges.amazonaws.com/ip-ranges.json | jq '.prefixes[] | select(.service == "CLOUDFRONT")' | grep 52.