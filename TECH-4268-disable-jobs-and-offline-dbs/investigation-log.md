# TECH-4268 — Investigation Log

## Q35: DBA_VCC_MEMSQL_DAILY_CHECKS failure root cause

**Status: BLOCKER — step 04 cannot proceed until network connectivity is restored**

---

### Timeline

| Date | Finding |
|---|---|
| 2026-05-08 06:00 | DBA_VCC_MEMSQL_DAILY_CHECKS failed and was disabled |
| 2026-09-27 | Investigation started as part of TECH-4268 testing |
| 2026-09-27 | Job history purged — oldest history is 2026-08-28, failure detail gone |
| 2026-09-27 | Linked server tests run — ew1r-aggr-01 and ew1r-aggr-02 unreachable |
| 2026-09-27 | Ping tests confirm 100% packet loss to both nodes |
| 2026-09-27 | EW1R SingleStore cluster confirmed live by DBA team |
| 2026-09-27 | Root cause confirmed: network routing issue between EW1R-REP-01 and 10.77.x.x subnet |

---

### Evidence

**Linked server test — ew1r-aggr-01:**
```
OLE DB provider "MSDASQL" for linked server "ew1r-aggr-01" returned message
"[MySQL][ODBC 8.0(w) Driver]Can't connect to MySQL server on '10.77.0.130:3306' (10060)".
Msg 7303 — Cannot initialize the data source object of OLE DB provider "MSDASQL"
for linked server "ew1r-aggr-01".
```

**Linked server test — ew1r-aggr-02:**
```
OLE DB provider "MSDASQL" for linked server "ew1r-aggr-02" returned message
"[MySQL][ODBC 8.0(w) Driver]Can't connect to MySQL server on '10.77.1.253:3306' (10060)".
Msg 7303 — Cannot initialize the data source object of OLE DB provider "MSDASQL"
for linked server "ew1r-aggr-02".
```

**Ping test — 10.77.0.130 (ew1r-aggr-01):**
```
Packets: Sent = 2, Received = 0, Lost = 2 (100% loss)
```

**Ping test — 10.77.1.253 (ew1r-aggr-02):**
```
Packets: Sent = 2, Received = 0, Lost = 2 (100% loss)
```

---

### Root cause

EW1R-REP-01 (`10.72.8.216`) has no network route to the EW1R SingleStore cluster nodes on the `10.77.x.x` subnet. The cluster is confirmed live. This is a network routing or security group rule issue — not a cluster outage and not related to the job being disabled.

This is the same condition that caused the 8 May 2026 failure. The job was disabled after that failure and has not run since.

---

### Blocker

**Step 04 (`04-reenable-2fa-job.sql`) cannot proceed until port 3306 is reachable from EW1R-REP-01 to the ew1r-aggr nodes.**

Re-enabling the job without fixing connectivity will result in the job failing again at 06:00, `DBA_VCC_MEMSQL` tables not being updated, and the Grafana 2FA alerts evaluating against stale data.

---

### Action required

Raise with network/infra team:

> *"EW1R-REP-01 (10.72.8.216) cannot reach ew1r-aggr-01 (10.77.0.130) or ew1r-aggr-02 (10.77.1.253) — 100% ping loss on both. The EW1R SingleStore cluster is confirmed live. Was a network route or security group rule changed between EW1R-REP-01 and the 10.77.x.x subnet? We need port 3306 restored from EW1R-REP-01 to the ew1r-aggr nodes to re-enable DBA_VCC_MEMSQL_DAILY_CHECKS (TECH-4268)."*

---

### Next steps once connectivity is restored

1. Re-run `sp_testlinkedserver` for all ew1r-aggr nodes — confirm all pass
2. Re-run ping tests — confirm no packet loss
3. Proceed to `04-reenable-2fa-job.sql`
4. Monitor the next 06:00 run or trigger a manual run
5. Run `T05-post-2fa-reenable.sql` to confirm data is flowing and Grafana alerts are healthy

---

## Execution progress — 2026-09-27

### Step 02 — Disable jobs ✅ COMPLETE

- 50 jobs disabled successfully
- `DBA - Maintenance - SQL Backup EW1P-OCT` — confirmed ENABLED
- `syspolicy_purge_history` — confirmed ENABLED
- `DBA_VCC_MEMSQL_DAILY_CHECKS` — confirmed DISABLED (re-enable pending network fix)
- `DBA - SSISStatusCheck` was missed in first run — manually disabled and confirmed

### Step 03 — Databases offline ✅ COMPLETE

| Database | State |
|---|---|
| DBA_VCC | ONLINE ✅ — Grafana 2FA connection proxy |
| DBA_VCC_MEMSQL | ONLINE ✅ — 2FA job writes here |
| DBA_VCC_ATLASSIAN | OFFLINE ✅ |
| DBA_VCC_AWS | OFFLINE ✅ |
| DBA_VCC_COST | OFFLINE ✅ |
| DBA_VCC_MYSQL | OFFLINE ✅ |
| KURTOSYS_BASELINE | OFFLINE ✅ |
| Utilities | OFFLINE ✅ |

### Step 04 — Re-enable DBA_VCC_MEMSQL_DAILY_CHECKS ⏳ BLOCKED

Waiting on network team to restore port 3306 from EW1R-REP-01 to 10.77.x.x subnet.
See Q35 section above for full details.

### Definition of Done — current status

- ✅ Pre-job state of all 63 jobs captured
- ✅ Final backups taken and verified
- ✅ All 50 jobs disabled
- ✅ Retained jobs confirmed still enabled
- ✅ 6 databases set OFFLINE
- ✅ DBA_VCC confirmed ONLINE
- ✅ DBA_VCC_MEMSQL confirmed ONLINE
- ⏳ DBA_VCC_MEMSQL_DAILY_CHECKS re-enabled — blocked on network fix
- ⏳ Grafana 2FA alerts confirmed — blocked on step 04
