# Decommission Recommendation & Proposed Solution — EW1R-REP-01
**Ticket:** TECH-3481 — Theme D: Classification, Topology and Handover
**Date:** 2026-08-13
**Status:** Final — all Theme A, B, C findings incorporated. All 6 original blockers closed.

---

## Executive Summary

EW1R-REP-01 is **not safe to decommission today**. It is actively collecting production data every 30 minutes, serving 74 Grafana dashboards to 3 active users, and is the sole monitoring path for two production SQL Servers. However, the decommission plan is now fully defined. Every function this server performs has a confirmed replacement path. The server can be decommissioned in 10–12 weeks from stakeholder sign-off, provided the migration actions below are executed in order.

The server was built in 2017 to solve a monitoring problem that AWS now solves natively. Every single thing it does has a direct AWS equivalent. The platform has moved to AWS — the monitoring should follow.

---

## What This Server Does — Value Summary

| Function | Active? | Criticality | Replacement Exists? |
|---|---|---|---|
| Monitors EW2P-MSSQL-01/02 (production SQL Servers) | Yes | Critical | Yes — CloudWatch Agent |
| Serves 74 Grafana dashboards to 3 active admins | Yes | Critical | Yes — Amazon Managed Grafana |
| Collects KAPP API query logs every 30 min (297M rows) | Yes | High | Yes — CloudWatch Logs + Insights |
| Collects AWS costs per entity daily | Yes | High | Yes — AWS Cost Explorer |
| Collects NiFi pipeline logs | Yes | Medium | Yes — CloudWatch Logs |
| Collects Encore/BNY IIS logs hourly | Yes | Medium | Yes — CloudWatch Logs (already there) |
| Tracks client billing data for 280 institutional clients | Yes (stale since May 2026) | Critical | Needs dedicated licensed RDS |
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
| F4 | donovan.vangraan credentials active in 4 Grafana Zabbix datasources — ex-employee inactive since Nov 2024 | Live security risk — ex-employee has active database access to Zabbix MySQL | Revoke Grafana admin access. Create grafana_readonly service account. Replace credentials in all 4 datasources |
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
| Grafana dashboards (74 total, 9 with live data) | Amazon Managed Grafana | AWS-managed. No server to maintain. IAM-based access. Connects to CloudWatch, RDS, and other AWS datasources natively |
| Zabbix monitoring dashboards (4 dashboards) | Amazon Managed Grafana → direct to Zabbix MySQL | Cut out this server entirely. Connect Grafana directly to Zabbix. No middleman |
| Client billing data (DBA_VCC_COST — 280 clients) | Dedicated licensed RDS instance (SQL Server Standard or Enterprise) | Cannot stay on Developer Edition non-prod server. Needs production-grade host with proper backup, monitoring, and access control |
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


AFTER (Target State)
─────────────────────────────────────────────────────────────────────
CloudWatch Logs ──────────────────────────────────────────────────────┐
CloudWatch Metrics ───────────────────────────────────────────────────┤
AWS Cost Explorer ────────────────────────────────────────────────────┤
AWS Config ───────────────────────────────────────────────────────────┤
KAPP MySQL (UK/EU/US Prod) ───────────────────────────────────────────┤
Zabbix MySQL (direct) ────────────────────────────────────────────────┤
NiFi API (direct) ────────────────────────────────────────────────────┤
                                                                      ▼
                                              Amazon Managed Grafana (IAM-based access)
                                              ├── 9 migrated dashboards (live data)
                                              ├── CloudWatch native dashboards
                                              └── Zabbix dashboards (direct connection)
                                                             │
                                                             ▼
                                              DBA Team (3 active admins)

DBA_VCC_COST ──────────────────────────────► Dedicated licensed RDS instance
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
| Revoke donovan.vangraan Grafana admin access | DBA team | Zero — ex-employee, inactive since Nov 2024 |
| Create grafana_readonly service account in Zabbix MySQL | DBA / Monitoring team | Low |
| Replace donovan.vangraan credentials in all 4 Zabbix datasources | DBA team | Low — test each datasource after update |
| Disable default Grafana admin account | DBA team | Zero |
| Remove WPv2 steps from DBA_VCC_MYSQL_DAILY_CHECKS and DBA_VCC_MYSQL_AUDIT_DXM_CLIENT_DETAILED | DBA team | Zero — WPv2 confirmed decommissioned |
| Drop SP_AUDIT_WPv2_CLIENTS_DETAILED | DBA team | Zero |
| Drop 4 WPv2 linked servers (ew2p-wpv2, ew2r-wpv2, ue1p-wpv2, ue1r-wpv2) | DBA team | Zero |
| Drop 26 gen-rel + gen-prd linked servers | DBA team | Zero — platform confirmed retired |
| Drop ZabbixNonProd and ZabbixProdOld linked servers | DBA team | Zero — both confirmed dead |
| Add --sse AES256 to USP_DatabaseBackupMoveToS3 | DBA team | Low — test backup job after change |
| Fix KMS key NULL on EW1P-OCT RDS backup job | DBA team | Low |
| Confirm and delete KAPP Month End Reporting snapshot (expires 2074) | tashvir.babulal | Low — confirm recipient first |
| Notify stakeholders that DBA_VCC_COST data has been stale since 4 May 2026 | DBA team lead | Required — billing data impact |

### Phase 1 — Confirm Remaining Open Items
**Timeline: Weeks 1–2**

| Action | Owner | Blocks |
|---|---|---|
| Confirm EW2P-MSSQL-01/02 are RDS or EC2-hosted | DBA / DevOps | Determines CloudWatch replacement path |
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
| Provision Amazon Managed Grafana workspace | DevOps / DBA team | IAM-based access. Connect to CloudWatch, RDS, KAPP MySQL, NiFi API, Zabbix MySQL |
| Configure CloudWatch Agent on EW2P-MSSQL-01/02 | DevOps | Replaces 24 VCC monitoring jobs. Confirm RDS vs EC2 first |
| Set up CloudWatch dashboards for EW2P-MSSQL-01/02 | DBA team | Replaces VCC monitoring dashboards |
| Provision dedicated licensed RDS instance for DBA_VCC_COST | DevOps / DBA team | SQL Server Standard or Enterprise. FULL recovery. Proper backup and monitoring |
| Migrate DBA_VCC_COST data to new RDS instance | DBA team | 5 GB — straightforward migration. Validate all 280 client records |
| Configure AWS Backup policies for SQL Server backups | DevOps | Replace xp_cmdshell S3 sync. Encryption and retention managed natively |
| Enable RDS native automated backups for EW1P-OCT | DevOps | Replace custom backup job |

### Phase 3 — Migrate Active Grafana Dashboards
**Timeline: Weeks 6–8**

| Action | Owner | Notes |
|---|---|---|
| Migrate 9 confirmed active dashboards to Amazon Managed Grafana | DBA team | NiFi API Reporting, Database Engineering Costs, Cluster View, Historical Workload Monitoring, Query History, Detailed KAPP Workflow Stats, Release/Dev Doc Gen Run Metrics |
| Re-point KAPP UK/EU/US Prod datasources in new Grafana | DBA team | Direct MySQL connections — same IPs, new Grafana host |
| Re-point NiFi JSON API datasource in new Grafana | DBA team | 10.125.9.192:8443 — same endpoint |
| Re-point Zabbix datasources in new Grafana (direct connection) | DBA / Monitoring team | Use new grafana_readonly service account |
| Validate all migrated dashboards show live data | DBA team | Test each dashboard before retiring old Grafana |
| Notify 3 active admins of new Grafana URL | DBA team | tashvir.babulal, yogeshwar.phull, rayhaan.suleyman |
| Confirm 2 pending dashboards (KAPP Client Utilisation, BNY IIS Log Streams) | tashvir.babulal | Migrate or retire based on confirmation |
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
| Retire DBA_VCC_COST from this server | DBA team | After migration to licensed RDS confirmed |
| Detach IAM instance profile KurtosysEC2InstanceProfileRoleRep | DevOps | Confirm permissions reviewed before detaching |
| Retire Grafana contact points and alert rules | DBA team | alerts-data-operations, grafana-default-email, alert rules |
| Retire Grafana stored procedures (REP_CLIENT_CONFIG_CHANGES_REPORT, REP_CLIENT_APP_AUTH_CONFIG_CHANGES_REPORT) | DBA team | No active consumer confirmed |
| Stop S3 backup jobs | DBA team | After AWS Backup policies confirmed active |
| Confirm S3 retention policy on ksys-ew1r-db-backups before stopping | DevOps | Do not stop until retention confirmed |
| Switch off EW1R-REP-01 EC2 instance | DevOps | Final step — after all above confirmed |
| Deregister Zabbix agent from Zabbix server | Monitoring team | Zabbix will lose visibility of this server |

---

## Realistic Timeline

| Phase | What Happens | Duration | Cumulative |
|---|---|---|---|
| Phase 0 | Fix active failures — credentials, WPv2 jobs, encryption | Week 1 | Week 1 |
| Phase 1 | Confirm remaining open items | Weeks 1–2 | Week 2 |
| Phase 2 | Set up replacement infrastructure | Weeks 3–6 | Week 6 |
| Phase 3 | Migrate active Grafana dashboards | Weeks 6–8 | Week 8 |
| Phase 4 | Migrate DXM monitoring | Weeks 8–10 | Week 10 |
| Phase 5 | Decommission | Weeks 10–12 | Week 12 |

**Realistic total: 10–12 weeks from stakeholder sign-off on Phase 0.**

The critical path is Phase 2 — provisioning Amazon Managed Grafana and CloudWatch Agent on EW2P servers. Everything else can run in parallel once that infrastructure is in place.

---

## Risk Register

| Risk | Severity | Mitigation |
|---|---|---|
| EW2P-MSSQL-01/02 go dark during migration | Critical | Do not decommission VCC monitoring jobs until CloudWatch Agent confirmed active and dashboards validated |
| DBA_VCC_COST client billing data lost | Critical | Migrate to licensed RDS before retiring from this server. Validate all 280 client records after migration |
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
- [x] Decommission recommendation finalised — not safe to decommission today, 10–12 week plan defined
- [x] Handover package complete — all active failures documented with owner and next action
- [x] Migration input produced — ordered 5-phase plan with owners and dependencies
- [ ] All Confluence pages updated to reflect final classification and topology
- [ ] Handover published to Confluence and shared with migration team
