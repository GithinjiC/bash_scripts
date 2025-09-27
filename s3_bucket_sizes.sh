# #!/bin/bash

# # Script to check and return the size of all S3 buckets in the AWS account.

# # Ensure AWS CLI is installed and configured
# if ! command -v aws &> /dev/null; then
#   echo "Error: AWS CLI not found. Please install and configure AWS CLI."
#   exit 1
# fi

# # Function to calculate bucket size
# calculate_bucket_size() {
#   local bucket_name=$1
#   local region=$2
  
#   echo "Processing bucket: $bucket_name (Region: $region)..."
  
#   # Get total size and object count
#   SIZE_OUTPUT=$(aws s3api list-objects-v2 --bucket "$bucket_name" --region "$region" --query "[sum(Contents[].Size), length(Contents[])]" --output text)

#   # Extract size and count
#   TOTAL_SIZE=$(echo "$SIZE_OUTPUT" | awk '{print $1}')
#   OBJECT_COUNT=$(echo "$SIZE_OUTPUT" | awk '{print $2}')

#   # Handle empty buckets
#   TOTAL_SIZE=${TOTAL_SIZE:-0}
#   OBJECT_COUNT=${OBJECT_COUNT:-0}

#   # Convert size to human-readable format
#   HUMAN_READABLE_SIZE=$(numfmt --to=iec --suffix=B "$TOTAL_SIZE")

#   echo "Bucket: $bucket_name"
#   echo "  Total Objects: $OBJECT_COUNT"
#   echo "  Total Size: $HUMAN_READABLE_SIZE ($TOTAL_SIZE bytes)"
#   echo "--------------------------------------"
# }

# # Get a list of all buckets
# echo "Fetching list of buckets..."
# BUCKET_LIST=$(aws s3api list-buckets --query "Buckets[].Name" --output text)

# if [ -z "$BUCKET_LIST" ]; then
#   echo "No buckets found in your AWS account."
#   exit 0
# fi

# # Process each bucket
# # for BUCKET in $BUCKET_LIST; do
# #   # Determine the bucket's region
# #   REGION=$(aws s3api get-bucket-location --bucket "$BUCKET" --query "LocationConstraint" --output text)
# #   REGION=${REGION:-us-east-1} # Default to us-east-1 for null/empty region

# #   # Calculate and display the bucket size
# #   calculate_bucket_size "$BUCKET" "$REGION"
# # done

# calculate_bucket_size "processing.onz" "eu-west-1"

# echo "Bucket size calculation completed."


#!/bin/bash

# Check for input arguments
# if [ "$#" -ne 2 ]; then
#   echo "Usage: $0 <bucket_name> <region>"
#   exit 1
# fi

# BUCKET_NAME=$1
# REGION=$2

# # Initialize counters
# TOTAL_SIZE=0
# OBJECT_COUNT=0

# # Paginate through all objects in the bucket
# NEXT_TOKEN=""
# while : ; do
#   if [ -z "$NEXT_TOKEN" ]; then
#     # First API call without a continuation token
#     OUTPUT=$(aws s3api list-objects-v2 --bucket "$BUCKET_NAME" --region "$REGION" --query 'Contents[].[Size]' --output text)
#   else
#     # Subsequent API calls with continuation token
#     # OUTPUT=$(aws s3api list-objects-v2 --bucket "$BUCKET_NAME" --region "$REGION" --query 'Contents[].[Size]' --output text --starting-token "$NEXT_TOKEN")
#     OUTPUT=$(aws s3api list-objects-v2 --bucket "$BUCKET_NAME" --region "$REGION" --query 'Contents[].[Size]' --output text --continuation-token "$NEXT_TOKEN")
#   fi

#   # Check if AWS CLI command failed
#   if [ $? -ne 0 ]; then
#     echo "Error retrieving bucket contents. Check the bucket name and permissions."
#     exit 1
#   fi

#   # Add sizes and count objects
#   for size in $OUTPUT; do
#     TOTAL_SIZE=$((TOTAL_SIZE + size))
#     OBJECT_COUNT=$((OBJECT_COUNT + 1))
#   done

#   # Check for next continuation token
#   NEXT_TOKEN=$(aws s3api list-objects-v2 --bucket "$BUCKET_NAME" --region "$REGION" --query 'NextContinuationToken' --output text)
#   if [ "$NEXT_TOKEN" == "None" ] || [ -z "$NEXT_TOKEN" ]; then
#     break
#   fi
# done

# # Convert size to MB
# SIZE_MB=$(echo "scale=2; $TOTAL_SIZE / 1048576" | bc)

# # Output results
# echo "Bucket Name: $BUCKET_NAME"
# echo "Total Objects: $OBJECT_COUNT"
# echo "Total Size: ${SIZE_MB} MB"


#!/bin/bash

BUCKET_NAME="processing.onz"
PREFIX=""  # Specify a prefix if needed
REGION="eu-west-1"

CONTINUATION_TOKEN=""
TOTAL_SIZE=0
OBJECT_COUNT=0

echo "Listing objects in bucket: $BUCKET_NAME"

while true; do
  # Make the AWS CLI call with continuation token if present
  if [ -z "$CONTINUATION_TOKEN" ]; then
    RESPONSE=$(aws s3api list-objects-v2 \
      --bucket "$BUCKET_NAME" \
      --prefix "$PREFIX" \
      --region "$REGION")
  else
    RESPONSE=$(aws s3api list-objects-v2 \
      --bucket "$BUCKET_NAME" \
      --prefix "$PREFIX" \
      --region "$REGION" \
      --continuation-token "$CONTINUATION_TOKEN")
  fi

  # Extract object keys and sizes
  KEYS=$(echo "$RESPONSE" | jq -r '.Contents[]?.Key // empty')
  SIZES=$(echo "$RESPONSE" | jq -r '.Contents[]?.Size // 0')

  # Increment object count and total size
  for size in $SIZES; do
    TOTAL_SIZE=$((TOTAL_SIZE + size))
    OBJECT_COUNT=$((OBJECT_COUNT + 1))
  done

  # Output object keys (optional)
  for key in $KEYS; do
    echo "Found object: $key"
  done

  # Check for NextContinuationToken
  CONTINUATION_TOKEN=$(echo "$RESPONSE" | jq -r '.NextContinuationToken // empty')
  if [ -z "$CONTINUATION_TOKEN" ]; then
    break
  fi
done


SIZE_MB=$(echo "scale=2; $TOTAL_SIZE / 1048576" | bc)

echo "Total objects: $OBJECT_COUNT"
echo "Total size (bytes): $SIZE_MB MBs"
