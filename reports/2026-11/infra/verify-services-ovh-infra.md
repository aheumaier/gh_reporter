# Verification: services-ovh-infra, November 2026 (checked 2026-11-27, read-only)

## Q1. What is the "data platform" and what is Fox?

### Answer
The "prd data platform" is NOT the Kubernetes setup. It is the production database platform: three OVH dedicated servers running Proxmox, with PostgreSQL (Patroni, one primary plus one synchronous replica) and MariaDB in containers on local NVMe disks. Tenants (customers or applications) each get their own database instance there. Kubernetes (self-run Talos on OVH instances) is a separate part of the same repo and runs the apps, which reach the databases over the network.
Fox is the first tenant: the Fox application (very likely SchoolFox, the school communication app; repo hostnames `web-schoolfox`, `meet-qa.schoolfox.com`). Fox's database `fox-pg` is PostgreSQL 17, 48 GB RAM, 1.8 TB. It is meant to replace 10 separate PostgreSQL servers now at Exoscale. The "SchoolFox" name is inferred from hostnames; no doc says "Fox = SchoolFox" outright.

### Evidence
- PR #629 (merged 2026-11-12): "onboard Fox ... the first tenant of the prd data platform"; members `fox-pg-1` on prd-pve-03, `fox-pg-2` on prd-pve-01 (Proxmox hosts).
- `docs/prd-data-platform.md` on main: title "prd data platform: Proxmox cluster with local NVMe"; "a Proxmox VE cluster of three OVH dedicated servers".
- PR #889: `tenant-fox` is the Kubernetes namespace of the Fox apps; "fox-pg is on the data platform".
- `docs/fox/prd-db-migration.md`: 10 source PostgreSQL clusters merge into `fox-pg`.

### Confidence
High for "database platform on Proxmox, not Kubernetes". Medium for "Fox = SchoolFox".

## Q2. Is the Fox production restore and switchover (#742) finished?

### Answer
No. #742 only recorded backup and recovery evidence (docs only) BEFORE any application data was imported. The actual move of Fox's data into fox-pg is not done as of 2026-11-27 (no merged PR or doc says it is done). Careful: absence of proof, not proof of absence. The "switchover" in #742 is a Patroni primary/replica switch inside fox-pg (a failover test), not the move of Fox from Exoscale.

### Evidence
- #742 (merged 2026-11-13) says: "Documentation only"; "Post-import restores and observation of automatic multipart expiry remain open".
- `docs/fox/prod-backup-and-recovery.md` on main: section "Restore evidence before application data import"; "both regional restores after data import ... Fox application access remains locked."
- #982 (merged 2026-11-22): a runbook and scripts for the logical migration of the 10 sources, with "Part D: Cutover" still as a procedure. Last commit on `docs/fox` is #982 (2026-11-22); none after.
- #1261 (merged 2026-11-24): "post-import fresh backup ... and isolated DE/GRA restores remain due under #982".
- Temporary egress to Exoscale (#934, "remove once the migration is complete") is still on main in `apps/prd/pgadmin/network.yaml` (checked 2026-11-27).
- Many "Prepare ..." PRs on 2026-11-22 (#1170-#1181, #1197-#1199: pgAdmin, Grafana, secrets "inert"). #1200 (group-managed Fox DBA writes) still open.
- Coralogix: `cx logs` for fox in application or subsystem name, frequent tier, last 3 days: empty. Not usable as proof (the account holds mostly dev logs, e.g. sdui-app-staging).

### Confidence
Medium-high that it is not finished (several documents say import and cutover are still due; newest was 2026-11-24, so a later cutover on 25-27 Nov without a doc PR is unlikely but not excluded).

## Q3. Is production worker autoscaling (#1158) switched on?

### Answer
No. It is in dry-run: it is evaluated every 15 minutes but creates and deletes nothing. The production pool has 0 elastic nodes.

### Evidence
- `gh variable list -R 7education/services-ovh-infra` (2026-11-27): `PRD_POOL_AUTOSCALE  dry-run  2026-11-20T22:18:58Z`. (The variables `POOL_AUTOSCALE=on` and `CI_POOL_AUTOSCALE=on` are the DEV pools and CI runners, a different thing.)
- `docs/prd-cluster.md` "Qualification for automatic resizing": "dry-run since 2026-11-20 22:18 UTC. Nothing in the repository switches it. Setting it to on is an operator action ... Pool: 0 nodes". Updated by #1182 (2026-11-22) and #1270 (2026-11-24).
- `gh run list --workflow prd-pool-scale.yml`: scheduled runs continue, latest 2026-11-27 11:24 UTC, all success (consistent with dry-run).
- OVH `GET /cloud/project/1c8d13cb.../instance` (2026-11-27): 11 instances; workers only `prd-wk-01..03`, created 2026-10-23. No `prd-wk-pNN` elastic node exists.
- One test only: on 2026-11-20 a manual run added `prd-wk-p01` (21:53) and a manual shrink removed it (22:17), after the join check failed on a certificate (fixed in #1165).
- The dev-side commits "worker_pool_size ..." and "ci_pool_size ..." on 2026-11-27 are the dev autoscaler, not prod.

### Confidence
High (variable value, docs and OVH instance list agree).

## Notes for the report
- Say "tested in dry-run, not live" for #1158; do not say "merged and scaling".
- Say "first production tenant of the database platform; data migration still to come" for Fox.

Process: GitHub (gh api for main files, variables, runs) and the OVH instance list worked best; Coralogix was empty for prd and Fox (holds mostly dev logs), so it added nothing.
