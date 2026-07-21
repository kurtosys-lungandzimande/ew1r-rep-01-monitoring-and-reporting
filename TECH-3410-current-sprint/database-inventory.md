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
| Created | 2023-06-09 |
| Technical owner (SQL level) | sa — generic admin account, no real accountable person at DB level |
| Primary purpose | AWS infrastructure monitoring, KAPP API query tracking, NiFi pipeline monitoring, EC2/RDS inventory |

**What it contains — validated 2026-07-20:**

| Table | Rows | Size (MB) | Notes |
|---|---|---|---|
| INFO_AWS_KAPP_Query_API_Detail | 297,606,716 | 53,665 MB | Every KAPP API query — actively growing |
| INFO_AWS_KAPP_Query_Datasets_Detail | 62,644,408 | 15,813 MB | Dataset-level query tracking |
| INFO_AWS_KAPP_Source_Datasets_Detail | 52,801,576 | 14,872 MB | Source dataset tracking |
| ARC_INFO_AWS_Nifi_Loader_API_Detail | 14,586,154 | 4,004 MB | NiFi pipeline archive |
| INFO_AWS_Nifi_Loader_API_Detail | 2,718,376 | 762 MB | NiFi data pipeline monitoring |
| MON_AWS_Entity_Cost | 2,533,553 | 387 MB | Cost monitoring per entity — last updated 2026-07-15 |
| INFO_AWS_KAPP_Query_API_Error_Detail | 276,051 | 157 MB | KAPP API errors |
| ARC_INFO_AWS_Entity_Cost | 81,834 | 9 MB | Entity cost archive |
| INFO_AWS_Entity_Cost | 60,045 | 6 MB | Entity cost detail |
| ARC_INFO_AWS_DataTransfer_Regional_Bytes_Detail | 53,412 | 14 MB | Archive |
| ARC_INFO_AWS_S3_Bucket_Sizes_Detail | 54,275 | 10 MB | S3 bucket size archive |
| INFO_AWS_DataTransfer_Regional_Bytes_Detail | 95,061 | 14 MB | Regional data transfer tracking |
| ARC_INFO_AWS_RDS_Security_Group_Rules | 18,604 | 6 MB | RDS security group archive |
| INFO_AWS_KAPP_Datasets_Lambda_Timeouts_Executions_Detail | 23,784 | 4 MB | Lambda timeout executions |
| INFO_AWS_RDS_Detail | 3,053 | 4 MB | RDS instance inventory |
| ARC_INFO_AWS_S3_Bucket_NumberOfObjects_Detail | 27,664 | 4 MB | S3 object count archive |
| INFO_AWS_EC2_Detail | 11,286 | 4 MB | EC2 instance inventory |
| MON_AWS_RDS_Detail | 1,495 | 3 MB | RDS monitoring |
| ARC_INFO_AWS_S3_Bucket_LifeCycle_Detail | 7,267 | 2 MB | S3 lifecycle archive |
| MON_AWS_RDS_Maintenance_Detail | 3,379 | 1 MB | RDS maintenance monitoring |
| ARC_INFO_AWS_RDS_Maintenance_Detail | 2,820 | 1 MB | RDS maintenance archive |
| INFO_AWS_S3_Bucket_Sizes_Detail | 3,950 | 1 MB | S3 bucket sizes |
| INFO_AWS_S3_Bucket_Encryption_Detail | 3,985 | 1 MB | S3 encryption audit |
| INFO_AWS_KAPP_Datasets_Lambda_Timeouts_Detail | 6,830 | 1 MB | Lambda timeout detail |
| ARC_INFO_AWS_IAM_KEYS_Detail | 1,560 | 0 MB | IAM keys archive |
| INFO_AWS_S3_Bucket_NumberOfObjects_Detail | 2,285 | 1 MB | S3 object counts |
| INFO_AWS_S3_Bucket_LifeCycle_Detail | 746 | 0 MB | S3 lifecycle detail |
| LU_AWS_S3_Buckets | 34 | 0 MB | S3 bucket lookup |
| ARC_INFO_AWS_EC2_Detail | 67 | 0 MB | EC2 archive |
| INFO_AWS_IAM_KEYS_Detail | 101 | 0 MB | IAM keys detail |
| LU_AWS_Keys | 9 | 0 MB | AWS keys lookup |
| LU_AWS_Log_Groups | 9 | 0 MB | Log groups lookup |

**Note:** 21 additional tables with 0 rows and 0 MB — MON_* staging tables, LU_* lookup tables, ARC_* pre-allocated archives. No active data. `ARC_INFO_AWS_KAPP_Query_API_Error_Detail` has 0 rows but 9 MB pre-allocated.

**Active jobs feeding this database:**
- `DBA_VCC_AWS_15MIN_CHECKS` — KAPP API logs, NiFi logs, Lambda timeouts (every 30 min, succeeded)
- `DBA_VCC_AWS_DAILY_CHECKS` — S3 sizes, AWS costs per entity (daily, succeeded)
- `DBA_VCC_AWS_WEEKLY_CHECKS` — RDS inventory, EC2 inventory, IAM keys (weekly, succeeded)
- `DBA_VCC_JIRA_MONTHEND_CHECKS` — Jira sprint data (monthly, succeeded)

**Finding — MON_AWS_Entity_Cost is current (last updated 2026-07-15):**  
`MON_AWS_Entity_Cost` confirmed collecting — last record 2026-07-15. The previously noted "broken since Sept 2024" finding requires re-investigation to identify exactly which Python API call or ETL step stopped writing. `DBA_VCC_AWS_DAILY_CHECKS` uses CATCH blocks that swallow errors — individual step failures do not surface as job failures. Specific broken step still to be identified.

**Finding — MERGE performance risk:**  
`INFO_AWS_KAPP_Query_API_Detail` has **297,606,716 rows** (confirmed 2026-07-20, NOT PARTITIONED — single partition, no partition scheme). The ETL job uses a MERGE statement against this table. The original 563M figure was incorrect. Table is still unpartitioned and actively growing — MERGE performance risk stands. At current growth rate, the MERGE execution window is approaching the job schedule interval — risk of job overlap and table lock contention.

**Proposed resolution:**
| Action | Owner | Priority |
|---|---|---|
| Identify which specific step in DBA_VCC_AWS_DAILY_CHECKS is silently failing — CATCH blocks mask individual step errors | DBA team | High |
| Add explicit error handling so step failures surface as job failures | DBA team | High |
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

**What it contains — validated 2026-07-20:**

| Table | Rows | Size (MB) | Notes |
|---|---|---|---|
| ARC_INFO_Client_FP_Token_Detail | 431,764,165 | 54,667 MB | FP token archive — largest table in database |
| INFO_Client_FP_Token_Detail | 64,819,183 | 8,387 MB | FP token detail — active |
| ARC_INFO_Top10_Query_Run_Detail | 1,704,713 | 2,457 MB | Top query run archive |
| INFO_Top10_Query_Run_Detail | 594,473 | 1,140 MB | Top query run detail |
| ARC_INFO_FP_LoaderRunHistory_Detail | 6,948,284 | 778 MB | FP loader run history archive |
| ARC_INFO_ClientSizes_Sizes_FP | 33,293,391 | 616 MB | FP client sizes archive |
| ARC_INFO_Backup_Info_Detail | 518,441 | 381 MB | Backup info archive |
| INFO_Client_FP_Detail | 556,675 | 309 MB | FinancialPortal client detail — last write May 2026 |
| INFO_ClientSizes_Sizes_FP | 2,903,660 | 252 MB | FP client sizes |
| ARC_ClientSizes_Sizes_FP | 9,155,223 | 159 MB | FP client sizes archive |
| ARC_Ping_Stat | 8,886,810 | 104 MB | Ping stats archive |
| INFO_KAPP_Workflow_Run_Detail | 268,422 | 91 MB | KAPP workflow run history — last write May 2026 |
| ARC_SQL_Status | 7,307,046 | 86 MB | SQL status archive |
| ARC_INFO_FP_SnapshotRunHistory_Detail | 368,123 | 75 MB | FP snapshot run history archive |
| INFO_KAPP_Workflow_Times_Run_Detail | 296,533 | 59 MB | KAPP workflow timing detail |
| INFO_Backup_Info_Detail | 32,574 | 29 MB | Backup info |
| out | 244,800 | 22 MB | Unknown purpose |
| BAS_SQL_Status | 440,064 | 18 MB | SQL status baseline |
| BAS_Ping_Stat | 440,112 | 18 MB | Ping stats baseline |
| INFO_FP_LoaderRunHistory_Detail | 109,645 | 16 MB | FP loader run history |
| ARC_INFO_Client_FP_Detail | 310,438 | 13 MB | FP client detail archive |
| ARC_INFO_ClientSizes_Sizes_IP | 690,058 | 13 MB | InvestorPress client sizes archive |
| INFO_Client_Application_Auth_Config_Detail | 49,040 | 8 MB | Application auth config |
| INFO_ClientSizes_Sizes_IP | 42,364 | 5 MB | InvestorPress client sizes |
| ARC_INFO_FP_DuplicateRecordHistory_Detail | 237,073 | 4 MB | FP duplicate record history archive |
| ARC_ClientSizes_Sizes_IP | 174,322 | 3 MB | IP client sizes archive |
| INFO_FP_DuplicateRecordHistory_Detail | 29,061 | 3 MB | FP duplicate record history |
| INFO_FP_SnapshotRunHistory_Detail | 15,262 | 3 MB | FP snapshot run history |
| ARC_INFO_FP_OrphanedRecords_Check | 147,170 | 3 MB | FP orphaned records archive |
| INFO_FP_OrphanedRecords_Check | 15,895 | 2 MB | FP orphaned records |
| ARC_INFO_Client_IP_Detail | 24,798 | 1 MB | InvestorPress client detail archive |
| INFO_Client_IP_Detail | 2,047 | 0 MB | InvestorPress client detail — 2,047 rows, last write May 2026 |

**Note:** ~80 additional tables with 0 rows — MON_* staging, LU_* lookups, BAS_* baselines, Error_* error tables, ARC_* pre-allocated archives. No active data.

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

**What it contains — validated 2026-07-20:**

| Table | Rows | Size (MB) | Notes |
|---|---|---|---|
| BAS_MYSQL_TABLE_SIZE_PER_DATABASES | 199,146,701 | 46,909 MB | MySQL table size baselines — dominant table |
| BAS_MSSQL_TABLE_SIZE_PER_DATABASES | 18,689,333 | 2,159 MB | MSSQL table size baselines |
| BAS_MSSQL_DATABASES_CONNECTIONS | 4,464,862 | 356 MB | MSSQL connection baselines |
| BAS_MYSQL_DATABASES_CONNECTIONS | 2,919,395 | 138 MB | MySQL connection baselines |
| BAS_MEMSQL_TABLE_SIZE_PER_DATABASES | 1,620,917 | 133 MB | MemSQL table size baselines — stale since May 2026 |
| STG_Client_Tokens | 821,369 | 92 MB | Client token staging — purpose unclear |
| BAS_MEMSQL_DATABASES_CONNECTIONS | 236,736 | 12 MB | MemSQL connection baselines — stale since May 2026 |
| BAS_MSSQL_BACKUPS | 22,268 | 2 MB | MSSQL backup baselines |
| STG_API_COUNTS | 3,600 | 1 MB | API count staging |
| BAS_MYSQL_BACKUPS | 10,656 | 1 MB | MySQL backup baselines |
| BAS_MEMSQL_BACKUPS | 833 | 0 MB | MemSQL backup baselines — stale since May 2026 |
| LU_EntityList | 118 | 0 MB | Entity lookup |

**Note:** `BAS_WP_Posts_Tracking_Sizes_Info` — 0 rows, WPv2 baseline table, never populated after WPv2 decommission.

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

**What it contains — validated 2026-07-20:**

| Table | Rows | Size (MB) | Notes |
|---|---|---|---|
| ARC_INFO_Database_Table_Sizes | 212,533,594 | 18,883 MB | Database table size archive — dominant table |
| CTI_AUDIT_2024 | 5,212,125 | 3,030 MB | CTI audit 2024 — purpose unclear |
| INFO_Database_Table_Sizes | 20,709,755 | 1,918 MB | Database table sizes — active |
| ARC_INFO_Backup_Info_Detail | 4,006,587 | 485 MB | Backup info archive |
| ARC_INFO_DXM_LAMBDA_BACKUPS_Detail | 5,515,034 | 298 MB | DXM Lambda backup archive |
| INFO_DXM_Posts_Tracking_Sizes_Info | 2,894,669 | 259 MB | DXM post tracking sizes |
| ARC_SQL_Global_Status_Detail | 15,770 | 105 MB | SQL global status archive |
| ARC_SQL_Status | 2,766,911 | 104 MB | SQL status archive |
| ARC_INFO_WP_Posts_Tracking_Sizes_Info | 970,593 | 80 MB | WPv2 post tracking archive — legacy, WPv2 decommissioned |
| ARC_INFO_Database_Columns_Info_Detailed | 1,954,029 | 62 MB | Database columns archive |
| ARC_Ping_Stat | 2,839,010 | 60 MB | Ping stats archive |
| INFO_Backup_Info_Detail | 90,518 | 30 MB | Backup info |
| ARC_INFO_DXM_Client_Sizes | 1,024,840 | 17 MB | DXM client sizes archive |
| ARC_INFO_DXM_Clients_Detail | 811,333 | 14 MB | DXM clients detail archive |
| ARC_INFO_SQL_Top100_Query_Detail | 68,900 | 12 MB | Top 100 query archive |
| INFO_DXM_LAMBDA_BACKUPS_Detail | 79,190 | 10 MB | DXM Lambda backup detail |
| ARC_INFO_SQL_Slow_Query_Detail | 14,180 | 9 MB | Slow query archive |
| ARC_INFO_Database_Tables_Info_Detailed | 253,818 | 8 MB | Database tables info archive |
| BAS_SQL_Status | 177,120 | 7 MB | SQL status baseline |
| BAS_Ping_Stat | 177,120 | 7 MB | Ping stats baseline |
| ARC_Service_Status_Check | 78,734 | 5 MB | Service status archive |
| INFO_DXM_Client_Sizes | 60,117 | 4 MB | DXM client sizes — active |
| ARC_System_Time_Check | 65,941 | 4 MB | System time archive |
| ARC_INFO_DXM_FOOTER_MONITOR_DETAILED | 124,534 | 2 MB | DXM footer monitor archive |
| ARC_SQL_Version_Check | 25,735 | 2 MB | SQL version archive |
| ARC_INFO_WPv2_Client_Sizes | 66,168 | 1 MB | WPv2 client sizes archive — legacy |
| INFO_DXM_Clients_Detail | 3,173 | 1 MB | DXM clients detail — active |
| INFO_WPv2_Client_Sizes | 810 | 0 MB | WPv2 client sizes — legacy, WPv2 decommissioned |

**Note:** ~80 additional tables with 0 rows — MON_* staging, LU_* lookups, BAS_* baselines, Error_* error tables. WPv2 tables (`INFO_WPv2_Clients_Detail`, `ARC_INFO_WPv2_Clients_Detail`) still present but legacy — WPv2 decommissioned.

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

**What it contains — validated 2026-07-20:**

| Table | Rows | Size (MB) | Notes |
|---|---|---|---|
| INFO_Table_Index_Frag_Detail | 34,720,728 | 6,824 MB | Index fragmentation detail — actively collected |
| INFO_AWS_Encore_Cloudwatch_IIS_Logs | 21,674,341 | 4,232 MB | Encore/BNY IIS logs from CloudWatch — actively collected |
| ARC_INFO_Table_Index_Frag_Detail | 0 | 3,641 MB | Index frag archive — 0 rows but 3.6 GB pre-allocated |
| ARC_SQL_Errorlog_Check | 40,564,851 | 1,400 MB | SQL error log archive |
| ARC_SQL_Connection_Check | 24,512,430 | 339 MB | Connection check archive |
| ARC_Database_Status_Check | 15,009,730 | 214 MB | Database status archive |
| ARC_INFO_Backup_Info_Detail | 3,671,476 | 188 MB | Backup info archive |
| ARC_Log_Check | 2,469,198 | 126 MB | Log check archive |
| ARC_INFO_Database_Info_Detail | 4,264,406 | 102 MB | Database info archive |
| ARC_INFO_Job_Info_Detail | 236,447 | 71 MB | Job info archive |
| ARC_Daily_Backup_Check | 1,062,168 | 69 MB | Daily backup check archive |
| ARC_SQL_Locks_Check | 3,388,114 | 62 MB | SQL locks archive |
| ARC_INFO_Database_Info_Detailed | 230,169 | 51 MB | Database info detailed archive |
| INFO_Backup_Info_Detail | 145,039 | 49 MB | Backup info detail |
| BAS_Database_Status_Check | 431,461 | 39 MB | Database status baseline |
| ARC_INFO_Database_Disk_Latency_Detail | 1,177,861 | 38 MB | Disk latency archive |
| INFO_Database_Info_Detail | 101,762 | 37 MB | Database info detail |
| ARC_Ping_Stat | 997,935 | 26 MB | Ping stats archive |
| ARC_INFO_SQL_Failed_Logins_Detail | 100,274 | 19 MB | Failed logins archive |
| ARC_SQL_Status | 878,388 | 16 MB | SQL status archive |
| ARC_Database_Info_Detailed | 348,177 | 15 MB | Database info detailed archive |
| ARC_INFO_TOP5_Tables_Per_Database_Detail | 640,290 | 14 MB | Top 5 tables archive |
| ARC_INFO_Database_Usage_Detail | 140,878 | 9 MB | Database usage archive |
| ARC_INFO_Encore_Document_Production_Detail | 77,096 | 8 MB | Encore document production archive |
| ARC_SQLAgent_Status | 356,153 | 7 MB | SQL Agent status archive |
| INFO_Job_Info_Detail | 8,739 | 5 MB | Job info detail |
| ARC_INFO_SQL_Logins_Detail | 93,663 | 5 MB | SQL logins archive |
| ARC_INFO_SQL_Database_Users_Detail | 40,454 | 4 MB | Database users archive |
| RO_secgrp | 11,357 | 4 MB | Security group read-only |
| INFO_Encore_Document_Production_Detail | 1,229 | 0 MB | Encore document production — active |

**Note:** `ARC_INFO_Table_Index_Frag_Detail` has 0 rows but 3.6 GB pre-allocated — largest pre-allocated table on the server. ~100 additional tables with 0 rows — MON_* staging, LU_* lookups, BAS_* baselines, Error_* error tables.

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

**What it contains — validated 2026-07-20:**

| Table | Rows | Size (MB) | Notes |
|---|---|---|---|
| INFO_KAPP_Client_Users_Counts | 14,811,776 | 2,592 MB | KAPP client user counts — dominant table, actively collected |
| INFO_KAPP_Client_Disclaimers_Commentaries_Counts | 578,926 | 57 MB | Disclaimer/commentary counts |
| INFO_KAPP_Client_Document_Counts | 471,593 | 35 MB | Document counts per client |
| INFO_KAPP_Client_Snapshots_Counts | 286,584 | 21 MB | Snapshot counts per client |
| INFO_KAPP_Client_Entities_Counts | 145,047 | 11 MB | Entity counts per client |
| INFO_KAPP_Client_Statstics_Counts | 134,707 | 9 MB | Statistics counts per client |
| INFO_KAPP_Client_Allocations_Counts | 123,374 | 9 MB | Allocation counts per client |
| INFO_KAPP_Client_TimeSeries_Counts | 120,269 | 8 MB | Time series counts per client |
| INFO_KAPP_Client_HistoricalDatasets_Counts | 33,483 | 2 MB | Historical dataset counts per client |
| INFO_DBE_JIRA_VALUES_Detail | 2,526 | 1 MB | Jira values detail |
| INFO_AWS_DE_Entity_Cost | 4,382 | 1 MB | AWS DE entity cost |
| INFO_DBE_JIRA_VALUES_Detail_old | 1,144 | 0 MB | Old Jira values — legacy |
| INFO_AWS_Account_Entity_Cost | 1,977 | 0 MB | AWS account entity cost |
| LU_KAPP_ClientList | 280 | 0 MB | KAPP client lookup — 280 real institutional clients |
| LU_EntityList | 209 | 0 MB | Entity lookup |
| LU_DXM_ClientList | 160 | 0 MB | DXM client lookup |
| LU_Encore_ClientList | 28 | 0 MB | Encore client lookup |
| LU_IP_ClientList | 23 | 0 MB | InvestorPress client lookup |
| LU_WPv2_ClientList | 10 | 0 MB | WPv2 client lookup — legacy |

**Note:** `cleanup`, `MON_AWS_DE_Entity_Cost`, `MON_DBE_JIRA_VALUES_Detail` — 0 rows, 0 MB.

**Active jobs feeding this database:**
- `DBA_VCC_COST_Entity_Count_Collection` — collects KAPP client entity counts (weekly, succeeded)

**Finding — FULL recovery model signals this data is critical:**  
Every other database on this server uses SIMPLE recovery. DBA_VCC_COST is the only one on FULL recovery — meaning someone deliberately set it that way to enable point-in-time restore. This is the strongest signal that this data is considered production-critical.

**Finding — collection job runs weekly every Monday:**  
`DBA_VCC_COST_Entity_Count_Collection` confirmed scheduled weekly on Mondays (freq_type=8, freq_interval=2). This appears intentional.

**Finding — KAPP Client Utilisation and Growth Report may be client-facing:**  
4 Grafana dashboards read from DBA_VCC_COST. `KAPP Client Utilisation and Growth Report` (last updated 2024-02-22) — the name strongly suggests this is shown to clients. If confirmed client-facing, this is the highest-risk dependency on the entire server.

**Proposed resolution:**
| Action | Owner | Priority |
|---|---|---|
| Confirm whether KAPP Client Utilisation and Growth Report is client-facing | tashvir.babulal / rayhaan.suleyman | **Critical — blocks decommission** |
| Weekly Monday schedule confirmed — no action needed on schedule |  DBA team | Closed |
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

**What it contains — validated 2026-07-20:**

| Table | Rows | Size (MB) | Notes |
|---|---|---|---|
| Jira_Project_Issue_Field_Types | 181,714 | 30 MB | Jira issue field types — frozen since 2023-12-12 |
| Jira_Project_Leads | 657 | 0 MB | Jira project leads — frozen since 2023-12-12 |

**Active jobs feeding this database:**
- `DBA_VCC_JIRA_MONTHEND_CHECKS` — pulls Jira sprint data monthly via Python API (succeeded) — writes to DBA_VCC_AWS, not confirmed to write here

**Finding — no stored procedures, data frozen since 2023-12-12:**  
DBA_VCC_ATLASSIAN has 0 stored procedures. It is a data store only. `MAX(DateChecked)` across `Jira_Project_Issue_Field_Types` (181,714 rows) = 2023-12-12 — no data written in 2.5+ years. A full job-command search across all SQL Agent jobs on the server returned zero matches for this database. No active writer identified through any mechanism.

**Proposed resolution:**
| Action | Owner | Priority |
|---|---|---|
| Confirm who reads from this database — data confirmed frozen, no active writer | DBA team | Medium |
| If no active consumer, mark for archival ahead of decommission | DBA team | Low |

---

### 8. Utilities — 0.18 GB — UTILITY ✅

| Property | Value |
|---|---|
| Size | 0.18 GB |
| Recovery Model | SIMPLE |
| Status | Active — DBA tooling database |
| Primary purpose | Ola Hallengren maintenance SPs, Zabbix integration (USP_ZAB_*), MemSQL history collection, KAPP schema comparison |

**What it contains — validated 2026-07-20:**

| Table | Rows | Size (MB) | Notes |
|---|---|---|---|
| MemSQLTableIdHistory | 1,577,467 | 95 MB | MemSQL table ID history |
| Benchmarks_1704 | 12,543 | 61 MB | Benchmarks — purpose unclear |
| CommandLog | 12,736 | 6 MB | Ola Hallengren command log |
| MemSqlInfo | 2,365 | 1 MB | MemSQL info |
| BackupRestoreTests | 28 | 0 MB | Backup restore test records |
| KAPP_Schema_routines_diff | 1 | 0 MB | KAPP schema routine diff |
| estimated_data_compression_savings | 448 | 0 MB | Compression savings estimates |
| ObjectIDValidationReport | 26 | 0 MB | Object ID validation report |
| KAPP_Schema_column_count | 996 | 0 MB | KAPP schema column count |
| MemSqlConfig | 57 | 0 MB | MemSQL config |
| SQLServerADGroups | 272 | 0 MB | SQL Server AD groups |
| Variables | 2 | 0 MB | Variables lookup |
| deltacheck | 3 | 0 MB | Delta check |
| memsql_leaf_pairs | 12 | 0 MB | MemSQL leaf pairs |
| MemSQLTableMemoryInfo | 0 | 0 MB | MemSQL table memory info — pre-allocated |

**Note:** `ObjectProperties`, `OrphanedRecords`, `Plancache`, `PRODUCTION_LOGIN_REPORT`, and KAPP schema diff tables — 0 rows, 0 MB.

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
| Q-DB5 | Who reads from DBA_VCC_ATLASSIAN? Data confirmed frozen since 2023-12-12, no active writer identified | DBA team | DBA_VCC_ATLASSIAN archival |
| Q-DB6 | Identify which specific step in DBA_VCC_AWS_DAILY_CHECKS is silently failing — CATCH blocks mask individual step errors | DBA team | DBA_VCC_AWS data integrity |
| Q-DB7 | What is the S3 backup retention policy for DBA_VCC_COST? | DBA team / DevOps | Backup compliance |

---

## Decommission Readiness — Database Summary

| Database | Size | Status | Safe to Decommission? |
|---|---|---|---|
| DBA_VCC_AWS | 182 GB | Active | ❌ No — consumers not confirmed, specific broken ETL step in DBA_VCC_AWS_DAILY_CHECKS not yet identified |
| DBA_VCC_MEMSQL | 75 GB | Broken / Stale | ⚠️ Pending — need to confirm why jobs disabled |
| KURTOSYS_BASELINE | 50 GB | Active, purpose unclear | ⚠️ Pending — confirm consumer |
| DBA_VCC_MYSQL | 25 GB | Partially broken | ⚠️ Pending — fix WPv2 failures first, confirm DXM consumer |
| DBA_VCC | 21 GB | Active | ❌ No — monitors production servers EW2P-MSSQL-01/02 |
| DBA_VCC_COST | 5 GB | Active | ❌ No — FULL recovery, possible client-facing dashboard |
| DBA_VCC_ATLASSIAN | 2 GB | Reference only | ⚠️ Pending — confirm no active consumer |
| Utilities | 0.18 GB | Active utility | ⚠️ Pending — decommission last, after all jobs migrated |
