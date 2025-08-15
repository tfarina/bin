#!/bin/bash
#
# Backs up ~/src (contains git repositories) to a mounted USB drive
# labeled KINGSTON_X2.
# Default is dry run. Use --go to perform a real backup.
#

# Configuration
SOURCE="$HOME/src"
BACKUP_LABEL="KINGSTON_X2"
MOUNT_POINT="/media/$USER/$BACKUP_LABEL"
DEST_BASE="$MOUNT_POINT/backups/gateway-mt6707/lp2/home-tfarina"
LATEST="$DEST_BASE/rsync-latest"
LOGFILE="$HOME/.logs/backup_git_projects.log"
DATE=$(date "+%Y-%m-%d %H:%M:%S")

# Make sure logs folder exists
mkdir -p "$HOME/.logs"

# Check if backup drive is mounted
if ! mountpoint -q "$MOUNT_POINT"; then
    echo "[$DATE] ERROR: Backup drive '$BACKUP_LABEL' not mounted at $MOUNT_POINT" | tee -a "$LOGFILE"
    exit 1
fi

# Calculate total size of src
total_size=$(du -sb "$SOURCE" 2>/dev/null | awk '{print $1}')

# Get total size of USB drive (in bytes)
usb_capacity=$(df --output=size -B1 "$MOUNT_POINT" | tail -1)

echo "[$DATE] Total backup size: $total_size bytes" | tee -a "$LOGFILE"
echo "[$DATE] USB device total capacity: $usb_capacity bytes" | tee -a "$LOGFILE"

if (( total_size > usb_capacity )); then
    echo "[$DATE] ERROR: Not enough free space on $BACKUP_LABEL for backup." | tee -a "$LOGFILE"
    echo "Required: $total_size bytes, Available: $usb_capacity bytes" | tee -a "$LOGFILE"
    exit 2
fi

# Determine if dry run or real run
if [[ "$1" == "--go" ]]; then
    DRYRUN_FLAG=""
    RUN_TYPE="REAL RUN"
else
    DRYRUN_FLAG="--dry-run"
    RUN_TYPE="DRY RUN (no changes)"
fi

echo "[$DATE] Starting backup ($RUN_TYPE)..." | tee -a "$LOGFILE"

# Make sure destination base and latest folder exist
mkdir -p "$LATEST"

SRC="$SOURCE/"
DEST="$LATEST/src/"
echo "[$DATE] Syncing $SRC -> $DEST" | tee -a "$LOGFILE"
rsync -avh --delete $DRYRUN_FLAG \
      --exclude='node_modules' \
      --exclude='.venv' \
      "$SRC" "$DEST" >> "$LOGFILE" 2>&1

echo "[$DATE] Backup ($RUN_TYPE) completed." | tee -a "$LOGFILE"
echo "---------------------------------------------" >> "$LOGFILE"
