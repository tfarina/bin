#!/bin/bash

# Configuration
BACKUP_LABEL="KINGSTON_X1"
MOUNT_POINT="/media/$USER/$BACKUP_LABEL"
DEST_BASE="$MOUNT_POINT/backups/gateway-mt6707/lp2/home-tfarina"
LATEST="$DEST_BASE/rsync-latest"
LOGFILE="$HOME/personal_rsync_backup.log"
DATE_FMT="%Y-%m-%d %H:%M:%S"
START_TIME="$(date "+$DATE_FMT")"

# Directories inside my home to backup
HOME_DIRS=(
    "Archives"
    "Bookmarks"
    "Documents"
    "Music"
    "Notes"
    "Pictures"
    "Resources"
    "Videos"
    ".secure"
)

# Helpers
ts() { date "+$DATE_FMT"; }
log() { printf '[%s] %s\n' "$(ts)" "$*" | tee -a "$LOGFILE" ; }

# Check if backup drive is mounted
if ! mountpoint -q "$MOUNT_POINT"; then
    log "ERROR: Backup drive '$BACKUP_LABEL' not mounted at $MOUNT_POINT"
    exit 1
fi

# Calculate total size of folders to back up
total_size=$(du -sb "${HOME_DIRS[@]/#/$HOME/}" 2>/dev/null | awk '{sum += $1} END {print sum}')

# Get total size of USB drive (in bytes)
usb_space=$(df --output=size -B1 "$MOUNT_POINT" | tail -1)

echo "Total backup size: $total_size bytes"
echo "Available space (USB drive): $usb_space bytes"

if (( total_size > usb_space )); then
    log "ERROR: Not enough free space on $BACKUP_LABEL for backup."
    echo "Required: $total_size bytes, Available: $usb_space bytes"
    exit 1
fi

log "Starting backup..."

# Determine if dry run or real run
if [[ "$1" == "--go" ]]; then
    DRYRUN_FLAG=""
    RUN_TYPE="REAL RUN"
else
    DRYRUN_FLAG="--dry-run"
    RUN_TYPE="DRY RUN (no changes)"
fi

log "Running backup script ($RUN_TYPE)"

# Make sure destination base and latest folder exist
mkdir -p "$LATEST"

# Loop through each directory and rsync it
for dir in "${HOME_DIRS[@]}"; do
    SRC="$HOME/$dir/"
    DEST="$LATEST/$dir/"
    log "Syncing $SRC -> $DEST"
    rsync -avh --delete --exclude='ISO/' $DRYRUN_FLAG "$SRC" "$DEST" >> "$LOGFILE" 2>&1
done

END_TIME="$(ts)"

# info.txt: metadata about this backup
INFO_FILE="$MOUNT_POINT/backups/gateway-mt6707/lp2/info.txt"
cat > "$INFO_FILE" <<EOF
Backup Drive for: Thiago's Gateway MT6707
Purpose: Personal backups (Linux home directory)
Method: rsync, with --archive and --delete options
Mount Point: $MOUNT_POINT
Backup Path (latest): $LATEST
Backup Started: $START_TIME
Backup Finished: $END_TIME
EOF

log "Backup script ($RUN_TYPE) completed."
echo "--------------------------------------------------------" >> "$LOGFILE"
