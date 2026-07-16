# Linked Server Inventory — EW1R-REP-01
**Ticket:** TECH-3478 — Theme A SQL Server Inventory  
**Date captured:** 2026-07-16  
**Total linked servers:** 109 (103 MSDASQL, 6 SQLNCLI)  
**Confirmed dead:** 63  
**Confirmed reachable:** 46  

---

## Summary by Group

| Group | Total | Dead | Reachable |
|---|---|---|---|
| WPv2 (MySQL RDS) | 4 | 4 | 0 |
| gen-rel (SingleStore retired) | 5 | 5 | 0 |
| gen-prd (SingleStore retired) | 21 | 21 | 0 |
| ec1p (SingleStore) | 14 | 6 | 8 |
| ew1d (SingleStore dev) | 4 | 2 | 2 |
| ew1r aggr/leaf (SingleStore release) | 12 | 6 | 6 |
| ew2p aggr/leaf (SingleStore prod) | 22 | 7 | 15 |
| ue1p (SingleStore US prod) | 12 | 6 | 6 |
| Zabbix | 3 | 2 | 1 |
| SQLNCLI (SQL Server to SQL Server) | 6 | 1 | 5 |
| Clickhouse (pmmdev/pmmprod) | 2 | 0 | 2 |
| Other MSDASQL (EW1R-TC, EW1P-NIFIREG-01) | 2 | 0 | 2 |
| **Total** | **109** | **63** | **46** |

---

## New Findings vs Discovery

Discovery (TECH-3560) reported 11 dead linked servers. Actual count confirmed today: **63 dead (58% of all linked servers)**.

Additional findings not in discovery:
- **pmmdev / pmmprod** — two Clickhouse linked servers with NULL data_source. Not previously documented. Both reachable.
- **ZabbixNonProd and ZabbixProdOld** — both dead. Only ZabbixProdNew is reachable.
- **ew1p-oct (short hostname)** — dead. The job `DBA - Maintenance - SQL Backup EW1P-OCT` uses the full RDS hostname which is reachable. Short linked server is an orphan.
- **WPv2 ping data is false** — SP_MON_PING_STATS has xp_cmdshell commented out. All servers in V_InstanceList get Status = 1 written regardless of reachability. WPv2 servers still in LU_Serverlist as active.

---

## Dead Linked Servers — Full List (63)

### WPv2 Group (4 dead)

| Linked Server | Provider | Error | Notes |
|---|---|---|---|
| ew2p-wpv2 | MSDASQL | DNS not found — RDS instance gone | WPv2 decommissioned |
| ew2r-wpv2 | MSDASQL | DNS not found — RDS instance gone | WPv2 decommissioned |
| ue1p-wpv2 | MSDASQL | DNS not found — RDS instance gone | WPv2 decommissioned |
| ue1r-wpv2 | MSDASQL | DNS not found — RDS instance gone | WPv2 decommissioned |

### gen-rel Group (5 dead)

| Linked Server | Provider | Error | Notes |
|---|---|---|---|
| ew1r-aggr-03.gen-rel | MSDASQL | ODBC DSN not found | SingleStore gen-rel retired |
| ew1r-aggr-05.gen-rel | MSDASQL | TCP 10060 — 10.79.20.101:3306 unreachable | SingleStore gen-rel retired |
| ew1r-leaf-11.gen-rel | MSDASQL | TCP 10060 — 10.79.31.152:3306 unreachable | SingleStore gen-rel retired |
| ew1r-leaf-12.gen-rel | MSDASQL | TCP 10060 — 10.79.19.153:3306 unreachable | SingleStore gen-rel retired |
| ew1r-leaf-14.gen-rel | MSDASQL | TCP 10060 — 10.79.30.243:3306 unreachable | SingleStore gen-rel retired |

### gen-prd Group (21 dead)

| Linked Server | Provider | Error | Notes |
|---|---|---|---|
| ew2p-aggr-01.gen-prd | MSDASQL | TCP 10060 — 10.119.16.190:3306 unreachable | SingleStore gen-prd retired |
| ew2p-aggr-02.gen-prd | MSDASQL | TCP 10060 — 10.119.18.233:3306 unreachable | SingleStore gen-prd retired |
| ew2p-aggr-10.gen-prd | MSDASQL | ODBC DSN not found | SingleStore gen-prd retired |
| ew2p-aggr-11.gen-prd | MSDASQL | ODBC DSN not found | SingleStore gen-prd retired |
| ew2p-leaf-01.gen-prd | MSDASQL | TCP 10060 — 10.119.26.156:3306 unreachable | SingleStore gen-prd retired |
| ew2p-leaf-02.gen-prd | MSDASQL | TCP 10060 — 10.119.22.107:3306 unreachable | SingleStore gen-prd retired |
| ew2p-leaf-03.gen-prd | MSDASQL | TCP 10060 — 10.119.16.56:3306 unreachable | SingleStore gen-prd retired |
| ew2p-leaf-04.gen-prd | MSDASQL | TCP 10060 — 10.119.16.70:3306 unreachable | SingleStore gen-prd retired |
| ew2p-leaf-11.gen-prd | MSDASQL | ODBC DSN not found | SingleStore gen-prd retired |
| ew2p-leaf-12.gen-prd | MSDASQL | ODBC DSN not found | SingleStore gen-prd retired |
| ew2p-leaf-13.gen-prd | MSDASQL | ODBC DSN not found | SingleStore gen-prd retired |
| ew2p-leaf-14.gen-prd | MSDASQL | ODBC DSN not found | SingleStore gen-prd retired |
| ew2p-leaf-21.gen-prd | MSDASQL | ODBC DSN not found | SingleStore gen-prd retired |
| ew2p-leaf-22.gen-prd | MSDASQL | ODBC DSN not found | SingleStore gen-prd retired |
| ew2p-leaf-23.gen-prd | MSDASQL | ODBC DSN not found | SingleStore gen-prd retired |
| ew2p-leaf-24.gen-prd | MSDASQL | ODBC DSN not found | SingleStore gen-prd retired |
| ew2p-leaf-51.gen-prd | MSDASQL | TCP 10060 — 10.119.16.158:3306 unreachable | SingleStore gen-prd retired |
| ew2p-leaf-52.gen-prd | MSDASQL | TCP 10060 — 10.119.29.192:3306 unreachable | SingleStore gen-prd retired |
| ew2p-leaf-53.gen-prd | MSDASQL | TCP 10060 — 10.119.16.242:3306 unreachable | SingleStore gen-prd retired |
| ew2p-leaf-54.gen-prd | MSDASQL | TCP 10060 — 10.119.26.248:3306 unreachable | SingleStore gen-prd retired |
| ew2p-leaf-61.gen-prd | MSDASQL | ODBC DSN not found | SingleStore gen-prd retired |

### ec1p Group (6 dead)

| Linked Server | Provider | Error |
|---|---|---|
| ec1p-aggr-02 | MSDASQL | TCP 10060 — 10.125.13.194:3306 unreachable |
| ec1p-aggr-04 | MSDASQL | TCP 10060 — 10.125.21.215:3306 unreachable |
| ec1p-leaf-03 | MSDASQL | TCP 10060 — 10.125.4.74:3306 unreachable |
| ec1p-leaf-04 | MSDASQL | TCP 10060 — 10.125.1.59:3306 unreachable |
| ec1p-leaf-53 | MSDASQL | TCP 10060 — 10.125.29.14:3306 unreachable |
| ec1p-leaf-54 | MSDASQL | TCP 10060 — 10.125.17.87:3306 unreachable |

### ew1d Group (2 dead)

| Linked Server | Provider | Error |
|---|---|---|
| ew1d-admin-01 | MSDASQL | TCP 10060 — 10.61.12.200:3306 unreachable |
| ew1d-admin-02 | MSDASQL | TCP 10060 — 10.61.5.136:3306 unreachable |

### ew1r aggr/leaf Group (6 dead)

| Linked Server | Provider | Error |
|---|---|---|
| ew1r-aggr-01 | MSDASQL | TCP 10060 — 10.77.0.130:3306 unreachable |
| ew1r-aggr-02 | MSDASQL | TCP 10060 — 10.77.1.253:3306 unreachable |
| ew1r-leaf-01 | MSDASQL | TCP 10060 — 10.77.13.83:3306 unreachable |
| ew1r-leaf-02 | MSDASQL | TCP 10060 — 10.77.2.174:3306 unreachable |
| ew1r-leaf-03 | MSDASQL | TCP 10060 — 10.77.9.145:3306 unreachable |
| ew1r-leaf-04 | MSDASQL | TCP 10060 — 10.77.15.161:3306 unreachable |

### ew2p aggr/leaf Group (7 dead)

| Linked Server | Provider | Error |
|---|---|---|
| ew2p-aggr-01 | MSDASQL | TCP 10060 — 10.121.25.16:3306 unreachable |
| ew2p-aggr-02 | MSDASQL | TCP 10060 — 10.121.35.162:3306 unreachable |
| ew2p-leaf-01 | MSDASQL | TCP 10060 — 10.121.18.10:3306 unreachable |
| ew2p-leaf-02 | MSDASQL | TCP 10060 — 10.121.18.76:3306 unreachable |
| ew2p-leaf-03 | MSDASQL | TCP 10060 — 10.121.18.4:3306 unreachable |
| ew2p-leaf-51 | MSDASQL | TCP 10060 — 10.121.43.144:3306 unreachable |
| ew2p-leaf-52 | MSDASQL | TCP 10060 — 10.121.37.88:3306 unreachable |

### ue1p Group (6 dead)

| Linked Server | Provider | Error |
|---|---|---|
| ue1p-leaf-01 | MSDASQL | TCP 10060 — 10.128.25.148:3306 unreachable |
| ue1p-leaf-02 | MSDASQL | TCP 10060 — 10.128.23.245:3306 unreachable |
| ue1p-leaf-51 | MSDASQL | TCP 10060 — 10.128.41.219:3306 unreachable |
| ue1p-leaf-52 | MSDASQL | TCP 10060 — 10.128.37.156:3306 unreachable |
| ue1p-aggr-01 | MSDASQL | TCP 10060 — 10.128.31.10:3306 unreachable |
| ue1p-aggr-02 | MSDASQL | TCP 10060 — 10.128.47.148:3306 unreachable |

### Zabbix Group (2 dead)

| Linked Server | Provider | Error | Notes |
|---|---|---|---|
| ZabbixNonProd | MSDASQL | TCP 10060 — 10.72.8.191:3306 unreachable | Non-prod Zabbix gone |
| ZabbixProdOld | MSDASQL | TCP 10060 — 10.120.8.120:3306 unreachable | Old prod Zabbix decommissioned |

### SQLNCLI Group (1 dead)

| Linked Server | Provider | Error | Notes |
|---|---|---|---|
| ew1p-oct | SQLNCLI | Login timeout — server not found | Short hostname orphan — job uses full RDS hostname |

---

## Reachable Linked Servers (46)

### MSDASQL — Reachable (40)

| Linked Server | Group |
|---|---|
| ec1p-aggr-01 | ec1p SingleStore |
| ec1p-aggr-03 | ec1p SingleStore |
| ec1p-dxm | ec1p DXM |
| ec1p-dxm-logging | ec1p DXM |
| ec1p-leaf-01 | ec1p SingleStore |
| ec1p-leaf-02 | ec1p SingleStore |
| ec1p-leaf-51 | ec1p SingleStore |
| ec1p-leaf-52 | ec1p SingleStore |
| ew1d-dxm | ew1d DXM |
| ew1d-dxm-logging | ew1d DXM |
| ew1r-aggr-03 | ew1r SingleStore |
| ew1r-aggr-04 | ew1r SingleStore |
| ew1r-dxm | ew1r DXM |
| ew1r-dxm-logging | ew1r DXM |
| ew1r-leaf-05 | ew1r SingleStore |
| ew1r-leaf-06 | ew1r SingleStore |
| ew1r-leaf-07 | ew1r SingleStore |
| ew1r-leaf-08 | ew1r SingleStore |
| ew2p-aggr-03 | ew2p SingleStore |
| ew2p-aggr-04 | ew2p SingleStore |
| ew2p-dxm | ew2p DXM |
| ew2p-dxm-logging | ew2p DXM |
| ew2p-dxm-repl | ew2p DXM |
| ew2p-leaf-04 | ew2p SingleStore |
| ew2p-leaf-05 | ew2p SingleStore |
| ew2p-leaf-06 | ew2p SingleStore |
| ew2p-leaf-55 | ew2p SingleStore |
| ew2p-leaf-56 | ew2p SingleStore |
| ue1p-aggr-03 | ue1p SingleStore |
| ue1p-aggr-04 | ue1p SingleStore |
| ue1p-dxm | ue1p DXM |
| ue1p-dxm-logging | ue1p DXM |
| ue1p-dxm-repl | ue1p DXM |
| ue1p-leaf-03 | ue1p SingleStore |
| ue1p-leaf-04 | ue1p SingleStore |
| ue1p-leaf-53 | ue1p SingleStore |
| ue1p-leaf-54 | ue1p SingleStore |
| ZabbixProdNew | Zabbix |
| pmmdev | Clickhouse |
| pmmprod | Clickhouse |

### MSDASQL — Reachable, purpose unknown (2)

| Linked Server | Notes |
|---|---|
| EW1R-TC | No product name — purpose unknown, needs investigation |
| EW1P-NIFIREG-01 | No product name — purpose unknown, needs investigation |

### SQLNCLI — Reachable (5)

| Linked Server | Notes |
|---|---|
| EW1D-MSSQL-01 | SQL Server to SQL Server |
| EW1P-OCT.CNMEBXZBEDLW.EU-WEST-1.RDS.AMAZONAWS.COM | EW1P-OCT RDS — used by backup job |
| EW1R-MSSQL-01 | SQL Server to SQL Server — self-reference |
| EW2P-MSSQL-01 | SQL Server to SQL Server |
| EW2P-MSSQL-02 | SQL Server to SQL Server |

---

## Open Questions

| # | Question | Who to Ask |
|---|---|---|
| Q32 | Are gen-rel and gen-prd SingleStore nodes permanently retired? | SingleStore / Platform team |
| Q4 | Are all 109 linked servers confirmed — which are safe to drop? | DBA team |
| NEW | What are EW1R-TC and EW1P-NIFIREG-01 used for? | DBA team |
| NEW | What are pmmdev and pmmprod (Clickhouse) used for? Who owns them? | DBA team / Platform team |
| NEW | Can ew1p-oct (short hostname orphan) be dropped? | DBA team |
| NEW | Can ZabbixNonProd and ZabbixProdOld linked servers be dropped? | DBA / Monitoring team |
