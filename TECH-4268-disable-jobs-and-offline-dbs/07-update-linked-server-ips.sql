-- =============================================================================
-- 07-update-linked-server-ips.sql
-- Server:  EW1R-REP-01 (10.72.8.216)
-- Ticket:  TECH-4268
-- Purpose: Update linked server data sources from old IPs to new IPs.
--          Workaround for DNS resolution failure while Route53 VPC
--          association is blocked on IAM permission.
--
-- Context:
--   ew1r-aggr-03 relaunched — new IP 10.77.6.161 (was 10.77.0.130)
--   ew1r-aggr-04 relaunched — new IP 10.77.2.255 (was 10.77.1.253)
--   EW1R-REP-01 VPC (vpc-0312c2efa75e26a4d) not associated with
--   rel.kurtosys-internal.net hosted zone — DNS resolution fails.
--
-- Rollback: see ROLLBACK E in 06-rollback.sql
-- Long-term fix: Route53 VPC association — see investigation-log.md
-- =============================================================================

-- =============================================================================
-- STEP 1 — Verify current state before changes
-- =============================================================================

SELECT name, data_source, product, provider
FROM sys.servers
WHERE name IN ('ew1r-aggr-03', 'ew1r-aggr-04')
ORDER BY name;

-- Expected before:
--   ew1r-aggr-03  |  ew1r-aggr-03  |  MSDASQL
--   ew1r-aggr-04  |  ew1r-aggr-04  |  MSDASQL

-- =============================================================================
-- STEP 2 — Update ew1r-aggr-03 to new IP
-- =============================================================================

EXEC sp_dropserver
    @server      = N'ew1r-aggr-03',
    @droplogins  = 'droplogins';

EXEC sp_addlinkedserver
    @server      = N'ew1r-aggr-03',
    @srvproduct  = N'MySQL',
    @provider    = N'MSDASQL',
    @datasrc     = N'10.77.6.161';

-- =============================================================================
-- STEP 3 — Update ew1r-aggr-04 to new IP
-- =============================================================================

EXEC sp_dropserver
    @server      = N'ew1r-aggr-04',
    @droplogins  = 'droplogins';

EXEC sp_addlinkedserver
    @server      = N'ew1r-aggr-04',
    @srvproduct  = N'MySQL',
    @provider    = N'MSDASQL',
    @datasrc     = N'10.77.2.255';

-- =============================================================================
-- STEP 4 — Verify updated data sources
-- =============================================================================

SELECT name, data_source, product, provider
FROM sys.servers
WHERE name IN ('ew1r-aggr-03', 'ew1r-aggr-04')
ORDER BY name;

-- Expected after:
--   ew1r-aggr-03  |  10.77.6.161  |  MSDASQL
--   ew1r-aggr-04  |  10.77.2.255  |  MSDASQL

-- =============================================================================
-- STEP 5 — Test connectivity
-- =============================================================================

EXEC sp_testlinkedserver N'ew1r-aggr-03';
-- Expected: Command(s) completed successfully.

EXEC sp_testlinkedserver N'ew1r-aggr-04';
-- Expected: Command(s) completed successfully.
