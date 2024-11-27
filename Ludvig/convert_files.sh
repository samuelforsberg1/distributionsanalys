#!/bin/bash

# Get the current directory
directory=$(pwd)

# Loop through all .txt files in the directory
for filename in "$directory"/*.txt; do
  # Extract the base name of the file
  base=$(basename "$filename")
  # Check if the filename contains two dots
  if [[ "$base" == *.*.* ]]; then
    # Remove the first dot
    new_base="${base/./}"
    echo "$new_base"
    # Construct the full file paths
    old_file="$directory/$base"
    new_file="$directory/$new_base"
    # Rename the file
    mv "$old_file" "$new_file"
  fi
done

echo "Filenames updated successfully!"
