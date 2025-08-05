#!/bin/bash
#
# This script renames all files in the current directory to kebab-case.
#
# kebab-case is a lowercase naming style where words are separated by hyphens.
# For example:
#   "My File.txt"          → "my-file.txt"
#   "another_file.TXT"     → "another-file.txt"
#   "YetAnotherFile 2025"  → "yetanotherfile-2025"
#
# Usage:
#   Place this script in a directory and run it:
#     ./rename-to-kebab-case.sh
#
# Note:
#   - Only affects files (not directories) in the current folder.
#   - Prompts before overwriting existing files with the -i flag in mv.
#

# Loop over all items in the current directory
for f in *; do
    # Skip if not a regular file
    [ -f "$f" ] || continue

    # Step 1: Convert uppercase to lowercase (tr '[:upper:]' '[:lower:]')
    # Step 2: Replace any sequence of non-alphanumeric characters with a dash (s/[^a-z0-9]+/-/g)
    # Step 3: Remove leading/trailing dashes (s/^-+|-+$//g)
    new=$(echo "$f" \
		 | tr '[:upper:]' '[:lower:]' \
		 | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g')

    # Only rename if the new name is different
    if [[ "$f" != "$new" ]]; then
	echo "Renaming: '$f' → '$new'"
	mv -i -- "$f" "$new"
    fi
done
