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
#
# USAGE:
#   ./rename-to-kebab-case.sh         # Preview changes (default)
#   ./rename-to-kebab-case.sh --apply # Actually rename files
#
# NOTES:
#   - Only regular files (not directories) are processed.
#   - File extensions are preserved and lowercased.
#   - Prompts before overwriting existing files with the -i flag in mv.
#   - Logs changes to stdout; can be redirected to a file for manual undo.

apply_mode=false
files_processed=0
files_renamed=0

# Check for --apply flag
if [[ "$1" == "--apply" ]]; then
    apply_mode=true
elif [[ -n "$1" ]]; then
    echo "Usage: $0 [--apply]"
    exit 1
fi

# Loop over all items in the current directory
for f in *; do
    # Skip if not a regular file
    [ -f "$f" ] || continue

    ((files_processed++))

    # Extract filename and extension
    filename="${f%.*}"     # everything before the last dot
    extension="${f##*.}"   # everything after the last dot

    # Handle files with no extension
    if [[ "$f" == "$filename" ]]; then
	extension=""
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
	else
	    echo "Would rename: '$f' → '$new'"
        fi
	((files_renamed++))
    fi
done

# Summary
echo
if $apply_mode; then
    echo "Processed: $files_processed files"
    echo "Renamed:   $files_renamed files"
else
    echo "Processed: $files_processed files"
    echo "Would rename: $files_renamed files"
    echo "Dry-run mode: No changes made. Use --apply to rename."
fi
