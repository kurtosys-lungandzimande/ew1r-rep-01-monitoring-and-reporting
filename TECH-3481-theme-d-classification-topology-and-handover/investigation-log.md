# TECH-3481 — Investigation Log
**Ticket:** TECH-3481 — Theme D: Classification, Topology and Handover
**Date:** 2026-08-13
**Scope:** Consolidation of all Theme A, B, C findings into finalised classification, topology, decommission recommendation, and handover package.

---

## 2026-08-13 — Theme D consolidation from Themes A, B, C

**Method:** All findings drawn from confirmed evidence in TECH-3560 (Theme A), TECH-3561 (Theme B), TECH-3562 (Theme C), and TECH-3563 (preliminary topology). No new queries required — all open questions from TECH-3563 have been answered.

---

## What Changed Since TECH-3563 (Preliminary Topology)

TECH-3563 was written during the discovery sprint with 6 open blocker questions. All 6 have since been answered through Themes A, B, and C. The table below shows what changed.

| Question | TECH-3563 Status | TECH-3481 Status | Source |
|---|---|---|---|
| Q13 — Who owns DBA_VCC_AWS KAPP monitoring data? | Open | CLOSED — confirmed internal DBA team use. Not SLA-reporting. KAPP API data originates in CloudWatch — this server is a copy | Theme A + Theme C |
| Q21 — What breaks if server goes offline? | Open | CLOSED — 74 Grafana dashboards, EW2P-MSSQL-01/02 monitoring, KAPP billing dashboard, S3 backups, CloudWatch collection | Theme C |
| Q22 — Is any alerting solely dependent on this server? | Open | CLOSED — confirmed via Grafana UI 2026-08-12. All 3 contact points (alerts-data-operations, alert-app-allow2fa-disabled, grafana-default-email) show No attempts — none have ever fired. No active consumer | Theme C |
| Q23 — Is VCC framework replicated anywhere else? | Open | CLOSED — VCC framework unique to EW1R-REP-01. No VCC databases on EW2P-MSSQL-01/02 | Theme C |
| Q35 — Who disabled DBA_VCC_MEMSQL jobs May 2026? | Open | CLOSED — SingleStore being decommissioned. Deliberate action confirmed from timestamps (all 7 jobs disabled within 90 seconds on 2026-05-08 12:00–12:01). B3 closed | Theme B |
| Q36 — Has anyone noticed DBA_VCC_COST stale since May 2026? | Open — must disclose | CLOSED — stakeholders notified. Confirmed internal use only. Not client-facing. No disclosure risk to clients | Theme C |

---

## Classification Changes From TECH-3563

| Component | TECH-3563 Classification | TECH-3481 Classification | Reason for Change |
|---|---|---|---|
| DBA_VCC_MEMSQL | Retire (pending confirmation) | Retire — confirmed | B3 closed — SingleStore decommissioned |
| DBA_VCC_ATLASSIAN | Investigate | Retire | No writer, no consumer, frozen Dec 2023 — confirmed from job command search |
| KURTOSYS_BASELINE | Investigate | Retire | No confirmed consumer — confirmed from Grafana datasource audit |
| Jira month-end job | Investigate | Retire | DBA_VCC_ATLASSIAN frozen — job has no active consumer |
| EW1P-OCT backup job | Investigate | Move (pending C7) | Job confirmed active. Confirm if RDS native backup replaces it |
| Slack alerts | Active — 2 channels | Retire on decommission | Confirmed via Grafana UI 2026-08-12. 3 contact points: alerts-data-operations (Slack, No attempts), alert-app-allow2fa-disabled (Slack, No attempts), grafana-default-email (Email, No attempts). None have ever fired. No active consumer |
| 63 dead linked servers | 11 confirmed dead | 63 confirmed dead | Full reachability audit completed in Theme C |
| DBA_VCC_COST | Replace — consumer TBC | Replace — confirmed | Consumer confirmed internal. 280 clients confirmed. Needs licensed RDS |

---

## Topology Corrections From TECH-3563

| Item | TECH-3563 State | Corrected State |
|---|---|---|
| Client count in DBA_VCC_COST | 200+ | 280 confirmed from LU_KAPP_ClientList COUNT(*) = 280 |
| Dead linked server count | 11 confirmed | 63 confirmed dead (58% of 109) |
| SingleStore Prod UK/EU/US | Assumed reachable | Confirmed dead — 100% packet loss from ping tests |
| Slack alert consumers | 2 active channels | alerts-data-operations never fired. alert-app-allow2fa-disabled does not exist as contact point |
| IAM credential type | Unknown | EC2 instance profile KurtosysEC2InstanceProfileRoleRep — no static key on disk |
| ZabbixProdOld | Assumed dead | Confirmed dead — ping timed out 2026-08-06 |
| Grafana alert contact points | 3 active | alerts-data-operations (Slack, No attempts), alert-app-allow2fa-disabled (Slack, No attempts), grafana-default-email (Email, No attempts) — none have ever fired |
| DBA_VCC_COST stale since | Unknown | 4 May 2026 — confirmed from INFO_KAPP_Client_* table MAX(DateChecked) |

---

## Findings Summary — All Themes

| Theme | Key Findings |
|---|---|
| Theme A — SQL Server | 8 databases, 369 GB. 52 of 63 jobs enabled. 2 jobs failing daily (WPv2). DBA_VCC_COST only FULL recovery database. Developer Edition licensing risk. AWS cost ETL broken since Sept 2024 |
| Theme B — Grafana | 74 dashboards, 21 datasources, 9 users. 9 dashboards with live data and no equivalent elsewhere. 35+ retire candidates. Ex-employee credentials in 4 datasources. 3 alert rules — none have ever fired to Slack. 2 permanent public snapshot URLs |
| Theme C — External Targets | 109 linked servers — 63 dead (58%). All 6 blocker questions closed. IAM instance profile confirmed. Firewall rules documented (Windows Firewall done, AWS Security Group pending). S3 encryption gaps confirmed |
| Theme D — Classification | All components classified. 5-phase migration plan defined. 10–12 week timeline from stakeholder sign-off. 7 active failures requiring immediate action |

---

## Decommission Readiness Assessment

| Area | Ready to Decommission? | Blocker |
|---|---|---|
| EW2P-MSSQL-01/02 monitoring | No | CloudWatch Agent not yet provisioned on EW2P servers |
| Grafana dashboards | No | Amazon Managed Grafana not yet provisioned. 9 dashboards not yet migrated |
| DBA_VCC_COST | No | Licensed RDS instance not yet provisioned. Data not yet migrated |
| DXM monitoring | No | New host not yet confirmed |
| Active failures | No | 7 active failures must be fixed first (Phase 0) |
| Dead linked servers (30 safe) | Yes | Safe to drop immediately — no dependencies |
| DBA_VCC_MEMSQL | Yes | Retire — SingleStore decommissioned |
| DBA_VCC_ATLASSIAN | Yes | Retire — no consumer |
| KURTOSYS_BASELINE | Yes | Retire — no consumer |
| WPv2 linked servers | Yes | Drop immediately |
| gen-rel + gen-prd linked servers | Yes | Drop immediately |

**Overall: NOT READY. Phase 0 must start immediately. Full decommission in 10–12 weeks.**
