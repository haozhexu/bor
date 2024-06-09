#!/bin/bash

# Check if the pattern and suffix arguments are provided
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: $0 'pattern' 'suffix'"
    echo "Example: $0 '*.jpg' '_bor'"
    exit 1
fi

# Define the pattern from the first argument
pattern="$1"

# Define the suffix from the second argument
suffix="$2"

# Loop through each file matching the pattern
for input_file in $pattern; do
    # Check if the file exists to avoid processing a non-matching pattern
    if [ ! -f "$input_file" ]; then
        echo "No files found matching the pattern: $pattern"
        exit 1
    fi

    echo "Converting $input_file"

    # Extract the directory path of the input file
    dir_path=$(dirname "$input_file")

    # Extract the base name of the input file (without the directory path and extension)
    base_name=$(basename "$input_file" | cut -f 1 -d '.')

    # Get the file extension
    extension="${input_file##*.}"

    # Define the output file name by appending the suffix to the base name and adding the extension
    output_file="${dir_path}/${base_name}${suffix}.${extension}"

    ./bor.sh -b 5%x10% -e cameramodel,focallength35,fnumber,exptime,isospeed,stripexif $input_file $output_file
    echo "Output $output_file"
done
