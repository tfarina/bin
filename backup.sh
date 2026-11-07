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

MOUNT_POINT="/media/$USER/$DEVICE_LABEL"
DEST_BASE="$MOUNT_POINT/backups/gateway-mt6707/lp2/home-tfarina"
LATEST="$DEST_BASE/rsync-latest"
LOGFILE="$HOME/.logs/personal_rsync_backup.log"
DATE_FMT="%Y-%m-%d %H:%M:%S"
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
ts() { date "+$DATE_FMT"; }
log() { printf '[%s] %s\n' "$(ts)" "$*" | tee -a "$LOGFILE" ; }

# Make sure logs folder exists
mkdir -p "$HOME/.logs"

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

# Make sure destination base and latest folder exist
if [[ "$IS_DRY_RUN" == false ]]; then
    mkdir -p "$LATEST"
fi

RSYNC_FAILED=false

# Loop through each directory and rsync it
for dir in "${HOME_DIRS[@]}"; do
    SRC="$HOME/$dir/"
    DEST="$LATEST/$dir/"
    log "Syncing $SRC -> $DEST"
    if rsync -avh --delete --exclude='ISO/' "${rsync_options[@]}" "$SRC" "$DEST" >> "$LOGFILE" 2>&1; then
        :
    else
        rsync_status=$?
        RSYNC_FAILED=true
        log "ERROR: rsync failed for $SRC (exit status $rsync_status)."
    fi
done

END_TIME="$(ts)"

if [[ "$RSYNC_FAILED" == true ]]; then
    result=1
    rsync_status="failed"

    if [[ "$IS_DRY_RUN" == true ]]; then
        log "Dry run finished with one or more rsync errors; no backup changes were applied."
    else
        log "Backup run finished with one or more rsync errors."
    fi
elif [[ "$IS_DRY_RUN" == true ]]; then
    result=0
    log "Dry run finished; no backup files were changed."
else
    result=0
    rsync_status="succeeded"
    log "The backup completed successfully."
fi

# info.txt: metadata about this backup
INFO_FILE="$MOUNT_POINT/backups/gateway-mt6707/lp2/info.txt"

if [[ "$IS_DRY_RUN" == false ]]; then
    cat > "$INFO_FILE" <<EOF
Backup Drive for: Thiago's Gateway MT6707
Purpose: Personal backups (Linux home directory)
Method: rsync, with --archive and --delete options
Mount Point: $MOUNT_POINT
Backup Path (latest): $LATEST
Backup Started: $START_TIME
Backup Finished: $END_TIME
Rsync Status: $rsync_status
EOF
fi

echo "--------------------------------------------------------" >> "$LOGFILE"
exit "$result"
