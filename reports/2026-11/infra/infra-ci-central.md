# infra-ci-central, 2026-11

## Numbers
- Merged PRs: 7 (previous month: 10)
- Lines: +172 / -81 (computed from the 7 PRs)
- Human authors: 2 (suraj-sdui 5 PRs, mikolajgruszecki 2). Bot PRs: 0
- Releases: 0. Issues opened: 0. Open PRs now: 2

## Highlights
- Security: sdux IAM and ODS Ingresses were reachable from the whole internet (RabbitMQ management UI, ODS swagger/API/admin returned 200 from a non-VPN address). They now have a VPN allowlist. [#49](https://github.com/7education/infra-ci-central/pull/49)
- nginx sidecars upgraded 1.28.2 to 1.30.7 (fixes CVEs); feature-env Ingresses no longer use FastCGI, which Traefik does not support. This unblocks the move from the archived ingress-nginx to Traefik. [#47](https://github.com/7education/infra-ci-central/pull/47)
- GitLab decommission step: feature environments no longer pull `imaginary` and `redis` through the GitLab dependency proxy, so pods would not break when GitLab is switched off. [#43](https://github.com/7education/infra-ci-central/pull/43), [#45](https://github.com/7education/infra-ci-central/pull/45)

## Themes
- Move sdux from ingress-nginx to Traefik, with hardening (INFRA-2070): #47, #48 (regex paths as ImplementationSpecific, because Traefik skipped one Ingress and ods-mono-main returned 404), #49. Links: [#47](https://github.com/7education/infra-ci-central/pull/47), [#48](https://github.com/7education/infra-ci-central/pull/48), [#49](https://github.com/7education/infra-ci-central/pull/49)
- Retire the GitLab instance (INFRA-1895): #43 and #45 (same change landed on main). [#43](https://github.com/7education/infra-ci-central/pull/43), [#45](https://github.com/7education/infra-ci-central/pull/45)
- Langfuse and AI access: ClickHouse cluster mode disabled for the single-node langfuse setup, which fixes migrations written for a clustered setup ([#46](https://github.com/7education/infra-ci-central/pull/46)); Seven AI egress IPs allowlisted for the MCP chat server ([#52](https://github.com/7education/infra-ci-central/pull/52)).

## People
- suraj-sdui: both infra themes (INFRA-2070, INFRA-1895), 5 PRs.
- mikolajgruszecki: Langfuse fix and the MCP allowlist, 2 PRs.

## In flight
- [#50](https://github.com/7education/infra-ci-central/pull/50) (rustamgk): review environments for the OVH dev cluster (INFRA-2089).
- [#44](https://github.com/7education/infra-ci-central/pull/44) (strickersteffen): digest-pinned Holder feature deployment (SC-1864).

## Unclear
- #43 and #45 share a title and diff size; #45 says "(main)". Is #43 a branch-targeted copy of the same change?
- The Traefik cutover on sdux is validated alongside ingress-nginx; is a cutover date known?
