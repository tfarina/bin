#!/bin/bash

# rename-to-kebab-case.sh
# -----------------------
# Renames all regular files in the current directory to kebab-case.
#
# kebab-case is a lowercase naming style where words are separated by hyphens.
#   Examples:
#     "My File.txt"             → "my-file.txt"
#     "another_file.TXT"        → "another-file.txt"
#     "My Video File.mp4"       → "my-video-file.mp4"
#     "YetAnotherFile 2025"     → "yetanotherfile-2025"
#     "YetAnotherFile 2026.DOC" → "yetanotherfile-2026.doc"
#
# SAFETY:
#   - By default, runs in dry-run mode (no actual changes made).
#   - Use --apply to perform actual renaming.
#   - In --apply mode, all renames are logged to a timestamped file.
#   - Supports --undo <logfile> (or --undo=logfile) to reverse previous renames.
#
#
# USAGE:
#   ./rename-to-kebab-case.sh
#     → Preview forward renames (dry-run)
#
#   ./rename-to-kebab-case.sh --apply
#     → Perform forward renames and log them

#   ./rename-to-kebab-case.sh --undo rename-log-YYYYMMDD-HHMMSS.txt
#     → Preview undo (dry-run)
#
#   ./rename-to-kebab-case.sh --undo=rename-log-YYYYMMDD-HHMMSS.txt --apply
#     → Perform undo
#
# NOTES:
#   - By default, only regular files are processed.
#   - Use --include-dirs to also rename directories (first level only).
#   - File extensions are preserved and lowercased.
#   - mv -i ensures no overwriting without confirmation.
#   - Log file format: original_name<TAB>new_name
#   - Limitations: filenames with tabs/newlines are not supported in logs.

apply_mode=false
undo_mode=false
undo_log=""
include_dirs=false
files_processed=0
files_renamed=0
log_file=""

usage() {
  cat <<EOF
Usage: $0 [--apply] [--undo <logfile>] | [--undo=<logfile>] [--include-dirs] [--help]

Options:
  --apply              Actually perform changes (default is dry-run)
  --undo <logfile>     Undo renames listed in <logfile>
  --undo=<logfile>     Same as above (equals form)
  --include-dirs       Also rename directories (first level only)
  --help               Show this help

Examples:
  $0
  $0 --apply
  $0 --include-dirs
  $0 --include-dirs apply
  $0 --undo rename-log-20250817-110049.txt
  $0 --undo=rename-log-20250817-110049.txt --apply
EOF
}

# Parse options in any order
while [[ $# -gt 0 ]]; do
    case "$1" in
	--apply)
	    apply_mode=true; shift ;;
	--undo)
	    undo_mode=true
	    if [[ $# -ge 2 && "$2" != --* ]]; then
		undo_log="$2"; shift 2
	    else
		echo "Error: --undo requires a log file argument."
		usage; exit 1
	    fi ;;
	--undo=*)
	    undo_mode=true
	    undo_log="${1#*=}"; shift ;;
	--include-dirs)
	    include_dirs=true; shift ;;
	-h|--help)
	    usage; exit 0 ;;
	--)
	    shift; break ;;
	*)
	    echo "Unknown option: $1"; usage; exit 1 ;;
    esac
done

# If in UNDO mode, require a real file
if $undo_mode; then
    if [[ -z "$undo_log" || ! -f "$undo_log" ]]; then
	echo "Error: undo log not found: '$undo_log'"; exit 1
    fi
fi

# ----------------------------
# NORMAL RENAME (FORWARD) MODE
# ----------------------------
if ! $undo_mode; then
    # Optional: avoid literal '*' when no files match
    shopt -s nullglob

    if $apply_mode; then
	timestamp=$(date +"%Y%m%d-%H%M%S")
	log_file="rename-log-$timestamp.txt"
    fi

    # Loop over all items in the current directory
    for f in *; do
        # Skip if not a regular file
        if [ -f "$f" ]; then
            is_dir=false
        elif [ -d "$f" ] && $include_dirs; then
            is_dir=true
        else
            continue
        fi

        ((files_processed++))

        if $is_dir; then
            # For dirs, no extension handling
            filename="$f"
            extension=""
        else
            # Split into base name and extension
            filename="${f%.*}"     # everything before the last dot
            extension="${f##*.}"   # everything after the last dot

            # Handle files without extension
            if [[ "$f" == "$filename" ]]; then
	        extension=""
            fi
        fi

        # Convert base name to kebab-case
        # Step 1: Convert uppercase to lowercase (tr '[:upper:]' '[:lower:]')
        # Step 2: Replace any sequence of non-alphanumeric characters with a dash (s/[^a-z0-9]+/-/g)
        # Step 3: Remove leading/trailing dashes (s/^-+|-+$//g)
        new_base=$(echo "$filename" \
			  | tr '[:upper:]' '[:lower:]' \
			  | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g')

        # Reconstruct new name with extension
        if [[ -n "$extension" ]]; then
            new="${new_base}.${extension,,}"  # convert extension to lowercase
        else
            new="$new_base"
        fi

        # Only rename if the new name is different
        if [[ "$f" != "$new" ]]; then
	    if $apply_mode; then
	        mv -i -- "$f" "$new"
	        echo "Renamed: '$f' → '$new'"
	        printf "%s\t%s\n" "$f" "$new" >> "$log_file"
	    else
	        echo "Would rename: '$f' → '$new'"
            fi
	    ((files_renamed++))
        fi
    done

    # Summary
    echo
    if $apply_mode; then
        echo "Processed: $files_processed items"
        echo "Renamed:   $files_renamed items"
        echo "Log saved to: $log_file"
    else
        echo "Processed: $files_processed items"
        echo "Would rename: $files_renamed items"
        echo "Dry-run mode: No changes made. Use --apply to rename."
    fi
    exit 0
fi

# ---------
# UNDO MODE
# ---------
# Read the log and apply in REVERSE order for safety
mapfile -t _lines < "$undo_log"

for (( i=${#_lines[@]}-1; i>=0; i-- )); do
    line="${_lines[i]}"
    # Skip empty/comment lines
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

    IFS=$'\t' read -r old new <<< "$line"
    ((files_processed++))

    if [[ -e "$new" ]]; then
        if $apply_mode; then
            mv -i -- "$new" "$old"
            echo "Undid: '$new' → '$old'"
        else
            echo "Would undo: '$new' → '$old'"
        fi
        ((files_changed++))
    else
        echo "Skip: '$new' not found (already undone, moved, or missing)"
    fi
done

# Summary
echo
if $apply_mode; then
    echo "Processed: $files_processed entries from log"
    echo "Reverted:  $files_changed files"
else
    echo "Processed: $files_processed entries from log"
    echo "Would revert: $files_changed files"
    echo "Dry-run mode: No changes made. Use --apply to undo."
fi
