#!/bin/bash

# Get the key values from the azd env get-values command
output=$(azd env get-values)

# Loop through each line of the output
while IFS= read -r line; do
    # Split the line into key and value
    key=$(echo "$line" | cut -d '=' -f 1)
    value=$(echo "$line" | cut -d '=' -f 2-)
    
    # Strip out the double quotes at the beginning and end of the value
    value=$(echo "$value" | sed 's/^"//;s/"$//')
    
    # Export the key and value as environment variables
    export "$key=$value"
done <<< "$output"