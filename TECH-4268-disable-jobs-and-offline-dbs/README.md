# TECH-4268 — EW1R-REP-01: Disable non-2FA jobs and take databases offline

**Parent epic:** TECH-3410
**Server:** EW1R-REP-01 — 10.72.8.216
**Executed by:** Lunga Ndzimande
**Last updated:** 2026-09-28
**Purpose:** Reduce EW1R-REP-01 to the minimum footprint required for (a) the 2FA alerting chain, (b) Grafana, and (c) the EW1P-OCT Octopus backup job. Everything else is disabled and left offline ready for decommission.
**Nothing is dropped. All changes are reversible.**

---

## Current status

| Step | Script | Status |
|---|---|---|
| 0 | `00-pre-change-state-capture.sql` | ✅ Complete |
| 1 | `01-final-backups.sql` | ✅ Confirmed — automated backups in S3 (2026-09-26) |
| 2 | `02-disable-jobs.sql` | ✅ Complete — 50 jobs disabled (2026-09-27) |
| 3 | `03-databases-offline.sql` | ✅ Complete — 6 databases offline (2026-09-28) |
| 4 | `04-reenable-2fa-job.sql` | ⏳ BLOCKED — see blocker section below |
| 5 | `05-verify.sql` | ⏳ Pending — blocked on step 4 |

---

## Blocker — step 4 cannot proceed yet

**Root cause:** `ew1r-aggr-03` was relaunched after 8 May 2026 with a new IP (`10.77.6.161`). EW1R-REP-01 cannot resolve `ew1r-aggr-03.rel.kurtosys-internal.net` because its VPC (`vpc-0312c2efa75e26a4d` — ew1r-shared) is not associated with the `rel.kurtosys-internal.net` Route53 private hosted zone.

**Fix required:** Add inline policy to IAM role `KurtosysEC2InstanceProfileRoleRep` (account `649997393595`):

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": "route53:AssociateVPCWithHostedZone",
    "Resource": "arn:aws:route53:::hostedzone/Z089788836L79G874CNG8"
  }]
}
```

Then run from EW1R-REP-01 PowerShell (Session Manager):
```powershell
aws route53 associate-vpc-with-hosted-zone `
  --hosted-zone-id Z089788836L79G874CNG8 `
  --vpc VPCRegion=eu-west-1,VPCId=vpc-0312c2efa75e26a4d
```

**⚠️ Step 1 authorization expires 2026-10-05 — must be completed before then.**

Full details in `investigation-log.md`. Run `testing/T07-blocker-evidence.sql` to demonstrate the blocker.

---

## What stays running

| Component | Detail |
|---|---|
| DBA_VCC_MEMSQL | ONLINE — 2FA job writes to it |
| DBA_VCC | ONLINE — Grafana datasource UID e8597015 connects to it as 2FA connection proxy (confirmed 2026-09-23) |
| DBA_VCC_MEMSQL_DAILY_CHECKS | Currently DISABLED — re-enabled in step 4 once blocker is resolved |
| Grafana (grafana.exe, port 443) | Untouched — relocation tracked separately |
| DBA - Maintenance - SQL Backup EW1P-OCT | ENABLED — retained until replacement is delivered |
| syspolicy_purge_history | ENABLED — system job, leave alone |
| SQL Server engine + SQL Agent | Untouched |

---

## What was disabled (50 jobs) ✅

VCC AWS (3), VCC Core (4), VCC Audit Collection (16), VCC Server Monitoring (8), VCC MySQL/DXM (7), VCC Cost/Atlassian (2), Baseline (2), KAPP Schema (1), DBA Maintenance (6), SSIS (1).
The 6 MemSQL jobs and 4 DBA jobs that were already disabled before this ticket are left off — not touched.

---

## What went offline (6 databases) ✅

| Database | State | Reason offline |
|---|---|---|
| DBA_VCC_AWS | OFFLINE | KAPP API and AWS monitoring — no active consumer |
| DBA_VCC_MYSQL | OFFLINE | MySQL/DXM monitoring — no active consumer |
| DBA_VCC_COST | OFFLINE | Client billing data — stale since 4 May 2026, backup retained |
| DBA_VCC_ATLASSIAN | OFFLINE | Jira reference data — no active consumer |
| KURTOSYS_BASELINE | OFFLINE | Performance baselines — no active consumer |
| Utilities | OFFLINE | DBA tooling — all dependent jobs disabled |

**DBA_VCC stays ONLINE** — confirmed 2026-09-23. It is the Grafana connection entry point for both 2FA alert rules. Taking it offline breaks both alerts immediately.

---

## Pre-checks status

| Pre-check | Status |
|---|---|
| 1 — Grafana 2FA datasource dependency | ✅ CLOSED 2026-09-23 — DBA_VCC stays ONLINE |
| 2 — Final backups | ✅ Confirmed — automated backups in S3 (2026-09-26) |
| 3 — Capture current state | ✅ Done — 00-pre-change-state-capture.sql run |
| 4 — Notify stakeholders | ❓ Pending confirmation |
| 5 — Q35 root cause | ✅ CLOSED — fully investigated, documented in investigation-log.md |

---

## Execution order — for reference

| Step | Script | What it does |
|---|---|---|
| 0 | `00-pre-change-state-capture.sql` | Captures current state of all 63 jobs and databases |
| 1 | `01-final-backups.sql` | FULL backups of all 8 databases — confirmed in S3 |
| 2 | `02-disable-jobs.sql` | Disables all 50 non-retained jobs |
| 3 | `03-databases-offline.sql` | Takes 6 databases offline — DBA_VCC stays ONLINE |
| 4 | `04-reenable-2fa-job.sql` | Re-enables DBA_VCC_MEMSQL_DAILY_CHECKS — ⏳ BLOCKED |
| 5 | `05-verify.sql` | Post-change verification — all DoD checks |

---

## Expected consequences (accepted)

- ~70 Grafana dashboards stop returning data — only the two 2FA dashboards remain functional
- EW2P-MSSQL-01/02 VCC monitoring stops
- AWS/KAPP API collection into DBA_VCC_AWS stops — table frozen, growth halted
- DBA_VCC_COST collection stops — already stale since 4 May 2026
- Encore/BNY IIS CloudWatch ingestion, DXM client sizes, Jira sprint pull, and baseline captures all stop
- Zabbix deadlock / sync / AG lag checks sourced from Utilities stop
- 2 daily-failing MySQL WPv2 jobs stop failing

---

## Backup decision — DBA_VCC_MEMSQL ongoing backup

Disabling the maintenance backup jobs means DBA_VCC_MEMSQL has no ongoing local backup while it stays live.

| Option | Detail |
|---|---|
| A — Accept no ongoing backup | Data is rebuilt daily from SingleStore source. Accept the gap for the observation period. |
| B — Keep a scoped weekly FULL backup | Create a new single-step job scoped to DBA_VCC_MEMSQL and system databases only, weekly. |

**❓ Decision not yet recorded — confirm Option A or B and attach to ticket.**

---

## Definition of Done

- [x] Pre-job state of all 63 jobs captured
- [x] Final FULL backups confirmed in S3 (automated — 2026-09-26)
- [x] Grafana 2FA alert datasource dependency confirmed — DBA_VCC stays ONLINE
- [x] All 50 listed jobs disabled
- [x] Retained jobs confirmed still enabled
- [x] 6 listed databases set OFFLINE
- [x] DBA_VCC confirmed ONLINE
- [ ] DBA_VCC_MEMSQL_DAILY_CHECKS re-enabled and successful 06:00 run confirmed — ⏳ BLOCKED
- [ ] DBA_VCC_MEMSQL data freshness confirmed post re-enable — ⏳ BLOCKED
- [ ] Both 2FA Grafana alert rules confirmed evaluating without error — ⏳ BLOCKED
- [ ] DBA Team and monitoring team notified — ❓ Pending
- [ ] Backup decision (Option A or B) recorded — ❓ Pending
- [ ] Observation period agreed with follow-up date — ❓ Pending

---

## Rollback

`06-rollback.sql` contains individually commented-out sections for every change:

- **Rollback A** — bring a specific database back ONLINE
- **Rollback B** — re-enable a specific SQL Agent job
- **Rollback C** — disable DBA_VCC_MEMSQL_DAILY_CHECKS if it causes problems
- **Rollback D** — full rollback, restores server to pre-change state

Each section is independent. Uncomment only the line(s) needed, then investigate.

---

## Files in this folder

| File | Purpose |
|---|---|
| `00-pre-change-state-capture.sql` | Capture current state before any change |
| `01-final-backups.sql` | FULL backups of all databases before going offline |
| `02-disable-jobs.sql` | Disable all 50 non-retained SQL Agent jobs |
| `03-databases-offline.sql` | Take 6 databases offline (DBA_VCC stays ONLINE) |
| `04-reenable-2fa-job.sql` | Re-enable DBA_VCC_MEMSQL_DAILY_CHECKS — ⏳ BLOCKED |
| `05-verify.sql` | Post-change verification — all DoD checks |
| `06-rollback.sql` | Reverse any change individually or full rollback |
| `check-grafana-datasource.py` | Python script to confirm Grafana 2FA datasource UID |
| `investigation-log.md` | Full investigation log — root cause, blocker, evidence |
| `testing/` | Test scripts T01–T07 — run before, during and after each step |
| `README.md` | This file |
