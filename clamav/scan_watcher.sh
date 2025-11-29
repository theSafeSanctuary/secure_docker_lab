#!/bin/bash
# Directories
WATCH_DIR="/scandata"        # Mounted volume shared with SFTP container
QUARANTINE_DIR="/quarantine" # Local directory to isolate threats

echo " Waiting for ClamD socket..."
# We loop until the ClamAV daemon is fully loaded and listening. 
# Attempting to scan before the daemon is ready would result in errors.
while; do 
    sleep 1
done
echo " ClamD is ready. Starting inotify..."

# Start the Inotify Watcher
# -m: Monitor indefinitely (don't exit after first event)
# -r: Recursive (watch subdirectories)
# -e close_write: ONLY trigger when a file is finished writing.
#     Triggering on 'create' is dangerous because the upload might be incomplete.
#     'close_write' ensures the SFTP server has finished writing the file.
inotifywait -m -r -e close_write --format '%w%f' "$WATCH_DIR" | while read FILE
do
    echo " New file detected: $FILE" | logger -t "AV_WATCHER"
    
    # Run the scan using 'clamdscan' (Client) not 'clamscan' (Standalone).
    # - clamdscan: fast, sends file descriptor to the running daemon.
    # - clamscan: slow, has to load the virus DB into memory every single time.
    # --fdpass: Pass file descriptor permissions. Crucial when running as root
    #           but the daemon runs as 'clamav'.
    # --move:   Automatically move infected files out of the share to quarantine.
    clamdscan --fdpass --move="$QUARANTINE_DIR" --no-summary "$FILE"
    
    # Check return code (1 = Virus Found)
    if [ $? -eq 1 ]; then
        echo " Malware detected in $FILE. Moved to Quarantine." | logger -p local0.crit -t "AV_ALERT"
    fi
done