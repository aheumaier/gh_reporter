#!/usr/bin/env bash
# Build the newsletter page reports/YYYY-MM-GROUP.html from reports/YYYY-MM-GROUP.md and templates/newsletter.html.
# Usage: scripts/newsletter-html.sh YYYY-MM GROUP
# The markdown goes into the page unchanged and is laid out in the browser. The skill publishes it as a private
# Artifact (CLAUDE.md, Report rules).
# Prints the page's absolute path.
# Exit codes: 64 bad usage, missing report or template, or a report the page can't hold.
# Anything else: a tool failed.
set -euo pipefail

if [[ $# -ne 2 || ! $1 =~ ^[0-9]{4}-(0[1-9]|1[0-2])$ || ! $2 =~ ^[a-z0-9][a-z0-9_-]*$ ]]; then
  echo "usage: $0 YYYY-MM GROUP (GROUP: lowercase letters, digits, - or _; reads reports/YYYY-MM-GROUP.md)" >&2
  exit 64
fi
month=$1
group=$2

root=$(cd "$(dirname "$0")/.." && pwd)
md="$root/reports/$month-$group.md"
html="$root/reports/$month-$group.html"
template="$root/templates/newsletter.html"
for f in "$md" "$template"; do
  [[ -f $f && -r $f ]] || { echo "error: $f not found or not readable" >&2; exit 64; }
done

# The markdown sits in a <script> block, so it must neither open nor close one.
if grep -qiE '</?script' "$md"; then
  echo "error: $md contains a <script> or </script> tag" >&2
  exit 64
fi

# Page title from the dateline "*Sdui app news for November 2026 (...)*": "Sdui app news, November 2026".
title=$(sed -nE '/^\*(.+) for ([A-Z][a-z]+ [0-9]{4}) \(.*$/{s//\1, \2/p;q;}' "$md")
[[ -n $title ]] || title="$group news, $month"

title=${title//&/\&amp;}
title=${title//</\&lt;}
# Values go through the environment: awk -v would turn backslashes in them into escapes.
title="$title" md="$md" awk '
  /<!-- MARKDOWN -->/ { while ((getline line < ENVIRON["md"]) > 0) print line; next }
  (i = index($0, "{{TITLE}}")) { $0 = substr($0, 1, i - 1) ENVIRON["title"] substr($0, i + 9) }
  { print }
' "$template" >"$html"

echo "$html"
