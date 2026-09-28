-- =============================================================================
-- T07-blocker-evidence.sql
-- TECH-4268 — Blocker Evidence Script
-- Run on EW1R-REP-01 in SSMS to demonstrate why DBA_VCC_MEMSQL_DAILY_CHECKS
-- cannot be re-enabled until the Route53 VPC association is fixed.
--
-- Share the output of this script with whoever needs to understand the blocker
-- and approve the IAM permission request.
--
-- What this script proves:
--   1. EW1R-REP-01 cannot resolve ew1r-aggr-03.rel.kurtosys-internal.net
--   2. The linked server connection to ew1r-aggr-03 fails
--   3. EW1R-REP-01 cannot ping the new IP of ew1r-aggr-03 (10.77.6.161)
--   4. The job is currently disabled and cannot be safely re-enabled
--   5. DBA_VCC_MEMSQL data is over 4 months stale — 2FA alerts affected
--   6. What the fix is and what permission is needed
--
-- Root cause summary:
--   ew1r-aggr-03 was relaunched after 8 May 2026 with a new IP (10.77.6.161).
--   The DNS record exists in rel.kurtosys-internal.net Route53 private hosted
--   zone but EW1R-REP-01 cannot see it because its VPC (vpc-0312c2efa75e26a4d)
--   is not associated with that hosted zone.
--
-- Fix required:
--   Add inline policy to KurtosysEC2InstanceProfileRoleRep (account 649997393595):
--   {
--     "Version": "2012-10-17",
--     "Statement": [{
--       "Effect": "Allow",
--       "Action": "route53:AssociateVPCWithHostedZone",
--       "Resource": "arn:aws:route53:::hostedzone/Z089788836L79G874CNG8"
--     }]
--   }
--   Then run from EW1R-REP-01 PowerShell (Session Manager):
--   aws route53 associate-vpc-with-hosted-zone
--     --hosted-zone-id Z089788836L79G874CNG8
--     --vpc VPCRegion=eu-west-1,VPCId=vpc-0312c2efa75e26a4d
--
-- ⚠️  Step 1 authorization expires 2026-10-05 — must be completed before then.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- TEST 1: Can EW1R-REP-01 resolve ew1r-aggr-03.rel.kurtosys-internal.net?
-- Expected: Non-existent domain — DNS resolution fails
-- This is the root cause. The linked server uses this hostname.
-- If DNS cannot resolve it, the connection never reaches port 3306.
-- -----------------------------------------------------------------------------
PRINT '=== TEST 1: DNS resolution for ew1r-aggr-03.rel.kurtosys-internal.net ===';
PRINT '>>> Expected: Non-existent domain';
EXEC xp_cmdshell 'nslookup ew1r-aggr-03.rel.kurtosys-internal.net';


-- -----------------------------------------------------------------------------
-- TEST 2: Can EW1R-REP-01 reach ew1r-aggr-03 via linked server?
-- Expected: OLE DB error — Cannot initialize data source
-- This is what the job hits at 06:00 every day if re-enabled now.
-- The job will fail immediately at this step and DBA_VCC_MEMSQL will
-- not be updated with fresh data.
-- -----------------------------------------------------------------------------
PRINT '=== TEST 2: Linked server connectivity test — ew1r-aggr-03 ===';
PRINT '>>> Expected: OLE DB provider error — connection refused';
EXEC sp_testlinkedserver N'ew1r-aggr-03';


-- -----------------------------------------------------------------------------
-- TEST 3: Can EW1R-REP-01 ping the new IP of ew1r-aggr-03?
-- New IP confirmed in AWS Console: 10.77.6.161 (instance i-053297eaa46bd4562)
-- Old IP (pre-May 2026): 10.77.0.130
-- Expected: 100% packet loss — no network route from ew1r-shared VPC
-- to ew1r-kapp VPC on this IP
-- -----------------------------------------------------------------------------
PRINT '=== TEST 3: Ping test to ew1r-aggr-03 new IP (10.77.6.161) ===';
PRINT '>>> Expected: 100% packet loss';
EXEC xp_cmdshell 'ping 10.77.6.161 -n 2';


-- -----------------------------------------------------------------------------
-- TEST 4: Confirm the job is currently disabled
-- Expected: DISABLED
-- The job was disabled on 2026-05-08 after failing at 06:00 UTC.
-- It cannot be safely re-enabled until tests 1, 2 and 3 above all pass.
-- Re-enabling it now will result in the job failing again at 06:00
-- with the same linked server error.
-- -----------------------------------------------------------------------------
PRINT '=== TEST 4: DBA_VCC_MEMSQL_DAILY_CHECKS current state ===';
PRINT '>>> Expected: DISABLED';
SELECT
    name,
    CASE enabled WHEN 1 THEN 'ENABLED' ELSE 'DISABLED' END AS state,
    'Cannot re-enable until DNS resolves and linked server test passes' AS reason
FROM msdb.dbo.sysjobs
WHERE name = 'DBA_VCC_MEMSQL_DAILY_CHECKS';


-- -----------------------------------------------------------------------------
-- TEST 5: Show how stale DBA_VCC_MEMSQL data is
-- Expected: last_data = 2026-05-08 for all tables — over 4 months stale
-- This is the data the two Grafana 2FA alert rules are currently
-- evaluating against:
--   - KAPP Client Config Alert
--   - KAPP Client Application Auth Config Alert
-- These alerts are supposed to detect 2FA configuration changes in real time.
-- With stale data they could miss a real 2FA issue completely.
-- -----------------------------------------------------------------------------
PRINT '=== TEST 5: DBA_VCC_MEMSQL data freshness — how stale is it? ===';
PRINT '>>> Expected: last_data = 2026-05-08 — over 4 months stale';
SELECT
    'BAS_Ping_Stat'         AS table_name,
    MAX(DATECHECKED)        AS last_data,
    COUNT(*)                AS row_count
FROM DBA_VCC_MEMSQL.dbo.BAS_Ping_Stat
UNION ALL
SELECT
    'BAS_SQL_Status',
    MAX(DATECHECKED),
    COUNT(*)
FROM DBA_VCC_MEMSQL.dbo.BAS_SQL_Status
UNION ALL
SELECT
    'INFO_Client_FP_Detail',
    MAX(DateChecked),
    COUNT(*)
FROM DBA_VCC_MEMSQL.dbo.INFO_Client_FP_Detail
UNION ALL
SELECT
    'INFO_Client_ApplicationConfiguration_Auth',
    MAX(DateChecked),
    COUNT(*)
FROM DBA_VCC_MEMSQL.dbo.INFO_Client_Application_Auth_Config_Detail;


-- -----------------------------------------------------------------------------
-- TEST 6: What is the fix and what is needed
-- -----------------------------------------------------------------------------
PRINT '=== TEST 6: Fix summary ===';
PRINT '>>> Root cause: vpc-0312c2efa75e26a4d (ew1r-shared) is not associated';
PRINT '>>>             with rel.kurtosys-internal.net hosted zone (Z089788836L79G874CNG8)';
PRINT '>>> ';
PRINT '>>> Step 1: DONE — VPC association authorization created 2026-09-28 from ew1r-aggr-03';
PRINT '>>> ';
PRINT '>>> Step 2: BLOCKED — KurtosysEC2InstanceProfileRoleRep (account 649997393595)';
PRINT '>>>         needs route53:AssociateVPCWithHostedZone permission added';
PRINT '>>> ';
PRINT '>>> Once IAM permission is granted, run from EW1R-REP-01 PowerShell:';
PRINT '>>> aws route53 associate-vpc-with-hosted-zone';
PRINT '>>>   --hosted-zone-id Z089788836L79G874CNG8';
PRINT '>>>   --vpc VPCRegion=eu-west-1,VPCId=vpc-0312c2efa75e26a4d';
PRINT '>>> ';
PRINT '>>> ⚠️  Step 1 authorization expires 2026-10-05 — must be completed before then.';
PRINT '>>> After fix: re-run TEST 1 and TEST 2 — both must pass before re-enabling the job.';
