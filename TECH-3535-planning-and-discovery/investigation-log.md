# TECH-3535 — Planning & Discovery — Investigation Log

Scope: Initial discovery of EW1R-REP-01. Read-only. Feeds all theme tickets.
Each entry has the question, the query, the evidence, and the finding.

---

## 2026-07-03 — Server confirmed: version, edition, service accounts

**Question:** What is running on EW1R-REP-01 and is it healthy?

**Query 1 — Server version and edition:**
```sql
SELECT
    @@SERVERNAME                            AS server_name,
    SERVERPROPERTY('ProductVersion')        AS version,
    SERVERPROPERTY('ProductLevel')          AS patch_level,
    SERVERPROPERTY('Edition')               AS edition,
    SERVERPROPERTY('Collation')             AS collation,
    SERVERPROPERTY('IsClustered')           AS is_clustered,
    SERVERPROPERTY('IsHadrEnabled')         AS is_ag_enabled;
```

**Evidence:**
```
server_name   version       patch_level   edition                    collation             is_clustered  is_ag_enabled
EW1R-REP-01   15.0.4455.2   RTM-CU32-GDR  Developer Edition (64-bit) Latin1_General_CI_AS  0             0
```

**Query 2 — Service accounts:**
```sql
SELECT servicename, service_account, status_desc, startup_type_desc
FROM sys.dm_server_services;
```

**Evidence:**
```
SQL Server (MSSQLSERVER)             SHNONPRD\sqlsrv             Running  Automatic
SQL Server Agent (MSSQLSERVER)       SHNONPRD\sqlagent           Running  Automatic
SQL Server Launchpad (MSSQLSERVER)   NT Service\MSSQLLaunchpad   Running  Automatic
```

**Finding:** SQL Server 2019 Developer Edition, fully patched (KB5068404 Oct 2025). Not clustered, no AG. Developer Edition is not licensed for production use. Three service accounts confirmed — all Running, all Automatic startup. Launchpad runs Python scripts for AWS and Jira API calls — if it stops, those jobs fail silently with no error raised.

---

## 2026-06-29 — Initial discovery: server purpose confirmed

**Question:** What is the purpose of this server and what does it run?

**Finding:** EW1R-REP-01 is a non-production Windows host that runs two things:
- SQL Server 2019 Developer Edition — runs the VCC (Visibility and Cost Control) framework, a custom DBA-built monitoring platform
- Grafana 9.5.2 on port 443 (HTTPS)

It collects data from KAPP, SingleStore, MySQL, AWS, Jira, and Zabbix into the DBA_VCC_* databases. Grafana reads from those databases to serve dashboards. It is not production itself but production depends on it for visibility. This is the only instance of the VCC framework — not replicated anywhere else (unconfirmed, open question 23).
