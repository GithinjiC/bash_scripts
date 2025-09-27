#!/bin/bash

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <bucket_name> <file_name> <region>"
  exit 1
fi

BUCKET_NAME=$1
FILE_NAME=$2
REGION=$3

LOG_FILE="s3_bucket_search.log"

# Clear and initialize log file
> "$LOG_FILE"
echo "Searching for file '$FILE_NAME' in bucket '$BUCKET_NAME'" | tee -a  "$LOG_FILE"

# Recursive function to search through the bucket
search_bucket() {
  local prefix=$1
  echo "Visiting folder: $prefix" >> "$LOG_FILE"

  # List objects in the current prefix
  OUTPUT=$(aws s3api list-objects-v2 --bucket "$BUCKET_NAME" --prefix "$prefix" --region "$REGION" --delimiter '/' 2>&1)

  # Check if the AWS CLI command failed
  if [ $? -ne 0 ]; then
    echo "Error: Failed to list objects in prefix '$prefix'. AWS CLI output: $OUTPUT" | tee -a "$LOG_FILE"
    return
  fi

  # Process the output safely with jq
  COMMON_PREFIXES=$(echo "$OUTPUT" | jq -r '.CommonPrefixes[]?.Prefix // empty')
  CONTENTS=$(echo "$OUTPUT" | jq -r '.Contents[]?.Key // empty')

  # Iterate over folders
  if [ -n "$COMMON_PREFIXES" ]; then
    echo "$COMMON_PREFIXES" | while read -r folder; do
      search_bucket "$folder"
    done
  fi

  # Iterate over files
  if [ -n "$CONTENTS" ]; then
    echo "$CONTENTS" | while read -r file; do
      if [[ $file == *"$FILE_NAME"* ]]; then
        echo "File found: $file" | tee -a "$LOG_FILE"
        exit 0
      fi
    done
  fi
}

# Start searching from the root
search_bucket ""

# Check if the file was found
if ! grep -q "File found:" "$LOG_FILE"; then
  echo "File '$FILE_NAME' not found in bucket '$BUCKET_NAME'." | tee -a "$LOG_FILE"
fi

echo "Search completed. Logs are available in '$LOG_FILE'." | tee -a "$LOG_FILE"

# BUCKETS=$(aws s3 ls)