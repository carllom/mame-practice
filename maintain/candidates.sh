#!/usr/bin/env bash
# List candidate commits in a range, oldest first, tagged with why each matched.
# Usage: candidates.sh <mame-repo> <from-exclusive> [to=master]
# Output: <hash> <tags> <subject>   tags: core,deprecated,keyword,mass
set -euo pipefail
repo=$1 from=$2 to=${3:-master}
range="$from..$to"
cd "$repo"
tmp=$(mktemp)

{
	git log --format='%H core' "$range" -- src/emu src/lib/util docs/source/techspecs docs/source/contributing
	git log --format='%H deprecated' -G'\[\[deprecated' "$range"
	git log --format='%H keyword' -i -E --grep='deprecat|instead of|helper|\bAPI\b|migrat|convert' "$range" -- src
	git log --format='@%H' --name-only "$range" -- src/mame src/devices |
		awk '/^@/ { if (h && n >= 20) print h " mass"; h = substr($0, 2); n = 0; next } NF { n++ } END { if (h && n >= 20) print h " mass" }'
} | awk '{ t[$1] = ($1 in t) ? t[$1] "," $2 : $2 } END { for (h in t) print h, t[h] }' > "$tmp"

# Re-emit in commit order, oldest first, with subject
git log --reverse --format='%H %s' "$range" |
	awk 'NR == FNR { t[$1] = $2; next } ($1 in t) { h = $1; $1 = ""; print substr(h, 1, 11), t[h], substr($0, 2) }' "$tmp" -
rm -f "$tmp"
