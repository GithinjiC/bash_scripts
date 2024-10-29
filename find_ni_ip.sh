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
  
    ### ni Gateways
  echo "Checking Network Interfaces..."

  ni_result=$(aws ec2 describe-network-interfaces --region "$region" --query "NetworkInterfaces[].[Attachment.AttachmentId, InterfaceType, PrivateIpAddresses[].PrivateIpAddress, PrivateIpAddresses[].Association[].PublicIp, Status]" --output json)

  found_public_ips=()
  found_private_ips=()

    for ni in $(echo "$ni_result" | jq -c '.[]'); do
    ni_attachment_id=$(echo "$ni" | jq -r '.[0]')
    ni_interface_type=$(echo "$ni" | jq -r '.[1]')
    ni_private_ips=$(echo "$ni" | jq -r '.[2][]?')
    ni_public_ips=$(echo "$ni" | jq -r '.[3][]?')
    ni_status=$(echo "$ni" | jq -r '.[4]')

    # Check for matches
    if [[ "$ni_public_ips" == *"$IP_ADDRESS"* ]]; then
      found_public_ips+=("Network Interface: $ni_attachment_id Status: $ni_status")
    fi

    if [[ "$ni_private_ips" == *"$IP_ADDRESS"* ]]; then
      found_private_ips+=("Network Interface: $ni_attachment_id Status: $ni_status")
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