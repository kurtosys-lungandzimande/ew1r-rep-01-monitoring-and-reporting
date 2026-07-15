# Theme D — Classification, Topology Diagram and Handover
# [TECH-3481](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3481)

> **Parent Epic:** TECH-3410
> **Status:** To Do

---

## Purpose

Using the classification and topology work completed in TECH-3563 during the TECH-3535 discovery sprint, produce a finalised component classification, a validated topology diagram, and a complete handover package for EW1R-REP-01. This ticket is the final output of the Phase 2 sprint — it consolidates findings from Themes A, B, and C into a single decommission-ready picture and hands it over to the team responsible for migration and replacement planning.

---

## Background

TECH-3563 completed the topology map and preliminary classification across all components. 12 components were classified across 4 categories (Replace, Retire, Move, Investigate). A preliminary decommission recommendation was written — the server is not safe to decommission. 6 stakeholder questions (Q13, Q21, Q22, Q23, Q35, Q36) remain open and block any decommission date being set. This ticket finalises that classification once stakeholder answers are received, updates the topology diagram, and produces the handover package.

---

## What Was Found in Discovery

| Component | Classification | Reason |
|---|---|---|
| DBA_VCC_AWS (KAPP monitoring) | Replace | Core KAPP observability — cannot retire |
| DBA_VCC_MYSQL (MySQL monitoring) | Replace | Active MySQL/RDS monitoring |
| DBA_VCC_COST (Cost tracking) | Replace | Confirmed client billing — 200+ clients |
| DBA_VCC_MEMSQL (MemSQL monitoring) | Retire | All 7 jobs disabled since May 2026 — likely superseded |
| DBA_VCC_ATLASSIAN (Jira integration) | Investigate | Unknown consumer |
| KURTOSYS_BASELINE | Investigate | 51 GB — unknown active consumer |
| SingleStore linked servers (90) | Retire | All MemSQL jobs disabled |
| SQL Server linked servers (active) | Move | Still needed for EW2P monitoring |
| Grafana dashboards (74) | Replace / Move | 3 active admins, actively used as of June 2026 |
| VCC AWS jobs | Replace | Move to CloudWatch / native AWS monitoring |
| VCC MemSQL jobs | Retire | All disabled |
| DBA Maintenance jobs | Move | Needed on any replacement host |

**Decommission blockers (6 open questions):**

| # | Question | Who to Ask |
|---|---|---|
| Q13 | Who owns the KAPP monitoring data in DBA_VCC_AWS? Is it used for SLA reporting? | KAPP engineering / platform team |
| Q21 | If this server went offline today, what would break immediately? | yogeshwar.phull / tashvir.babulal |
| Q22 | Is any alerting dependent solely on this server — would anyone lose visibility? | yogeshwar.phull / tashvir.babulal |
| Q23 | Is the VCC framework replicated anywhere else or is this the only instance? | DBA team |
| Q35 | Who disabled the DBA_VCC_MEMSQL jobs in May 2026 and why? | yogeshwar.phull / tashvir.babulal |
| Q36 | Has anyone noticed that DBA_VCC_COST billing data has been stale since 4 May 2026? | tashvir.babulal / rayhaan.suleyman |

---

## This Ticket Delivers

- Finalised component classification table — updated once Q13, Q21, Q22, Q23 are answered
- Validated topology diagram (drawio) — updated to reflect confirmed consumers, dead targets removed, active data flows confirmed
- Decommission recommendation — final version with stakeholder answers incorporated
- Handover package — all Confluence pages linked, all open questions resolved or escalated, all active failures documented with owner and action
- Migration input — what must be replaced, what can be retired, what must move, in what order

---

## Open Questions to Resolve in This Ticket

| # | Question | Who to Ask |
|---|---|---|
| Q13 | Who owns the KAPP monitoring data in DBA_VCC_AWS? Is it used for SLA reporting? | KAPP engineering / platform team |
| Q21 | If this server went offline today, what would break immediately? | yogeshwar.phull / tashvir.babulal |
| Q22 | Is any alerting dependent solely on this server — would anyone lose visibility? | yogeshwar.phull / tashvir.babulal |
| Q23 | Is the VCC framework replicated anywhere else or is this the only instance? | DBA team |
| Q35 | Who disabled the DBA_VCC_MEMSQL jobs in May 2026 and why? | yogeshwar.phull / tashvir.babulal |
| Q36 | Has anyone noticed that DBA_VCC_COST billing data has been stale since 4 May 2026? | tashvir.babulal / rayhaan.suleyman |

---

## Definition of Done

- [ ] All 6 decommission blocker questions answered or formally escalated with evidence
- [ ] Component classification finalised — all 12 components confirmed as Replace, Retire, Move, or Investigate
- [ ] Topology diagram updated — dead targets removed, confirmed consumers added, active data flows validated
- [ ] Decommission recommendation finalised — safe or not safe, with conditions clearly stated
- [ ] Handover package complete — all active failures documented with owner and next action
- [ ] Migration input produced — ordered list of what must be replaced, retired, or moved before decommission
- [ ] All Confluence pages updated to reflect final classification and topology
- [ ] Handover published to Confluence and shared with migration team

---

## Dependencies

- Themes A, B, and C (TECH-3478, TECH-3479, TECH-3480) must be complete before this ticket can be finalised
- Q13, Q21, Q22, Q23 must be answered before classification can be confirmed and decommission recommendation written
- Q35 must be answered before DBA_VCC_MEMSQL can be classified as Retire with confidence
- Q36 must be disclosed to stakeholders before this ticket closes — billing data stale since May 2026

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
