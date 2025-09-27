#!/bin/bash

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <file_name_to_search>"
    exit 1
fi

LOG_FILE="search_buckets.log"

# Clear the log file at the start of the script
> "$LOG_FILE"

# Function to log messages
log_message() {
    local message="$1"
    echo "$message"
    # echo "$message" | tee -a "$LOG_FILE"
}

# Function to search for a file in all buckets
search_file_in_all_buckets() {
    local search_file="$1"

    if [[ -z "$search_file" ]]; then
        log_message "Error: No file name provided for search." | tee -a "$LOG_FILE"
        exit 1
    fi

    log_message "Starting search for file: $search_file across all buckets in your AWS account." | tee -a "$LOG_FILE"

    buckets=($(aws s3api list-buckets --query 'Buckets[].Name' --output text))
    excluded_buckets=("aws-cspm-cloudtrail-logs-241355714281-3d225976" "config-bucket-241355714281" "directpay-accesslogs" "directpay-cloudtrail" "directpay-s3-access")
    filtered_buckets=()

    if [[ -z "$buckets" ]]; then
        log_message "No buckets found in your AWS account." | tee -a "$LOG_FILE"
        exit 1
    fi

    for bucket in "${buckets[@]}"; do
    exclude=false

    # Check if the current bucket is in the removal list
    for excluded_bucket in "${excluded_buckets[@]}"; do
        if [ "$bucket" == "$excluded_bucket" ]; then
        exclude=true
        break
        fi
    done

    # If the bucket is not to be excluded, add it to the result
    if [ "$exclude" == false ]; then
        filtered_buckets+=("$bucket")
    fi
    done

# echo "Updated buckets:"
# for bucket in "${filtered_buckets[@]}"; do
#   echo "$bucket"
# done
# }
    log_message "Number of buckets to be checked: ${#filtered_buckets[@]} out of ${#buckets[@]}"
    
    for bucket in "${filtered_buckets[@]}"; do
        log_message "Checking bucket: $bucket" | tee -a "$LOG_FILE"

        files=$(aws s3api list-objects --bucket "$bucket" --query 'Contents[].Key' --output text 2>/dev/null)

        if [[ -z "$files" ]]; then
            log_message "  - Bucket $bucket is empty or inaccessible."
            continue
        fi

        file_found=false

        # Iterate through all files and folders
        for file in $files; do
            # log_message "  - Visiting file/folder: $file" | tee -a "$LOG_FILE"
            log_message "  - Visiting file/folder: $file" >> "$LOG_FILE"

            # Check if the current file matches the search file
            if [[ "$file" == *"$search_file"* ]]; then
                log_message "  --> File found: $file in bucket: $bucket" | tee -a "$LOG_FILE"
                file_found=true
                break
            fi
        done

        # Log if the file was not found in the bucket
        if [[ "$file_found" == false ]]; then
            log_message "  - File $search_file not found in bucket: $bucket" | tee -a "$LOG_FILE"
        fi
    done

    log_message "Search completed for file: $search_file." | tee -a "$LOG_FILE"
}

search_file_in_all_buckets "$1"
