#!/bin/bash

DEVICE_LABEL=""
IS_DRY_RUN=true
rsync_options=()

for arg in "$@"; do
    case "$arg" in
        --go)
            IS_DRY_RUN=false
            ;;
        --help|-h)
            echo "Usage: $0 [--go] <LABEL>"
            exit 0
            ;;
        -*)
            echo "Unknown option: $arg" >&2
            echo "Usage: $0 [--go] <LABEL>" >&2
            exit 1
            ;;
        *)
            if [[ -n "$DEVICE_LABEL" ]]; then
                echo "Too many arguments" >&2
                echo "Usage: $0 [--go] <LABEL>" >&2
                exit 1
            fi
            DEVICE_LABEL="$arg"
            ;;
    esac
done

if [[ "$IS_DRY_RUN" == true ]]; then
    rsync_options+=("--dry-run")
fi

if [[ -z "$DEVICE_LABEL" ]]; then
    echo "Usage: $0 [--go] <LABEL>" >&2
    exit 1
fi

host=$(hostname)
MOUNT_POINT="/media/$USER/$DEVICE_LABEL"
DEST_BASE="$MOUNT_POINT/backup/$host/$USER/home"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/personal-rsync-backup"
LOG_FILE="$STATE_DIR/backup.log"
INFO_FILE="$DEST_BASE/info.txt"
DATE_FMT="%Y-%m-%dT%H:%M:%S%z"
START_TIME="$(date "+$DATE_FMT")"

# Directories inside my home to backup
HOME_DIRS=(
    "Archives"
    "Bookmarks"
    "Documents"
    "Library"
    "Music"
    "Notes"
    "Pictures"
    "Videos"
    ".vault"
)

# Helpers
ts() { date "+%Y-%m-%d %H:%M:%S"; }
log() { printf '[%s] %s\n' "$(ts)" "$*" | tee -a "$LOG_FILE" ; }

# Make sure the log directory exists
mkdir -p "$STATE_DIR"

# Check if backup drive is mounted
if ! mountpoint -q "$MOUNT_POINT"; then
    log "ERROR: Backup drive '$DEVICE_LABEL' not mounted at $MOUNT_POINT"
    exit 1
fi

log "Target: $DEVICE_LABEL ($MOUNT_POINT)"

if [[ "$IS_DRY_RUN" == true ]]; then
    log "Mode: DRY RUN - rsync changes will not be applied"
else
    log "Mode: LIVE RUN - rsync changes, including deletions, will be applied"
fi

# Calculate the estimated size of the backup sources.
if ! du_output=$(du -sb -c -- "${HOME_DIRS[@]/#/$HOME/}"); then
    log "ERROR: Could not calculate the backup size; see du errors above."
    exit 1
fi

backup_size=$(awk 'END { print $1 }' <<< "$du_output")

# Get total capacity and available space on the USB filesystem (in bytes).
if ! filesystem_stats=$(df --output=size,avail -B1 "$MOUNT_POINT"); then
    log "ERROR: Could not read USB filesystem capacity and free space."
    exit 1
fi

read -r filesystem_size filesystem_free \
    <<< "$(tail -n 1 <<< "$filesystem_stats")"

log "Estimated backup size: $backup_size bytes"
log "USB filesystem capacity: $filesystem_size bytes"
log "Free space on USB filesystem: $filesystem_free bytes"

if (( backup_size > filesystem_size )); then
    log "ERROR: Estimated backup size exceeds the capacity of $DEVICE_LABEL."
    exit 1
fi

log "Preflight phase completed; starting the backup."

# Make sure destination folder exist
if [[ "$IS_DRY_RUN" == false ]]; then
    mkdir -p "$DEST_BASE"
fi

RSYNC_FAILED=false

# Loop through each directory and rsync it
for dir in "${HOME_DIRS[@]}"; do
    SRC="$HOME/$dir/"
    DEST="$DEST_BASE/$dir/"
    log "Syncing $SRC -> $DEST"
    if rsync -avh --delete --exclude='ISO/' "${rsync_options[@]}" "$SRC" "$DEST" >> "$LOG_FILE" 2>&1; then
        :
    else
        rsync_exit_code=$?
        RSYNC_FAILED=true
        log "ERROR: rsync failed for $SRC (exit code $rsync_exit_code)."
    fi
done

END_TIME="$(date "+$DATE_FMT")"

if [[ "$RSYNC_FAILED" == true ]]; then
    rsync_result="failed"
else
    rsync_result="succeeded"
fi

METADATA_WRITE_FAILED=false

# Write metadata about the completed backup run.
if [[ "$IS_DRY_RUN" == false ]]; then
    if ! cat > "$INFO_FILE" <<EOF
Backup device: $DEVICE_LABEL
Purpose: Personal backup of the Linux home directory
Method: rsync archive; delete destination files absent from source; exclude ISO/ directories
Mount point: $MOUNT_POINT
Backup path: $DEST_BASE
Backup started: $START_TIME
Backup finished: $END_TIME
Rsync result: $rsync_result
EOF
    then
        log "ERROR: Could not write backup metadata to $INFO_FILE."
        METADATA_WRITE_FAILED=true
    fi
fi

if [[ "$IS_DRY_RUN" == true ]]; then
    if [[ "$RSYNC_FAILED" == true ]]; then
        result=1
        log "Dry run finished with one or more rsync errors; no backup changes were applied."
    else
        result=0
        log "Dry run finished successfully; no backup files were changed."
    fi
else
    if [[ "$RSYNC_FAILED" == true ]]; then
        result=1
        if [[ "$METADATA_WRITE_FAILED" == true ]]; then
            log "Backup run finished with one or more rsync errors and the metadata could not be written."
        else
            log "Backup run finished with one or more rsync errors."
        fi
    elif [[ "$METADATA_WRITE_FAILED" == true ]]; then
        result=1
        log "Backup run finished but metadata could not be written."
    else
        result=0
        log "The backup completed successfully."
    fi
fi

echo "--------------------------------------------------------" >> "$LOG_FILE"
exit "$result"
