#!/bin/bash

# Define the cron job with a relative path
CRON_JOB="@reboot /bin/bash $(dirname "$0")/pipe/execpipe.sh >> $(dirname "$0")/pipe/execpipe.log 2>&1"

# Check if the cron job exists
if sudo crontab -l 2>/dev/null | grep -F -q "$CRON_JOB"; then
    # Remove the cron job
    (sudo crontab -l 2>/dev/null | grep -v -F "$CRON_JOB") | sudo crontab -
    echo "Cron job removed from root's crontab."
else
    echo "Cron job does not exist in root's crontab."
fi

# Stop any running instances of execpipe.sh
PID=$(pgrep -f "$(dirname "$0")/pipe/execpipe.sh")
if [ -n "$PID" ]; then
    echo "Stopping execpipe.sh with PID: $PID"
    sudo kill $PID
else
    echo "No running instance of execpipe.sh found."
fi
