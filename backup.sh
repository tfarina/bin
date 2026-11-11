#!/bin/bash

deviceLabel=""
isDryRun=true
rsyncOptions=("-avh" "--delete")

for arg in "$@"; do
    case "$arg" in
        --go)
            isDryRun=false
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
            if [[ -n "$deviceLabel" ]]; then
                echo "Too many arguments" >&2
                echo "Usage: $0 [--go] <LABEL>" >&2
                exit 1
            fi
            deviceLabel="$arg"
            ;;
    esac
done

if [[ "$isDryRun" == true ]]; then
    rsyncOptions+=("--dry-run")
fi

if [[ -z "$deviceLabel" ]]; then
    echo "Usage: $0 [--go] <LABEL>" >&2
    exit 1
fi

host=$(hostname)
mountPoint="/media/$USER/$deviceLabel"
destBase="$mountPoint/backup/$host/$USER/home"
stateDir="${XDG_STATE_HOME:-$HOME/.local/state}/personal-rsync-backup"
logFile="$stateDir/backup.log"
infoFile="$destBase/info.txt"
DATE_FMT="%Y-%m-%dT%H:%M:%S%z"
startTime="$(date "+$DATE_FMT")"

# Directories inside my home to backup
homeDirs=(
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
log() { printf '[%s] %s\n' "$(ts)" "$*" | tee -a "$logFile" ; }

# Make sure the log directory exists
mkdir -p "$stateDir"

# Check if backup drive is mounted
if ! mountpoint -q "$mountPoint"; then
    log "ERROR: Backup drive '$deviceLabel' not mounted at $mountPoint"
    exit 1
fi

log "Target: $deviceLabel ($mountPoint)"

if [[ "$isDryRun" == true ]]; then
    log "Mode: DRY RUN - rsync changes will not be applied"
else
    log "Mode: LIVE RUN - rsync changes, including deletions, will be applied"
fi

# Calculate the estimated size of the backup sources.
if ! duOutput=$(du -sb -c -- "${homeDirs[@]/#/$HOME/}"); then
    log "ERROR: Could not calculate the backup size; see du errors above."
    exit 1
fi

backupSize=$(awk 'END { print $1 }' <<< "$duOutput")

# Get total capacity and available space on the USB filesystem (in bytes).
if ! filesystemStats=$(df --output=size,avail -B1 "$mountPoint"); then
    log "ERROR: Could not read USB filesystem capacity and free space."
    exit 1
fi

read -r filesystemSize filesystemFree \
    <<< "$(tail -n 1 <<< "$filesystemStats")"

log "Estimated backup size: $backupSize bytes"
log "USB filesystem capacity: $filesystemSize bytes"
log "Free space on USB filesystem: $filesystemFree bytes"

if (( backupSize > filesystemSize )); then
    log "ERROR: Estimated backup size exceeds the capacity of $deviceLabel."
    exit 1
fi

log "Preflight phase completed; starting the backup."

# Make sure destination folder exist
if [[ "$isDryRun" == false ]]; then
    mkdir -p "$destBase"
fi

rsyncFailed=false

# Loop through each directory and rsync it
for dir in "${homeDirs[@]}"; do
    src="$HOME/$dir/"
    dest="$destBase/$dir/"
    log "Syncing $src -> $dest"
    if rsync "${rsyncOptions[@]}" --exclude='ISO/' "$src" "$dest" >> "$logFile" 2>&1; then
        :
    else
        rsyncExitCode=$?
        rsyncFailed=true
        log "ERROR: rsync failed for $src (exit code $rsyncExitCode)."
    fi
done

endTime="$(date "+$DATE_FMT")"

if [[ "$rsyncFailed" == true ]]; then
    rsyncResult="failed"
else
    rsyncResult="succeeded"
fi

metadataWriteFailed=false

# Write metadata about the completed backup run.
if [[ "$isDryRun" == false ]]; then
    if ! cat > "$infoFile" <<EOF
Backup device: $deviceLabel
Purpose: Personal backup of the Linux home directory
Method: rsync archive; delete destination files absent from source; exclude ISO/ directories
Mount point: $mountPoint
Backup path: $destBase
Backup started: $startTime
Backup finished: $endTime
Rsync result: $rsyncResult
EOF
    then
        log "ERROR: Could not write backup metadata to $infoFile."
        metadataWriteFailed=true
    fi
fi

if [[ "$isDryRun" == true ]]; then
    if [[ "$rsyncFailed" == true ]]; then
        result=1
        log "Dry run finished with one or more rsync errors; no backup changes were applied."
    else
        result=0
        log "Dry run finished successfully; no backup files were changed."
    fi
else
    if [[ "$rsyncFailed" == true ]]; then
        result=1
        if [[ "$metadataWriteFailed" == true ]]; then
            log "Backup run finished with one or more rsync errors and the metadata could not be written."
        else
            log "Backup run finished with one or more rsync errors."
        fi
    elif [[ "$metadataWriteFailed" == true ]]; then
        result=1
        log "Backup run finished but metadata could not be written."
    else
        result=0
        log "The backup completed successfully."
    fi
fi

echo "--------------------------------------------------------" >> "$logFile"
exit "$result"
