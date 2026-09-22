#!/usr/bin/env bash
# apply the repository settings, labels and rulesets under .github/repo to a
# github repository. safe to rerun: each item is created or updated in place.
#
# usage: tools/github-apply.sh [owner/repo] [--prune-labels]
#   owner/repo      defaults to the repository of the current checkout
#   --prune-labels  delete labels that .github/repo/labels.json does not list
set -euo pipefail

repo=""
prune=false
for arg in "$@"; do
    case "$arg" in
        --prune-labels) prune=true ;;
        -*) echo "unknown option: $arg" >&2; exit 1 ;;
        *) repo=$arg ;;
    esac
done
[ -n "$repo" ] || repo=$(gh repo view --json nameWithOwner --jq .nameWithOwner)
root=$(cd "$(dirname "$0")/.." && pwd)/.github/repo
echo "applying $root to $repo"

# dev is the default branch and integration target; main takes releases only
main_sha=$(gh api "repos/$repo/git/ref/heads/main" --jq .object.sha)
if ! gh api "repos/$repo/git/ref/heads/dev" > /dev/null 2>&1; then
    gh api --method POST "repos/$repo/git/refs" -f ref=refs/heads/dev -f sha="$main_sha" > /dev/null
    echo "created dev at ${main_sha:0:7}"
fi
jq '. + {default_branch: "dev"}' "$root/settings.json" \
    | gh api --method PATCH "repos/$repo" --input - > /dev/null
echo "settings applied, default branch is dev"

existing=$(gh label list -R "$repo" --limit 500 --json name --jq '.[].name')
jq -c '.[]' "$root/labels.json" | while read -r label; do
    name=$(jq -r .name <<< "$label")
    gh label create "$name" -R "$repo" --force \
        --color "$(jq -r .color <<< "$label")" \
        --description "$(jq -r .description <<< "$label")" > /dev/null
done
echo "labels applied"
if $prune; then
    wanted=$(jq -r '.[].name' "$root/labels.json")
    grep -vxF -f <(printf '%s\n' "$wanted") <<< "$existing" | while read -r name; do
        [ -n "$name" ] || continue
        gh label delete "$name" -R "$repo" --yes > /dev/null
        echo "deleted label $name"
    done
fi

rulesets=$(gh api "repos/$repo/rulesets?includes_parents=false" --paginate)
for file in "$root"/rulesets/*.json; do
    name=$(jq -r .name "$file")
    id=$(jq -r --arg n "$name" '.[] | select(.name == $n) | .id' <<< "$rulesets")
    if [ -n "$id" ]; then
        gh api --method PUT "repos/$repo/rulesets/$id" --input "$file" > /dev/null
        echo "ruleset '$name' updated"
    else
        gh api --method POST "repos/$repo/rulesets" --input "$file" > /dev/null
        echo "ruleset '$name' created"
    fi
done
