# infra-k8s-countly, 2026-11

## Numbers
- Merged PRs: 1 (previous month: 11)
- Lines: +2 / -2, 2 files
- Human authors: 1 (muhammadali7edu). Bot PRs: 0
- Releases: 0. Issues opened: 0. Open PRs now: 2

## Highlights
- Storage increase for the Countly analytics stack: ClickHouse server PVC to 2500Gi and Kafka broker PVCs to 400Gi (title is truncated in the data, so the Kafka size is read from "…00Gi" in the body start; see Unclear). Capacity change in production storage. [#34](https://github.com/7education/infra-k8s-countly/pull/34)

## People
- muhammadali7edu: the only merged PR (#34).

## In flight
- [#33](https://github.com/7education/infra-k8s-countly/pull/33) (aheumaier): keep the chart revision label off Strimzi pods.
- [#32](https://github.com/7education/infra-k8s-countly/pull/32) (aheumaier): rightsize Kafka and ClickHouse StatefulSet requests, planned for a maintenance window.

## Unclear
- Is the Kafka broker PVC size 400Gi or 4xx Gi? The title is cut ("4…" + "…00Gi"), and the PR body is empty.
- Why did the volume need to grow (data growth, retention change)? No description in the PR.
- Does #32 (rightsizing requests) follow from #34? Not stated.
