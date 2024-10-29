#! /bin/bash
# set -x 

file1="sg_anywhere_inbound_eu-west-1.csv"
file2="unused_sg_eu-west-1.csv"

sg_ids_file1=$(awk -F, 'NR>1 {print $2}' "$file1" | sort)
sg_ids_file2=$(awk -F, 'NR>1 {print $2}' "$file2" | sort)

# Initialize a flag to check for matches
match_found=false

# Loop through each Security Group ID in file1 and check if it exists in file2
for sg_id in $sg_ids_file1; do
    if echo "$sg_ids_file2" | grep -q "$sg_id"; then
        echo "Security Group ID $sg_id from $file1 is found in $file2."
        match_found=true
    fi
done

# If no matches are found, print a message
if [ "$match_found" = false ]; then
    echo "No Security Group IDs from $file1 are found in $file2."
fi