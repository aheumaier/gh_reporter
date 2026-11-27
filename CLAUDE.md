# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Mission

This repo produces monthly GitHub news reports for the engineering org and the CTO, one per group of repos in the
`7education` GitHub organization (infra and sdui as of 2026-11-27). The report should inform the reader and make
them want to read it: what shipped, what changed, who did notable work, and what is coming next. Other teams read it
too, so explain things in plain words.

There is no application code. The tools are the GitHub CLI (`gh`, already logged in with access to the private
org repos) and Claude Code sub-agents running in parallel. Each run writes one newsletter for one group: a markdown file and an
HTML page made from it, published as a private Artifact.

## Layout

- `repos/<group>.txt`: the watched repos of one report group, one `7education/<name>` per line. `infra.txt` holds
  the infrastructure team's four repos, `sdui.txt` holds `7education/sdui-monorepo` (as of 2026-11-27). Do not add
  repos from `gh repo list`: the org has many more repos than are watched.
- `scripts/collect.sh YYYY-MM GROUP`: downloads the month for every repo of the group into
  `reports/YYYY-MM/GROUP/raw/` (merged PRs, open PRs, releases, issues) and writes `raw/summary.json` with counts,
  the previous month's merged count and authors. Each group has its own folder, so a run never touches another
  group's data.
- `.claude/agents/repo-reporter.md`: the sub-agent brief that turns one repo's raw data into
  `reports/YYYY-MM/<group>/<repo>.md`, a fact file with numbers, highlights, themes, people, in-flight work and open
  questions. The main session writes the report from these files and does not re-read raw `gh` output.
- `.claude/skills/monthly-report/SKILL.md`: the end-to-end workflow (`/monthly-report YYYY-MM GROUP`): collect,
  fan out, ask the user the open questions, write `reports/YYYY-MM-GROUP.md`, check, publish the page, then feed
  lessons back into the tool.
- `scripts/newsletter-html.sh YYYY-MM GROUP`: builds `reports/YYYY-MM-GROUP.html` from the markdown report and
  `templates/newsletter.html`, the one design for every newsletter, in the Seven Education brand
  ([guidelines](https://brand.7education.com/seven-education/guidelines); the template names the colours it uses).
  The page lays the markdown out in the browser, so the markdown keeps the fixed parts of the skill's step 4. Change
  the design in the template, never in a page.

The month window is the UTC calendar month. When the tool gets something wrong, fix the script, agent brief or
skill rather than patching one report by hand, so the next month benefits.

## Data collection commands

`scripts/collect.sh` wraps these. Checked against `7education/educamos` for October 2026 on 2026-11-27.

```bash
R=7education/educamos

# Merged PR count (one call, no 1000 cap on the count itself)
gh api search/issues -X GET -f q="repo:$R is:pr is:merged merged:2026-10-01..2026-10-31" --jq .total_count

# Merged PRs with details. Raise --limit: the default and 500 silently cut the month short
# (educamos merged 664 PRs in October 2026). This goes through the search API, so 1000 is the hard cap;
# above that, split the month into smaller date ranges.
gh pr list -R $R --state merged --search "merged:2026-10-01..2026-10-31" --limit 1000 \
  --json number,title,author,mergedAt,url,labels,body,additions,deletions,changedFiles

# Releases published in the month (gh release list has no date filter; newest first)
gh release list -R $R --limit 1000 --json tagName,name,publishedAt \
  --jq '[.[] | select(.publishedAt[:7] == "2026-10")]'

# Commits on the default branch in the month
gh api "repos/$R/commits?since=2026-10-01T00:00:00Z&until=2026-11-01T00:00:00Z&per_page=100" --paginate

# Issues opened in the month (educamos had none in October 2026; some teams may track work outside GitHub)
gh search issues --repo $R --created 2026-10-01..2026-10-31 --limit 1000 \
  --json number,title,state,url,author,createdAt
```

`collect.sh` exits 65 when a list hit its limit (data incomplete: split that repo's month into smaller date
ranges) and 64 on bad usage or a bad or missing `repos/GROUP.txt`.

GitHub search uses only one `merged:` qualifier: `merged:>=2026-10-01 merged:<2026-11-01` returned 1310 PRs
instead of 218 for services-ovh-infra. Always pass the month as one `start..end` range.

Org-wide `gh search prs --owner 7education ...` covers every org repo, not only the watched ones, and hits the
1000-result cap: October 2026 had 2075 merged PRs across the org. Use per-repo calls. The search API allows about
30 requests per minute, so sub-agents should not loop over many small date ranges at once.

## Report rules

- The report is a short newsletter about what other teams get out of it: what to do on Monday, what comes in the
  next weeks, and where the platform is heading. No PR counts or activity stats, no team-internal work and no
  security findings: the user said on 2026-11-27 that an outside reader needn't see the numbers proven. The
  fact files under `reports/YYYY-MM/<group>/` keep the detail. Any number that is in the report says what it counts.
- Every claim links to its PR, release or issue, or to its commit when it was pushed without a PR.
- Write for readers outside the team: say what a change means for users or other teams, not only its title, and
  whether they must act. Explain repo names and internal terms the first time they appear. A reviewer with no
  context, reading as a developer from another team, found that explaining how a change works is not enough
  (2026-11-27).
- The repos are private. The newsletter is published only as a private Artifact (the user asked for this on
  2026-11-27); the user shares it from the page. Do not post it or send it anywhere else unless the user asks.
