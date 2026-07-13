# TECH-3481 — Theme D: Classification & Topology — Investigation Log

Scope: Topology map, server classification, decommission decision.
Each entry has the question, the query, the evidence, and the finding.

> Status: IN PROGRESS — Themes A, B, C complete. Topology and classification produced from confirmed findings. Decommission blockers documented. Stakeholder input still required on Q13, Q21, Q22, Q23, Q35, Q36 before any decommission action.

---

## 2026-07-10 — Topology and classification produced from Themes A, B, C findings

**Question:** Based on everything confirmed in Themes A, B, and C — what does this server do, what is the classification of each component, and is it safe to decommission?

**Method:** No new queries run. All findings drawn from confirmed evidence in TECH-3478, TECH-3479, TECH-3480 investigation logs and open-questions.md. Full detail in topology-and-classification.md.

---

### What was confirmed from Theme A (TECH-3478)

| Finding | Evidence |
|---|---|
| 63 SQL Agent jobs — 52 enabled, 11 disabled | query 2.1 — sysjobs |
| 378 GB total across 7 databases — DBA_VCC_AWS actively growing | query 1.1 — sys.master_files |
| DBA_VCC_COST is the only FULL recovery database on the server | query 1.1 — recovery_model_desc |
| 109 linked servers — 11 confirmed stale, full audit still needed | query 4.1 — sys.servers |
| All 7 DBA_VCC_MEMSQL jobs disabled since May 2026 — DAILY_CHECKS failed on last run | query 2.3 — sysjobhistory |
| 4 WPv2 linked servers dead — DNS gone, 2 jobs failing silently since 25 June 2026 | query 4.2 — job failure history |
| 7 additional stale linked servers beyond WPv2 — gen-rel, gen-prd, EW2P-MARKETING-DB | query 4.2 — BASELINE_CONNECTIONS errors |
| AWS cost ETL silently broken since Sept 2024 — 2.4M rows stuck in staging, CATCH block swallows error | query 5.4 + SP_AUDIT_COST_ETL_CLEANUP definition |
| MERGE on 563M row table taking 9+ min on 30-min schedule — performance risk for migration | sys.dm_exec_requests session 67 |

---

### What was confirmed from Theme B (TECH-3479)

| Finding | Evidence |
|---|---|
| Grafana 9.5.2 on port 443 HTTPS — IP 10.72.8.216 | query 9.1 — netstat |
| 21 datasources confirmed — DBA_VCC localhost, KAPP MySQL x5, SingleStore x5, Zabbix MySQL x4, NiFi JSON API, CloudWatch, InfluxDB | query 12.6 — data_source table |
| 74 dashboards across 16 folders — 10 actively updated in 2025 | query 13.7 — dashboard table |
| 3 active admins — tashvir.babulal, yogeshwar.phull, rayhaan.suleyman (all last seen 2026) | query 9.4 — user table |
| donovan.vangraan inactive since Nov 2024 — credentials still in 4 Zabbix datasources | query 9.4 + query 12.6 |
| Default admin account still active — last seen Nov 2024, should be disabled | query 9.4 — user table |
| 3 Grafana alert rules — 2 Slack channels active, email contact point is a placeholder | query 9.7 + query 9.8 |
| Duplicate DBA_VCC datasource entries — 2 UIDs pointing to same localhost target | query 12.6 — data_source table |

---

### What was confirmed from Theme C (TECH-3480)

| Finding | Evidence |
|---|---|
| DBA_VCC_COST confirmed client billing data — 200+ real institutional clients across EW2, UE1, EC1 | query 14.3 — LU_KAPP_ClientList |
| All 9 INFO_KAPP_Client_* collection tables stale since 4 May 2026 — same day MEMSQL jobs disabled | query 14.2 — data freshness |
| Root cause confirmed — SP_INFO procedures check MEMSQL ping stats within last 40 min before collecting. With MEMSQL jobs disabled, @SERVERNAMES always empty, zero rows written, job reports Succeeded | SP_INFO_KAPP_CLIENT_ALLOCATIONS_COUNTS definition |
| 19 REP_MONTHEND procedures in DBA_VCC_COST + 14 in DBA_VCC_MEMSQL — who calls them each month end is still open | query 14.1 + query 14.5 |
| EW1R-TC confirmed TeamCity — EW2P-MARKETING-DB owner confirmed Marketing account (232173278818) | query 14.4 — LU_EntityList |
| EW1R-REP-01 tracks its own AWS costs in LU_EntityList under Reporting / Shared_Services_Non-Prod | query 14.4 — LU_EntityList |

---

### Component classification summary

Full classification table in topology-and-classification.md. Summary:

| Decision | Components |
|---|---|
| Retire | DBA_VCC_MEMSQL, all 97 SingleStore linked servers, all 7 VCC MemSQL jobs |
| Replace | DBA_VCC_AWS, DBA_VCC_MYSQL, DBA_VCC_COST, VCC AWS jobs, VCC MySQL jobs, Grafana (74 dashboards, 3 active admins) |
| Move | Active SQL Server linked servers (EW2P-MSSQL-01/02, EW1P-OCT), DBA maintenance jobs |
| Investigate | DBA_VCC_ATLASSIAN, KURTOSYS_BASELINE, Jira month-end job, EW1P-OCT backup job |

---

### Decommission blockers — confirmed from evidence, stakeholder input still needed

| # | Blocker | Who to Ask | Status |
|---|---|---|---|
| Q13 | Who owns DBA_VCC_AWS KAPP monitoring data — is it used for SLA reporting? | KAPP engineering / platform team | Open |
| Q21 | If this server went offline today, what would break immediately? | yogeshwar.phull / tashvir.babulal | Open |
| Q22 | Is any alerting dependent solely on this server? | yogeshwar.phull / tashvir.babulal | Open |
| Q23 | Is the VCC framework replicated anywhere else or is this the only instance? | DBA team | Open |
| Q35 | Who disabled DBA_VCC_MEMSQL jobs in May 2026 and why — was the DAILY_CHECKS failure ever investigated? | yogeshwar.phull / tashvir.babulal | Open |
| Q36 | Has anyone noticed DBA_VCC_COST billing data has been stale since 4 May 2026? Billing figures for May and June 2026 are wrong. | tashvir.babulal / rayhaan.suleyman | Open — must disclose |

**Finding:** This server is not safe to decommission based on current evidence. It is actively collecting production KAPP, MySQL, and AWS data, serving 74 Grafana dashboards to 3 active users, running production Slack alerts for KAPP client config and read query failures, and is the sole host of client billing data in DBA_VCC_COST. The six blockers above must be answered and actioned before any decommission work begins. Full topology and classification published in topology-and-classification.md.
