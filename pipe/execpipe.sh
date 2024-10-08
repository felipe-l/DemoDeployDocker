#!/bin/bash

# Navigate to the script's directory
cd "$(dirname "$0")" || exit 1  # Exit if changing directory fails

# Use a while loop to execute commands from the named pipe
while true; do
    eval "$(cat mypipe)"  # Execute commands from the pipe
done