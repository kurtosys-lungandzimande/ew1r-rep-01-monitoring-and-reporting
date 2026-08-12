# Decommission Recommendation & Proposed Solution — EW1R-REP-01
**Ticket:** TECH-3481 — Theme D: Classification, Topology and Handover
**Date:** 2026-08-13
**Status:** Final — all Theme A, B, C findings incorporated. All 6 original blockers closed.

---

## Executive Summary

EW1R-REP-01 is not safe to decommission today. It is actively collecting production data every 30 minutes, serving 74 Grafana dashboards to 3 active users, and is the sole monitoring path for two production SQL Servers. The purpose of this document is to lay out what the server does, what is broken right now, and what needs to happen step by step before decommission can proceed.

The target is to have this server decommissioned by October 2026, with November 2026 as the hard deadline. The approach is deliberate — shut one thing down, let it run for a week, confirm nothing breaks, then move to the next. The replacement approach for each function has not been fully agreed yet and will be confirmed with the team at the start of the execution sprint.

---

## What This Server Does — Value Summary

| Function | Active? | Criticality | Replacement Exists? |
|---|---|---|---|
| Monitors EW2P-MSSQL-01/02 (production SQL Servers) | Yes | Critical | Yes — CloudWatch Agent |
| Serves 74 Grafana dashboards to 3 active admins | Yes | Critical | TBD — replacement approach to be agreed with team |
| Collects KAPP API query logs every 30 min (297M rows) | Yes | High | Yes — CloudWatch Logs + Insights |
| Collects AWS costs per entity daily | Yes | High | Yes — AWS Cost Explorer |
| Collects NiFi pipeline logs | Yes | Medium | Yes — CloudWatch Logs |
| Collects Encore/BNY IIS logs hourly | Yes | Medium | Yes — CloudWatch Logs (already there) |
| Tracks client billing data for 280 institutional clients | Yes (stale since May 2026) | Critical | TBD — DBA team to confirm if data is still needed before deciding on migration or retirement |
| Monitors DXM client sizes daily | Yes | Medium | Yes — new monitoring host |
| Backs up EW1P-OCT RDS to S3 | Yes | Medium | Yes — RDS native backup |
| Backs up local SQL Server databases to S3 | Yes | Medium | Yes — AWS Backup |
| Collects Jira sprint data monthly | Yes | Low | Yes — new host or retire |
| Monitors SingleStore clusters | No (disabled May 2026) | N/A — SingleStore decommissioned | N/A |

---

## What Is Wrong Right Now — Active Failures

These must be addressed immediately, independent of the decommission timeline.

| # | Failure | Impact | Fix |
|---|---|---|---|
| F1 | DBA_VCC_MYSQL_DAILY_CHECKS and DBA_VCC_MYSQL_AUDIT_DXM_CLIENT_DETAILED failing every day since 25 June 2026 | Silent daily failures — no alert fires | Remove WPv2 steps from both jobs. Drop SP_AUDIT_WPv2_CLIENTS_DETAILED. Drop 4 WPv2 linked servers |
| F2 | DBA_VCC_COST data stale since 4 May 2026 — 11+ consecutive silent zero-row runs | 280 institutional client billing records frozen. KAPP Client Utilisation dashboard showing stale data | Root cause: DBA_VCC_MEMSQL jobs disabled. SingleStore decommissioned — collection pipeline will not recover. Stakeholders notified. Replacement pipeline needed |
| F3 | AWS cost ETL silently broken since Sept 2024 — CATCH block swallows error | AWS Cost Report and AWS Cost Report Monthly dashboards showing data 22+ months stale | Identify failing step in DBA_VCC_AWS_DAILY_CHECKS. Fix or retire — AWS Cost Explorer replaces this natively |
| F4 | Ex-employee credentials active in 4 Grafana Zabbix datasources — inactive since Nov 2024 | Live security risk — ex-employee has active database access to Zabbix MySQL | Revoke Grafana admin access. Create grafana_readonly service account. Replace credentials in all 4 datasources |
| F5 | Default Grafana admin account active — last seen Nov 2024 | Unnecessary admin account — security risk | Disable immediately |
| F6 | S3 backup encryption gaps — no --sse flag on ksys-ew1r-db-backups, KMS key NULL on ksys-ew1p-oct-dbbackup | DBA_VCC_COST client billing data potentially backed up unencrypted | Add --sse AES256 to USP_DatabaseBackupMoveToS3. Fix KMS key on EW1P-OCT backup job |
| F7 | KAPP Month End Reporting snapshot with 50-year expiry (expires 2074) — permanent public URL | Anyone with the URL can access dashboard data without logging in | Confirm who it was shared with. Delete snapshot if no longer needed |

---

## Proposed Replacement Architecture

### The Core Argument

This server is a custom-built monitoring hub from 2017. It sits between AWS infrastructure and the people who need to see the data, adding complexity, a licensing risk (Developer Edition), and a security risk (ex-employee credentials). AWS now provides every capability this server was built for — natively, at scale, with proper access control.

The proposed replacement stack eliminates this server entirely and replaces each function with the AWS-native equivalent.

### Replacement Stack

| What EW1R-REP-01 Does Today | Replace With | Why |
|---|---|---|
| SQL Server monitoring via VCC framework (EW2P-MSSQL-01/02) | AWS CloudWatch Agent + CloudWatch dashboards | CloudWatch natively monitors EC2 and RDS. No custom framework needed. Metrics available out of the box |
| KAPP API query tracking (297M rows, every 30 min) | CloudWatch Logs + CloudWatch Insights | Data already originates in CloudWatch. This server is making a copy. Query it directly with Insights |
| AWS cost tracking per client/entity | AWS Cost Explorer + Cost Allocation Tags | Native AWS tool. No SQL Server needed. Tag resources by client and query Cost Explorer directly |
| EC2/RDS/S3/IAM inventory | AWS Config + Systems Manager Inventory | Native AWS tools. Auto-updated. No custom collection jobs needed |
| NiFi pipeline logs | CloudWatch Logs | Already flowing there. Query directly |
| Encore/BNY IIS logs | CloudWatch Logs | Already flowing there. This server is making a copy |
| Grafana dashboards (74 total, 9 with live data) | TBD — to be agreed with team at start of execution sprint | Options: Amazon Managed Grafana, Grafana Cloud, self-hosted on new host. Decision needed before Phase 2 |
| Zabbix monitoring dashboards (4 dashboards) | TBD — same as above | Once Grafana replacement is agreed, connect directly to Zabbix MySQL. No middleman |
| Client billing data (DBA_VCC_COST — 280 clients) | TBD — DBA team to confirm if data is still needed | Data stale since May 2026. If still needed: destination to be agreed with team (separate production server migration project ongoing). If no longer needed: archive to S3 and retire |
| DXM client size monitoring | New monitoring host or CloudWatch | DXM is active — needs a confirmed home before decommission |
| SQL Server backups | AWS Backup | Replace xp_cmdshell S3 sync with proper AWS Backup policies. Encryption and retention managed natively |
| EW1P-OCT RDS backup | RDS native automated backups | RDS already supports automated backups to S3 natively. Custom job is redundant |
| Jira sprint data | Retire or move to new host | Low value, low frequency. Assess whether anyone reads DBA_VCC_ATLASSIAN before deciding |

### Architecture Diagram — Target State

```
BEFORE (Current State)
─────────────────────────────────────────────────────────────────────
CloudWatch ──────────────────────────────────────────────────────────┐
Jira API ────────────────────────────────────────────────────────────┤
KAPP MySQL (UK/EU/US Prod) ──────────────────────────────────────────┤
SingleStore (DEAD) ──────────────────────────────────────────────────┤
EW2P-MSSQL-01/02 ───────────────────────────────────────────────────┤
                                                                     ▼
                                              EW1R-REP-01 (SQL Server Dev Edition)
                                              ├── 369 GB custom databases
                                              ├── 63 SQL Agent jobs
                                              ├── 109 linked servers (63 dead)
                                              └── Grafana 9.5.2 (self-hosted)
                                                             │
                                                             ▼
                                              DBA Team (3 active admins)


AFTER (Target State — Grafana replacement approach TBD, to be agreed with team)
─────────────────────────────────────────────────────────────────────
CloudWatch Logs ──────────────────────────────────────────────────────┐
CloudWatch Metrics ───────────────────────────────────────────────────┤
AWS Cost Explorer ────────────────────────────────────────────────────┤
AWS Config ───────────────────────────────────────────────────────────┤
KAPP MySQL (UK/EU/US Prod) ───────────────────────────────────────────┤
Zabbix MySQL (direct) ────────────────────────────────────────────────┤
NiFi API (direct) ────────────────────────────────────────────────────┤
                                                                      ▼
                                              Replacement Grafana (approach TBD)
                                              ├── 9 migrated dashboards (live data)
                                              ├── CloudWatch native dashboards
                                              └── Zabbix dashboards (direct connection)
                                                             │
                                                             ▼
                                              DBA Team (3 active admins)

DBA_VCC_COST ──────────────────────────────► TBD (DBA team to confirm if still needed)
EW2P-MSSQL-01/02 monitoring ───────────────► CloudWatch Agent (installed on EW2P servers)
DXM monitoring ────────────────────────────► New monitoring host (TBC)
SQL Server backups ────────────────────────► AWS Backup policies
```

---

## Migration Plan — Ordered Execution

### Phase 0 — Fix Active Failures Now (Before Any Migration Work)
**Timeline: Week 1 — do not wait for decommission planning**

| Action | Owner | Risk |
|---|---|---|
| Revoke ex-employee Grafana admin access | DBA team | Zero — ex-employee, inactive since Nov 2024 |
| Create grafana_readonly service account in Zabbix MySQL | DBA / Monitoring team | Low |
| Replace ex-employee credentials in all 4 Zabbix datasources | DBA team | Low — test each datasource after update |
| Disable default Grafana admin account | DBA team | Zero |
| Remove WPv2 steps from DBA_VCC_MYSQL_DAILY_CHECKS and DBA_VCC_MYSQL_AUDIT_DXM_CLIENT_DETAILED | DBA team | Zero — WPv2 confirmed decommissioned |
| Drop SP_AUDIT_WPv2_CLIENTS_DETAILED | DBA team | Zero |
| Drop 4 WPv2 linked servers (ew2p-wpv2, ew2r-wpv2, ue1p-wpv2, ue1r-wpv2) | DBA team | Zero |
| Drop 26 gen-rel + gen-prd linked servers | DBA team | Zero — platform confirmed retired |
| Drop ZabbixNonProd and ZabbixProdOld linked servers | DBA team | Zero — both confirmed dead |
| Add --sse AES256 to USP_DatabaseBackupMoveToS3 | DBA team | Low — test backup job after change |
| Fix KMS key NULL on EW1P-OCT RDS backup job | DBA team | Low |
| Confirm and delete KAPP Month End Reporting snapshot (expires 2074) | DBA team | Low — confirm recipient first |
| Notify stakeholders that DBA_VCC_COST data has been stale since 4 May 2026 | DBA team lead | Required — billing data impact |

### Phase 1 — Confirm Remaining Open Items
**Timeline: Weeks 1–2**

| Action | Owner | Blocks |
|---|---|---|
| Confirmed EW2P-MSSQL-01/02 are EC2-hosted — install CloudWatch Agent on EW2P servers | DBA / DevOps | Replacement path confirmed: CloudWatch Agent, not native RDS monitoring |
| Get AWS Security Group rules for EW1R-REP-01 from DevOps | DevOps | Completes firewall documentation |
| Confirm pmmdev and pmmprod (Clickhouse) purpose and owner | DBA / Platform team | Cannot drop linked servers without this |
| Confirm ew1d-admin-01/02 permanently retired | DBA team | Cannot drop linked servers without this |
| Confirm what SSIS packages DBA - SSISStatusCheck monitors | DBA team | Cannot retire job without this |
| Confirm EW1P-OCT RDS backup job still needed post-decommission | DBA team | Determines whether job migrates or retires |
| Confirm KAPP Dev, KAPP Rel, MySQL generic datasource usage | DBA team | Cannot retire datasources without this |
| Confirm SingleStore-Release datasource still needed | DBA team | Target alive — confirm if dashboards still needed |

### Phase 2 — Set Up Replacement Infrastructure
**Timeline: Weeks 3–6**

| Action | Owner | Notes |
|---|---|---|
| Provision replacement Grafana workspace (approach TBD — agree with team before this phase) | DevOps / DBA team | Options: Amazon Managed Grafana, Grafana Cloud, self-hosted. Connect to CloudWatch, RDS, KAPP MySQL, NiFi API, Zabbix MySQL |
| Configure CloudWatch Agent on EW2P-MSSQL-01/02 | DevOps | Replaces 24 VCC monitoring jobs. EC2-hosted confirmed — CloudWatch Agent is the path |
| Set up CloudWatch dashboards for EW2P-MSSQL-01/02 | DBA team | Replaces VCC monitoring dashboards |
| Confirm with DBA team whether DBA_VCC_COST data is still needed — migrate or retire based on answer | DBA team | Data stale since May 2026. If still needed: destination to be agreed with team — separate production server migration project is ongoing and may cover this. If no longer needed: archive to S3 cold storage and retire |
| Configure AWS Backup policies for SQL Server backups | DevOps | Replace xp_cmdshell S3 sync. Encryption and retention managed natively |
| Enable RDS native automated backups for EW1P-OCT | DevOps | Replace custom backup job |

### Phase 3 — Migrate Active Grafana Dashboards
**Timeline: Weeks 6–8**

| Action | Owner | Notes |
|---|---|---|
| Migrate 9 confirmed active dashboards to replacement Grafana | DBA team | NiFi API Reporting, Database Engineering Costs, Cluster View, Historical Workload Monitoring, Query History, Detailed KAPP Workflow Stats, Release/Dev Doc Gen Run Metrics |
| Re-point KAPP UK/EU/US Prod datasources in new Grafana | DBA team | Direct MySQL connections — same IPs, new Grafana host |
| Re-point NiFi JSON API datasource in new Grafana | DBA team | 10.125.9.192:8443 — same endpoint |
| Re-point Zabbix datasources in new Grafana (direct connection) | DBA / Monitoring team | Use new grafana_readonly service account |
| Validate all migrated dashboards show live data | DBA team | Test each dashboard before retiring old Grafana |
| Notify 3 active admins of new Grafana URL | DBA team | Inform active admins once new URL is confirmed |
| Confirm 2 pending dashboards (KAPP Client Utilisation, BNY IIS Log Streams) | DBA team | Migrate or retire based on confirmation |
| Retire 35+ dashboards confirmed as retire candidates | DBA team | Dead datasources, duplicates, MemSQL-dependent |

### Phase 4 — Migrate DXM Monitoring
**Timeline: Weeks 8–10**

| Action | Owner | Notes |
|---|---|---|
| Confirm new host for DXM monitoring jobs | DBA team | DXM is active — needs a confirmed home |
| Migrate DBA_VCC_MYSQL DXM jobs to new host | DBA team | Remove WPv2 steps first (done in Phase 0) |
| Migrate DXM linked servers (ew1r-dxm, ew2p-dxm, ec1p-dxm, ue1p-dxm) | DBA team | Active connections — test after migration |
| Validate DXM monitoring on new host | DBA team | Confirm data flowing before retiring old jobs |

### Phase 5 — Decommission
**Timeline: Weeks 10–12**

| Action | Owner | Notes |
|---|---|---|
| Disable all remaining SQL Agent jobs | DBA team | Confirm each job has been replaced or retired |
| Drop all remaining dead linked servers (30 partial-cluster nodes) | DBA team | Confirm with platform team first |
| Archive DBA_VCC_MEMSQL, DBA_VCC_ATLASSIAN, KURTOSYS_BASELINE to S3 cold storage | DBA team | 127 GB — export before dropping |
| Retire DBA_VCC_MEMSQL, DBA_VCC_ATLASSIAN, KURTOSYS_BASELINE databases | DBA team | After archive confirmed |
| Retire DBA_VCC_AWS database | DBA team | After CloudWatch Logs confirmed as replacement |
| Retire DBA_VCC database | DBA team | After CloudWatch Agent confirmed on EW2P servers |
| Retire DBA_VCC_MYSQL database | DBA team | After DXM migration confirmed |
| Retire DBA_VCC_COST from this server | DBA team | After migration destination confirmed and data validated |
| Detach IAM instance profile KurtosysEC2InstanceProfileRoleRep | DevOps | Confirm permissions reviewed before detaching |
| Confirm with DBA team whether Grafana contact points and alert rules are still needed — retire if confirmed no longer needed | DBA team | alerts-data-operations, grafana-default-email, alert rules — no active consumer confirmed, but DBA team must approve before retiring |
| Confirm with DBA team whether stored procedures REP_CLIENT_CONFIG_CHANGES_REPORT and REP_CLIENT_APP_AUTH_CONFIG_CHANGES_REPORT are still needed — retire if confirmed | DBA team | No active consumer confirmed — DBA team sign-off required before dropping |
| Stop S3 backup jobs | DBA team | After AWS Backup policies confirmed active |
| Confirm S3 retention policy on ksys-ew1r-db-backups before stopping | DevOps | Do not stop until retention confirmed |
| Switch off EW1R-REP-01 EC2 instance | DevOps | Final step — after all above confirmed |
| Deregister Zabbix agent from Zabbix server | Monitoring team | Zabbix will lose visibility of this server |

---

## Realistic Timeline

**Target: October 2026. Hard deadline: November 2026.**

Each week has one focus. Shut it down, let it run for a week, confirm nothing breaks, then move to the next. Nothing is retired until confirmed stable.

| Week | Focus | What Happens |
|---|---|---|
| Week 1 | Fix active failures | Fix ex-employee credentials in Grafana. Disable default admin. Remove WPv2 steps from failing jobs. Drop 4 WPv2 linked servers. Drop 26 gen-rel + gen-prd dead linked servers. Drop ZabbixNonProd + ZabbixProdOld. Fix S3 encryption gaps. Notify stakeholders about stale DBA_VCC_COST data |
| Week 2 | Confirm + stabilise | Let Week 1 fixes run. Confirm no jobs broke. Answer remaining open items: EW2P-MSSQL-01/02 hosting type, pmmdev/pmmprod purpose, ew1d-admin-01/02 status, SSIS packages, EW1P-OCT backup need. Agree Grafana replacement approach with team |
| Week 3 | Replacement infrastructure | Provision replacement Grafana workspace (approach agreed in Week 2). Configure CloudWatch Agent on EW2P-MSSQL-01/02. Confirm DBA_VCC_COST decision with DBA team (still needed or not — migration destination TBD, separate project ongoing). Set up AWS Backup policies |
| Week 4 | Validate replacement infrastructure | Confirm CloudWatch Agent collecting data on EW2P servers. Confirm DBA_VCC_COST decision actioned (migration validated or archive confirmed). Confirm AWS Backup running. Do not retire anything yet |
| Week 5 | Migrate Grafana dashboards | Migrate 9 active dashboards to replacement Grafana. Run old and new Grafana in parallel. Re-point KAPP, NiFi, Zabbix datasources. Validate each dashboard shows live data |
| Week 6 | Confirm Grafana migration + retire old dashboards | Confirm all 3 admins using new Grafana. Retire 44 confirmed retire-candidate dashboards from old Grafana. Retire dead datasources (SingleStore dead, InfluxDB, duplicates). Confirm with DBA team whether Grafana contact points, alert rules, and stored procedures (REP_CLIENT_CONFIG_CHANGES_REPORT, REP_CLIENT_APP_AUTH_CONFIG_CHANGES_REPORT) are still needed. Retire only if DBA team confirms no longer needed |
| Week 7 | Migrate DXM monitoring + retire databases | Migrate DXM jobs and linked servers to new host. Confirm data flowing. Archive DBA_VCC_MEMSQL (75 GB), DBA_VCC_ATLASSIAN (2 GB), KURTOSYS_BASELINE (50 GB) to S3 cold storage. Retire those 3 databases after archive confirmed |
| Week 8 | Decommission | Drop remaining 30 dead partial-cluster linked servers (after platform team confirmation). Retire DBA_VCC_AWS, DBA_VCC, DBA_VCC_MYSQL, DBA_VCC_COST from this server (after replacements confirmed). Detach IAM instance profile. Stop S3 backup jobs (after AWS Backup confirmed). Switch off EW1R-REP-01. Deregister Zabbix agent |

---

## Risk Register

| Risk | Severity | Mitigation |
|---|---|---|
| EW2P-MSSQL-01/02 go dark during migration | Critical | Do not decommission VCC monitoring jobs until CloudWatch Agent confirmed active and dashboards validated |
| DBA_VCC_COST client billing data lost | Critical | DBA team to confirm if data is still needed before any action. If still needed: migration destination to be agreed — separate production server migration project is ongoing and may cover this. If no longer needed: archive to S3 cold storage and retire |
| Active Grafana dashboards break during migration | High | Run old and new Grafana in parallel during Phase 3. Only retire old Grafana after all 3 admins confirm new dashboards working |
| DXM monitoring gap | High | Confirm new host before Phase 4. Do not retire DXM jobs until new host validated |
| KAPP Month End Reporting snapshot still in use | Medium | Confirm recipient before deleting. If still in use, migrate to new Grafana first |
| 30 partial-cluster dead linked servers have hidden dependencies | Medium | Run dependency check before dropping — confirm no job or stored proc references them |
| pmmdev/pmmprod Clickhouse linked servers have unknown dependencies | Medium | Confirm purpose and owner before Phase 5 |
| S3 backup retention gap on decommission | Medium | Confirm retention policy before stopping backup jobs. Do not stop until confirmed |
| Zabbix loses visibility of EW1R-REP-01 on decommission | Low | Notify monitoring team before Phase 5. Zabbix agent goes with the server |

---

## Definition of Done — TECH-3481

- [x] All 6 decommission blocker questions answered or formally escalated with evidence
- [x] Component classification finalised — all components confirmed as Replace, Retire, Move, or Confirm
- [x] Topology diagram updated — dead targets removed, confirmed consumers added, active data flows validated
- [x] Decommission recommendation finalised — not safe to decommission today, 8-week execution plan defined targeting October 2026
- [x] Handover package complete — all active failures documented with owner and next action
- [x] Migration input produced — ordered 5-phase plan with owners and dependencies
- [ ] All Confluence pages updated to reflect final classification and topology
- [ ] Handover published to Confluence and shared with migration team
