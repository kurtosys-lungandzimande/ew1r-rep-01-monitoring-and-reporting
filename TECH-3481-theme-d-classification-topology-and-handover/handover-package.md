# Handover Package — EW1R-REP-01
**Ticket:** TECH-3481 — Theme D: Classification, Topology and Handover
**Date:** 2026-08-13
**Purpose:** Complete handover of all findings, active failures, owners, and next actions to the team responsible for migration and replacement planning.

---

## Server at a Glance

| Property | Value |
|---|---|
| Hostname | EW1R-REP-01 |
| IP | 10.72.8.216 |
| Platform | AWS EC2 — eu-west-1 |
| SQL Server | 2019 Developer Edition — NOT licensed for production use |
| Grafana | 9.5.2 self-hosted — port 443 HTTPS |
| Total data | 369 GB across 8 databases |
| Active jobs | 52 of 63 enabled |
| Linked servers | 109 total — 63 dead, 46 reachable |
| Grafana dashboards | 74 total — 9 with live data and no equivalent elsewhere |
| Active Grafana users | 3 active admins |
| Decommission status | NOT SAFE — 8-week execution plan required. Target: October 2026. Hard deadline: November 2026 |

---

## Active Failures — Fix Before Anything Else

| # | Failure | Since | Impact | Owner | Action |
|---|---|---|---|---|---|
| F1 | DBA_VCC_MYSQL_DAILY_CHECKS and DBA_VCC_MYSQL_AUDIT_DXM_CLIENT_DETAILED failing daily | 25 June 2026 | Silent daily failures — no alert fires | DBA team | Remove WPv2 steps. Drop SP_AUDIT_WPv2_CLIENTS_DETAILED. Drop 4 WPv2 linked servers |
| F2 | DBA_VCC_COST data stale — 280 client billing records frozen | 4 May 2026 | Client billing data 3+ months stale. KAPP Client Utilisation dashboard showing wrong figures | DBA team lead | Stakeholders notified. Replacement pipeline needed. Cannot recover without new data source |
| F3 | AWS cost ETL silently broken — CATCH block swallows error | Sept 2024 | AWS Cost Report dashboards showing data 22+ months stale | DBA team | Identify failing step in DBA_VCC_AWS_DAILY_CHECKS. Fix or retire — AWS Cost Explorer replaces this |
| F4 | donovan.vangraan credentials active in 4 Grafana Zabbix datasources | Nov 2024 (inactive) | Ex-employee has active database access to Zabbix MySQL | DBA team | Revoke Grafana admin. Create grafana_readonly service account. Replace credentials |
| F5 | Default Grafana admin account active | — | Unnecessary admin account | DBA team | Disable immediately |
| F6 | S3 backup encryption gaps | — | DBA_VCC_COST client data potentially backed up unencrypted | DBA team | Add --sse AES256 to USP_DatabaseBackupMoveToS3. Fix KMS key NULL on EW1P-OCT backup |
| F7 | KAPP Month End Reporting snapshot — permanent public URL (expires 2074) | Jan 2024 | Anyone with URL can access dashboard data without login | DBA team | Confirm recipient. Delete snapshot if no longer needed |

---

## What Must Be Migrated Before Decommission

These are the items that will break immediately if the server is switched off without migration.

| Component | What Breaks | Migration Target | Priority |
|---|---|---|---|
| EW2P-MSSQL-01/02 monitoring (24 jobs) | Two production SQL Servers go completely dark — no monitoring, no alerting | CloudWatch Agent on EW2P servers | Critical |
| 9 active Grafana dashboards | DBA team loses visibility of KAPP, NiFi, SingleStore, and cost data | Amazon Managed Grafana | Critical |
| DBA_VCC_COST (280 client billing records) | Client billing data inaccessible — no replacement pipeline | Dedicated licensed RDS instance | Critical |
| DXM monitoring jobs | DXM client size monitoring stops | New monitoring host (TBC) | High |
| KAPP MySQL datasources (UK/EU/US Prod) | 9 dashboards reading production KAPP data break | Re-point in Amazon Managed Grafana | High |
| NiFi JSON API datasource | NiFi API Reporting dashboard breaks | Re-point in Amazon Managed Grafana | Medium |
| EW1P-OCT RDS backup job | EW1P-OCT RDS loses its backup | RDS native automated backups | Medium |
| SQL Server backups (FULL/DIFF/LOG) | EW1R-REP-01 databases lose backup coverage | AWS Backup policies | Medium |
| Zabbix agent (port 10050) | Zabbix loses visibility of EW1R-REP-01 | Notify monitoring team — agent goes with server | Low |

---

## What Can Be Retired — No Migration Needed

These items have no active consumer or have been superseded. They can be dropped as part of the decommission cleanup.

### Databases
| Database | Size | Reason |
|---|---|---|
| DBA_VCC_MEMSQL | 75 GB | All 7 jobs disabled May 2026. SingleStore decommissioned. Archive to S3 cold storage before dropping |
| DBA_VCC_ATLASSIAN | 2 GB | No writer, no confirmed consumer, data frozen Dec 2023. Export 2 tables to S3 before dropping |
| KURTOSYS_BASELINE | 50 GB | No confirmed consumer. Baselines dead systems. Archive MySQL baseline tables to S3 before dropping |

### SQL Agent Jobs
| Job | Reason |
|---|---|
| All 7 DBA_VCC_MEMSQL jobs | SingleStore decommissioned |
| DBA - MemSQL Range Stats Candidates | Disabled, failed May 2023 |
| DBA - ObjectIDValidationReport | Disabled, failed May 2026 — queries dead EW1R-MSSQL-01 |
| DBA - Production Logon Report | Disabled, failed May 2026 |
| DBA - UtilitiesCleanupHistoryTables | Disabled, failed May 2023 |
| BASELINE_CONNECTIONS (MemSQL steps) | MemSQL decommissioned — remove MemSQL steps |
| BASELINE_TABLE_SIZES (MemSQL steps) | MemSQL decommissioned — remove MemSQL steps |

### Linked Servers (safe to drop immediately)
| Group | Count | Reason |
|---|---|---|
| WPv2 (ew2p-wpv2, ew2r-wpv2, ue1p-wpv2, ue1r-wpv2) | 4 | DNS gone, platform decommissioned |
| gen-rel (5 nodes) | 5 | Platform confirmed retired |
| gen-prd (21 nodes) | 21 | Platform confirmed retired |
| ZabbixNonProd | 1 | Confirmed dead |
| ZabbixProdOld | 1 | Confirmed dead — ping timed out 2026-08-06 |
| ew1p-oct short hostname | 1 | Orphan — job uses full RDS hostname |

### Linked Servers (drop after platform team confirmation)
| Group | Count | Confirmation Needed From |
|---|---|---|
| Dead partial-cluster nodes (ec1p/ew1r/ew2p/ue1p) | 30 | SingleStore / platform team |
| ew1d-admin-01/02 | 2 | DBA team |

### Grafana Datasources
| Datasource | Reason |
|---|---|
| DBA_VCC (e8597015 duplicate) | Exact duplicate of a082f27e |
| SingleStore-Dev | Confirmed dead — 100% packet loss |
| SingleStore-Production-UK/EU/US | Confirmed dead — 100% packet loss |
| Zabbix Nonprod old | Dead target |
| Zabbix Prod Old | Dead target — ex-employee credentials |
| monitoring (duplicate) | Exact duplicate of KAPP Monitoring |
| InfluxDB | Never used — zero dashboards, no URL |

### Grafana Dashboards (retire — 35+ confirmed)
| Category | Count |
|---|---|
| Dead datasource — no recovery path | 7 |
| WPv2 decommissioned | 2 |
| MemSQL disabled — no consumer | 11 |
| Duplicate — older copy superseded | 17 |
| Never completed or dead feed | 2 |
| Stale — no confirmed consumer | 5 |
| **Total retire candidates** | **44** |

### Stored Procedures
| Procedure | Database | Reason |
|---|---|---|
| SP_AUDIT_WPv2_CLIENTS_DETAILED | DBA_VCC_MYSQL | Last modified 2022. References dead linked servers. Causing daily job failures |
| REP_CLIENT_CONFIG_CHANGES_REPORT | DBA_VCC_MEMSQL | No active consumer — alerts-data-operations never fired |
| REP_CLIENT_APP_AUTH_CONFIG_CHANGES_REPORT | DBA_VCC_MEMSQL | No active consumer — alert-app-allow2fa-disabled contact point confirmed in Grafana UI but has never fired |
| All REP_MONTHEND_* procedures (33 total) | DBA_VCC_COST (19) + DBA_VCC_MEMSQL (14) | Called by Grafana dashboards only. Dashboards retiring on decommission |

### Infrastructure
| Item | Action |
|---|---|
| IAM instance profile KurtosysEC2InstanceProfileRoleRep | Detach on decommission. Review permissions before detaching |
| Grafana contact points (alerts-data-operations, alert-app-allow2fa-disabled, grafana-default-email) | Retire on decommission — all 3 confirmed via Grafana UI, none have ever fired |
| Grafana alert rules (3) | Retire on decommission — no active consumer confirmed |
| Zabbix agent | Goes with the server on decommission — notify monitoring team |

---

## Items Requiring Confirmation Before Decommission

| # | Item | Who to Ask | Risk if Not Answered |
|---|---|---|---|
| C1 | AWS Security Group rules for EW1R-REP-01 | DevOps | Incomplete firewall picture |
| C2 | KAPP Month End Reporting snapshot recipient (expires 2074) | DBA team | Permanent public URL may still be in use |
| C3 | Database Engineering Sprint Reporting snapshot recipient (expires 2073) | DBA team | Same risk as C2 |
| C4 | pmmdev and pmmprod (Clickhouse) purpose and owner | DBA / Platform team | Cannot drop linked servers without this |
| C5 | ew1d-admin-01/02 permanently retired? | DBA team | Cannot drop linked servers without this |
| C6 | What SSIS packages does DBA - SSISStatusCheck monitor? | DBA team | Cannot retire job without knowing what it watches |
| C7 | EW1P-OCT RDS backup job still needed post-decommission? | DBA team | Determines whether job migrates or retires |
| C8 | EW2P-MSSQL-01/02 — RDS or EC2-hosted? | DBA / DevOps | Determines CloudWatch replacement path |
| C9 | KAPP Dev, KAPP Rel, MySQL generic datasource — which dashboards use them? | DBA team | Cannot retire datasources without this |
| C10 | SingleStore-Release datasource — are dependent dashboards still needed? | DBA team | Target alive — confirm before retiring |

---

## Key Contacts

| Role | Person | What They Own |
|---|---|---|
| Active Grafana admins (3) | DBA team | Grafana dashboards, DBA_VCC_COST consumer confirmation, snapshot confirmation |
| SQL Agent service account | SHNONPRD\sqlagent | Runs all SQL Agent jobs |
| AWS IAM | KurtosysEC2InstanceProfileRoleRep | EC2 instance profile — Python API calls |
| Infrastructure | DevOps / cloud team | AWS Security Group rules, EW2P-MSSQL-01/02 hosting type, Amazon Managed Grafana provisioning |
| Monitoring | Monitoring team | ZabbixProdOld sign-off, Zabbix agent deregistration |

---

## Confluence Pages to Update

| Page | Status | Action |
|---|---|---|
| SQL Server Inventory | Complete | Publish final version from TECH-3560 |
| Grafana Inventory | Complete | Publish final version from TECH-3561 |
| External Targets | Complete | Publish final version from TECH-3562 |
| Consumers and Dependencies | Complete | Publish final version from TECH-3562 |
| Topology & Classification | Updated | Publish final version from TECH-3481 |
| Decommission Recommendation | New | Publish decommission-recommendation.md |
| Handover Package | New | Publish this document |
| Investigation Log | Updated | Publish investigation-log.md |
