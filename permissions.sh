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

CheckPermissions()
{
    local path="$1"
    local kind expected perms

    # Skip symlinks; their permission bits are not meaningful here.
    if [[ -L "$path" ]]; then
        printf '[SKIP] Symlink %s\n' "$path"
        return
    elif [[ -f "$path" ]]; then
        kind="File"
        expected=644
    elif [[ -d "$path" ]]; then
        kind="Directory"
        expected=755
    else
        printf '[SKIP] Not a regular file or directory: %s\n' "$path"
        return
    fi

    perms=$(stat -c '%a' -- "$path")
    if [[ "$perms" != "$expected" ]]; then
        printf '%s %s has permissions %s (should be %s)\n' \
	       "$kind" "$path" "$perms" "$expected"
        if [[ "$fix" == true ]]; then
            chmod -- "$expected" "$path"
            printf 'Fixed %s\n' "$path"
        fi
    else
        printf '[OK] %s %s has permissions %s\n' "$kind" "$path" "$perms"
    fi
}

Iterate()
{
    local dir="$1"
    local node

    # This checks the starting directory too, including $targetDir.
    CheckPermissions "$dir"

    # find does not follow symlinks by default. Skip them explicitly so
    # their targets are never inspected or changed by this script.
    while IFS= read -r -d '' node; do
        if [[ -L "$node" ]]; then
            CheckPermissions "$node"
        elif [[ -d "$node" ]]; then
            Iterate "$node"
        else
            CheckPermissions "$node"
	fi
    done < <(find "$dir" -mindepth 1 -print0)
}

Iterate "$targetDir"

echo "Done."
