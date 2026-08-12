# Classification & Topology — EW1R-REP-01
**Ticket:** TECH-3481 — Theme D: Classification, Topology and Handover
**Status:** Finalised — all Theme A, B, C findings incorporated
**Date:** 2026-08-13
**Source:** TECH-3560 (Theme A) + TECH-3561 (Theme B) + TECH-3562 (Theme C) + TECH-3563 (preliminary topology)

---

## Server Identity

| Property | Value |
|---|---|
| Hostname | EW1R-REP-01 |
| IP Address | 10.72.8.216 |
| Platform | AWS EC2 — eu-west-1 (Ireland) |
| Environment | Shared NonProd (REL) |
| SQL Server Edition | Developer Edition (64-bit) — NOT licensed for production use |
| SQL Server Version | 2019 RTM-CU32-GDR — 15.0.4455.2 |
| OS | Windows Server 2019 Datacenter |
| Grafana Version | 9.5.2 (self-hosted, port 443 HTTPS) |
| Total Data | 369 GB across 8 databases |

> Critical: This server is running SQL Server Developer Edition in a non-production environment but is actively monitoring two production SQL Servers and storing client billing data for 280 institutional clients. This is a licensing and architecture risk that exists today, independent of the decommission decision.

---

## Topology — Confirmed State (2026-08-13)

```
EW1R-REP-01 (Custom VCC Monitoring Hub)
│
├── SQL Server 2019 Developer Edition
│   │
│   ├── COLLECTS FROM — SQL Server (SQLNCLI linked servers)
│   │   ├── EW2P-MSSQL-01 (Production EU-West-2) ← ACTIVE — 24 jobs monitoring
│   │   ├── EW2P-MSSQL-02 (Production EU-West-2) ← ACTIVE — 24 jobs monitoring
│   │   ├── EW1P-OCT RDS (Production RDS EU-West-1) ← ACTIVE — backup job running
│   │   ├── EW1D-MSSQL-01 (Dev) ← monitoring disabled
│   │   └── EW1R-MSSQL-01 (Release) ← monitoring disabled
│   │
│   ├── COLLECTS FROM — SingleStore/MySQL (MSDASQL/ODBC linked servers)
│   │   ├── 46 reachable SingleStore nodes (EC1/EW1/EW2/UE1) ← JOBS DISABLED since May 2026
│   │   ├── 63 dead linked servers ← DNS gone / TCP unreachable
│   │   │   ├── 4 WPv2 (ew2p-wpv2, ew2r-wpv2, ue1p-wpv2, ue1r-wpv2) ← platform decommissioned
│   │   │   ├── 26 gen-rel + gen-prd nodes ← platform retired
│   │   │   ├── 2 Zabbix (ZabbixNonProd, ZabbixProdOld) ← confirmed dead
│   │   │   ├── 1 ew1p-oct short hostname ← orphan
│   │   │   └── 30 partial-cluster dead nodes (ec1p/ew1r/ew2p/ue1p) ← TCP unreachable
│   │   └── DXM nodes (ew1r-dxm, ew2p-dxm, ec1p-dxm, ue1p-dxm) ← ACTIVE
│   │
│   ├── COLLECTS FROM — AWS APIs (Python via SQL Agent)
│   │   ├── CloudWatch log streams (KAPP API, NiFi, Encore IIS, BNY IIS) ← ACTIVE every 30 min
│   │   ├── AWS Cost Explorer (entity costs) ← ACTIVE daily
│   │   ├── AWS EC2/RDS/S3/IAM inventory ← ACTIVE weekly
│   │   └── Jira API (sprint data) ← ACTIVE monthly
│   │
│   ├── COLLECTS FROM — Zabbix (MSDASQL linked server)
│   │   └── ZabbixProdNew ← ACTIVE — Zabbix reads Utilities.dbo.Zab_* tables
│   │
│   ├── STORES IN — Local databases
│   │   ├── DBA_VCC_AWS (182 GB, SIMPLE) ← ACTIVE — 297M KAPP API rows, growing
│   │   ├── DBA_VCC_MEMSQL (75 GB, SIMPLE) ← STALE since May 2026 — all 7 jobs disabled
│   │   ├── KURTOSYS_BASELINE (50 GB, SIMPLE) ← ACTIVE collection, no confirmed consumer
│   │   ├── DBA_VCC_MYSQL (25 GB, SIMPLE) ← PARTIALLY ACTIVE — DXM ok, WPv2 broken
│   │   ├── DBA_VCC (20 GB, SIMPLE) ← ACTIVE — EW2P monitoring, Encore/BNY logs
│   │   ├── DBA_VCC_COST (5 GB, FULL) ← STALE since May 2026 — 280 client billing records
│   │   ├── DBA_VCC_ATLASSIAN (2 GB, SIMPLE) ← FROZEN since Dec 2023
│   │   └── Utilities (0.2 GB, SIMPLE) ← ACTIVE — DBA utility scripts
│   │
│   ├── BACKS UP TO — S3
│   │   ├── ksys-ew1r-db-backups ← ACTIVE — no --sse flag, unencrypted in transit
│   │   └── ksys-ew1p-oct-dbbackup ← ACTIVE — KMS key NULL, unencrypted at rest
│   │
│   └── INTEGRATES WITH
│       ├── Jira/Confluence (DBA_VCC_JIRA_MONTHEND_CHECKS) ← ACTIVE monthly
│       └── dba@kurtosys.com (maintenance alerts) ← ACTIVE
│
└── Grafana 9.5.2 (port 443 HTTPS — PID 3844)
    ├── READS FROM — 21 datasources
    │   ├── DBA_VCC on localhost (MSSQL) ← primary — 2 UIDs, duplicate entry
    │   ├── KAPP MySQL — Dev, Release, UK/EU/US Prod ← ACTIVE
    │   ├── KAPP Monitoring (10.120.8.208) ← ACTIVE
    │   ├── SingleStore — Dev (DEAD), Release (ALIVE), UK/EU/US Prod (ALL DEAD)
    │   ├── Zabbix MySQL — NonProd old (DEAD), NonProd current, Prod Old (DEAD), Prod current
    │   │   └── All 4 Zabbix datasources use donovan.vangraan credentials (ex-employee, inactive Nov 2024)
    │   ├── JSON API — NiFi (10.125.9.192:8443) ← ACTIVE
    │   ├── CloudWatch ← ACTIVE (IAM instance role)
    │   └── InfluxDB ← ORPHANED — no URL, zero dashboards reference it
    │
    ├── DASHBOARDS — 74 total
    │   ├── 9 confirmed active with live data and no equivalent elsewhere
    │   ├── 7 broken — dead SingleStore targets (100% packet loss)
    │   ├── 14 stale — DBA_VCC_MEMSQL disabled May 2026
    │   ├── 4 replaceable — AWS Cost Explorer / CloudWatch covers natively
    │   ├── 4 replaceable — Zabbix covers natively (middleman dashboards)
    │   ├── 2 broken — WPv2 decommissioned
    │   ├── 17 duplicate — older copies superseded
    │   ├── 2 pending confirmation — KAPP Client Utilisation, BNY IIS Log Streams
    │   └── 11 confirm before deciding — month-end, SingleStore monitoring copies
    │
    ├── ALERT RULES — 3
    │   ├── Failed Read Queries per Second → alerts-data-operations (Slack, NEVER FIRED)
    │   ├── KAPP Client Config Alert → alerts-data-operations (Slack, NEVER FIRED)
    │   └── KAPP Client Application Auth Config Alert → alert-app-allow2fa-disabled
    │       └── Contact point does NOT exist in current Grafana setup
    │
    └── USERS — 9
        ├── tashvir.babulal (admin, last seen 2026-06-09) ← ACTIVE
        ├── yogeshwar.phull (admin, last seen 2026-06-22) ← ACTIVE
        ├── rayhaan.suleyman (admin, last seen 2026-06-30) ← ACTIVE
        ├── ram.jeyaraman (viewer, last seen 2025-09-11) ← ACTIVE
        ├── jason.wolmarans (viewer, last seen 2025-02-12) ← ACTIVE
        ├── donovan.vangraan (admin, last seen 2024-11-13) ← INACTIVE — credentials in 4 datasources
        ├── admin (default, last seen 2024-11-29) ← SHOULD BE DISABLED
        ├── sunil.odedra (viewer, last seen 2023-07-12) ← INACTIVE
        └── lunga.ndzimande (admin, created 2026-07-20) ← investigation account
```

---

## Component Classification — Finalised

> Legend: **Retire** = no longer needed, safe to remove | **Replace** = function still needed, move to better platform | **Move** = keep but relocate to new host | **Confirm** = needs stakeholder answer before deciding | **Fix Now** = active failure, fix independent of decommission

### Databases

| Component | Classification | Rationale | Target |
|---|---|---|---|
| DBA_VCC (20 GB) | Replace | Core monitoring of EW2P-MSSQL-01/02 — cannot retire until replacement confirmed | CloudWatch Agent on EW2P servers |
| DBA_VCC_AWS (182 GB) | Replace | Data originates in CloudWatch — this server is a copy. KAPP API, NiFi, AWS costs, EC2/RDS inventory | CloudWatch Logs + Insights + Cost Explorer + Config |
| DBA_VCC_COST (5 GB) | Replace | 280 institutional client billing records, FULL recovery model — cannot retire without confirmed replacement and stakeholder sign-off | Dedicated licensed RDS instance |
| DBA_VCC_MYSQL (25 GB) | Replace (DXM) / Retire (WPv2) | DXM side active and needed. WPv2 side dead — linked servers gone, stored proc from 2022 | New monitoring host for DXM |
| DBA_VCC_MEMSQL (75 GB) | Retire | All 7 jobs disabled May 2026. SingleStore Prod EU/UK/US confirmed dead (100% packet loss). B3 closed — SingleStore being decommissioned | N/A |
| DBA_VCC_ATLASSIAN (2 GB) | Retire | No writer, no confirmed consumer, data frozen Dec 2023. Export to S3 cold archive before dropping | N/A |
| KURTOSYS_BASELINE (50 GB) | Retire | No confirmed consumer. Baselines dead systems (MemSQL, WPv2). MySQL baseline still collecting but no confirmed reader | N/A |
| Utilities (0.2 GB) | Move | DBA utility scripts — Ola Hallengren, Zabbix integration, KAPP schema comparison. Needed on any replacement host | New SQL Server host |

### SQL Agent Jobs

| Job Group | Count | Classification | Action |
|---|---|---|---|
| VCC AWS jobs (15min/daily/weekly) | 3 | Replace | Move to CloudWatch native monitoring + Cost Explorer |
| VCC Core monitoring jobs | 4 | Replace | Move to CloudWatch Agent on EW2P servers |
| VCC Audit Collection jobs | 16 | Replace | Move to CloudWatch Agent on EW2P servers |
| VCC Server Monitoring jobs | 8 | Replace | Move to CloudWatch Agent on EW2P servers |
| VCC MySQL / DXM jobs | 7 | Replace (DXM) / Retire (WPv2 steps) | Remove WPv2 steps. Move DXM jobs to new host |
| VCC Cost / Atlassian jobs | 2 | Replace (Cost) / Retire (Atlassian) | Cost collection needs new home. Atlassian frozen |
| DBA Maintenance jobs | 7 enabled | Move | Standard maintenance — needed on any SQL Server host |
| DBA Maintenance jobs | 4 disabled | Retire | All failed before being disabled — no recovery path |
| VCC MemSQL jobs | 7 disabled | Retire | SingleStore decommissioned — confirmed B3 closed |
| Baseline jobs | 2 | Retire | No confirmed consumer for baseline data |

### Linked Servers

| Group | Count | Classification | Action |
|---|---|---|---|
| WPv2 (ew2p-wpv2, ew2r-wpv2, ue1p-wpv2, ue1r-wpv2) | 4 | Retire immediately | DNS gone, causing 2 daily job failures. Zero risk to drop |
| gen-rel (5 nodes) | 5 | Retire immediately | Platform confirmed retired |
| gen-prd (21 nodes) | 21 | Retire immediately | Platform confirmed retired |
| ZabbixNonProd, ZabbixProdOld | 2 | Retire | Both confirmed dead. Pending infrastructure sign-off |
| ew1p-oct short hostname | 1 | Retire | Orphan — job uses full RDS hostname |
| Dead partial-cluster nodes (ec1p/ew1r/ew2p/ue1p) | 30 | Retire | TCP unreachable — confirm with platform team before dropping |
| EW2P-MSSQL-01/02 | 2 | Move | Critical — production monitoring. Must move to replacement host |
| EW1P-OCT RDS (full hostname) | 1 | Move | Backup job active — move to replacement host |
| ZabbixProdNew | 1 | Retire on decommission | Zabbix reads Utilities tables via this — Zabbix agent replaces this |
| DXM nodes (ew1r/ew2p/ec1p/ue1p-dxm) | 8 | Move | DXM monitoring active — move to replacement host |
| EW1R-TC (TeamCity) | 1 | Confirm | Purpose confirmed but decommission impact TBC |
| EW1P-NIFIREG-01 (NiFi) | 1 | Move | NiFi API active — Grafana reads this directly |
| pmmdev / pmmprod (Clickhouse) | 2 | Confirm | Both reachable — purpose and owner not yet confirmed |
| ew1d-admin-01/02 | 2 | Confirm | Dev admin nodes — confirm permanently retired before dropping |

### Grafana Datasources

| Datasource | Classification | Reason |
|---|---|---|
| DBA_VCC (a082f27e) | Move | Primary datasource — 9 active dashboards depend on it |
| DBA_VCC (e8597015) | Retire | Exact duplicate — consolidate before migration |
| KAPP UK/EU/US Prod MySQL | Move | Active dashboards reading production data |
| KAPP Monitoring (10.120.8.208) | Move | Active SingleStore monitoring dashboards |
| JSON API (NiFi) | Move | NiFi data confirmed active — no equivalent elsewhere |
| CloudWatch | Replace | CloudWatch has native dashboards — no need to duplicate in Grafana |
| SingleStore-Dev | Retire | Confirmed dead — 100% packet loss |
| SingleStore-Production-UK/EU/US | Retire | Confirmed dead — 100% packet loss. Dependent dashboards broken |
| Zabbix Nonprod old, Zabbix Prod Old | Retire | Dead targets. Ex-employee credentials |
| zabbix-server-data.shnonprd/shprd | Replace | Zabbix covers this natively. Credentials must be rotated regardless |
| KAPP Dev, KAPP Rel, MySQL generic | Confirm | Audit which dashboards reference these before deciding |
| SingleStore-Release | Confirm | Target alive — confirm if dependent dashboards still needed |
| monitoring (duplicate) | Retire | Exact duplicate of KAPP Monitoring |
| InfluxDB | Retire | Never used — zero dashboards, no URL configured |

### Grafana Dashboards (summary — full detail in Theme B)

| Classification | Count | Examples |
|---|---|---|
| Keep — live data, no equivalent elsewhere | 9 | NiFi API Reporting, Database Engineering Costs, Cluster View (current), Historical Workload Monitoring, Query History, Detailed KAPP Workflow Stats, Release/Dev Doc Gen Run Metrics |
| Keep — pending stakeholder confirmation | 2 | KAPP Client Utilisation and Growth Report, BNY IIS Log Streams |
| Replace — AWS already covers this | 4 | AWS Cost Report, AWS Cost Report Monthly, AWS EC2 Report, AWS RDS Report |
| Replace — Zabbix already covers this | 4 | Dashboard Servers Windows, SQL SERVER, Microsoft SQL Server, Zabbix Server Dashboard |
| Retire — dead datasource, no recovery | 7 | Prod EU/UK/US Doc Gen Run Metrics, NTAM Workflow, KAPP Client Config, KAPP Client App Auth Config |
| Retire — WPv2 decommissioned | 2 | WPv2 Month End Reporting (both copies) |
| Retire — MemSQL disabled, no consumer | 11 | KAPP Workflow History, KAPP API Error Reporting, KAPP Dataset dashboards, Query Performance |
| Retire — duplicate, superseded | 17 | All older duplicate copies across folders |
| Retire — never completed or dead feed | 2 | Other Services Month End Reporting Draft, Jira Projects Info |
| Retire — stale, no confirmed consumer | 5 | AWS S3/Security/DataTransfer, Server States, Zabbix Monitoring |
| Confirm before deciding | 11 | Month-end dashboards, SingleStore monitoring copies, KAPP Client Growth |

### Infrastructure

| Component | Classification | Action |
|---|---|---|
| IAM instance profile (KurtosysEC2InstanceProfileRoleRep) | Retire on decommission | Detach instance profile. No static key on disk. Confirm permissions scoped to minimum |
| S3 bucket ksys-ew1r-db-backups | Fix now + Retire on decommission | Add --sse AES256 to AWS CLI sync command now. Confirm retention policy. Stop backup job on decommission |
| S3 bucket ksys-ew1p-oct-dbbackup | Fix now | Fix KMS key NULL on EW1P-OCT RDS backup. Confirm retention policy |
| Windows Firewall rules | Retire on decommission | Documented in firewall-rules.md. AWS Security Group rules still needed from DevOps |
| Zabbix agent (port 10050, PID 5700) | Retire on decommission | Zabbix will lose visibility of this server — confirm with monitoring team |
| donovan.vangraan Grafana credentials | Fix now | Revoke Grafana admin access. Create grafana_readonly service account for Zabbix datasources |
| Default admin Grafana account | Fix now | Disable — last seen Nov 2024, no legitimate use |
| KAPP Month End Reporting snapshot (expires 2074) | Confirm now | Permanent public URL — confirm who it was shared with before retiring |
| Database Engineering Sprint Reporting snapshot (expires 2073) | Confirm | Permanent public URL — confirm who it was shared with |

---

## Decommission Blockers — Final Status

All 6 original blockers from TECH-3563 are now closed. Additional items confirmed during Themes A/B/C.

| # | Blocker | Status | Evidence |
|---|---|---|---|
| B1 | Who calls REP_MONTHEND_* each month end? | CLOSED | Called by Grafana dashboards only. No SQL Agent job. Internal use only. Confirmed Theme C |
| B2 | Is KAPP Client Utilisation dashboard client-facing? | CLOSED | Confirmed internal use only. Not client-facing. Confirmed Theme C |
| B3 | Why were DBA_VCC_MEMSQL jobs disabled May 2026? | CLOSED | SingleStore being decommissioned. All 7 jobs, DBA_VCC_MEMSQL, and 14 dashboards are retire candidates |
| B4 | Migration plan for EW2P-MSSQL-01/02 monitoring? | CLOSED — plan required | EW2P-MSSQL-01/02 confirmed SQLNCLI linked servers. No other monitoring path. Migration must be planned before decommission date |
| B5 | Is VCC framework replicated anywhere else? | CLOSED | VCC framework unique to EW1R-REP-01. No VCC databases on EW2P-MSSQL-01/02 |
| B6 | Who receives Slack alerts — would they lose visibility? | CLOSED | alerts-data-operations never fired (No attempts). alert-app-allow2fa-disabled does not exist as contact point. No active consumer |
| B7 | What IAM role/key does Python caller use? | CLOSED | EC2 instance profile KurtosysEC2InstanceProfileRoleRep. No static key on disk |
| B8 | Is ZabbixProdOld safe to remove? | CLOSED | Confirmed dead — ping timed out 2026-08-06. Pending infrastructure sign-off |
| B9 | Firewall rules documented? | CLOSED (partial) | Windows Firewall documented 2026-08-11. AWS Security Group rules still needed from DevOps |

---

## Items Still Requiring Confirmation

These are not blockers to the decommission plan being written, but must be resolved before decommission actions are executed.

| # | Item | Who to Ask | Risk if Not Answered |
|---|---|---|---|
| C1 | AWS Security Group rules for EW1R-REP-01 (10.72.8.216) | DevOps / cloud team | Incomplete firewall picture — decommission checklist cannot be finalised |
| C2 | Who was the KAPP Month End Reporting snapshot shared with (expires 2074)? | tashvir.babulal / rayhaan.suleyman | Permanent public URL may still be in use — cannot retire dashboard without confirming |
| C3 | Who was the Database Engineering Sprint Reporting snapshot shared with (expires 2073)? | tashvir.babulal / rayhaan.suleyman | Same risk as C2 |
| C4 | Are pmmdev and pmmprod (Clickhouse) linked servers still needed? | DBA / Platform team | Cannot drop without confirming no active dependency |
| C5 | Are ew1d-admin-01 and ew1d-admin-02 permanently retired? | DBA team | Cannot drop linked servers without confirmation |
| C6 | What SSIS packages does DBA - SSISStatusCheck monitor? | DBA team | Cannot retire job without knowing what it watches |
| C7 | Is EW1P-OCT RDS backup job still needed after decommission? | DBA team | If EW1P-OCT has native RDS backup, this job is redundant |
| C8 | Confirm EW2P-MSSQL-01/02 are RDS or EC2-hosted | DBA / DevOps team | Determines whether CloudWatch Agent or native RDS monitoring is the replacement path |
