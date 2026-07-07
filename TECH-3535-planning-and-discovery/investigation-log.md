# TECH-3535 — Planning & Discovery

---

## Summary

Perform initial investigation and discovery on EW1R-REP-01 to understand what is running, what depends on it, and what risks exist before any decommission work begins.

EW1R-REP-01 is a non-production Windows host running SQL Server 2019 and Grafana 9.5.2. It hosts the VCC (Visibility and Cost Control) framework — a custom DBA-built monitoring platform that collects data from KAPP, SingleStore, MySQL, AWS, Jira, and Zabbix. Production does not run on this server but production visibility depends on it. It is the only known instance of the VCC framework.

---

## Scope

| # | Scope Item | Status | Owner Ticket |
|---|---|---|---|
| 1 | Run SQL discovery queries and capture outputs | ✅ Done | TECH-3535 |
| 2 | Inventory SQL Server and Grafana components | ✅ Done | TECH-3478 / TECH-3479 |
| 3 | Map external targets and consumers | 🔄 In Progress | TECH-3480 |
| 4 | Document open questions and blockers | ✅ Done | TECH-3535 |
| 5 | Produce a topology and risk classification | ⏳ Blocked | TECH-3481 |

---

## Definition of Done — Progress

| DoD Item | Status | Notes |
|---|---|---|
| All discovery queries executed and outputs captured | ✅ Done | 11 sections of discovery queries run — captured in discovery-queries.sql |
| SQL Server inventory complete (jobs, databases, linked servers) | ✅ Done | Jobs, databases, 109 linked servers inventoried — TECH-3478 owns the detail |
| Grafana inventory complete (datasources, dashboards, users, alerts) | ✅ Done | 21 datasources, dashboards, 3 active users, 2 alert channels captured — TECH-3479 owns the detail |
| External targets and consumers mapped | 🔄 In Progress | Data sources identified — consumer confirmation still open, TECH-3480 owns this |
| Open questions documented and blockers escalated | ✅ Done | 34 open questions logged in open-questions.md — critical blockers flagged |
| Topology and classification published to Confluence | ⏳ Blocked | Blocked on TECH-3478, TECH-3479, TECH-3480 completing — TECH-3481 owns this |

---

## What we found — by scope item

### 1. Discovery queries

Initial discovery queries executed across 11 sections covering server basics, databases, jobs, linked servers, Grafana, AWS cost data, and job-to-linked-server mapping. All outputs captured in discovery-queries.sql.

---

### 2. SQL Server inventory

- SQL Server 2019 Developer Edition — not clustered, no AG
- Three service accounts: SQL Server engine, SQL Agent, Launchpad (Python-based API jobs)
- SQL Agent jobs running on schedules from every 15 minutes to daily
- 109 linked servers connecting to SingleStore, MySQL, and RDS targets
- Several linked servers confirmed unreachable — WPv2 platform decommissioned, 4 linked servers dead
- Additional stale targets identified beyond WPv2
- At least two ETL jobs have silent failures — CATCH blocks swallow errors, jobs report Succeeded

→ Full detail in TECH-3478

### 2b. Grafana inventory

- Grafana 9.5.2 on port 443 (HTTPS)
- 21 datasources: SQL Server (localhost), KAPP MySQL, SingleStore, Zabbix MySQL, NiFi, CloudWatch, InfluxDB
- 3 active admin users, 1 inactive builder (no longer active)
- 2 Slack alert channels configured — email contact point is a placeholder, not configured
- Some dashboards are candidates for client-facing or SLA use — not yet confirmed

→ Full detail in TECH-3479

---

### 3. External targets and consumers

Data sources feeding into EW1R-REP-01: KAPP, SingleStore, MySQL, AWS, Jira, Zabbix.

- Not all targets are reachable — WPv2 confirmed decommissioned, others suspected stale
- Consumers: DB engineering confirmed. Client-facing unconfirmed
- AWS cost data stale since September 2024 — no consumer noticed, raises questions about active use

→ Full detail in TECH-3480

---

### 4. Open questions and blockers

34 open questions documented. Critical blockers escalated:

- WPv2 decommission cleanup — no owner assigned, jobs failing silently daily
- Client-facing dashboard exposure — not confirmed, needs stakeholder input
- Consumer confirmation for AWS cost and KAPP data — needed before any decommission decision

→ Full list in open-questions.md

---

### 5. Topology and risk classification

Not started. Blocked on Themes A, B, and C completing their discovery.

Risks identified at discovery level:

| Risk | Owner Ticket | Priority |
|---|---|---|
| WPv2 linked servers dead — jobs failing silently daily | TECH-3478 | Critical |
| Additional stale linked servers beyond WPv2 | TECH-3478 | Critical |
| Client-facing dashboard exposure not confirmed | TECH-3479 / TECH-3480 | Critical |
| VCC framework may be single point of failure — not replicated | All | High |
| Silent ETL failures — errors swallowed, jobs report Succeeded | TECH-3478 | High |
| AWS cost data stale since Sept 2024 — no alert, no one noticed | TECH-3478 / TECH-3480 | High |
| MERGE on large unpartitioned table approaching schedule interval | TECH-3478 | High |
| No runbook or documentation exists for this server | All | Medium |
| Developer Edition not licensed for production use | TECH-3478 | Medium |

→ Full topology and classification in TECH-3481 once upstream themes complete

---

## Links

| Resource | Location |
|---|---|
| Discovery queries | TECH-3535-planning-and-discovery/discovery-queries.sql |
| Open questions | TECH-3535-planning-and-discovery/open-questions.md |
| Architecture diagram | TECH-3535-planning-and-discovery/ew1r-rep-01-architecture.drawio |
| SQL Server detail | TECH-3478-theme-a-sql-server/investigation-log.md |
| Grafana detail | TECH-3479-theme-b-grafana/investigation-log.md |
| Targets & consumers detail | TECH-3480-theme-c-targets-and-consumers/investigation-log.md |
| Topology & classification | TECH-3481-theme-d-classification-and-topology/investigation-log.md |
| Confluence | TBC — to be published on completion of TECH-3481 |
