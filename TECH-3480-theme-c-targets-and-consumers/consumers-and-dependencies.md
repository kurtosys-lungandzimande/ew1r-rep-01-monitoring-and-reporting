# Consumers and Dependencies — EW1R-REP-01

> Status: Consumers partially identified from query evidence. Stakeholder confirmation still needed for billing and client-facing use.

---

## Known Data Consumers

| Data | Consumer | Confidence | Notes |
|---|---|---|---|
| Grafana dashboards (74 total) | tashvir.babulal, yogeshwar.phull, rayhaan.suleyman | Confirmed | 3 active admins as of June 2026 |
| DBA_VCC_COST — Database Engineering Costs | DB engineering team | Confirmed | Dashboard JSON confirmed — last updated Oct 2024 |
| DBA_VCC_COST — Database Engineering Sprint Reporting | Engineering management | Confirmed | Dashboard JSON confirmed — last updated Mar 2024 |
| DBA_VCC_COST — KAPP Client Utilisation and Growth Report | Unknown — likely client-facing | ⚠️ High risk | Dashboard JSON confirmed — name suggests client use, needs confirmation |
| DBA_VCC_COST — AWS Cost Report Monthly | Unknown | Medium | Dashboard JSON confirmed — AWS data stale since Sept 2024 |
| DBA_VCC_MEMSQL — 14 dashboards | Unknown | Confirmed broken | All stale since May 2026 — jobs disabled |
| DBA_VCC_AWS — KAPP API query logs | KAPP engineering / platform team | High | 563M rows, collected every 30 min |
| Encore IIS logs / BNY IIS logs | Encore team / BNY integration team | Medium | Hourly collection — BNY named explicitly in job step |
| DBA_VCC_MYSQL — DXM client sizes | DXM platform team | Medium | Active daily collection |
| DBA_VCC_ATLASSIAN — Jira sprint data | Engineering management / delivery | Medium | Month-end Jira pull |
| Slack alerts (alerts-data-operations) | Unknown Slack channel members | Confirmed | KAPP client config and read query failure alerts |

---

## Alert Mechanisms

### SQL Server Alerts
17 SQL Server alerts defined (severity 19-25, IO errors 823-825) — all have `has_notification = 0`. No operator is notified when these fire. They are silent.

### SQL Agent Job Alerts

| Alert Category | Target | Channel |
|---|---|---|
| CHECKDB failures | dba@kurtosys.com | Email |
| Backup failures (FULL/DIFF/LOG) | dba@kurtosys.com | Email |
| Low disk space | dba@kurtosys.com | Email |
| Server restart required | dba@kurtosys.com | Email |
| Errorlog size alerts | dba@kurtosys.com | Email |
| VLF count report | dba@kurtosys.com | Email |
| Memory pressure | dba@kurtosys.com | Email |
| SSIS long-running packages | Slack | Channel unknown — needs confirmation |
| Most VCC monitoring jobs | None | No alert — data written to DB tables only |

> Critical gap: SQL Server severity alerts are all silent. If the server hits a fatal error, no one is automatically notified.

---

## DBA_VCC_COST — What It Tracks

Collection job `DBA_VCC_COST_Entity_Count_Collection` runs on schedule SCHED1. Last confirmed successful run: 29 June 2026 at 08:00. Database is on FULL recovery — the only database on this server set that way.

Collects 9 entity types per KAPP client across 5 environments:

| Entity Type | Table |
|---|---|
| Allocations | INFO_KAPP_Client_Allocations_Counts |
| Disclaimers & Commentaries | INFO_KAPP_Client_Disclaimers_Commentaries_Counts |
| Documents | INFO_KAPP_Client_Document_Counts |
| Entities | INFO_KAPP_Client_Entities_Counts |
| Historical Datasets | INFO_KAPP_Client_HistoricalDatasets_Counts |
| Snapshots | INFO_KAPP_Client_Snapshots_Counts |
| Statistics | INFO_KAPP_Client_Statstics_Counts |
| Time Series | INFO_KAPP_Client_TimeSeries_Counts |
| Users | INFO_KAPP_Client_Users_Counts |

Environments collected from:

| Code | Region | Environment |
|---|---|---|
| EW1-D | eu-west-1 | UK Dev |
| EW1-R | eu-west-1 | UK Release |
| EW2-P | eu-west-2 | UK Production |
| UE1-P | us-east-1 | US Production |
| EC1-P | eu-central-1 | EU Production |

19 stored procedures named `REP_MONTHEND_*` sit on top of the collection tables. These are called every month end to generate client reports — both summary (all clients) and per-client versions. Who calls them and whether they are client-facing is still open.

Confirmed by query 5.3 (run 2026-07-07) — all objects in DBA_VCC_COST:
```sql
SELECT name, type_desc, create_date, modify_date
FROM DBA_VCC_COST.sys.objects
WHERE type IN ('P', 'V', 'U')
ORDER BY type, name;
```

Evidence — full output (run 2026-07-09):
```
-- REP_MONTHEND reporting procedures (19 total)
REP_MONTHEND_CLIENT_ALLOCATIONS_CLIENT_REPORT          created 2023-01-06  modified 2023-01-06
REP_MONTHEND_CLIENT_ALLOCATIONS_REPORT                 created 2022-09-28  modified 2023-01-06
REP_MONTHEND_CLIENT_DISCLAIMERS_COMMENTARIES_CLIENT_REPORT  created 2023-01-06  modified 2023-01-06
REP_MONTHEND_CLIENT_DISCLAIMERS_COMMENTARIES_REPORT    created 2022-09-28  modified 2022-11-23
REP_MONTHEND_CLIENT_DOCUMENTS_CLIENT_REPORT            created 2023-01-06  modified 2023-01-06
REP_MONTHEND_CLIENT_DOCUMENTS_REPORT                   created 2022-09-28  modified 2022-11-23
REP_MONTHEND_CLIENT_ENTITY_REPORT                      created 2022-09-28  modified 2022-11-23
REP_MONTHEND_CLIENT_HISTORICALDATASETS_CLIENT_REPORT   created 2023-01-06  modified 2023-01-06
REP_MONTHEND_CLIENT_HISTORICALDATASETS_REPORT          created 2022-09-28  modified 2022-11-23
REP_MONTHEND_CLIENT_SNAPSHOTS_CLIENT_REPORT            created 2023-01-06  modified 2023-01-06
REP_MONTHEND_CLIENT_SNAPSHOTS_REPORT                   created 2022-09-29  modified 2022-11-23
REP_MONTHEND_CLIENT_STATSTICS_CLIENT_REPORT            created 2023-01-06  modified 2023-01-06
REP_MONTHEND_CLIENT_STATSTICS_REPORT                   created 2022-09-29  modified 2022-11-23
REP_MONTHEND_CLIENT_TIMESERIES_CLIENT_REPORT           created 2023-01-06  modified 2023-01-06
REP_MONTHEND_CLIENT_TIMESERIES_REPORT                  created 2022-09-29  modified 2022-11-23
REP_MONTHEND_CLIENT_TOP5_ALLOCATIONS_REPORT            created 2023-01-06  modified 2023-01-06
REP_MONTHEND_CLIENT_USER_COUNTS_REPORT                 created 2022-10-12  modified 2022-10-12
REP_MONTHEND_CLIENT_USER_REPORT                        created 2022-09-29  modified 2022-11-23
REP_MONTHEND_TOP5_CLIENTS_DATA_FOOTPRINT_REPORT        created 2023-01-06  modified 2023-01-06

-- SP_INFO collection procedures (9 total — these feed the INFO_KAPP_Client_* tables)
SP_INFO_KAPP_CLIENT_ALLOCATIONS_COUNTS                 created 2022-09-27
SP_INFO_KAPP_CLIENT_DISCLAIMERS_COMMENTARIES_COUNTS    created 2022-09-27
SP_INFO_KAPP_CLIENT_DOCUMENT_COUNTS                    created 2022-09-27
SP_INFO_KAPP_CLIENT_ENTITIES_COUNTS                    created 2022-09-27
SP_INFO_KAPP_CLIENT_HISTORICALDATASETS_COUNTS          created 2022-09-27
SP_INFO_KAPP_CLIENT_SNAPSHOTS_COUNTS                   created 2022-09-27
SP_INFO_KAPP_CLIENT_STATISTICS_COUNTS                  created 2022-09-27
SP_INFO_KAPP_CLIENT_TIMESERIES_COUNTS                  created 2022-09-27
SP_INFO_KAPP_CLIENT_USERS_COUNTS                       created 2022-09-27
```

Note: each REP_MONTHEND procedure has two versions — a summary report (all clients) and a per-client report (e.g. `REP_MONTHEND_CLIENT_ALLOCATIONS_REPORT` vs `REP_MONTHEND_CLIENT_ALLOCATIONS_CLIENT_REPORT`). All were last modified between Sep 2022 and Jan 2023 — built by donovan.vangraan, never touched since.

6 Grafana dashboards confirmed calling these procedures — confirmed by query 12.4 (run 2026-07-07), full dashboard JSON scan:
```sql
-- run via xp_cmdshell + Python against grafana.db
SELECT title, updated FROM dashboard
WHERE is_folder=0 AND data LIKE '%REP_MONTHEND%'
ORDER BY updated DESC;
```

Evidence — dashboards returned:
```
WPv2 Month End Reporting                    2024-06-20
Encore Month End Reporting                  2023-08-10
DXM Month End Reporting                     2023-08-10
InvestorPress Month End Reporting           2023-08-10
KAPP Month End Reporting                    2023-08-10
Other Services Month End Reporting (Draft)  2023-07-21
```

---

## DBA_VCC_MEMSQL — Data Freshness

All 7 collection jobs disabled since May 2026. Last run history:

| Job | Last Run | Last Outcome |
|---|---|---|
| DBA_VCC_MEMSQL_DAILY_CHECKS | 8 May 2026 | Failed |
| DBA_VCC_MEMSQL_HOURLY_CHECKS | 8 May 2026 | Succeeded |
| DBA_VCC_MEMSQL_MON_PING_STATS | 8 May 2026 | Succeeded |
| DBA_VCC_MEMSQL_MON_SQL_STATUS | 8 May 2026 | Succeeded |
| DBA_VCC_MEMSQL_AUDIT_BACKUP_INFO_DETAILED | 8 May 2026 | Succeeded |
| DBA_VCC_MEMSQL_WEEKLY_CHECKS | 3 May 2026 | Succeeded |

Table freshness:

| Table | Last Data | Row Count |
|---|---|---|
| INFO_ClientSizes_Sizes_FP (KAPP) | May 2026 | 2,903,660 |
| INFO_ClientSizes_Sizes_IP (InvestorPress) | May 2026 | 42,364 |
| ARC_INFO_ClientSizes_Sizes_FP (KAPP archive) | Feb 2026 | 33,293,391 |
| ARC_INFO_ClientSizes_Sizes_IP (IP archive) | Feb 2026 | 690,058 |
| INFO_AWS_DE_Entity_Cost (AWS costs) | Nov 2024 | 4,382 |

14 dashboards referencing DBA_VCC_MEMSQL confirmed by query 12.5 (run 2026-07-07):
```sql
-- run via xp_cmdshell + Python against grafana.db
SELECT title, updated FROM dashboard
WHERE is_folder=0 AND data LIKE '%DBA_VCC_MEMSQL%'
ORDER BY updated DESC;
```

6 dashboards calling REP_MONTHEND confirmed by query 12.4 — see DBA_VCC_COST section above.

All 20 of these dashboards are showing stale data. Do not re-enable jobs without understanding why DAILY_CHECKS failed on 8 May 2026.

---

## Infrastructure Dependencies

### Service Accounts

| Service | Account |
|---|---|
| SQL Server Engine | SHNONPRD\sqlsrv |
| SQL Server Agent | SHNONPRD\sqlagent |
| SQL Server Launchpad | NT Service\MSSQLLaunchpad |
| Linked server credentials | Unknown — check vault |
| AWS API access (Python) | Unknown — IAM role or key on server |

### Backup Storage

| Type | Location | Notes |
|---|---|---|
| Local staging | D:\SQL\Backup\ | Intermediate before S3 copy |
| S3 destination | ARN referenced in job — bucket name TBC | 30-day retention confirmed via S3 lifecycle rule |

### Network

| Name | Resolves To |
|---|---|
| EW1R-REP-01 | 10.72.8.216 |
| Grafana URL | https://ew1r-rep-01 — port 443 (HTTPS) |

### Services Running

| Service | Port | PID |
|---|---|---|
| Grafana | 443 | 3844 |
| SQL Server | 1433 | 3096 |
| Zabbix Agent | 10050 | 5700 |
| RDP | 3389 | 360 |
| WinRM | 5985 | 4 |

### Firewall Rules (needs network team confirmation)

| Direction | Source / Destination | Port | Purpose |
|---|---|---|---|
| Outbound | SingleStore nodes (109) | ODBC | MemSQL cluster queries |
| Outbound | MySQL/DXM/WPv2 nodes | 3306 | MySQL monitoring |
| Outbound | EW2P-MSSQL-01/02 | 1433 | SQL Server monitoring |
| Outbound | AWS APIs | 443 | Python API calls |
| Outbound | Jira | 443 | Sprint data collection |
| Outbound | S3 | 443 | Backup uploads |
| Inbound | Grafana clients | 443 | Dashboard access |
| Inbound | DBA team | 1433 | SQL Server management |

---

## Open Items

| # | Item | Who to Ask |
|---|---|---|
| 1 | Is KAPP Client Utilisation and Growth Report client-facing? | tashvir.babulal / rayhaan.suleyman |
| 2 | Who calls REP_MONTHEND_* procedures each month end? | tashvir.babulal / rayhaan.suleyman |
| 3 | Is DBA_VCC_COST used for client billing? | tashvir.babulal / rayhaan.suleyman |
| 4 | Who receives the Slack alerts from SSISStatusCheck? | DBA team / ops team |
| 5 | What IAM role/key does the Python AWS API caller use? | DevOps / cloud team |
| 6 | What S3 bucket do backups go to — bucket name/ARN? | DevOps / cloud team |
| 7 | Is ZabbixProdOld still active or can it be removed? | Infrastructure team |
| 8 | What does EW1R-TC resolve to — is it TeamCity? | Infrastructure team |
