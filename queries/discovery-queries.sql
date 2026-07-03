-- ============================================================
-- EW1R-REP-01 Discovery Queries
-- Used during investigation — read-only, no changes made
-- ============================================================

-- 1. Server info
SELECT 
    @@SERVERNAME AS server_name,
    @@VERSION AS sql_version,
    SERVERPROPERTY('Edition') AS edition,
    SERVERPROPERTY('ProductVersion') AS version,
    SERVERPROPERTY('Collation') AS collation;

-- 2. Database inventory with sizes
SELECT 
    d.name, 
    d.state_desc,
    d.recovery_model_desc,
    CAST(SUM(f.size * 8.0 / 1024) AS DECIMAL(10,2)) AS size_mb
FROM sys.databases d
JOIN sys.master_files f ON d.database_id = f.database_id
GROUP BY d.name, d.state_desc, d.recovery_model_desc
ORDER BY size_mb DESC;

-- 3. Linked servers
SELECT 
    name,
    product,
    provider,
    data_source,
    is_linked
FROM sys.servers
WHERE is_linked = 1;

-- 4. SQL Agent jobs
SELECT 
    j.name AS job_name,
    j.enabled,
    j.description,
    ISNULL(s.name, 'No schedule') AS schedule_name,
    ISNULL(n.email_address, 'No alert') AS alert_target
FROM msdb.dbo.sysjobs j
LEFT JOIN msdb.dbo.sysjobschedules js ON j.job_id = js.job_id
LEFT JOIN msdb.dbo.sysschedules s ON js.schedule_id = s.schedule_id
LEFT JOIN msdb.dbo.sysoperators n ON j.notify_email_operator_id = n.id
ORDER BY j.name;

-- 5. DBA_VCC_AWS table inventory
SELECT 
    t.name AS table_name,
    SUM(p.rows) AS row_count,
    CAST(SUM(a.total_pages * 8.0 / 1024) AS DECIMAL(10,2)) AS size_mb
FROM DBA_VCC_AWS.sys.tables t
JOIN DBA_VCC_AWS.sys.partitions p ON t.object_id = p.object_id
JOIN DBA_VCC_AWS.sys.allocation_units a ON p.partition_id = a.container_id
GROUP BY t.name
ORDER BY size_mb DESC;

-- 6. DBA_VCC table inventory
SELECT 
    t.name AS table_name,
    SUM(p.rows) AS row_count,
    CAST(SUM(a.total_pages * 8.0 / 1024) AS DECIMAL(10,2)) AS size_mb
FROM DBA_VCC.sys.tables t
JOIN DBA_VCC.sys.partitions p ON t.object_id = p.object_id
JOIN DBA_VCC.sys.allocation_units a ON p.partition_id = a.container_id
GROUP BY t.name
ORDER BY size_mb DESC;

-- 7. Active monitored servers
SELECT * FROM DBA_VCC.dbo.LU_Serverlist;

-- 8. Decommissioned servers list
SELECT * FROM DBA_VCC.dbo.LU_DECOM_Serverlist;

-- 9. Check Grafana port (run via xp_cmdshell if enabled)
-- EXEC xp_cmdshell 'netstat -ano | findstr LISTENING | findstr ":3000"';
-- EXEC xp_cmdshell 'sc query grafana';

-- 10. Check all databases for a specific user
EXEC sp_MSforeachdb '
USE [?];
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name LIKE ''%ram%'' OR name LIKE ''%jeyaraman%'')
SELECT ''?'' AS database_name, name, type_desc, create_date 
FROM sys.database_principals 
WHERE name LIKE ''%ram%'' OR name LIKE ''%jeyaraman%''';

-- 11. Job step details (to see what each job actually does)
SELECT 
    j.name AS job_name,
    js.step_id,
    js.step_name,
    js.command,
    js.database_name
FROM msdb.dbo.sysjobs j
JOIN msdb.dbo.sysjobsteps js ON j.job_id = js.job_id
ORDER BY j.name, js.step_id;
