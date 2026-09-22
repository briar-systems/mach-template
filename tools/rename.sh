#!/usr/bin/env bash
# rename the project id: the manifest, the library artifact, the surface module
# and every `use <id>.` path under src/.
#
# usage: tools/rename.sh <new-id>
set -euo pipefail

new=${1:?usage: tools/rename.sh <new-id>}
[[ "$new" =~ ^[a-z][a-z0-9_]*$ ]] || { echo "error: id must match [a-z][a-z0-9_]*" >&2; exit 1; }
cd "$(dirname "$0")/.."

old=$(python3 -c 'import tomllib; print(tomllib.load(open("mach.toml", "rb"))["project"]["id"])')
[ "$old" != "$new" ] || { echo "project id is already $new"; exit 0; }

sed -i.bak -E \
    -e "s/^(id[[:space:]]*=[[:space:]]*)\"$old\"/\1\"$new\"/" \
    -e "s/^\[artifact\.$old\]/[artifact.$new]/" \
    -e "s/^(entry[[:space:]]*=[[:space:]]*)\"$old\.mach\"/\1\"$new.mach\"/" \
    -e "s|^(out[[:space:]]*=[[:space:]]*)\"lib/$old\"|\1\"lib/$new\"|" \
    mach.toml
rm mach.toml.bak
git mv "src/$old.mach" "src/$new.mach" 2>/dev/null || mv "src/$old.mach" "src/$new.mach"
find src -name '*.mach' -exec sed -i.bak -E "s/\buse $old([.;])/use $new\1/g" {} + -exec rm -f {}.bak \;
find src -name '*.mach.bak' -delete
echo "renamed project $old to $new"
