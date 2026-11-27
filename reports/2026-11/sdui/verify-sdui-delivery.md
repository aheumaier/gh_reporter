# sdui-monorepo: delivery and ownership fact check (November 2026)

Checked on 2026-11-27 with read-only `gh` calls (GET only). `R=7education/sdui-monorepo`. Files are on `main`
unless stated. Security findings seen in PR bodies are left out on purpose.

## Correction to the brief: `sdui-hq` was not renamed

`sdui-hq` still exists as its own org and still holds the old repos. `7education` is a separate org.

- `gh api orgs/sdui-hq` → `{"created_at":"2018-12-03T10:41:05Z","login":"sdui-hq","name":"Seven Education - Sdui"}`
- `gh api orgs/7education` → `{"created_at":"2026-01-02T14:01:12Z","login":"7education"}`
- `gh api repos/7education/sduiapp-vault-proxy` (and `sduiapp-meet`, `sduiapp-timetable-untis-remote-api`,
  `infra-k8s-sduiapp`) → `404 Not Found`; the same names under `sdui-hq/` resolve.

So links in the newsletter must use `github.com/sdui-hq/<repo>` for the old repos and for `infra-k8s-sduiapp`.
`sdui-monorepo` itself is `7education/sdui-monorepo`. Confidence: high.

## 1. How a merged PR reaches production

**Answer:** Manual. A merge to `main` deploys nothing to production. Someone runs a deploy workflow by hand
(`workflow_dispatch`) from `main`; it ships whatever `main` holds at that moment, so all PRs merged since the last
deploy go out together. There are no fixed release dates and no GitHub releases. A merge to `main` does
automatically refresh the shared test environment `mono-main` (not production).

In practice the team deploys almost every workday, usually minutes to an hour after the merge. For the main
PRs of the month, the first production deploy that contained them:

| PR | Merged (UTC) | First prod deploy run containing it (UTC) |
|----|--------------|-------------------------------------------|
| #1688 step-up kill switch | 2026-11-06 15:40 | core 2026-11-06 15:40 |
| #1684 outbound sync from 2025 | 2026-11-10 15:06 | core 2026-11-10 15:10 |
| #1747 / #1748 holder Core side | 2026-11-12 15:05 / 15:10 | core 2026-11-12 15:40; frontend 2026-11-12 16:42 |
| #1782 Android system bars | 2026-11-18 15:02 | frontend 2026-11-18 15:03 |
| #1418 AI widget host | 2026-11-24 15:02 | frontend 2026-11-24 15:16 |
| #1824 Keycloak code removed | 2026-11-25 15:04 | core 2026-11-25 15:37 |
| #1790 on-device translation | 2026-11-26 00:14 | core 2026-11-26 00:39; frontend 2026-11-26 01:03 |
| #1801 MCP chat endpoint | 2026-11-26 14:42 | core 2026-11-26 14:48 |

So the newsletter can write "in production since <deploy date>" for these (same day as the merge in every case
above). For any other PR, say "merged on" unless its deploy is checked the same way.

**Evidence:**
- There is no `sdui-app-deploy.yml`. The frontend workflow is `deploy-frontend.yml` (DE + CH), next to
  `deploy-core.yml` and `deploy-timetable.yml`; each has DE-only and CH-only children. All are
  `on: workflow_dispatch` only (children also `workflow_call`).
  `gh api repos/$R/contents/.github/workflows/deploy-core.yml` → `on:\n  workflow_dispatch:`
- `.github/workflows/ci.yml` (runs on push to `main`) ends with:
  `# PRODUCTION DEPLOYS — MANUAL ONLY (see WIZ-1150 / ADR Phase 1)` /
  `# Production deploys are NOT auto-triggered on merge to main.`
  Its last job `monorepo-k8s-refresh` refreshes the `mono-main` test environment through
  `7education/infra-ci-central/.github/workflows/k8s-refresh-monorepo.yml@main`.
- [docs/sdui-platform/guides/production-deployments.md](https://github.com/7education/sdui-monorepo/blob/main/docs/sdui-platform/guides/production-deployments.md):
  "Production deploys are **manually triggered** from GitHub Actions. They no longer fire automatically on merge
  to `main`." Step 1: "Merge your PR to `main` as usual. CI runs lint/tests/builds — **no deploy fires**."
  DE images go to Kubernetes via Flux; CH and OVH hosts are updated over SSH by the workflow.
- `.github/workflows/delivery.yml` (new shared pipeline) is shadow mode: "it reports on PRs and builds trunk
  pushes, deploys nothing". `delivery.yaml` sets `gitops: sdui-de/core` and `sdui-de/sdui-app` with `.invalid`
  version URLs (placeholders). Open PR #1875 says auto-deploy stays off until further infra work.
- Runs: `gh api "repos/$R/actions/workflows/deploy-core.yml/runs?created=>=2026-10-25"` → every run has
  `event=workflow_dispatch`, branch `main`; 29 successful runs (plus 1 cancelled) from 2026-11-02 to 2026-11-26 by 8 different
  developers. `deploy-frontend.yml`: 15 runs in November; `deploy-timetable.yml`: 2. No run with event `push`.
- Table: for each PR, `gh api repos/$R/compare/<mergeCommit>...<deploy run head_sha> --jq .status` returned
  `ahead` or `identical` for the first successful run after the merge.
- Rollback is also manual: `rollback-production.yml` (`workflow_dispatch`, `target_sha`, region de/ch/both).

**Caveats:** a green deploy run means the image was built and pushed, the tag was committed to the Flux repo
(DE) and CH was restarted over SSH. I checked the run, not the cluster. The release windows in the PR template
(17:00–19:00, 21:00–04:00) give no time zone, so I did not compare deploy times against them.

**Confidence:** high (manual deploy, and the dates in the table); medium that the cluster rolled out at that minute.

## 2. vault-proxy: is production on the monorepo image?

**Answer:** Yes, production runs the monorepo build since 2026-11-03, but pinned to tag `mono-main-2166e10`
(the CI build of the #1653 merge commit, through the OVH registry mirror of GHCR), not the moving `:mono-main`
tag. The production deploy workflow from #1679 (`deploy-vault-proxy.yml`, which would write `mono-production-<ts>`
tags) has never run. Preprod also runs a monorepo image (`preproduction-1795778421`, deployed 2026-11-27 from a
branch). The old repo `sdui-hq/sduiapp-vault-proxy` is **not** archived, and its PR #3 (SC-1911) is still open
there.

**Evidence:**
- `gh api repos/sdui-hq/infra-k8s-sduiapp/contents/apps/production/vault-proxy/kustomization.yaml` →
  `newName: l706781w.c1.de1.container-registry.ovh.net/ghcr/7education/sdui-monorepo/vault-proxy` /
  `newTag: mono-main-2166e10`
- `gh api repos/sdui-hq/infra-k8s-sduiapp/commits/972be85b` (2026-11-03 09:15 UTC) → "INFRA-1895 :: vault-proxy:
  pull production image from GHCR monorepo build … Start on mono-main-2166e10, the CI build of the merged monorepo
  PR 7education/sdui-monorepo#1653, pinned by commit rather than the moving mono-main tag."
- `gh api repos/$R/commits/2166e10` → `Merge pull request #1653 from 7education/INFRA-1895-vault-proxy-monorepo`
  (2026-11-02 15:10 UTC).
- `gh api "repos/$R/actions/workflows/deploy-vault-proxy.yml/runs" --jq .total_count` → `0`.
  The workflow header says: "The mono-main image built by ci.yml on every push to main is not deployed to
  production."
- `gh api repos/sdui-hq/infra-k8s-sduiapp/contents/apps/preproduction/vault-proxy/kustomization.yaml` →
  `newTag: preproduction-1795778421`; last commit 2026-11-27 11:54 UTC. (The comment in
  `deploy-vault-proxy-preprod.yml` that "infra-k8s-sduiapp has no apps/preproduction/vault-proxy overlay yet" is
  out of date; not fixed, this is read-only.)
- `gh api repos/sdui-hq/sduiapp-vault-proxy --jq .archived` → `false` (last push 2026-10-19).
  `gh api "repos/sdui-hq/sduiapp-vault-proxy/pulls?state=open"` → `#3 SC-1911: cap /codes batch size and reject
  duplicate /key creation`.
- The APP_ENV=prod follow-up from #1653: not set in `apps/base/vault-proxy/config.yaml` or `deployment.yaml` of
  infra-k8s-sduiapp (grep found nothing); it may be set elsewhere. Unverified.

**Confidence:** high (production image and tag, archive flag); low (APP_ENV).

## 3. Sdui Meet move (#1785)

**Answer:** `sdui-hq/sduiapp-meet` **is archived** (read-only). #1785 **was merged with a merge commit** (2
parents). The rule "PRs that add or update the Jitsi subtree must be merged with a merge commit, never squash or
rebase" is written in the root `CLAUDE.md` and in `apps/sduiapp-meet/README.md`. GitHub does not enforce it:
the repo allows squash and rebase merges on `main`.

**Evidence:**
- `gh api repos/sdui-hq/sduiapp-meet --jq .archived` → `true` (last push 2026-11-20 10:04 UTC, minutes after the merge).
- `gh pr view 1785 -R $R --json mergedAt,mergeCommit` → `2026-11-20T10:00:29Z 842c835f…`;
  `gh api repos/$R/commits/842c835f… --jq '.parents|length'` → `2` ("Merge pull request #1785 from
  7education/SC-2043-migrate-sduiapp-meet-repository-into-monorepo").
- [CLAUDE.md](https://github.com/7education/sdui-monorepo/blob/main/CLAUDE.md) line 75: "PRs that add or update
  the subtree must be merged with a **merge commit**, never "Squash and merge" or rebase. Squashing drops the
  `git-subtree-dir` / `git-subtree-split` trailers, and the next pull then fails …"
- [apps/sduiapp-meet/README.md](https://github.com/7education/sdui-monorepo/blob/main/apps/sduiapp-meet/README.md)
  line 117 (section "Updating from upstream jitsi-meet"): "Merge the update PR with a **merge commit**, never
  "Squash and merge" or rebase." Step 7 repeats it.
- `gh api repos/$R/rules/branches/main` → pull_request rule `allowed_merge_methods: ["merge","squash","rebase"]`.

**Confidence:** high.

## 4. Holder portal

**What a holder is (plain words):** a *Träger*, the organisation that runs several schools, for example a city or
a non-profit. The holder portal is a separate web app where a holder's administrators log in and see all their
schools in one place. MVP: activate the account, log in, reset the password, home page with the linked schools
and how many people can be reached. Next step in review: a news overview for holders (#1806).

Sources: #1747 body: "A *holder* (Träger) is an organisation such as a city or a non-profit that runs several
schools on Sdui. Holder admins get their own portal (`apps/holder`) …". #1731 body: "holder admins activate their
account, log in, reset their password and see the home page with their linked schools." #1749 body: "It is a
separate product: own Go API (`holder-api`), own React app, own Postgres database". Note: `apps/holder/README.md`
is the README of the agent harness template, not a product description; Core's own doc is
`docs/sdui-platform/features/sduiapp-core/schools/holder-schools.md`.

**Is it deployed?** Split in two:

- **Core and app side (#1747, #1748): in production, but switched off.** It shipped with the core deploy of
  2026-11-12 15:40 UTC and the frontend deploy of 16:42 UTC (see table in 1). #1747: "Core: `HOLDER_API_CLIENT_ID`,
  `HOLDER_PORTAL_URL`. sdui-app: `VITE_HOLDER_PORTAL_URL`. All empty by default, so nothing changes for existing
  environments until they are set." `gh api "search/code?q=repo:sdui-hq/infra-k8s-sduiapp+HOLDER_PORTAL_URL"`
  → `0` hits (config may live elsewhere, so medium).
- **The portal app itself (#1749): Dev only.** It runs as a Dev preview on the infra team's DS42 Dev cluster at
  `holder-sdui.dev.ds42.cloud`, deployed from the gitops repo `7education/services-ovh-apps`
  (`apps/sdui/holder`), which [services-ovh-apps#229](https://github.com/7education/services-ovh-apps/pull/229)
  "Deploy Holder Dev from monorepo main 0ac51f47" added (merged 2026-11-13). Not on staging, not in production.

**Evidence (portal):**
- `gh api repos/7education/services-ovh-apps/contents/apps/sdui/holder/README.md` → "Dev preview at
  `https://holder-sdui.dev.ds42.cloud` in namespace `tenant-sdui`. Flux reconciles this path separately …"
- `apps/sdui/holder/chart/values.yaml` → `ingressEnabled: false` by default; `release.yaml` → `ingressEnabled: true`
  for the Dev host.
- `envs/stg/kustomization.yaml` and `envs/prd/kustomization.yaml` in services-ovh-apps contain no sdui or holder
  entry (grep empty); `envs/dev` lists sdui core, sdui-app and jitsi, and says Holder is reconciled separately.
- `sdui-hq/infra-k8s-sduiapp` (current production gitops) has no holder app: `apps/production` lists
  `phpmyadmin pupilconnect-frontend royal-schedule sdui-app-redis-k8s sduiapp-backend sduiapp-echo sduiapp-frontend
  sduiapp-imaginary sduiapp-memcached vault-proxy vault`.
- No workflow in the monorepo root builds or deploys holder images. `grep -l holder .github/workflows/*` → only
  `holder-mono-main-readonly.yml` (a read-only check of DS42 Holder test data in the `mono-main` environment, from
  #1857). `apps/holder/.github/workflows/*` exist but are inert (#1746: "`apps/holder/.github` stays inert on
  GitHub (no CI, no CODEOWNERS)"). The CI PR #1733 "ci(holder): run holder checks and image builds in monorepo CI"
  is an open draft.
- #1749 body: "no environment has applied the holder migrations yet" (as of the merge; the Dev preview has since
  been provisioned, per #1755).
- Production setup is a written runbook, not yet done:
  [apps/holder/docs/runbooks/production-setup.md](https://github.com/7education/sdui-monorepo/blob/main/apps/holder/docs/runbooks/production-setup.md)
  "Run once per environment (staging, then production) at the first deploy".

**Open PRs:**
- [#1806](https://github.com/7education/sdui-monorepo/pull/1806) (open, created 2026-11-20): holder news overview,
  portal plus Core. "Go-live (News out of "coming soon") follows in SC-2103." No date.
- [#1780](https://github.com/7education/sdui-monorepo/pull/1780) (draft, 2026-11-17): fixes from the holder portal
  security review (details left out). No date.
- [#1755](https://github.com/7education/sdui-monorepo/pull/1755) (draft, 2026-11-12): build the four Holder Dev
  images from `main` and provision sample data on DS42 Dev; "The initial demo has already been provisioned and
  its login and activation verified." Deployment pins are in services-ovh-apps#229 (merged).

**Confidence:** high (meaning of holder; portal not in stg/prd; Core side deployed); medium (Core side switched off
in production, because its config could come from outside the gitops repo).

## 5. Other repos moving in soon

**Answer:** One move is open, with no date: [#1130](https://github.com/7education/sdui-monorepo/pull/1130)
"migrate sduiapp-timetable-untis-remote-api into the monorepo" (SC-1646, open since 2026-08-18, last update
2026-08-30). Its body starts "Blocked: do not merge until SC-1648 has a … ruling", a review of some imported files
(details left out). No other open PR moves a repo in. The vault-proxy move still has open loose ends (old repo
not archived, PR #3 there).

The repos that are still active in `sdui-hq` and could follow (no plan or date found in the monorepo):
`sduiapp-vault-proxy` (moved, not archived), `sduiapp-timetable-untis-remote-api` (#1130),
`sduiapp-app-internationalization`, `app-switcher`, `tracking`, `php-opentelemetry`,
`sduiapp-frontend-bootstrap-scss`, `sduiapp-frontend-icon-font`, `sduiapp-frontend-fonts`,
`sduiapp-push-notification`, `edfi-*-sdk`, `sduiapp-vault`, `infra-sdui-php-base`. Many of these already have a
copy under `packages/` or `i18n` in the monorepo (see `delivery.yaml` library list), so they may simply be
unarchived leftovers. 35 repos in `sdui-hq` are not archived.

**Evidence:**
- `gh pr view 1130 -R $R --json state,isDraft,createdAt,updatedAt` → `OPEN draft=false created=2026-08-18 updated=2026-08-30`.
- `gh pr list -R $R --state open --limit 300 … select(.title|test("migrat|monorepo|move|import|onboard"))` → only
  #1130 is a repo move (others: #1744 onboard timetable to the delivery pipeline, #1733 holder CI, unrelated).
- `gh repo list sdui-hq --limit 300 --json name,isArchived,pushedAt` → 35 not archived (list above).
- Root README / CLAUDE.md: no migration roadmap with dates found.

**Confidence:** high (#1130 status, no dates); low (which of the remaining sdui-hq repos will move).

## 6. Who to ask

**Answer:** Ask the GitHub team **`@7education/sdui`** ("Sdui Product - School communication app (Germany)",
18 members; 15 of the 18 humans who authored merged PRs this month are in it, not ihor-solopii-sdui, rustamgk, strickersteffen), and announce or ask in the Microsoft Teams
channel **"sdui"** linked from the PR template. Release process: Confluence "Deployment Guide" (space SCTS).
Work is tracked in Jira (SC-, INFRA-, PE-, WIZ- keys), not in GitHub issues. For infra/delivery topics the
`@7education/platform` team has push access too.

The ownership files point to teams that do not exist, so they do not help: `.github/CODEOWNERS` names
`@7education/backend-team`, `frontend-team`, `platform-team`, and `delivery.yaml` names `@7education/product-sdui`
as owner of every app. None of these four exist (`platform-security`, also named in `delivery.yaml`, does).
Because the branch rules require 1 approval but not code-owner review, the wrong CODEOWNERS does not block
merges; it just requests nobody.

**Evidence:**
- `gh api repos/$R/teams` → `product pull`, `platform push`, `engineering-leadership maintain`, `sdui push`,
  `domain-engineering push`, `product-managers pull`, `engineering push`.
- `gh api orgs/7education/teams --paginate --jq '.[].slug'` → `domain-engineering engineering engineering-leadership
  owners platform platform-devex platform-infra-build platform-infra-qa platform-infra-sre platform-infrastructure
  platform-objectstore platform-security product product-bavaria product-bavaria-admins product-educamos-additio
  product-educamos-additio-admins product-managers product-pupil sdui` (no backend-team, frontend-team,
  platform-team, product-sdui).
- `gh api orgs/7education/teams/sdui` → `sdui: Sdui Product - School communication app (Germany) members=18
  parent=engineering`.
- `gh api repos/$R/rules/branches/main` → `required_approving_review_count: 1`, `require_code_owner_review: false`.
  Rulesets: `default-branch-protection`, `default-four-eye-principle`, `docs-auto-merge` (some users may bypass).
- [.github/pull_request_template.md](https://github.com/7education/sdui-monorepo/blob/main/.github/pull_request_template.md)
  line 2: "Announce on [Teams](https://teams.microsoft.com/l/channel/…/sdui?…) beforehand and release as a pair.
  See [Deployment Guide](https://7education.atlassian.net/wiki/spaces/SCTS/pages/78315550/Deployment+Guide)."
- Root `README.md` and `CLAUDE.md`: no contact person or channel (grep for contact/team/channel/owner found none).
  `docs/sdui-platform/README.md` points to Confluence spaces SASADA and SCTS for ADRs.

**Confidence:** high (teams, CODEOWNERS, template links); medium ("ask team sdui" is a recommendation from
membership and PR authorship, not a written contact rule).

## Delivery pipeline pin (checked 2026-11-27, after the user asked about delivery-templates)

- `.github/workflows/delivery.yml` on main calls `7education/delivery-templates` at `7e10940` (merge of
  delivery-templates#25, 2026-11-18 15:24 UTC), set by #1788. No later monorepo commit changes the pin; main of
  delivery-templates is 8 commits ahead.
- delivery-templates#26 (merged 2026-11-19) moves Core integration shards and the DB migration check back to ARC Full,
  because on arc-slim Docker Compose rejects their flags. The monorepo pin predates it.
- Matching symptom: on #1874 and #1870 (merged 2026-11-26) all `pipeline / integration` shards and the DB migration
  check fail in about 45 s. The rulesets have no required status checks, so these runs don't block merges.
- Open: draft #1856 would move the pin to release tag `v0.1.0-rc.1` (delivery-templates#30/#31, both open).
