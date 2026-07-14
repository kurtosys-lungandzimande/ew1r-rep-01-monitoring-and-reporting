/* ============================================================================
   PRODUCTION SCRIPT — TECH-3306
   Remove temporary read-only access for ram.jeyaraman on TROWEPRICE

   Ticket       : TECH-3306
   Original grant: TECH-2245 / KSYS-11462
   Server       : ew2p-mssql-01.gen-prd.kurtosys-internal.net
   Database     : TROWEPRICE
   Access type  : db_datareader (read-only, no write access was ever granted)
   

   ============================================================================
   BEFORE YOU RUN THIS SCRIPT — READ CAREFULLY
   ============================================================================

   PRE-REQUISITES (both must be true before executing):
   1. Ram Jeyaraman has confirmed in TECH-3306 that access is no longer needed.
   2. Dev test has passed — dev_setup_test_kuhle_konke.sql and
      dev_test_revoke_kuhle_konke.sql were run on Utilities and all
      Step 5 verification queries returned 0 rows.

   WHAT THIS SCRIPT DOES:
   Step 1 — Pre-check: confirms the user and role exist (read only, safe to run)
   Step 2 — Removes ram.jeyaraman from db_datareader role on TROWEPRICE
   Step 3 — Drops the ram.jeyaraman database user from TROWEPRICE
   Step 4 — Drops the ram.jeyaraman server login from master
   Step 5 — Post-check: confirms all 3 queries return 0 rows (green light)

   RISK: LOW
   - No data is read, modified, or deleted
   - No schema changes
   - Only a read-only login is being removed
   - All steps have IF EXISTS guards — safe to run even if partially done

   ROLLBACK:
   If you need to restore access after running this script, run the following:

       USE master;
       GO
       CREATE LOGIN [ram.jeyaraman] FROM WINDOWS;

       USE TROWEPRICE;
       GO
       CREATE USER [ram.jeyaraman] FOR LOGIN [ram.jeyaraman];
       ALTER ROLE db_datareader ADD MEMBER [ram.jeyaraman];

   That fully restores the original read-only access.

   HOW TO EXECUTE:
   - Run each step individually, one GO block at a time
   - Review the PRINT output after each step before moving to the next
   - Do NOT run the entire script at once
============================================================================ */


/* ----------------------------------------------------------------------------
   STEP 1 — PRE-REVOKE VERIFICATION (read only — safe to run first)

   Expected output:
   - First query  : 1 row showing ram.jeyaraman, WINDOWS_USER, and create_date
   - Second query : 1 row showing db_datareader | ram.jeyaraman

   If either query returns 0 rows, STOP and raise with the team before
   proceeding — the user may have already been removed or never existed.
---------------------------------------------------------------------------- */
PRINT '--- STEP 1: Pre-revoke verification ---';

USE TROWEPRICE;
GO

SELECT dp.name AS database_user, dp.type_desc, dp.create_date
FROM sys.database_principals dp
WHERE dp.name = 'ram.jeyaraman';

SELECT dp_role.name AS role_name, dp_user.name AS member_name
FROM sys.database_role_members drm
JOIN sys.database_principals dp_role ON drm.role_principal_id = dp_role.principal_id
JOIN sys.database_principals dp_user ON drm.member_principal_id = dp_user.principal_id
WHERE dp_user.name = 'ram.jeyaraman';
GO


/* ----------------------------------------------------------------------------
   STEP 2 — REMOVE FROM db_datareader ROLE

   This revokes read-only query access to TROWEPRICE immediately.
   The IF EXISTS guard means if the role membership is already gone,
   it will print a skipping message and move on safely — no error.

   Expected output: 'Removed ram.jeyaraman from db_datareader.'
---------------------------------------------------------------------------- */
PRINT '--- STEP 2: Removing ram.jeyaraman from db_datareader ---';

USE TROWEPRICE;
GO

IF EXISTS (
    SELECT 1
    FROM sys.database_role_members drm
    JOIN sys.database_principals dp_role ON drm.role_principal_id = dp_role.principal_id
    JOIN sys.database_principals dp_user ON drm.member_principal_id = dp_user.principal_id
    WHERE dp_role.name = 'db_datareader' AND dp_user.name = 'ram.jeyaraman'
)
BEGIN
    ALTER ROLE db_datareader DROP MEMBER [ram.jeyaraman];
    PRINT 'Removed ram.jeyaraman from db_datareader.';
END
ELSE
    PRINT 'ram.jeyaraman was not in db_datareader - skipping.';
GO


/* ----------------------------------------------------------------------------
   STEP 3 — DROP THE DATABASE USER FROM TROWEPRICE

   Removes ram.jeyaraman as a user from the TROWEPRICE database.
   Must be done before dropping the server login in Step 4.
   The IF EXISTS guard makes this safe to re-run if needed.

   Expected output: 'Dropped database user ram.jeyaraman.'
---------------------------------------------------------------------------- */
PRINT '--- STEP 3: Dropping database user ram.jeyaraman from TROWEPRICE ---';

USE TROWEPRICE;
GO

IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'ram.jeyaraman')
BEGIN
    DROP USER [ram.jeyaraman];
    PRINT 'Dropped database user ram.jeyaraman.';
END
ELSE
    PRINT 'Database user ram.jeyaraman not found - skipping.';
GO


/* ----------------------------------------------------------------------------
   STEP 4 — DROP THE SERVER LOGIN FROM MASTER

   Removes the ram.jeyaraman Windows/AD login from the server entirely.
   This is the final removal — after this, the account has no footprint
   on this SQL Server instance at all.
   The IF EXISTS guard makes this safe to re-run if needed.

   Expected output: 'Dropped server login ram.jeyaraman.'
---------------------------------------------------------------------------- */
PRINT '--- STEP 4: Dropping server login ram.jeyaraman from master ---';

USE master;
GO

IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'ram.jeyaraman')
BEGIN
    DROP LOGIN [ram.jeyaraman];
    PRINT 'Dropped server login ram.jeyaraman.';
END
ELSE
    PRINT 'Server login ram.jeyaraman not found - skipping.';
GO


/* ----------------------------------------------------------------------------
   STEP 5 — POST-REVOKE VERIFICATION (read only — confirms clean removal)

   ALL THREE queries must return 0 rows.
   If any query returns a row, the removal was not fully successful —
   review the output and re-run the relevant step above.

   Once confirmed, paste this output as a comment in TECH-3306 as evidence
   that the access has been fully revoked and the DoD is satisfied.
---------------------------------------------------------------------------- */
PRINT '--- STEP 5: Post-revoke verification (all queries must return 0 rows) ---';

USE TROWEPRICE;
GO

-- 1. Confirm database user is gone
SELECT dp.name AS database_user
FROM sys.database_principals dp
WHERE dp.name = 'ram.jeyaraman';

-- 2. Confirm role membership is gone
SELECT dp_role.name AS role_name, dp_user.name AS member_name
FROM sys.database_role_members drm
JOIN sys.database_principals dp_role ON drm.role_principal_id = dp_role.principal_id
JOIN sys.database_principals dp_user ON drm.member_principal_id = dp_user.principal_id
WHERE dp_user.name = 'ram.jeyaraman';

-- 3. Confirm server login is gone
SELECT name AS server_login
FROM master.sys.server_principals
WHERE name = 'ram.jeyaraman';
GO

PRINT '--- DONE: Paste the 0-row output above as evidence in TECH-3306. ---';
