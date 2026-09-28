# TECH-4268 — Testing Plan

**Server:** EW1R-REP-01
**Branch:** TECH-4268-disable-jobs-and-offline-dbs
**Last updated:** 2026-09-28
**Purpose:** Validate every step of the disable-jobs / offline-databases change before and after execution.

---

## Test status

| File | When to run | Status |
|---|---|---|
| `T01-pre-change-baseline.sql` | Before any change | ✅ Run — output saved |
| `T02-pre-checks.sql` | Before any change | ✅ Run — all pre-checks passed |
| `T03-post-disable-jobs.sql` | After `02-disable-jobs.sql` | ✅ Run — 50 jobs disabled, 2 retained enabled |
| `T04-post-databases-offline.sql` | After `03-databases-offline.sql` | ✅ Run — 6 offline, DBA_VCC + DBA_VCC_MEMSQL online |
| `T05-post-2fa-reenable.sql` | After `04-reenable-2fa-job.sql` + 06:00 run | ⏳ BLOCKED — pending step 4 |
| `T06-rollback-verify.sql` | After any rollback (if needed) | Not needed yet |
| `T07-blocker-evidence.sql` | Run to demonstrate the current blocker | ⚠️ Run this to show why step 4 is blocked |

---

## Pass/Fail criteria

| Test | Pass condition | Result |
|---|---|---|
| T01 | Output saved — baseline only | ✅ |
| T02 | All pre-checks return no blockers | ✅ |
| T03 | 50 jobs = DISABLED, 2 retained = ENABLED | ✅ |
| T04 | 6 DBs = OFFLINE, DBA_VCC = ONLINE, DBA_VCC_MEMSQL = ONLINE | ✅ |
| T05 | Job = ENABLED, last run = Succeeded, data fresh, Grafana alerts = Normal | ⏳ |
| T06 | Rolled-back items match T01 baseline | N/A |
| T07 | All 6 tests show expected failures — blocker confirmed | ⚠️ Run to demonstrate |

---

## T07 — Blocker evidence script

Run `T07-blocker-evidence.sql` on EW1R-REP-01 to produce evidence of the current blocker.
Share the output with whoever needs to approve the IAM permission fix.

It proves:
1. DNS resolution for `ew1r-aggr-03.rel.kurtosys-internal.net` fails — Non-existent domain
2. Linked server `ew1r-aggr-03` connection fails — OLE DB error
3. Ping to new IP `10.77.6.161` fails — 100% packet loss
4. Job is DISABLED and cannot be safely re-enabled yet
5. DBA_VCC_MEMSQL data is 4+ months stale — 2FA alerts affected
6. Exactly what IAM permission is needed and what command to run

---

## Notes

- T01 output must be saved — it is the rollback reference for T06
- T05 requires waiting for the 06:00 UTC run after step 4 completes — or trigger manually
- Check 6 in T05 (Grafana alert state) is manual — verify in the Grafana UI
- T07 can be re-run at any time to confirm whether the blocker has been resolved
