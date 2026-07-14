# SQL Server Inventory — EW1R-REP-01

## Server Info
| Property | Value |
|---|---|
| Hostname | EW1R-REP-01 |
| SQL Server Version | 2019 (RTM-CU32-GDR) KB5068404 — 15.0.4455.2 |
| Edition | Developer Edition (64-bit) |
| OS | Windows Server 2019 Datacenter 10.0 (Hypervisor) |
| Collation | Latin1_General_CI_AS |
| Patch Level | Fully patched as of Oct 7 2025 |

---

## Databases

| Database | Size (MB) | Recovery Model | Purpose |
|---|---|---|---|
| DBA_VCC_AWS | 189,088 | SIMPLE | AWS infrastructure and KAPP API monitoring data |
| DBA_VCC_MEMSQL | 77,316 | SIMPLE | SingleStore/MemSQL monitoring data (jobs disabled) |
| KURTOSYS_BASELINE | 52,224 | SIMPLE | Performance baseline captures (connections, table sizes) |
| DBA_VCC_MYSQL | 27,262 | SIMPLE | MySQL and RDS monitoring data |
| DBA_VCC | 24,625 | SIMPLE | Core VCC monitoring framework data |
| DBA_VCC_COST | 5,120 | FULL | Cost tracking per entity/client (FULL recovery — critical) |
| DBA_VCC_ATLASSIAN | 2,048 | SIMPLE | Jira/Confluence integration data |
| Utilities | 201 | SIMPLE | DBA utility scripts and stored procedures |

**Total data size: ~378 GB** (confirmed — last run July 2026)

---

## Key Database Contents

### DBA_VCC_AWS (180 GB)
Core AWS and KAPP monitoring database. Largest on the server.

| Table | Rows | Size (MB) | Notes |
|---|---|---|---|
| INFO_AWS_KAPP_Query_API_Detail | 563,685,574 | 143,798 | Every KAPP API query — actively growing |
| INFO_AWS_KAPP_Query_Datasets_Detail | 59,793,228 | 15,316 | Dataset-level query tracking |
| INFO_AWS_KAPP_Source_Datasets_Detail | 50,704,002 | 14,461 | Source dataset tracking |
| ARC_INFO_AWS_Nifi_Loader_API_Detail | 14,122,899 | 3,876 | NiFi pipeline archive |
| INFO_AWS_Nifi_Loader_API_Detail | 2,699,971 | 759 | NiFi data pipeline monitoring |
| MON_AWS_Entity_Cost | 2,466,484 | 377 | Cost monitoring per entity |
| INFO_AWS_EC2_Detail | 22,296 | 7 | EC2 instance inventory |
| INFO_AWS_RDS_Detail | 9,159 | 7 | RDS instance inventory |

### DBA_VCC (21 GB)
Core monitoring framework — tracks all monitored SQL Server instances.

| Table | Rows | Size (MB) | Notes |
|---|---|---|---|
| INFO_AWS_Encore_Cloudwatch_IIS_Logs | 65,023,023 | 7,032 | Encore IIS logs via CloudWatch |
| INFO_Table_Index_Frag_Detail | 34,693,911 | 6,813 | Index fragmentation history |
| ARC_SQL_Errorlog_Check | 40,564,851 | 1,400 | SQL error log archive |
| ARC_Database_Status_Check | 29,829,380 | 1,089 | Database status history |
| ARC_SQL_Connection_Check | 24,512,430 | 339 | Connection history |

---

## Monitored Servers (LU_Serverlist)

| Server | Active | Environment | Platform |
|---|---|---|---|
| EW2P-MSSQL-01 | Yes | Production | SHD Prod |
| EW2P-MSSQL-02 | Yes | Production | SHD Prod |
| EW1D-MSSQL-01 | No | Dev | SHD Non-Prod |
| ew1r-mssql-01 | No | Release | Kexpress (legacy) |

---

## SQL Agent Jobs

### DBA Maintenance Jobs

| Job Name | Enabled | Last Run | Last Outcome | Schedule | Alert Target | Purpose |
|---|---|---|---|---|---|---|
| BASELINE_CONNECTIONS | Yes | 2026-07-06 | Succeeded | Sched1 | None | Captures connection baselines across MemSQL, MSSQL, and MySQL via stored procs into KURTOSYS_BASELINE |
| BASELINE_TABLE_SIZES | Yes | 2026-07-06 | Succeeded | SCHED1 | None | Captures table size baselines across MemSQL, MySQL, and MSSQL into KURTOSYS_BASELINE |
| DBA - AUDIT - KAPP_Schema_details_Capture | Yes | 2026-07-06 | Succeeded | Everyday once | None | Executes USP_KAPP_Schema_details_Capture in Utilities — captures KAPP schema metadata daily |
| DBA - Maintenance - CHECKDB | Yes | 2026-07-05 | Succeeded | Daily @ 22:00 | dba@kurtosys.com | Ola Hallengren DBCC CHECKDB on all read-write databases, logs to CommandLog |
| DBA - Maintenance - History Cleanup | Yes | 2026-07-06 | Succeeded | Daily @ 00:00 | dba@kurtosys.com | 5-step cleanup: cycles error logs, purges job history (30d), cleans output files (30d), cleans CommandLog (30d), deletes backup history (30d) |
| DBA - Maintenance - ReIndex and Statistics - Local | Yes | 2026-07-05 | Succeeded | Weekly @ 01:00 | dba@kurtosys.com | Ola Hallengren IndexOptimize on all local databases excluding AG databases |
| DBA - Maintenance - SQL Backup EW1P-OCT | Yes | 2026-07-06 | Succeeded | Sched1 | None | Backs up RDS instance EW1P-OCT directly to S3 via ARN — custom backup proc in master |
| DBA - Maintenance - SQL Backups DIFF | Yes | 2026-07-06 | Succeeded | Daily @ 00:05 | dba@kurtosys.com | Ola Hallengren DIFF backup to D:\SQL\Backup\, then copies to S3 via USP_DatabaseBackupMoveToS3 |
| DBA - Maintenance - SQL Backups FULL | Yes | 2026-07-04 | Succeeded | Weekly @ 00:05 | dba@kurtosys.com | Ola Hallengren FULL backup to D:\SQL\Backup\, then copies to S3 via USP_DatabaseBackupMoveToS3 |
| DBA - Maintenance - SQL Backups LOG | Yes | 2026-07-06 | Succeeded | Hourly | dba@kurtosys.com | Ola Hallengren LOG backup to D:\SQL\Backup\, then copies to S3 via USP_DatabaseBackupMoveToS3 |
| DBA - SSISStatusCheck | Yes | 2026-07-06 | Succeeded | SCHED1 | dba@kurtosys.com | Executes SP_MON_SSIS_Long_Running_Packages_Slack in DBA_VCC — sends Slack alert for long-running SSIS packages |
| DBA - MemSQL Range Stats Candidates | No | 2023-05-15 | **Failed** | Every 8 hours | dba@kurtosys.com | DISABLED — last failed May 2023, finds range statistics candidates in MemSQL |
| DBA - ObjectIDValidationReport | No | 2026-05-04 | **Failed** | Weekly | dba@kurtosys.com | DISABLED — last failed May 2026, queries EW1R-MSSQL-01 via linked server |
| DBA - Production Logon Report | No | 2026-05-04 | **Failed** | Weekly | dba@kurtosys.com | DISABLED — last failed May 2026, generates and emails production logon report |
| DBA - UtilitiesCleanupHistoryTables | No | 2023-05-14 | **Failed** | Daily 11 PM | dba@kurtosys.com | DISABLED — last failed May 2023, cleans MemSQL query length history tables older than 90 days |

### VCC AWS Jobs

| Job Name | Enabled | Last Run | Last Outcome | Schedule | Alert Target | Purpose |
|---|---|---|---|---|---|---|
| DBA_VCC_AWS_15MIN_CHECKS | Yes | 2026-07-06 | Succeeded | Every 30 min | None | 12-step job: pulls KAPP API query logs, NiFi loader API logs, KAPP dataset logs, Lambda timeout logs, and dataset metrics from CloudWatch log streams via Python (SP_AUDIT_AWS_PY_CALL_DETAILED). Core KAPP observability job. |
| DBA_VCC_AWS_DAILY_CHECKS | Yes | 2026-07-06 | Succeeded | Daily | None | Collects S3 bucket sizes, AWS costs per entity, and regional data transfer bytes via Python API calls. |
| DBA_VCC_AWS_WEEKLY_CHECKS | Yes | 2026-07-05 | Succeeded | Weekly | None | Collects RDS inventory, RDS maintenance windows, RDS security group rules, S3 lifecycle/encryption, EC2 inventory, IAM key details. Archives data older than 90 days. |

### VCC Core Monitoring Jobs

| Job Name | Enabled | Last Run | Last Outcome | Schedule | Alert Target | Purpose |
|---|---|---|---|---|---|---|
| DBA_VCC_DAILY_CHECKS | Yes | 2026-07-06 | Succeeded | Daily | None | Executes SP_AUDIT_ENCORE_DOCUMENT_PRODUCTION_DETAILED — tracks Encore document production metrics daily |
| DBA_VCC_HOURLY_CHECKS | Yes | 2026-07-06 | Succeeded | Hourly | None | Collects BNY IIS logs from CloudWatch (iis_logstream) and runs ETL cleanup — Encore/BNY IIS log ingestion |
| DBA_VCC_WEEKLY_CHECKS | Yes | 2026-07-05 | Succeeded | Weekly | None | Archives DBA_VCC tables older than 90 days and runs index fragmentation audit |
| DBA_VCC_BASE_SERVER_MEMORY_PRESSURE_DETAILED | Yes | 2026-07-06 | Succeeded | SCHED1 | None | Checks server memory pressure and sends mail alert if threshold breached |

### VCC Audit Collection Jobs (all enabled, all succeeded 2026-07-06, no alert target)

| Job Name | Purpose |
|---|---|
| DBA_VCC_AUDIT_BACKUP_INFO_DETAILED | Collects backup info detail across monitored servers |
| DBA_VCC_AUDIT_DATABASE_CREATION | Audits database creation dates |
| DBA_VCC_AUDIT_DATABASE_INFO_DETAILED | Collects detailed database info |
| DBA_VCC_AUDIT_DATABASE_USERS_DETAILED | Audits database users across servers |
| DBA_VCC_AUDIT_DBINFO_DETAILED | Collects DB-level info detail |
| DBA_VCC_AUDIT_ERRORLOG_SIZES_DETAILED | Audits error log sizes; sends mail if logs are oversized or need cycling |
| DBA_VCC_AUDIT_FAILED_LOGIN_SQL_CHECK | Audits failed SQL login attempts |
| DBA_VCC_AUDIT_JOB_INFO_DETAILED | Collects SQL Agent job info across monitored servers |
| DBA_VCC_AUDIT_LOGIN_SQL_CHECK | Audits SQL logins; cleans data older than 120 days |
| DBA_VCC_AUDIT_LOW_RUNNING_DRIVES_FILES_DETAILED | Audits low disk space; sends mail alert if drives are low |
| DBA_VCC_AUDIT_SERVER_RESTART_REQUIRED_DETAILED | Checks if servers require restart; sends mail alert |
| DBA_VCC_AUDIT_SQL_DATABASE_USAGE_DETAILED | Audits SQL database usage |
| DBA_VCC_AUDIT_SQL_LOGINS_INFO_DETAILED | Collects SQL login info detail |
| DBA_VCC_AUDIT_SQL_SERVER_DEFAULT_LOCATIONS_DETAILED | Audits SQL Server default file locations |
| DBA_VCC_AUDIT_TOP5_TABLES_PER_DATABASE_DETAILED | Collects top 5 largest tables per database |
| DBA_VCC_AUDIT_TRACE_FLAGS_DETAILED | Audits trace flags across monitored servers |

### VCC Server Monitoring Jobs

| Job Name | Enabled | Last Run | Last Outcome | Schedule | Alert Target | Purpose |
|---|---|---|---|---|---|---|
| DBA_VCC_MON_BASE_SERVER_MEMORY_CHECK | Yes | 2026-07-06 | Succeeded | SCHED1 | None | Monitors server memory pressure |
| DBA_VCC_MON_CHECKS_SERV_DATA_COLLECT | Yes | 2026-07-06 | Succeeded | SCHED1 | None | Collects server check data and moves to MON tables via SP_VCC_MOVE_MON_SERV2_DATA |
| DBA_VCC_MON_CONNECTION_CHECK | Yes | 2026-07-06 | Succeeded | SCHED1 | None | Runs connection checks and moves data to MON tables. Open tran check steps are commented out. |
| DBA_VCC_MON_Eventlog_CHECK | Yes | 2026-07-06 | Succeeded | SCHED1 | None | Monitors Windows event log for errors |
| DBA_VCC_MON_LOCAL_DRIVE_CHECK | Yes | 2026-07-06 | Succeeded | SCHED1 | None | Monitors local disk space |
| DBA_VCC_MON_SQL_DAILY_BACKUPS_CHECK | Yes | 2026-07-06 | Succeeded | Daily | None | Verifies daily backups completed successfully |
| DBA_VCC_MON_SQL_SERVER_INFO_CHECK | Yes | 2026-07-06 | Succeeded | SCHED1 | None | Collects SQL Server instance info |
| DBA_VCC_MON_VLF_COUNT_CHECK | Yes | 2026-07-06 | Succeeded | Daily | None | Checks VLF counts and sends mail report |

### VCC MySQL / DXM Jobs

| Job Name | Enabled | Last Run | Last Outcome | Schedule | Alert Target | Purpose |
|---|---|---|---|---|---|---|
| DBA_VCC_MYSQL_AUDIT_BACKUP_INFO_DETAILED | Yes | 2026-07-06 | Succeeded | SCHED1 | None | Audits MySQL backup info |
| DBA_VCC_MYSQL_AUDIT_DXM_CLIENT_DETAILED | Yes | 2026-07-06 | **Failed** ⚠️ | Daily | None | Audits DXM client details and WPv2 client details via MySQL linked servers — investigate failure |
| DBA_VCC_MYSQL_DAILY_CHECKS | Yes | 2026-07-06 | **Failed** ⚠️ | Daily | None | Collects WPv2 and DXM client sizes, DXM Lambda backup details — investigate failure |
| DBA_VCC_MYSQL_MON_PING_STATS | Yes | 2026-07-06 | Succeeded | SCHED1 | None | Pings MySQL targets and records stats |
| DBA_VCC_MYSQL_MON_SQL_STATUS | Yes | 2026-07-06 | Succeeded | SCHED1 | None | Checks MySQL instance status |
| DBA_VCC_MYSQL_MON_SQL_VERSION_CHECK | Yes | 2026-07-06 | Succeeded | SCHED1 | None | Checks MySQL version across targets |
| DBA_VCC_MYSQL_WEEKLY_CHECKS | Yes | 2026-07-05 | Succeeded | Weekly | None | DXM post tracking. Most steps commented out. Archives data older than 90 days. |

### VCC Cost and Atlassian Jobs

| Job Name | Enabled | Last Run | Last Outcome | Schedule | Alert Target | Purpose |
|---|---|---|---|---|---|---|
| DBA_VCC_COST_Entity_Count_Collection | Yes | 2026-07-06 | Succeeded | SCHED1 | None | Collects KAPP client entity counts: allocations, disclaimers/commentaries, documents, and other entity types via stored procs in DBA_VCC_COST |
| DBA_VCC_JIRA_MONTHEND_CHECKS | Yes | 2026-07-01 | Succeeded | Monthly | None | Pulls Jira sprint data via Python API call (jira_sprint logstream) and runs ETL cleanup into DBA_VCC_AWS |

### VCC MemSQL Jobs (ALL DISABLED — last ran May 2026)

| Job Name | Last Run | Last Outcome | Schedule | Purpose |
|---|---|---|---|---|
| DBA_VCC_MEMSQL_AUDIT_BACKUP_INFO_DETAILED | 2026-05-08 | Succeeded | SCHED1 | Would audit MemSQL backup info |
| DBA_VCC_MEMSQL_DAILY_CHECKS | 2026-05-08 | **Failed** | SCHED1 | Would collect top queries, FP duplicate data, loader/snapshot history, client sizes |
| DBA_VCC_MEMSQL_GLOBAL_STATUS_CAPTURE | 2025-05-05 | Succeeded | Every minute | Would capture MemSQL global status every minute |
| DBA_VCC_MEMSQL_HOURLY_CHECKS | 2026-05-08 | Succeeded | SCHED1 | Would collect KAPP workflow run history and timing |
| DBA_VCC_MEMSQL_MON_PING_STATS | 2026-05-08 | Succeeded | SCHED1 | Would ping MemSQL nodes |
| DBA_VCC_MEMSQL_MON_SQL_STATUS | 2026-05-08 | Succeeded | SCHED1 | Would check MemSQL instance status |
| DBA_VCC_MEMSQL_WEEKLY_CHECKS | 2026-05-03 | Succeeded | SCHED1 | Would archive MemSQL tables older than 90 days |

> All MemSQL jobs disabled. Last ran May 2026 — confirmed. DBA_VCC_MEMSQL_DAILY_CHECKS failed on last run. 77 GB of historical data remains. Monitoring likely moved elsewhere — needs confirmation.

### System Job

| Job Name | Enabled | Purpose |
|---|---|---|
| syspolicy_purge_history | Yes | Standard SQL Server system job — purges policy history and phantom health records |

### Job Summary

| Category | Total | Enabled | Disabled |
|---|---|---|---|
| DBA Maintenance | 11 | 7 | 4 |
| VCC AWS Checks | 3 | 3 | 0 |
| VCC Core Checks | 4 | 4 | 0 |
| VCC Audit Collection | 16 | 16 | 0 |
| VCC MySQL / DXM | 7 | 7 | 0 |
| VCC MemSQL | 7 | 0 | 7 |
| VCC Server Monitoring | 8 | 8 | 0 |
| VCC Cost / Atlassian | 2 | 2 | 0 |
| Baseline / KAPP | 2 | 2 | 0 |
| System | 1 | 1 | 0 |
| VCC Weekly | 1 | 1 | 0 |
| **Total** | **63** | **52** | **11** |

---

## Linked Servers

### SQL Server Linked Servers (SQLNCLI)
| Server | Type | Notes |
|---|---|---|
| EW1P-OCT.CNMEBXZBEDLW.EU-WEST-1.RDS.AMAZONAWS.COM | RDS SQL Server | Production RDS in eu-west-1 |
| EW1D-MSSQL-01 | SQL Server | Dev SQL Server |
| EW1R-MSSQL-01 | SQL Server | Release SQL Server |
| EW2P-MSSQL-01 | SQL Server | Production SQL Server eu-west-2 |
| EW2P-MSSQL-02 | SQL Server | Production SQL Server eu-west-2 |
| ew1p-oct | SQL Server | Likely same as RDS above (short name) |

### SingleStore/MemSQL Nodes (MSDASQL/ODBC)
| Region | Aggregator Nodes | Leaf Nodes | DXM Nodes |
|---|---|---|---|
| EC1 (eu-central-1) | ec1p-aggr-01/02/03/04 | ec1p-leaf-01/02/03/04/51/52/53/54 | ec1p-dxm, ec1p-dxm-logging |
| EW1 (eu-west-1) | ew1r-aggr-01/02/03/04, ew1r-aggr-03.gen-rel, ew1r-aggr-05.gen-rel | ew1r-leaf-01/02/03/04/05/06/07/08, ew1r-leaf-11.gen-rel, ew1r-leaf-12.gen-rel, ew1r-leaf-14.gen-rel | ew1r-dxm, ew1r-dxm-logging |
| EW1 Dev | — | — | ew1d-dxm, ew1d-dxm-logging |
| EW2 (eu-west-2) | ew2p-aggr-01/02/03/04, ew2p-aggr-01.gen-prd, ew2p-aggr-02.gen-prd, ew2p-aggr-10.gen-prd, ew2p-aggr-11.gen-prd | ew2p-leaf-01/02/03/04/05/06, ew2p-leaf-01-04.gen-prd, ew2p-leaf-11-14.gen-prd, ew2p-leaf-21-24.gen-prd, ew2p-leaf-51-54/51-54.gen-prd, ew2p-leaf-55/56, ew2p-leaf-61.gen-prd | ew2p-dxm, ew2p-dxm-logging, ew2p-dxm-repl |
| UE1 (us-east-1) | ue1p-aggr-01/02/03/04 | ue1p-leaf-01/02/03/04/51/52/53/54 | ue1p-dxm, ue1p-dxm-logging, ue1p-dxm-repl |

> Note: `.gen-rel` and `.gen-prd` suffixed nodes are generation-tagged variants of existing nodes — confirmed present in sys.servers as separate linked server entries.

### Other Linked Servers (MSDASQL)
| Server | Type | Notes |
|---|---|---|
| pmmdev | Clickhouse | Percona Monitoring and Management — dev |
| pmmprod | Clickhouse | Percona Monitoring and Management — prod |
| ZabbixNonProd | Zabbix | Non-production Zabbix monitoring |
| ZabbixProdOld | Zabbix | Old production Zabbix instance |
| ZabbixProdNew | Zabbix | Current production Zabbix instance |
| EW1P-NIFIREG-01 | NiFi Registry | Apache NiFi registry |
| EW1R-TC | Unknown | Likely TeamCity build server |
| ew1d-admin-01/02 | Admin | Dev admin servers |
| ew2p-wpv2 / ew2r-wpv2 | Web Platform v2 | EW2 web platform |
| ue1p-wpv2 / ue1r-wpv2 | Web Platform v2 | UE1 web platform |

**Total linked servers: 109**

---

## Open Items
- [ ] Confirm what SSIS packages are being checked by DBA - SSISStatusCheck
- [ ] Identify what reads from MON_ tables (Grafana datasource?)
- [ ] Confirm if EW1P-OCT RDS backup job is still needed
- [ ] Identify owner of DBA_VCC_COST data — who consumes cost reports?
- [ ] Confirm if MemSQL linked servers are still reachable or all stale

---

## Stored Procedure Inventory (query 13.6 — confirmed 2026-07-07)

Total across all user databases: ~600+ procedures. Counts per database:

| Database | SP Count | Notes |
|---|---|---|
| DBA_VCC | ~160 | Core monitoring/reporting SPs. Prefixes: APP_, DBA_, MAINT_, REP_, SP_AUDIT_, SP_MON_, SP_REP_, SP_VDBA_, SP_VCC_. Most created 2017-11-30 (bulk deploy). Notable recent: `SP_AUDIT_ENCORE_DOCUMENT_PRODUCTION_DETAILED` (2023-08), `SP_AUDIT_INDEX_FRAG_DETAILED` (2023-06), `SP_AUDIT_IIS_ETL_CLEANUP` (2023-07). |
| DBA_VCC_MEMSQL | ~200 | Largest SP set. Mirrors DBA_VCC base set plus FinancialPortal (FP_), InvestorPress (IP_), KAPP-specific SPs. Notable: `SP_AUDIT_FP_Client_DETAILED` (modified 2024-09), `SP_AUDIT_KAPP_WorkFlow_Run_History` (2024-03), `REP_CLIENT_APP_AUTH_CONFIG_CHANGES_REPORT` (2024-10), `USP_GLOBAL_STATUS_INSERT` (modified 2024-08), `DBA_KAPP_DELETE_CREATOR` (modified 2024-11). |
| DBA_VCC_MYSQL | ~200 | Mirrors MEMSQL base set plus DXM/WPv2-specific SPs. Notable: `SP_AUDIT_WPv2_CLIENTS_DETAILED` (the failing job's target — last modified 2022-11-01), `SP_AUDIT_DXM_CLIENT_SIZES_DETAILED` (2023-05), `SP_AUDIT_DATABASE_TABLE_SIZES_DETAILED` (2023-05), TAC monitoring SPs (`SP_MON_TAC_*`). |
| DBA_VCC_AWS | 15 | ETL cleanup SPs only. All `SP_AUDIT_*_ETL_CLEANUP`. Most recent: `SP_AUDIT_AWS_PY_CALL_DETAILED` (modified 2024-11), `SP_AUDIT_KAPP_QUERY_DATASETS_ETL_CLEANUP` (modified 2024-10). |
| DBA_VCC_COST | 28 | Two groups: `REP_MONTHEND_*` reporting SPs and `SP_INFO_KAPP_CLIENT_*_COUNTS` collection SPs. All created 2022–2023, last modified 2023. |
| DBA_VCC_ATLASSIAN | 0 | No stored procedures. Confirmed — reference data store only. |
| KURTOSYS_BASELINE | 8 | Baseline collection SPs: MSSQL, MemSQL, MySQL connections and table sizes. Plus `sp_WhoIsActive` (2024-02). |
| Utilities | ~60 | DBA utility scripts. Ola Hallengren maintenance SPs (`DatabaseBackup`, `IndexOptimize`, etc.), Zabbix integration (`USP_ZAB_*`), MemSQL history collection (`USP_MemSQL_*`), KAPP schema comparison (`USP_KAPP_Schema_details_Capture` modified 2024-08, `USP_ZAB_KAPP_schema_compare` modified 2024-05). |

### Key observations

- `SP_AUDIT_WPv2_CLIENTS_DETAILED` in DBA_VCC_MYSQL — last modified **2022-11-01**. This is the SP called by the failing job `DBA_VCC_MYSQL_AUDIT_DXM_CLIENT_DETAILED`. The SP has not been touched since WPv2 was decommissioned. Likely broken due to missing source tables.
- DBA_VCC and DBA_VCC_MEMSQL/MYSQL share a large common base of SPs (APP_, SP_MON_, SP_REP_, SP_VDBA_, SP_VCC_) — these were bulk-deployed in 2017 and are largely unchanged. Not all are actively called.
- DBA_VCC_MEMSQL has the most actively maintained SPs — FP, IP, KAPP-specific procedures modified as recently as 2024-11.
- Utilities database holds the KAPP schema comparison logic (`USP_KAPP_Schema_details_Capture`, `USP_ZAB_KAPP_schema_compare`) — relevant to TECH-3563.
- DBA_VCC_AWS SPs are exclusively ETL cleanup routines — no reporting SPs.
