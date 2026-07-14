# EW1R-REP-01 — Discovery & Investigation Summary
# [TECH-3535](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3535) — Planning & Discovery

> **Status:** Discovery complete. Decommission blocked on 6 open stakeholder questions.

---

## Executive Summary

EW1R-REP-01 is a custom-built monitoring and reporting hub running a bespoke VCC (Virtualised Collection & Consolidation) framework. It is the sole source of 74 Grafana dashboards, production Slack alerts, and billing data for 200+ institutional clients. Discovery is complete across all 4 investigation tracks (SQL Server, Grafana, Targets & Consumers, Topology & Classification).

6 critical failures were identified during investigation — including silent ETL breakage since September 2024, all SingleStore collection jobs disabled since May 2026, and client billing data stale for 2 months with no alert fired. The server is not safe to decommission. 6 stakeholder questions (Q13, Q21, Q22, Q23, Q35, Q36) must be answered before any migration or decommission action can proceed.

| Area | Status |
|---|---|
| SQL Server inventory | Complete |
| Grafana inventory | Complete |
| Targets & Consumers mapping | Complete |
| Topology & Classification | Complete |
| Active failures identified | 6 |
| Decommission blockers | 6 open questions |
| Safe to decommission | ❌ No |

---

## Repository Structure

Each folder maps to a Jira ticket. All investigation and discovery work is scoped per ticket.

```
TECH-3535-planning-and-discovery/                        ← Parent — Planning & Discovery
│
│   discovery-summary.md                                 ← Master consolidation doc (this file)
│   discovery-queries.sql                                ← All SQL queries used during investigation (14 sections)
│   open-questions.md                                    ← All open questions, blockers, and active findings
│   investigation-log.md                                 ← Critical findings with query evidence
│   ew1r-rep-01-architecture.drawio                      ← Architecture diagram
│
├── TECH-3560-sql-server/                                ← Child — SQL Server investigation
│   │
│   │   sql-server-inventory.md                          ← Databases, jobs, linked servers, service accounts, stored procs
│   │   investigation-log.md                             ← TECH-3560 findings
│
├── TECH-3561-grafana/                                   ← Child — Grafana investigation
│   │
│   │   grafana-inventory.md                             ← Datasources, dashboards (74 confirmed), users, alert rules
│   │   investigation-log.md                             ← TECH-3561 findings
│
├── TECH-3562-targets-and-consumers/                     ← Child — Targets & Consumers investigation
│   │
│   │   external-targets.md                              ← External targets and connections
│   │   consumers-and-dependencies.md                    ← Consumers, service accounts, firewall rules
│   │   investigation-log.md                             ← TECH-3562 findings
│
└── TECH-3563-topology-and-classification/               ← Child — Topology & Classification investigation
    │
    │   topology-and-classification.md                   ← Topology map and classification outputs
    │   investigation-log.md                             ← TECH-3563 findings
```

**Confluence Documentation**

| Document | Description |
|---|---|
| [Discovery Queries](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6841237572/06+-Discovery+Queries) | All 14 SQL query sections with outputs |
| [SQL Server Inventory](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6847725586/SQL+Server+Inventory+EW1R-REP-01) | Databases, jobs, linked servers, stored procedures |
| [SQL Server Investigation Log](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6848282648/SQL+Server+Investigation+Log) | TECH-3560 findings with query evidence |
| [Grafana Inventory](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6850314252/Grafana+Inventory) | Datasources, dashboards, users, alert rules |
| [Grafana Investigation Log](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6851067926/Grafana+-+Investigation+Log) | TECH-3561 findings with query evidence |
| [Consumers & Dependencies](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6853460033/Consumers+and+Dependencies) | Consumers, service accounts, firewall rules |
| [External Targets](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6854344805/External+Targets+EW1R-REP-01) | External targets and connections |
| [Targets & Consumers Investigation Log](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6853918807/Investigation+Log+for+External+Target+and+Consumers) | TECH-3562 findings with query evidence |
| [Topology & Classification](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6860963905/Topology+Classification+EW1R-REP-01) | Full topology map and component classification |
| [Topology Investigation Log](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6860243025/Topology+-+Investigaton+Log) | TECH-3563 findings with query evidence |

---

## 1. What Is This Server

EW1R-REP-01 is a custom-built monitoring and reporting hub. It is not a standard product — it runs a bespoke framework called VCC (Virtualised Collection & Consolidation) built by the DBA team. It collects data from production systems across SingleStore, MySQL, AWS, and SQL Server, stores it locally, and serves 74 Grafana dashboards to the DB engineering team and potentially to clients.

| Property | Value |
|---|---|
| Hostname | EW1R-REP-01 |
| IP Address | 10.72.8.216 |
| SQL Server | 2019 Developer Edition (15.0.4455.2) |
| OS | Windows Server 2019 Datacenter |
| Grafana | 9.5.2 — port 443 (HTTPS) |
| Environment | Non-production host monitoring production systems |

---

## 2. Key Numbers

| Metric | Count |
|---|---|
| Total databases | 8 |
| Total storage | 378 GB |
| SQL Agent jobs | 63 (52 enabled, 11 disabled) |
| Linked servers | 109 (11 confirmed unreachable) |
| Stored procedures | ~600+ across all databases |
| Grafana datasources | 21 |
| Grafana dashboards | 74 |
| Active Grafana admins | 3 (as of June 2026) |

---

## 3. What It Collects and Stores

| Database | Size | Purpose | Status |
|---|---|---|---|
| DBA_VCC_AWS | 184 GB | AWS + KAPP API monitoring — 563M row KAPP query log | ✅ Active — growing |
| DBA_VCC_MEMSQL | 75 GB | SingleStore monitoring | ⚠️ All 7 jobs disabled since May 2026 |
| KURTOSYS_BASELINE | 51 GB | Connection and table size baselines | ✅ Active |
| DBA_VCC_MYSQL | 26 GB | MySQL/RDS/DXM monitoring | ⚠️ 2 jobs failing (WPv2 DNS dead) |
| DBA_VCC | 24 GB | Core VCC framework + Encore/BNY IIS logs | ✅ Active |
| DBA_VCC_COST | 5 GB | KAPP client entity counts — billing data | ⚠️ Stale since 4 May 2026 |
| DBA_VCC_ATLASSIAN | 2 GB | Jira/Confluence sprint data | ✅ Active |
| Utilities | 0.2 GB | DBA maintenance scripts | ✅ Active |

---

## 4. What It Serves (Consumers)

| Consumer | What They Get | Criticality |
|---|---|---|
| tashvir.babulal, yogeshwar.phull, rayhaan.suleyman | 74 Grafana dashboards — KAPP, SingleStore, AWS, Encore, Zabbix, Jira | Critical |
| alerts-data-operations (Slack) | KAPP client config and read query failure alerts | High |
| alert-app-allow2fa-disabled (Slack) | KAPP client auth config alerts | High |
| dba@kurtosys.com | SQL Agent job failure alerts (backups, CHECKDB, disk) | High |
| Client-facing (unconfirmed) | KAPP Client Utilisation and Growth Report — 200+ institutional clients tracked | ⚠️ Critical — must confirm |

---

## 5. Active Failures Found During Discovery

### F1 — AWS Cost ETL Silently Broken Since September 2024
- **What:** SP_AUDIT_COST_ETL_CLEANUP does `convert(decimal(20,10), Cost)` but Cost is nvarchar. One bad row causes the entire MERGE to roll back. CATCH block swallows the error — job reports Succeeded.
- **Impact:** 2.4M rows stuck in MON_AWS_Entity_Cost staging table. INFO_AWS_Entity_Cost stale since 22 Sept 2024. INFO_AWS_DE_Entity_Cost in DBA_VCC_COST stale since Nov 2024.
- **Action:** Raise separate fix ticket. Out of scope for TECH-3535.

### F2 — All 7 DBA_VCC_MEMSQL Jobs Disabled Since May 2026
- **What:** All 7 MemSQL collection jobs disabled. DAILY_CHECKS failed on 8 May 2026 — likely triggered the decision to disable all.
- **Impact:** 14 Grafana dashboards showing stale data. 6 month-end reporting dashboards (KAPP, Encore, DXM, InvestorPress, WPv2, Other Services) have no fresh data since May 2026. June 2026 month-end reporting was impacted. No alert fired. Nobody was notified.
- **Cascade:** DBA_VCC_COST collection also stopped on the same day — all 9 SP_INFO_KAPP_CLIENT_* procedures depend on DBA_VCC_MEMSQL ping stats being fresh. When MEMSQL jobs were disabled, every SP_INFO found zero live nodes and exited cleanly. Job reports Succeeded. Zero rows written since 4 May 2026.
- **Action:** Do not re-enable without understanding why DAILY_CHECKS failed. Escalate to yogeshwar.phull / tashvir.babulal (Q35).

### F3 — DBA_VCC_COST Billing Data Stale Since 4 May 2026
- **What:** All 9 INFO_KAPP_Client_* tables last updated 4 May 2026. KAPP Client Utilisation and Growth Report dashboard is showing 2-month-old data.
- **Impact:** 200+ real institutional clients tracked (BlackRock, BNY Mellon, Aberdeen, Wellington, T. Rowe Price, Nordea and others). If this feeds billing, May and June 2026 figures are wrong.
- **Action:** Must disclose to tashvir.babulal / rayhaan.suleyman immediately (Q36).

### F4 — WPv2 Linked Servers Dead — 2 Jobs Failing Silently Since 25 June 2026
- **What:** All 4 WPv2 linked servers (ew2p-wpv2, ew2r-wpv2, ue1p-wpv2, ue1r-wpv2) return DNS error 11001 — host not found. WPv2 platform confirmed decommissioned.
- **Impact:** DBA_VCC_MYSQL_DAILY_CHECKS and DBA_VCC_MYSQL_AUDIT_DXM_CLIENT_DETAILED failing every day. No alert configured — nobody was notified.
- **Action:** Remove all 4 linked servers and clean up referencing job steps.

### F5 — 7 Additional Stale Linked Servers Beyond WPv2
- **What:** BASELINE_CONNECTIONS job history confirms further unreachable targets: ew1d-aggr-05, ew1d-aggr-15 (Not Online), ew1r-aggr-03.gen-rel (ODBC misconfigured), ew1r-aggr-05.gen-rel, ew2p-aggr-01.gen-prd, ew2p-aggr-02.gen-prd (Can't connect), EW2P-MARKETING-DB (Not Online — confirmed decommissioned).
- **Impact:** Total confirmed stale: 11 out of 109 linked servers. gen-rel and gen-prd nodes are generation-tagged SingleStore variants never cleaned up after a generation upgrade.
- **Action:** Full reachability audit needed across all 109 linked servers.

### F6 — KAPP MERGE Performance Risk
- **What:** INFO_AWS_KAPP_Query_API_Detail has 563M rows with no partitioning. MERGE already taking 9+ minutes per run on a 30-minute schedule.
- **Impact:** As the table grows this will eventually exceed 30 minutes and runs will overlap. This is a performance risk for any RDS migration — needs redesign before moving.
- **Action:** Raise as decommission blocker for RDS migration planning.

---

## 6. Summaries

### SQL Server — [TECH-3560](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3560)
Full inventory complete. 8 databases, 378 GB, 63 jobs, 109 linked servers, ~600+ stored procedures documented. All critical failures identified and evidenced with query output.

| Resource | Link |
|---|---|
| SQL Server Inventory | [View in Confluence](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6847725586/SQL+Server+Inventory+EW1R-REP-01) |
| SQL Server Investigation Log | [View in Confluence](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6848282648/SQL+Server+Investigation+Log) |

**Open questions for this theme:**

| # | Question | Who to Ask | Status |
|---|---|---|---|
| Q1 | What SSIS packages are checked by DBA - SSISStatusCheck? Where do they run? | Unknown | Open |
| Q3 | Is DBA - Maintenance - SQL Backup EW1P-OCT still needed? Who owns that RDS instance? | Unknown | Open |
| Q4 | Are all 109 SingleStore linked servers still reachable or are most stale? | DBA team | Open |
| Q5 | What credentials are used for linked server connections — where are they stored in vault? | DBA team / DevOps | Open |
| Q28 | Which linked servers are referenced by zero job steps — true orphans safe to drop? | DBA team | Open |
| Q29 | Which stored procedures reference the stale linked servers (WPv2, gen-rel, gen-prd)? | DBA team | Open |
| Q30 | For each enabled job — what database does it feed and what breaks if it stops? | DBA team | Open |
| Q31 | Why does BASELINE_CONNECTIONS still have steps for ew1d-aggr-05 and ew1d-aggr-15? | Unknown | Open |
| Q32 | Are gen-rel and gen-prd SingleStore nodes permanently retired? | SingleStore / Platform team | Open |

---

### Grafana — [TECH-3561](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3561)
Full inventory complete. 21 datasources, 74 dashboards, 8 users (3 active admins, 2 inactive), 3 alert rules, 3 contact points.

| Resource | Link |
|---|---|
| Grafana Inventory | [View in Confluence](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6850314252/Grafana+Inventory) |
| Grafana Investigation Log | [View in Confluence](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6851067926/Grafana+-+Investigation+Log) |

**Key findings:**
- 14 dashboards reading from DBA_VCC_MEMSQL — all showing stale data since May 2026
- 6 month-end dashboards calling REP_MONTHEND procedures — no fresh data since May 2026
- 4 Zabbix datasources using an ex-employee account inactive since Nov 2024 — credentials need rotation
- Default admin account still active — should be disabled
- Email contact point is a placeholder — will never deliver alerts
- DBA_VCC has two datasource entries with different UIDs — dashboards split across both, must resolve before migration

**Open questions for this theme:**

| # | Question | Who to Ask | Status |
|---|---|---|---|
| Q9 | Which teams use the Grafana dashboards — engineering, ops, client-facing? | tashvir.babulal / rayhaan.suleyman | Partial — DB engineering confirmed, client-facing TBC |
| Q13 | Who owns the KAPP monitoring data in DBA_VCC_AWS? Is it used for SLA reporting? | KAPP engineering / platform team | Open — critical |
| Q14 | Is INFO_AWS_KAPP_Query_API_Detail (563M rows) actively read by any dashboard? | tashvir.babulal | Partial |

---

### Targets & Consumers — [TECH-3562](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3562)
External targets and consumers mapped. DBA_VCC_COST confirmed client billing data. DBA_VCC_MEMSQL confirmed broken. Consumer confirmation still needed for month-end procedures.

| Resource | Link |
|---|---|
| Consumers & Dependencies | [View in Confluence](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6853460033/Consumers+and+Dependencies) |
| External Targets | [View in Confluence](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6854344805/External+Targets+EW1R-REP-01) |
| Investigation Log | [View in Confluence](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6853918807/Investigation+Log+for+External+Target+and+Consumers) |

**Key findings:**
- DBA_VCC_COST tracks entity counts for 200+ real institutional clients across EW2, UE1, EC1 — confirmed billing data
- 19 REP_MONTHEND procedures in DBA_VCC_COST + 14 in DBA_VCC_MEMSQL — who calls them each month end is still open
- CLINTGROWTH typo in older DBA_VCC_MEMSQL procedures — both old and new versions still present, never cleaned up
- REP_MONTHEND_MAXDB_SERVER_STATUS_REPORT created 2017 — predates VCC framework, likely a leftover
- LU_EntityList has data quality issues: Enviroment column typo, mixed case values, leading spaces — never corrected since 2022

**Open questions for this theme:**

| # | Question | Who to Ask | Status |
|---|---|---|---|
| Q3 (C) | Who calls REP_MONTHEND_* procedures each month end? | tashvir.babulal / rayhaan.suleyman | Open |
| Q4 (C) | Who receives the Slack alerts from SSISStatusCheck? | DBA team / ops team | Open |
| Q5 (C) | What IAM role/key does the Python AWS API caller use? | DevOps / cloud team | Open |
| Q6 (C) | What S3 bucket do backups go to — bucket name/ARN? | DevOps / cloud team | Open |
| Q7 (C) | Is ZabbixProdOld still active or can it be removed? | Infrastructure team | Open |

---

### Classification & Topology — [TECH-3563](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3563)
Topology map complete. Component classification complete. Preliminary decommission recommendation written. Blocked on 6 stakeholder questions.

| Resource | Link |
|---|---|
| Topology & Classification | [View in Confluence](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6860963905/Topology+Classification+EW1R-REP-01) |
| Topology Investigation Log | [View in Confluence](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6860243025/Topology+-+Investigaton+Log) |

**Classification summary:**

| Component | Classification | Reason |
|---|---|---|
| DBA_VCC_AWS (KAPP monitoring) | Replace | Core KAPP observability — cannot retire |
| DBA_VCC_MYSQL (MySQL monitoring) | Replace | Active MySQL/RDS monitoring |
| DBA_VCC_COST (Cost tracking) | Replace | Confirmed client billing — 200+ clients |
| DBA_VCC_MEMSQL (MemSQL monitoring) | Retire | All jobs disabled, likely superseded |
| DBA_VCC_ATLASSIAN (Jira integration) | Investigate | Unknown consumer |
| KURTOSYS_BASELINE | Investigate | Large (51 GB) — unknown active consumer |
| SingleStore linked servers (90) | Retire | All MemSQL jobs disabled |
| SQL Server linked servers (active) | Move | Still needed for EW2P monitoring |
| Grafana dashboards (74) | Replace/Move | 3 active admins, actively used Oct 2025 |
| VCC AWS jobs | Replace | Move to CloudWatch/native AWS monitoring |
| VCC MemSQL jobs | Retire | All disabled |
| DBA Maintenance jobs | Move | Needed on any replacement host |

---

## 7. Open Questions — Decommission Blockers

These must be answered before any decommission or migration action is taken.

| # | Question | Who to Ask | Why It Blocks |
|---|---|---|---|
| Q13 | Who owns the KAPP monitoring data in DBA_VCC_AWS? Is it used for SLA reporting? | KAPP engineering / platform team | If SLA — cannot decommission without confirmed replacement |
| Q21 | If this server went offline today, what would break immediately? | yogeshwar.phull / tashvir.babulal | Required for decommission risk assessment |
| Q22 | Is any alerting dependent solely on this server — would anyone lose visibility? | yogeshwar.phull / tashvir.babulal | Required for decommission risk assessment |
| Q23 | Is the VCC framework replicated anywhere else or is this the only instance? | DBA team | If not replicated — single point of failure |
| Q35 | Who disabled the DBA_VCC_MEMSQL jobs in May 2026 and why? Was the DAILY_CHECKS failure on 8 May 2026 ever investigated? | yogeshwar.phull / tashvir.babulal | Must not re-enable without understanding root cause |
| Q36 | Has anyone noticed that DBA_VCC_COST billing data has been stale since 4 May 2026? KAPP Client Utilisation and Growth Report is showing 2-month-old data. | tashvir.babulal / rayhaan.suleyman | Must disclose immediately — May and June billing figures may be wrong |

---

## 8. Decommission Recommendation (Preliminary)

**This server is not safe to decommission based on current evidence.**

It is:
- Actively collecting production KAPP, MySQL, and AWS data every 30 minutes
- Serving 74 Grafana dashboards to at least 3 active users as of June 2026
- The sole source of SingleStore and Zabbix monitoring dashboards
- Running production Slack alerts for KAPP client config and read query failures
- Tracking billing data for 200+ real institutional clients

**Before decommission can proceed:**
1. Q13, Q21, Q22, Q23, Q35, Q36 must be answered by stakeholders
2. Ex-employee Zabbix credentials rotated — 4 Grafana datasources still using that account
3. Replacement monitoring confirmed in place (TECH-3428)
4. All 3 active Grafana admins notified and migrated to replacement
5. Slack alert channels re-routed to new host
6. All stale linked servers cleaned up (11 confirmed unreachable)
7. AWS cost ETL bug fixed (separate ticket)

---

## 9. Confirmed Facts (Evidence-Backed)

> All facts below are backed by query evidence. Full queries available in the [Discovery Queries Confluence page](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6841237572/06+-Discovery+Queries).

| Fact | Source |
|---|---|
| 109 linked servers (103 MSDASQL + 6 SQLNCLI) | [query 3.1](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6841237572/06+-Discovery+Queries) — sys.servers |
| 90 SingleStore nodes across 4 clusters | [query 3.2](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6841237572/06+-Discovery+Queries) — linked server breakdown |
| 63 jobs (52 enabled, 11 disabled) | [query 2.1](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6841237572/06+-Discovery+Queries) — sysjobs |
| 378 GB total storage | [query 1.2](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6841237572/06+-Discovery+Queries) — sys.master_files |
| 74 Grafana dashboards | [query 9.5 + 13.7](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6841237572/06+-Discovery+Queries) — grafana.db |
| 21 Grafana datasources | [query 12.6](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6841237572/06+-Discovery+Queries) — grafana.db |
| DBA_VCC_AWS_15MIN_CHECKS runs every 30 min (:00 and :30) | [query 2.2](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6841237572/06+-Discovery+Queries) — job history evidence |
| DBA_VCC_COST last collected 4 May 2026 (not 29 June as job history suggests) | [query 5.1](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6841237572/06+-Discovery+Queries) — data freshness |
| 200+ institutional clients in LU_KAPP_ClientList | [query 5.2](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6841237572/06+-Discovery+Queries) — DBA_VCC_COST |
| 2.4M rows stuck in MON_AWS_Entity_Cost staging | [query 4](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6841237572/06+-Discovery+Queries) — COUNT(*) |
| INFO_AWS_KAPP_Query_API_Detail has 563M rows | [query evidence from MERGE session](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6841237572/06+-Discovery+Queries) |
| MERGE on 563M row table already taking 9+ minutes | [query evidence](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6841237572/06+-Discovery+Queries) — sys.dm_exec_requests session 67 |
| S3 backup buckets confirmed — `ksys-ew1r-db-backups` (local backups, AWS CLI s3 sync, no encryption specified) and `ksys-ew1p-oct-dbbackup` (EW1P-OCT RDS, KMS key NULL, unencrypted at rest). Retention TBC. | [USP_DatabaseBackupMoveToS3 definition](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6841237572/06+-Discovery+Queries) — job step command |
| DBA_VCC_COST is the only FULL recovery database on this server | [query 1.2](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6841237572/06+-Discovery+Queries) — recovery_model_desc |
| Grafana reads directly from DBA_VCC on localhost | [query 12.6](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6841237572/06+-Discovery+Queries) — grafana.db datasource table |
| 4 Zabbix datasources use ex-employee credentials inactive since Nov 2024 | [query 12.6](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6841237572/06+-Discovery+Queries) — grafana.db |

---

## 10. Documentation Index

| Document | Description | Confluence |
|---|---|---|
| Discovery Queries | All 14 SQL query sections with outputs | [View](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6841237572/06+-Discovery+Queries) |
| SQL Server Inventory | Databases, jobs, linked servers, stored procedures | [View](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6847725586/SQL+Server+Inventory+EW1R-REP-01) |
| SQL Server Investigation Log | TECH-3560 findings with query evidence | [View](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6848282648/SQL+Server+Investigation+Log) |
| Grafana Inventory | Datasources, dashboards, users, alert rules | [View](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6850314252/Grafana+Inventory) |
| Grafana Investigation Log | TECH-3561 findings with query evidence | [View](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6851067926/Grafana+-+Investigation+Log) |
| Consumers & Dependencies | Consumers, service accounts, firewall rules | [View](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6853460033/Consumers+and+Dependencies) |
| External Targets | External targets and connections | [View](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6854344805/External+Targets+EW1R-REP-01) |
| Targets & Consumers Investigation Log | TECH-3562 findings with query evidence | [View](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6853918807/Investigation+Log+for+External+Target+and+Consumers) |
| Topology & Classification | Full topology map and component classification | [View](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6860963905/Topology+Classification+EW1R-REP-01) |
| Topology Investigation Log | TECH-3563 findings with query evidence | [View](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6860243025/Topology+-+Investigaton+Log) |
