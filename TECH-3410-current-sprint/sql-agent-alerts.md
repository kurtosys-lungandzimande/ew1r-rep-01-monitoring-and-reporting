# SQL Agent Alert Inventory — EW1R-REP-01
# TECH-3478

---

## Summary

| Item | Count |
|---|---|
| Total alerts | 16 |
| Enabled | 16 |
| Disabled | 0 |
| Linked to a job | 0 |
| With notification message | 0 |
| Operators configured | 1 |
| Alerts wired to operator | 0 |

**Net result: All 16 alerts are enabled but silent. No notifications will fire.**

---

## Alert Inventory

| Alert Name | Enabled | Error / Message ID | Severity |
|---|---|---|---|
| Condition - Lock wait time | Yes | 0 | 0 |
| Error 00823 - IO - Read or Write request failure | Yes | 823 | 0 |
| Error 00824 - IO - Logical Consistency I/O Error | Yes | 824 | 0 |
| Error 00825 - IO - Read-Retry Required | Yes | 825 | 0 |
| Error 01480 - AG - Role Change | Yes | 1480 | 0 |
| Error 35264 - AG - Data Movement - Suspended | Yes | 35264 | 0 |
| Error 35265 - AG - Data Movement - Resumed | Yes | 35265 | 0 |
| Error 41404 - AG - Offline | Yes | 41404 | 0 |
| Error 41405 - AG - Not Ready for Automatic Failover | Yes | 41405 | 0 |
| Severity 019 - Fatal Error in Resource | Yes | 0 | 19 |
| Severity 020 - Fatal Error in Current Process | Yes | 0 | 20 |
| Severity 021 - Fatal Error in Database Process | Yes | 0 | 21 |
| Severity 022 - Fatal Error: Table Integrity Suspect | Yes | 0 | 22 |
| Severity 023 - Fatal Error Database Integrity Suspect | Yes | 0 | 23 |
| Severity 024 - Fatal Hardware Error | Yes | 0 | 24 |
| Severity 025 - Fatal Error | Yes | 0 | 25 |

---

## Operator Inventory

| Operator | Enabled | Email | Alerts Wired |
|---|---|---|---|
| dba@kurtosys.com | Yes | dba@kurtosys.com | 0 |

---

## Findings

### F1 — Alert system is fully silent
All 16 alerts are enabled and cover the right conditions (IO errors, AG failures, fatal severities). One operator exists and is enabled. However, `sysnotifications` is empty — no alert is wired to the operator. If any of these conditions fire, no email is sent and no job is triggered.

### F2 — AG alerts are irrelevant on this server
Errors 1480, 35264, 35265, 41404, 41405 are Availability Group alerts. EW1R-REP-01 is a standalone Developer Edition instance — it has no AG. These alerts will never fire and are inherited boilerplate.

---

## Open Questions

| # | Question |
|---|---|
| Q-A1 | Were these alerts ever wired to the operator, or has this always been misconfigured? |
| Q-A2 | Should `dba@kurtosys.com` be wired to severity 19–25 and IO error alerts before decommission work begins? |
