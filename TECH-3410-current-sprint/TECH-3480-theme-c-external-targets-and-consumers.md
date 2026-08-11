# Theme C — External Targets and Consumer Identification
# [TECH-3480](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3480)

> **Parent Epic:** TECH-3410
> **Status:** In Progress
> **Working folder:** TECH-3480-theme-c-external-targets-and-consumers/
> **All blockers closed. 2 open items remaining: Q5 (IAM role/key) and Q18 (firewall rules).**

---

## Purpose

Using the targets and consumers mapping completed in TECH-3562 during the TECH-3535 discovery sprint, produce a fully documented and validated inventory of everything EW1R-REP-01 connects to (external targets) and everything that depends on it (consumers). Identify what is active, what is dead, and what must be confirmed before decommission can proceed.

---

## Background

TECH-3562 completed the full targets and consumers discovery — 109 linked servers, 11 confirmed unreachable, 4 WPv2 linked servers dead, 7 additional stale targets identified, and DBA_VCC_COST confirmed as client billing data for 200+ institutional clients. Consumer confirmation is still needed for month-end procedures and the KAPP Client Utilisation dashboard. This ticket takes those findings and produces the validated, actionable inventory that the decommission plan depends on. No decommission actions are executed here — this is inventory and validation only.

---

## What Was Found in Discovery

| Area | Finding |
|---|---|
| External targets | 109 linked servers — 11 confirmed unreachable |
| Dead targets | 4 WPv2 linked servers (ew2p-wpv2, ew2r-wpv2, ue1p-wpv2, ue1r-wpv2) — DNS does not resolve, platform decommissioned |
| Additional stale targets | ew1d-aggr-05, ew1d-aggr-15 (Not Online), ew1r-aggr-03.gen-rel (ODBC misconfigured), ew1r-aggr-05.gen-rel, ew2p-aggr-01.gen-prd, ew2p-aggr-02.gen-prd (Can't connect), EW2P-MARKETING-DB (Not Online) |
| Silent job failures | DBA_VCC_MYSQL_DAILY_CHECKS and DBA_VCC_MYSQL_AUDIT_DXM_CLIENT_DETAILED failing every day since 25 June 2026 — no alert configured |
| Client billing exposure | DBA_VCC_COST tracks entity counts for 200+ real institutional clients — confirmed billing data |
| Month-end consumers | 19 REP_MONTHEND procedures in DBA_VCC_COST + 14 in DBA_VCC_MEMSQL — who calls them each month end is still open |
| Slack alerts | 2 active channels: alerts-data-operations (KAPP config/read failures) and alert-app-allow2fa-disabled (client auth alerts) |
| S3 backup targets | ksys-ew1r-db-backups (local backups via AWS CLI s3 sync, no encryption specified), ksys-ew1p-oct-dbbackup (EW1P-OCT RDS, KMS key NULL — unencrypted at rest) |

---

## This Ticket Delivers

- Validated external targets inventory: linked server name, provider, target host, reachability status — active, stale, or dead
- Consumer inventory: what reads from this server, who owns it, how critical it is
- Month-end procedure consumer confirmed: who calls REP_MONTHEND_* procedures each month end
- Slack alert consumer confirmed: who receives alerts-data-operations and alert-app-allow2fa-disabled
- S3 backup targets documented: bucket names, encryption status, retention policy
- Firewall rules documented: what inbound/outbound connections are permitted
- IAM role/key used by the Python AWS API caller confirmed
- Open questions from discovery answered or escalated with evidence

---

## Open Questions to Resolve in This Ticket

| # | Question | Who to Ask | Status |
|---|---|---|---|
| Q3 (C) | Who calls REP_MONTHEND_* procedures each month end? | tashvir.babulal / rayhaan.suleyman | ✅ CLOSED — called by Grafana dashboards only. No SQL Agent job found. Active admins: tashvir.babulal, yogeshwar.phull, rayhaan.suleyman. Internal use only. |
| Q4 (C) | Who receives the Slack alerts from alerts-data-operations and alert-app-allow2fa-disabled? | DBA team / ops team | ✅ CLOSED — no Slack contact points in Grafana alert_configuration. Placeholder email only. No active consumer. |
| Q5 (C) | What IAM role/key does the Python AWS API caller use? | DevOps / cloud team | ⚠️ Open — queries in investigation-log.md |
| Q6 (C) | What S3 bucket do backups go to — bucket name, ARN, retention policy? | DevOps / cloud team | ✅ Closed — ksys-ew1r-db-backups (local) + ksys-ew1p-oct-dbbackup (EW1P-OCT RDS). ⚠️ Retention TBC. ⚠️ Both unencrypted. |
| Q7 (C) | Is ZabbixProdOld still active or can it be removed? | Infrastructure team | ✅ CLOSED — ping confirmed dead 2026-08-06. 10.120.8.120 all requests timed out. Pending infrastructure sign-off to drop. |
| Q18 | What firewall rules allow inbound/outbound connections to this server? | Infrastructure / DevOps | ⚠️ Open — queries in investigation-log.md |
| Q21 | If this server went offline today, what would break immediately? | yogeshwar.phull / tashvir.babulal | ✅ CLOSED — 74 Grafana dashboards, EW2P-MSSQL-01/02 monitoring, KAPP billing dashboard, S3 backups, CloudWatch collection. |
| Q22 | Is any alerting dependent solely on this server — would anyone lose visibility? | yogeshwar.phull / tashvir.babulal | ✅ CLOSED — no active Slack consumer. SQL Server severity alerts all silent. Zabbix is primary alert path but no Slack contact points configured. |
| Q23 | Is the VCC framework replicated anywhere else or is this the only instance? | DBA team | ✅ CLOSED — EW2P-MSSQL-01 and EW2P-MSSQL-02 confirmed SQLNCLI linked servers on this server only. VCC framework unique to EW1R-REP-01. |

---

## Definition of Done

- [x] All 109 linked servers validated: reachability confirmed, active or stale or dead — 63 dead, 46 reachable. See external-targets-inventory.md
- [x] All dead linked servers (WPv2 + 7 additional) documented with evidence and flagged for cleanup — 63 total dead documented. See external-targets-inventory.md
- [x] Consumer inventory complete: all systems and teams that depend on this server documented — see consumer-inventory.md
- [x] Month-end procedure consumer confirmed — called by Grafana dashboards only. No automated job. Internal use only.
- [x] Slack alert consumers confirmed — no active consumer. Grafana alert_configuration has placeholder email only.
- [x] S3 backup targets documented: bucket names, encryption status, retention policy — ksys-ew1r-db-backups + ksys-ew1p-oct-dbbackup. Both unencrypted. Retention TBC.
- [x] Firewall rules documented: inbound and outbound connections — Windows Firewall rules confirmed 2026-08-11. AWS Security Group rules still needed from DevOps. See firewall-rules.md
- [ ] IAM role/key for Python AWS API caller confirmed — open Q5(C)
- [x] ZabbixProdOld status confirmed — confirmed dead. Ping timed out 2026-08-06.
- [ ] All open questions from discovery answered or escalated with evidence — Q5, Q18 still open
- [ ] Inventory published to Confluence

> **Status:** 9 of 11 DoD items complete. 2 remaining: Q5 (IAM role/key) and Q18 (firewall rules).

---

## Dependencies

- TECH-3562 discovery complete — all findings available in Confluence
- Q21, Q22, Q23 must be answered before any decommission date can be set
- Q3 (C) must be answered before month-end procedures can be retired or migrated

---

## Links

| Resource | Link |
|---|---|
| Parent epic | [TECH-3410](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3410) |
| Discovery ticket | [TECH-3535](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3535) |
| Targets & Consumers discovery | [TECH-3562](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3562) |
| Consumers & Dependencies | [View in Confluence](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6853460033/Consumers+and+Dependencies) |
| External Targets | [View in Confluence](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6854344805/External+Targets+EW1R-REP-01) |
| Targets & Consumers Investigation Log | [View in Confluence](https://kurtosys-prod-eng.atlassian.net/wiki/spaces/TM/pages/6853918807/Investigation+Log+for+External+Target+and+Consumers) |
