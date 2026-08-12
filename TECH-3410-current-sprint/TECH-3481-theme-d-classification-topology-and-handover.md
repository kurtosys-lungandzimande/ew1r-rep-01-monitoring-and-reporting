# Theme D — Classification, Topology Diagram and Handover
# [TECH-3481](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3481)

> **Parent Epic:** TECH-3410
> **Status:** In Progress
> **Working folder:** TECH-3481-theme-d-classification-topology-and-handover/
> **All 6 original blocker questions closed. Classification finalised. Migration plan defined. 2 DoD items remaining: Confluence publishing.**

---

## Purpose

Using the classification and topology work completed in TECH-3563 during the TECH-3535 discovery sprint, produce a finalised component classification, a validated topology diagram, and a complete handover package for EW1R-REP-01. This ticket is the final output of the Phase 2 sprint — it consolidates findings from Themes A, B, and C into a single decommission-ready picture and hands it over to the team responsible for migration and replacement planning.

---

## What Was Found in Discovery (TECH-3563)

| Component | Classification | Reason |
|---|---|---|
| DBA_VCC_AWS (KAPP monitoring) | Replace | Core KAPP observability — cannot retire |
| DBA_VCC_MYSQL (MySQL monitoring) | Replace | Active MySQL/RDS monitoring |
| DBA_VCC_COST (Cost tracking) | Replace | Confirmed client billing — 280 clients |
| DBA_VCC_MEMSQL (MemSQL monitoring) | Retire | All 7 jobs disabled since May 2026 — SingleStore decommissioned |
| DBA_VCC_ATLASSIAN (Jira integration) | Retire | No writer, no consumer, frozen Dec 2023 |
| KURTOSYS_BASELINE | Retire | No confirmed consumer |
| SingleStore linked servers (63 dead) | Retire | Platform decommissioned |
| SQL Server linked servers (active) | Move | Still needed for EW2P monitoring |
| Grafana dashboards (74) | Replace / Move / Retire | 9 active, 35+ retire candidates, 4 replaceable by AWS/Zabbix |
| VCC AWS jobs | Replace | Move to CloudWatch / native AWS monitoring |
| VCC MemSQL jobs | Retire | All disabled — SingleStore decommissioned |
| DBA Maintenance jobs | Move | Needed on any replacement host |

---

## Blocker Questions — All Closed

| # | Question | Status |
|---|---|---|
| Q13 | Who owns DBA_VCC_AWS KAPP monitoring data? | CLOSED — internal DBA team use. Not SLA-reporting |
| Q21 | If this server went offline today, what would break? | CLOSED — 74 Grafana dashboards, EW2P-MSSQL-01/02 monitoring, KAPP billing dashboard, S3 backups, CloudWatch collection |
| Q22 | Is any alerting solely dependent on this server? | CLOSED — alerts-data-operations never fired. alert-app-allow2fa-disabled does not exist. No active consumer |
| Q23 | Is VCC framework replicated anywhere else? | CLOSED — unique to EW1R-REP-01. No VCC databases on EW2P-MSSQL-01/02 |
| Q35 | Who disabled DBA_VCC_MEMSQL jobs May 2026? | CLOSED — SingleStore decommissioned. Deliberate action confirmed from timestamps |
| Q36 | Has anyone noticed DBA_VCC_COST stale since May 2026? | CLOSED — stakeholders notified. Internal use only. No client disclosure risk |

---

## This Ticket Delivers

- [x] Finalised component classification — all components confirmed as Replace, Retire, Move, or Confirm
- [x] Validated topology diagram — dead targets removed, confirmed consumers added, active data flows confirmed
- [x] Decommission recommendation — not safe today, 10–12 week migration plan defined
- [x] Handover package — all active failures documented with owner and next action
- [x] Migration input — ordered 5-phase plan with owners, dependencies, and timeline
- [ ] All Confluence pages updated to reflect final classification and topology
- [ ] Handover published to Confluence and shared with migration team

> **Status:** 6 of 8 DoD items complete. 2 remaining: Confluence publishing.

---

## Active Failures — Must Fix Now (Phase 0)

| # | Failure | Owner | Action |
|---|---|---|---|
| F1 | DBA_VCC_MYSQL jobs failing daily since 25 June 2026 | DBA team | Remove WPv2 steps. Drop SP_AUDIT_WPv2_CLIENTS_DETAILED. Drop 4 WPv2 linked servers |
| F2 | DBA_VCC_COST data stale since 4 May 2026 — 280 client billing records | DBA team lead | Stakeholders notified. Replacement pipeline needed |
| F3 | AWS cost ETL broken since Sept 2024 | DBA team | Identify failing step. Fix or retire — AWS Cost Explorer replaces this |
| F4 | donovan.vangraan credentials in 4 Grafana datasources | DBA team | Revoke Grafana admin. Create grafana_readonly service account |
| F5 | Default Grafana admin account active | DBA team | Disable immediately |
| F6 | S3 backup encryption gaps | DBA team | Add --sse AES256. Fix KMS key NULL on EW1P-OCT backup |
| F7 | KAPP Month End Reporting snapshot — permanent public URL (expires 2074) | tashvir.babulal | Confirm recipient. Delete if no longer needed |

---

## Migration Plan Summary

| Phase | What Happens | Timeline |
|---|---|---|
| Phase 0 | Fix active failures — credentials, WPv2 jobs, encryption, dead linked servers | Week 1 |
| Phase 1 | Confirm remaining open items (EW2P hosting type, AWS Security Group, pmmdev/pmmprod, etc.) | Weeks 1–2 |
| Phase 2 | Set up replacement infrastructure (Amazon Managed Grafana, CloudWatch Agent, licensed RDS for DBA_VCC_COST, AWS Backup) | Weeks 3–6 |
| Phase 3 | Migrate 9 active Grafana dashboards to Amazon Managed Grafana | Weeks 6–8 |
| Phase 4 | Migrate DXM monitoring to new host | Weeks 8–10 |
| Phase 5 | Decommission — retire databases, drop linked servers, switch off server | Weeks 10–12 |

**Realistic total: 10–12 weeks from stakeholder sign-off on Phase 0.**

---

## Items Still Requiring Confirmation

| # | Item | Who to Ask |
|---|---|---|
| C1 | AWS Security Group rules for EW1R-REP-01 | DevOps |
| C2 | KAPP Month End Reporting snapshot recipient (expires 2074) | tashvir.babulal |
| C3 | Database Engineering Sprint Reporting snapshot recipient (expires 2073) | tashvir.babulal |
| C4 | pmmdev and pmmprod (Clickhouse) purpose and owner | DBA / Platform team |
| C5 | ew1d-admin-01/02 permanently retired? | DBA team |
| C6 | What SSIS packages does DBA - SSISStatusCheck monitor? | DBA team |
| C7 | EW1P-OCT RDS backup job still needed post-decommission? | DBA team |
| C8 | EW2P-MSSQL-01/02 — RDS or EC2-hosted? | DBA / DevOps |

---

## Dependencies

- Themes A, B, and C (TECH-3478, TECH-3479, TECH-3480) complete — all findings incorporated
- Phase 0 must start immediately — active failures are independent of decommission timeline
- Phase 2 requires DevOps to provision Amazon Managed Grafana and confirm EW2P hosting type
- Phase 3 requires 3 active Grafana admins to validate migrated dashboards before old Grafana is retired

---

## Links

| Resource | Link |
|---|---|
| Parent epic | [TECH-3410](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3410) |
| Discovery ticket | [TECH-3535](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3535) |
| Topology & Classification discovery | [TECH-3563](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3563) |
| Theme A — SQL Server Inventory | [TECH-3478](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3478) |
| Theme B — Grafana Inventory | [TECH-3479](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3479) |
| Theme C — External Targets and Consumers | [TECH-3480](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3480) |
| Topology & Classification | [View in Confluence](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6860963905/Topology+Classification+EW1R-REP-01) |
| Topology Investigation Log | [View in Confluence](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6860243025/Topology+-+Investigaton+Log) |
