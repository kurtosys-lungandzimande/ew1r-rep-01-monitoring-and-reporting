# TECH-3479 — Theme B: Grafana — Investigation Log

Scope: Grafana inventory — datasources, dashboards, users, alert rules, contact points.
Each entry has the question, the query, the evidence, and the finding.

> Status: Initial inventory complete. Not being investigated further in current sprint (TECH-3535).
> Full Grafana investigation deferred to when TECH-3479 is picked up.

---

## 2026-07-01 — Full Grafana inventory extracted from grafana.db

**Question:** What datasources, dashboards, users, and alert rules does Grafana have?

**Method:** Python scripts via xp_cmdshell reading grafana.db (SQLite) directly.
Full queries in TECH-3535-planning-and-discovery/discovery-queries.sql — Section 9.

---

### Datasources (query 9.3)

**Query:**
```sql
EXEC xp_cmdshell 'echo import sqlite3 > C:\temp\gf.py && echo conn = sqlite3.connect(r"C:\Program Files\GrafanaLabs\grafana\data\grafana.db") >> C:\temp\gf.py && echo rows = conn.execute("SELECT name, type, url, user FROM data_source").fetchall() >> C:\temp\gf.py && echo [print(r) for r in rows] >> C:\temp\gf.py';
EXEC xp_cmdshell 'C:\Users\sqlsrv\AppData\Local\Programs\Python\Python311\python.exe C:\temp\gf.py';
```

**Evidence:**

| Name | Type | URL | User | Notes |
|---|---|---|---|---|
| DBA_VCC | mssql | localhost | grafana | Core SQL Server datasource — reads from DBA_VCC on localhost |
| DBA_VCC | mssql | localhost | grafana | ⚠️ Duplicate entry — same datasource registered twice |
| KAPP Dev | mysql | 10.61.11.70:3306 | root | KAPP Dev environment |
| KAPP Rel | mysql | 10.77.3.236 | root | KAPP Release environment |
| KAPP UK Prod | mysql | 10.121.29.82 | root | KAPP UK Production |
| KAPP EU Prod | mysql | 10.125.6.134 | root | KAPP EU Production |
| KAPP US Prod | mysql | 10.128.30.6 | root | KAPP US Production |
| KAPP Monitoring | mysql | 10.120.8.208 | root | KAPP monitoring database |
| MySQL | mysql | 10.77.3.236:3306 | root | ⚠️ Likely duplicate of KAPP Rel — same IP |
| monitoring | mysql | 10.120.8.208 | root | ⚠️ Likely duplicate of KAPP Monitoring — same IP |
| SingleStore-Dev | mysql | 10.61.0.95 | FundPressDataReader | SingleStore Dev environment |
| SingleStore-Release | mysql | 10.77.6.161 | FundPressDataReader | SingleStore Release environment |
| SingleStore-Production-UK | mysql | 10.121.22.219 | FundPressDataReader | SingleStore UK Production |
| SingleStore-Production-EU | mysql | 10.125.12.126 | FundPressDataReader | SingleStore EU Production |
| SingleStore-Production-US | mysql | 10.128.24.122 | FundPressDataReader | SingleStore US Production |
| Zabbix Prod Old | mysql | 10.120.8.120 | donovan.vangraan | ⚠️ Stale credentials — donovan.vangraan inactive since Nov 2024 |
| zabbix-server-data.shprd.kurtosys-internal | mysql | 10.120.8.51 | donovan.vangraan | ⚠️ Stale credentials — donovan.vangraan inactive since Nov 2024 |
| Zabbix Nonprod old | mysql | 10.72.8.191 | donovan.vangraan | ⚠️ Stale credentials — donovan.vangraan inactive since Nov 2024 |
| zabbix-server-data.shnonprd.kurtosys-internal | mysql | 10.72.8.186 | donovan.vangraan | ⚠️ Stale credentials — donovan.vangraan inactive since Nov 2024 |
| JSON API | marcusolsson-json-datasource | https://10.125.9.192:8443/nifi-api/flow/process-groups/root/ | — | NiFi Registry API |
| CloudWatch | cloudwatch | — | — | AWS CloudWatch — uses IAM role |
| InfluxDB | influxdb | — | — | InfluxDB — connection details not exposed |

**Total: 22 rows returned (1 duplicate DBA_VCC entry, 1 NULL row). Distinct datasources: 21.**

---

### Users (query 9.4)

**Query:**
```sql
EXEC xp_cmdshell 'echo import sqlite3 > C:\temp\gf.py && echo conn = sqlite3.connect(r"C:\Program Files\GrafanaLabs\grafana\data\grafana.db") >> C:\temp\gf.py && echo rows = conn.execute("SELECT login, email, name, is_admin, last_seen_at FROM user").fetchall() >> C:\temp\gf.py && echo [print(r) for r in rows] >> C:\temp\gf.py';
EXEC xp_cmdshell 'C:\Users\sqlsrv\AppData\Local\Programs\Python\Python311\python.exe C:\temp\gf.py';
```

**Evidence:**

| Login | Name | Email | Role | Last Seen | Notes |
|---|---|---|---|---|---|
| admin | — | admin@localhost | Admin | 2024-11-29 | ⚠️ Default admin account — no real name, should be disabled |
| donovan.vangraan | Donovan van Graan | donovan.vangraan@kurtosys.com | Admin | 2024-11-13 | ⚠️ Inactive since Nov 2024 — credentials still in 4 Zabbix datasources |
| tashvir.babulal | Tashvir Babulal | tashvir.babulal@kurtosys.com | Admin | 2026-06-09 | Active |
| yogeshwar.phull | Yogeshwar Phull | yogeshwar.phull@kurtosys.com | Admin | 2026-06-22 | Active |
| rayhaan.suleyman | Rayhaan Suleyman | rayhaan.suleyman@kurtosys.com | Admin | 2026-07-07 | Active |
| ram.jeyaraman | Ram Jeyaraman | ram@kurtosys.com | Viewer | 2025-09-11 | Active |
| jason.wolmarans | Jason Wolmarans | jason.wolmarans@kurtosys.com | Viewer | 2025-02-12 | Active |
| sunil.odedra | Sunil Odedra | sunil.odedra@kurtosys.com | Viewer | 2023-07-12 | ⚠️ Inactive since Jul 2023 |

**Total: 8 users (5 admins, 3 viewers, 1 NULL row ignored)**

> Note: User list re-run on 2026-07-07. Role determined by is_admin column (1 = Admin, 0 = Viewer).

---

### Dashboards (queries 9.5 and 13.7)

**Query:**
```sql
EXEC xp_cmdshell 'echo import sqlite3 > C:\temp\gf.py && echo conn = sqlite3.connect(r"C:\Program Files\GrafanaLabs\grafana\data\grafana.db") >> C:\temp\gf.py && echo rows = conn.execute("SELECT title, created, updated FROM dashboard WHERE is_folder=0 ORDER BY updated DESC").fetchall() >> C:\temp\gf.py && echo print(len(rows), "dashboards total") >> C:\temp\gf.py && echo [print(r) for r in rows] >> C:\temp\gf.py';
EXEC xp_cmdshell 'C:\Users\sqlsrv\AppData\Local\Programs\Python\Python311\python.exe C:\temp\gf.py';
```

**Evidence:**

| Title | Datasource | Last Updated | Notes |
|---|---|---|---|
| Prod US Document Generation Run Metrics | SingleStore-Production-US | 2025-10-29 | Active |
| Prod UK Document Generation Run Metrics | SingleStore-Production-UK | 2025-10-29 | Active |
| Prod EU Document Generation Run Metrics | SingleStore-Production-EU | 2025-10-29 | Active |
| Release Document Generation Run Metrics | SingleStore-Release | 2025-10-29 | Active |
| Development Document Generation Run Metrics | SingleStore-Dev | 2025-10-29 | Active |
| NTAM Workflow by workflowRunId | SingleStore-Production-US | 2025-09-07 | Active |
| Detailed KAPP Workflow Document Generation Stats | SingleStore-Dev | 2025-08-18 | Active |
| Query History | monitoring (KAPP Monitoring) | 2025-08-07 | Active |
| Historical Workload Monitoring | KAPP Monitoring, SingleStore-Production-UK | 2025-08-07 | Active |
| Cluster View | SingleStore-Production-UK | 2025-06-23 | Active |
| KAPP Dataset Query and Source Execution | DBA_VCC | 2024-11-20 | ⚠️ Stale — MEMSQL feed disabled May 2026 |
| KAPP Dataset Query Execution | DBA_VCC | 2024-11-07 | ⚠️ Stale — MEMSQL feed disabled May 2026 |
| Grafana Dashboard Exporter/Importer | — | 2024-10-29 | Utility dashboard |
| KAPP Client Application Auth Config | DBA_VCC | 2024-10-29 | ⚠️ Stale — MEMSQL feed disabled May 2026 |
| KAPP Dataset Lambdas Time Outs | DBA_VCC | 2024-10-23 | ⚠️ Stale — MEMSQL feed disabled May 2026 |
| Database Engineering Costs | DBA_VCC | 2024-10-15 | Internal |
| KAPP Client Config | DBA_VCC | 2024-09-02 | ⚠️ Stale — MEMSQL feed disabled May 2026 |
| Resource Pool Monitoring | monitoring (KAPP Monitoring) | 2024-07-12 | SingleStore monitoring |
| Pipeline Summary | monitoring (KAPP Monitoring) | 2024-07-12 | SingleStore monitoring |
| Pipeline Performance | monitoring (KAPP Monitoring) | 2024-07-12 | SingleStore monitoring |
| Memory Usage | monitoring (KAPP Monitoring) | 2024-07-12 | SingleStore monitoring |
| Historical Workload Monitoring | monitoring (KAPP Monitoring) | 2024-07-12 | ⚠️ Duplicate title — older copy |
| Disk Usage | monitoring (KAPP Monitoring) | 2024-07-12 | SingleStore monitoring |
| Detailed Cluster View By Node | monitoring (KAPP Monitoring) | 2024-07-12 | SingleStore monitoring |
| Cluster View | monitoring (KAPP Monitoring) | 2024-07-12 | ⚠️ Duplicate title — older copy |
| WPv2 Month End Reporting | DBA_VCC | 2024-06-20 | ⚠️ Stale — WPv2 decommissioned |
| KAPP Workflow Times History | DBA_VCC | 2024-06-12 | ⚠️ Stale — MEMSQL feed disabled May 2026 |
| KAPP Orphaned and Duplicated Records Report | DBA_VCC | 2024-03-26 | ⚠️ Stale — MEMSQL feed disabled May 2026 |
| KAPP API Error Reporting | DBA_VCC | 2024-03-11 | ⚠️ Stale — MEMSQL feed disabled May 2026 |
| Database Engineering Sprint Reporting | DBA_VCC | 2024-03-08 | Internal |
| Query Performance Dashboard | DBA_VCC | 2024-03-07 | ⚠️ Stale — MEMSQL feed disabled May 2026 |
| KAPP Workflow History | DBA_VCC | 2024-03-07 | ⚠️ Stale — MEMSQL feed disabled May 2026 |
| KAPP Client Growth | DBA_VCC | 2024-02-28 | ⚠️ Duplicate title — older copy |
| KAPP API Query Reporting | DBA_VCC | 2024-02-23 | ⚠️ Stale |
| KAPP Client Utilisation and Growth Report | DBA_VCC, KAPP Dev | 2024-02-22 | ⚠️ High risk — name suggests client-facing |
| AWS DataTransfer AZ Bytes Report | DBA_VCC | 2024-02-20 | AWS reporting |
| Nifi API Reporting | DBA_VCC | 2024-02-15 | NiFi monitoring |
| Jira Projects Info | DBA_VCC | 2023-12-08 | Jira reporting |
| KAPP Client Growth | DBA_VCC | 2023-11-16 | ⚠️ Duplicate title |
| Zabbix Monitoring | Zabbix Prod Old, zabbix-server-data.shprd, Zabbix Nonprod old, zabbix-server-data.shnonprd | 2023-10-27 | ⚠️ All 4 datasources use donovan.vangraan credentials |
| Database Engineering Costs | DBA_VCC | 2023-10-12 | ⚠️ Duplicate title — older copy |
| AWS Cost Report Monthly | DBA_VCC, KAPP Dev | 2023-10-06 | ⚠️ Stale — AWS cost data stale since Sept 2024 |
| Nifi API Reporting Copy | DBA_VCC, KAPP Dev | 2023-09-21 | ⚠️ Stale copy |
| Database Engineering Sprint Reporting | DBA_VCC | 2023-09-15 | ⚠️ Duplicate title — older copy |
| Memory Usage | SingleStore-Production-UK | 2023-09-07 | ⚠️ Duplicate title — older copy |
| Detailed Cluster View By Node | SingleStore-Production-UK | 2023-09-07 | ⚠️ Duplicate title — older copy |
| Dashboard Servers Windows | DBA_VCC, KAPP Dev | 2023-09-05 | Zabbix/Windows monitoring |
| SQL SERVER | DBA_VCC, KAPP Dev | 2023-09-05 | SQL Server monitoring |
| Microsoft SQL Server | DBA_VCC | 2023-09-05 | SQL Server monitoring |
| Zabbix Server Dashboard | DBA_VCC | 2023-09-05 | Zabbix |
| AWS RDS Report | DBA_VCC | 2023-08-21 | AWS reporting |
| Encore Document Production Runtimes | DBA_VCC | 2023-08-16 | Encore monitoring |
| Encore Month End Reporting | DBA_VCC | 2023-08-10 | ⚠️ Stale — month-end, no dedicated job |
| DXM Month End Reporting | DBA_VCC | 2023-08-10 | ⚠️ Stale — month-end, no dedicated job |
| InvestorPress Month End Reporting | DBA_VCC | 2023-08-10 | ⚠️ Stale — month-end, no dedicated job |
| KAPP Month End Reporting | DBA_VCC | 2023-08-10 | ⚠️ Stale — month-end, no dedicated job |
| AWS Security Report | DBA_VCC, KAPP Dev | 2023-08-10 | AWS reporting |
| KAPP Orphaned and Duplicated Records Report | DBA_VCC | 2023-08-10 | ⚠️ Duplicate title — older copy |
| AWS S3 Report | DBA_VCC | 2023-08-09 | AWS reporting |
| AWS EC2 Report | DBA_VCC | 2023-08-09 | ⚠️ Duplicate title |
| AWS EC2 Report | DBA_VCC | 2023-08-09 | ⚠️ Duplicate title — older copy |
| AWS RDS Report | DBA_VCC | 2023-08-09 | ⚠️ Duplicate title — older copy |
| Home | DBA_VCC | 2023-08-09 | Home dashboard |
| AWS Cost Report | DBA_VCC, KAPP Dev | 2023-08-09 | ⚠️ Stale — AWS cost data stale since Sept 2024 |
| Other Services Month End Reporting -- Draft | DBA_VCC | 2023-07-21 | ⚠️ Draft — month-end, no dedicated job |
| AWS S3 Report | DBA_VCC | 2023-07-13 | ⚠️ Duplicate title — older copy |
| BNY IIS Log Streams | DBA_VCC | 2023-07-11 | ⚠️ BNY — external client? Needs confirmation before decommission |
| Encore Document Production Runtimes | DBA_VCC | 2023-07-09 | ⚠️ Duplicate title — older copy |
| DXM Month End Reporting | DBA_VCC | 2023-07-07 | ⚠️ Duplicate title — older copy |
| WPv2 Month End Reporting | DBA_VCC | 2023-07-07 | ⚠️ Duplicate title — older copy |
| Encore Month End Reporting | DBA_VCC | 2023-07-07 | ⚠️ Duplicate title — older copy |
| KAPP Month End Reporting | DBA_VCC | 2023-07-05 | ⚠️ Duplicate title — older copy |
| InvestorPress Month End Reporting | DBA_VCC | 2023-07-05 | ⚠️ Duplicate title — older copy |
| Server States | DBA_VCC | 2023-05-29 | Server monitoring |

**Total: 74 dashboards. 10 actively updated (2025+). Majority read from DBA_VCC (SQL Server localhost) — decommissioning this server breaks them all.**

> Note: Initial count from query 9.5 showed 90. Recount via query 13.7 on 2026-07-07 confirmed 74. Difference due to deleted/archived dashboards between runs.

---

### Alert rules (query 9.7)

**Query:**
```sql
EXEC xp_cmdshell 'echo import sqlite3 > C:\temp\gf.py && echo conn = sqlite3.connect(r"C:\Program Files\GrafanaLabs\grafana\data\grafana.db") >> C:\temp\gf.py && echo rows = conn.execute("SELECT title, condition, no_data_state, exec_err_state, is_paused, updated FROM alert_rule").fetchall() >> C:\temp\gf.py && echo [print(r) for r in rows] >> C:\temp\gf.py';
EXEC xp_cmdshell 'C:\Users\sqlsrv\AppData\Local\Programs\Python\Python311\python.exe C:\temp\gf.py';
```

**Evidence:**
```
Alert rules: 3
  Failed Read Queries per Second        → alerts-data-operations (Slack)
  KAPP Client Config Alert              → alerts-data-operations (Slack)
  KAPP Client Application Auth Config   → alert-app-allow2fa-disabled (Slack)
```

---

### Contact points (query 9.8)

**Query:**
```sql
EXEC xp_cmdshell 'echo import sqlite3 > C:\temp\gf.py && echo conn = sqlite3.connect(r"C:\Program Files\GrafanaLabs\grafana\data\grafana.db") >> C:\temp\gf.py && echo rows = conn.execute("SELECT alertmanager_configuration FROM alert_configuration").fetchall() >> C:\temp\gf.py && echo [print(r) for r in rows] >> C:\temp\gf.py';
EXEC xp_cmdshell 'C:\Users\sqlsrv\AppData\Local\Programs\Python\Python311\python.exe C:\temp\gf.py';
```

**Evidence:**
```
Contact points:
  alerts-data-operations       Slack  active
  alert-app-allow2fa-disabled  Slack  active
  email                        Email  placeholder — no address set, will not deliver
```

**Finding:** Grafana reads directly from DBA_VCC on localhost. 4 Zabbix datasources use donovan.vangraan credentials — he has not logged in since November 2024 and is no longer active. His credentials need to be rotated before decommission. Email contact point is a placeholder and will never deliver alerts. Month-end dashboards are showing stale data since May 2026 due to MemSQL jobs being disabled — nobody has flagged this.

**Open questions for TECH-3479:**
- Are any dashboards client-facing or SLA-related? (Month End Reporting and KAPP Client reports are candidates)
- Which teams use the dashboards — engineering only or wider?
- Confirm with tashvir.babulal / rayhaan.suleyman before decommission decision
