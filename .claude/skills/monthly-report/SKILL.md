---
name: monthly-report
description: Write the monthly GitHub news report for one group of repos (one list per group in repos/, such as infra or sdui). Use when the user asks for the monthly report, a report for a given month, or to re-run or improve one.
---

# Monthly report

Arguments: the month as `YYYY-MM` and the group: `repos/<group>.txt` lists its repos. If one is missing, ask; a
month that has not ended gives partial numbers, so say so in the report. Data, fact and verify files of a run live in
`reports/YYYY-MM/<group>/`, below called the group folder; the report is `reports/YYYY-MM-<group>.md`. So groups never
overwrite each other. Last month's report of the group is `reports/<previous month>-<group>.md`.

## Groups

- **infra** (the infrastructure team's repos). Readers: developers in other teams who run apps on the group
  platform. Actions: access, routing, CI or database changes. Who to ask: the `Infrastructure` README, Jira INFRA.
  Progress count: companies on the platform, how many in production, old servers switched off. Model:
  `reports/2026-11-infra.md`.
- **sdui** (`sdui-monorepo`). Readers: teams who use the Sdui app or its APIs, and the CTO. Actions: API changes,
  removed features, new rules for contributing to the monorepo, repos that moved in. Who to ask: the monorepo's
  README, `.github/CODEOWNERS` and PR template. Progress count: repos moved into the monorepo. Model:
  `reports/2026-11-sdui.md`. The old repos are in the separate org `sdui-hq`, so link them there. A merge does not
  deploy: write "live since" only after finding the `deploy-core.yml` or `deploy-frontend.yml` run that shipped it.

## Steps

1. **Collect.** Run `scripts/collect.sh YYYY-MM <group>`. On exit 65 or any `WARNING` (a list hit its limit),
   split that repo's month (see CLAUDE.md). Read `raw/summary.json` in the group folder. On a rerun, first move
   the old fact and verify files (`*.md`) of the group folder into `previous/` there, so the next steps read only
   this run's files.
2. **Fan out.** Start one `repo-reporter` sub-agent per repo (name the month and group), all in parallel and in
   the background. Give a repo with more than about 300 merged PRs two or more agents, each with a `from`/`to` date
   range. Put repos with fewer than about 10 merged PRs into one agent. If the `repo-reporter` agent type is not
   listed in this session, start a general-purpose agent and tell it to read and follow
   `.claude/agents/repo-reporter.md`.
   Meanwhile check the group's monitoring yourself. Coralogix alerts, dashboards, alert routing and log policies are
   Terraform in `7education/Infrastructure` under `terraform/orgs/7education/coralogix/`: `units/sdui` for sdui,
   `units/infrastructure` and `shared` for infra. List the month's commits on that path with
   `gh api "repos/7education/Infrastructure/commits?path=<path>&since=<start>T00:00:00Z&until=<end>T00:00:00Z"`:
   many are pushed without a PR, so the merged PR list misses them. Confirm in Coralogix that a change is live (an
   alert is enabled and has fired) before you write it. Report what it changes for readers: which alerts watch their
   product, where alerts go, new dashboards, how long logs are kept.
3. **Verify, then ask.** Collect every `## Unclear` item from the fact files. Settle what you can yourself; the
   user expects this ("figure it out, part of the job"). Group the questions by repo and start one read-only
   general-purpose sub-agent per repo, which writes `verify-<topic>.md` in the group folder with answer, evidence
   and confidence. Sources, all strictly read-only:
   - `gh`: PR diffs, base branches, follow-up PRs, files on the default branch.
   - OVHcloud REST API: keys in `OVH_APP_KEY`, `OVH_APP_SECRET`, `OVH_CONSUMER_KEY`; signed GET calls. The key
     also has write rights, so never send anything but GET. The services-ovh-infra clusters are self-run, not
     OVH-managed Kubernetes.
   - Coralogix: `cx` CLI, after loading the `coralogix` skill. Logs and metrics show what is really live.
   Ask the user only what these sources cannot answer, in one batch.
4. **Write** `reports/YYYY-MM-<group>.md` from the fact and verify files. It is a short newsletter, not an activity
   report: one page, under 100 lines. The reader (see Groups) asks "what's in it for me on Monday, what happens in
   the next weeks, and where is the company heading?" The group's model report sets format and tone. Fixed parts, in
   this order:
   - **Headline title**: the month's two biggest news for other teams, not "Infrastructure news". It must be true
     as written (the platform "is ready for" a company, not "goes live", while its data has not moved).
   - **In 30 seconds**: three bullets, *Act*, *Coming*, *Win*. A reader who stops here knows enough.
   - **What you need to do**: one block per action with *Who*, *What* (with "since" or "by" dates from the PRs)
     and *Help* (where to ask). Add a self-check when readers can't tell if they are affected (for example "search
     your chart for `fastcgi`"). End with "Nothing else needs action from you."
   - **Coming up**: a table of what, status (Planned, Preparing, In review, Ready to start, Live) and what it means
     for the reader. Say once below the table that there's no date yet, not in every row. From the second month
     on, say what happened to last month's items.
   - **Where this is going**: first the group's one-line progress count, carried over from last month's report,
     then 2 to 3 short paragraphs. Write each benefit from the reader's side ("the infra team can take over your
     backups"), not the authors' ("one server to patch instead of ten"). Give exact counts and names, not "about
     ten".
   - **Good to know**: this month's news that helps day to day.
   - **Thanks**: real names (`gh api users/<login> --jq .name`), each with one achievement.
   - **Footer**: where to look when something breaks, who to ask (see Groups), and a one-line source.
   Leave out PR counts and other activity numbers, team-internal work and security findings. The fact files keep
   them. Every claim still links its PR, or its commit when it was pushed without one. A headline never claims
   more than its text: "Shorter CI queues", not "Faster builds"; "Dev now, production next". Use one name for each
   thing, explain it where it first appears, and keep to it (not "feature environments" in one place and "review
   environments" in another). Write an action as a plain instruction that names the place: "open your PRs for Sdui
   Meet in the monorepo", not "send changes to Sdui Meet to the monorepo" (the user found that hard to parse,
   2026-11-27). *In 30 seconds* comes before any explanation, so it uses only words the reader already knows.
5. **Check.** Every claim matches a fact or verify file. Every link opens a PR (or commit) in the right repo. Then
   start a sub-agent with no context that reads only the report as a developer from another team and lists every
   question mark, every sentence it had to read twice, what each item changes for it, what is missing and what is
   too detailed. Fix what it finds,
   verifying first.
6. **Improve.** Ask the user what to change. Write lasting lessons back into this skill,
   `.claude/agents/repo-reporter.md`, `scripts/collect.sh` or CLAUDE.md, so the next month starts better. Keep
   one-off corrections in the report only.
