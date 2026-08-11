# External Targets Inventory — EW1R-REP-01
**Ticket:** TECH-3480 — Theme C: External Targets and Consumer Identification
**Source:** TECH-3560 linked server audit (2026-07-16) + TECH-3562 discovery
**Total linked servers:** 109
**Dead:** 63 (58%)
**Reachable:** 46 (42%)

---

## Summary by Group

| Group | Total | Dead | Reachable | Notes |
|---|---|---|---|---|
| WPv2 (MySQL RDS) | 4 | 4 | 0 | Platform decommissioned — DNS gone |
| gen-rel (SingleStore retired) | 5 | 5 | 0 | Platform retired |
| gen-prd (SingleStore retired) | 21 | 21 | 0 | Platform retired |
| ec1p (SingleStore EU Central prod) | 14 | 6 | 8 | Partial — 6 nodes unreachable |
| ew1d (SingleStore dev) | 4 | 2 | 2 | Admin nodes dead, DXM reachable |
| ew1r aggr/leaf (SingleStore release) | 12 | 6 | 6 | Half dead |
| ew2p aggr/leaf (SingleStore EU West prod) | 22 | 7 | 15 | Partial |
| ue1p (SingleStore US East prod) | 12 | 6 | 6 | Half dead |
| Zabbix | 3 | 2 | 1 | ZabbixNonProd + ZabbixProdOld dead |
| SQLNCLI (SQL Server) | 6 | 1 | 5 | ew1p-oct short hostname orphan |
| Clickhouse (pmmdev/pmmprod) | 2 | 0 | 2 | Both reachable — purpose TBC |
| Other (EW1R-TC, EW1P-NIFIREG-01) | 2 | 0 | 2 | Both reachable — confirmed purposes |
| **Total** | **109** | **63** | **46** | |

---

## Dead Linked Servers — Full List (63)

### WPv2 Group — 4 dead Flagged for cleanup

| Linked Server | Provider | Error | Action |
|---|---|---|---|
| ew2p-wpv2 | MSDASQL | DNS not found — RDS gone | Drop linked server, remove from LU_Serverlist |
| ew2r-wpv2 | MSDASQL | DNS not found — RDS gone | Drop linked server, remove from LU_Serverlist |
| ue1p-wpv2 | MSDASQL | DNS not found — RDS gone | Drop linked server, remove from LU_Serverlist |
| ue1r-wpv2 | MSDASQL | DNS not found — RDS gone | Drop linked server, remove from LU_Serverlist |

> Root cause: WPv2 platform decommissioned. Jobs DBA_VCC_MYSQL_DAILY_CHECKS and DBA_VCC_MYSQL_AUDIT_DXM_CLIENT_DETAILED fail daily because SP_AUDIT_WPv2_CLIENTS_DETAILED still calls OPENQUERY against these servers. No alert fires — silent failures since decommission.

### gen-rel Group — 5 dead Flagged for cleanup

| Linked Server | Provider | Error |
|---|---|---|
| ew1r-aggr-03.gen-rel | MSDASQL | ODBC DSN not found |
| ew1r-aggr-05.gen-rel | MSDASQL | TCP 10060 — 10.79.20.101:3306 unreachable |
| ew1r-leaf-11.gen-rel | MSDASQL | TCP 10060 — 10.79.31.152:3306 unreachable |
| ew1r-leaf-12.gen-rel | MSDASQL | TCP 10060 — 10.79.19.153:3306 unreachable |
| ew1r-leaf-14.gen-rel | MSDASQL | TCP 10060 — 10.79.30.243:3306 unreachable |

### gen-prd Group — 21 dead Flagged for cleanup

| Linked Server | Provider | Error |
|---|---|---|
| ew2p-aggr-01.gen-prd | MSDASQL | TCP 10060 — 10.119.16.190:3306 unreachable |
| ew2p-aggr-02.gen-prd | MSDASQL | TCP 10060 — 10.119.18.233:3306 unreachable |
| ew2p-aggr-10.gen-prd | MSDASQL | ODBC DSN not found |
| ew2p-aggr-11.gen-prd | MSDASQL | ODBC DSN not found |
| ew2p-leaf-01.gen-prd | MSDASQL | TCP 10060 — 10.119.26.156:3306 unreachable |
| ew2p-leaf-02.gen-prd | MSDASQL | TCP 10060 — 10.119.22.107:3306 unreachable |
| ew2p-leaf-03.gen-prd | MSDASQL | TCP 10060 — 10.119.16.56:3306 unreachable |
| ew2p-leaf-04.gen-prd | MSDASQL | TCP 10060 — 10.119.16.70:3306 unreachable |
| ew2p-leaf-11.gen-prd | MSDASQL | ODBC DSN not found |
| ew2p-leaf-12.gen-prd | MSDASQL | ODBC DSN not found |
| ew2p-leaf-13.gen-prd | MSDASQL | ODBC DSN not found |
| ew2p-leaf-14.gen-prd | MSDASQL | ODBC DSN not found |
| ew2p-leaf-21.gen-prd | MSDASQL | ODBC DSN not found |
| ew2p-leaf-22.gen-prd | MSDASQL | ODBC DSN not found |
| ew2p-leaf-23.gen-prd | MSDASQL | ODBC DSN not found |
| ew2p-leaf-24.gen-prd | MSDASQL | ODBC DSN not found |
| ew2p-leaf-51.gen-prd | MSDASQL | TCP 10060 — 10.119.16.158:3306 unreachable |
| ew2p-leaf-52.gen-prd | MSDASQL | TCP 10060 — 10.119.29.192:3306 unreachable |
| ew2p-leaf-53.gen-prd | MSDASQL | TCP 10060 — 10.119.16.242:3306 unreachable |
| ew2p-leaf-54.gen-prd | MSDASQL | TCP 10060 — 10.119.26.248:3306 unreachable |
| ew2p-leaf-61.gen-prd | MSDASQL | ODBC DSN not found |

### ec1p Group — 6 dead

| Linked Server | Provider | Error |
|---|---|---|
| ec1p-aggr-02 | MSDASQL | TCP 10060 — 10.125.13.194:3306 unreachable |
| ec1p-aggr-04 | MSDASQL | TCP 10060 — 10.125.21.215:3306 unreachable |
| ec1p-leaf-03 | MSDASQL | TCP 10060 — 10.125.4.74:3306 unreachable |
| ec1p-leaf-04 | MSDASQL | TCP 10060 — 10.125.1.59:3306 unreachable |
| ec1p-leaf-53 | MSDASQL | TCP 10060 — 10.125.29.14:3306 unreachable |
| ec1p-leaf-54 | MSDASQL | TCP 10060 — 10.125.17.87:3306 unreachable |

### ew1d Group — 2 dead

| Linked Server | Provider | Error |
|---|---|---|
| ew1d-admin-01 | MSDASQL | TCP 10060 — 10.61.12.200:3306 unreachable |
| ew1d-admin-02 | MSDASQL | TCP 10060 — 10.61.5.136:3306 unreachable |

### ew1r aggr/leaf Group — 6 dead

| Linked Server | Provider | Error |
|---|---|---|
| ew1r-aggr-01 | MSDASQL | TCP 10060 — 10.77.0.130:3306 unreachable |
| ew1r-aggr-02 | MSDASQL | TCP 10060 — 10.77.1.253:3306 unreachable |
| ew1r-leaf-01 | MSDASQL | TCP 10060 — 10.77.13.83:3306 unreachable |
| ew1r-leaf-02 | MSDASQL | TCP 10060 — 10.77.2.174:3306 unreachable |
| ew1r-leaf-03 | MSDASQL | TCP 10060 — 10.77.9.145:3306 unreachable |
| ew1r-leaf-04 | MSDASQL | TCP 10060 — 10.77.15.161:3306 unreachable |

### ew2p aggr/leaf Group — 7 dead

| Linked Server | Provider | Error |
|---|---|---|
| ew2p-aggr-01 | MSDASQL | TCP 10060 — 10.121.25.16:3306 unreachable |
| ew2p-aggr-02 | MSDASQL | TCP 10060 — 10.121.35.162:3306 unreachable |
| ew2p-leaf-01 | MSDASQL | TCP 10060 — 10.121.18.10:3306 unreachable |
| ew2p-leaf-02 | MSDASQL | TCP 10060 — 10.121.18.76:3306 unreachable |
| ew2p-leaf-03 | MSDASQL | TCP 10060 — 10.121.18.4:3306 unreachable |
| ew2p-leaf-51 | MSDASQL | TCP 10060 — 10.121.43.144:3306 unreachable |
| ew2p-leaf-52 | MSDASQL | TCP 10060 — 10.121.37.88:3306 unreachable |

### ue1p Group — 6 dead

| Linked Server | Provider | Error |
|---|---|---|
| ue1p-leaf-01 | MSDASQL | TCP 10060 — 10.128.25.148:3306 unreachable |
| ue1p-leaf-02 | MSDASQL | TCP 10060 — 10.128.23.245:3306 unreachable |
| ue1p-leaf-51 | MSDASQL | TCP 10060 — 10.128.41.219:3306 unreachable |
| ue1p-leaf-52 | MSDASQL | TCP 10060 — 10.128.37.156:3306 unreachable |
| ue1p-aggr-01 | MSDASQL | TCP 10060 — 10.128.31.10:3306 unreachable |
| ue1p-aggr-02 | MSDASQL | TCP 10060 — 10.128.47.148:3306 unreachable |

### Zabbix Group — 2 dead Flagged for cleanup

| Linked Server | Provider | Error | Notes |
|---|---|---|---|
| ZabbixNonProd | MSDASQL | TCP 10060 — 10.72.8.191:3306 unreachable | Non-prod Zabbix gone |
| ZabbixProdOld | MSDASQL | TCP 10060 — 10.120.8.120:3306 unreachable | Old prod Zabbix — confirmed dead |

### SQLNCLI Group — 1 dead

| Linked Server | Provider | Error | Notes |
|---|---|---|---|
| ew1p-oct | SQLNCLI | Login timeout — server not found | Short hostname orphan — job uses full RDS hostname. Safe to drop. |

---

## Reachable Linked Servers (46)

### MSDASQL — SingleStore / MySQL (40 reachable)

| Linked Server | Group | Environment | Status |
|---|---|---|---|
| ec1p-aggr-01 | ec1p | EU Central prod | Active |
| ec1p-aggr-03 | ec1p | EU Central prod | Active |
| ec1p-dxm | ec1p DXM | EU Central prod | Active |
| ec1p-dxm-logging | ec1p DXM | EU Central prod | Active |
| ec1p-leaf-01 | ec1p | EU Central prod | Active |
| ec1p-leaf-02 | ec1p | EU Central prod | Active |
| ec1p-leaf-51 | ec1p | EU Central prod | Active |
| ec1p-leaf-52 | ec1p | EU Central prod | Active |
| ew1d-dxm | ew1d DXM | Dev | Active |
| ew1d-dxm-logging | ew1d DXM | Dev | Active |
| ew1r-aggr-03 | ew1r | Release | Active |
| ew1r-aggr-04 | ew1r | Release | Active |
| ew1r-dxm | ew1r DXM | Release | Active |
| ew1r-dxm-logging | ew1r DXM | Release | Active |
| ew1r-leaf-05 | ew1r | Release | Active |
| ew1r-leaf-06 | ew1r | Release | Active |
| ew1r-leaf-07 | ew1r | Release | Active |
| ew1r-leaf-08 | ew1r | Release | Active |
| ew2p-aggr-03 | ew2p | EU West prod | Active |
| ew2p-aggr-04 | ew2p | EU West prod | Active |
| ew2p-dxm | ew2p DXM | EU West prod | Active |
| ew2p-dxm-logging | ew2p DXM | EU West prod | Active |
| ew2p-dxm-repl | ew2p DXM | EU West prod | Active |
| ew2p-leaf-04 | ew2p | EU West prod | Active |
| ew2p-leaf-05 | ew2p | EU West prod | Active |
| ew2p-leaf-06 | ew2p | EU West prod | Active |
| ew2p-leaf-55 | ew2p | EU West prod | Active |
| ew2p-leaf-56 | ew2p | EU West prod | Active |
| ue1p-aggr-03 | ue1p | US East prod | Active |
| ue1p-aggr-04 | ue1p | US East prod | Active |
| ue1p-dxm | ue1p DXM | US East prod | Active |
| ue1p-dxm-logging | ue1p DXM | US East prod | Active |
| ue1p-dxm-repl | ue1p DXM | US East prod | Active |
| ue1p-leaf-03 | ue1p | US East prod | Active |
| ue1p-leaf-04 | ue1p | US East prod | Active |
| ue1p-leaf-53 | ue1p | US East prod | Active |
| ue1p-leaf-54 | ue1p | US East prod | Active |
| ZabbixProdNew | Zabbix | Production | Active — only live Zabbix linked server |
| pmmdev | Clickhouse (PMM) | Dev | Reachable — purpose needs confirmation |
| pmmprod | Clickhouse (PMM) | Production | Reachable — purpose needs confirmation |

### MSDASQL — Other (2 reachable, confirmed)

| Linked Server | Purpose | Status |
|---|---|---|
| EW1R-TC | TeamCity CI/CD — Release environment | Active — confirmed via LU_EntityList |
| EW1P-NIFIREG-01 | Apache NiFi pipeline registry | Active — confirmed Grafana JSON API datasource |

### SQLNCLI — SQL Server to SQL Server (5 reachable)

| Linked Server | Purpose | Status |
|---|---|---|
| EW1D-MSSQL-01 | Dev SQL Server | Active |
| EW1P-OCT.CNMEBXZBEDLW.EU-WEST-1.RDS.AMAZONAWS.COM | EW1P-OCT RDS — used by backup job | Active |
| EW1R-MSSQL-01 | Self-reference — Release SQL Server | Active |
| EW2P-MSSQL-01 | Production SQL Server — monitored by 16 VCC audit jobs | Active — critical |
| EW2P-MSSQL-02 | Production SQL Server — monitored by 16 VCC audit jobs | Active — critical |

---

## S3 Backup Targets

| Bucket | Path | Used By | Encryption | Retention |
|---|---|---|---|---|
| ksys-ew1r-db-backups | Backups/Reporting/EW1R-REP-01/ | DBA - Maintenance - SQL Backups FULL/DIFF/LOG | None — no --sse flag in AWS CLI sync command | TBC — check S3 lifecycle rule |
| ksys-ew1p-oct-dbbackup | backup/octopus_db_<date>.bak | DBA - Maintenance - SQL Backup EW1P-OCT | KMS key NULL — unencrypted at rest | TBC — check S3 lifecycle rule |

---

## Cleanup Actions Required

| Target | Action | Priority | Owner |
|---|---|---|---|
| ew2p-wpv2, ew2r-wpv2, ue1p-wpv2, ue1r-wpv2 | Drop linked servers + remove from LU_Serverlist + fix SP_AUDIT_WPv2_CLIENTS_DETAILED | High | DBA team |
| All 26 gen-rel + gen-prd linked servers | Drop linked servers — platform confirmed retired | High | DBA team |
| ZabbixNonProd, ZabbixProdOld | Drop linked servers — both confirmed dead | Medium | DBA / Monitoring team |
| ew1p-oct (short hostname) | Drop linked server — orphan, job uses full RDS hostname | Low | DBA team |
| pmmdev, pmmprod | Confirm purpose and owner before any action | Medium | DBA / Platform team |
| ew1d-admin-01, ew1d-admin-02 | Confirm permanently retired before dropping | Medium | DBA team |
