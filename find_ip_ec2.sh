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
  
  ### EC2 Instances
  echo "Checking EC2 Instances..."
  
  # Retrieve all EC2 instances in the region
  ec2_result=$(aws ec2 describe-instances --region "$region" --query "Reservations[].Instances[].[InstanceId, NetworkInterfaces[].PrivateIpAddresses[].PrivateIpAddress, NetworkInterfaces[].Association.PublicIp]" --output json)

  found_public_ips=()
  found_private_ips=()

  # Loop through the results to check for matching IPs
  for instance in $(echo "$ec2_result" | jq -c '.[]'); do
    instance_id=$(echo "$instance" | jq -r '.[0]')
    private_ips=$(echo "$instance" | jq -r '.[1][]?')
    public_ips=$(echo "$instance" | jq -r '.[2][]?')

    # Check for matches
    if [[ "$public_ips" == *"$IP_ADDRESS"* ]]; then
      found_public_ips+=("$instance_id")
    fi

    if [[ "$private_ips" == *"$IP_ADDRESS"* ]]; then
      found_private_ips+=("$instance_id")
    fi
  done

  # Check if any instances were found
  if [[ ${#found_public_ips[@]} -eq 0 && ${#found_private_ips[@]} -eq 0 ]]; then
    # echo "No matching EC2 instances found in region $region."
    echo "###########################################################################################"
    echo
    continue
  fi

  # Output results for public IPs
  if [[ ${#found_public_ips[@]} -gt 0 ]]; then
    echo "Found EC2 instances with public IP $IP_ADDRESS in region $region: ${found_public_ips[*]}"
    echo "###########################################################################################"
    echo
  fi

  # Output results for private IPs
  if [[ ${#found_private_ips[@]} -gt 0 ]]; then
    echo "Found EC2 instances with private IP $IP_ADDRESS in region $region: ${found_private_ips[*]}"
    echo "###########################################################################################"
    echo
  fi
done

