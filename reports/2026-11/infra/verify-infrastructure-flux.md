# Verify: Flux switch after Infrastructure PR #76 (as of 2026-11-27)

## Answer
Yes for the two clusters PR #76 covers. `infra-platform` and `infra-monitoring` both deploy from `7education/Infrastructure`. No cluster covered by #76 still points to the old `sdui-hq/infra-k8s-monitoring` or `sdui-hq/infra-k8s-platform` repos. Confirmed directly for platform; for monitoring it is inferred (no Flux logs from that cluster in Coralogix).

Outside #76 (not part of the claim): the sduiapp clusters (prod, staging) still read `sdui-hq/infra-k8s-sduiapp` and fail to authenticate as of 2026-11-25 15:45 UTC. See "Out of scope" below. The report should not say "all clusters".

## Evidence per cluster
- **infra-platform: switched (direct evidence).** Coralogix source-controller log, 2026-11-12 00:03 UTC: `stored artifact for commit 'Merge pull request #76 from 7edu...'`. Before that the cluster failed with `unable to list remote for sdui-hq/infra-k8s-platform ... unable to authenticate` (2026-10-28 to 2026-11-05 16:03; 248 events). Since then it has reconciled `master` of the monorepo (revisions from PRs #86 etc., covey chart packaged 2026-11-17 to 2026-11-25). Only blip: 10 auth failures against `7education/Infrastructure`, 2026-11-24 18:30 to 2026-11-25 01:00, then it stored artifact for commit `e9c4715...` and went back to "no changes" through 2026-11-27 11:32. Cause unknown.
- **infra-monitoring: switched (indirect evidence).** No source-controller logs from this cluster in Coralogix for November (query by `k8s.cluster.name`, archive tier, 2026-11-01 to now; also none for text `infra-monitoring`). Evidence instead: repo deploy key `flux-infra-monitoring` on `7education/Infrastructure` created 2026-11-11 23:58 and last used 2026-11-26 00:00 UTC (`gh api repos/7education/Infrastructure/keys`). That key is the one the runbook creates in cutover step 1, and only Flux uses it. The old repo `sdui-hq/infra-k8s-monitoring` is archived (last push 2026-11-11 13:48), and its last commit `395a8d0` is the one #76 imported; no new commits after.
- **Platform deploy key** `flux-infra-platform`: created 2026-11-12 00:03, last used 2026-11-26 00:04 UTC.
- **Manifests on master**: `k8s/monitoring/clusters/monitoring/flux-system/gotk-sync.yaml` and `k8s/platform/clusters/platform/flux-system/gotk-sync.yaml` exist. I did not read the `url:` values; these show repo config, not what runs on the cluster.
- PR #76 merged 2026-11-11 23:51 UTC. Old repos: platform archived (last push 2026-11-05 22:37), monitoring archived. The "after cutover" archive step is therefore done; the GitLab Receiver cleanup and credential rotation are not checked.
- Not verified: that the old `flux-system` secrets, the stale `gitlab-flux-system` Receiver, or the rotation of committed credentials were handled.

## Out of scope for #76 (found on the way)
Coralogix `unable to authenticate` errors, archive tier, 2026-10-28 to 2026-11-25:
- `infrastructure-sduiapp-prod` and `-staging` (clusters `ovh-sduiapp-production`/`-preproduction`): still `ssh://git@github.com/sdui-hq/infra-k8s-sduiapp`, last failure 2026-11-25 15:45 UTC.
- `infrastructure-iam-dev/-staging/-prod`: already on `7education/domain-engineering-platform` (the earlier IAM move, INFRA-1763) but auth failures 2026-11-24 18:30 to 2026-11-25 15:45.
- iam production stored artifacts from `sdui-hq` PR merges as late as early November, then from `main@sha1:...`: it switched around 2026-11-04 09:37.
`sdui-hq/infra-k8s-sduiapp` is not archived and was pushed 2026-11-26 15:04 UTC, so people still commit there. Status of the sduiapp and iam clusters on 2026-11-27 is not confirmed; treat as open.

## Confidence
- infra-platform switched: high.
- infra-monitoring switched: medium. No cluster log, only deploy-key last_used (2026-11-26) and repo state. Ask the platform owner or run `kubectl get gitrepository flux-system -n flux-system -o jsonpath='{.spec.url}'` on `infra-monitoring` (not done here: read-only, no kube access used).
- "No other cluster in #76 scope": high, #76 lists only these two.

Best source: Coralogix source-controller logs (per-cluster, revision text, dated) and the GitHub deploy-key `last_used` field. Worst: gh code search/tree (shows config, not live state; I did not use it for URLs) and Coralogix for infra-monitoring (cluster not shipping Flux logs).
