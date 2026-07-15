# Theme A — SQL Server Inventory (databases, jobs, linked servers, alerts)
# [TECH-3478](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3478)

> **Parent Epic:** TECH-3410
> **Status:** To Do

---

## Purpose

Using the SQL Server inventory completed in TECH-3560 during the TECH-3535 discovery sprint, produce a fully documented and validated SQL Server inventory for EW1R-REP-01 covering databases, SQL Agent jobs, linked servers, and alerts. Identify what is active, what is stale, what is broken, and what is safe to clean up ahead of decommission.

---

## Background

TECH-3560 completed the full SQL Server discovery — 8 databases, 378 GB, 63 jobs, 109 linked servers, and ~600+ stored procedures were inventoried and documented. 6 active failures were identified. This ticket takes those findings and produces the validated, actionable inventory that the decommission plan depends on. No decommission actions are executed here — this is inventory and validation only.

---

## What Was Found in Discovery

| Area | Finding |
|---|---|
| Databases | 8 databases, 378 GB total storage |
| SQL Agent jobs | 63 total — 52 enabled, 11 disabled |
| Linked servers | 109 total — 11 confirmed unreachable |
| Active failures | F1 — AWS cost ETL broken since Sept 2024 |
| | F2 — All 7 MemSQL jobs disabled since May 2026 |
| | F4 — 4 WPv2 linked servers dead, 2 jobs failing daily |
| | F5 — 7 additional stale linked servers beyond WPv2 |

---

## This Ticket Delivers

- Validated database inventory: name, size, recovery model, purpose, status — active, stale, or broken
- SQL Agent job inventory: name, enabled status, last run, step types, what database it feeds
- Linked server inventory: name, provider, reachability status — active, stale, or dead
- Alert inventory: SQL Agent alerts, Zabbix alerts, Slack alerts — what fires, what is misconfigured, what is silent
- Open questions from discovery answered or escalated with evidence

---

## Open Questions to Resolve in This Ticket

| # | Question | Who to Ask |
|---|---|---|
| Q1 | What SSIS packages are checked by DBA - SSISStatusCheck? Where do they run? | DBA team |
| Q3 | Is DBA - Maintenance - SQL Backup EW1P-OCT still needed? Who owns that RDS instance? | DBA team |
| Q4 | Are all 109 SingleStore linked servers still reachable or are most stale? | DBA team |
| Q5 | What credentials are used for linked server connections — where are they stored in vault? | DBA team / DevOps |
| Q28 | Which linked servers are referenced by zero job steps — true orphans safe to drop? | DBA team |
| Q29 | Which stored procedures reference the stale linked servers (WPv2, gen-rel, gen-prd)? | DBA team |
| Q30 | For each enabled job — what database does it feed and what breaks if it stops? | DBA team |
| Q31 | Why does BASELINE_CONNECTIONS still have steps for ew1d-aggr-05 and ew1d-aggr-15? | DBA team |
| Q32 | Are gen-rel and gen-prd SingleStore nodes permanently retired? | SingleStore / Platform team |

---

## Definition of Done

- [ ] All 8 databases validated: name, size, recovery model, purpose, active or stale
- [ ] All 63 SQL Agent jobs validated: enabled status, last run, step types, what it feeds
- [ ] All 109 linked servers validated: reachability confirmed, active or stale or dead
- [ ] Alert inventory complete: SQL Agent alerts, Zabbix alerts, Slack alerts documented
- [ ] All open questions from discovery answered or escalated with evidence
- [ ] Stale linked servers identified and flagged for cleanup
- [ ] Broken jobs identified and flagged for remediation
- [ ] Inventory published to Confluence

---

## Dependencies

- TECH-3560 discovery complete — all findings available in Confluence
- Stakeholder answers needed for Q4, Q28, Q30, Q32 before linked server cleanup can proceed

---

## Links

| Resource | Link |
|---|---|
| Parent epic | [TECH-3410](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3410) |
| Discovery ticket | [TECH-3535](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3535) |
| SQL Server discovery | [TECH-3560](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3560) |
| SQL Server Inventory | [View in Confluence](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6847725586/SQL+Server+Inventory+EW1R-REP-01) |
| SQL Server Investigation Log | [View in Confluence](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6848282648/SQL+Server+Investigation+Log) |
