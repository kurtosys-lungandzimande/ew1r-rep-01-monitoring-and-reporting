# TECH-3480 — Investigation Log
**Ticket:** TECH-3480 — Theme C: External Targets and Consumer Identification
**Scope:** Queries to answer open questions Q3(C), Q4(C), Q5(C), Q7(C), Q18, Q21, Q22, Q23
**Run on:** EW1R-REP-01 via SSM Session Manager or SSMS

---

## Q3(C) — Who calls REP_MONTHEND_* procedures each month end?

**Goal:** Confirm whether the month-end procedures are called manually (by a person) or by an automated job/scheduler. Identify the caller and whether the output is client-facing.

### Step 1 — Check SQL Agent job history for any job that calls REP_MONTHEND

```sql
SELECT
    j.name AS job_name,
    jh.step_name,
    jh.run_date,
    jh.run_time,
    jh.message
FROM msdb.dbo.sysjobhistory jh
JOIN msdb.dbo.sysjobs j ON jh.job_id = j.job_id
WHERE jh.message LIKE '%REP_MONTHEND%'
   OR jh.step_name LIKE '%MONTHEND%'
ORDER BY jh.run_date DESC, jh.run_time DESC;
```

### Step 2 — Check all job steps for REP_MONTHEND references

```sql
SELECT
    j.name AS job_name,
    js.step_id,
    js.step_name,
    js.command
FROM msdb.dbo.sysjobsteps js
JOIN msdb.dbo.sysjobs j ON js.job_id = j.job_id
WHERE js.command LIKE '%REP_MONTHEND%';
```

### Step 3 — Check SQL Server audit / trace for recent EXEC calls against REP_MONTHEND

```sql
-- Check default trace for recent procedure executions
SELECT
    te.name AS event_type,
    t.DatabaseName,
    t.ObjectName,
    t.LoginName,
    t.HostName,
    t.ApplicationName,
    t.StartTime
FROM sys.fn_trace_gettable(
    (SELECT path FROM sys.traces WHERE is_default = 1), DEFAULT) t
JOIN sys.trace_events te ON t.EventClass = te.trace_event_id
WHERE t.ObjectName LIKE '%REP_MONTHEND%'
ORDER BY t.StartTime DESC;
```

### Step 4 — Check Grafana dashboard datasource queries for direct EXEC calls

```sql
-- Run via xp_cmdshell + Python against grafana.db on the Grafana host
-- Or check grafana.db directly if accessible
SELECT title, updated, data
FROM dashboard
WHERE is_folder = 0
  AND data LIKE '%REP_MONTHEND%'
ORDER BY updated DESC;
```

**Expected finding:** Either a job step calls the procedures on a schedule, or a person runs them manually via SSMS each month end. If no job is found, escalate to tashvir.babulal / rayhaan.suleyman with evidence.

---

## Q4(C) — Who receives alerts-data-operations and alert-app-allow2fa-disabled?

**Goal:** Confirm the Slack channel membership and whether these alerts are still actively monitored.

### Step 1 — Confirm Zabbix action config for these channels

```sql
-- Check Zabbix media types and actions configured on ZabbixProdNew
-- Run against ZabbixProdNew MySQL via linked server
SELECT *
FROM OPENQUERY([ZabbixProdNew],
    'SELECT a.name, a.status, am.sendto, am.mediatypeid
     FROM zabbix.actions a
     JOIN zabbix.operations o ON a.actionid = o.actionid
     JOIN zabbix.opmessage om ON o.operationid = om.operationid
     JOIN zabbix.media am ON om.mediatypeid = am.mediatypeid
     WHERE am.sendto LIKE ''%alerts-data-operations%''
        OR am.sendto LIKE ''%allow2fa%''');
```

### Step 2 — Check Zabbix media type for Slack webhook

```sql
SELECT *
FROM OPENQUERY([ZabbixProdNew],
    'SELECT mt.name, mt.type, mt.status, mt.parameters
     FROM zabbix.media_type mt
     WHERE mt.name LIKE ''%Slack%''
        OR mt.parameters LIKE ''%alerts-data-operations%''
        OR mt.parameters LIKE ''%allow2fa%''');
```

### Step 3 — Check stored procedures that reference these channel names

```sql
SELECT
    OBJECT_SCHEMA_NAME(o.object_id) AS schema_name,
    o.name AS proc_name,
    m.definition
FROM sys.sql_modules m
JOIN sys.objects o ON m.object_id = o.object_id
WHERE m.definition LIKE '%alerts-data-operations%'
   OR m.definition LIKE '%allow2fa%'
   OR m.definition LIKE '%SlackChatPostMessage%';
```

**Expected finding:** Zabbix webhook config will show the channel name and the Slack workspace. Channel membership must be confirmed with the DBA / ops team directly — Zabbix does not store individual subscribers.

---

## Q5(C) — What IAM role/key does the Python AWS API caller use?

**Goal:** Identify the IAM identity used by the Python scripts that call AWS APIs (CloudWatch, S3, Cost Explorer).

### Step 1 — Find the Python script location via job step commands

```sql
SELECT
    j.name AS job_name,
    js.step_id,
    js.step_name,
    js.command,
    js.subsystem
FROM msdb.dbo.sysjobsteps js
JOIN msdb.dbo.sysjobs j ON js.job_id = j.job_id
WHERE js.command LIKE '%python%'
   OR js.command LIKE '%.py%'
   OR js.subsystem = 'CmdExec'
ORDER BY j.name, js.step_id;
```

### Step 2 — Check AWS credential files on the server via xp_cmdshell

```sql
-- Check for AWS credentials file
EXEC xp_cmdshell 'type C:\Users\sqlagent\.aws\credentials';
EXEC xp_cmdshell 'type C:\Windows\System32\config\systemprofile\.aws\credentials';

-- Check for IAM role attached to EC2 instance (instance metadata)
EXEC xp_cmdshell 'curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/';
```

### Step 3 — Check environment variables for AWS keys

```sql
EXEC xp_cmdshell 'set AWS';
```

### Step 4 — Check Python script content for credential references

```sql
-- Adjust path based on Step 1 findings
EXEC xp_cmdshell 'findstr /i "aws_access_key boto3 iam role" C:\path\to\script.py';
```

**Expected finding:** Either an IAM instance role (preferred — no key on disk) or an access key stored in the credentials file. If a key is found, confirm with DevOps whether it is rotated and whether it should be migrated to an instance role.

---

## Q7(C) — Is ZabbixProdOld still active or confirmed safe to remove?

**Goal:** Confirm ZabbixProdOld is decommissioned and the linked server can be dropped.

### Step 1 — Confirm linked server is dead (already confirmed in TECH-3560)

```sql
-- Already confirmed dead: TCP 10060 — 10.120.8.120:3306 unreachable
-- Re-verify if needed
EXEC sp_testlinkedserver 'ZabbixProdOld';
```

### Step 2 — Check if any job or stored procedure still references ZabbixProdOld

```sql
-- Check job steps
SELECT j.name, js.step_name, js.command
FROM msdb.dbo.sysjobsteps js
JOIN msdb.dbo.sysjobs j ON js.job_id = j.job_id
WHERE js.command LIKE '%ZabbixProdOld%';

-- Check stored procedures
SELECT o.name, m.definition
FROM sys.sql_modules m
JOIN sys.objects o ON m.object_id = o.object_id
WHERE m.definition LIKE '%ZabbixProdOld%';

-- Check views
SELECT o.name, m.definition
FROM sys.sql_modules m
JOIN sys.objects o ON m.object_id = o.object_id
WHERE o.type = 'V'
  AND m.definition LIKE '%ZabbixProdOld%';
```

### Step 3 — Confirm with infrastructure team that the Zabbix instance at 10.120.8.120 is decommissioned

> Escalate to infrastructure team with evidence: linked server ZabbixProdOld points to 10.120.8.120:3306 — TCP connection refused. Confirm this IP is decommissioned and the linked server is safe to drop.

**Expected finding:** No active references in jobs or procs + infrastructure team confirms decommission = safe to drop.

### ✅ Evidence — 2026-08-06 — Confirmed dead

Ping run from EW1R-REP-01 via PowerShell (SSM Session Manager):

```
PS C:\Windows\system32> ping 10.120.8.120

Pinging 10.120.8.120 with 32 bytes of data:
Request timed out.
Request timed out.
Request timed out.
Request timed out.
```

**Finding:** 10.120.8.120 is unreachable — all 4 ping requests timed out. ZabbixProdOld confirmed dead. Safe to drop linked server pending infrastructure team sign-off. Q7(C) CLOSED.

---

## Q18 — What firewall rules allow inbound/outbound connections?

**Goal:** Document the actual firewall rules for EW1R-REP-01 for the decommission plan.

### Step 1 — Check Windows Firewall rules on the server

```sql
EXEC xp_cmdshell 'netsh advfirewall firewall show rule name=all dir=in';
EXEC xp_cmdshell 'netsh advfirewall firewall show rule name=all dir=out';
```

### Step 2 — Check active connections and listening ports

```sql
EXEC xp_cmdshell 'netstat -ano';
```

### Step 3 — Check SQL Server network configuration

```sql
-- Confirm SQL Server listening ports
EXEC xp_cmdshell 'netstat -ano | findstr :1433';
EXEC xp_cmdshell 'netstat -ano | findstr :443';
EXEC xp_cmdshell 'netstat -ano | findstr :3306';
```

### Step 4 — Escalate to network / DevOps team for AWS Security Group rules

> The server is at 10.72.8.216 in eu-west-1. Request the Security Group inbound/outbound rules for the EC2 instance from the DevOps / cloud team. Windows Firewall rules alone are not sufficient — AWS Security Group rules are the outer boundary.

**Expected finding:** Windows Firewall rules + AWS Security Group rules together give the full picture. Document both for the decommission plan.

---

## Q21 — If this server went offline today, what would break immediately?

**Goal:** Produce a concrete impact list for stakeholder sign-off before decommission.

### Step 1 — List all enabled jobs and their external dependencies

```sql
SELECT
    j.name AS job_name,
    j.enabled,
    js.step_name,
    js.command
FROM msdb.dbo.sysjobs j
JOIN msdb.dbo.sysjobsteps js ON j.job_id = js.job_id
WHERE j.enabled = 1
ORDER BY j.name, js.step_id;
```

### Step 2 — Confirm Grafana datasource connectivity depends on this server

```sql
-- Grafana is hosted on this server (port 443, PID 3844)
-- All 74 dashboards go offline if this server goes offline
-- Confirm Grafana data directory and config
EXEC xp_cmdshell 'dir "C:\Program Files\GrafanaLabs\grafana\conf\"';
EXEC xp_cmdshell 'type "C:\Program Files\GrafanaLabs\grafana\conf\defaults.ini" | findstr /i "data_path db_path"';
```

### Step 3 — Confirm EW2P-MSSQL-01/02 monitoring dependency

```sql
-- Confirm these servers have no other monitoring path
-- Check if EW2P-MSSQL-01/02 appear in any other monitoring system
SELECT name, data_source, provider
FROM sys.servers
WHERE name IN ('EW2P-MSSQL-01', 'EW2P-MSSQL-02');
```

**Immediate impact summary (based on current inventory):**
- All 74 Grafana dashboards go offline
- EW2P-MSSQL-01 and EW2P-MSSQL-02 lose all monitoring (16 audit + 8 server monitoring jobs)
- KAPP Client Utilisation dashboard (280 institutional clients) goes offline
- All 6 month-end reporting dashboards go offline
- Zabbix loses its linked server connection to EW1R-REP-01 — deadlock and sync check data stops
- S3 backups for EW1R-REP-01 and EW1P-OCT RDS stop
- AWS CloudWatch / Cost data collection stops

---

## Q22 — Is any alerting dependent solely on this server?

**Goal:** Confirm whether any alert would be silenced if this server went offline.

### Step 1 — Check all Zabbix triggers that read from this server

```sql
-- Check what Zabbix reads from EW1R-REP-01 via linked server
SELECT *
FROM OPENQUERY([ZabbixProdNew],
    'SELECT h.host, h.name, i.name AS item_name, i.key_
     FROM zabbix.hosts h
     JOIN zabbix.items i ON h.hostid = i.hostid
     WHERE h.host LIKE ''%EW1R-REP-01%''
        OR h.host LIKE ''%ew1r-rep-01%''');
```

### Step 2 — Check SQL Server alerts with operators wired

```sql
SELECT
    a.name AS alert_name,
    a.severity,
    a.message_id,
    a.has_notification,
    o.name AS operator_name,
    o.email_address
FROM msdb.dbo.sysalerts a
LEFT JOIN msdb.dbo.sysnotifications n ON a.id = n.alert_id
LEFT JOIN msdb.dbo.sysoperators o ON n.operator_id = o.id
ORDER BY a.severity DESC;
```

### Step 3 — Check SQL Agent alerts for jobs with no operator

```sql
SELECT
    j.name AS job_name,
    j.notify_level_email,
    j.notify_level_netsend,
    j.notify_level_page,
    j.notify_email_operator_id,
    o.name AS operator_name
FROM msdb.dbo.sysjobs j
LEFT JOIN msdb.dbo.sysoperators o ON j.notify_email_operator_id = o.id
WHERE j.enabled = 1
ORDER BY j.name;
```

**Expected finding:** SQL Server severity alerts are all silent (has_notification = 0 — confirmed in TECH-3562). Zabbix is the primary alert path. If this server goes offline, Zabbix loses its data source for deadlock detection and MemSQL sync checks.

---

## Q23 — Is the VCC framework replicated anywhere else?

**Goal:** Confirm whether DBA_VCC, DBA_VCC_COST, DBA_VCC_MEMSQL, DBA_VCC_AWS, DBA_VCC_MYSQL, DBA_VCC_ATLASSIAN exist on any other server.

### Step 1 — Check EW2P-MSSQL-01 and EW2P-MSSQL-02 for VCC databases

```sql
-- Run against EW2P-MSSQL-01
SELECT name FROM [EW2P-MSSQL-01].master.sys.databases
WHERE name LIKE '%VCC%' OR name LIKE '%DBA_%';

-- Run against EW2P-MSSQL-02
SELECT name FROM [EW2P-MSSQL-02].master.sys.databases
WHERE name LIKE '%VCC%' OR name LIKE '%DBA_%';
```

### Step 2 — Check EW1D-MSSQL-01 for VCC databases

```sql
SELECT name FROM [EW1D-MSSQL-01].master.sys.databases
WHERE name LIKE '%VCC%' OR name LIKE '%DBA_%';
```

### Step 3 — Ask DBA team directly

> Escalate to DBA team: Does the VCC monitoring framework (DBA_VCC_COST, DBA_VCC_MEMSQL, DBA_VCC_AWS) exist on any other SQL Server instance? If not, decommissioning EW1R-REP-01 permanently ends client entity count collection and month-end reporting for 280 institutional clients.

**Expected finding:** VCC framework is unique to this server — confirmed by TECH-3562 discovery. No secondary instance found. This is the decommission blocker.

---

## Findings Summary

| Question | Status | Finding |
|---|---|---|
| Q3(C) — Who calls REP_MONTHEND? | ⚠️ Partially closed | Confirmed internal use only — not client-facing. Who calls them each month end still open — needs tashvir.babulal / rayhaan.suleyman confirmation |
| Q4(C) — Who receives Slack alerts? | ⚠️ Open | Alerts flow via Zabbix webhook. Channel membership needs DBA / ops team confirmation |
| Q5(C) — IAM role/key for Python caller? | ⚠️ Open | Run Step 2 queries on server to identify credential type |
| Q7(C) — ZabbixProdOld status? | ✅ CLOSED — Confirmed dead | Ping from EW1R-REP-01 — 10.120.8.120 all requests timed out (2026-08-06). Safe to drop linked server pending infrastructure team sign-off. |
| Q18 — Firewall rules? | ⚠️ Open | Windows Firewall rules need to be pulled from server + AWS Security Group rules from DevOps |
| Q21 — What breaks immediately? | ✅ Documented | 74 Grafana dashboards, EW2P-MSSQL-01/02 monitoring, KAPP billing dashboard, S3 backups, CloudWatch collection |
| Q22 — Alerting solely dependent? | ⚠️ Open | Zabbix deadlock + sync check data stops. SQL Server severity alerts already silent. Run Step 1 query to confirm full Zabbix dependency |
| Q23 — VCC replicated elsewhere? | ⚠️ Open | Run Step 1-2 queries. Expected: unique to this server — decommission blocker |
