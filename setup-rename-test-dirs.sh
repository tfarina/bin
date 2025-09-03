#!/bin/bash
#
# setup-rename-test-dirs.sh
# -------------------------
# Creates a test environment under ~/tmp/rename-test
# with a variety of directory names to stress-test
# rename-to-kebab-case.sh --include-dirs
#
# Usage:
#   ./setup-rename-test-dirs.sh
#   cd ~/tmp/rename-test
#   ~/bin/rename-to-kebab-case.sh --include-dirs
#
# Notes:
#   - The script will delete ~/tmp/rename-test if it already exists.
#   - Safe to run multiple times (fresh start each run).
#

set -e

TEST_ROOT="$HOME/tmp/rename-test"

echo "Preparing test environment at $TEST_ROOT ..."
rm -rf "$TEST_ROOT"
mkdir -p "$TEST_ROOT"
cd "$TEST_ROOT"

# 1. Simple cases
mkdir "MyDir"
mkdir "Another_Dir"
mkdir "Video Files"

# 2. Mixed case and underscores
mkdir "YetAnotherDIR"
mkdir "My_Test_Dir"
mkdir "Dir_WITH_MIXED_case"

# 3. Spaces and multiple spaces
mkdir "New   Project"
mkdir " Dir With Leading Space"
mkdir "Dir With Trailing Space "

# 4. Special characters
mkdir "My!Dir@2025"
mkdir "C++ Code"
mkdir "Python#3"
mkdir "Data&Files"

# 5. Numbers and mixed alphanumerics
mkdir "2025 Reports"
mkdir "Version2Final"
mkdir "Final_Version_3"

# 6. Dots in names
mkdir "My.Dir.Name"
mkdir "Config.v2.0"

# 7. Hyphens already present
mkdir "already-kebab"
mkdir "Mix_of-Styles"

# 8. Leading/trailing dashes/underscores
mkdir -- "-Temp-Dir-"
mkdir -- "_Cache_"

# 9. Hidden dirs
mkdir ".git"
mkdir ".Config Dir"

# 10. Collision check
mkdir "Test Dir"
mkdir "Test-Dir"

echo "All test directories created in: $TEST_ROOT"
echo
echo "Next steps:"
echo "  cd $TEST_ROOT"
echo "  ~/bin/rename-to-kebab-case.sh --include-dirs"
echo "  (add --apply to actually rename)"
