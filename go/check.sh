# #!/bin/bash

# # Function to get CPU usage on macOS
# get_cpu_usage() {
#     # Get the full CPU stats using 'top' command
#     top_output=$(top -l 1)

#     # Extract the CPU idle percentage
#     cpu_idle=$(echo "$top_output" | grep -o 'CPU usage: [^)]*' | awk '{print $3}' | sed 's/%//')

#     # Check if the cpu_idle value is not empty or invalid
#     if [[ -z "$cpu_idle" ]] || ! [[ "$cpu_idle" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
#         echo "Failed to get CPU idle percentage"
#         exit 1
#     fi

#     # Calculate CPU usage percentage (100 - idle percentage)
#     cpu_usage=$(echo "scale=2; 100 - $cpu_idle" | bc)

#     # Return CPU usage
#     echo "$cpu_usage"
# }

# # Function to restart a service if CPU usage is above a threshold
# check_and_restart_service() {
#     local cpu_usage=$1
#     local threshold=80
#     local service_name="mysql" # Replace with the service you want to restart

#     if (( $(echo "$cpu_usage > $threshold" | bc -l) )); then
#         echo "CPU usage ($cpu_usage%) is above $threshold%. Restarting $service_name..."
        
#         # Restart the service (macOS example: using `brew services restart` or launchctl)
#         # sudo launchctl stop "$service_name"
#         # sudo launchctl start "$service_name"

#         brew services restart $service_name

#         echo "$service_name has been restarted."
#     else
#         echo "CPU usage ($cpu_usage%) is within acceptable limits."
#     fi
# }

# # Main script execution
# cpu_usage=$(get_cpu_usage)
# echo "Current CPU Usage: $cpu_usage%"

# # Check and restart service if needed
# check_and_restart_service "$cpu_usage"


get_cpu_usage() {
    # Get the full CPU stats using 'top' command
    top_output=$(top -l 1 | grep "CPU usage")

    # Debug: Print the raw CPU usage line
    echo "Raw CPU usage line: $top_output"

    # Extract the idle percentage
    cpu_idle=$(echo "$top_output" | awk -F "idle" '{print $1}' | awk '{print $NF}' | sed 's/%//')

    # Debug: Print the extracted idle percentage
    echo "Extracted CPU idle percentage: $cpu_idle"

    # Check if the cpu_idle value is not empty or invalid
    if [[ -z "$cpu_idle" ]] || ! [[ "$cpu_idle" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        echo "Failed to get CPU idle percentage"
        exit 1
    fi

    # Calculate CPU usage percentage (100 - idle percentage)
    cpu_usage=$(echo "scale=2; 100 - $cpu_idle" | bc)

    # Return CPU usage
    echo "$cpu_usage"
}

get_cpu_usage