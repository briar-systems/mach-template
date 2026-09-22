#!/usr/bin/env bash
# print the CHANGELOG.md section for a version, failing when it is missing or empty
set -euo pipefail

version=${1:?usage: tools/changelog.sh <version>}
file=${2:-CHANGELOG.md}

notes=$(awk -v v="$version" '
    /^## \[/ { on = index($0, "## [" v "]") == 1; next }
    on
' "$file" | sed -e '/./,$!d' -e ':a' -e '/^\n*$/{$d;N;ba' -e '}')

if [ -z "$notes" ]; then
    echo "error: $file has no non-empty section for $version" >&2
    exit 1
fi
printf '%s\n' "$notes"
