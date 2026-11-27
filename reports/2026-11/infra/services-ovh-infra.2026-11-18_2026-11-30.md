# services-ovh-infra, 2026-11-18 to 2026-11-30 (by mergedAt)

Base URL: https://github.com/7education/services-ovh-infra/pull/N

## Numbers
Range 2026-11-18 to 2026-11-30 only (the other agent covers 11-01 to 11-17). Merges stop after 2026-11-27, the collection date.
- Merged PRs in range: 366. Whole month: 701 (range file total; previous month 218). The 2026-11-01..17 share is therefore 335.
- Lines added / removed: 136,070 / 10,021.
- Distinct human authors: 5 (strickersteffen 293 PRs, schockds42 50, brjasha 6, petro-slyvko-ds42 4, renepupil 1).
- Bot PRs: 12 (app/dependabot 9, app/renovate-ovh-infra-app 3).
- Releases: 0 (month). Issues opened: 3 (month; issues have no created date in the raw file, so not split by range).
- Merges per day: 11-18 61, 11-19 79, 11-20 29, 11-21 1, 11-22 45, 11-23 53, 11-24 41, 11-25 45, 11-26 7, 11-27 5.

## Highlights
1. Production observability moved to operators (stages O1 and O2). Grafana and Alloy now run as operators in Production, with Production Alloy on central collectors and Grafana aligned across Dev and Production. Fewer chart-managed parts, one pattern in both environments. [#1231](https://github.com/7education/services-ovh-infra/pull/1231), [#1238](https://github.com/7education/services-ovh-infra/pull/1238), [#1246](https://github.com/7education/services-ovh-infra/pull/1246), [#1250](https://github.com/7education/services-ovh-infra/pull/1250), [#1176](https://github.com/7education/services-ovh-infra/pull/1176)
2. Production backup and recovery got real. Production Velero is active with daily coordinated Nextcloud captures and 30-day retention, and weekly database restores from Gravelines are prepared. Reliability and data-loss risk. [#1003](https://github.com/7education/services-ovh-infra/pull/1003), [#1172](https://github.com/7education/services-ovh-infra/pull/1172), [#1171](https://github.com/7education/services-ovh-infra/pull/1171), [#1302](https://github.com/7education/services-ovh-infra/pull/1302)
3. Production CVE prioritization and a new-P1 Teams alert route are active, and the Vulnerability Report shows who can fix each CVE. Security. [#1298](https://github.com/7education/services-ovh-infra/pull/1298), [#1179](https://github.com/7education/services-ovh-infra/pull/1179), [#1196](https://github.com/7education/services-ovh-infra/pull/1196)
4. CI capacity and cost: Dev slim runners 50 to 92 and pool cap 55 to 97, idle runner VMs retire after 15 minutes, faster scale-down. Production worker autoscaling (elastic general workers) merged. [#1048](https://github.com/7education/services-ovh-infra/pull/1048), [#956](https://github.com/7education/services-ovh-infra/pull/956), [#1188](https://github.com/7education/services-ovh-infra/pull/1188), [#1158](https://github.com/7education/services-ovh-infra/pull/1158)
5. Teams alert cards now carry logs, pod status, events, graphs, silence and ack buttons (Dev and Prod). Faster incident triage. [#1080](https://github.com/7education/services-ovh-infra/pull/1080)

## Themes
1. **Production observability operator cutover** (Grafana, Alloy, tenant Grafana, Thanos capacity, authenticated app telemetry): #1176, #1181, #1231, #1238, #1242, #1246, #1250, #1262, #1266, #1175, #1177, #1259. Also the Dev side: #882, #1072, #1076, #1114, #1258.
2. **Dev capacity redistribution ("placement waves" and ten-worker profile)**: moving services onto eligible existing workers. #882, #1011, #1023, #1027, #1031, #1035, #1052, #1056, #1060, #1064, #1110. About 24 titles say "placement".
3. **Backup, restore and recovery assurance** (Production Velero, Databasus, 7OS PostgreSQL/ClickHouse restore checks, restore-result reporting, probe-state inventory): #1003, #1171, #1172, #1213, #1302, #1306, #1314, #1318, #1322, #1328, #1336, #1341, #1353, #1209.
4. **Security and CVE handling** (CVE prioritization, P1 routing, Trivy alignment, Keycloak stopgap removal, S3 gateway diagnostics, signed preview groups, Entra group access for Nextcloud): #1106, #1127, #1146, #1179, #1196, #1290, #1294, #1298.
5. **CI runners and worker autoscaling**: #956, #1048, #1158, #1162, #1188, #1201.
6. **Database guests and tenants** (Dev MariaDB scrape/log shipping, pgAdmin HBA rules, Fox prd DB migration, new DB configs, Data Hub onboarding): #974, #982, #986, #991, #1131, #1138, #1183, #1223, #1227, #1274, #1278, #1310.
7. **Production tenant onboarding** (Nextcloud at cloud.7.education, Fox access, Holder/Passport credentials, tenant application path): #1084, #1123, #1180, #1200, #1363.
8. **New region pilot**: Zurich Talos pilot with Swiss S3 state and public Kubernetes API. #1358.
9. **Dependency upkeep**: 12 bot PRs plus Renovate tracking of images and digests (#1132, #1136, #1254).

## People
- strickersteffen: 293 of 366 PRs (80%). Titles and bodies show many small, staged PRs (prepare, then activate, then verify; one "placement wave" per service) with pre-merge checks and rollback notes in the bodies, plus a few very large prepare PRs (#882 31,187 lines added, #1207, #1176). Mostly Production and Dev observability, backup/restore, CVE and capacity work. Largest line counts come from that staged approach, not bulk generation.
- schockds42: 50 PRs. Dev MariaDB guest scraping, restore qualification, pgAdmin HBA, Production worker autoscaling (#1158, #1162), removing retired VMs (#978).
- brjasha: 6 PRs. Fox Postgres/pgAdmin, Fox prd DB migration.
- petro-slyvko-ds42: 4 PRs. Database configurations.
- renepupil: 1 PR, CI runner capacity (#1048).
- Bots: dependabot 9, renovate-ovh-infra-app 3 (dependency bumps only).

## In flight
27 open PRs (as of collection). Draft means isDraft.
- Dev placement waves (all draft, strickersteffen): [#1037](https://github.com/7education/services-ovh-infra/pull/1037), [#1038](https://github.com/7education/services-ovh-infra/pull/1038), [#1039](https://github.com/7education/services-ovh-infra/pull/1039), [#1040](https://github.com/7education/services-ovh-infra/pull/1040), [#1041](https://github.com/7education/services-ovh-infra/pull/1041). Open since 2026-11-18.
- Proxmox monitoring (draft): [#1342](https://github.com/7education/services-ovh-infra/pull/1342) Dev native OTLP and dashboard 23855, [#1343](https://github.com/7education/services-ovh-infra/pull/1343) Prod equivalent, [#1344](https://github.com/7education/services-ovh-infra/pull/1344) tenant-scoped Proxmox MCP for Dev and Production.
- Zurich pilot follow-up: [#1364](https://github.com/7education/services-ovh-infra/pull/1364) omit unsupported port security attribute.
- Production tenant work: [#1351](https://github.com/7education/services-ovh-infra/pull/1351) tenant-sdui sandbox for Holder Portal (draft, nickstruckmeyer), [#1200](https://github.com/7education/services-ovh-infra/pull/1200) group-managed Fox DBA writes (open since 2026-11-22).
- Fox and databases: [#1324](https://github.com/7education/services-ovh-infra/pull/1324) Fox Jitsi in tenant-fox, [#1325](https://github.com/7education/services-ovh-infra/pull/1325) meet-qa certificate, [#1224](https://github.com/7education/services-ovh-infra/pull/1224) Barman rollback note in prd DB cutover, [#1223](https://github.com/7education/services-ovh-infra/pull/1223) pgadmin guard default, [#1355](https://github.com/7education/services-ovh-infra/pull/1355) new MariaDB for dxtsevilla, [#1340](https://github.com/7education/services-ovh-infra/pull/1340) node exporter for db-additio-escoladeladona (draft).
- OpenBao: [#1359](https://github.com/7education/services-ovh-infra/pull/1359) role gitops for delivery image pins, Dev (draft, aheumaier).
- Renovate tracking: [#1132](https://github.com/7education/services-ovh-infra/pull/1132), [#1136](https://github.com/7education/services-ovh-infra/pull/1136).
- Dependency bots (8): [#1101](https://github.com/7education/services-ovh-infra/pull/1101), [#1102](https://github.com/7education/services-ovh-infra/pull/1102), [#1103](https://github.com/7education/services-ovh-infra/pull/1103), [#1166](https://github.com/7education/services-ovh-infra/pull/1166), [#1184](https://github.com/7education/services-ovh-infra/pull/1184), [#1236](https://github.com/7education/services-ovh-infra/pull/1236), [#1237](https://github.com/7education/services-ovh-infra/pull/1237) and one more in the raw file.
- Open issues of the month: #1118 IaC for Windows VMs on Proxmox, #1105 Dependency Dashboard, #671 Review Dev S3 offsite backups.

## Unclear
- Is the Dev "ten-worker" profile final, and are the five open placement waves (#1037 to #1041) intentionally parked?
- Was the Production worker autoscaling (#1158, drafted with "nothing scales until steps are done") fully enabled by merge, or are manual steps left?
- The other agent's range covers 335 PRs; confirm the whole-month total 701 matches the final report.
- Issue creation dates are null in the raw file, so "issues opened" cannot be split by range.
- Theme PR lists are from title scanning of 366 PRs, not every PR read; some PRs may fit other themes.
