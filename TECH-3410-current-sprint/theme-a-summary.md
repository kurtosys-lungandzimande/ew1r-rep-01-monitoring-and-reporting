# Theme A — SQL Server Inventory Summary
# TECH-3478 — EW1R-REP-01
**Date:** 2026-07-17  
**Prepared by:** TECH-3478 Investigation  
**Server:** EW1R-REP-01 — 10.72.8.216 — eu-west-1 — Shared NonProd  
**DNS:** ew1r-rep-01.ad.shnonprd.kurtosys-internal.net / dbe-reports.shnonprd.kurtosys-internal.net  

---

## 1. Server Overview

| Property | Value |
|---|---|
| Hostname | EW1R-REP-01 |
| IP Address | 10.72.8.216 |
| Location | AWS eu-west-1 — Shared NonProd |
| SQL Server Version | 2019 (RTM-CU32-GDR) 15.0.4455.2 |
| Edition | Developer Edition (64-bit) — ⚠️ not licensed for production use |
| OS | Windows Server 2019 Datacenter |
| Collation | Latin1_General_CI_AS |
| Grafana | 9.5.2 — port 443 HTTPS |
| Purpose | Custom VCC monitoring hub — collects, stores, and serves monitoring data for KAPP, Encore, DXM, AWS infrastructure, and production SQL Servers |

---

## 2. Databases — 8 Total, 378 GB

| Database | Size | Recovery | Status | Decision |
|---|---|---|---|---|
| DBA_VCC_AWS | 182 GB | SIMPLE | ✅ Active — collecting every 30 min | ❌ Must migrate |
| DBA_VCC_MEMSQL | 75 GB | SIMPLE | ⚠️ Suspended — jobs disabled May 2026 | ⚠️ Pending Q3 |
| KURTOSYS_BASELINE | 50 GB | SIMPLE | ⚠️ Active but consumer unknown | ⚠️ Confirm consumer |
| DBA_VCC_MYSQL | 25 GB | SIMPLE | ⚠️ Partial — DXM active, WPv2 broken | ❌ Fix then migrate |
| DBA_VCC | 21 GB | SIMPLE | ✅ Active — core monitoring framework | ❌ Must migrate |
| DBA_VCC_COST | 5 GB | FULL | ✅ Active — possible client-facing | ❌ Must migrate |
| DBA_VCC_ATLASSIAN | 2 GB | SIMPLE | ⚠️ Reference only — no confirmed consumer | ⚠️ Confirm then archive |
| Utilities | 0.18 GB | SIMPLE | ✅ Active — DBA tooling | ⚠️ Migrate last |

### Key Database Findings

**DBA_VCC_AWS (182 GB)**
- Contains 563M rows in `INFO_AWS_KAPP_Query_API_Detail` — every KAPP API query ever made, actively growing
- `MON_AWS_Entity_Cost` confirmed current — last updated 2026-07-15
- `DBA_VCC_AWS_DAILY_CHECKS` reports Succeeded but at least one step is silently failing via CATCH block suppression — specific step not yet identified
- MERGE statement on 563M row unpartitioned table approaching schedule interval — performance risk

**DBA_VCC_MEMSQL (75 GB)**
- All 7 collection jobs disabled May 2026 — reason unconfirmed
- Contains KAPP workflow history (268K rows, last write 2026-05-08) and FinancialPortal client data (556K rows, last write 2026-05-08) — both were active products when jobs were disabled
- 14 Grafana dashboards showing stale data since May 2026 — nobody noticed, no alert fired
- June 2026 month-end reporting was produced from stale data

**DBA_VCC_COST (5 GB)**
- Only database on FULL recovery — deliberately set, signals production-critical data
- `KAPP Client Utilisation and Growth Report` Grafana dashboard reads from this database — name suggests client-facing
- Collection confirmed running weekly every Monday
- ⚠️ Contains institutional client billing data — BlackRock, BNY Mellon, Aberdeen, Wellington, T. Rowe Price, Nordea and others. Collection stale since 4 May 2026 — must be disclosed to stakeholders

**DBA_VCC_MYSQL (25 GB)**
- DXM side is active and healthy
- WPv2 side is broken — 2 jobs failing daily since WPv2 was decommissioned, cleanup never done

---

## 3. Product Status — Verified 2026-07-17

| Product | Status | Last Data | Key Evidence |
|---|---|---|---|
| **Encore** | ✅ Active | 2026-07-17 today | `INFO_Encore_Document_Production_Detail` collecting today. Independent of MemSQL — unaffected |
| **KAPP** | ⚠️ Suspended May 2026 | 2026-05-08 | 268K + 296K rows. `DBA_KAPP_DELETE_CREATOR` modified Nov 2024. Cut off by MemSQL job disable |
| **FinancialPortal** | ⚠️ Suspended May 2026 | 2026-05-08 | 556K rows. Most recently maintained proc Oct 2024. Cut off by MemSQL job disable |
| **InvestorPress** | ❌ Decommissioned | 2026-05-01 | 2,047 rows. Procs last modified May 2023. Zero Zabbix triggers firing |
| **WPv2** | ❌ Decommissioned | Unknown | DNS gone. 4 linked servers dead. 2 jobs failing daily. Cleanup never done |
| **DXM** | ✅ Active | 2026-07-16 | MySQL jobs running. DXM linked servers reachable |

**Critical insight:** The May 2026 MemSQL job disable cut off KAPP and FinancialPortal data collection — both active products at the time. This was not a planned product decommission. It was an unintended side effect. Nobody noticed. No alert fired.

---

## 4. SQL Agent Jobs — 63 Total

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

### Key Job Findings

**2 jobs failing daily — WPv2 root cause:**
- `DBA_VCC_MYSQL_DAILY_CHECKS` — fails at Step 5 (SP_AUDIT_WPv2_CLIENTS_DETAILED)
- `DBA_VCC_MYSQL_AUDIT_DXM_CLIENT_DETAILED` — fails at Step 2 (SP_AUDIT_WPv2_CLIENTS_DETAILED)
- Root cause: WPv2 RDS decommissioned, LU_Serverlist never updated, SP_MON_PING_STATS has xp_cmdshell commented out so all servers show Status=1 regardless of reachability, WPv2 procs attempt OPENQUERY against dead linked servers and fail
- No alert fires — no operator wired to these jobs
- Has been failing every day since WPv2 was decommissioned

**7 MemSQL jobs disabled — May 2026:**
- All disabled, last ran May 2026
- Cut off KAPP and FinancialPortal data collection
- 14 Grafana dashboards showing stale data as a result

**4 disabled DBA jobs:**
- DBA - MemSQL Range Stats Candidates — safe to drop
- DBA - UtilitiesCleanupHistoryTables — safe to drop
- DBA - ObjectIDValidationReport — investigate before dropping
- DBA - Production Logon Report — confirm if still needed

**Backup encryption gap:**
- 3 backup jobs (DIFF, FULL, LOG) sync to S3 via xp_cmdshell with no `--sse` flag
- EW1P-OCT backup job has NULL KMS key
- Backups landing in S3 unencrypted at rest

**VCC framework monitors production servers:**
- 16 VCC Audit Collection jobs + 8 VCC Server Monitoring jobs watch EW2P-MSSQL-01 and EW2P-MSSQL-02
- No secondary monitoring path exists for these servers
- Decommissioning without migrating the VCC framework leaves 2 production SQL Servers unmonitored

---

## 5. Linked Servers — 109 Total

| Group | Total | Dead | Reachable |
|---|---|---|---|
| WPv2 (decommissioned) | 4 | 4 | 0 |
| gen-rel (retired) | 5 | 5 | 0 |
| gen-prd (retired) | 21 | 21 | 0 |
| ec1p SingleStore | 14 | 6 | 8 |
| ew1d SingleStore dev | 4 | 2 | 2 |
| ew1r SingleStore release | 12 | 6 | 6 |
| ew2p SingleStore prod | 22 | 7 | 15 |
| ue1p SingleStore US prod | 12 | 6 | 6 |
| Zabbix | 3 | 2 | 1 |
| SQLNCLI SQL Server | 6 | 1 | 5 |
| Clickhouse (pmmdev/pmmprod) | 2 | 0 | 2 |
| Other (EW1R-TC, EW1P-NIFIREG-01) | 2 | 0 | 2 |
| **Total** | **109** | **63** | **46** |

**58% of linked servers are dead.** Discovery originally reported 11 dead — actual count is 63.

### Key Linked Server Findings
- **30 confirmed safe to drop immediately** — WPv2 (4), gen-rel (5), gen-prd (21) all confirmed decommissioned
- **33 dead SingleStore nodes** — partial node failures across ec1p, ew1d, ew1r, ew2p, ue1p — confirm with Platform team then drop
- **ew1p-oct short hostname** — dead orphan, job uses full RDS hostname which is reachable
- **ZabbixNonProd and ZabbixProdOld** — both dead, safe to drop
- **EW1R-TC and EW1P-NIFIREG-01** — reachable but purpose unknown
- **pmmdev and pmmprod (Clickhouse)** — reachable but purpose unknown, not in original discovery

---

## 6. SQL Agent Alerts — 16 Total, All Silent

| Item | Finding |
|---|---|
| Total alerts | 16 — all enabled |
| Operators configured | 1 — dba@kurtosys.com |
| Alerts wired to operator | 0 |
| Net result | Alert system fully silent — nothing will ever fire |

- 5 AG alerts (1480, 35264, 35265, 41404, 41405) are irrelevant — this server has no AG
- Severity 19–25 and IO error alerts are configured but unwired — fatal errors go unnoticed
- Fix: wire dba@kurtosys.com to all relevant alerts — 5-minute fix in SSMS

---

## 7. Zabbix Alerts

| Item | Finding |
|---|---|
| Zabbix instance | ZabbixProdNew — MariaDB 10.6.22 |
| Total monitored hosts | 30 |
| Active hosts | 21 |
| Disabled hosts (not removed) | 9 — gen-prd nodes + WPv2 |
| Triggers currently firing | 3 — MSSQL errorlog on ew2p-mssql-01/02, missing backups, KAPP backup integrity |
| Notification channels | 8 — Email, Opsgenie, Slack, SMS, Jabber active. OpsGenie-Plugin, Slack-Script, incident.io disabled |

**Critical finding: EW1R-REP-01 is not in Zabbix.** The server being investigated has no external monitoring. If it goes down, nothing alerts.

**3 live alerts firing on production systems** — MSSQL errorlog errors on both EW2P-MSSQL-01 and EW2P-MSSQL-02. Unknown if being actioned.

---

## 8. Slack Alerts

| Item | Finding |
|---|---|
| Direct Slack posting from this server | None — fully disabled |
| SlackChatPostMessage calls | All commented out across all stored procedures |
| Current Slack notification method | Zabbix webhook only |

- All Slack notification code replaced by Zabbix table writes — Zabbix fires Slack via webhook
- 4 stored procs reference dead linked servers (P23-P-AGGR-201, p23-p-aggr-301) — dead procs, safe to drop
- SPSlackCheckSyncStatus is dormant — no live MemSQL data to compare against

---

## 9. Active Problems — Fix Now, Independent of Decommission

These exist today and need fixing regardless of decommission decision:

| # | Problem | Impact | Owner |
|---|---|---|---|
| P1 | 2 jobs failing daily — WPv2 cleanup never done | Silent failures, DXM data collection incomplete | DBA team |
| P2 | 14 Grafana dashboards showing stale data since May 2026 | June 2026 month-end reporting impacted silently | tashvir.babulal / yogeshwar.phull |
| P3 | DBA_VCC_COST billing data stale since 4 May 2026 | Institutional client invoicing data is 2+ months out of date | tashvir.babulal / rayhaan.suleyman |
| P4 | SQL Agent alert system fully silent | Fatal errors, IO failures go unnoticed | DBA team |
| P5 | MSSQL errorlog alerts firing on ew2p-mssql-01/02 | Live production alerts — unknown if actioned | DBA team |
| P6 | Missing backups and KAPP backup integrity check firing in Zabbix | Live production alerts | DBA team |
| P7 | Backup jobs syncing to S3 with no encryption | Compliance risk — unencrypted backups at rest | DBA team / DevOps |
| P8 | EW1R-REP-01 not in Zabbix | Server has no external monitoring | Monitoring team |
| P9 | Ping stats showing false positives | xp_cmdshell commented out — all servers show Status=1 | DBA team |

---

## 10. Decommission Readiness — Retire / Replace / Move

### ✅ Safe to Retire (Drop / Archive)

| Component | Reason |
|---|---|
| 63 dead linked servers | Confirmed dead — WPv2, gen-rel, gen-prd, partial SingleStore nodes |
| InvestorPress procs and tables | Confirmed decommissioned — procs last modified 2023, 2,047 rows, zero Zabbix triggers |
| WPv2 stored procedures | Confirmed decommissioned — SP_AUDIT_WPv2_CLIENTS_DETAILED and related |
| 4 disabled DBA jobs | MemSQL range stats, utilities cleanup — no longer relevant |
| DBA_VCC_MEMSQL (75 GB) | Pending Q3 — archive to S3 then drop once MemSQL status confirmed |
| DBA_VCC_ATLASSIAN (2 GB) | Pending confirmation — no stored procs, no confirmed consumer |

### ❌ Must Replace or Migrate

| Component | Migration Option | Complexity |
|---|---|---|
| VCC monitoring framework (24 jobs) | New EC2 or existing SQL Server in same VPC | High — 4–6 weeks |
| DBA_VCC_AWS (182 GB) | Replace with CloudWatch + AWS native observability, or migrate to new EC2 | High |
| DBA_VCC_COST (5 GB) | Migrate to new host or replace with AWS Cost Explorer | Medium |
| DBA_VCC (21 GB) — Encore monitoring | Migrate with VCC framework | Medium |
| DBA_VCC_MYSQL — DXM side | Fix WPv2 failures first, then migrate | Medium |
| Grafana (74 dashboards) | Amazon Managed Grafana or new EC2 host | High — TECH-3479 scope |
| EW1P-OCT backup job | Replace with native RDS automated backups | Low |

### ⚠️ Investigate Before Deciding

| Component | Blocker |
|---|---|
| DBA_VCC_MEMSQL (75 GB) | Q3 — were KAPP and FinancialPortal decommissioned in May 2026? |
| KURTOSYS_BASELINE (50 GB) | Who reads this data — is it used for capacity planning? |
| EW1R-TC linked server | Purpose unknown |
| EW1P-NIFIREG-01 linked server | Purpose unknown |
| pmmdev / pmmprod (Clickhouse) | Purpose unknown, not in original discovery |

---

## 11. The 6 Questions That Block the Decommission Date

| # | Question | Ask | Why It Blocks |
|---|---|---|---|
| Q1 | Is KAPP Client Utilisation and Growth Report client-facing? | tashvir.babulal / rayhaan.suleyman | Client impact assessment required before migration |
| Q2 | Who consumes DBA_VCC_COST data — internal or external? | tashvir.babulal / rayhaan.suleyman | Determines migration urgency and handover owner |
| Q3 | Why were MemSQL jobs disabled in May 2026 — were KAPP and FinancialPortal decommissioned at the same time? | yogeshwar.phull / tashvir.babulal | Determines fate of 75 GB of data and 2 suspended products |
| Q4 | Who consumes VCC monitoring data for EW2P-MSSQL-01/02? | DBA team | Determines who owns the monitoring migration |
| Q5 | What is the migration plan for VCC monitoring post-decommission? | DBA team | Hardest technical dependency — no decommission without this |
| Q6 | Who consumes KAPP API and AWS data from DBA_VCC_AWS? | tashvir.babulal / rayhaan.suleyman | 182 GB actively collected — needs confirmed new home |

---

## 12. Proposed Resolution — In Order

**Phase 1 — Fix active failures now (1–2 days)**
1. Remove WPv2 steps from 2 failing jobs
2. Wire dba@kurtosys.com to SQL Agent alerts
3. Add EW1R-REP-01 to Zabbix monitoring
4. Fix S3 backup encryption — add `--sse aws:kms` to sync command
5. Investigate and resolve live Zabbix alerts on ew2p-mssql-01/02
6. Disclose DBA_VCC_COST billing data staleness to tashvir.babulal / rayhaan.suleyman

**Phase 2 — Answer the 6 blocking questions (1–2 weeks)**
1. Confirm DBA_VCC_COST consumer and client-facing dashboard status
2. Confirm MemSQL jobs disable reason — KAPP and FinancialPortal status
3. Confirm VCC monitoring migration owner and target

**Phase 3 — Clean up confirmed dead components (2–3 days)**
1. Drop 63 dead linked servers
2. Drop InvestorPress and WPv2 stored procedures
3. Drop 4 disabled DBA jobs
4. Archive DBA_VCC_MEMSQL to S3 then drop (pending Q3)

**Phase 4 — Migrate active workloads (4–8 weeks)**
1. Migrate VCC monitoring framework to new EC2 or existing SQL Server in AWS
2. Migrate or replace DBA_VCC_AWS — CloudWatch vs SQL Server migration decision
3. Migrate DBA_VCC_COST to new host with confirmed handover owner
4. Migrate Grafana — Amazon Managed Grafana or new EC2 (TECH-3479 scope)
5. Replace EW1P-OCT backup job with native RDS automated backups

**Phase 5 — Decommission (1 day)**
Only after Phase 1–4 complete and signed off by manager.

---

## 13. Estimated Timeline

| Phase | Effort | Owner |
|---|---|---|
| Phase 1 — Fix active failures | 1–2 days | DBA team |
| Phase 2 — Answer blocking questions | 1–2 weeks | Stakeholders |
| Phase 3 — Clean up dead components | 2–3 days | DBA team |
| Phase 4 — Migrate active workloads | 4–8 weeks | DBA team + Platform team |
| Phase 5 — Decommission | 1 day | DBA team + DevOps |

**Realistic earliest decommission date: 10–12 weeks from stakeholder answers being received.**

---

## 14. Open Questions Summary

| Priority | Count | Key Questions |
|---|---|---|
| Critical — blocks decommission | 6 | Q1–Q6 above |
| High — active failures | 6 | Zabbix live alerts, backup encryption, silent job failures |
| Medium — cleanup blockers | 10 | Unknown linked servers, stale server list, ping stats |
| Low — housekeeping | 2 | incident.io, Jabber |
| **Answered** | **7** | gen-rel/gen-prd retired, cost schedule confirmed, InvestorPress dead, Encore active, KAPP/FP suspended |

---

## 15. Documents Produced — TECH-3478

| Document | Location |
|---|---|
| Database inventory | `TECH-3410-current-sprint/database-inventory.md` |
| Job inventory | `TECH-3410-current-sprint/job-inventory.md` |
| Linked server inventory | `TECH-3410-current-sprint/linked-server-inventory.md` |
| SQL Agent alert inventory | `TECH-3410-current-sprint/sql-agent-alerts.md` |
| Zabbix alert inventory | `TECH-3410-current-sprint/zabbix-alert-inventory.md` |
| Slack alert inventory | `TECH-3410-current-sprint/slack-alert-inventory.md` |
| Open questions tracker | `TECH-3410-current-sprint/open-questions.md` |
| Decommission readiness | `TECH-3410-current-sprint/decommission-readiness.md` |
| This summary | `TECH-3410-current-sprint/theme-a-summary.md` |
