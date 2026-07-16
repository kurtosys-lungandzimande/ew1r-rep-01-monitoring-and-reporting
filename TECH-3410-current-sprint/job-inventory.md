# SQL Agent Job Inventory — EW1R-REP-01
**Ticket:** TECH-3478 — Theme A SQL Server Inventory  
**Date captured:** 2026-07-16  
**Total jobs:** 63  
**Enabled:** 52  
**Disabled:** 11  
**Actively failing:** 2  

---

## Executive Summary

52 of 63 SQL Agent jobs are enabled and running. 11 are disabled — all MemSQL-related, disabled since May 2026. Of the 52 enabled jobs, **2 are failing daily** — both caused by the same root cause: WPv2 linked servers were decommissioned but never cleaned up. Every other enabled job is succeeding as of 2026-07-16.

**Key risks:**
- 2 jobs failing daily with no alert firing — silent failures since WPv2 decommission
- 7 MemSQL jobs disabled since May 2026 — reason unconfirmed, 14 dashboards showing stale data
- 4 disabled DBA jobs with NULL last run — never ran or history purged, purpose unclear
- Backup jobs copying to S3 with no encryption specified — compliance risk

---

## Broken Jobs — Immediate Action Required 🔴

### DBA_VCC_MYSQL_AUDIT_DXM_CLIENT_DETAILED
| Property | Value |
|---|---|
| Enabled | Yes |
| Last run | 2026-07-16 01:00 |
| Last outcome | **Failed** |
| Failing step | Step 2 — SP_AUDIT_WPv2_CLIENTS_DETAILED |
| Feeds | DBA_VCC_MYSQL |
| Frequency | Daily |

**Root cause:** Step 2 calls `SP_AUDIT_WPv2_CLIENTS_DETAILED` in DBA_VCC_MYSQL — a stored procedure last modified 2022-11-01 that attempts OPENQUERY against WPv2 linked servers (ew2p-wpv2, ew2r-wpv2, ue1p-wpv2, ue1r-wpv2). All 4 are dead — DNS not found. Job has been failing every day since WPv2 was decommissioned. No alert fires because no operator is wired to this job.

**Proposed resolution:**
| Action | Owner | Priority |
|---|---|---|
| Disable or remove Step 2 (SP_AUDIT_WPv2_CLIENTS_DETAILED) from this job | DBA team | High |
| Drop or archive SP_AUDIT_WPv2_CLIENTS_DETAILED — last modified 2022, references dead servers | DBA team | High |
| Validate Step 1 (DXM audit) still works correctly after Step 2 is removed | DBA team | High |

---

### DBA_VCC_MYSQL_DAILY_CHECKS
| Property | Value |
|---|---|
| Enabled | Yes |
| Last run | 2026-07-16 10:00 |
| Last outcome | **Failed** |
| Failing step | Step 5 — SP_AUDIT_WPv2_CLIENTS_DETAILED |
| Feeds | DBA_VCC_MYSQL |
| Frequency | Daily |

**Root cause:** Same as above — Step 5 calls SP_AUDIT_WPv2_CLIENTS_DETAILED against dead WPv2 linked servers. Steps 1–4 (DXM client sizes, Lambda backup details) are succeeding. Only Step 5 fails. Job reports Failed overall despite 4 of 5 steps succeeding.

**Proposed resolution:**
| Action | Owner | Priority |
|---|---|---|
| Remove Step 5 (SP_AUDIT_WPv2_CLIENTS_DETAILED) from this job | DBA team | High |
| Validate Steps 1–4 continue to run correctly | DBA team | Medium |
| Consider renaming job to reflect DXM-only scope after WPv2 steps removed | DBA team | Low |

---

## Disabled Jobs — Action Required ⚠️

### MemSQL Jobs (7 disabled — all since May 2026)

| Job Name | Last Run | Last Outcome |
|---|---|---|
| DBA_VCC_MEMSQL_AUDIT_BACKUP_INFO_DETAILED | NULL | NULL |
| DBA_VCC_MEMSQL_DAILY_CHECKS | NULL | NULL |
| DBA_VCC_MEMSQL_GLOBAL_STATUS_CAPTURE | NULL | NULL |
| DBA_VCC_MEMSQL_HOURLY_CHECKS | NULL | NULL |
| DBA_VCC_MEMSQL_MON_PING_STATS | NULL | NULL |
| DBA_VCC_MEMSQL_MON_SQL_STATUS | NULL | NULL |
| DBA_VCC_MEMSQL_WEEKLY_CHECKS | NULL | NULL |

> NULL last run and NULL outcome — history was purged or these jobs were disabled before they ever ran in the current history window. Discovery confirmed last run was May 2026.

**Impact:** 14 Grafana dashboards reading from DBA_VCC_MEMSQL have been showing stale data since May 2026. 6 month-end reporting dashboards have no independent pipeline — June 2026 month-end reporting was impacted.

**Proposed resolution:**
| Action | Owner | Priority |
|---|---|---|
| Confirm why jobs were disabled — decommission, migration, or pause? | yogeshwar.phull / tashvir.babulal | Critical |
| If SingleStore decommissioned: drop all 7 jobs, archive DBA_VCC_MEMSQL, update 14 dashboards | DBA team | High |
| If SingleStore migrated: update linked server connections and re-enable jobs | DBA team | High |
| Notify dashboard consumers that data has been stale since May 2026 regardless of outcome | tashvir.babulal / rayhaan.suleyman | High |

---

### DBA Disabled Jobs (4 — NULL last run)

| Job Name | Last Outcome | Notes |
|---|---|---|
| DBA - MemSQL Range Stats Candidates | NULL | Disabled — last failed May 2023, MemSQL range stats finder |
| DBA - ObjectIDValidationReport | NULL | Disabled — last failed May 2026, queries EW1R-MSSQL-01 via linked server |
| DBA - Production Logon Report | NULL | Disabled — last failed May 2026, generates and emails production logon report |
| DBA - UtilitiesCleanupHistoryTables | NULL | Disabled — last failed May 2023, cleans MemSQL query length history tables |

**Proposed resolution:**
| Action | Owner | Priority |
|---|---|---|
| DBA - MemSQL Range Stats Candidates — drop, MemSQL monitoring disabled | DBA team | Medium |
| DBA - UtilitiesCleanupHistoryTables — drop, MemSQL monitoring disabled | DBA team | Medium |
| DBA - ObjectIDValidationReport — investigate failure before dropping, references EW1R-MSSQL-01 | DBA team | Low |
| DBA - Production Logon Report — confirm if report is still needed before dropping | DBA team | Low |

---

## Active Jobs — Full Inventory ✅

### DBA Maintenance (7 enabled, all succeeded)

| Job Name | Last Run | Schedule | Feeds | Notes |
|---|---|---|---|---|
| DBA - Maintenance - CHECKDB | 2026-07-15 22:00 | Daily 22:00 | msdb CommandLog | Ola Hallengren DBCC CHECKDB — ~2 hours nightly |
| DBA - Maintenance - History Cleanup | 2026-07-16 00:00 | Daily 00:00 | msdb | 5-step: cycles error logs, purges job history (30d), output files (30d), CommandLog (30d), backup history (30d) |
| DBA - Maintenance - ReIndex and Statistics - Local | 2026-07-12 01:00 | Weekly 01:00 | msdb CommandLog | Ola Hallengren IndexOptimize — all local databases |
| DBA - Maintenance - SQL Backup EW1P-OCT | 2026-07-16 14:00 | Daily | S3: ksys-ew1p-oct-dbbackup | Backs up EW1P-OCT RDS to S3. ⚠️ KMS key NULL — unencrypted at rest |
| DBA - Maintenance - SQL Backups DIFF | 2026-07-16 00:00 | Daily 00:05 | S3: ksys-ew1r-db-backups | Ola Hallengren DIFF + S3 sync via xp_cmdshell. ⚠️ No encryption in sync command |
| DBA - Maintenance - SQL Backups FULL | 2026-07-11 00:00 | Weekly 00:05 | S3: ksys-ew1r-db-backups | Ola Hallengren FULL + S3 sync via xp_cmdshell. ⚠️ No encryption in sync command |
| DBA - Maintenance - SQL Backups LOG | 2026-07-16 14:00 | Hourly | S3: ksys-ew1r-db-backups | Ola Hallengren LOG + S3 sync via xp_cmdshell. ⚠️ No encryption in sync command |
| DBA - SSISStatusCheck | 2026-07-16 14:00 | SCHED1 | Slack | Sends Slack alert for long-running SSIS packages via SP_MON_SSIS_Long_Running_Packages_Slack |

### Baseline / KAPP (3 enabled, all succeeded)

| Job Name | Last Run | Schedule | Feeds | Notes |
|---|---|---|---|---|
| BASELINE_CONNECTIONS | 2026-07-16 14:00 | SCHED1 | KURTOSYS_BASELINE | SP_BAS_MEMSQL_CONNECTIONS, SP_BAS_MSSQL_CONNECTIONS, SP_BAS_MYSQL_CONNECTIONS |
| BASELINE_TABLE_SIZES | 2026-07-16 10:00 | SCHED1 | KURTOSYS_BASELINE | Captures table size baselines across MemSQL, MySQL, MSSQL |
| DBA - AUDIT - KAPP_Schema_details_Capture | 2026-07-16 11:00 | Daily | Utilities | USP_KAPP_Schema_details_Capture — captures KAPP schema metadata |

### VCC AWS Jobs (3 enabled, all succeeded)

| Job Name | Last Run | Schedule | Feeds | Notes |
|---|---|---|---|---|
| DBA_VCC_AWS_15MIN_CHECKS | 2026-07-16 14:00 | Every 30 min | DBA_VCC_AWS | 12-step: KAPP API logs, NiFi logs, Lambda timeouts, dataset metrics via Python |
| DBA_VCC_AWS_DAILY_CHECKS | 2026-07-16 06:00 | Daily | DBA_VCC_AWS | S3 sizes, AWS costs per entity, regional data transfer bytes via Python |
| DBA_VCC_AWS_WEEKLY_CHECKS | 2026-07-12 04:00 | Weekly | DBA_VCC_AWS | RDS inventory, EC2 inventory, IAM keys, S3 lifecycle/encryption |

### VCC Core Monitoring (4 enabled, all succeeded)

| Job Name | Last Run | Schedule | Feeds | Notes |
|---|---|---|---|---|
| DBA_VCC_DAILY_CHECKS | 2026-07-16 14:00 | Daily | DBA_VCC | SP_AUDIT_ENCORE_DOCUMENT_PRODUCTION_DETAILED — Encore document production metrics |
| DBA_VCC_HOURLY_CHECKS | 2026-07-16 14:15 | Hourly | DBA_VCC | BNY IIS logs from CloudWatch — Encore/BNY IIS log ingestion |
| DBA_VCC_WEEKLY_CHECKS | 2026-07-12 00:00 | Weekly | DBA_VCC | Archives DBA_VCC tables older than 90 days, index fragmentation audit |
| DBA_VCC_BASE_SERVER_MEMORY_PRESSURE_DETAILED | 2026-07-16 12:00 | SCHED1 | DBA_VCC | Server memory pressure check — sends mail alert if threshold breached |

### VCC Audit Collection (16 enabled, all succeeded)

| Job Name | Last Run | Feeds |
|---|---|---|
| DBA_VCC_AUDIT_BACKUP_INFO_DETAILED | 2026-07-16 12:00 | DBA_VCC |
| DBA_VCC_AUDIT_DATABASE_CREATION | 2026-07-16 01:00 | DBA_VCC |
| DBA_VCC_AUDIT_DATABASE_INFO_DETAILED | 2026-07-16 01:00 | DBA_VCC |
| DBA_VCC_AUDIT_DATABASE_USERS_DETAILED | 2026-07-16 06:00 | DBA_VCC |
| DBA_VCC_AUDIT_DBINFO_DETAILED | 2026-07-16 12:00 | DBA_VCC |
| DBA_VCC_AUDIT_ERRORLOG_SIZES_DETAILED | 2026-07-16 12:00 | DBA_VCC |
| DBA_VCC_AUDIT_FAILED_LOGIN_SQL_CHECK | 2026-07-16 06:00 | DBA_VCC |
| DBA_VCC_AUDIT_JOB_INFO_DETAILED | 2026-07-16 06:00 | DBA_VCC |
| DBA_VCC_AUDIT_LOGIN_SQL_CHECK | 2026-07-16 06:00 | DBA_VCC |
| DBA_VCC_AUDIT_LOW_RUNNING_DRIVES_FILES_DETAILED | 2026-07-16 04:00 | DBA_VCC |
| DBA_VCC_AUDIT_SERVER_RESTART_REQUIRED_DETAILED | 2026-07-16 05:00 | DBA_VCC |
| DBA_VCC_AUDIT_SQL_DATABASE_USAGE_DETAILED | 2026-07-16 02:00 | DBA_VCC |
| DBA_VCC_AUDIT_SQL_LOGINS_INFO_DETAILED | 2026-07-16 03:00 | DBA_VCC |
| DBA_VCC_AUDIT_SQL_SERVER_DEFAULT_LOCATIONS_DETAILED | 2026-07-16 00:00 | DBA_VCC |
| DBA_VCC_AUDIT_TOP5_TABLES_PER_DATABASE_DETAILED | 2026-07-16 01:00 | DBA_VCC |
| DBA_VCC_AUDIT_TRACE_FLAGS_DETAILED | 2026-07-16 00:00 | DBA_VCC |

> All 16 audit collection jobs monitor EW2P-MSSQL-01 and EW2P-MSSQL-02. These are production SQL Server instances. If EW1R-REP-01 is decommissioned, monitoring of these servers stops entirely.

### VCC Server Monitoring (8 enabled, all succeeded)

| Job Name | Last Run | Schedule | Feeds |
|---|---|---|---|
| DBA_VCC_MON_BASE_SERVER_MEMORY_CHECK | 2026-07-16 12:00 | SCHED1 | DBA_VCC |
| DBA_VCC_MON_CHECKS_SERV_DATA_COLLECT | 2026-07-16 14:15 | SCHED1 | DBA_VCC |
| DBA_VCC_MON_CONNECTION_CHECK | 2026-07-16 14:15 | SCHED1 | DBA_VCC |
| DBA_VCC_MON_Eventlog_CHECK | 2026-07-16 12:00 | SCHED1 | DBA_VCC |
| DBA_VCC_MON_LOCAL_DRIVE_CHECK | 2026-07-16 12:00 | SCHED1 | DBA_VCC |
| DBA_VCC_MON_SQL_DAILY_BACKUPS_CHECK | 2026-07-16 14:00 | Daily | DBA_VCC |
| DBA_VCC_MON_SQL_SERVER_INFO_CHECK | 2026-07-16 06:00 | SCHED1 | DBA_VCC |
| DBA_VCC_MON_VLF_COUNT_CHECK | 2026-07-16 08:00 | Daily | DBA_VCC |

### VCC MySQL / DXM (5 enabled, all succeeded)

| Job Name | Last Run | Schedule | Feeds | Notes |
|---|---|---|---|---|
| DBA_VCC_MYSQL_AUDIT_BACKUP_INFO_DETAILED | 2026-07-16 01:00 | SCHED1 | DBA_VCC_MYSQL | MySQL backup audit — succeeded |
| DBA_VCC_MYSQL_MON_PING_STATS | 2026-07-16 14:15 | SCHED1 | DBA_VCC_MYSQL | MySQL ping stats — SP_MON_PING_STATS. ⚠️ xp_cmdshell commented out — all targets get Status=1 regardless of reachability |
| DBA_VCC_MYSQL_MON_SQL_STATUS | 2026-07-16 14:15 | SCHED1 | DBA_VCC_MYSQL | MySQL status check |
| DBA_VCC_MYSQL_MON_SQL_VERSION_CHECK | 2026-07-16 08:00 | SCHED1 | DBA_VCC_MYSQL | MySQL version check |
| DBA_VCC_MYSQL_WEEKLY_CHECKS | 2026-07-12 00:00 | Weekly | DBA_VCC_MYSQL | DXM post tracking, archival — most steps commented out |

### VCC Cost / Atlassian (2 enabled, all succeeded)

| Job Name | Last Run | Schedule | Feeds | Notes |
|---|---|---|---|---|
| DBA_VCC_COST_Entity_Count_Collection | 2026-07-13 08:00 | Weekly Monday | DBA_VCC_COST | KAPP client entity counts — allocations, disclaimers, documents |
| DBA_VCC_JIRA_MONTHEND_CHECKS | 2026-07-01 08:00 | Monthly | DBA_VCC_AWS | Jira sprint data via Python API |

### System (1 enabled, succeeded)

| Job Name | Last Run | Schedule | Notes |
|---|---|---|---|
| syspolicy_purge_history | 2026-07-16 02:00 | Daily | Standard SQL Server system job |

---

## Job Summary

| Category | Total | Enabled | Disabled | Failing |
|---|---|---|---|---|
| DBA Maintenance | 11 | 7 | 4 | 0 |
| Baseline / KAPP | 3 | 3 | 0 | 0 |
| VCC AWS | 3 | 3 | 0 | 0 |
| VCC Core | 4 | 4 | 0 | 0 |
| VCC Audit Collection | 16 | 16 | 0 | 0 |
| VCC Server Monitoring | 8 | 8 | 0 | 0 |
| VCC MySQL / DXM | 7 | 5 | 0 | 2 |
| VCC MemSQL | 7 | 0 | 7 | 0 |
| VCC Cost / Atlassian | 2 | 2 | 0 | 0 |
| System | 1 | 1 | 0 | 0 |
| **Total** | **63** | **52** | **11** | **2** |

---

## Findings

### F1 — 2 jobs failing daily, no alert fires
`DBA_VCC_MYSQL_AUDIT_DXM_CLIENT_DETAILED` and `DBA_VCC_MYSQL_DAILY_CHECKS` fail every day. Both fail on `SP_AUDIT_WPv2_CLIENTS_DETAILED` — a stored procedure that has not been updated since WPv2 was decommissioned in 2022. No operator is wired to these jobs so no notification fires. The failures are invisible unless someone manually checks job history.

### F2 — 7 MemSQL jobs disabled, reason unconfirmed
All 7 MemSQL collection jobs disabled since May 2026. 14 Grafana dashboards have been showing stale data ever since. 6 month-end dashboards have no independent pipeline — June 2026 month-end reporting was impacted silently.

### F3 — Ping stats are unreliable
`SP_MON_PING_STATS` has `xp_cmdshell` commented out. Every server in `V_InstanceList` gets `Status = 1` written regardless of actual reachability. Dead WPv2 servers still appear as reachable in ping data. Any dashboard or report reading ping status data is showing false positives.

### F4 — Backup jobs have no encryption
3 backup jobs (`SQL Backups DIFF`, `SQL Backups FULL`, `SQL Backups LOG`) sync to S3 via `xp_cmdshell` with no `--sse` flag. `DBA - Maintenance - SQL Backup EW1P-OCT` has KMS key NULL. Backups are unencrypted at rest in S3.

### F5 — Decommissioning this server stops monitoring of EW2P-MSSQL-01 and EW2P-MSSQL-02
All 16 VCC Audit Collection jobs and 8 VCC Server Monitoring jobs monitor production SQL Server instances EW2P-MSSQL-01 and EW2P-MSSQL-02. There is no secondary monitoring path. Decommissioning EW1R-REP-01 without migrating the VCC framework leaves two production servers unmonitored.

---

## Open Questions

| # | Question | Who to Ask | Blocks |
|---|---|---|---|
| Q-J1 | Why were MemSQL jobs disabled in May 2026 — decommission, migration, or pause? | yogeshwar.phull / tashvir.babulal | MemSQL job resolution |
| Q-J2 | What is the migration plan for VCC monitoring of EW2P-MSSQL-01/02 post-decommission? | DBA team | Decommission date |
| Q-J3 | What SSIS packages does DBA - SSISStatusCheck monitor — where do they run? | DBA team | SSISStatusCheck relevance |
| Q-J4 | Is DBA - Maintenance - SQL Backup EW1P-OCT still needed — who owns that RDS instance? | DBA team | Backup job cleanup |
| Q-J5 | Why is xp_cmdshell commented out in SP_MON_PING_STATS — was this intentional? | DBA team | Ping data reliability |
| Q-J6 | Are the S3 backup encryption gaps a known risk or an oversight? | DBA team / DevOps | Compliance |
