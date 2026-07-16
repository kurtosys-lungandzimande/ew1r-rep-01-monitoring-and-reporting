# Database Inventory — EW1R-REP-01
**Ticket:** TECH-3478 — Theme A SQL Server Inventory  
**Date captured:** 2026-07-16  
**Total databases:** 8  
**Total size:** ~378 GB  

---

## Executive Summary

EW1R-REP-01 hosts 8 databases totalling 378 GB. Of these:

- **3 are fully active** — DBA_VCC_AWS, DBA_VCC, DBA_VCC_COST
- **2 are partially active / partially broken** — DBA_VCC_MYSQL (DXM side active, WPv2 side broken), KURTOSYS_BASELINE (collecting but purpose unclear post-decommission)
- **1 is broken / stale** — DBA_VCC_MEMSQL (75 GB, no new data since May 2026, jobs disabled)
- **1 is reference data only** — DBA_VCC_ATLASSIAN (no stored procedures, no active jobs)
- **1 is utility** — Utilities (DBA tooling, Ola Hallengren, Zabbix integration)

**The server cannot be decommissioned until DBA_VCC_COST and DBA_VCC_AWS consumers are confirmed and migrated.**

---

## Database Inventory

### 1. DBA_VCC_AWS — 182 GB — ACTIVE ⚠️ RISK

| Property | Value |
|---|---|
| Size | 182.66 GB |
| Recovery Model | SIMPLE |
| Status | Active — jobs running daily |
| Primary purpose | AWS infrastructure monitoring, KAPP API query tracking, NiFi pipeline monitoring, EC2/RDS inventory |

**What it contains:**

| Table | Rows | Size | Notes |
|---|---|---|---|
| INFO_AWS_KAPP_Query_API_Detail | 563M | 143 GB | Every KAPP API query — actively growing |
| INFO_AWS_KAPP_Query_Datasets_Detail | 59M | 15 GB | Dataset-level query tracking |
| INFO_AWS_KAPP_Source_Datasets_Detail | 50M | 14 GB | Source dataset tracking |
| ARC_INFO_AWS_Nifi_Loader_API_Detail | 14M | 3.8 GB | NiFi pipeline archive |
| MON_AWS_Entity_Cost | 2.4M | 377 MB | Cost monitoring per entity |

**Active jobs feeding this database:**
- `DBA_VCC_AWS_15MIN_CHECKS` — KAPP API logs, NiFi logs, Lambda timeouts (every 30 min, succeeded)
- `DBA_VCC_AWS_DAILY_CHECKS` — S3 sizes, AWS costs per entity (daily, succeeded)
- `DBA_VCC_AWS_WEEKLY_CHECKS` — RDS inventory, EC2 inventory, IAM keys (weekly, succeeded)
- `DBA_VCC_JIRA_MONTHEND_CHECKS` — Jira sprint data (monthly, succeeded)

**Finding — AWS cost ETL broken since Sept 2024:**  
`DBA_VCC_AWS_DAILY_CHECKS` reports Succeeded but AWS cost data has not updated since September 2024. The job uses Python API calls with CATCH blocks that swallow errors — the job completes without failing even when the API call returns nothing. `MON_AWS_Entity_Cost` has 2.4M rows but the most recent cost data is ~22 months stale. No alert fired. No one raised an incident.

**Finding — MERGE performance risk:**  
`INFO_AWS_KAPP_Query_API_Detail` has 563M rows and is unpartitioned. The ETL job uses a MERGE statement against this table. At current growth rate, the MERGE execution window is approaching the job schedule interval — risk of job overlap and table lock contention.

**Proposed resolution:**
| Action | Owner | Priority |
|---|---|---|
| Investigate why AWS cost Python API call stopped writing in Sept 2024 — check CloudWatch log stream, Python script, API credentials | DBA team | High |
| Fix or replace the ETL — add explicit error handling so failures surface as job failures | DBA team | High |
| Assess partitioning strategy for INFO_AWS_KAPP_Query_API_Detail before it causes a production incident | DBA team | Medium |
| Confirm who consumes AWS cost data from this database before decommission | tashvir.babulal / rayhaan.suleyman | Critical — blocks decommission |

---

### 2. DBA_VCC_MEMSQL — 75 GB — BROKEN / STALE 🔴

| Property | Value |
|---|---|
| Size | 75.50 GB |
| Recovery Model | SIMPLE |
| Status | Broken — all 7 collection jobs disabled since May 2026 |
| Primary purpose | SingleStore/MemSQL monitoring — KAPP workflow history, FP/IP client data, month-end reporting |

**What it contains:**
- KAPP workflow run history and timing
- FinancialPortal (FP_) and InvestorPress (IP_) client data
- Month-end reporting tables (REP_MONTHEND_*) — called by 6 Grafana dashboards
- ~200 stored procedures — most recently modified Nov 2024

**Active jobs feeding this database:** None — all 7 disabled.

**Last data collected:** May 2026 (DBA_VCC_MEMSQL_DAILY_CHECKS failed on last run before disable).

**Finding — 14 Grafana dashboards showing stale data since May 2026:**  
14 dashboards confirmed reading from DBA_VCC_MEMSQL. All have been displaying stale data for 2+ months. No alert fired. No one raised an incident. 6 of these are month-end reporting dashboards with no independent data pipeline — June 2026 month-end reporting was impacted.

**Finding — reason for disable unknown:**  
It is not confirmed whether the jobs were disabled because SingleStore was decommissioned, migrated, or paused for maintenance. This is the most important open question for this database.

**Proposed resolution:**
| Action | Owner | Priority |
|---|---|---|
| Confirm why jobs were disabled — decommission, migration, or pause? | yogeshwar.phull / tashvir.babulal | Critical — determines everything below |
| If SingleStore decommissioned: mark database as stale, archive or drop, update all 14 dashboards | DBA team | High |
| If SingleStore migrated: update linked server connections and re-enable jobs | DBA team | High |
| Disclose to dashboard consumers that data has been stale since May 2026 | tashvir.babulal / rayhaan.suleyman | High |
| Do not decommission this server until month-end dashboard consumers are identified and notified | TBD | Critical — blocks decommission |

---

### 3. KURTOSYS_BASELINE — 50 GB — ACTIVE, PURPOSE UNCLEAR ⚠️

| Property | Value |
|---|---|
| Size | 50 GB |
| Recovery Model | SIMPLE |
| Status | Active — baseline jobs running daily |
| Primary purpose | Performance baseline captures — connection counts and table sizes across MemSQL, MySQL, MSSQL |

**Active jobs feeding this database:**
- `BASELINE_CONNECTIONS` — captures connection baselines (daily, succeeded)
- `BASELINE_TABLE_SIZES` — captures table size baselines (daily, succeeded)

**Finding — baseline data for dead systems:**  
BASELINE_CONNECTIONS and BASELINE_TABLE_SIZES collect data across MemSQL, MySQL, and MSSQL linked servers. With 63 linked servers now dead and all MemSQL jobs disabled, a significant portion of what this database was designed to baseline no longer exists. The jobs still run and succeed — but what they are capturing post-decommission of those systems is unclear.

**Finding — BASELINE_CONNECTIONS has steps for dead servers:**  
Job steps reference ew1d-aggr-05 and ew1d-aggr-15 — both dead. Steps likely fail silently or are skipped.

**Proposed resolution:**
| Action | Owner | Priority |
|---|---|---|
| Confirm who reads baseline data from this database — is it used for capacity planning or reporting? | DBA team | Medium |
| Audit which job steps are still writing valid data vs silently failing | DBA team | Medium |
| If no active consumer exists post-decommission, mark for archival | DBA team | Low |

---

### 4. DBA_VCC_MYSQL — 25 GB — PARTIALLY ACTIVE / PARTIALLY BROKEN ⚠️

| Property | Value |
|---|---|
| Size | 25.62 GB |
| Recovery Model | SIMPLE |
| Status | Partially active — DXM side running, WPv2 side broken |
| Primary purpose | MySQL and RDS monitoring — DXM client sizes, WPv2 client data (legacy) |

**Active jobs feeding this database:**
- `DBA_VCC_MYSQL_AUDIT_BACKUP_INFO_DETAILED` — MySQL backup audit (succeeded)
- `DBA_VCC_MYSQL_MON_PING_STATS` — MySQL ping stats (succeeded)
- `DBA_VCC_MYSQL_MON_SQL_STATUS` — MySQL status check (succeeded)
- `DBA_VCC_MYSQL_MON_SQL_VERSION_CHECK` — MySQL version check (succeeded)
- `DBA_VCC_MYSQL_WEEKLY_CHECKS` — DXM post tracking, archival (succeeded)

**Broken jobs:**
- `DBA_VCC_MYSQL_DAILY_CHECKS` — **failing daily** — calls WPv2 linked servers (all 4 dead)
- `DBA_VCC_MYSQL_AUDIT_DXM_CLIENT_DETAILED` — **failing daily** — calls `SP_AUDIT_WPv2_CLIENTS_DETAILED` which was last modified 2022-11-01 and references dead WPv2 linked servers

**Root cause — WPv2 failure chain:**  
WPv2 RDS was decommissioned. `LU_Serverlist` was never updated to remove WPv2 entries. `SP_MON_PING_STATS` has `xp_cmdshell` commented out — so all servers in `V_InstanceList` get `Status = 1` written regardless of actual reachability. WPv2 stored procedures then attempt `OPENQUERY` against dead linked servers and fail. Both jobs report failure daily. No alert fires because no operator is wired to these jobs.

**Proposed resolution:**
| Action | Owner | Priority |
|---|---|---|
| Remove WPv2 entries from LU_Serverlist | DBA team | High |
| Disable or drop `SP_AUDIT_WPv2_CLIENTS_DETAILED` — last modified 2022, references dead servers | DBA team | High |
| Fix `DBA_VCC_MYSQL_DAILY_CHECKS` — remove WPv2 steps, keep DXM steps | DBA team | High |
| Fix `DBA_VCC_MYSQL_AUDIT_DXM_CLIENT_DETAILED` — remove WPv2 call, validate DXM steps | DBA team | High |
| Restore `xp_cmdshell` in `SP_MON_PING_STATS` or replace with a working ping mechanism | DBA team | Medium |

---

### 5. DBA_VCC — 21 GB — ACTIVE ✅

| Property | Value |
|---|---|
| Size | 20.86 GB |
| Recovery Model | SIMPLE |
| Status | Active — core monitoring framework running |
| Primary purpose | Core VCC monitoring framework — SQL Server instance monitoring, Encore IIS logs, index fragmentation, error log archive, connection history |

**Active jobs feeding this database:**
- `DBA_VCC_DAILY_CHECKS` — Encore document production metrics (daily, succeeded)
- `DBA_VCC_HOURLY_CHECKS` — BNY IIS logs from CloudWatch (hourly, succeeded)
- `DBA_VCC_WEEKLY_CHECKS` — archival and index fragmentation audit (weekly, succeeded)
- All 16 VCC Audit Collection jobs — monitoring EW2P-MSSQL-01, EW2P-MSSQL-02 (succeeded)
- All 8 VCC Server Monitoring jobs (succeeded)

**Finding — monitored server list is partially stale:**  
`LU_Serverlist` shows 4 entries: EW2P-MSSQL-01 (active), EW2P-MSSQL-02 (active), EW1D-MSSQL-01 (inactive), ew1r-mssql-01 (inactive). The two inactive entries are still in the list — audit jobs may be attempting to connect to them.

**Proposed resolution:**
| Action | Owner | Priority |
|---|---|---|
| Confirm EW1D-MSSQL-01 and ew1r-mssql-01 are permanently retired — remove from LU_Serverlist if so | DBA team | Medium |
| Confirm who consumes the audit and monitoring data from this database before decommission | DBA team | Critical — blocks decommission |
| Document migration path for VCC framework monitoring of EW2P-MSSQL-01/02 post-decommission | DBA team | Critical — blocks decommission |

---

### 6. DBA_VCC_COST — 5 GB — ACTIVE, HIGHEST RISK 🔴

| Property | Value |
|---|---|
| Size | 5 GB |
| Recovery Model | FULL (only database on this server with FULL recovery) |
| Status | Active — collection job running |
| Primary purpose | Cost tracking per KAPP client entity — allocations, disclaimers, documents, other entity types |

**Active jobs feeding this database:**
- `DBA_VCC_COST_Entity_Count_Collection` — collects KAPP client entity counts (weekly, succeeded)

**Finding — FULL recovery model signals this data is critical:**  
Every other database on this server uses SIMPLE recovery. DBA_VCC_COST is the only one on FULL recovery — meaning someone deliberately set it that way to enable point-in-time restore. This is the strongest signal that this data is considered production-critical.

**Finding — collection job runs weekly not daily:**  
`DBA_VCC_COST_Entity_Count_Collection` is scheduled weekly. Whether this is intentional or a misconfiguration is unconfirmed.

**Finding — KAPP Client Utilisation and Growth Report may be client-facing:**  
4 Grafana dashboards read from DBA_VCC_COST. `KAPP Client Utilisation and Growth Report` (last updated 2024-02-22) — the name strongly suggests this is shown to clients. If confirmed client-facing, this is the highest-risk dependency on the entire server.

**Proposed resolution:**
| Action | Owner | Priority |
|---|---|---|
| Confirm whether KAPP Client Utilisation and Growth Report is client-facing | tashvir.babulal / rayhaan.suleyman | **Critical — blocks decommission** |
| Confirm whether weekly collection schedule is intentional | DBA team | Medium |
| Identify migration target for DBA_VCC_COST before any decommission date is set | DBA team / Platform team | **Critical — blocks decommission** |
| Confirm S3 backup retention for this database — FULL recovery with no confirmed retention policy is a risk | DBA team / DevOps | High |

---

### 7. DBA_VCC_ATLASSIAN — 2 GB — REFERENCE DATA ONLY ⚠️

| Property | Value |
|---|---|
| Size | 2 GB |
| Recovery Model | SIMPLE |
| Status | Reference data — no stored procedures, no active collection jobs confirmed |
| Primary purpose | Jira/Confluence integration data |

**Active jobs feeding this database:**
- `DBA_VCC_JIRA_MONTHEND_CHECKS` — pulls Jira sprint data monthly via Python API (succeeded) — writes to DBA_VCC_AWS, not confirmed to write here

**Finding — no stored procedures:**  
DBA_VCC_ATLASSIAN has 0 stored procedures. It is a data store only. No active collection job has been confirmed to write directly to it.

**Proposed resolution:**
| Action | Owner | Priority |
|---|---|---|
| Confirm what writes to this database and who reads from it | DBA team | Medium |
| If no active consumer, mark for archival ahead of decommission | DBA team | Low |

---

### 8. Utilities — 0.18 GB — UTILITY ✅

| Property | Value |
|---|---|
| Size | 0.18 GB |
| Recovery Model | SIMPLE |
| Status | Active — DBA tooling database |
| Primary purpose | Ola Hallengren maintenance SPs, Zabbix integration (USP_ZAB_*), MemSQL history collection, KAPP schema comparison |

**Key stored procedures:**
- Ola Hallengren: `DatabaseBackup`, `IndexOptimize`, `DatabaseIntegrityCheck`, `CommandLog`
- Zabbix: `USP_ZAB_*` — Zabbix integration procedures
- KAPP: `USP_KAPP_Schema_details_Capture` (modified 2024-08), `USP_ZAB_KAPP_schema_compare` (modified 2024-05)
- `USP_DatabaseBackupMoveToS3` — used by all backup jobs to sync to S3 via xp_cmdshell

**Proposed resolution:**
| Action | Owner | Priority |
|---|---|---|
| Retain until all backup jobs and maintenance jobs are decommissioned or migrated | DBA team | Low |
| Confirm Zabbix USP_ZAB_* procedures are still called — ZabbixNonProd and ZabbixProdOld are dead | DBA team | Medium |

---

## Open Questions — Blocking Decommission

| # | Question | Who to Ask | Blocks |
|---|---|---|---|
| Q-DB1 | Why were all 7 DBA_VCC_MEMSQL jobs disabled in May 2026 — decommission, migration, or pause? | yogeshwar.phull / tashvir.babulal | DBA_VCC_MEMSQL resolution |
| Q-DB2 | Is KAPP Client Utilisation and Growth Report client-facing? | tashvir.babulal / rayhaan.suleyman | DBA_VCC_COST decommission |
| Q-DB3 | Who consumes DBA_VCC_COST data — internal only or external? | tashvir.babulal / rayhaan.suleyman | DBA_VCC_COST decommission |
| Q-DB4 | Who consumes the VCC monitoring data for EW2P-MSSQL-01/02 — what breaks if this server goes away? | DBA team | DBA_VCC decommission |
| Q-DB5 | Why is DBA_VCC_COST_Entity_Count_Collection running weekly not daily — intentional? | DBA team | DBA_VCC_COST accuracy |
| Q-DB6 | What writes to DBA_VCC_ATLASSIAN and who reads from it? | DBA team | DBA_VCC_ATLASSIAN archival |
| Q-DB7 | Why has AWS cost ETL been broken since Sept 2024 with no alert and no incident raised? | DBA team | DBA_VCC_AWS data integrity |
| Q-DB8 | What is the S3 backup retention policy for DBA_VCC_COST? | DBA team / DevOps | Backup compliance |

---

## Decommission Readiness — Database Summary

| Database | Size | Status | Safe to Decommission? |
|---|---|---|---|
| DBA_VCC_AWS | 182 GB | Active | ❌ No — consumers not confirmed, AWS cost ETL broken |
| DBA_VCC_MEMSQL | 75 GB | Broken / Stale | ⚠️ Pending — need to confirm why jobs disabled |
| KURTOSYS_BASELINE | 50 GB | Active, purpose unclear | ⚠️ Pending — confirm consumer |
| DBA_VCC_MYSQL | 25 GB | Partially broken | ⚠️ Pending — fix WPv2 failures first, confirm DXM consumer |
| DBA_VCC | 21 GB | Active | ❌ No — monitors production servers EW2P-MSSQL-01/02 |
| DBA_VCC_COST | 5 GB | Active | ❌ No — FULL recovery, possible client-facing dashboard |
| DBA_VCC_ATLASSIAN | 2 GB | Reference only | ⚠️ Pending — confirm no active consumer |
| Utilities | 0.18 GB | Active utility | ⚠️ Pending — decommission last, after all jobs migrated |
