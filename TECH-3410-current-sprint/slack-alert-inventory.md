# Slack Alert Inventory — EW1R-REP-01
**Ticket:** TECH-3478 — Theme A SQL Server Inventory  
**Date captured:** 2026-07-16  

---

## Summary

| Item | Finding |
|---|---|
| Stored procs with Slack code | 6 |
| Slack calls active (not commented out) | 0 |
| Slack calls commented out | All |
| Current Slack notification method | Zabbix webhook (via ZabbixProdNew) |
| Direct Slack posting from SQL Server | None — fully disabled |

**Net result: EW1R-REP-01 does not post directly to Slack. All Slack notification code has been commented out or replaced. Slack alerts from this server flow exclusively through Zabbix.**

---

## Stored Procedures with Slack Code

### 1. USP_ZAB_CheckAlwaysOnLatency — Utilities
**Purpose:** Checks Always On AG replica lag — alerts if any database is >60 minutes behind primary or NOT SYNCHRONIZING.  
**Slack status:** Commented out — `SlackChatPostMessage` call is fully commented out.  
**Current behaviour:** Writes nothing, sends nothing. The proc checks AG lag but the notification block is dead code.  
**Finding:** EW1R-REP-01 is a standalone Developer Edition instance — it has no AG. This proc will never fire a meaningful result. It is irrelevant boilerplate on this server.

---

### 2. USP_ZAB_Deadlock — Utilities / msdb
**Purpose:** Reads deadlock XEL files and returns deadlock details if a deadlock occurred in the last 5 minutes.  
**Slack status:** No Slack call present — proc returns a result set only. Referenced in `USP_ZAB_Deadlock` — the filter `event_data NOT LIKE '%Utilities.dbo.SPSlackCheckSyncStatus%'` excludes sync check deadlocks.  
**Current behaviour:** Returns deadlock info to Zabbix via the linked server query mechanism — Zabbix reads the output and triggers the `MSSQL - Deadlock` alert.  
**Finding:** This proc is active and functional. It feeds the Zabbix deadlock trigger on ew2p-mssql-01 and ew2p-mssql-02.

---

### 3. SPSlackCheckSyncStatus — Utilities
**Purpose:** Checks row count sync between SQL Server and MemSQL — alerts if tables are out of sync. Posts `*SYNC TABLE ALERT*` or `*SYNC ISSUE RESOLVED*` messages.  
**Slack status:** Commented out — `SlackChatPostMessage` and `sp_send_dbmail` calls both commented out.  
**Current behaviour:** Writes sync check results to `Utilities.dbo.Zab_MemSQLSyncCheck` and `Utilities.dbo.Zab_MemSQLSyncCheck_Metrics` — Zabbix reads these tables via the linked server.  
**Finding:** Slack posting replaced by Zabbix table writes. The proc is still functional as a Zabbix data source. However — with all MemSQL jobs disabled since May 2026, this proc has no live MemSQL data to compare against. The sync check is effectively dormant.

---

### 4. USP_MemSQL_Loaders_Increased — Utilities
**Purpose:** Checks if MemSQL loader execution count has increased by more than 10% vs baseline — alerts if so.  
**Slack status:** Commented out — `SlackChatPostMessage` call commented out.  
**Current behaviour:** Returns `@Message1` as a result set only — nothing is sent anywhere.  
**Finding:** References linked server `P23-P-AGGR-201` — not in the current linked server inventory. This is a dead proc referencing a decommissioned server. No active caller confirmed.

---

### 5. USP_ZAB_MemSQL_Loaders_Increased — Utilities
**Purpose:** Zabbix variant of USP_MemSQL_Loaders_Increased — same logic, same linked server reference.  
**Slack status:** Commented out.  
**Current behaviour:** Returns `@Message1` as a result set only.  
**Finding:** Same as above — references `P23-P-AGGR-201` which is not in the linked server inventory. Dead proc.

---

### 6. USP_MemSQL_LongRunning_Loaders — Utilities
**Purpose:** Checks if any MemSQL loader ran more than 5 minutes longer than its baseline — alerts if so.  
**Slack status:** Commented out — `SlackChatPostMessage` and `sp_send_dbmail` both commented out.  
**Current behaviour:** Returns `@Message1` as a result set only.  
**Finding:** References linked server `p23-p-aggr-301` — not in the current linked server inventory. Dead proc referencing a decommissioned server.

---

### 7. USP_ZAB_MemSQL_LongRunning_Loaders — Utilities
**Purpose:** Zabbix variant of USP_MemSQL_LongRunning_Loaders — same logic.  
**Slack status:** Commented out.  
**Current behaviour:** Returns `@Message1` as a result set only.  
**Finding:** References `p23-p-aggr-201` — not in linked server inventory. Dead proc.

---

## Findings

### F1 — No direct Slack posting from this server
All `SlackChatPostMessage` calls across all stored procedures are commented out. EW1R-REP-01 does not post to Slack directly. Slack notifications from this server's monitoring flow through Zabbix only.

### F2 — Slack was replaced by Zabbix table writes
The pattern across all procs is consistent — Slack calls commented out, replaced by `INSERT INTO Utilities.dbo.Zab_*` tables. Zabbix reads these tables via the linked server and fires its own Slack webhook. This migration happened at some point between 2016–2019 based on proc modification dates.

### F3 — 4 procs reference dead linked servers (P23-P-AGGR-201, p23-p-aggr-301)
`USP_MemSQL_Loaders_Increased`, `USP_ZAB_MemSQL_Loaders_Increased`, `USP_MemSQL_LongRunning_Loaders`, `USP_ZAB_MemSQL_LongRunning_Loaders` all reference `P23-P-AGGR-201` or `p23-p-aggr-301`. Neither server appears in the linked server inventory. These procs are dead — they will fail if called.

### F4 — SPSlackCheckSyncStatus is dormant
The sync check proc is structurally intact and writes to Zabbix tables correctly. But with all MemSQL jobs disabled since May 2026, there is no live MemSQL data to compare against. The proc will run but produce no meaningful output.

### F5 — USP_ZAB_CheckAlwaysOnLatency is irrelevant on this server
AG lag monitoring on a standalone Developer Edition instance with no AG configured. Will never produce a meaningful result.

---

## Proposed Resolutions

| Action | Owner | Priority |
|---|---|---|
| Drop USP_MemSQL_Loaders_Increased and USP_ZAB_MemSQL_Loaders_Increased — reference dead linked server P23-P-AGGR-201 | DBA team | Medium |
| Drop USP_MemSQL_LongRunning_Loaders and USP_ZAB_MemSQL_LongRunning_Loaders — reference dead linked server p23-p-aggr-301 | DBA team | Medium |
| Drop USP_ZAB_CheckAlwaysOnLatency — AG monitoring irrelevant on standalone Developer Edition | DBA team | Low |
| Confirm whether SPSlackCheckSyncStatus should be disabled given MemSQL jobs are all disabled | DBA team | Medium |
| No action needed on Slack channel config — direct Slack posting already disabled | — | Closed |
