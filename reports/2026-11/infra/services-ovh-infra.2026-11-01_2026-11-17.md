# services-ovh-infra, 2026-11-01 to 2026-11-17 (by mergedAt)

PR links: https://github.com/7education/services-ovh-infra/pull/<number>. Short form `#N` below.

## Numbers
(range 2026-11-01..2026-11-17 only; first merge 2026-11-02, last 2026-11-17)
- Merged PRs: 335 in range. Whole month, all days: 701 (summary.json); previous month: 218 (whole month).
- Lines: +223,632 / -15,117.
- Distinct human authors: 7 (strickersteffen 247, schockds42 66, renepupil 10, petro-slyvko-ds42 6, brjasha 3, aheumaier 1, pere-additio 1).
- Bot PRs: 1 (dependabot #895, pyjwt bump). Renovate bot merged none in range.
- Releases: 0 (repo has none this month).
- Issues opened: the issues file has no dates, so not computable for the range. Whole-month count is 3 (open: #1118, #1105, #671).

## Highlights
1. **Backups with proven recovery became mandatory for new databases.** Databasus enrolment, off-site copies to Gravelines, weekly rotating restore tests (GRA restore) and alerts to Teams. Dev has the full chain active, for all tenants: #670, #666, #884, #885, #887, #970, #964. Prod got native S3 replication prep (#665) and a separate Fox backup storage (#713). Why: restore is tested, not assumed.
2. **Prod data platform started: Fox is the first tenant.** `fox-pg` (PostgreSQL 17, 48 GB RAM, 1.8 TB) onboarded in #629, the prd tenant sandbox in #889, a shared Prod pgAdmin with Keycloak SSO in #738/#744/#746, Fox restore and switchover evidence in #742. Also Databasus for prd (#618) and Proxmox host logs into Loki (#947).
3. **Dev database host moved to Proxmox VE 9.** Code and cutover phases for `dev-pve-01` (#798, #799, #800, #801, #802), then MariaDB guests per Moodle/Additio instance (#944, #946, #952, #965). Prd got slimmer cookie sessions without Valkey (#954).
4. **Monitoring and observability per tenant.** Isolated Grafana orgs and access for six tenants (#714, #707, #704, #896), tenant dashboards for MariaDB, PostgreSQL, backup and recovery (#918 to #922, #928), shared Alloy with six authenticated tenant paths (#931), traces and browser vitals (#933, #937), private central k6 (#943), ARC runner and CI capacity dashboards (#925).
5. **Public TLS and platform security.** Wildcard certificates via DNS-01 in Dev and PRD, six PRD routes switched (#651 to #661); Cilium 1.20.4 security release in prd with only Traefik reaching login doors (#617); Kyverno/OpenBao fix (#881); Flux never prunes Namespaces, PVCs or CNPG clusters (#779).

## Themes
1. **Backup and recovery gates for databases** (the largest). #670, #664, #665, #666, #667, #679, #705, #706, #713, #720, #721, #724, #732, #737, #787, #792, #793, #827, #828, #829, #833, #835, #836, #837, #846-#850, #853-#855, #857, #864-#867, #870-#877, #884, #885, #887, #957, #970. Developers: new databases need a Databasus entry and a passing restore before apps get access. Operators: restore runs on isolated hosts and reports to Grafana and Teams.
2. **Prod data platform and Fox onboarding.** #617, #618, #629, #631, #738, #741, #742, #743, #744, #746, #889, #934 (temporary egress to Fox's Exoscale PostgreSQL until migration ends), #947.
3. **Dev DB host to Proxmox and MariaDB guests.** #795, #796, #797, #798-#802, #804, #805, #809, #811, #815, #817, #819, #820, #944, #946, #950, #952, #953, #954, #958, #960, #965.
4. **Tenant monitoring, Grafana and telemetry.** #707, #714, #725, #747, #754, #756, #760, #762, #830, #831, #883, #891-#893, #896-#904, #916, #918-#933, #937, #938, #940-#943, #945, #948, #951, #963.
5. **Tenant rename and database access tooling.** Move from mandant-a to tenant-* names (#688-#690, #698-#702); shared pgAdmin with DBA groups and Keycloak SSO (#697, #709, #710, #717, #722, #726); LibreDB read/write governance (#715, #736, #739, #740, #749, #750).
6. **Ingress, wildcard TLS and Octavia.** #642-#661, #773, #774, #781, #788, #791, #794, #807, #810, #813, #821-#824, #868, #764, #759, #674 (real client IP via PROXY protocol, brjasha).
7. **CI runners and cluster capacity.** #632, #635, #641, #680, #880 (slim runners 30 to 50, pool cap 55), #628, #636, #638, #627; ARC runner egress rules for pupil servers (#673, #696, #770, #888, #910, #939, renepupil).
8. **Identity, access and misc.** Keycloak role values and Entra mappings (#672, #907, #909, #631, #633), bastion admin and docs (#841-#843), Windows IIS server Terraform (#890, #913, #935, #936, petro-slyvko-ds42), OpenCost tenant costs (#668, #669), Flux image automation for Fox (#621-#625), OpenBao delivery roles (#620, aheumaier), capacity review pilot (#662).

## People
- strickersteffen (247 PRs): drove themes 1, 4, 5, 6. Mostly many small, staged steps: each rollout is split into "prepare", "activate", "fix" and "docs: record acceptance" PRs (for example #846 to #850 for DS42 backup, #827 to #831 for Databasus collectors). So the count reflects staged delivery, not 247 separate features. Some are 1-line follow-up fixes.
- schockds42 (66): themes 2, 3, 7, 8. Proxmox cutover, Fox prd onboarding, Keycloak, CI pool and runner sizing.
- renepupil (10): ARC runner egress and CI pool sizing.
- petro-slyvko-ds42 (6): Windows IIS server Terraform, firewall and RDP rules, tenant quota.
- brjasha (3): Fox QA hostnames and certificates, PROXY protocol client IP.
- aheumaier (1): #620 OpenBao roles. pere-additio (1): #886 additio-web egress to Firestore and Google OAuth2 (outside contributor to the repo, a tenant person).
- Bots: dependabot #895 only.

## In flight
Open PRs created in range: none (the earliest open PR was created 2026-11-18). Items started in range and visibly continuing, from merged PR bodies and titles:
- Prod backup replication is "prepared", activation switches default off and historical backfill is a separate step (#665, #667).
- Prod pgAdmin and Fox migration cutover continue (#934 is marked TEMPORARY).
- Prod sandboxes for other tenants come "at their prd onboarding" (#889).
- Capacity review pilot is advisory for four weeks from #662 (merged 2026-11-1x; exact date not checked).
Open issues: #671 Dev: Review S3 offsite backups; #1118 IaC for Windows VMs on the Proxmox cluster; #1105 Renovate Dependency Dashboard.

## Unclear
- Does the #662 capacity-review pilot end around mid-December, and what is decided then?
- Are the prd Fox restore and switchover (#742) complete, and when does the temporary egress in #934 end?
- Issues file has no creation dates: how many issues were opened 2026-11-01 to 2026-11-17?
- PR numbers #619 to #620 and others near the range start were merged before 2026-11-02? First merged date in range is 2026-11-02, so nothing is known about 2026-11-01. Check if the other agent or earlier data covers it.
