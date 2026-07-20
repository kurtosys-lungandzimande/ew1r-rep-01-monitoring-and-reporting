# Consumers and Dependencies — EW1R-REP-01

> Status: Validated 2026-07-20 from live queries against EW1R-REP-01. All findings confirmed. Corrections applied — see validation notes inline.

---

## Known Data Consumers

| Data | Consumer | Confidence | Notes |
|---|---|---|---|
| Grafana dashboards (74 total) | tashvir.babulal, yogeshwar.phull, rayhaan.suleyman | Confirmed | 3 active admins as of June 2026 |
| DBA_VCC_COST — Database Engineering Costs | DB engineering team | Confirmed | Dashboard JSON confirmed — last updated Oct 2024 |
| DBA_VCC_COST — Database Engineering Sprint Reporting | Engineering management | Confirmed | Dashboard JSON confirmed — last updated Mar 2024 |
| DBA_VCC_COST — KAPP Client Utilisation and Growth Report | Client-facing — confirmed | ⚠️ Critical | LU_KAPP_ClientList contains **280** real institutional clients across EW2, UE1, EC1 — BlackRock, BNY Mellon, Aberdeen, Wellington, T. Rowe Price, Nordea, Jupiter, M&G, AXA IM, BMO, HSBC and others. This is billing data. |
| DBA_VCC_COST — AWS Cost Report Monthly | Unknown | Medium | Dashboard JSON confirmed — AWS data stale since Nov 2024 |
| DBA_VCC_COST — INFO_KAPP_Client_* tables | Unknown | ⚠️ High risk | All 9 collection tables stale since 4 May 2026 — job reports Succeeded but no data written, silent failure |
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

Collection job `DBA_VCC_COST_Entity_Count_Collection` runs on schedule SCHED1 every Sunday at 08:00. Service account: `SHNONPRD\sqlagent`. Database is on FULL recovery — the only database on this server set that way.

⚠️ The job has run every Sunday and reported Succeeded continuously — most recently **2026-07-20 at 08:00**. Despite this, all 9 collection tables remain frozen at **2026-05-04 08:00** — confirmed 11+ consecutive weeks of silent zero-row runs. The job succeeds because the SP_INFO procedures exit cleanly with no error when MEMSQL ping stats are stale. There is nothing to catch.

Collects 9 entity types per KAPP client across 5 environments.

Data freshness confirmed by query 14.2 (re-run 2026-07-20):

| Table | Last Collected | Row Count |
|---|---|---|
| INFO_KAPP_Client_Allocations_Counts | 2026-05-04 08:00:02 | 123,374 |
| INFO_KAPP_Client_Disclaimers_Commentaries_Counts | 2026-05-04 08:00:06 | 578,926 |
| INFO_KAPP_Client_Document_Counts | 2026-05-04 08:00:09 | 471,593 |
| INFO_KAPP_Client_Entities_Counts | 2026-05-04 08:00:11 | 145,047 |
| INFO_KAPP_Client_HistoricalDatasets_Counts | 2026-05-04 08:00:14 | 33,483 |
| INFO_KAPP_Client_Snapshots_Counts | 2026-05-04 08:00:16 | 286,584 |
| INFO_KAPP_Client_Statstics_Counts | 2026-05-04 08:00:18 | 134,707 |
| INFO_KAPP_Client_TimeSeries_Counts | 2026-05-04 08:00:20 | 120,269 |
| INFO_KAPP_Client_Users_Counts | 2026-05-04 08:00:39 | 14,811,776 |
| INFO_AWS_DE_Entity_Cost | 2024-11-01 ⚠️ Stale — 20+ months out of date | 4,382 |

⚠️ All 9 collection tables confirmed frozen at 4 May 2026 — re-validated 2026-07-20. Row counts unchanged. The job has run every Sunday since then and reported Succeeded — 11+ consecutive silent zero-row runs.

Root cause confirmed by SP_INFO_KAPP_CLIENT_ALLOCATIONS_COUNTS definition (run 2026-07-09):

```sql
-- The procedure only collects from nodes that appear in DBA_VCC_MEMSQL ping stats
-- within the last 40 minutes AND have SQL status = 1 within the last 40 minutes
INSERT INTO @SERVERNAMES
SELECT InstanceName
FROM DBA_VCC_MEMSQL..LU_Serverlist
WHERE Role = 'Master Aggregator'
  AND SERVERNAME IN (
      SELECT SERVERNAME FROM DBA_VCC_MEMSQL.dbo.BAS_Ping_Stat
      WHERE DATEDIFF(MINUTE, DATECHECKED, GETDATE()) < 40
      AND [Status] = 1)
  AND INSTANCENAME IN (
      SELECT SERVERNAME FROM DBA_VCC_MEMSQL.dbo.BAS_SQL_Status
      WHERE DATEDIFF(MINUTE, DATECHECKED, GETDATE()) < 40
      AND [Status] = 1)
  AND SERVERNAME IN (
      SELECT EntityName COLLATE Latin1_General_CI_AS
      FROM [DBA_VCC_COST].[dbo].[LU_EntityList]
      WHERE Application = 'KAPP')
```

The procedure checks `DBA_VCC_MEMSQL.dbo.BAS_Ping_Stat` and `DBA_VCC_MEMSQL.dbo.BAS_SQL_Status` for nodes that were active within the last 40 minutes. The MEMSQL jobs that write to those tables were disabled on 4 May 2026. From that point on, no node ever passes the 40-minute freshness check — `@SERVERNAMES` is always empty, the WHILE loop never executes, nothing is inserted, and the procedure exits cleanly with no error.

This is not a CATCH block swallowing an error — there is no error to catch. The procedure runs successfully and writes zero rows. The job reports Succeeded because it did succeed — it just had nothing to do.

All 9 SP_INFO procedures follow the same pattern. Every one of them depends on DBA_VCC_MEMSQL ping stats being fresh. When the MEMSQL jobs were disabled, the entire DBA_VCC_COST collection pipeline silently stopped with it.

This means the DBA_VCC_COST data that the KAPP Client Utilisation and Growth Report dashboard is reading is also stale since 4 May 2026 — not just the MEMSQL dashboards. Both databases stopped collecting on the same day for the same root cause.

Client list confirmed by query 5.2 (run 2026-07-09) — `SELECT * FROM DBA_VCC_COST.dbo.LU_KAPP_ClientList ORDER BY ClientName`:

| Client | Region | Account Group | Notes |
|---|---|---|---|
| Aberdeen / abrdn | EW2 | Aberdeen | Multiple prod/staging/dev entries |
| AXA IM | EC1 | AXA IM | Dev/staging/prod |
| BlackRock | UE1 | BlackRock | Prod/staging/dev/index services |
| BlueBay | EW2 | Blue Bay | Prod/staging/FundTools staging |
| BMO / BMO GAM / BMO NL | EW2/UE1/EC1 | BMO | Multiple regions and entities |
| BNY Mellon / BNY Dreyfus | EW2/UE1 | BNY | Multiple prod/staging/dev entries |
| Boston Partners | UE1 | Boston Partners | Prod/staging/dev |
| CTI / Threadneedle | EW2 | Threadneedle | Prod/staging/MIGR/AOV entries |
| FedHermes | EW2 | Hermes | Factsheets and web prod/staging |
| HSBC Asset Management | EW2 | Potential Client | Not yet live |
| ICMARC | UE1 | ICMARC | Prod/staging/dev/release |
| Jupiter / OMGI / Merian | EW2 | Jupiter | Multiple prod/staging entries |
| M&G Investments | EW2 | M&G Investments | Prod/staging/dev/European tools |
| Nordea Asset Management | EW2/EC1 | Nordea | Multiple regions |
| OP Cooperative | EW2/EC1 | OP Cooperative | Prod/staging/DXM |
| Osmosis | EW2 | Osmosis | Prod/staging/dev/P2 |
| PRIMECAP | UE1 | Primecap | Prod/staging/testing |
| RWC Partners | EW2 | RWC | Prod/staging/dev |
| SALI | EW2/UE1 | Sali | Prod/staging/dev/portal entries |
| Sands Capital | UE1 | Sands Capital | Prod/staging |
| Security Benefit | UE1 | Security Benefit | Prod/staging/dev |
| T. Rowe Price | EW2 | T. Rowe Price | Prod/staging/data API |
| TDAM | UE1 | TDAM | Prod/staging/dev |
| Wellington | EW2 | Wellington | Prod/staging/dev/WMF global FS |
| Ziegler | EW2/UE1 | Ziegler | Prod/staging/dev |
| C&D Investments | EW2 | C&D (Terminated) | ⚠️ Marked Terminated — still in list |
| AXAIM, Brown Advisory, CCLA, HSBC, Brunel | EW2 | Potential Client | ⚠️ Not yet live — POC/demo entries |
| Kurtosys internal | EW2/UE1/EC1 | Kurtosys | Internal demo, sales, support, monitoring entries |

⚠️ This confirms DBA_VCC_COST is tracking entity counts for real production clients across three regions. This is billing data. Decommissioning this server without a confirmed replacement directly impacts client invoicing.

Entity registry confirmed by query (run 2026-07-09) — `SELECT * FROM DBA_VCC_COST.dbo.LU_EntityList ORDER BY Application, Enviroment, EntityName`:

| Application | Account | Environments | Nodes | Notes |
|---|---|---|---|---|
| KAPP | KurtosysApp_Prod / Non-Prod | Production (EC1P, EW2P, UE1P), Release (EW1R), Dev (EW1D) | Aggregators, leaves, admin, mops, EFS, backups | Core KAPP platform |
| DXM | KurtosysApp_Prod / Non-Prod | Production (EC1P, EW2P, UE1P), Release (EW1R), Dev (EW1D) | DXM nodes, logging, replication, jump, backups | Document generation |
| InvestorPress | InvestorPress_Encore_Prod / Non-Prod | Production (EW2P), Release (EW1R), Dev (EW1D) | Aggregators, leaves, admin, mops, EFS, IP RDS | |
| Encore | InvestorPress_Encore_Prod / Non-Prod | Production (EW2P), Release (EW1R), Dev (EW1D) | MSSQL-01/02/03, backups, license exemption node | |
| WPv2 | Wordpress_V2_Prod / Non-Prod | Production (EW2P, UE1P), Release (EW2R, UE1R) | WPV2 nodes, backups | ⚠️ Decommissioned — entries stale. Includes `EW2P-WPV2-TEMP-ABDUL` — temp node named after a person, never cleaned up |
| Marketing | Marketing (232173278818) | Production (EW2P) | EW2P-MARKETING-DB, EW2P-JUMP-01, backup | ⚠️ EW2P-MARKETING-DB Not Online |
| NiFi | Shared_Services_Prod | Production (EW1P) | EW1P-NIFIREG-01, backup | |
| TeamCity | Shared_Services_Prod / Non-Prod | Production (EW1P), Release (EW1R) | EW1P-GIT-01/02, EW1P-JUMP-01, EW1R-TC, EW1R-JUMP-01/02 | EW1R-TC confirmed TeamCity |
| Octa | Shared_Services_Non-Prod | Production (EW1P) | EW1P-OCT, backups. Also `KSYS-EW1P-OCT-DBBACKUP2` under Sandbox account 598752988079 | |
| Reporting | Shared_Services_Non-Prod | Release (EW1R) | EW1R-REP-01 | This server tracks its own costs |
| Zabbix | Shared_Services_Non-Prod | Release (EW1R) | EW1R-ZABBIX-02 | |
| REP | Monitoring_Alerting | Production (EW1P) | EW1P-MON-01 | |

⚠️ Data quality issues in LU_EntityList confirmed 2026-07-20:
- `Enviroment` column name is a typo — never corrected since 2022
- Mixed case values: `RELEASE` vs `Release` vs `Development` in same column
- Region has leading spaces on some EW1R rows — `EW1R-LEAF-01/02/03/04` show Region = ` EW` (space + EW, truncated) instead of `EW1`
- `EW1R-LEAF-04` appears twice under KAPP Release — once with Region ` EW` and once with `EW1` — duplicate row with different region values
- `UE1P-WPV2` appears under two different accounts — `Wordpress_V2_Prod (850398446702)` and `Networking (896537139917)` — duplicate entry under different account owners
- `DELETE` row exists — `InvestorPress_Encore_Non-Prod`, EntityName = `DELETE`, Application = NULL — orphan row never cleaned up
- `EW1R-AGGR-31` listed under InvestorPress Release — added 2023-07-06, after InvestorPress was decommissioned
- `EW1P-GIT-01` classified as Application=`GIT`, `EW1P-GIT-02` classified as Application=`TeamCity` — inconsistent classification of the same infrastructure

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

| Procedure | Type | Created | Last Modified |
|---|---|---|---|
| REP_MONTHEND_CLIENT_ALLOCATIONS_CLIENT_REPORT | Reporting | 2023-01-06 | 2023-01-06 |
| REP_MONTHEND_CLIENT_ALLOCATIONS_REPORT | Reporting | 2022-09-28 | 2023-01-06 |
| REP_MONTHEND_CLIENT_DISCLAIMERS_COMMENTARIES_CLIENT_REPORT | Reporting | 2023-01-06 | 2023-01-06 |
| REP_MONTHEND_CLIENT_DISCLAIMERS_COMMENTARIES_REPORT | Reporting | 2022-09-28 | 2022-11-23 |
| REP_MONTHEND_CLIENT_DOCUMENTS_CLIENT_REPORT | Reporting | 2023-01-06 | 2023-01-06 |
| REP_MONTHEND_CLIENT_DOCUMENTS_REPORT | Reporting | 2022-09-28 | 2022-11-23 |
| REP_MONTHEND_CLIENT_ENTITY_REPORT | Reporting | 2022-09-28 | 2022-11-23 |
| REP_MONTHEND_CLIENT_HISTORICALDATASETS_CLIENT_REPORT | Reporting | 2023-01-06 | 2023-01-06 |
| REP_MONTHEND_CLIENT_HISTORICALDATASETS_REPORT | Reporting | 2022-09-28 | 2022-11-23 |
| REP_MONTHEND_CLIENT_SNAPSHOTS_CLIENT_REPORT | Reporting | 2023-01-06 | 2023-01-06 |
| REP_MONTHEND_CLIENT_SNAPSHOTS_REPORT | Reporting | 2022-09-29 | 2022-11-23 |
| REP_MONTHEND_CLIENT_STATSTICS_CLIENT_REPORT | Reporting | 2023-01-06 | 2023-01-06 |
| REP_MONTHEND_CLIENT_STATSTICS_REPORT | Reporting | 2022-09-29 | 2022-11-23 |
| REP_MONTHEND_CLIENT_TIMESERIES_CLIENT_REPORT | Reporting | 2023-01-06 | 2023-01-06 |
| REP_MONTHEND_CLIENT_TIMESERIES_REPORT | Reporting | 2022-09-29 | 2022-11-23 |
| REP_MONTHEND_CLIENT_TOP5_ALLOCATIONS_REPORT | Reporting | 2023-01-06 | 2023-01-06 |
| REP_MONTHEND_CLIENT_USER_COUNTS_REPORT | Reporting | 2022-10-12 | 2022-10-12 |
| REP_MONTHEND_CLIENT_USER_REPORT | Reporting | 2022-09-29 | 2022-11-23 |
| REP_MONTHEND_TOP5_CLIENTS_DATA_FOOTPRINT_REPORT | Reporting | 2023-01-06 | 2023-01-06 |
| SP_INFO_KAPP_CLIENT_ALLOCATIONS_COUNTS | Collection | 2022-09-27 | 2022-09-27 |
| SP_INFO_KAPP_CLIENT_DISCLAIMERS_COMMENTARIES_COUNTS | Collection | 2022-09-27 | 2022-09-27 |
| SP_INFO_KAPP_CLIENT_DOCUMENT_COUNTS | Collection | 2022-09-27 | 2022-09-27 |
| SP_INFO_KAPP_CLIENT_ENTITIES_COUNTS | Collection | 2022-09-27 | 2022-09-27 |
| SP_INFO_KAPP_CLIENT_HISTORICALDATASETS_COUNTS | Collection | 2022-09-27 | 2022-09-27 |
| SP_INFO_KAPP_CLIENT_SNAPSHOTS_COUNTS | Collection | 2022-09-27 | 2022-09-27 |
| SP_INFO_KAPP_CLIENT_STATISTICS_COUNTS | Collection | 2022-09-27 | 2022-09-27 |
| SP_INFO_KAPP_CLIENT_TIMESERIES_COUNTS | Collection | 2022-09-27 | 2022-09-27 |
| SP_INFO_KAPP_CLIENT_USERS_COUNTS | Collection | 2022-09-27 | 2022-09-27 |

Note: each REP_MONTHEND procedure has two versions — a summary report (all clients) and a per-client report (e.g. `REP_MONTHEND_CLIENT_ALLOCATIONS_REPORT` vs `REP_MONTHEND_CLIENT_ALLOCATIONS_CLIENT_REPORT`). All were last modified between Sep 2022 and Jan 2023 — built by donovan.vangraan, never touched since.

6 Grafana dashboards confirmed calling these procedures — confirmed by query 12.4 (run 2026-07-07), full dashboard JSON scan:
```sql
-- run via xp_cmdshell + Python against grafana.db
SELECT title, updated FROM dashboard
WHERE is_folder=0 AND data LIKE '%REP_MONTHEND%'
ORDER BY updated DESC;
```

Evidence — dashboards returned:

| Dashboard | Last Updated |
|---|---|
| WPv2 Month End Reporting | 2024-06-20 |
| Encore Month End Reporting | 2023-08-10 |
| DXM Month End Reporting | 2023-08-10 |
| InvestorPress Month End Reporting | 2023-08-10 |
| KAPP Month End Reporting | 2023-08-10 |
| Other Services Month End Reporting (Draft) | 2023-07-21 |

---

### DBA_VCC_MEMSQL — REP_MONTHEND procedures

A second set of REP_MONTHEND procedures exists in DBA_VCC_MEMSQL — confirmed by query 6.2 (run 2026-07-09):
```sql
SELECT name, type_desc, create_date, modify_date
FROM DBA_VCC_MEMSQL.sys.objects
WHERE type = 'P' AND name LIKE '%MONTHEND%'
ORDER BY name;
```

Evidence — full output (run 2026-07-09):

| Procedure | Created | Last Modified | Notes |
|---|---|---|---|
| REP_MONTHEND_CLIENT_NUMBER_REPORT | 2023-07-04 | 2024-01-22 | Most recently modified |
| REP_MONTHEND_CLIENTGROWTH_COST_ENV_FOOTPRINT_REPORT | 2023-07-04 | 2023-10-13 | |
| REP_MONTHEND_CLIENTGROWTH_COST_REPORT | 2023-07-05 | 2023-07-05 | |
| REP_MONTHEND_CLIENTGROWTH_COST_TOP5_REPORT | 2023-07-05 | 2024-01-22 | Most recently modified |
| REP_MONTHEND_CLINTGROWTH_COST_ENV_FOOTPRINT_REPORT | 2022-07-05 | 2023-08-10 | ⚠️ CLINT typo — old version |
| REP_MONTHEND_CLINTGROWTH_COST_REPORT | 2022-06-21 | 2022-06-21 | ⚠️ CLINT typo — old version |
| REP_MONTHEND_CLINTGROWTH_COST_TOP5_REPORT | 2022-07-05 | 2023-08-10 | ⚠️ CLINT typo — old version |
| REP_MONTHEND_IP_BACKUP_REPORT | 2022-07-06 | 2023-08-10 | InvestorPress backups |
| REP_MONTHEND_IP_CLINTGROWTH_COST_REPORT | 2022-06-21 | 2023-01-05 | ⚠️ CLINT typo — old version |
| REP_MONTHEND_KAPP_BACKUP_REPORT | 2022-07-06 | 2023-08-10 | KAPP backups |
| REP_MONTHEND_KAPP_CLINTGROWTH_COST_REPORT | 2022-06-21 | 2022-06-21 | ⚠️ CLINT typo — old version |
| REP_MONTHEND_KAPP_LOADER_REPORT | 2022-07-05 | 2023-08-10 | |
| REP_MONTHEND_KAPP_SNAPSHOTS_TOP5_REPORT | 2022-07-05 | 2023-08-10 | |
| REP_MONTHEND_MAXDB_SERVER_STATUS_REPORT | 2017-12-13 | 2017-12-13 | ⚠️ Predates VCC framework — leftover |

Note: `REP_MONTHEND_MAXDB_SERVER_STATUS_REPORT` was created in 2017 and never modified — predates the VCC framework, likely a leftover from a previous monitoring system. `REP_MONTHEND_CLIENT_NUMBER_REPORT` and `REP_MONTHEND_CLIENTGROWTH_COST_TOP5_REPORT` were last modified January 2024 — the most recently touched procedures in this database, suggesting someone was still actively working on these reports 6 months before donovan.vangraan went inactive.

Note also the typo: `CLINTGROWTH` vs `CLIENTGROWTH` — both variants exist. The older procedures (2022) use `CLINT`, the newer ones (2023) corrected it to `CLIENT`. Both sets are still present — the old ones were never cleaned up.

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

Table freshness confirmed by query 6.1 (re-run 2026-07-20):

| Table | Last Data | Row Count |
|---|---|---|
| INFO_ClientSizes_Sizes_FP (KAPP) | 2026-05-07 06:13:50 | 2,903,660 |
| INFO_ClientSizes_Sizes_IP (InvestorPress) | 2026-05-01 06:29:36 | 42,364 |
| ARC_INFO_ClientSizes_Sizes_FP (KAPP archive) | 2026-02-01 06:18:53 | 33,293,391 |
| ARC_INFO_ClientSizes_Sizes_IP (IP archive) | 2026-02-01 06:33:06 | 690,058 |

⚠️ Correction from previous documentation: KAPP and InvestorPress data did not stop on the same day. InvestorPress data stopped **2026-05-01**, KAPP data stopped **2026-05-07** — 6 days later. The MEMSQL jobs were disabled between 2026-05-07 and 2026-05-08 (last job run confirmed 2026-05-08 from job history).

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
| SQL Server Engine | AD domain account — contact DBA team |
| SQL Server Agent | AD domain account — contact DBA team |
| SQL Server Launchpad | NT Service account |
| Linked server credentials | Unknown — check vault |
| AWS API access (Python) | Unknown — IAM role or key on server |

### Backup Storage

| Type | Location | Notes |
|---|---|---|
| Local staging | D:\SQL\Backup\ | Intermediate before S3 copy |
| S3 destination (local backups) | `ksys-ew1r-db-backups` — path `Backups/Reporting/EW1R-REP-01/` | AWS CLI s3 sync via xp_cmdshell. ⚠️ No encryption specified. Retention TBC — check S3 lifecycle rule on bucket. |
| S3 destination (EW1P-OCT RDS) | `ksys-ew1p-oct-dbbackup` — path `backup/octopus_db_<date>.bak` | rds_backup_database. ⚠️ KMS key NULL — unencrypted at rest. Retention TBC. |

### Network

| Name | Resolves To |
|---|---|
| EW1R-REP-01 | 10.72.8.216 |
| Grafana URL | https://ew1r-rep-01 — port 443 (HTTPS) |

### Services Running

Confirmed from netstat (re-run 2026-07-20) — all PIDs unchanged since original discovery:

| Service | Port | PID |
|---|---|---|
| Grafana | 443 | 3844 |
| SQL Server | 1433 | 3096 |
| Zabbix Agent | 10050 | 5700 |
| RDP | 3389 | 360 |
| WinRM | 5985 | 4 |
| SQL Server Browser | 1434 (loopback) | 3096 |
| Unknown | 59563 (loopback) | 9148 | ⚠️ Not previously documented — purpose unknown |}

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
| 1 | ~~Is KAPP Client Utilisation and Growth Report client-facing?~~ | **Closed** — confirmed client-facing. LU_KAPP_ClientList contains **280** real institutional clients (BlackRock, BNY Mellon, Aberdeen, Wellington, T. Rowe Price, Nordea and others). This is billing data. |
| 2 | ~~Is DBA_VCC_COST used for client billing?~~ | **Closed** — confirmed. 280 clients tracked. Collection silently stale since 4 May 2026 — job runs every Sunday and reports Succeeded but writes zero rows. Re-validated 2026-07-20. |
| 3 | Who calls REP_MONTHEND_* procedures each month end? | tashvir.babulal / rayhaan.suleyman |
| 4 | Who receives the Slack alerts from SSISStatusCheck? | DBA team / ops team |
| 5 | What IAM role/key does the Python AWS API caller use? | DevOps / cloud team |
| 6 | What S3 bucket do backups go to — bucket name/ARN? | DevOps / cloud team | **Closed** — `ksys-ew1r-db-backups` (local backups) and `ksys-ew1p-oct-dbbackup` (EW1P-OCT RDS). ⚠️ Retention still TBC — check S3 lifecycle rules on both buckets. ⚠️ EW1P-OCT backup has KMS key NULL — unencrypted at rest. ⚠️ Local backups use AWS CLI s3 sync via xp_cmdshell — no encryption specified in sync command. |
| 7 | Is ZabbixProdOld still active or can it be removed? | Infrastructure team |
| 8 | ~~What does EW1R-TC resolve to — is it TeamCity?~~ | **Closed** — confirmed TeamCity. EW1R-TC appears in LU_EntityList under Shared_Services_Non-Prod, Application=TeamCity, Release environment, EW1 region. |
