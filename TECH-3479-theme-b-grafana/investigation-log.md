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
```
Users: 8 total
  tashvir.babulal    admin   last_seen 2026-06-28   active
  yogeshwar.phull    admin   last_seen 2026-06-15   active
  rayhaan.suleyman   admin   last_seen 2026-06-30   active
  donovan.vangraan   editor  last_seen 2024-11-12   INACTIVE — credentials still in 4 datasources
  [4 additional viewer accounts]
```

> Note: User list was captured on 2026-07-01. Re-run query 9.4 to confirm current state before TECH-3479 deep work begins — user accounts may have changed.

---

### Dashboards (queries 9.5 and 13.7)

**Query:**
```sql
EXEC xp_cmdshell 'echo import sqlite3 > C:\temp\gf.py && echo conn = sqlite3.connect(r"C:\Program Files\GrafanaLabs\grafana\data\grafana.db") >> C:\temp\gf.py && echo rows = conn.execute("SELECT title, created, updated FROM dashboard WHERE is_folder=0 ORDER BY updated DESC").fetchall() >> C:\temp\gf.py && echo print(len(rows), "dashboards total") >> C:\temp\gf.py && echo [print(r) for r in rows] >> C:\temp\gf.py';
EXEC xp_cmdshell 'C:\Users\sqlsrv\AppData\Local\Programs\Python\Python311\python.exe C:\temp\gf.py';
```

**Evidence:**
```
Dashboards: 74 total across 16 folders (confirmed query 13.7 — 2026-07-07)
  KAPP and SingleStore dashboards last updated Oct/Nov 2025 — actively used
  Month End Reporting dashboards exist but data stale since May 2026
```

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
