-- =============================================================================
-- 01-final-backups.sql
-- EW1R-REP-01 — Final FULL backups before taking databases offline
-- Ticket: TECH-4268
-- Run AFTER 00-pre-change-state-capture.sql and BEFORE any disable/offline steps.
-- Confirm each backup lands in ksys-ew1r-db-backups before proceeding.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Databases being taken OFFLINE — must be backed up first:
--   DBA_VCC_AWS, DBA_VCC_MYSQL, DBA_VCC, DBA_VCC_COST,
--   DBA_VCC_ATLASSIAN, KURTOSYS_BASELINE, Utilities
--
-- Staying ONLINE — back up for safety:
--   DBA_VCC_MEMSQL (stays live, 2FA job will write to it)
--
-- DBA_VCC_COST is FULL recovery and holds client billing data.
-- Retain its backup per policy — do not delete from S3.
-- -----------------------------------------------------------------------------

-- NOTE: These use Ola Hallengren DatabaseBackup stored in Utilities.
-- If Utilities is being taken offline, run these backups BEFORE that step.
-- The S3 sync (USP_DatabaseBackupMoveToS3) runs inside DatabaseBackup via
-- the AfterBackup parameter — confirm S3 sync completes for each database.

-- -----------------------------------------------------------------------------
-- Step 1: Back up DBA_VCC_MEMSQL (stays online — back up for safety)
-- -----------------------------------------------------------------------------
EXECUTE Utilities.dbo.DatabaseBackup
    @Databases      = 'DBA_VCC_MEMSQL',
    @BackupType     = 'FULL',
    @Directory      = 'D:\SQL\Backup',
    @CleanupTime    = NULL,
    @Compress       = 'Y',
    @Verify         = 'Y',
    @LogToTable     = 'Y';

-- -----------------------------------------------------------------------------
-- Step 2: Back up DBA_VCC_COST (FULL recovery — client billing data)
-- -----------------------------------------------------------------------------
EXECUTE Utilities.dbo.DatabaseBackup
    @Databases      = 'DBA_VCC_COST',
    @BackupType     = 'FULL',
    @Directory      = 'D:\SQL\Backup',
    @CleanupTime    = NULL,
    @Compress       = 'Y',
    @Verify         = 'Y',
    @LogToTable     = 'Y';

-- -----------------------------------------------------------------------------
-- Step 3: Back up DBA_VCC_AWS
-- -----------------------------------------------------------------------------
EXECUTE Utilities.dbo.DatabaseBackup
    @Databases      = 'DBA_VCC_AWS',
    @BackupType     = 'FULL',
    @Directory      = 'D:\SQL\Backup',
    @CleanupTime    = NULL,
    @Compress       = 'Y',
    @Verify         = 'Y',
    @LogToTable     = 'Y';

-- -----------------------------------------------------------------------------
-- Step 4: Back up DBA_VCC_MYSQL
-- -----------------------------------------------------------------------------
EXECUTE Utilities.dbo.DatabaseBackup
    @Databases      = 'DBA_VCC_MYSQL',
    @BackupType     = 'FULL',
    @Directory      = 'D:\SQL\Backup',
    @CleanupTime    = NULL,
    @Compress       = 'Y',
    @Verify         = 'Y',
    @LogToTable     = 'Y';

-- -----------------------------------------------------------------------------
-- Step 5: Back up DBA_VCC
-- -----------------------------------------------------------------------------
EXECUTE Utilities.dbo.DatabaseBackup
    @Databases      = 'DBA_VCC',
    @BackupType     = 'FULL',
    @Directory      = 'D:\SQL\Backup',
    @CleanupTime    = NULL,
    @Compress       = 'Y',
    @Verify         = 'Y',
    @LogToTable     = 'Y';

-- -----------------------------------------------------------------------------
-- Step 6: Back up DBA_VCC_ATLASSIAN
-- -----------------------------------------------------------------------------
EXECUTE Utilities.dbo.DatabaseBackup
    @Databases      = 'DBA_VCC_ATLASSIAN',
    @BackupType     = 'FULL',
    @Directory      = 'D:\SQL\Backup',
    @CleanupTime    = NULL,
    @Compress       = 'Y',
    @Verify         = 'Y',
    @LogToTable     = 'Y';

-- -----------------------------------------------------------------------------
-- Step 7: Back up KURTOSYS_BASELINE
-- -----------------------------------------------------------------------------
EXECUTE Utilities.dbo.DatabaseBackup
    @Databases      = 'KURTOSYS_BASELINE',
    @BackupType     = 'FULL',
    @Directory      = 'D:\SQL\Backup',
    @CleanupTime    = NULL,
    @Compress       = 'Y',
    @Verify         = 'Y',
    @LogToTable     = 'Y';

-- -----------------------------------------------------------------------------
-- Step 8: Back up Utilities (last — it hosts the backup proc itself)
-- -----------------------------------------------------------------------------
EXECUTE Utilities.dbo.DatabaseBackup
    @Databases      = 'Utilities',
    @BackupType     = 'FULL',
    @Directory      = 'D:\SQL\Backup',
    @CleanupTime    = NULL,
    @Compress       = 'Y',
    @Verify         = 'Y',
    @LogToTable     = 'Y';

-- -----------------------------------------------------------------------------
-- Step 9: Confirm all backups completed and are in S3
-- Run this after all DatabaseBackup calls complete.
-- Expect one row per database with backup_finish_date within the last hour.
-- -----------------------------------------------------------------------------
SELECT
    database_name,
    backup_start_date,
    backup_finish_date,
    CAST(backup_size / 1048576.0 AS decimal(10,2))  AS backup_size_mb,
    type                                             AS backup_type,
    physical_device_name
FROM msdb.dbo.backupset bs
JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
WHERE bs.database_name IN (
    'DBA_VCC_MEMSQL','DBA_VCC_COST','DBA_VCC_AWS',
    'DBA_VCC_MYSQL','DBA_VCC','DBA_VCC_ATLASSIAN',
    'KURTOSYS_BASELINE','Utilities'
)
AND bs.type = 'D'
AND bs.backup_finish_date >= DATEADD(HOUR, -2, GETDATE())
ORDER BY bs.database_name, bs.backup_finish_date DESC;

-- -----------------------------------------------------------------------------
-- Step 10: Sync backups to S3
-- Run after confirming all local backups completed above.
-- USP_DatabaseBackupMoveToS3 uses AWS CLI s3 sync via xp_cmdshell.
-- NOTE: No --sse flag — known compliance gap, accepted for this ticket.
-- -----------------------------------------------------------------------------
EXECUTE Utilities.dbo.USP_DatabaseBackupMoveToS3;
