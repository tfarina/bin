#!/bin/bash

# Configuration
BACKUP_LABEL="KINGSTON_X1"
MOUNT_POINT="/media/$USER/$BACKUP_LABEL"
DEST_BASE="$MOUNT_POINT/backups/gateway-mt6707/lp2/home-tfarina"
LATEST="$DEST_BASE/rsync-latest"
LOGFILE="$HOME/personal_rsync_backup.log"
DATE=$(date "+%Y-%m-%d %H:%M:%S")

# Directories inside my home to backup
HOME_DIRS=(
    "Archives"
    "Backups"
    "Music"
    "Notes"
    "Pictures"
    "Resources"
    ".secure"
    # "Documents"  # excluded due to size
    # "Videos"     # excluded due to size
    # "src"        # excluded due to size
)

# Check if backup drive is mounted
if ! mountpoint -q "$MOUNT_POINT"; then
    echo "[$DATE] ERROR: Backup drive '$BACKUP_LABEL' not mounted at $MOUNT_POINT" | tee -a "$LOGFILE"
    exit 1
fi

echo "[$DATE] Starting backup..." | tee -a "$LOGFILE"

# Determine if dry run or real run
if [[ "$1" == "--go" ]]; then
    DRYRUN_FLAG=""
    RUN_TYPE="REAL RUN"
else
    DRYRUN_FLAG="--dry-run"
    RUN_TYPE="DRY RUN (no changes)"
fi

echo "[$DATE] Running backup script ($RUN_TYPE)" | tee -a "$LOGFILE"

# Make sure destination base and latest folder exist
mkdir -p "$LATEST"

# Loop through each directory and rsync it
for dir in "${HOME_DIRS[@]}"; do
    SRC="$HOME/$dir/"
    DEST="$LATEST/$dir/"
    echo "[$DATE] Syncing $SRC -> $DEST" | tee -a "$LOGFILE"
    rsync -avh --delete $DRYRUN_FLAG "$SRC" "$DEST" >> "$LOGFILE" 2>&1
done

echo "[$DATE] Backup script ($RUN_TYPE) completed." | tee -a "$LOGFILE"
echo "--------------------------------------------------------" >> "$LOGFILE"
