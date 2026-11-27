# Verify: infra-k8s-countly PR #34 (PVC sizes), checked 2026-11-27

## Answer
PR #34 mostly made Git match what is already deployed. It is not a new capacity jump.
- OVH shows the ClickHouse volume is already 2500 GB, created 2026-10-14 10:40Z (about 1h45 after PR #26 "KT32-128-nomongodb sizing profile, pin ClickHouse to dedicated node" merged at 08:57Z). The three Kafka broker volumes are already 400 GB.
- Git still said 200Gi for both until 2026-11-26. So the volumes were enlarged by hand (or by an earlier apply) outside Git, and #34 recorded it. Same pattern as PR #30 (2026-10-22), which wrote "PVCs were already expanded in place to 200Gi (emergency); this makes Git match".
- The stated reason is not written anywhere (empty body, one commit, no review, merged 41 seconds after opening). Best inference: Kafka disk-full incident (data growth/backlog) for the brokers, plus sizing the single ClickHouse node for the migrated Countly data (the old MongoDB worker volume is 4000 GB). Retention is not the reason: no retention setting changed in either file.

## Evidence
- PR #34 (muhammadali7edu, branch fix/adjust-pvc-sizes): created 2026-11-26T09:14:47Z, merged 09:15:08Z, 1 commit "fix: increase ClickHouse server PVC to 2500Gi, Kafka broker PVCs to 400Gi", body empty, no comments or reviews. Diff is 1 line per file: `persistence: { size: 200Gi }` -> `2500Gi`; broker `size: 200Gi` -> `400Gi`.
- OVH API, project 7c0c802c..., volume list (GET only): `...l2rjx5-pvc-228aa98d...` 2500 GB, created 2026-10-14T10:40:32Z (l2rjx5 is the seveneducation-countly cluster); three 400 GB volumes created 2026-07-20 (same cluster, the broker PVCs; creation date unchanged means they were resized in place); three 20 GB (controllers); one 10 GB (keeper). Old `infra-countly-mongodb-worker-vol-01` is 4000 GB, created 2025-10-28, still in use as of 2026-11-27. Resize dates are not in the API output, so when the brokers went 200 -> 400 is unknown (between 2026-10-22 and 2026-11-26).
- PR #30 (merged 2026-10-22, written by Claude Code): real incident. From 2026-10-15 ~10:19Z brokers 1 and 2 crash-looped (~586 restarts) with `IOException: No space left on device`; broker 0 at ~99% of 100 GB; Kafka Connect (ClickHouse sink) down (671 restarts). Brokers expanded to 200Gi in place. Follow-ups listed: "Size storage from measured topic growth (200Gi is a stop-gap)" and "Check ClickHouse data gap since 10-15 ... (retention is 168h)". So Kafka was breaking on disk full before #30; #34 doubles it again, consistent with 200Gi not being enough.
- Retention: values on main have no ClickHouse TTL setting or Kafka retention keys (only replication factors and consumer fetch sizes); the 168h Kafka retention is the chart default per PR #30. No retention change found.
- PR #33 (open): after PR #31, consumer lag spiked to ~400k during Strimzi rolls, then drained. This is about rolling restarts, not disk. PR #32 (open) explicitly leaves clickhouse-server out of scope ("single replica on a dedicated b3-128 node").
- Infrastructure #71 "Decomissioning Old Countly Cluster": merged 2026-11-03, empty body. Nothing links it to PR #34 except timing (23 days earlier) and the 4000 GB MongoDB volume still existing. A migration is plausible but unproven.
- Repo history: PR #26 (2026-10-14) "apply KT32-128-nomongodb sizing profile, pin ClickHouse to dedicated node" is the only earlier commit touching the ClickHouse values file after July.

## Not proven
- Why 2500 GB specifically, and whether ClickHouse was filling up. No ClickHouse disk-full evidence found.
- Coralogix: no kubelet_volume_stats or kube_pod_info series exist for the countly cluster (clusters present: ovh-iam-dev/production/staging, ovh-sduiapp-preproduction/production). Metrics for Countly live in Grafana/Mimir (per PR #31/#32 text). Log search for "No space left" Oct-Nov (archive tier) returned nothing, because the cluster does not ship logs to Coralogix as far as these queries show. So no usage trend, no lag, no ingestion data from Coralogix.

## Confidence
- High: PR content, empty body, sizes before/after, volumes already at 2500/400 GB in OVH, Kafka disk-full incident on 2026-10-15 (from PR #30).
- Medium: #34 is a Git catch-up to manual resizes (OVH sizes are certain; the "manual" part is inferred from Git still saying 200Gi).
- Low: the exact motive (migration data vs growth). Suggest asking Muhammad Ali before printing a reason. Safe wording for the report: "PR #34 brought Git in line with larger disks already in place, after a Kafka disk-full outage in October."

Source note: gh (PR #30 text) and the OVH volume list worked best; Coralogix did not work because the countly cluster sends no metrics or logs there.
