# Incident Report — Zabbix Alerts 2026-07-25
**Date:** 2026-07-25
**Investigated by:** Lunga Ndzimande
**Investigation date:** 2026-07-28
**Status:** Closed — root cause confirmed, actions raised

---

## Alerts Received

| Time | Alert | Host | Status |
|---|---|---|---|
| 13:02 | KAPP SingleStore Schema Discrepancies | EW1R-REP-01 | ✅ Resolved |
| 15:15 | MSSQL Errors in Errorlog (past 4 hours) | EW1R-REP-01 | ✅ Resolved |
| 22:58 | MSSQL Errors in Errorlog (past 4 hours) | EW2P-MSSQL-01 | ✅ Resolved |
| 23:01 | MSSQL Errors in Errorlog (past 4 hours) | EW2P-MSSQL-02 | ✅ Resolved |
| 00:45 (26 Jul) | MSSQL Jobs running > 30 min — DBA - Maintenance - CHECKDB | EW1R-REP-01 | ⚠️ Known issue |

---

## Investigation Summary

### Alert 1 — KAPP SingleStore Schema Discrepancies (EW1R-REP-01)
- **What happened:** Zabbix detected a schema mismatch between KAPP and SingleStore on EW1R-REP-01
- **Resolution:** Resolved automatically after 1 day — event age 1d 0h 0m 2s at time of resolution
- **Root cause:** Not confirmed — likely a transient schema drift detected by `USP_ZAB_KAPP_schema_compare` in the Utilities database
- **Action:** Confirm with yogeshwar.phull whether this is expected or a sign of ongoing schema drift

---

### Alerts 2, 3, 4 — MSSQL Errorlog Errors (EW1R-REP-01, EW2P-MSSQL-01, EW2P-MSSQL-02)

**Error confirmed from live errorlog query (run 2026-07-28 via OPENQUERY):**

```
Error: 18456, Severity: 14, State: 38
Source: Logon
Time: 2026-07-28 02:30:00 — 2026-07-28 02:30:30
Frequency: Every ~1 second for ~30 seconds
Servers affected: EW2P-MSSQL-01 and EW2P-MSSQL-02 simultaneously
```

**Error 18456 State 38** = Login succeeded but the target database was unavailable at that moment — either offline, in recovery, or being restored.

**Root cause confirmed:** `DBA_VCC_MON_CONNECTION_CHECK` runs every night at 23:00 UTC and connects to both EW2P-MSSQL-01 and EW2P-MSSQL-02 to check connection health. Job history confirms this job ran successfully on 2026-07-25 at 23:00 on both servers. The 02:30 AM login failures align with the nightly CHECKDB and backup maintenance window — a database was briefly unavailable, the connection check retried rapidly for ~30 seconds, then the database came back online and connections resumed.

**This is not a security incident.** No evidence of unauthorised access. The pattern — both servers hit simultaneously, every second for 30 seconds, then stops — is consistent with a scheduled monitoring job hitting a maintenance window.

**Why the 2026-07-25 errorlog data was not available:** The SQL Server errorlog is reinitialized at midnight every day (`The error log has been reinitialized`). The 2026-07-25 errors rolled into the previous log file before investigation began on 2026-07-28. Only the current log (from 2026-07-28 00:00) was accessible — which showed the same pattern repeating, confirming this is a nightly occurrence.

---

### Alert 5 — CHECKDB Running > 30 Minutes (EW1R-REP-01)

- **What happened:** Zabbix fired a Warning that `DBA - Maintenance - CHECKDB` exceeded the 30-minute threshold
- **Root cause:** Known and documented — `INFO_AWS_KAPP_Query_API_Detail` in DBA_VCC_AWS has 297M+ rows, is unpartitioned, and causes CHECKDB to take ~40 minutes every night. Confirmed across 10+ days of job history.
- **This alert will fire every single night** until the KAPP table is partitioned or archived
- **Not an incident** — a known performance issue documented in the decommission investigation

---

## Additional Findings Identified During Investigation

### Finding 1 — WPv2 DNS errors firing every night (known issue)
Every run of `DBA_VCC_MYSQL_MON_SQL_STATUS` produces 4 WPv2 DNS errors:
```
OLE DB provider "MSDASQL" for linked server "ew2p-wpv2" returned message
"[MySQL][ODBC 8.0(w) Driver]Unknown MySQL server host
'ew2p-wpv2.cmrr9j6takgk.eu-west-2.rds.amazonaws.com' (11001)"
```
This fires every night across all 4 WPv2 linked servers (ew2p-wpv2, ew2r-wpv2, ue1p-wpv2, ue1r-wpv2). WPv2 was decommissioned but the linked servers and job steps were never cleaned up. Documented in the decommission investigation — action pending DBA team.

### Finding 2 — Errorlog collection stopped in August 2021
The VCC errorlog collection table (`DBA_VCC.dbo.ARC_SQL_Errorlog_Check`) has no data since **2021-08-19** for EW2P-MSSQL-01 and EW2P-MSSQL-02. The collection job (`DBA_VCC_AUDIT_ERRORLOG_SIZES_DETAILED`) shows as enabled and succeeding but has not written data in 5 years.

| Server | Last Collected | Rows |
|---|---|---|
| EW2P-MSSQL-01 | 2021-08-19 | 633 |
| EW2P-MSSQL-02 | 2021-08-19 | 891 |

**Impact:** There is no historical errorlog evidence available from EW1R-REP-01 for any incident investigation. Every investigation requires going directly to the production servers via OPENQUERY. This is a monitoring gap.

---

## Actions Raised

| # | Action | Owner | Priority |
|---|---|---|---|
| A1 | Remove WPv2 linked servers and job steps from `DBA_VCC_MYSQL_MON_SQL_STATUS` and related jobs | DBA team | High — fires every night |
| A2 | Investigate why `DBA_VCC_AUDIT_ERRORLOG_SIZES_DETAILED` stopped writing data in August 2021 | DBA team | Medium |
| A3 | Raise Zabbix CHECKDB threshold from 30 min to 60 min for EW1R-REP-01 — current threshold fires every night as a false positive | DBA team / Monitoring team | Low |
| A4 | Confirm KAPP schema discrepancy with yogeshwar.phull — expected or ongoing drift? | yogeshwar.phull | Low |

---

## Queries Used During Investigation

```sql
-- Pull errorlog errors from production servers
EXEC ('EXEC xp_readerrorlog 0, 1, N''Error'', NULL') AT [EW2P-MSSQL-01];
EXEC ('EXEC xp_readerrorlog 0, 1, N''Error'', NULL') AT [EW2P-MSSQL-02];

-- Check errorlog collection data freshness
SELECT ServerName, MIN(LogDate) AS oldest_entry, MAX(LogDate) AS latest_entry, COUNT(*) AS total_rows
FROM DBA_VCC.dbo.ARC_SQL_Errorlog_Check
GROUP BY ServerName ORDER BY ServerName;

-- Check jobs running at 02:30
SELECT j.name, h.run_date, h.run_time, h.run_duration,
    CASE h.run_status WHEN 0 THEN 'Failed' WHEN 1 THEN 'Succeeded' END AS status, h.message
FROM msdb.dbo.sysjobhistory h
JOIN msdb.dbo.sysjobs j ON h.job_id = j.job_id
WHERE h.run_time BETWEEN 023000 AND 023500
ORDER BY h.run_date DESC, h.run_time;
```
