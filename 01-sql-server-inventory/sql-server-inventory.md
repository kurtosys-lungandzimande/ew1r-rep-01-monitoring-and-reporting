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
| DBA_VCC_AWS | 180,896 | SIMPLE | AWS infrastructure and KAPP API monitoring data |
| DBA_VCC_MEMSQL | 77,316 | SIMPLE | SingleStore/MemSQL monitoring data (jobs disabled) |
| KURTOSYS_BASELINE | 51,200 | SIMPLE | Performance baseline captures (connections, table sizes) |
| DBA_VCC_MYSQL | 25,918 | SIMPLE | MySQL and RDS monitoring data |
| DBA_VCC | 21,297 | SIMPLE | Core VCC monitoring framework data |
| DBA_VCC_COST | 5,120 | FULL | Cost tracking per entity/client (FULL recovery — critical) |
| DBA_VCC_ATLASSIAN | 2,048 | SIMPLE | Jira/Confluence integration data |
| Utilities | 185 | SIMPLE | DBA utility scripts and stored procedures |

**Total data size: ~363 GB**

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

| Job Name | Enabled | Schedule | Alert Target | Notes |
|---|---|---|---|---|
| BASELINE_CONNECTIONS | Yes | Sched1 | None | Captures connection baselines |
| BASELINE_TABLE_SIZES | Yes | SCHED1 | None | Captures table size baselines |
| DBA - AUDIT - KAPP_Schema_details_Capture | Yes | Everyday once | None | Captures KAPP schema details daily |
| DBA - Maintenance - CHECKDB | Yes | Daily @ 22:00 | dba@kurtosys.com | Ola Hallengren integrity checks |
| DBA - Maintenance - History Cleanup | Yes | Daily @ 00:00 | dba@kurtosys.com | Cleans up job/backup history |
| DBA - Maintenance - ReIndex and Statistics - Local | Yes | Weekly @ 01:00 | dba@kurtosys.com | Index maintenance |
| DBA - Maintenance - SQL Backup EW1P-OCT | Yes | Sched1 | None | Backs up RDS instance EW1P-OCT |
| DBA - Maintenance - SQL Backups DIFF | Yes | Daily @ 00:05 | dba@kurtosys.com | Differential backups |
| DBA - Maintenance - SQL Backups FULL | Yes | Weekly @ 00:05 | dba@kurtosys.com | Full backups |
| DBA - Maintenance - SQL Backups LOG | Yes | Hourly | dba@kurtosys.com | Log backups |
| DBA - MemSQL Range Stats Candidates | No | Every 8 hours | dba@kurtosys.com | Disabled — MemSQL stats |
| DBA - ObjectIDValidationReport | No | Weekly | dba@kurtosys.com | Disabled |
| DBA - Production Logon Report | No | Weekly | dba@kurtosys.com | Disabled |
| DBA - SSISStatusCheck | Yes | SCHED1 | dba@kurtosys.com | Checks SSIS package status |
| DBA - UtilitiesCleanupHistoryTables | No | Daily 11 PM | dba@kurtosys.com | Disabled |
| DBA_VCC_AWS_15MIN_CHECKS | Yes | Every 15 min | None | AWS resource checks every 15 min |
| DBA_VCC_AWS_DAILY_CHECKS | Yes | Daily | None | Daily AWS checks |
| DBA_VCC_AWS_WEEKLY_CHECKS | Yes | Weekly | None | Weekly AWS checks |
| DBA_VCC_DAILY_CHECKS | Yes | Daily | None | Core VCC daily checks |
| DBA_VCC_HOURLY_CHECKS | Yes | Hourly | None | Core VCC hourly checks |
| DBA_VCC_WEEKLY_CHECKS | Yes | Weekly | None | Core VCC weekly checks |
| DBA_VCC_COST_Entity_Count_Collection | Yes | SCHED1 | None | Cost data collection per entity |
| DBA_VCC_JIRA_MONTHEND_CHECKS | Yes | Monthly | None | Jira month-end integration |
| DBA_VCC_MEMSQL_AUDIT_BACKUP_INFO_DETAILED | No | SCHED1 | None | Disabled — MemSQL backup audit |
| DBA_VCC_MEMSQL_DAILY_CHECKS | No | SCHED1 | None | Disabled — MemSQL daily checks |
| DBA_VCC_MEMSQL_GLOBAL_STATUS_CAPTURE | No | Every minute | None | Disabled — was running every minute |
| DBA_VCC_MEMSQL_HOURLY_CHECKS | No | SCHED1 | None | Disabled |
| DBA_VCC_MEMSQL_MON_PING_STATS | No | SCHED1 | None | Disabled |
| DBA_VCC_MEMSQL_MON_SQL_STATUS | No | SCHED1 | None | Disabled |
| DBA_VCC_MEMSQL_WEEKLY_CHECKS | No | SCHED1 | None | Disabled |
| DBA_VCC_MYSQL_DAILY_CHECKS | Yes | Daily | None | MySQL/RDS daily checks |
| DBA_VCC_MYSQL_WEEKLY_CHECKS | Yes | Weekly | None | MySQL/RDS weekly checks |
| DBA_VCC_MYSQL_MON_PING_STATS | Yes | SCHED1 | None | MySQL ping monitoring |
| DBA_VCC_MYSQL_MON_SQL_STATUS | Yes | SCHED1 | None | MySQL status monitoring |
| DBA_VCC_MYSQL_MON_SQL_VERSION_CHECK | Yes | SCHED1 | None | MySQL version checks |
| DBA_VCC_MYSQL_AUDIT_BACKUP_INFO_DETAILED | Yes | SCHED1 | None | MySQL backup audit |
| DBA_VCC_MYSQL_AUDIT_DXM_CLIENT_DETAILED | Yes | Daily | None | DXM client audit via MySQL |
| DBA_VCC_MON_BASE_SERVER_MEMORY_CHECK | Yes | SCHED1 | None | Memory pressure monitoring |
| DBA_VCC_MON_CHECKS_SERV_DATA_COLLECT | Yes | SCHED1 | None | Server data collection |
| DBA_VCC_MON_CONNECTION_CHECK | Yes | SCHED1 | None | Connection monitoring |
| DBA_VCC_MON_Eventlog_CHECK | Yes | SCHED1 | None | Windows event log monitoring |
| DBA_VCC_MON_LOCAL_DRIVE_CHECK | Yes | SCHED1 | None | Disk space monitoring |
| DBA_VCC_MON_SQL_DAILY_BACKUPS_CHECK | Yes | Daily | None | Backup verification |
| DBA_VCC_MON_SQL_SERVER_INFO_CHECK | Yes | SCHED1 | None | SQL Server info collection |
| DBA_VCC_MON_VLF_COUNT_CHECK | Yes | Daily | None | VLF count monitoring |
| DBA_VCC_AUDIT_* (12 jobs) | Yes | SCHED1 | None | Full audit data collection suite |
| DBA_VCC_BASE_SERVER_MEMORY_PRESSURE_DETAILED | Yes | SCHED1 | None | Memory pressure detail |
| syspolicy_purge_history | Yes | System | None | System policy cleanup |

### Job Summary
| Category | Total | Enabled | Disabled |
|---|---|---|---|
| DBA Maintenance | 9 | 7 | 2 |
| VCC AWS Checks | 3 | 3 | 0 |
| VCC Core Checks | 3 | 3 | 0 |
| VCC Audit Collection | 12 | 12 | 0 |
| VCC MySQL Monitoring | 6 | 6 | 0 |
| VCC MemSQL Monitoring | 7 | 0 | 7 |
| VCC Server Monitoring | 8 | 8 | 0 |
| VCC Cost/Jira | 2 | 2 | 0 |
| Baseline/KAPP | 3 | 3 | 0 |
| System | 1 | 1 | 0 |
| **Total** | **54** | **45** | **9** |

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
| EW1 (eu-west-1) | ew1r-aggr-01/02/03/04/05 | ew1r-leaf-01-08, ew1r-leaf-11/12/14 | ew1r-dxm, ew1r-dxm-logging |
| EW2 (eu-west-2) | ew2p-aggr-01/02/03/04/10/11 | ew2p-leaf-01-06/21-24/51-56/61 | ew2p-dxm, ew2p-dxm-logging, ew2p-dxm-repl |
| UE1 (us-east-1) | ue1p-aggr-01/02/03/04 | ue1p-leaf-01/02/03/04/51/52/53/54 | ue1p-dxm, ue1p-dxm-logging, ue1p-dxm-repl |

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

**Total linked servers: 97**

---

## Open Items
- [ ] Confirm what SSIS packages are being checked by DBA - SSISStatusCheck
- [ ] Identify what reads from MON_ tables (Grafana datasource?)
- [ ] Confirm if EW1P-OCT RDS backup job is still needed
- [ ] Identify owner of DBA_VCC_COST data — who consumes cost reports?
- [ ] Confirm if MemSQL linked servers are still reachable or all stale
