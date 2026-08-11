# Consumer Inventory — EW1R-REP-01
**Ticket:** TECH-3480 — Theme C: External Targets and Consumer Identification
**Source:** TECH-3562 discovery + TECH-3560 SQL Server inventory
**Date:** 2026-08-06

---

## What Depends on This Server

| Consumer | What It Uses | Criticality | Status |
|---|---|---|---|
| Grafana dashboards (74 total) | SQL Server datasource — DBA_VCC_COST, DBA_VCC_MEMSQL, DBA_VCC_AWS, DBA_VCC, Utilities | Critical | Active — 3 admins (DBA team) |
| KAPP Client Utilisation and Growth Report | DBA_VCC_COST — LU_KAPP_ClientList (280 clients) | Internal | Confirmed internal use only — not client-facing. Data stale since 4 May 2026 — silent failure |
| Database Engineering Costs dashboard | DBA_VCC_COST | Internal | Active — last updated Oct 2024 |
| Database Engineering Sprint Reporting | DBA_VCC_COST | Internal | Active — last updated Mar 2024 |
| AWS Cost Report Monthly | DBA_VCC_COST — INFO_AWS_DE_Entity_Cost | Internal | Stale since Nov 2024 |
| 6 Month-End Reporting dashboards | DBA_VCC_COST + DBA_VCC_MEMSQL — REP_MONTHEND_* procedures | Internal | All stale since May 2026. Called by Grafana dashboards only — no automated job. Internal use only. |
| 14 DBA_VCC_MEMSQL dashboards | DBA_VCC_MEMSQL | Internal | All stale since May 2026 — jobs disabled |
| EW2P-MSSQL-01 monitoring | 16 VCC Audit Collection jobs + 8 VCC Server Monitoring jobs | Critical — production server | Active — no secondary monitoring path |
| EW2P-MSSQL-02 monitoring | 16 VCC Audit Collection jobs + 8 VCC Server Monitoring jobs | Critical — production server | Active — no secondary monitoring path |
| Zabbix (via ZabbixProdNew linked server) | Utilities.dbo.Zab_* tables — deadlock, sync check, AG lag | High | Active — Zabbix reads via linked server |
| Slack alerts (via Grafana) | Grafana alerts — REP_CLIENT_CONFIG_CHANGES_REPORT, REP_CLIENT_APP_AUTH_CONFIG_CHANGES_REPORT | High | Active — alerts-data-operations and alert-app-allow2fa-disabled channels. Data fed by DBA_VCC_MEMSQL_DAILY_CHECKS — stale since May 2026. Alerts currently firing on stale data. |
| AWS CloudWatch / S3 | Python API — DBA_VCC_AWS_15MIN_CHECKS, DBA_VCC_AWS_DAILY_CHECKS | High | Active — 30-min and daily jobs running |
| Encore IIS / BNY IIS logs | DBA_VCC_HOURLY_CHECKS — CloudWatch ingestion | Medium | Active — hourly collection |
| DXM client sizes | DBA_VCC_MYSQL — DXM audit jobs | Medium | Active — daily collection |
| Jira sprint data | DBA_VCC_ATLASSIAN — DBA_VCC_JIRA_MONTHEND_CHECKS | Medium | Active — monthly |
| EW1P-OCT RDS backup | DBA - Maintenance - SQL Backup EW1P-OCT | Medium | Active — daily. KMS key NULL — unencrypted |

---

## Month-End Procedure Consumers

### DBA_VCC_COST — 19 REP_MONTHEND procedures

| Procedure | Covers | Last Modified |
|---|---|---|
| REP_MONTHEND_CLIENT_ALLOCATIONS_REPORT | All clients — allocations summary | 2023-01-06 |
| REP_MONTHEND_CLIENT_ALLOCATIONS_CLIENT_REPORT | Per-client — allocations | 2023-01-06 |
| REP_MONTHEND_CLIENT_DISCLAIMERS_COMMENTARIES_REPORT | All clients — disclaimers | 2022-11-23 |
| REP_MONTHEND_CLIENT_DISCLAIMERS_COMMENTARIES_CLIENT_REPORT | Per-client — disclaimers | 2023-01-06 |
| REP_MONTHEND_CLIENT_DOCUMENTS_REPORT | All clients — documents | 2022-11-23 |
| REP_MONTHEND_CLIENT_DOCUMENTS_CLIENT_REPORT | Per-client — documents | 2023-01-06 |
| REP_MONTHEND_CLIENT_ENTITY_REPORT | All clients — entities | 2022-11-23 |
| REP_MONTHEND_CLIENT_HISTORICALDATASETS_REPORT | All clients — historical datasets | 2022-11-23 |
| REP_MONTHEND_CLIENT_HISTORICALDATASETS_CLIENT_REPORT | Per-client — historical datasets | 2023-01-06 |
| REP_MONTHEND_CLIENT_SNAPSHOTS_REPORT | All clients — snapshots | 2022-11-23 |
| REP_MONTHEND_CLIENT_SNAPSHOTS_CLIENT_REPORT | Per-client — snapshots | 2023-01-06 |
| REP_MONTHEND_CLIENT_STATSTICS_REPORT | All clients — statistics | 2022-11-23 |
| REP_MONTHEND_CLIENT_STATSTICS_CLIENT_REPORT | Per-client — statistics | 2023-01-06 |
| REP_MONTHEND_CLIENT_TIMESERIES_REPORT | All clients — time series | 2022-11-23 |
| REP_MONTHEND_CLIENT_TIMESERIES_CLIENT_REPORT | Per-client — time series | 2023-01-06 |
| REP_MONTHEND_CLIENT_TOP5_ALLOCATIONS_REPORT | Top 5 clients — allocations | 2023-01-06 |
| REP_MONTHEND_CLIENT_USER_COUNTS_REPORT | All clients — user counts | 2022-10-12 |
| REP_MONTHEND_CLIENT_USER_REPORT | All clients — users | 2022-11-23 |
| REP_MONTHEND_TOP5_CLIENTS_DATA_FOOTPRINT_REPORT | Top 5 clients — data footprint | 2023-01-06 |

> All 19 procedures depend on DBA_VCC_COST collection tables which have been stale since 4 May 2026. Any month-end report run since May 2026 has been using stale data. Never modified since Jan 2023.

### DBA_VCC_MEMSQL — 14 REP_MONTHEND procedures

| Procedure | Covers | Last Modified | Notes |
|---|---|---|---|
| REP_MONTHEND_CLIENT_NUMBER_REPORT | Client count | 2024-01-22 | Most recently modified |
| REP_MONTHEND_CLIENTGROWTH_COST_ENV_FOOTPRINT_REPORT | Client growth by env | 2023-10-13 | |
| REP_MONTHEND_CLIENTGROWTH_COST_REPORT | Client growth cost | 2023-07-05 | |
| REP_MONTHEND_CLIENTGROWTH_COST_TOP5_REPORT | Top 5 client growth | 2024-01-22 | Most recently modified |
| REP_MONTHEND_CLINTGROWTH_COST_ENV_FOOTPRINT_REPORT | Client growth by env | 2023-08-10 | CLINT typo — old version |
| REP_MONTHEND_CLINTGROWTH_COST_REPORT | Client growth cost | 2022-06-21 | CLINT typo — old version |
| REP_MONTHEND_CLINTGROWTH_COST_TOP5_REPORT | Top 5 client growth | 2023-08-10 | CLINT typo — old version |
| REP_MONTHEND_IP_BACKUP_REPORT | InvestorPress backups | 2023-08-10 | |
| REP_MONTHEND_IP_CLINTGROWTH_COST_REPORT | IP client growth | 2023-01-05 | CLINT typo — old version |
| REP_MONTHEND_KAPP_BACKUP_REPORT | KAPP backups | 2023-08-10 | |
| REP_MONTHEND_KAPP_CLINTGROWTH_COST_REPORT | KAPP client growth | 2022-06-21 | CLINT typo — old version |
| REP_MONTHEND_KAPP_LOADER_REPORT | KAPP loaders | 2023-08-10 | |
| REP_MONTHEND_KAPP_SNAPSHOTS_TOP5_REPORT | KAPP top 5 snapshots | 2023-08-10 | |
| REP_MONTHEND_MAXDB_SERVER_STATUS_REPORT | MaxDB server status | 2017-12-13 | Predates VCC framework — leftover |

> All 14 procedures depend on DBA_VCC_MEMSQL which has been stale since May 2026 — jobs disabled. Called by Grafana dashboards only. SingleStore being decommissioned — all 14 procedures are retire candidates.

### Grafana Dashboards Calling REP_MONTHEND

| Dashboard | Last Updated |
|---|---|
| WPv2 Month End Reporting | 2024-06-20 |
| Encore Month End Reporting | 2023-08-10 |
| DXM Month End Reporting | 2023-08-10 |
| InvestorPress Month End Reporting | 2023-08-10 |
| KAPP Month End Reporting | 2023-08-10 |
| Other Services Month End Reporting (Draft) | 2023-07-21 |

> Q3(C) CLOSED — caller confirmed as whoever opens these dashboards in Grafana. No automated job or external scheduler. Internal use only. Dashboards are retire candidates on decommission.

---

## Slack Alert Consumers

| Channel | Source | Trigger | Status |
|---|---|---|---|
| alerts-data-operations | Grafana alert — REP_CLIENT_CONFIG_CHANGES_REPORT | Client config changes (enableDocumentEntitlement, enabledEntityTypeEntitlements, enabledCaseSensitive) — current vs 2 days ago | Active — alert evaluates every 10 minutes. Data fed by DBA_VCC_MEMSQL_DAILY_CHECKS (06:00 UTC daily). Stale since May 2026. |
| alert-app-allow2fa-disabled | Grafana alert — REP_CLIENT_APP_AUTH_CONFIG_CHANGES_REPORT | Application 2FA config changes — current vs 2 days ago | Active — alert evaluates every 10 minutes. Data fed by DBA_VCC_MEMSQL_DAILY_CHECKS (06:00 UTC daily). Stale since May 2026. |

> Q4(C) UPDATED — alerts-data-operations and alert-app-allow2fa-disabled are active Grafana alerts, not Zabbix webhooks. Data is collected by DBA_VCC_MEMSQL_DAILY_CHECKS job steps SP_AUDIT_FP_Client_Sizes_DETAILED and SP_AUDIT_FP_Client_ApplicationConfiguration_Auth_DETAILED. Since DBA_VCC_MEMSQL jobs were disabled in May 2026, both alerts have been evaluating on stale data. On decommission: both Grafana alerts and their underlying stored procedures must be retired. See Confluence: Client and Application 2FA configuration changes alerting.

---

## Infrastructure Dependencies

### Service Accounts

| Service | Account | Notes |
|---|---|---|
| SQL Server Engine | AD domain account | Contact DBA team |
| SQL Server Agent | SHNONPRD\sqlagent | Confirmed — runs DBA_VCC_COST_Entity_Count_Collection |
| SQL Server Launchpad | NT Service account | |
| Linked server credentials | Unknown | Check vault |
| AWS API access (Python) | IAM instance profile `KurtosysEC2InstanceProfileRoleRep` | Confirmed — STS temporary credentials active. No static key on disk. Detach instance profile on decommission. |

### Firewall Rules (Windows Firewall confirmed 2026-08-11 — AWS Security Group rules still needed from DevOps)

| Direction | Source / Destination | Port | Purpose |
|---|---|---|---|
| Outbound | SingleStore nodes (46 reachable) | 3306 (ODBC) | MemSQL cluster queries |
| Outbound | MySQL / DXM / WPv2 nodes | 3306 | MySQL monitoring |
| Outbound | EW2P-MSSQL-01/02 | 1433 | SQL Server monitoring |
| Outbound | AWS APIs (CloudWatch, S3) | 443 | Python API calls |
| Outbound | Jira | 443 | Sprint data collection |
| Outbound | S3 (ksys-ew1r-db-backups, ksys-ew1p-oct-dbbackup) | 443 | Backup uploads |
| Inbound | Grafana clients | 443 | Dashboard access |
| Inbound | DBA team | 1433 | SQL Server management |
| Inbound | Zabbix (ZabbixProdNew) | 10050 | Zabbix agent |
| Inbound | RDP | 3389 | Remote management |
| Inbound | WinRM | 5985 | Remote management |

---

## Open Questions

| # | Question | Who to Ask | Status |
|---|---|---|---|
| Q3(C) | Who calls REP_MONTHEND_* procedures each month end — manually or automated? | DBA team | CLOSED — called by Grafana dashboards only. No SQL Agent job. Internal use only. |
| Q4(C) | Who receives alerts-data-operations and alert-app-allow2fa-disabled Slack channels? | DBA team / ops team | UPDATED — active Grafana alerts confirmed. alerts-data-operations triggered by REP_CLIENT_CONFIG_CHANGES_REPORT, alert-app-allow2fa-disabled triggered by REP_CLIENT_APP_AUTH_CONFIG_CHANGES_REPORT. Both fed by DBA_VCC_MEMSQL_DAILY_CHECKS. Stale since May 2026. Must be retired on decommission. |
| Q5(C) | What IAM role/key does the Python AWS API caller use? | DevOps / cloud team | CLOSED — IAM instance profile `KurtosysEC2InstanceProfileRoleRep`. No static key on disk. |
| Q7(C) | Is ZabbixProdOld still active or confirmed safe to remove? | Infrastructure team | CLOSED — confirmed dead. Ping timed out 2026-08-06. Pending infrastructure sign-off to drop. |
| Q18 | What firewall rules allow inbound/outbound connections to this server? | Infrastructure / DevOps | CLOSED — Windows Firewall rules documented 2026-08-11. AWS Security Group rules still needed from DevOps. See firewall-rules.md |
| Q21 | If this server went offline today, what would break immediately? | DBA team | CLOSED — 74 Grafana dashboards, EW2P-MSSQL-01/02 monitoring, KAPP billing dashboard, S3 backups, CloudWatch collection. |
| Q22 | Is any alerting dependent solely on this server — would anyone lose visibility? | DBA team | UPDATED — alerts-data-operations and alert-app-allow2fa-disabled are active Grafana alerts on this server. Both will be silenced on decommission. SQL Server severity alerts all silent. Zabbix deadlock and sync check data also stops. |
| Q23 | Is the VCC framework replicated anywhere else or is this the only instance? | DBA team | CLOSED — VCC framework unique to EW1R-REP-01. No VCC databases on EW2P-MSSQL-01 or EW2P-MSSQL-02. |
