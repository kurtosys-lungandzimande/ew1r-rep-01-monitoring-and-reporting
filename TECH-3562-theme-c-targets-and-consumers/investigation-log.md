# TECH-3562 — Theme C: Targets & Consumers — Investigation Log

Scope: External targets, consumers, service accounts, firewall rules, dependencies.
Each entry has the question, the query, the evidence, and the finding.

> Status: External targets mapped — 109 linked servers inventoried, 11 confirmed stale. DBA_VCC_COST confirmed client billing data — 280 real institutional clients tracked. All collection tables stale since 4 May 2026. Full detail in consumers-and-dependencies.md and external-targets.md.

---

## 2026-07-06 — External targets: confirmed reachable vs confirmed stale

**Question:** Which external targets is this server connecting to and which are still alive?

**Method:** Job history errors from sysjobhistory and linked server list from sys.servers.
Full queries in TECH-3535-planning-and-discovery/discovery-queries.sql — Sections 4 and 11.

**Evidence — confirmed reachable:**

| Server | Type | Location | Status |
|---|---|---|---|
| EW2P-MSSQL-01 | SQL Server | Production eu-west-2 | Reachable — jobs succeed daily |
| EW2P-MSSQL-02 | SQL Server | Production eu-west-2 | Reachable — jobs succeed daily |
| EW1P-OCT RDS | SQL Server | Production eu-west-1 | Reachable — backup job succeeds daily |
| SingleStore aggr nodes | ODBC | eu-west-1/2, us-east-1 | Majority reachable |
| AWS CloudWatch | Python API | eu-west-2 | Reachable — 15-min job running |
| AWS S3 | Python API | eu-west-2 | Reachable — daily job running |
| Zabbix (NonProd/Prod) | MySQL | Internal | Reachable — Grafana datasources active |

**Evidence — confirmed stale / unreachable:**

| Server | Type | Status |
|---|---|---|
| ew2p-wpv2 | MySQL | ⚠️ Decommissioned — DNS gone eu-west-2 |
| ew2r-wpv2 | MySQL | ⚠️ Decommissioned — DNS gone eu-west-2 |
| ue1p-wpv2 | MySQL | ⚠️ Decommissioned — DNS gone us-east-1 |
| ue1r-wpv2 | MySQL | ⚠️ Decommissioned — DNS gone us-east-1 |
| ew1d-aggr-05 | SingleStore | Not online |
| ew1d-aggr-15 | SingleStore | Not online |
| ew1r-aggr-03.gen-rel | SingleStore | ODBC misconfigured + unreachable |
| ew1r-aggr-05.gen-rel | SingleStore | Can't connect (111) |
| ew2p-aggr-01.gen-prd | SingleStore | Can't connect (111) |
| ew2p-aggr-02.gen-prd | SingleStore | Can't connect (111) |
| EW2P-MARKETING-DB | Unknown | Not online — owner unknown at time of discovery |

**Finding:** 11 confirmed stale targets out of 109 linked servers. Full reachability audit across all 109 still needed. WPv2 cleanup is urgent — jobs failing daily. gen-rel and gen-prd nodes need platform team confirmation before removal.

---

## 2026-07-07 — Grafana dashboard consumer mapping confirmed from JSON scan

**Question:** Which databases do Grafana dashboards read from — confirmed without stakeholder input?

**Method:** Full dashboard JSON scan via xp_cmdshell + Python against grafana.db.
Full queries in TECH-3535-planning-and-discovery/discovery-queries.sql — Sections 12.3, 12.4, 12.5.

**Evidence — dashboards reading from DBA_VCC_COST (query 12.3):**

| Dashboard | Last Updated | Notes |
|---|---|---|
| Database Engineering Costs | 2024-10-15 | Internal |
| Database Engineering Sprint Reporting | 2024-03-08 | Internal |
| KAPP Client Utilisation and Growth Report | 2024-02-22 | ⚠️ Name suggests client-facing |
| AWS Cost Report Monthly | 2023-10-06 | Internal — AWS data stale since Sept 2024 |

**Evidence — dashboards calling REP_MONTHEND procedures (query 12.4):**

| Dashboard | Last Updated | Notes |
|---|---|---|
| WPv2 Month End Reporting | 2024-06-20 | No dedicated job — reads DBA_VCC_MEMSQL directly |
| Encore Month End Reporting | 2023-08-10 | No dedicated job — reads DBA_VCC_MEMSQL directly |
| DXM Month End Reporting | 2023-08-10 | No dedicated job — reads DBA_VCC_MEMSQL directly |
| InvestorPress Month End Reporting | 2023-08-10 | No dedicated job — reads DBA_VCC_MEMSQL directly |
| KAPP Month End Reporting | 2023-08-10 | No dedicated job — reads DBA_VCC_MEMSQL directly |
| Other Services Month End Reporting (Draft) | 2023-07-21 | No dedicated job — reads DBA_VCC_MEMSQL directly |

**Finding:** DBA_VCC_COST confirmed active Grafana datasource. 6 month-end dashboards have no independent data pipeline — they depend entirely on DBA_VCC_MEMSQL which has been disabled since May 2026. Consumer confirmation escalated to tashvir.babulal and rayhaan.suleyman.

---

## 2026-07-09 — DBA_VCC_COST confirmed client billing data

**Question:** Is DBA_VCC_COST used for client billing or internal reporting only?

**Query (query 14.3):**
```sql
SELECT * FROM DBA_VCC_COST.dbo.LU_KAPP_ClientList ORDER BY ClientName;
```

**Evidence:**

| Client | Region | Account Group | Notes |
|---|---|---|---|
| Aberdeen / abrdn | EW2 | Aberdeen | Multiple prod/staging/dev entries |
| AXA IM | EC1 | AXA IM | Dev/staging/prod |
| BlackRock | UE1 | BlackRock | Prod/staging/dev/index services |
| BlueBay | EW2 | Blue Bay | Prod/staging |
| BMO / BMO GAM / BMO NL | EW2/UE1/EC1 | BMO | Multiple regions |
| BNY Mellon / BNY Dreyfus | EW2/UE1 | BNY | Multiple prod/staging/dev entries |
| Boston Partners | UE1 | Boston Partners | Prod/staging/dev |
| CTI / Threadneedle | EW2 | Threadneedle | Prod/staging/MIGR/AOV |
| FedHermes | EW2 | Hermes | Factsheets and web prod/staging |
| ICMARC | UE1 | ICMARC | Prod/staging/dev/release |
| Jupiter / OMGI / Merian | EW2 | Jupiter | Multiple prod/staging entries |
| M&G Investments | EW2 | M&G Investments | Prod/staging/dev/European tools |
| Nordea Asset Management | EW2/EC1 | Nordea | Multiple regions |
| OP Cooperative | EW2/EC1 | OP Cooperative | Prod/staging/DXM |
| Osmosis | EW2 | Osmosis | Prod/staging/dev/P2 |
| PRIMECAP | UE1 | Primecap | Prod/staging/testing |
| RWC Partners | EW2 | RWC | Prod/staging/dev |
| SALI | EW2/UE1 | Sali | Prod/staging/dev/portal |
| Sands Capital | UE1 | Sands Capital | Prod/staging |
| Security Benefit | UE1 | Security Benefit | Prod/staging/dev |
| T. Rowe Price | EW2 | T. Rowe Price | Prod/staging/data API |
| TDAM | UE1 | TDAM | Prod/staging/dev |
| Wellington | EW2 | Wellington | Prod/staging/dev/WMF global FS |
| Ziegler | EW2/UE1 | Ziegler | Prod/staging/dev |
| C&D Investments | EW2 | C&D (Terminated) | ⚠️ Marked Terminated — still in list |

**Finding:** 200+ real institutional clients confirmed across EW2, UE1, EC1 — COUNT(*) = 280 confirmed 2026-07-20. This is client billing data. Decommissioning this server without a confirmed replacement directly impacts client invoicing. Q2 and Q10 closed.

---

## 2026-07-09 — DBA_VCC_COST collection tables stale since 4 May 2026 — root cause confirmed

**Question:** Is the DBA_VCC_COST collection job actually writing data and why is it stale?

**Query (query 14.2):**
```sql
SELECT 'INFO_KAPP_Client_Allocations_Counts' AS table_name, MAX(DateChecked) AS last_collected, COUNT(*) AS rows FROM DBA_VCC_COST.dbo.INFO_KAPP_Client_Allocations_Counts
UNION ALL SELECT 'INFO_KAPP_Client_Disclaimers_Commentaries_Counts', MAX(DateChecked), COUNT(*) FROM DBA_VCC_COST.dbo.INFO_KAPP_Client_Disclaimers_Commentaries_Counts
UNION ALL SELECT 'INFO_KAPP_Client_Document_Counts', MAX(DateChecked), COUNT(*) FROM DBA_VCC_COST.dbo.INFO_KAPP_Client_Document_Counts
UNION ALL SELECT 'INFO_KAPP_Client_Entities_Counts', MAX(DateChecked), COUNT(*) FROM DBA_VCC_COST.dbo.INFO_KAPP_Client_Entities_Counts
UNION ALL SELECT 'INFO_KAPP_Client_HistoricalDatasets_Counts', MAX(DateChecked), COUNT(*) FROM DBA_VCC_COST.dbo.INFO_KAPP_Client_HistoricalDatasets_Counts
UNION ALL SELECT 'INFO_KAPP_Client_Snapshots_Counts', MAX(DateChecked), COUNT(*) FROM DBA_VCC_COST.dbo.INFO_KAPP_Client_Snapshots_Counts
UNION ALL SELECT 'INFO_KAPP_Client_Statstics_Counts', MAX(DateChecked), COUNT(*) FROM DBA_VCC_COST.dbo.INFO_KAPP_Client_Statstics_Counts
UNION ALL SELECT 'INFO_KAPP_Client_TimeSeries_Counts', MAX(DateChecked), COUNT(*) FROM DBA_VCC_COST.dbo.INFO_KAPP_Client_TimeSeries_Counts
UNION ALL SELECT 'INFO_KAPP_Client_Users_Counts', MAX(DateChecked), COUNT(*) FROM DBA_VCC_COST.dbo.INFO_KAPP_Client_Users_Counts
UNION ALL SELECT 'INFO_AWS_DE_Entity_Cost (STALE)', MAX(Period), COUNT(*) FROM DBA_VCC_COST.dbo.INFO_AWS_DE_Entity_Cost;
```

**Evidence:**

| Table | Last Collected | Row Count |
|---|---|---|
| INFO_KAPP_Client_Allocations_Counts | 2026-05-04 08:00 | 123,374 |
| INFO_KAPP_Client_Disclaimers_Commentaries_Counts | 2026-05-04 08:00 | 578,926 |
| INFO_KAPP_Client_Document_Counts | 2026-05-04 08:00 | 471,593 |
| INFO_KAPP_Client_Entities_Counts | 2026-05-04 08:00 | 145,047 |
| INFO_KAPP_Client_HistoricalDatasets_Counts | 2026-05-04 08:00 | 33,483 |
| INFO_KAPP_Client_Snapshots_Counts | 2026-05-04 08:00 | 286,584 |
| INFO_KAPP_Client_Statstics_Counts | 2026-05-04 08:00 | 134,707 |
| INFO_KAPP_Client_TimeSeries_Counts | 2026-05-04 08:00 | 120,269 |
| INFO_KAPP_Client_Users_Counts | 2026-05-04 08:00 | 14,811,776 |
| INFO_AWS_DE_Entity_Cost | 2024-11-01 | 4,382 |

**Root cause confirmed from SP_INFO_KAPP_CLIENT_ALLOCATIONS_COUNTS definition:**
```sql
-- Procedure only collects from nodes active in DBA_VCC_MEMSQL ping stats within last 40 minutes
INSERT INTO @SERVERNAMES
SELECT InstanceName FROM DBA_VCC_MEMSQL..LU_Serverlist
WHERE Role = 'Master Aggregator'
  AND SERVERNAME IN (
      SELECT SERVERNAME FROM DBA_VCC_MEMSQL.dbo.BAS_Ping_Stat
      WHERE DATEDIFF(MINUTE, DATECHECKED, GETDATE()) < 40 AND [Status] = 1)
  AND INSTANCENAME IN (
      SELECT SERVERNAME FROM DBA_VCC_MEMSQL.dbo.BAS_SQL_Status
      WHERE DATEDIFF(MINUTE, DATECHECKED, GETDATE()) < 40 AND [Status] = 1)
```

**Finding:** All 9 collection tables stale since 4 May 2026 — same day MEMSQL jobs were disabled. Every SP_INFO procedure checks DBA_VCC_MEMSQL ping stats before collecting. With MEMSQL jobs disabled, no node passes the 40-minute freshness check, @SERVERNAMES is always empty, nothing is written, job reports Succeeded. This is not a CATCH block error — the procedure runs cleanly with zero rows. Billing data for May and June 2026 is incomplete. Must be disclosed to stakeholders.

---

## 2026-07-09 — REP_MONTHEND procedures confirmed in DBA_VCC_COST and DBA_VCC_MEMSQL

**Question:** Where do the REP_MONTHEND procedures live and what do they cover?

**Query (query 14.1 and 14.5):**
```sql
SELECT name, type_desc, create_date, modify_date
FROM DBA_VCC_COST.sys.objects WHERE type = 'P' ORDER BY name;

SELECT name, type_desc, create_date, modify_date
FROM DBA_VCC_MEMSQL.sys.objects WHERE type = 'P' AND name LIKE '%MONTHEND%' ORDER BY name;
```

**Evidence — DBA_VCC_COST (19 REP_MONTHEND + 9 SP_INFO procedures):**

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

**Evidence — DBA_VCC_MEMSQL (14 REP_MONTHEND procedures):**

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

**Finding:** REP_MONTHEND procedures exist in both databases — 19 in DBA_VCC_COST (entity counts per client) and 14 in DBA_VCC_MEMSQL (client growth, cost footprint, backups). All built by donovan.vangraan between 2022 and 2024. Who calls them each month end is still open — needs tashvir.babulal / rayhaan.suleyman.

---

## 2026-07-09 — LU_EntityList confirms EW1R-TC = TeamCity and EW2P-MARKETING-DB owner

**Question:** What infrastructure nodes does DBA_VCC_COST track and who owns EW2P-MARKETING-DB?

**Query (query 14.4):**
```sql
SELECT * FROM DBA_VCC_COST.dbo.LU_EntityList ORDER BY Application, Enviroment, EntityName;
```

**Evidence:**

| Application | Account | Environments | Notes |
|---|---|---|---|
| KAPP | KurtosysApp_Prod / Non-Prod | Production (EC1P, EW2P, UE1P), Release (EW1R), Dev (EW1D) | Core KAPP platform |
| DXM | KurtosysApp_Prod / Non-Prod | Production (EC1P, EW2P, UE1P), Release (EW1R), Dev (EW1D) | Document generation |
| InvestorPress | InvestorPress_Encore_Prod / Non-Prod | Production (EW2P), Release (EW1R), Dev (EW1D) | |
| Encore | InvestorPress_Encore_Prod / Non-Prod | Production (EW2P), Release (EW1R), Dev (EW1D) | MSSQL nodes |
| WPv2 | Wordpress_V2_Prod / Non-Prod | Production (EW2P, UE1P), Release (EW2R, UE1R) | ⚠️ Decommissioned — entries stale |
| Marketing | Marketing (232173278818) | Production (EW2P) | ⚠️ EW2P-MARKETING-DB Not Online — owner confirmed |
| NiFi | Shared_Services_Prod | Production (EW1P) | EW1P-NIFIREG-01 |
| TeamCity | Shared_Services_Prod / Non-Prod | Production (EW1P), Release (EW1R) | EW1R-TC confirmed TeamCity |
| Octa | Shared_Services_Non-Prod | Production (EW1P) | EW1P-OCT |
| Reporting | Shared_Services_Non-Prod | Release (EW1R) | EW1R-REP-01 — this server tracks its own costs |
| Zabbix | Shared_Services_Non-Prod | Release (EW1R) | EW1R-ZABBIX-02 |
| REP | Monitoring_Alerting | Production (EW1P) | EW1P-MON-01 |

**Finding:** EW1R-TC confirmed as TeamCity — open question closed. EW2P-MARKETING-DB owner confirmed as Marketing account (AccountId 232173278818) — open question 26 closed. EW1R-REP-01 appears in its own entity list under Reporting — this server tracks its own AWS costs. WPv2 entries still present despite platform being decommissioned. Data quality issues: Enviroment column is a typo, mixed case values, Region has leading spaces on some rows.
