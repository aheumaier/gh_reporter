# Monthly newsletter for 7education/sdui-monorepo

**Goal:** write a second monthly newsletter, this one for the repo `7education/sdui-monorepo`, with the existing
tool. It is separate from the infrastructure newsletter. Done means two things:
`/Users/aheumaier/Codebox/gh_reporter/reports/2026-11-sdui-monorepo.md` exists in the newsletter format, and the
tool can produce such a report every month without breaking the infra report. Status as of 2026-11-27, written for
a session that starts after a context clear.

Read `/Users/aheumaier/Codebox/gh_reporter/CLAUDE.md` first: Mission, Data collection commands and Report rules.
Then read `.claude/skills/monthly-report/SKILL.md` (the workflow; step 4 is the newsletter format) and
`.claude/agents/repo-reporter.md` (the brief for the sub-agents). The model for format and tone is
`reports/2026-11.md`, the infra newsletter. Don't change that file.

## Preconditions

- `gh auth status` must show a login with access to the 7education org. On 2026-11-27,
  `gh repo view 7education/sdui-monorepo` worked. If it fails, stop and ask the user to log in with
  `! gh auth login`.
- `jq` and `shellcheck` must be installed: `command -v jq shellcheck`.
- Optional, for checking whether something is live: `OVH_APP_KEY`, `OVH_APP_SECRET` and `OVH_CONSUMER_KEY` in the
  environment, and the `cx` CLI for Coralogix. Both are strictly read-only. The OVH key has write rights, so send
  only GET. Never print a key or put it on a command line.

## Where things stand

- `/Users/aheumaier/Codebox/gh_reporter` is not a git repo, so there is no branch, PR or worktree. No other Claude
  session works in this folder (checked with `ListAgents` on 2026-11-27).
- The infra newsletter for November 2026 is done: `reports/2026-11.md`, from the data in `reports/2026-11/`.
  `repos.txt` lists the four infra repos.
- Facts about sdui-monorepo, checked 2026-11-27:
  - Default branch `main`. The description says "All Sdui repositories consolidate here", and "Accountable: Amir D."
  - 146 merged PRs in October 2026 and 137 in November so far. 149 PRs are open. That is below the 1000 cap of the
    search API, so one sub-agent per half month is enough.
  - Because Sdui repos are being moved in, line counts can be inflated by imports. The repo-reporter brief already
    says to name such PRs.
- **The tool blocks a second report today.** `scripts/collect.sh YYYY-MM` reads only `repos.txt`. At the start it
  deletes every `*.summary.json` and `summary.json` in `reports/YYYY-MM/raw/`. The skill writes
  `reports/YYYY-MM.md`. A run for the monorepo would therefore overwrite the infra data and report.

## Decisions already made (do not re-ask)

- 2026-11-27, user: the report is a short "what's in it for me" newsletter for developers in other teams and the
  CTO, in the format of the skill's step 4. No PR counts or activity stats, no team-internal work, no security
  findings.
- 2026-11-27, user: work out unclear facts yourself from read-only sources (gh, OVH API, Coralogix) before asking.
  No helper scripts for the OVH API.
- 2026-11-27, user: the repos are private. The report stays a local markdown file. Don't publish it as an
  Artifact, post it or send it anywhere unless asked.
- Agent-decided 2026-11-27, to confirm: the month is November 2026, like the infra report. If the run is on or
  after 2026-12-01, use the full month.

**Still open: how the tool keeps several reports apart.**

- **A. A repo list as an argument (recommended, least code).** `collect.sh YYYY-MM [LIST]`, where `LIST` defaults
  to `repos.txt`.
  - A new file `repos-sdui.txt` holds `7education/sdui-monorepo`.
  - The raw files stay in `reports/YYYY-MM/raw/`. File names are per repo, so they don't clash.
  - The summary is named after the list, for example `summary-sdui.json`. The default list keeps `summary.json`.
  - Only the summaries of the listed repos are deleted.
  - The report is `reports/YYYY-MM-sdui.md`, and the skill takes the list name as a second argument.
- **B. Report groups in folders.** Move `repos.txt` to `repos/infra.txt`, add `repos/sdui.txt`, and write data to
  `reports/YYYY-MM/<group>/`. This is cleaner when many teams join, but it moves the existing November files and
  changes more code.
- **C. No tool change.** Add the monorepo to `repos.txt`. The infra newsletter would then contain Sdui product news,
  which is not what the user asked for.

Ruling: **B**, chosen by the user on 2026-11-27 and built the same day. Lists are `repos/infra.txt` and
`repos/sdui.txt`; `scripts/collect.sh YYYY-MM GROUP` writes to `reports/YYYY-MM/GROUP/`; reports are
`reports/YYYY-MM-GROUP.md`. The infra files moved to `reports/2026-11/infra/` and `reports/2026-11-infra.md`
(content unchanged). The sdui report is `reports/2026-11-sdui.md`, not `2026-11-sdui-monorepo.md`. Paths elsewhere
in this file describe the layout before B.

## Do

1. Confirm the ruling above with the user in one question, together with the month if that is unclear.
2. Change `scripts/collect.sh` for the ruling. Keep exit codes 64 and 65 and the checks for duplicates, future
   months and limits.
   - Check: `shellcheck scripts/collect.sh` is clean.
   - `scripts/collect.sh 2026-11 repos-sdui.txt` (or the form for the ruling) exits 0, and
     `jq . reports/2026-11/raw/summary-sdui.json` shows about 137 merged PRs and 146 for the previous month.
   - `scripts/collect.sh 2026-11` still writes `summary.json` with the four infra repos (701/43/7/1 merged PRs on
     2026-11-27; numbers can grow later in the month).
   - A bad list file exits 64.
3. Update the skill (argument, report file name) and CLAUDE.md (Layout, where the tool writes). Keep them short and
   in the existing style.
4. Run the skill for the monorepo: collect, fan out `repo-reporter` agents (2 date ranges, 2026-11-01 to 2026-11-15
   and 2026-11-16 to the end), verify unclear items, write the newsletter.
   - The audience is other teams who use the Sdui app or its APIs. "What you need to do" means things like API
     changes, removed features, new rules for contributing to the monorepo, or repos that moved in.
   - "Who to ask" comes from the monorepo's README and CODEOWNERS.
5. Check (skill step 5):
   - Every link opens a PR in `7education/sdui-monorepo`: run `gh pr view <n> -R 7education/sdui-monorepo` for
     each one.
   - Every claim matches a fact or verify file.
   - Then start a reviewer sub-agent with no context as a developer from another team. Fix what it finds after
     verifying.
6. Review the tool change: before you report done, run `shell-reviewer` on the `collect.sh` diff in the
   background. Fix confirmed findings, then re-run once. There is no git, so take the diff against a copy saved
   before the edit in the session scratchpad.

## Known and deferred (do not do here)

- Rerun the infra report after 2026-11-30. That is a separate task.
- Open questions in the infra report: the VPN guide link, the GitLab switch-off date, and how many days to plan
  for a restore test. They wait for the user.
- `git init` for this folder: the user hasn't decided yet.
- Don't add other repos from `gh repo list`.

## Stop and ask when

- The ruling is still blank and the user is present.
- The infra data in `reports/2026-11/` would be overwritten or deleted.
- `gh` has no access, or a list hits its limit (exit 65) and splitting the date range doesn't help.
- A fact needs a source other than gh, OVH (GET only) or Coralogix.
- Anything would leave the machine (publish, post, push).

## Report

The final message to the user, in this order:
1. What now works: two reports side by side, and the command for each.
2. Evidence: shellcheck output, exit codes from the test runs, summary numbers, link check, and the reviewers'
   findings with what was done with each.
3. Open items: questions for the user, and facts that only a later run can confirm.
4. Anything still running or left in the scratchpad.
