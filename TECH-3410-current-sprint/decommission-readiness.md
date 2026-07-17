# Decommission Readiness — EW1R-REP-01
**Ticket:** TECH-3478 — Theme A SQL Server Inventory  
**Date:** 2026-07-17 (updated with product status verification)  
**Prepared by:** TECH-3478 Investigation  

---

## The One-Line Answer

> **EW1R-REP-01 is not safe to decommission today.**  
> 6 stakeholder questions must be answered first, and 4 active workloads must be migrated before the server can be switched off.  
> The May 2026 MemSQL job disable silently cut off 2 active products — KAPP and FinancialPortal. Nobody noticed.

---

## Product Status — Verified 2026-07-17

Each product was verified by checking last data write dates, stored procedure modification dates, job status, and Zabbix trigger state.

| Product | Status | Last Data Written | Evidence |
|---|---|---|---|
| **Encore** | ✅ Active | 2026-07-17 today | `DBA_VCC_DAILY_CHECKS` running, data collecting today. Independent of MemSQL — unaffected by May 2026 disable |
| **KAPP** | ⚠️ Suspended since May 2026 | 2026-05-08 | `DBA_KAPP_DELETE_CREATOR` modified Nov 2024. 268K + 296K rows. Cut off when MemSQL jobs disabled |
| **FinancialPortal** | ⚠️ Suspended since May 2026 | 2026-05-08 | `SP_AUDIT_FP_Client_ApplicationConfiguration_Auth_DETAILED` modified Oct 2024 — most recently maintained proc on server. 556K rows. Cut off when MemSQL jobs disabled |
| **InvestorPress** | ❌ Decommissioned | 2026-05-01 | Procs untouched since May 2023. Only 2,047 rows. Zero Zabbix triggers firing. Confirmed dead |
| **WPv2** | ❌ Decommissioned | Unknown | DNS gone, 4 linked servers dead, 2 jobs failing daily. Cleanup never done |
| **DXM** | ✅ Active | 2026-07-16 | MySQL jobs running and succeeding. DXM linked servers reachable |

**Critical insight:** The May 2026 MemSQL job disable did not just stop MemSQL monitoring — it cut off KAPP workflow history and FinancialPortal client data collection. Both products were being actively maintained in 2024. This was not a planned decommission of those products — it was an unintended side effect of disabling the jobs.

---

## What This Server Actually Does

Before talking about decommission, it helps to understand what the server is doing right now:

1. **Monitors 2 production SQL Servers** — EW2P-MSSQL-01 and EW2P-MSSQL-02 via 24 SQL Agent jobs running daily. No other monitoring path exists for these servers.
2. **Tracks every KAPP API query** — 563 million rows and growing. Every KAPP API call is logged here.
3. **Hosts cost tracking for KAPP clients** — DBA_VCC_COST is on FULL recovery, meaning someone deliberately treated this data as production-critical. A Grafana dashboard called "KAPP Client Utilisation and Growth Report" reads from it — possibly client-facing.
4. **Runs Grafana** — 74 dashboards, 21 datasources, all hosted on this server.
5. **Backs up EW1P-OCT RDS** — daily backup job running to S3.
6. **Was collecting KAPP workflow history and FinancialPortal client data** — until May 2026 when the MemSQL jobs were disabled. Both products were active at that point.

---

## The 40 / 40 / 20 Split

Think of the server's components in three buckets:

### 40% — Can be cleaned up now, low risk
These are confirmed dead or broken with no active consumer:

- **63 dead linked servers** — WPv2 decommissioned, gen-rel/gen-prd retired, partial SingleStore nodes gone. Safe to drop after Platform team confirms gen-rel/gen-prd retirement.
- **InvestorPress stored procedures and tables** — confirmed decommissioned. Procs last modified 2023, 2,047 rows, zero Zabbix triggers. Safe to drop immediately.
- **WPv2 stored procedures and linked servers** — confirmed decommissioned. SP_AUDIT_WPv2_CLIENTS_DETAILED and 4 dead linked servers. Safe to drop immediately.
- **4 disabled DBA jobs** — MemSQL range stats, utilities cleanup, stale reports. Safe to drop.
- **63 dead linked servers** — WPv2, gen-rel, gen-prd, partial SingleStore nodes. Safe to drop.
- **7 disabled MemSQL jobs** — ⚠️ Cannot drop yet. Confirmed that KAPP and FinancialPortal data collection was cut off by this disable. Need Q3 answered first.
- **DBA_VCC_MEMSQL (75 GB)** — ⚠️ Cannot archive yet. Contains KAPP workflow history (268K rows) and FinancialPortal client data (556K rows) — both products were active until May 2026.
- **DBA_VCC_ATLASSIAN (2 GB)** — no stored procs, no confirmed writer or reader. Likely safe to archive.

### 40% — Must be migrated before decommission
These are active workloads that will break if the server is switched off:

- **VCC monitoring framework** — 24 jobs (16 audit + 8 server monitoring) watching EW2P-MSSQL-01 and EW2P-MSSQL-02. This is the hardest migration — the entire VCC framework needs a new home.
- **Encore monitoring** — `DBA_VCC_DAILY_CHECKS` collecting Encore document production data today. Feeds active Grafana dashboards. Must migrate with VCC framework.
- **DBA_VCC_AWS (182 GB)** — KAPP API query tracking, NiFi pipeline monitoring, EC2/RDS inventory. Actively collecting every 30 minutes.
- **DBA_VCC_COST (5 GB)** — cost tracking per KAPP client. FULL recovery model. Possible client-facing dashboard. Must be migrated with a confirmed handover owner.
- **DBA_VCC_MYSQL — DXM side (25 GB)** — DXM client monitoring is active and healthy. WPv2 side is broken and needs cleanup first, then DXM needs a migration target.
- **Grafana (74 dashboards)** — covered under TECH-3479, but the datasources point to databases on this server. Grafana cannot be migrated until the databases are migrated first.
- **EW1P-OCT backup job** — daily RDS backup to S3. Needs a new host or needs to be replaced with native RDS backup.

### 20% — Unknown, needs investigation before deciding
These cannot be classified until stakeholder questions are answered:

- **KURTOSYS_BASELINE (50 GB)** — collecting baselines for systems that are mostly dead. No confirmed consumer. Could be drop or migrate depending on who reads it.
- **4 linked servers with unknown purpose** — EW1R-TC, EW1P-NIFIREG-01, pmmdev (Clickhouse), pmmprod (Clickhouse). All reachable. Purpose unknown.
- **DBA_VCC — inactive server entries** — EW1D-MSSQL-01 and ew1r-mssql-01 still in LU_Serverlist. Need confirmation they are retired before removing.

---

## The 6 Questions That Block the Decommission Date

No decommission date can be set until these are answered:

| # | Question | Ask | Why It Blocks |
|---|---|---|---|
| 1 | Is KAPP Client Utilisation and Growth Report client-facing? | tashvir.babulal / rayhaan.suleyman | If yes — client impact assessment required before any migration |
| 2 | Who consumes DBA_VCC_COST data — internal or external? | tashvir.babulal / rayhaan.suleyman | Determines migration urgency and handover owner |
| 3 | Why were MemSQL jobs disabled in May 2026 — decommission, migration, or pause? | yogeshwar.phull / tashvir.babulal | **Now more critical** — confirmed that KAPP (268K rows, procs maintained Nov 2024) and FinancialPortal (556K rows, procs maintained Oct 2024) were both actively collecting until the disable. Were those products decommissioned at the same time or is that data still needed? |
| 4 | Who consumes VCC monitoring data for EW2P-MSSQL-01/02? | DBA team | Determines who owns the migration of the monitoring framework |
| 5 | What is the migration plan for VCC monitoring post-decommission? | DBA team | The hardest technical dependency — no decommission without this |
| 6 | Who consumes KAPP API and AWS data from DBA_VCC_AWS? | tashvir.babulal / rayhaan.suleyman | 182 GB of actively collected data needs a confirmed new home |

---

## Active Problems Found — Independent of Decommission

These exist right now and need fixing regardless of whether the server is decommissioned:

| Problem | Impact | Owner |
|---|---|---|
| 2 SQL Agent jobs failing daily | WPv2 cleanup never done — silent failures since 2022 | DBA team |
| 14 Grafana dashboards showing stale data since May 2026 | June 2026 month-end reporting was impacted silently | tashvir.babulal / yogeshwar.phull |
| MSSQL errorlog alerts firing on ew2p-mssql-01 and ew2p-mssql-02 | Live production alerts — unknown if being actioned | DBA team |
| Missing backups and KAPP backup integrity check firing in Zabbix | Live production alerts | DBA team |
| SQL Agent alert system fully silent | 16 alerts configured, operator exists, nothing wired — no alerts will ever fire | DBA team |
| Backup jobs syncing to S3 with no encryption | Compliance risk — 3 jobs, no --sse flag, EW1P-OCT KMS key NULL | DBA team / DevOps |
| EW1R-REP-01 not in Zabbix | Server has no external monitoring — if it goes down, nothing alerts | Monitoring team |
| Ping stats showing false positives | xp_cmdshell commented out — all servers show Status=1 regardless of reachability | DBA team |

---

## Decommission Readiness by Component

| Component | Count / Size | Status | Decision |
|---|---|---|---|
| Dead linked servers | 63 | Confirmed dead | ✅ Drop — low risk |
| InvestorPress procs and tables | ~10 procs, 2K rows | Confirmed decommissioned | ✅ Drop — confirmed dead |
| WPv2 procs and linked servers | 4 servers, ~5 procs | Confirmed decommissioned | ✅ Drop — confirmed dead |
| Disabled DBA jobs | 4 | Stale, MemSQL-related | ✅ Drop |
| Disabled MemSQL jobs | 7 | Suspended May 2026 | ⚠️ Pending Q3 — KAPP and FP data may still be needed |
| DBA_VCC_MEMSQL | 75 GB | Suspended May 2026 | ⚠️ Pending Q3 — contains active product data |
| DBA_VCC_ATLASSIAN | 2 GB | No confirmed consumer | ⚠️ Confirm then archive |
| Unknown linked servers | 4 servers | Purpose unknown | ⚠️ Investigate first |
| KURTOSYS_BASELINE | 50 GB | Purpose unclear | ⚠️ Confirm consumer first |
| Active monitoring jobs | 24 | Watching production servers | ❌ Must migrate first |
| Encore monitoring | Active today | Collecting today | ❌ Must migrate first |
| KAPP / AWS data collection | 182 GB | Actively collecting | ❌ Must migrate first |
| Cost tracking | 5 GB | FULL recovery, possible client-facing | ❌ Must migrate first |
| DXM monitoring | 25 GB | Active, healthy | ❌ Must migrate first |
| Grafana | 74 dashboards | Active, some stale | ❌ Must migrate first (TECH-3479) |

---

## What Needs to Happen — In Order

**Phase 1 — Fix active failures (do now, independent of decommission)**
1. Remove WPv2 steps from 2 failing jobs
2. Wire dba@kurtosys.com operator to SQL Agent alerts
3. Add EW1R-REP-01 to Zabbix monitoring
4. Fix S3 backup encryption gap
5. Investigate and resolve live Zabbix alerts on ew2p-mssql-01/02

**Phase 2 — Answer the 6 blocking questions**
1. Confirm DBA_VCC_COST consumer and client-facing dashboard status
2. Confirm MemSQL jobs disable reason
3. Confirm VCC monitoring migration owner and target

**Phase 3 — Clean up confirmed dead components**
1. Drop 63 dead linked servers
2. Drop 7 MemSQL jobs
3. Archive DBA_VCC_MEMSQL to S3 then drop
4. Drop dead stored procedures

**Phase 4 — Migrate active workloads**
1. Migrate VCC monitoring framework to a new host
2. Migrate DBA_VCC_AWS and DBA_VCC_COST to new host or RDS
3. Migrate Grafana (TECH-3479 scope)
4. Migrate EW1P-OCT backup job

**Phase 5 — Decommission**
Only after Phase 1–4 are complete and signed off.

---

## Estimated Effort

| Phase | Effort | Who |
|---|---|---|
| Phase 1 — Fix active failures | 1–2 days | DBA team |
| Phase 2 — Answer blocking questions | 1–2 weeks | Stakeholders |
| Phase 3 — Clean up dead components | 2–3 days | DBA team |
| Phase 4 — Migrate active workloads | 4–8 weeks | DBA team + Platform team |
| Phase 5 — Decommission | 1 day | DBA team + DevOps |

**Realistic earliest decommission date: 10–12 weeks from stakeholder answers being received.**
