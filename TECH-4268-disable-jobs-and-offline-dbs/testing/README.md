# TECH-4268 — Testing Plan

**Server:** EW1R-REP-01  
**Branch:** TECH-4268-disable-jobs-and-offline-dbs  
**Purpose:** Validate every step of the disable-jobs / offline-databases change before and after execution.

---

## Test files

| File | When to run | What it tests |
|---|---|---|
| `T01-pre-change-baseline.sql` | Before any change | Captures baseline state — jobs, databases, data freshness |
| `T02-pre-checks.sql` | Before any change | Validates all 4 pre-checks are satisfied |
| `T03-post-disable-jobs.sql` | After `02-disable-jobs.sql` | Confirms all 50 jobs disabled, 3 retained jobs still enabled |
| `T04-post-databases-offline.sql` | After `03-databases-offline.sql` | Confirms 6 DBs offline, DBA_VCC + DBA_VCC_MEMSQL online |
| `T05-post-2fa-reenable.sql` | After `04-reenable-2fa-job.sql` + first 06:00 run | Confirms 2FA job enabled, data flowing, Grafana alerts healthy |
| `T06-rollback-verify.sql` | After any rollback (if needed) | Confirms rollback restored the expected state |

---

## Pass/Fail criteria summary

| Test | Pass condition |
|---|---|
| T01 | Output saved — no assertion, baseline only |
| T02 | All 4 pre-checks return no blockers |
| T03 | 50 jobs = DISABLED, 3 retained = ENABLED, count check = 0 unexpected |
| T04 | 6 DBs = OFFLINE, DBA_VCC = ONLINE, DBA_VCC_MEMSQL = ONLINE |
| T05 | Job = ENABLED, last run = Succeeded, MAX(DateChecked) = today, Grafana alerts = Normal/Pending |
| T06 | Rolled-back items match pre-change baseline from T01 |

---

## Notes

- Run T01 first and save the output — it is the rollback reference for T06.
- T02 must be fully green before proceeding to the change scripts.
- T03 and T04 can be run immediately after their respective change scripts.
- T05 requires waiting for the 06:00 UTC DBA_VCC_MEMSQL_DAILY_CHECKS run — or trigger a manual run via the commented block in `04-reenable-2fa-job.sql`.
- Check 6 in T05 (Grafana alert state) is manual — must be done in the Grafana UI.
