#!/bin/bash
# Directories
WATCH_DIR="/scandata"        # Mounted volume shared with SFTP container
QUARANTINE_DIR="/quarantine" # Local directory to isolate threats

echo "Waiting for ClamD socket..."
# We wait for the ClamAV Daemon to start. Scanning fails if the daemon isn't ready.
while; do sleep 1; done
echo "ClamD is ready."

# Start the Inotify Watcher
# -m: Monitor indefinitely (don't exit after first event)
# -r: Recursive (watch subdirectories)
# -e close_write: ONLY trigger when a file is finished writing.
#     If we triggered on 'create' or 'modify', we might scan a file
#     that is currently being uploaded (incomplete), causing errors.
inotifywait -m -r -e close_write --format '%w%f' "$WATCH_DIR" | while read FILE
do
    echo "New file detected: $FILE" | logger -t "AV_WATCHER"
    
    # Run the scan
    # --fdpass: Pass file descriptor permissions. Crucial when running as
    #           different users (sftp user vs clamav user).
    # --move:   Automatically move infected files out of the share.
    clamdscan --fdpass --move="$QUARANTINE_DIR" --no-summary "$FILE"
    
    # Check return code (1 = Virus Found)
    if [ $? -eq 1 ]; then
        echo " Malware detected in $FILE. Moved to Quarantine." | logger -p local0.crit -t "AV_ALERT"
    fi
done