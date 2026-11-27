# Infrastructure, 2026-11

## Numbers
- Merged PRs: 43 (2026-10: 20).
- Lines added: 280,553; removed: 1,938. About 275,484 of the added lines are one PR that moved two repos in with history ([#76](https://github.com/7education/Infrastructure/pull/76)); without it: about 5,069 added.
- Distinct human authors: 8 (muhammadali7edu 14, cristian-additio 13, rustamgk 6, muerselmazrek 3, suraj-sdui 3, aheumaier 2, Sergio-dmrl 1, renepupil 1).
- Bot PRs: 0. Releases: 0. Issues opened: 0. Open PRs now: 12.

## Highlights
1. Monitoring and platform GitOps repos moved into this repo, because the `sdui-hq` org disabled deploy keys on 2026-11-04 and Flux on clusters reading those repos failed. Merging changes nothing live; each cluster is switched by hand. Plain-text credentials in the old repos were removed in the import. [#76](https://github.com/7education/Infrastructure/pull/76)
2. New internal dev Kubernetes cluster on OVH Managed Kubernetes (own Terraform root `sdui_app_dev`), replacing the self-managed kubeadm dev setup on LumaServ. Plus savings plan for dev and fixes to the prod plan (Debian 12 image, memcached VMs removed). [#113](https://github.com/7education/Infrastructure/pull/113), [#116](https://github.com/7education/Infrastructure/pull/116), [#115](https://github.com/7education/Infrastructure/pull/115)
3. Legacy VM decommissioning: old Countly cluster, prod redis workers, timetable web, bastion, and the s3sync/imaginary/broadcast/phpmyadmin prod instances removed (about 950 lines deleted). Less cost and attack surface. [#71](https://github.com/7education/Infrastructure/pull/71), [#110](https://github.com/7education/Infrastructure/pull/110), [#75](https://github.com/7education/Infrastructure/pull/75)
4. Observability under Terraform and cleaner alerting: Coralogix TCO log policies (10 rules) and an Sdui dashboard folder with dashboard backups now managed as code; Additio SLO error-budget alerts, unified routing and APM presets. [#83](https://github.com/7education/Infrastructure/pull/83), [#84](https://github.com/7education/Infrastructure/pull/84), [#91](https://github.com/7education/Infrastructure/pull/91), [#92](https://github.com/7education/Infrastructure/pull/92), [#80](https://github.com/7education/Infrastructure/pull/80), [#107](https://github.com/7education/Infrastructure/pull/107)
5. CI runner reliability: Educamos Windows jobs were stuck in queue from 2026-11-05 because runner v2.336.0 in the images was too old; fix keeps runners current, and a follow-up deletes orphan GARM scale sets when the VM is recreated. [#72](https://github.com/7education/Infrastructure/pull/72), [#99](https://github.com/7education/Infrastructure/pull/99)

## Themes
- **Infra repos consolidated here** (Flux/GitOps): [#76](https://github.com/7education/Infrastructure/pull/76).
- **OVH Kubernetes dev cluster and capacity**: [#113](https://github.com/7education/Infrastructure/pull/113), [#116](https://github.com/7education/Infrastructure/pull/116), [#115](https://github.com/7education/Infrastructure/pull/115), [#114](https://github.com/7education/Infrastructure/pull/114), [#77](https://github.com/7education/Infrastructure/pull/77) (sduiapp-v2 node floor to 14), [#78](https://github.com/7education/Infrastructure/pull/78) (alert when KEDA scales above floor).
- **Decommissioning old VMs and clusters**: [#71](https://github.com/7education/Infrastructure/pull/71), [#75](https://github.com/7education/Infrastructure/pull/75), [#110](https://github.com/7education/Infrastructure/pull/110), [#96](https://github.com/7education/Infrastructure/pull/96) (pupil Linux GitHub runners removed).
- **Additio SLOs and alert routing (INFRA-2004/2022/2088)**: [#79](https://github.com/7education/Infrastructure/pull/79), [#80](https://github.com/7education/Infrastructure/pull/80), [#81](https://github.com/7education/Infrastructure/pull/81), [#90](https://github.com/7education/Infrastructure/pull/90), [#91](https://github.com/7education/Infrastructure/pull/91), [#92](https://github.com/7education/Infrastructure/pull/92), [#98](https://github.com/7education/Infrastructure/pull/98), [#107](https://github.com/7education/Infrastructure/pull/107), [#108](https://github.com/7education/Infrastructure/pull/108), [#109](https://github.com/7education/Infrastructure/pull/109), [#111](https://github.com/7education/Infrastructure/pull/111), [#112](https://github.com/7education/Infrastructure/pull/112), [#118](https://github.com/7education/Infrastructure/pull/118). Thresholds were raised and real latency SLOs removed in the end ([#118](https://github.com/7education/Infrastructure/pull/118)).
- **Coralogix as code and new alerts (INFRA-2020/2070)**: [#83](https://github.com/7education/Infrastructure/pull/83), [#84](https://github.com/7education/Infrastructure/pull/84), [#100](https://github.com/7education/Infrastructure/pull/100) (nginx worker crashes via Loki).
- **GitHub runners (GARM)**: [#72](https://github.com/7education/Infrastructure/pull/72), [#99](https://github.com/7education/Infrastructure/pull/99), [#89](https://github.com/7education/Infrastructure/pull/89) (VM for Covey runners), [#93](https://github.com/7education/Infrastructure/pull/93), [#94](https://github.com/7education/Infrastructure/pull/94).
- **Covey platform and IAM/DNS**: [#82](https://github.com/7education/Infrastructure/pull/82) (control plane + Postgres), [#85](https://github.com/7education/Infrastructure/pull/85), [#86](https://github.com/7education/Infrastructure/pull/86), [#101](https://github.com/7education/Infrastructure/pull/101), [#102](https://github.com/7education/Infrastructure/pull/102) (IAM DNS cutovers), DNS verification records [#97](https://github.com/7education/Infrastructure/pull/97), [#103](https://github.com/7education/Infrastructure/pull/103), [#105](https://github.com/7education/Infrastructure/pull/105), [#106](https://github.com/7education/Infrastructure/pull/106), [#70](https://github.com/7education/Infrastructure/pull/70); storage [#73](https://github.com/7education/Infrastructure/pull/73); GARM fix [#99](https://github.com/7education/Infrastructure/pull/99).

## People
- muhammadali7edu (14): decommissions, Covey platform, IAM DNS cutovers, small node-pool and runner fixes.
- cristian-additio (13): Additio SLO and alert work (INFRA-2004/2022/2088). Many PRs are small follow-ups in one ticket, not unrelated volume.
- rustamgk (6): OVH dev cluster, savings plans, monorepo move, KEDA alerts.
- muerselmazrek (3): DNS verification records. suraj-sdui (3): GARM runners and nginx alert. aheumaier (2): Coralogix TCO and dashboards as code. Sergio-dmrl (1): GARM orphan scale sets. renepupil (1): runner removal.
- No bots.

## In flight
- Coralogix: TCO exception routing [#119](https://github.com/7education/Infrastructure/pull/119), IAM ingress ready-pods alert [#104](https://github.com/7education/Infrastructure/pull/104), websocket alert [#88](https://github.com/7education/Infrastructure/pull/88), drop TCO import block [#87](https://github.com/7education/Infrastructure/pull/87).
- IAM RLS user room_service_write_db: [#69](https://github.com/7education/Infrastructure/pull/69), [#68](https://github.com/7education/Infrastructure/pull/68).
- Educamos GARM recovery docs and image copy script [#64](https://github.com/7education/Infrastructure/pull/64); harbor firewall IP for ds42 prod [#74](https://github.com/7education/Infrastructure/pull/74).
- Countly v2 cluster [#18](https://github.com/7education/Infrastructure/pull/18); timetable prod VM destroy [#5](https://github.com/7education/Infrastructure/pull/5); remove prod-lb.sdui.app DNS [#4](https://github.com/7education/Infrastructure/pull/4) (low numbers, likely old drafts).
- DNS verification for Anthropic [#117](https://github.com/7education/Infrastructure/pull/117).

## Unclear
- Are #18, #5 and #4 still wanted? Timetable VM work also merged elsewhere ([#110](https://github.com/7education/Infrastructure/pull/110)) and the old Countly cluster was removed ([#71](https://github.com/7education/Infrastructure/pull/71)).
- #110 and #75 have truncated titles and no body; the full list of decommissioned hosts was not checked.
- #82, #89 have no body; purpose of Covey runner VM and control plane taken from titles only.
- Has the manual Flux switch from #76 been done on each cluster?
