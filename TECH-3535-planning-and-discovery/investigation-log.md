# TECH-3535 — Planning & Discovery — Investigation Log

Scope: High-level discovery of EW1R-REP-01. Read-only. No deep dives.
Purpose: Understand what exists, identify risks at a surface level, and define the scope for each theme ticket.

---

## What is EW1R-REP-01?

A non-production Windows host running two things:
- SQL Server 2019 — hosts the VCC (Visibility and Cost Control) framework, a custom DBA-built monitoring platform
- Grafana 9.5.2 — serves dashboards on port 443 (HTTPS)

It collects data from KAPP, SingleStore, MySQL, AWS, Jira, and Zabbix. Grafana reads from those databases to serve dashboards to the DB engineering team and possibly client-facing consumers. It is the only known instance of the VCC framework.

Production does not run on this server, but production visibility depends on it.

---

## What we found — overview by theme

### Theme A — SQL Server (→ TECH-3478)

- SQL Server 2019 Developer Edition. Not clustered, no AG.
- Developer Edition is not licensed for production use — needs to be confirmed whether this is intentional for a non-prod host.
- Three service accounts confirmed — SQL Server engine, SQL Agent, and Launchpad (used for Python-based API jobs).
- Multiple SQL Agent jobs run on schedules ranging from every 15 minutes to daily.
- Linked servers connect to SingleStore, MySQL, and RDS targets — 109 linked servers total.
- Several linked servers are confirmed unreachable. WPv2 platform has been decommissioned — 4 linked servers pointing to it are dead. Additional stale targets identified beyond WPv2.
- At least two ETL stored procedures have silent failures — errors are swallowed by CATCH blocks, jobs report Succeeded.
- One large table (563M rows, unpartitioned) has a MERGE operation taking 9+ minutes on a 30-minute schedule — performance risk for RDS migration.

Action items for TECH-3478:
- Full linked server reachability audit
- Identify all jobs referencing stale linked servers
- Investigate silent ETL failures
- Assess MERGE performance risk before RDS migration

---

### Theme B — Grafana (→ TECH-3479)

- Grafana 9.5.2 running on port 443.
- 21 datasources confirmed — SQL Server (localhost), KAPP MySQL, SingleStore, Zabbix MySQL, NiFi, CloudWatch, InfluxDB.
- 3 active admin users. One inactive builder (donovan.vangraan) who is no longer active.
- Alert channels configured — 2 Slack channels. Email contact point is a placeholder, not configured.
- Some dashboards are candidates for client-facing or SLA use — not yet confirmed.

Action items for TECH-3479:
- Confirm which dashboards are client-facing or SLA-related
- Confirm who the consumers are (engineering only vs wider business)
- Assess impact if Grafana goes offline

---

### Theme C — Targets & Consumers (→ TECH-3480)

- Data sources feeding into EW1R-REP-01: KAPP, SingleStore, MySQL, AWS, Jira, Zabbix.
- Not all targets are reachable — WPv2 confirmed decommissioned, others suspected stale.
- Consumers of the data are not fully confirmed — DB engineering is confirmed, client-facing is unconfirmed.
- AWS cost data has been stale since at least September 2024 — not noticed by any consumer, which raises questions about whether it is actively used.

Action items for TECH-3480:
- Confirm full list of reachable vs stale data sources
- Confirm who consumes each data feed and for what purpose
- Confirm whether any data feeds into client billing or SLA reporting

---

### Theme D — Classification & Topology (→ TECH-3481)

- Not started. Blocked on Themes A, B, and C completing their discovery.
- Once the above themes confirm what is alive, what is stale, and who consumes what — Theme D will classify each component and produce a topology map.

Action items for TECH-3481:
- Wait for TECH-3478, TECH-3479, TECH-3480 to complete
- Classify each database, job, linked server, and dashboard as active / stale / unknown
- Produce a topology diagram showing data flow from source to consumer

---

## Risks identified at discovery level

| Risk | Theme | Priority |
|---|---|---|
| WPv2 linked servers dead — jobs failing silently daily | TECH-3478 | Critical |
| Additional stale linked servers beyond WPv2 | TECH-3478 | Critical |
| Silent ETL failures — errors swallowed, jobs report Succeeded | TECH-3478 | High |
| MERGE on 563M row table approaching schedule interval | TECH-3478 | High |
| Developer Edition not licensed for production use | TECH-3478 | Medium |
| AWS cost data stale since Sept 2024 — no alert, no one noticed | TECH-3478 / TECH-3480 | High |
| Client-facing dashboard exposure not confirmed | TECH-3479 / TECH-3480 | Critical |
| No runbook or documentation exists for this server | All themes | Medium |
| VCC framework may be single point of failure — not replicated | All themes | High |

---

## What TECH-3535 does not cover

- Root cause analysis of any failure — that is TECH-3478
- Deep Grafana dashboard audit — that is TECH-3479
- Full consumer confirmation — that is TECH-3480
- Topology mapping and classification — that is TECH-3481

This ticket's job is done when the above themes have enough context to start their own investigations.
