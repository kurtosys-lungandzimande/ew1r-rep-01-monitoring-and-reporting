# TECH-3561 — Theme B: Grafana — Investigation Log

Scope: Grafana inventory — datasources, dashboards, users, alert rules, contact points.
Each entry has the question, the query, the evidence, and the finding.

> Status: Initial inventory complete. Not being investigated further in current sprint (TECH-3535).
> Full Grafana investigation deferred to when TECH-3561 is picked up.

---

## 2026-07-01 — Full Grafana inventory extracted from grafana.db

**Question:** What datasources, dashboards, users, and alert rules does Grafana have?

**Method:** Python scripts via xp_cmdshell reading grafana.db (SQLite) directly.
Full queries in TECH-3535-planning-and-discovery/discovery-queries.sql — Section 9.

---

### Datasources (queries 9.3 and 12.6)

**Query 9.3** — initial datasource list (name, type, url, user):
```sql
EXEC xp_cmdshell 'echo import sqlite3 > C:\temp\gf.py && echo conn = sqlite3.connect(r"C:\Program Files\GrafanaLabs\grafana\data\grafana.db") >> C:\temp\gf.py && echo rows = conn.execute("SELECT name, type, url, user FROM data_source").fetchall() >> C:\temp\gf.py && echo [print(r) for r in rows] >> C:\temp\gf.py';
EXEC xp_cmdshell 'C:\Users\sqlsrv\AppData\Local\Programs\Python\Python311\python.exe C:\temp\gf.py';
```

**Query 12.6** — full datasource list with UIDs (run 2026-07-07 to resolve dashboard datasource references):
```sql
EXEC xp_cmdshell 'echo import sqlite3 > C:\temp\gf_ds_uid.py && echo conn = sqlite3.connect(r"C:\Program Files\GrafanaLabs\grafana\data\grafana.db") >> C:\temp\gf_ds_uid.py && echo rows = conn.execute("SELECT uid, name, type, url, json_data FROM data_source ORDER BY name").fetchall() >> C:\temp\gf_ds_uid.py && echo [print(r) for r in rows] >> C:\temp\gf_ds_uid.py';
EXEC xp_cmdshell 'C:\Users\sqlsrv\AppData\Local\Programs\Python\Python311\python.exe C:\temp\gf_ds_uid.py';
```

> Note: UID column in the evidence table below comes from query 12.6. UIDs are what Grafana stores inside dashboard JSON to reference datasources — without them you cannot map a dashboard to its datasource. Query 9.3 confirmed names/types/URLs. Query 12.6 added UIDs and confirmed the full picture.

**Evidence:**

| UID | Name | Type | URL | User | Notes |
|---|---|---|---|---|---|
| a082f27e-c56e-4a68-8a35-2b761fe5a099 | DBA_VCC | mssql | localhost | grafana | Core SQL Server datasource — reads from DBA_VCC on localhost |
| e8597015-eb43-4adc-8da4-090eed43ee62 | DBA_VCC | mssql | localhost | grafana | ⚠️ Duplicate entry — same datasource registered twice |
| da173cae-70a4-42da-9340-e04e08b63046 | KAPP Dev | mysql | 10.61.11.70:3306 | root | KAPP Dev environment |
| d1679f57-82d7-4450-b676-6f71f7099bf3 | KAPP Rel | mysql | 10.77.3.236 | root | KAPP Release environment |
| cd097e22-006c-4640-8a80-f1615c5c8b45 | KAPP UK Prod | mysql | 10.121.29.82 | root | KAPP UK Production |
| e792d174-d407-4690-8fe5-97d8460049fb | KAPP EU Prod | mysql | 10.125.6.134 | root | KAPP EU Production |
| db3d6c01-d578-4052-a636-041a65f38578 | KAPP US Prod | mysql | 10.128.30.6 | root | KAPP US Production |
| f4830a0f-711b-4a69-898d-5ce8e62e241b | KAPP Monitoring | mysql | 10.120.8.208 | root | KAPP monitoring database |
| f2ca52be-523b-44bc-a70a-5ede955155eb | MySQL | mysql | 10.77.3.236:3306 | root | ⚠️ Likely duplicate of KAPP Rel — same IP |
| dce83066-258a-41f8-b5f3-8c35bee807aa | monitoring | mysql | 10.120.8.208 | root | ⚠️ Likely duplicate of KAPP Monitoring — same IP |
| d8b0939b-9523-4e83-ada8-32ba2dd3cdb6 | SingleStore-Dev | mysql | 10.61.0.95 | FundPressDataReader | SingleStore Dev environment |
| f1d911af-52de-4255-8a11-94e39eedb62a | SingleStore-Release | mysql | 10.77.6.161 | FundPressDataReader | SingleStore Release environment |
| a6046586-7d67-428e-93e1-6b274d686900 | SingleStore-Production-UK | mysql | 10.121.22.219 | FundPressDataReader | SingleStore UK Production |
| df309b44-0d9b-4411-b7f8-7baed30382d0 | SingleStore-Production-EU | mysql | 10.125.12.126 | FundPressDataReader | SingleStore EU Production |
| bfe8f780-7ecc-4306-9d2c-b691b6352cca | SingleStore-Production-US | mysql | 10.128.24.122 | FundPressDataReader | SingleStore US Production |
| dbafc322-929d-4fa8-886f-abe9d96a41aa | Zabbix Prod Old | mysql | 10.120.8.120 | donovan.vangraan | ⚠️ Stale credentials — donovan.vangraan inactive since Nov 2024 |
| d68a35f0-c99b-4ec0-87c7-f714555753de | zabbix-server-data.shprd.kurtosys-internal | mysql | 10.120.8.51 | donovan.vangraan | ⚠️ Stale credentials — donovan.vangraan inactive since Nov 2024 |
| aafbf2f7-2e78-4fa4-988a-9358fed7bfb3 | Zabbix Nonprod old | mysql | 10.72.8.191 | donovan.vangraan | ⚠️ Stale credentials — donovan.vangraan inactive since Nov 2024 |
| b10bf74c-1c94-4624-8315-8953c9b407fa | zabbix-server-data.shnonprd.kurtosys-internal | mysql | 10.72.8.186 | donovan.vangraan | ⚠️ Stale credentials — donovan.vangraan inactive since Nov 2024 |
| b7838f71-ce6c-4646-9e4b-2dacf777cd53 | JSON API | marcusolsson-json-datasource | https://10.125.9.192:8443/nifi-api/flow/process-groups/root/ | — | NiFi Registry API |
| bae6c95e-4e84-413f-9c4a-8fd719e7e7b6 | CloudWatch | cloudwatch | — | — | AWS CloudWatch — uses IAM role |
| aa82f021-baae-4259-a9f6-571d3f5f7f2d | InfluxDB | influxdb | — | — | InfluxDB — connection details not exposed |

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

> Note: User list re-run on 2026-07-07. Role determined by is_admin column (1 = Admin, 0 = Viewer). Captured on 2026-07-07.

---

### Dashboards (queries 9.5, 13.7, and 12.6)

**Query 9.5 / 13.7** — dashboard titles and last updated dates:
```sql
EXEC xp_cmdshell 'echo import sqlite3 > C:\temp\gf.py && echo conn = sqlite3.connect(r"C:\Program Files\GrafanaLabs\grafana\data\grafana.db") >> C:\temp\gf.py && echo rows = conn.execute("SELECT title, created, updated FROM dashboard WHERE is_folder=0 ORDER BY updated DESC").fetchall() >> C:\temp\gf.py && echo print(len(rows), "dashboards total") >> C:\temp\gf.py && echo [print(r) for r in rows] >> C:\temp\gf.py';
EXEC xp_cmdshell 'C:\Users\sqlsrv\AppData\Local\Programs\Python\Python311\python.exe C:\temp\gf.py';
```

**UID-to-datasource resolution** — run after 13.7 to map dashboard datasource UIDs to names (query 13.7 variant):
```sql
EXEC xp_cmdshell 'del C:\temp\gf.py';
EXEC xp_cmdshell 'echo import sqlite3, json > C:\temp\gf.py';
EXEC xp_cmdshell 'echo conn = sqlite3.connect(r"C:\Program Files\GrafanaLabs\grafana\data\grafana.db") >> C:\temp\gf.py';
EXEC xp_cmdshell 'echo rows = conn.execute("SELECT title, data FROM dashboard WHERE is_folder=0 ORDER BY updated DESC").fetchall() >> C:\temp\gf.py';
EXEC xp_cmdshell 'echo for r in rows: >> C:\temp\gf.py';
EXEC xp_cmdshell 'echo     panels = json.loads(r[1]).get("panels", []) >> C:\temp\gf.py';
EXEC xp_cmdshell 'echo     ds = set() >> C:\temp\gf.py';
EXEC xp_cmdshell 'echo     for p in panels: >> C:\temp\gf.py';
EXEC xp_cmdshell 'echo         d = p.get("datasource", "") >> C:\temp\gf.py';
EXEC xp_cmdshell 'echo         ds.add(d.get("uid", "") if isinstance(d, dict) else str(d)) >> C:\temp\gf.py';
EXEC xp_cmdshell 'echo     print(r[0], "|", ds) >> C:\temp\gf.py';
EXEC xp_cmdshell 'C:\Users\sqlsrv\AppData\Local\Programs\Python\Python311\python.exe C:\temp\gf.py';
```

> Note: The Datasource column in the evidence table below was resolved by cross-referencing the UIDs extracted from dashboard JSON against the datasource UID table from query 12.6. Raw UIDs from the dashboard scan were replaced with human-readable datasource names for clarity.

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

| Title | Contact Point | Channel | Notes |
|---|---|---|---|
| Failed Read Queries per Second | alerts-data-operations | Slack | Active |
| KAPP Client Config Alert | alerts-data-operations | Slack | Active |
| KAPP Client Application Auth Config | alert-app-allow2fa-disabled | Slack | Active |

**Total: 3 alert rules**

---

### Contact points (query 9.8)

**Query:**
```sql
EXEC xp_cmdshell 'echo import sqlite3 > C:\temp\gf.py && echo conn = sqlite3.connect(r"C:\Program Files\GrafanaLabs\grafana\data\grafana.db") >> C:\temp\gf.py && echo rows = conn.execute("SELECT alertmanager_configuration FROM alert_configuration").fetchall() >> C:\temp\gf.py && echo [print(r) for r in rows] >> C:\temp\gf.py';
EXEC xp_cmdshell 'C:\Users\sqlsrv\AppData\Local\Programs\Python\Python311\python.exe C:\temp\gf.py';
```

**Evidence:**

| Name | Type | Notes |
|---|---|---|
| alerts-data-operations | Slack | Active |
| alert-app-allow2fa-disabled | Slack | Active |
| email | Email | ⚠️ Placeholder — no address set, will not deliver |

**Total: 3 contact points (2 active Slack, 1 broken email)**

> Note: query 9.8 returns 3 rows from `alert_configuration` — Grafana stores multiple config versions in this table (factory default, old draft, current active). The contact points above are extracted from the current active config (row 2 of 3). Row 1 is an old draft with no sub-routes where all alerts defaulted to the broken email. Row 3 is the factory default Grafana ships with — never customised. The Slack webhook tokens in row 2 are encrypted — a Grafana admin login is required to view or rotate them.

**Finding:** Grafana reads directly from DBA_VCC on localhost. 4 Zabbix datasources use donovan.vangraan credentials — he is an Admin account that has not logged in since November 2024. His credentials need to be rotated and his account should be reviewed before decommission. The default `admin` account is also still active and should be disabled. Email contact point is a placeholder and will never deliver alerts. Month-end dashboards are showing stale data since May 2026 due to MemSQL jobs being disabled — nobody has flagged this.

**Open questions for TECH-3561:**
- Are any dashboards client-facing or SLA-related? (Month End Reporting and KAPP Client reports are candidates)
- Which teams use the dashboards — engineering only or wider?
- Confirm with tashvir.babulal / rayhaan.suleyman before decommission decision
