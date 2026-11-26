#!/bin/bash

set -euo pipefail

targetDir=""
fix=false

for arg in "$@"; do
    case "$arg" in
        --fix)
            fix=true
            ;;
        --help|-h)
            echo "Usage: $0 [--fix] <DIRECTORY>"
            exit 0
            ;;
        -*)
            echo "Unknown option: $arg" >&2
            echo "Usage: $0 [--fix] <DIRECTORY>" >&2
            exit 1
            ;;
        *)
            if [[ -n "$targetDir" ]]; then
                echo "Too many arguments" >&2
                echo "Usage: $0 [--fix] <DIRECTORY>" >&2
                exit 1
            fi
            targetDir="$arg"
            ;;
    esac
done

if [[ -z "$targetDir" ]]; then
    echo "Usage: $0 [--fix] <DIRECTORY>"
    exit 1
fi

if [[ ! -d "$targetDir" || -L "$targetDir" ]]; then
    printf 'Not a directory (or is a symlink): %s\n' "$targetDir" >&2
    exit 1
fi

echo "Checking permissions..."

Iterate()
{
    local dir="$1"
    local node perms expected

    # find does not follow symlinks by default. Skip them explicitly so
    # their targets are never inspected or changed by this script.
    while IFS= read -r -d '' node; do
        if [[ -L "$node" ]]; then
            printf '[SKIP] Symlink %s\n' "$node"
            continue
        elif [[ -f "$node" ]]; then
            expected=644
            kind=File
        elif [[ -d "$node" ]]; then
            expected=755
            kind=Directory
        else
            printf '[SKIP] Not a regular file or directory: %s\n' "$node"
            continue
        fi

        perms=$(stat -c '%a' -- "$node")
        if [[ "$perms" != "$expected" ]]; then
            printf '%s %s has permissions %s (should be %s)\n' \
                "$kind" "$node" "$perms" "$expected"
            if [[ "$fix" == true ]]; then
                chmod -- "$expected" "$node"
                printf 'Fixed %s\n' "$node"
            fi
        else
            printf '[OK] %s %s has permissions %s\n' "$kind" "$node" "$perms"
        fi
    done < <(find "$dir" -mindepth 1 -print0)
}

Iterate "$targetDir"

echo "Done."
