# TECH-4268 — EW1R-REP-01: Disable non-2FA jobs and take databases offline

**Parent epic:** TECH-3410  
**Server:** EW1R-REP-01 — 10.72.8.216  
**Purpose:** Reduce the server to the minimum footprint required for (a) the 2FA alerting chain, (b) Grafana, and (c) the EW1P-OCT Octopus backup job. Everything else is disabled and left offline ready for decommission.  
**Nothing is dropped. All changes are reversible.**

---

## What stays running

| Component | Detail |
|---|---|
| DBA_VCC_MEMSQL | Database stays ONLINE — 2FA job writes to it |
| DBA_VCC | Database stays ONLINE — Grafana datasource UID e8597015 connects to it as connection proxy for both 2FA alert queries (confirmed 2026-09-23) |
| DBA_VCC_MEMSQL_DAILY_CHECKS | Re-enabled in step 04 — 06:00 UTC daily |
| Grafana (grafana.exe, port 443) | Untouched — relocation tracked separately |
| DBA - Maintenance - SQL Backup EW1P-OCT | Retained until replacement is delivered |
| syspolicy_purge_history | System job — leave alone |
| SQL Server engine + SQL Agent | Untouched |

## What gets disabled (50 jobs)

VCC AWS (3), VCC Core (4), VCC Audit Collection (16), VCC Server Monitoring (8), VCC MySQL/DXM (7), VCC Cost/Atlassian (2), Baseline (2), KAPP Schema (1), DBA Maintenance (6), SSIS (1).  
The 6 MemSQL jobs and 4 DBA jobs that were already disabled before this ticket are left off — not touched.

## What goes offline (6 databases)

DBA_VCC_AWS, DBA_VCC_MYSQL, DBA_VCC_COST, DBA_VCC_ATLASSIAN, KURTOSYS_BASELINE, Utilities.

**DBA_VCC stays ONLINE** — confirmed 2026-09-23. Both 2FA Grafana alert rules use datasource UID `e8597015` which connects to DBA_VCC on localhost. The panel queries use 3-part names to reach DBA_VCC_MEMSQL directly:
- `FROM DBA_VCC_MEMSQL..INFO_Client_FP_Detail`
- `FROM [DBA_VCC_MEMSQL].[dbo].[INFO_Client_Application_Auth_Config_Detail]`
- `EXEC [DBA_VCC_MEMSQL]..[REP_CLIENT_APP_AUTH_CONFIG_CHANGES_DETAILED_REPORT]`

DBA_VCC is the connection entry point — taking it offline causes SQL Server to reject the Grafana connection before the query reaches DBA_VCC_MEMSQL. Both 2FA alerts break immediately.

---

## Pre-checks — complete before running any script

### Pre-check 1 — Grafana 2FA alert datasource dependency ✅ CLOSED 2026-09-23

Both 2FA Grafana alert rules use datasource UID `e8597015-eb43-4adc-8da4-090eed43ee62` — the DBA_VCC mssql datasource on localhost. The panel queries use 3-part names to reach DBA_VCC_MEMSQL directly:
- `FROM DBA_VCC_MEMSQL..INFO_Client_FP_Detail`
- `FROM [DBA_VCC_MEMSQL].[dbo].[INFO_Client_Application_Auth_Config_Detail]`
- `EXEC [DBA_VCC_MEMSQL]..[REP_CLIENT_APP_AUTH_CONFIG_CHANGES_DETAILED_REPORT]`

DBA_VCC is the connection entry point. Taking it offline causes SQL Server to reject the Grafana connection before the query reaches DBA_VCC_MEMSQL — both 2FA alerts break immediately.

**Resolution: DBA_VCC stays ONLINE. Removed from the databases-offline list. 6 databases go offline instead of 7.**

### Pre-check 2 — Final backups

All databases being taken offline must be backed up first. `01-final-backups.sql` handles this. Confirm each backup lands in `ksys-ew1r-db-backups` before proceeding to step 02.

### Pre-check 3 — Capture current state

Run `00-pre-change-state-capture.sql` and save the output. This is your rollback reference for the exact enabled/disabled state of all 63 jobs before any change.

### Pre-check 4 — Notify stakeholders

Before running:
- Notify **DBA Team (Tashvir Babulal, Yogeshwar Phull, Rayhaan Suleyman)** — ~70 of 74 Grafana dashboards will stop returning data after this change. Only the two 2FA dashboards remain functional.
- Notify **monitoring team** — Zabbix reads `Utilities.dbo.Zab_*` tables via linked server for deadlock, sync check, and AG lag checks. Those stop when Utilities goes offline.
- Confirm **EW2P-MSSQL-01/02 monitoring gap is accepted** — the 24 VCC audit and server monitoring jobs are the only monitoring path for those two production servers. Arrange CloudWatch coverage first if the gap is not accepted.

### Pre-check 5 — Q35 (MemSQL job failure root cause)

Before re-enabling DBA_VCC_MEMSQL_DAILY_CHECKS in step 04, confirm with yogeshwar.phull / tashvir.babulal why the job was disabled on 2026-05-08 and what caused the last run failure. Do not re-enable without this answer.

---

## Execution order

Run scripts in this exact order. Do not skip steps.

| Step | Script | What it does |
|---|---|---|
| 1 | `00-pre-change-state-capture.sql` | Captures current state of all 63 jobs and all databases. Save the output. |
| 2 | `01-final-backups.sql` | Takes FULL backups of all 8 databases and syncs to S3. Confirm each backup before proceeding. |
| 3 | `02-disable-jobs.sql` | Disables all 50 non-retained jobs. Retained jobs are untouched. |
| 4 | `03-databases-offline.sql` | Takes 6 databases offline. DBA_VCC stays ONLINE — confirmed 2026-09-23. |
| 5 | `04-reenable-2fa-job.sql` | Re-enables DBA_VCC_MEMSQL_DAILY_CHECKS. Confirm Q35 is answered first. |
| 6 | `05-verify.sql` | Runs all DoD checks. All 7 checks must pass before closing the ticket. |

---

## Expected consequences (accepted)

- ~70 Grafana dashboards stop returning data — only the two 2FA dashboards remain functional
- EW2P-MSSQL-01/02 VCC monitoring stops
- AWS/KAPP API collection into DBA_VCC_AWS stops — 297M+ row table frozen, growth halted
- DBA_VCC_COST collection stops — already stale since 4 May 2026, no new impact
- Encore/BNY IIS CloudWatch ingestion, DXM client sizes, Jira sprint pull, and baseline captures all stop
- Zabbix deadlock / sync / AG lag checks sourced from Utilities stop
- 2 daily-failing MySQL WPv2 jobs stop failing

---

## Backup decision — DBA_VCC_MEMSQL ongoing backup

Disabling the maintenance backup jobs means DBA_VCC_MEMSQL has no ongoing local backup while it stays live.

**Decision required before step 03:**

| Option | Detail |
|---|---|
| A — Accept no ongoing backup | Data is rebuilt daily from SingleStore source. Accept the gap for the observation period. |
| B — Keep a scoped weekly FULL backup | Create a new single-step job that runs `DatabaseBackup` scoped to `DBA_VCC_MEMSQL` and system databases only, weekly. |

Record which option was chosen and attach to this ticket.

---

## Definition of Done

- [ ] Pre-job state of all 63 jobs captured and attached to this ticket (output of `00-pre-change-state-capture.sql`)
- [ ] Final FULL backups taken and verified in S3 for every database taken offline
- [ ] Grafana 2FA alert datasource dependency confirmed and handled (Pre-check 1)
- [ ] All 50 listed jobs disabled — confirmed by Check 1 in `05-verify.sql`
- [ ] Retained jobs confirmed still enabled — confirmed by Check 2 in `05-verify.sql`
- [ ] 6 listed databases set OFFLINE — confirmed by Check 3 in `05-verify.sql`
- [ ] DBA_VCC confirmed ONLINE — 2FA alert connection proxy (Pre-check 1 closed 2026-09-23)
- [ ] DBA_VCC_MEMSQL_DAILY_CHECKS re-enabled and a successful 06:00 run confirmed — Check 4
- [ ] DBA_VCC_MEMSQL data freshness confirmed post re-enable — Check 5
- [ ] Both 2FA Grafana alert rules confirmed evaluating without error — Check 6 (manual Grafana UI)
- [ ] DBA Team and monitoring team notified
- [ ] Backup decision (Option A or B) recorded and attached
- [ ] Observation period agreed (suggest 2 weeks) with a follow-up check date noted

---

## Rollback

`06-rollback.sql` contains individually commented-out sections for every change made in this ticket:

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
| `04-reenable-2fa-job.sql` | Re-enable DBA_VCC_MEMSQL_DAILY_CHECKS |
| `05-verify.sql` | Post-change verification — all DoD checks |
| `06-rollback.sql` | Reverse any change individually or full rollback |
| `README.md` | This file |
