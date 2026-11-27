#!/usr/bin/env bash
# Download one month of GitHub activity for every repo in repos/GROUP.txt into reports/YYYY-MM/GROUP/raw/.
# Usage: scripts/collect.sh YYYY-MM GROUP
# Needs: gh (logged in), jq. Writes per repo: <name>.prs.json, .open.json, .releases.json, .issues.json,
# .summary.json; and summary.json for all repos of the group.
# Exit codes: 64 bad usage or repo list, 65 a list hit its limit (data incomplete, see CLAUDE.md),
# anything else: gh or jq failed.
set -euo pipefail

if [[ $# -ne 2 || ! $1 =~ ^[0-9]{4}-(0[1-9]|1[0-2])$ || ! $2 =~ ^[a-z0-9][a-z0-9_-]*$ ]]; then
  echo "usage: $0 YYYY-MM GROUP (GROUP: lowercase letters, digits, - or _; reads repos/GROUP.txt)" >&2
  exit 64
fi
month=$1
group=$2

root=$(cd "$(dirname "$0")/.." && pwd)
list="$root/repos/$group.txt"
if [[ ! -f $list || ! -r $list ]]; then
  echo "no readable repo list $list (each .txt file in repos/ is a group)" >&2
  exit 64
fi
repos=$(tr -d '\r' <"$list" | sed -e '/^[[:space:]]*#/d' -e '/^[[:space:]]*$/d')
if [[ -z $repos ]]; then
  echo "$list lists no repos" >&2
  exit 64
fi
# Files are named by repo name without the owner, so names must be unique too, ignoring case like GitHub and macOS.
# shellcheck disable=SC2001 # sed strips the owner on every line of a multi-line string
if dups=$(sed 's|.*/||' <<<"$repos" | sort -f | uniq -di) && [[ -n $dups ]]; then
  echo "$list lists these repo names twice: $dups" >&2
  exit 64
fi

days_in_month() { # YEAR MM
  case $2 in
    04 | 06 | 09 | 11) echo 30 ;;
    02) if (($1 % 4 == 0 && ($1 % 100 != 0 || $1 % 400 == 0))); then echo 29; else echo 28; fi ;;
    *) echo 31 ;;
  esac
}

year=${month%-*}
mm=${month#*-}
start="$month-01"
end="$month-$(days_in_month "$year" "$mm")"
# GitHub search ignores all but one "merged:" qualifier, so the month must be one start..end range.
range="$start..$end"

# Count months from year 0 so January rolls back to December of the year before.
prev_total=$((10#$year * 12 + 10#$mm - 2))
prev=$(printf '%04d-%02d' $((prev_total / 12)) $((prev_total % 12 + 1)))
prev_range="$prev-01..$prev-$(days_in_month "${prev%-*}" "${prev#*-}")"

today=$(date -u +%F)
if [[ $start > $today ]]; then
  echo "$month has not started yet" >&2
  exit 64
fi

# Drop the last run's summaries, so a failed run leaves no stale summary.json and the group summary below only
# sums repos still in the list. Each group has its own folder, so this never touches another group's data.
raw="$root/reports/$month/$group/raw"
mkdir -p "$raw"
rm -f "$raw"/*.summary.json "$raw/summary.json"

complete=true
if [[ $end > $today || $end == "$today" ]]; then
  complete=false
  echo "NOTE: $month has not ended yet; numbers cover $start to $today only" >&2
fi

merged_count() { # REPO RANGE
  gh api search/issues -X GET -f q="repo:$1 is:pr is:merged merged:$2" \
    --jq 'if .incomplete_results then error("GitHub search timed out, count incomplete") else .total_count end'
}

incomplete=()
check_limit() { # FILE LIMIT WHAT
  if (($(jq length "$1") >= $2)); then
    echo "WARNING: $3 hit the limit of $2; the list is incomplete" >&2
    incomplete+=("$3")
  fi
}

# Each repo uses about 3 search API calls; the search API allows about 30 per minute.
while IFS= read -r -u 3 repo; do
  name=${repo#*/}
  echo "collecting $repo ($range)" >&2

  gh pr list -R "$repo" --state merged --search "merged:$range" --limit 1000 \
    --json number,title,author,mergedAt,url,labels,body,additions,deletions,changedFiles \
    >"$raw/$name.prs.json"
  # Open PRs are a snapshot taken now, not as of the end of the month.
  gh pr list -R "$repo" --state open --limit 500 \
    --json number,title,author,createdAt,url,isDraft >"$raw/$name.open.json"
  check_limit "$raw/$name.open.json" 500 "$repo open PRs"
  # Newest first, so the list is complete when its oldest release is older than the month.
  gh release list -R "$repo" --limit 1000 --json tagName,name,publishedAt >"$raw/$name.releases.all.json"
  if [[ $(jq -r 'length' "$raw/$name.releases.all.json") -ge 1000 &&
    $(jq -r 'last.publishedAt // ""' "$raw/$name.releases.all.json") > $start ]]; then
    echo "WARNING: $repo releases hit the limit of 1000 before reaching $month" >&2
    incomplete+=("$repo releases")
  fi
  jq "[.[] | select(.publishedAt[:7] == \"$month\")]" "$raw/$name.releases.all.json" >"$raw/$name.releases.json"
  rm "$raw/$name.releases.all.json"
  gh search issues --repo "$repo" --created "$range" --limit 1000 \
    --json number,title,state,url,author,createdAt >"$raw/$name.issues.json"
  check_limit "$raw/$name.issues.json" 1000 "$repo issues"

  merged=$(merged_count "$repo" "$range")
  merged_prev=$(merged_count "$repo" "$prev_range")
  fetched=$(jq length "$raw/$name.prs.json")
  if ((fetched < merged)); then
    echo "WARNING: $repo has $merged merged PRs but only $fetched were fetched (search caps at 1000)" >&2
    incomplete+=("$repo merged PRs")
  fi

  jq --arg repo "$repo" --argjson merged "$merged" --argjson prev "$merged_prev" \
    --slurpfile releases "$raw/$name.releases.json" --slurpfile issues "$raw/$name.issues.json" \
    --slurpfile open "$raw/$name.open.json" \
    '{repo: $repo, merged_prs: $merged, fetched_prs: length, merged_prs_prev_month: $prev,
      releases: ($releases[0] | length), issues_opened: ($issues[0] | length), open_prs_now: ($open[0] | length),
      authors: (group_by(.author.login)
                | map({login: .[0].author.login, is_bot: .[0].author.is_bot, merged_prs: length})
                | sort_by(-.merged_prs))}' \
    "$raw/$name.prs.json" >"$raw/$name.summary.json"
done 3<<<"$repos"

jq -s --arg month "$month" --arg group "$group" --arg range "$range" --arg prev "$prev" \
  --argjson complete "$complete" --arg collected_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  '{month: $month, group: $group, range: $range, complete: $complete, previous_month: $prev,
    collected_at: $collected_at, repos: .}' \
  "$raw"/*.summary.json >"$raw/summary.json"
echo "wrote $raw" >&2

if ((${#incomplete[@]})); then
  printf 'incomplete: %s\n' "${incomplete[@]}" >&2
  echo "split the month into smaller ranges for these repos, see CLAUDE.md" >&2
  exit 65
fi
