# Sdui monitoring in Coralogix, November 2026 (checked 2026-11-27)

Source: `7education/Infrastructure`, path `terraform/orgs/7education/coralogix/units/sdui` (and the Sdui-cluster
alerts in `units/infrastructure/infrastructure_sduiapp_alerts.tf`), plus read-only Coralogix MCP calls.

| Fact | Evidence | Confidence |
|---|---|---|
| The Sdui alerts were switched on 2026-11-16 00:11 UTC, by a direct push to `master` without a PR. | Commit [6389568](https://github.com/7education/Infrastructure/commit/6389568) "Enable the Sdui Coralogix alerts, scoped to the clusters that send to Coralogix [skip ci]" (Rustam Galimyanov), touches `units/sdui/sdui_alerts.tf` and `units/infrastructure/infrastructure_sduiapp_alerts.tf` | High |
| 32 Sdui product alerts (`units/sdui`, all `enabled = true`): HTTP 5xx and latency, Core API and timetable response times, PHP-FPM, workloads, Horizon queues, notification delay, KMS and encryption, Flux, Redis. | `sdui_alerts.tf` on master | High |
| 52 platform alerts for the Sdui clusters (`units/infrastructure`), all `enabled = true` (README line 54 still calls them disabled: stale). | `infrastructure_sduiapp_alerts.tf` on master | High |
| Live: 84 enabled alerts named "Sdui prod - …" in Coralogix; most recent triggers 2026-11-27, earliest seen 2026-11-16 06:22 ("Flux status metrics missing"). | `search_alert_definitions` name contains "Sdui prod - ", enabled=true: total_size 84 | High |
| Sdui alerts go through `Sdui-Router` to Slack `#coralogix-notifications`, "until the Teams workflows for Coralogix exist". Router added 2026-11-15 by direct push. | `sdui_notifications.tf`; commit [980e9f1](https://github.com/7education/Infrastructure/commit/980e9f1) | High |
| Dashboard folder "Sdui" exists in Coralogix with the Sdui prod health and logins dashboard (Git keeps a backup copy; content is edited in the UI). | [Infrastructure#84](https://github.com/7education/Infrastructure/pull/84), merged 2026-11-17; `list_dashboard_folders` shows "Sdui" | High |
| Unknown: whether the old Grafana alerts for Sdui are switched off. | Not checked; `infra-k8s-sduiapp` is in `sdui-hq`, not watched | Open |

Tool gap: `Infrastructure` had 164 single-parent commits on `master` from 2026-11-01 to 2026-11-27 but 43 merged PRs, so
many changes there never show up in `collect.sh` output (it reads merged PRs only).
