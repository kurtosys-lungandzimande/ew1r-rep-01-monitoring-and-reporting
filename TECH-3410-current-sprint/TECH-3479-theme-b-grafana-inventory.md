# Theme B — Grafana Inventory (datasources, dashboards, users, alert rules)
# [TECH-3479](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3479)

> **Parent Epic:** TECH-3410
> **Status:** To Do

---

## Purpose

Using the Grafana inventory completed in TECH-3561 during the TECH-3535 discovery sprint, produce a fully documented and validated Grafana inventory for EW1R-REP-01 covering datasources, dashboards, users, and alert rules. Identify what is active, what is stale, what is broken, and what must be migrated or replaced ahead of decommission.

---

## Background

TECH-3561 completed the full Grafana discovery — 21 datasources, 74 dashboards, 8 users (3 active admins, 2 inactive), and 3 alert rules were inventoried and documented. Several critical issues were identified: 14 dashboards showing stale data since May 2026, 4 Zabbix datasources using ex-employee credentials, a duplicate DBA_VCC datasource entry, and a broken email contact point. This ticket takes those findings and produces the validated, actionable inventory that the decommission plan depends on. No decommission actions are executed here — this is inventory and validation only.

---

## What Was Found in Discovery

| Area | Finding |
|---|---|
| Datasources | 21 datasources — DBA_VCC has 2 entries with different UIDs, dashboards split across both |
| Dashboards | 74 total — 14 reading from DBA_VCC_MEMSQL showing stale data since May 2026 |
| | 6 month-end dashboards (KAPP, Encore, DXM, InvestorPress, WPv2, Other Services) with no fresh data since May 2026 |
| | 4 dashboards reading from DBA_VCC_COST — KAPP Client Utilisation and Growth Report may be client-facing |
| Users | 8 users — 3 active admins (tashvir.babulal, yogeshwar.phull, rayhaan.suleyman), 2 inactive, default admin still active |
| Alert rules | 3 alert rules, 3 contact points — email contact point is a placeholder and will never deliver |
| Credentials | 4 Zabbix datasources using ex-employee account inactive since Nov 2024 |

---

## This Ticket Delivers

- Validated datasource inventory: name, UID, type, target database, status — active, stale, or broken
- Dashboard inventory: name, folder, datasource(s) used, last updated, status — active, stale, or broken
- User inventory: username, role, last login, status — active or inactive
- Alert rule inventory: rule name, contact point, what it fires on, whether it is functional
- Duplicate DBA_VCC datasource UID conflict documented and resolution proposed
- Ex-employee Zabbix credentials flagged for rotation
- Open questions from discovery answered or escalated with evidence

---

## Open Questions to Resolve in This Ticket

| # | Question | Who to Ask |
|---|---|---|
| Q9 | Which teams use the Grafana dashboards — engineering, ops, client-facing? | tashvir.babulal / rayhaan.suleyman |
| Q13 | Who owns the KAPP monitoring data in DBA_VCC_AWS? Is it used for SLA reporting? | KAPP engineering / platform team |
| Q14 | Is INFO_AWS_KAPP_Query_API_Detail (583M rows) actively read by any dashboard? | tashvir.babulal |
| Q21 | If this server went offline today, what would break immediately? | yogeshwar.phull / tashvir.babulal |
| Q22 | Is any alerting dependent solely on this server — would anyone lose visibility? | yogeshwar.phull / tashvir.babulal |
| Q35 | Who disabled the DBA_VCC_MEMSQL jobs in May 2026 and why? | yogeshwar.phull / tashvir.babulal |
| Q36 | Has anyone noticed that DBA_VCC_COST billing data has been stale since 4 May 2026? | tashvir.babulal / rayhaan.suleyman |

---

## Definition of Done

- [ ] All 21 datasources validated: name, UID, type, target, active or stale or broken
- [ ] All 74 dashboards validated: datasource(s) used, last updated, active or stale or broken
- [ ] All 8 users validated: role, last login, active or inactive
- [ ] All 3 alert rules validated: contact point, what it fires on, functional or broken
- [ ] Duplicate DBA_VCC UID conflict documented with proposed resolution
- [ ] Ex-employee Zabbix credentials flagged for rotation with evidence
- [ ] Default admin account flagged for disabling
- [ ] All open questions from discovery answered or escalated with evidence
- [ ] Inventory published to Confluence

---

## Dependencies

- TECH-3561 discovery complete — all findings available in Confluence
- Stakeholder answers needed for Q9, Q13, Q21, Q22 before any dashboard migration or decommission can proceed
- Q36 must be disclosed to tashvir.babulal / rayhaan.suleyman immediately — billing data stale since May 2026

---

## Links

| Resource | Link |
|---|---|
| Parent epic | [TECH-3410](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3410) |
| Discovery ticket | [TECH-3535](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3535) |
| Grafana discovery | [TECH-3561](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3561) |
| Grafana Inventory | [View in Confluence](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6850314252/Grafana+Inventory) |
| Grafana Investigation Log | [View in Confluence](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6851067926/Grafana+-+Investigation+Log) |
