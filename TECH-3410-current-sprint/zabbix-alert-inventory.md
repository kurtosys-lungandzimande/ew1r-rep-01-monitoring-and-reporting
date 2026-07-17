# Zabbix Alert Inventory — EW1R-REP-01
**Ticket:** TECH-3478 — Theme A SQL Server Inventory  
**Date captured:** 2026-07-16  
**Zabbix instance:** ZabbixProdNew (MariaDB 10.6.22, reachable via linked server)  
**Zabbix version context:** Production Zabbix — monitors all production infrastructure  

---

## Summary

| Item | Count |
|---|---|
| Total monitored hosts | 30 |
| Active hosts (status=0) | 21 |
| Disabled hosts (status=1) | 9 |
| Total enabled triggers | 500+ |
| Triggers currently firing (value=1) | 3 |
| Notification channels configured | 8 |
| Active notification channels | 5 |
| Disabled notification channels | 3 |

---

## Monitored Hosts

### Active Hosts (status=0)

| Host | Platform |
|---|---|
| ec1p-dxm-logging.ci5ahgfni7pl.eu-central-1.rds.amazonaws.com | DXM RDS — ec1p |
| ec1p-dxm-repl.ci5ahgfni7pl.eu-central-1.rds.amazonaws.com | DXM RDS — ec1p |
| ec1p-dxm.ci5ahgfni7pl.eu-central-1.rds.amazonaws.com | DXM RDS — ec1p |
| ew1p-admin-01.shprd.kurtosys-internal.net | Admin server — ew1p |
| ew1p-git-02.cf44omvduz9q.eu-west-1.rds.amazonaws.com | Git RDS — ew1p |
| ew1p-jump-01.shprd.kurtosys-internal.net | Jump server — ew1p |
| ew1p-nifireg-01.cf44omvduz9q.eu-west-1.rds.amazonaws.com | NiFi Registry RDS — ew1p |
| ew2p-dxm-logging.cppsu4v9i8cf.eu-west-2.rds.amazonaws.com | DXM RDS — ew2p |
| ew2p-dxm-repl.cppsu4v9i8cf.eu-west-2.rds.amazonaws.com | DXM RDS — ew2p |
| ew2p-dxm.cppsu4v9i8cf.eu-west-2.rds.amazonaws.com | DXM RDS — ew2p |
| ew2p-jump-02.prd.kurtosys-internal.net | Jump server — ew2p |
| ew2p-jump-02.wpv2-prd.kurtosys-internal.net | Jump server — ew2p WPv2 network |
| ew2p-mssql-01.gen-prd.kurtosys-internal.net | SQL Server — ew2p prod |
| ew2p-mssql-02.gen-prd.kurtosys-internal.net | SQL Server — ew2p prod |
| localhost | Zabbix server itself |
| ue1p-dxm-logging.ccj9eknkk7w9.us-east-1.rds.amazonaws.com | DXM RDS — ue1p |
| ue1p-dxm-repl.ccj9eknkk7w9.us-east-1.rds.amazonaws.com | DXM RDS — ue1p |
| ue1p-dxm.ccj9eknkk7w9.us-east-1.rds.amazonaws.com | DXM RDS — ue1p |
| ew2p-mssql-01 | SQL Server — ew2p (short hostname entry) |
| ew2p-mssql-02 | SQL Server — ew2p (short hostname entry) |

### Disabled Hosts (status=1) — Still in Zabbix, not removed

| Host | Notes |
|---|---|
| ew2p-admin-02.gen-prd.kurtosys-internal.net | gen-prd — retired, disabled not removed |
| ew2p-aggr-01.gen-prd.kurtosys-internal.net | gen-prd SingleStore — retired, disabled not removed |
| ew2p-aggr-02.gen-prd.kurtosys-internal.net | gen-prd SingleStore — retired, disabled not removed |
| ew2p-leaf-01.gen-prd.kurtosys-internal.net | gen-prd SingleStore — retired, disabled not removed |
| ew2p-leaf-02.gen-prd.kurtosys-internal.net | gen-prd SingleStore — retired, disabled not removed |
| ew2p-leaf-03.gen-prd.kurtosys-internal.net | gen-prd SingleStore — retired, disabled not removed |
| ew2p-leaf-04.gen-prd.kurtosys-internal.net | gen-prd SingleStore — retired, disabled not removed |
| ew2p-leaf-51.gen-prd.kurtosys-internal.net | gen-prd SingleStore — retired, disabled not removed |
| ew2p-leaf-52.gen-prd.kurtosys-internal.net | gen-prd SingleStore — retired, disabled not removed |
| ew2p-leaf-53.gen-prd.kurtosys-internal.net | gen-prd SingleStore — retired, disabled not removed |
| ew2p-leaf-54.gen-prd.kurtosys-internal.net | gen-prd SingleStore — retired, disabled not removed |
| ew2p-wpv2.cmrr9j6takgk.eu-west-2.rds.amazonaws.com | WPv2 RDS — decommissioned, disabled not removed |

---

## Trigger Summary by Priority

| Priority | Level | Count | Examples |
|---|---|---|---|
| 5 | Disaster | ~45 | SingleStore aggregator failure, thread exhaustion, leaves offline, DocumentLoader failed |
| 4 | High | ~300 | SingleStore memory/CPU/health, MSSQL deadlocks/queue/sync, MySQL down, disk space, burst balance |
| 3 | Average | ~60 | SSH down, low memory, service not running, MySQL replication lag, process count |
| 2 | Warning | ~150 | Disk space, replica lag, query rollbacks, errorlog errors, missing backups, network traffic |
| 1 | Info | ~60 | Host restarts, hostname changes, log flush waits, log growths, file descriptor limits |
| 0 | Not classified | ~31 | SingleStore Max Memory Flush Action Trigger (all value=0, not firing) |

---

## Triggers Currently Firing (value=1) ⚠️

| Trigger | Priority | Host |
|---|---|---|
| MSSQL - Errors in the Errorlog on {HOST.NAME} for the past 4 hours | High (2) | ew2p-mssql-01 |
| MSSQL - Errors in the Errorlog on {HOST.NAME} for the past 4 hours | High (2) | ew2p-mssql-02 |
| Missing Backups on {HOST.NAME} | Warning (2) | Unknown — trigger item {84728} |
| SingleStore KAPP - One or more database backups have failed integrity check | High (4) | Unknown — trigger item {87258} |

> These are live firing alerts as of 2026-07-16. MSSQL errorlog alerts on both production SQL Servers (ew2p-mssql-01 and ew2p-mssql-02) are active. Missing backups and KAPP backup integrity check also firing.

---

## Notification Channels (Media Types)

| Name | Type | Status | Notes |
|---|---|---|---|
| Email | Email (0) | ✅ Enabled | Standard email notifications |
| Opsgenie | Webhook (4) | ✅ Enabled | Primary incident management channel |
| Slack | Webhook (4) | ✅ Enabled | Slack notifications active |
| SMS | SMS (2) | ✅ Enabled | SMS notifications configured |
| Jabber | Jabber (1) | ✅ Enabled | Jabber/XMPP — likely legacy |
| OpsGenie-Plugin | Plugin (1) | ❌ Disabled | Old OpsGenie plugin — replaced by webhook |
| Slack-Script | Script (1) | ❌ Disabled | Old Slack script — replaced by webhook |
| incident.io | Webhook (4) | ❌ Disabled | incident.io integration — not active |

---

## Findings

### F1 — EW1R-REP-01 is not monitored by Zabbix
EW1R-REP-01 (10.72.8.216) does not appear in the Zabbix host list. The server being investigated for decommission has no Zabbix monitoring. SQL Server Agent, SQL Server service, disk space, and memory on this server are not covered by Zabbix. The only monitoring is the VCC framework running on the server itself — which means if the server goes down, it cannot alert on its own failure.

### F2 — WPv2 still in Zabbix as a disabled host
`ew2p-wpv2.cmrr9j6takgk.eu-west-2.rds.amazonaws.com` is disabled in Zabbix but not removed. Triggers are still configured against it. This is consistent with the WPv2 decommission pattern seen across linked servers and stored procedures — cleanup was incomplete across all systems.

### F3 — gen-prd nodes still in Zabbix as disabled hosts
11 gen-prd nodes (ew2p-aggr-01/02, ew2p-leaf-01–54) are disabled in Zabbix but not removed. Confirmed retired. Safe to remove from Zabbix.

### F4 — 3 triggers currently firing on production systems
Two `MSSQL - Errors in the Errorlog` triggers are actively firing on ew2p-mssql-01 and ew2p-mssql-02 — both production SQL Servers. These are live alerts that need investigation independent of this decommission work. A missing backups alert and a KAPP backup integrity check are also firing.

### F5 — incident.io disabled — not integrated
incident.io media type is configured but disabled. If the organisation is moving to incident.io for incident management, Zabbix is not wired to it.

### F6 — Jabber likely legacy
Jabber/XMPP media type is enabled but Jabber is not commonly used in modern environments. Likely a legacy channel that has never been cleaned up.

---

## Proposed Resolutions

| Action | Owner | Priority |
|---|---|---|
| Investigate MSSQL errorlog alerts firing on ew2p-mssql-01 and ew2p-mssql-02 — these are live production alerts | DBA team | High — independent of decommission |
| Investigate missing backups and KAPP backup integrity check alerts currently firing | DBA team | High — independent of decommission |
| Add EW1R-REP-01 to Zabbix monitoring before any decommission work begins — server has no external monitoring | DBA team / Monitoring team | High |
| Remove WPv2 host from Zabbix — decommissioned, disabled not removed | Monitoring team | Medium |
| Remove gen-prd nodes from Zabbix — retired, disabled not removed | Monitoring team | Medium |
| Confirm whether incident.io should be enabled and wired to Zabbix | Platform / DevOps team | Low |
| Confirm whether Jabber is still a valid notification channel — disable if not | Monitoring team | Low |

---

## Open Questions

| # | Question | Who to Ask |
|---|---|---|
| Q-Z1 | Why is EW1R-REP-01 not in Zabbix — was it intentionally excluded? | DBA / Monitoring team |
| Q-Z2 | Who is receiving the currently firing MSSQL errorlog alerts — are they being actioned? | DBA team |
| Q-Z3 | Is incident.io being adopted as the primary incident management tool — should Zabbix be wired to it? | Platform / DevOps team |
| Q-Z4 | When EW1R-REP-01 is decommissioned, what happens to Zabbix monitoring of ew2p-mssql-01/02 — does Zabbix connect directly or via this server? | Monitoring team |
