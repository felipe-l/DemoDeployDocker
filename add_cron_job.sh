#!/bin/bash

# Define the cron job with a relative path
CRON_JOB="@reboot /bin/bash $(dirname "$0")/pipe/execpipe.sh >> $(dirname "$0")/pipe/execpipe.log 2>&1"

# Check if the cron job already exists
if sudo crontab -l 2>/dev/null | grep -F -q "$CRON_JOB"; then
    echo "Cron job already exists in root's crontab."
else
    # If it doesn't exist, add the cron job
    (sudo crontab -l 2>/dev/null; echo "$CRON_JOB") | sudo crontab -
    echo "Cron job added to root's crontab."

    # Run execpipe.sh immediately in the background and redirect output to execpipe.log
    echo "Running execpipe.sh now in the background..."
    (sudo /bin/bash "$(dirname "$0")/pipe/execpipe.sh" >> "$(dirname "$0")/pipe/execpipe.log" 2>&1 &)
fi
