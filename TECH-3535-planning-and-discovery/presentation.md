# EW1R-REP-01 — Decommission Investigation
## Presentation Document — Epic TECH-3535

> **Purpose of this Epic:** Investigate and document EW1R-REP-01 to establish a complete inventory of workloads, consumers, and dependencies — and produce a decommission readiness assessment with retire / replace / move recommendations.
>
> **Scope:** Read-only discovery. No decommission execution is in scope.

---

## The One-Line Answer

> **EW1R-REP-01 is not safe to decommission today.**
> 6 stakeholder questions must be answered first, and 4 active workloads must be migrated before the server can be switched off.
> The May 2026 MemSQL job disable silently cut off 2 active products — KAPP and FinancialPortal. Nobody noticed.

---

## What Is This Server

EW1R-REP-01 is a custom-built monitoring and reporting hub running on an **AWS EC2 instance** (Windows Server 2019 Datacenter). It is not a standard product — it runs a bespoke framework called **VCC (Virtualised Collection & Consolidation)** built by the DBA team.

It collects data from production systems across SingleStore, MySQL, AWS, and SQL Server, stores it locally, and serves 74 Grafana dashboards to the DB engineering team and potentially to clients.

| Property | Value |
|---|---|
| Hostname | EW1R-REP-01 |
| IP Address | 10.72.8.216 |
| Platform | AWS EC2 — Windows Server 2019 Datacenter |
| SQL Server | 2019 Developer Edition (15.0.4455.2) |
| Grafana | 9.5.2 — port 443 (HTTPS) |
| Environment | Non-production host monitoring production systems |

---

## Architecture — Layer by Layer

The server operates across 4 distinct layers. Understanding each layer is required before any decommission decision can be made.

### Layer 1 — Data Sources (What It Connects To)

EW1R-REP-01 reaches out to production systems across 4 AWS regions via 109 linked servers.

| Region | Systems Monitored | Status |
|---|---|---|
| EW1 (Europe West 1) | Zabbix, InfluxDB, AWS APIs, Jira/Confluence | ✅ Active |
| EW2 (Europe West 2) | SingleStore aggr/leaf nodes, SQL Server EW2P-MSSQL-01/02, KAPP MySQL | ✅ Active (some nodes dead) |
| UE1 (US East 1) | SingleStore aggr/leaf nodes, KAPP MySQL | ✅ Active (some nodes dead) |
| EC1 (Europe Central 1) | SingleStore aggr/leaf nodes, KAPP MySQL | ✅ Active |

**Dead connections (confirmed):** 4 WPv2 linked servers (DNS gone), 7 stale SingleStore nodes (gen-rel/gen-prd retired) — 11 of 109 linked servers confirmed unreachable.

> Full linked server breakdown → [External Targets — Confluence](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6854344805/External+Targets+EW1R-REP-01)

---

### Layer 2 — Collection Engine (How It Collects)

SQL Server Agent runs 63 scheduled jobs that execute stored procedures to pull data from linked servers and write it into local databases.

| Job Category | Count | Status |
|---|---|---|
| VCC AWS / KAPP collection | ~16 | ✅ Running every 30 min |
| VCC MemSQL collection | 7 | ⚠️ All disabled since May 2026 |
| VCC MySQL / DXM collection | ~8 | ✅ Active (2 failing — WPv2 dead) |
| DBA Maintenance (backup, CHECKDB) | ~12 | ✅ Active |
| Encore / Atlassian / Baseline | ~10 | ✅ Active |
| Disabled / stale | 11 | ❌ Disabled |

**Service account:** `SHNONPRD\sqlagent` runs all SQL Agent jobs.

> Full job inventory → [SQL Server Inventory — Confluence](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6847725586/SQL+Server+Inventory+EW1R-REP-01)

---

### Layer 3 — Storage (What It Holds)

8 databases totalling **369 GB** (exact — confirmed 2026-07-20 from `sys.master_files`).

| Database | Size | Purpose | Status |
|---|---|---|---|
| DBA_VCC_AWS | 185.66 GB | AWS + KAPP API monitoring — 583M row KAPP query log | ✅ Active — growing ~1M rows/day |
| DBA_VCC_MEMSQL | 75.50 GB | SingleStore monitoring | ⚠️ All 7 jobs disabled since May 2026 |
| KURTOSYS_BASELINE | 50.00 GB | Connection and table size baselines | ✅ Active |
| DBA_VCC_MYSQL | 27.00 GB | MySQL / RDS / DXM monitoring | ⚠️ 2 jobs failing (WPv2 DNS dead) |
| DBA_VCC | 24.17 GB | Core VCC framework + Encore / BNY IIS logs | ✅ Active |
| DBA_VCC_COST | 5.00 GB | KAPP client entity counts — billing data | ⚠️ Stale since 4 May 2026 |
| DBA_VCC_ATLASSIAN | 2.00 GB | Jira / Confluence sprint data | ✅ Active |
| Utilities | 0.20 GB | DBA maintenance scripts | ✅ Active |

**~600+ stored procedures** across all 8 databases implement the collection, transformation, and reporting logic.

> Full database inventory → [SQL Server Inventory — Confluence](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6847725586/SQL+Server+Inventory+EW1R-REP-01)

---

### Layer 4 — Presentation (What It Serves)

Grafana 9.5.2 reads directly from SQL Server on localhost and serves dashboards over HTTPS (port 443).

| Metric | Count |
|---|---|
| Datasources | 21 |
| Dashboards | 74 |
| Users | 8 (5 admins, 3 viewers) |
| Active admins (as of June 2026) | 3 |
| Alert rules | 3 |
| Active Slack contact points | 2 |

**10 dashboards actively maintained in 2025.** 14 dashboards reading from DBA_VCC_MEMSQL — all showing stale data since May 2026.

> Full Grafana inventory → [Grafana Inventory — Confluence](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6850314252/Grafana+Inventory)

---

### Layer 5 — Consumers (Who Depends on It)

| Consumer | What They Get | Criticality |
|---|---|---|
| tashvir.babulal, yogeshwar.phull, rayhaan.suleyman | 74 Grafana dashboards — KAPP, SingleStore, AWS, Encore, Zabbix, Jira | Critical |
| alerts-data-operations (Slack) | KAPP client config and read query failure alerts | High |
| alert-app-allow2fa-disabled (Slack) | KAPP client auth config alerts | High |
| dba@kurtosys.com | SQL Agent job failure alerts (backups, CHECKDB, disk) | High |
| Client-facing (unconfirmed) | KAPP Client Utilisation and Growth Report — 280 institutional clients tracked | ⚠️ Critical — must confirm |

> Consumer mapping → [Consumers & Dependencies — Confluence](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6853460033/Consumers+and+Dependencies)

---

## Investigation Themes

The Epic was split into 4 investigation themes, each mapped to a Jira ticket.

---

### Theme A — SQL Server (TECH-3560)

**What was investigated:** All 8 databases, 63 SQL Agent jobs, 109 linked servers, ~600 stored procedures, service accounts, and backup configuration.

**Key findings:**

| Finding | Impact |
|---|---|
| AWS Cost ETL silently broken since Sept 2024 | 2.4M rows stuck in staging. `INFO_AWS_Entity_Cost` stale for 22 months. Job reports Succeeded — no alert fired |
| All 7 DBA_VCC_MEMSQL jobs disabled since May 2026 | 14 Grafana dashboards stale. KAPP and FinancialPortal data collection cut off as a side effect |
| DBA_VCC_COST billing data stale since 4 May 2026 | 280 institutional clients tracked — May and June 2026 figures may be wrong |
| WPv2 linked servers dead — 2 jobs failing daily | DNS gone, 4 linked servers unreachable, 2 jobs failing every day since 25 June 2026. No alert |
| 7 additional stale linked servers | gen-rel and gen-prd SingleStore nodes never cleaned up after generation upgrade |
| KAPP MERGE performance risk | 583M rows, 145 GB, growing ~1M rows/day. MERGE already taking 9+ min on a 30-min schedule. CHECKDB takes 40 min nightly |

> Full findings → [SQL Server Investigation Log — Confluence](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6848282648/SQL+Server+Investigation+Log) | [GitHub](../TECH-3560-theme-a-sql-server/investigation-log.md)

---

### Theme B — Grafana (TECH-3561)

**What was investigated:** All 21 datasources, 74 dashboards with last-updated dates and datasource mapping, 8 users, 3 alert rules, 3 contact points, 10 plugins.

**Key findings:**

| Finding | Impact |
|---|---|
| 14 dashboards reading from DBA_VCC_MEMSQL | All showing stale data since May 2026 — 6 month-end dashboards had no fresh data for June 2026 reporting |
| 4 Zabbix datasources using ex-employee credentials | donovan.vangraan inactive since Nov 2024 — credentials need rotation before migration |
| Default admin account still active | Security risk — should be disabled |
| Email contact point is a placeholder | Will never deliver alerts — broken since creation |
| DBA_VCC has two datasource entries with different UIDs | Dashboards split across both — must resolve before any migration |

> Full findings → [Grafana Investigation Log — Confluence](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6851067926/Grafana+-+Investigation+Log) | [GitHub](../TECH-3561-theme-b-grafana/investigation-log.md)

---

### Theme C — Targets & Consumers (TECH-3562)

**What was investigated:** All 109 linked servers mapped by type and region, consumer identification, service accounts, firewall rules, and data freshness validation.

**Key findings:**

| Finding | Impact |
|---|---|
| DBA_VCC_COST confirmed client billing data | 280 real institutional clients (BlackRock, BNY Mellon, Aberdeen, Wellington, T. Rowe Price, Nordea and others) across EW2, UE1, EC1 |
| All 9 INFO_KAPP_Client_* tables stale since 4 May 2026 | 11+ consecutive silent zero-row runs confirmed 2026-07-20. Job reports Succeeded every Sunday |
| 19 REP_MONTHEND procedures in DBA_VCC_COST + 14 in DBA_VCC_MEMSQL | Who calls them each month end is still open — no confirmed consumer identified |
| LU_EntityList data quality issues | `Enviroment` column typo, mixed case values, leading spaces — never corrected since 2022 |

> Full findings → [Targets & Consumers Investigation Log — Confluence](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6853918807/Investigation+Log+for+External+Target+and+Consumers) | [GitHub](../TECH-3562-theme-c-targets-and-consumers/investigation-log.md)

---

### Theme D — Classification & Topology (TECH-3563)

**What was investigated:** Full topology map, component-by-component classification (retire / replace / move / investigate), and preliminary decommission recommendation.

**Component classification:**

| Component | Decision | Reason |
|---|---|---|
| DBA_VCC_AWS (KAPP monitoring) | Replace | Core KAPP observability — cannot retire |
| DBA_VCC_COST (cost tracking) | Replace | Confirmed client billing — 280 clients |
| DBA_VCC_MYSQL (MySQL monitoring) | Replace | Active MySQL / RDS / DXM monitoring |
| DBA_VCC (Encore / BNY) | Replace | Active Encore monitoring |
| Grafana (74 dashboards) | Replace / Move | 3 active admins, actively used |
| DBA Maintenance jobs | Move | Needed on any replacement host |
| DBA_VCC_MEMSQL (MemSQL monitoring) | Retire | All jobs disabled — likely superseded |
| SingleStore linked servers (90) | Retire | All MemSQL jobs disabled |
| WPv2 linked servers (4) | Retire | DNS gone — confirmed decommissioned |
| InvestorPress procs and tables | Retire | Confirmed decommissioned — 2,047 rows, procs last modified 2023 |
| KURTOSYS_BASELINE | Investigate | 50 GB — no confirmed consumer |
| DBA_VCC_ATLASSIAN | Investigate | No confirmed consumer |

> Full topology and classification → [Topology & Classification — Confluence](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6860963905/Topology+Classification+EW1R-REP-01) | [GitHub](../TECH-3563-theme-d-classification-and-topology/topology-and-classification.md)

---

## The 40 / 40 / 20 Split

Think of the server's components in three buckets:

### 40% — Can be cleaned up now (low risk)
Confirmed dead or broken with no active consumer:
- 11 dead linked servers (WPv2, gen-rel, gen-prd, partial SingleStore nodes)
- InvestorPress stored procedures and tables — confirmed decommissioned
- WPv2 stored procedures — confirmed decommissioned
- 4 disabled DBA jobs — stale, MemSQL-related

### 40% — Must be migrated before decommission
Active workloads that will break if the server is switched off:
- VCC monitoring framework — 24 jobs watching EW2P-MSSQL-01 and EW2P-MSSQL-02
- Encore monitoring — collecting today
- DBA_VCC_AWS (185 GB) — KAPP API query tracking, collecting every 30 minutes
- DBA_VCC_COST (5 GB) — client billing data, FULL recovery model
- DBA_VCC_MYSQL — DXM side active and healthy
- Grafana (74 dashboards) — datasources point to databases on this server
- EW1P-OCT backup job — daily RDS backup to S3

### 20% — Unknown, needs stakeholder answers first
- KURTOSYS_BASELINE (50 GB) — no confirmed consumer
- 4 linked servers with unknown purpose (EW1R-TC, EW1P-NIFIREG-01, pmmdev, pmmprod)
- 7 disabled MemSQL jobs — cannot drop until Q35 is answered
- DBA_VCC_MEMSQL (75 GB) — contains KAPP and FinancialPortal data from before the May 2026 disable

---

## 6 Decommission Blockers

No decommission date can be set until these are answered:

| # | Question | Ask | Why It Blocks |
|---|---|---|---|
| Q13 | Who owns the KAPP monitoring data in DBA_VCC_AWS? Is it used for SLA reporting? | KAPP engineering / platform team | If SLA — cannot decommission without confirmed replacement |
| Q21 | If this server went offline today, what would break immediately? | yogeshwar.phull / tashvir.babulal | Required for decommission risk assessment |
| Q22 | Is any alerting dependent solely on this server — would anyone lose visibility? | yogeshwar.phull / tashvir.babulal | Required for decommission risk assessment |
| Q23 | Is the VCC framework replicated anywhere else or is this the only instance? | DBA team | If not replicated — single point of failure |
| Q35 | Who disabled the DBA_VCC_MEMSQL jobs in May 2026 and why? | yogeshwar.phull / tashvir.babulal | KAPP and FinancialPortal data collection was cut off as a side effect — must not re-enable without understanding root cause |
| Q36 | Has anyone noticed that DBA_VCC_COST billing data has been stale since 4 May 2026? | tashvir.babulal / rayhaan.suleyman | Must disclose immediately — May and June billing figures may be wrong |

> Full open questions list → [Open Questions — GitHub](../TECH-3535-planning-and-discovery/open-questions.md)

---

## Active Problems Found — Independent of Decommission

These exist right now and need fixing regardless of whether the server is decommissioned:

| Problem | Impact |
|---|---|
| 2 SQL Agent jobs failing daily | WPv2 cleanup never done — silent failures since June 2026 |
| 14 Grafana dashboards showing stale data since May 2026 | June 2026 month-end reporting was impacted silently |
| AWS Cost ETL silently broken since Sept 2024 | 2.4M rows stuck in staging — job reports Succeeded |
| DBA_VCC_COST billing data stale since 4 May 2026 | 280 clients — May and June figures may be wrong |
| SQL Agent alert system fully silent | 16 alerts configured, operator exists, nothing wired — no alerts will ever fire |
| Backup jobs syncing to S3 with no encryption | Compliance risk — 3 jobs, no `--sse` flag, EW1P-OCT KMS key NULL |
| EW1R-REP-01 not in Zabbix | Server has no external monitoring — if it goes down, nothing alerts |
| 4 Zabbix datasources using ex-employee credentials | donovan.vangraan inactive since Nov 2024 |
| KAPP MERGE growing ~1M rows/day | 583M rows, 145 GB — MERGE will eventually exceed 30-min collection window |

---

## What Needs to Happen — In Order

**Phase 1 — Fix active failures (do now, independent of decommission)**
1. Remove WPv2 steps from 2 failing jobs
2. Wire dba@kurtosys.com operator to SQL Agent alerts
3. Add EW1R-REP-01 to Zabbix monitoring
4. Fix S3 backup encryption gap
5. Rotate ex-employee Zabbix credentials (4 Grafana datasources)

**Phase 2 — Answer the 6 blocking questions**
1. Confirm DBA_VCC_COST consumer and client-facing dashboard status (Q13, Q21, Q22, Q36)
2. Confirm MemSQL jobs disable reason (Q35)
3. Confirm VCC framework replication status (Q23)

**Phase 3 — Clean up confirmed dead components**
1. Drop 11 dead linked servers
2. Archive DBA_VCC_MEMSQL to S3 then drop (pending Q35)
3. Drop dead stored procedures (WPv2, InvestorPress)

**Phase 4 — Migrate active workloads**
1. Migrate VCC monitoring framework to a new host
2. Migrate DBA_VCC_AWS and DBA_VCC_COST to new host or RDS
3. Migrate Grafana (TECH-3479 scope)
4. Migrate EW1P-OCT backup job

**Phase 5 — Decommission**
Only after Phase 1–4 are complete and signed off.

**Realistic earliest decommission date: 10–12 weeks from stakeholder answers being received.**

---

## Documentation Index

All detailed evidence, query outputs, and inventory data lives in Confluence. GitHub stores the raw artefacts.

| Document | Confluence | GitHub |
|---|---|---|
| Discovery Queries (14 sections) | [View](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6841237572/06+-Discovery+Queries) | [discovery-queries.sql](../TECH-3535-planning-and-discovery/discovery-queries.sql) |
| Discovery Summary | — | [discovery-summary.md](../TECH-3535-planning-and-discovery/discovery-summary.md) |
| Open Questions (36 questions) | — | [open-questions.md](../TECH-3535-planning-and-discovery/open-questions.md) |
| Architecture Diagram | — | [ew1r-rep-01-architecture.drawio](../TECH-3535-planning-and-discovery/ew1r-rep-01-architecture.drawio) |
| SQL Server Inventory | [View](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6847725586/SQL+Server+Inventory+EW1R-REP-01) | [sql-server-inventory.md](../TECH-3560-theme-a-sql-server/sql-server-inventory.md) |
| SQL Server Investigation Log | [View](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6848282648/SQL+Server+Investigation+Log) | [investigation-log.md](../TECH-3560-theme-a-sql-server/investigation-log.md) |
| Grafana Inventory | [View](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6850314252/Grafana+Inventory) | [grafana-inventory.md](../TECH-3561-theme-b-grafana/grafana-inventory.md) |
| Grafana Investigation Log | [View](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6851067926/Grafana+-+Investigation+Log) | [investigation-log.md](../TECH-3561-theme-b-grafana/investigation-log.md) |
| External Targets | [View](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6854344805/External+Targets+EW1R-REP-01) | [external-targets.md](../TECH-3562-theme-c-targets-and-consumers/external-targets.md) |
| Consumers & Dependencies | [View](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6853460033/Consumers+and+Dependencies) | [consumers-and-dependencies.md](../TECH-3562-theme-c-targets-and-consumers/consumers-and-dependencies.md) |
| Targets & Consumers Investigation Log | [View](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6853918807/Investigation+Log+for+External+Target+and+Consumers) | [investigation-log.md](../TECH-3562-theme-c-targets-and-consumers/investigation-log.md) |
| Topology & Classification | [View](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6860963905/Topology+Classification+EW1R-REP-01) | [topology-and-classification.md](../TECH-3563-theme-d-classification-and-topology/topology-and-classification.md) |
| Topology Investigation Log | [View](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6860243025/Topology+-+Investigaton+Log) | [investigation-log.md](../TECH-3563-theme-d-classification-and-topology/investigation-log.md) |
| Decommission Readiness | — | [decommission-readiness.md](../TECH-3410-current-sprint/decommission-readiness.md) |

---

## Related Jira Tickets

| Ticket | Theme | Status |
|---|---|---|
| [TECH-3535](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3535) | Planning & Discovery | In Progress |
| [TECH-3560](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3560) | Theme A — SQL Server | In Progress |
| [TECH-3561](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3561) | Theme B — Grafana | In Progress |
| [TECH-3562](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3562) | Theme C — Targets & Consumers | In Progress |
| [TECH-3563](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3563) | Theme D — Classification & Topology | In Progress |
