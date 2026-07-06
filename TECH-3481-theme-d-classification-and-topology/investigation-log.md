# TECH-3481 — Theme D: Classification & Topology — Investigation Log

Scope: Topology map, server classification, decommission decision.
Each entry has the question, the query, the evidence, and the finding.

> Status: Not started. Blocked on completing Themes A, B, C first.
> This ticket cannot be worked until the full picture from A, B, C is confirmed.

---

## Blocked — prerequisites not yet complete

Theme D requires answers to the following before any classification or decommission decision can be made:

- Theme A (TECH-3478): Job-to-linked-server cross-map not yet run. Full reachability audit of 109 linked servers not done. Consumer of DBA_VCC_COST not confirmed.
- Theme B (TECH-3479): Client-facing dashboard confirmation not done. donovan.vangraan credential rotation not done.
- Theme C (TECH-3480): Firewall rules not confirmed. Consumer confirmation not done.

**Key decommission risk questions (open):**
- If EW1R-REP-01 went offline today, what would break immediately?
- Is any alerting dependent solely on this server?
- Is the VCC framework replicated anywhere else or is this the only instance?

These will be answered as Themes A, B, C complete and findings are documented here.
