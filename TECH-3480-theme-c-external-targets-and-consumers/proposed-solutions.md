# Proposed Solutions — Theme C: External Targets and Consumers
**Ticket:** TECH-3480 — Theme C: External Targets and Consumer Identification
**Date:** 2026-08-06
**Source:** external-targets-inventory.md + consumer-inventory.md + TECH-3562 discovery

---

## Overview

This document covers what to do with each external target and consumer dependency. The structure mirrors Theme A and Theme B — for each area: what we found, why it matters, and what the proposed action is.

No decommission actions are executed here. This is the validated, actionable inventory the decommission plan depends on.

---

## 1. Dead Linked Servers — 63 of 109 (58%)

**What we found:**
More than half of all linked servers on this server are dead. They point at platforms that have been decommissioned, nodes that are no longer online, or DNS entries that no longer resolve. 30 of the 63 are safe to drop immediately with no further investigation. The remaining 33 need platform team confirmation before dropping.

**Why it matters:**
Dead linked servers are not just clutter — 2 SQL Agent jobs fail every single day because of them. No alert fires. The failures are invisible unless someone manually checks job history. Every dead linked server that stays in place is a future silent failure waiting to happen.

**Proposed actions:**

| Group | Count | Action | Risk |
|---|---|---|---|
| WPv2 (ew2p-wpv2, ew2r-wpv2, ue1p-wpv2, ue1r-wpv2) | 4 | Drop immediately — DNS gone, platform decommissioned, causing 2 daily job failures | Zero — platform confirmed gone |
| gen-rel (ew1r-aggr-03/05.gen-rel, ew1r-leaf-11/12/14.gen-rel) | 5 | Drop immediately — platform confirmed retired | Zero |
| gen-prd (21 nodes) | 21 | Drop immediately — platform confirmed retired | Zero |
| ZabbixNonProd, ZabbixProdOld | 2 | Drop — both confirmed dead (TCP 10060). Confirm with infrastructure team first | Low |
| ew1p-oct (short hostname) | 1 | Drop — orphan, job uses full RDS hostname | Zero |
| ec1p dead nodes (6) | 6 | Confirm with SingleStore / platform team — partial cluster, some nodes still reachable | Medium |
| ew1d-admin-01/02 | 2 | Confirm with DBA team — dev admin nodes, may be permanently retired | Low |
| ew1r dead aggr/leaf (6) | 6 | Confirm with SingleStore / platform team — partial cluster | Medium |
| ew2p dead aggr/leaf (7) | 7 | Confirm with SingleStore / platform team — partial cluster | Medium |
| ue1p dead nodes (6) | 6 | Confirm with SingleStore / platform team — partial cluster | Medium |

**Immediate safe cleanup: 33 linked servers** (WPv2 + gen-rel + gen-prd + ZabbixNonProd + ZabbixProdOld + ew1p-oct short hostname)

---

## 2. WPv2 — Fix the 2 Daily Failing Jobs

**What we found:**
`DBA_VCC_MYSQL_DAILY_CHECKS` and `DBA_VCC_MYSQL_AUDIT_DXM_CLIENT_DETAILED` fail every single day. Both fail on `SP_AUDIT_WPv2_CLIENTS_DETAILED` — a stored procedure last modified 2022-11-01 that calls OPENQUERY against WPv2 linked servers that no longer exist. No alert fires. The failures have been invisible since WPv2 was decommissioned.

**Why it matters:**
Two production jobs failing daily with no notification is a monitoring gap. The DXM steps in both jobs are succeeding — only the WPv2 step fails. The fix is surgical and low risk.

**Proposed actions:**
- Remove Step 2 from `DBA_VCC_MYSQL_AUDIT_DXM_CLIENT_DETAILED` (SP_AUDIT_WPv2_CLIENTS_DETAILED)
- Remove Step 5 from `DBA_VCC_MYSQL_DAILY_CHECKS` (SP_AUDIT_WPv2_CLIENTS_DETAILED)
- Drop or archive `SP_AUDIT_WPv2_CLIENTS_DETAILED` — last modified 2022, references dead servers
- Drop the 4 WPv2 linked servers
- Remove WPv2 entries from LU_Serverlist
- Validate DXM steps continue to run correctly after WPv2 steps are removed

This is a zero-risk cleanup. WPv2 is confirmed decommissioned. Nothing depends on this data.

---

## 3. EW2P-MSSQL-01 and EW2P-MSSQL-02 — Production Monitoring With No Backup Path

**What we found:**
16 VCC Audit Collection jobs and 8 VCC Server Monitoring jobs on this server are the only monitoring for two production SQL Servers — EW2P-MSSQL-01 and EW2P-MSSQL-02. There is no secondary monitoring path. If EW1R-REP-01 goes offline, those two production servers go completely dark.

**Why it matters:**
This is the single biggest decommission blocker for the VCC framework. The monitoring of production servers cannot simply stop — it must be migrated before this server is decommissioned.

**Proposed actions:**
- Confirm whether EW2P-MSSQL-01 and EW2P-MSSQL-02 are RDS or EC2-hosted
- If RDS: replace with AWS CloudWatch native SQL Server monitoring — RDS exposes metrics natively, no custom framework needed
- If EC2-hosted: install CloudWatch Agent on those servers and configure SQL Server metric collection
- The 24 VCC jobs monitoring these servers can be retired once CloudWatch coverage is confirmed
- This migration must be complete before any decommission date is set

---

## 4. DBA_VCC_COST — Client Billing Data, Silent Failure Since May 2026

**What we found:**
DBA_VCC_COST tracks entity counts for 280 real institutional clients — BlackRock, BNY Mellon, Aberdeen, Wellington, T. Rowe Price, Nordea and others. It is the only database on this server using FULL recovery model. The collection job runs every Sunday and reports Succeeded — but all 9 collection tables have been frozen at 4 May 2026 for 11+ consecutive weeks. The job succeeds because the stored procedures exit cleanly with zero rows when DBA_VCC_MEMSQL ping stats are stale. There is no error to catch.

**Why it matters:**
This is billing data for 200+ institutional clients. The KAPP Client Utilisation and Growth Report dashboard reads from it. If that dashboard is client-facing, clients have been seeing stale data since May 2026 without knowing it. This is a disclosure risk independent of the decommission decision.

**Proposed actions:**
- Disclose to stakeholders that DBA_VCC_COST data has been stale since 4 May 2026 — 11+ weeks of silent zero-row runs
- Confirm with tashvir.babulal / rayhaan.suleyman whether KAPP Client Utilisation and Growth Report is shown to clients
- Confirm who calls REP_MONTHEND_* procedures each month end and whether they are aware the data is stale
- Root cause fix: re-enable DBA_VCC_MEMSQL jobs (or confirm SingleStore is decommissioned) — the SP_INFO procedures will resume collecting once BAS_Ping_Stat has fresh data
- Long-term: this data should not live on a Developer Edition non-production server. If it is client billing data, it needs a production-grade home with proper monitoring and alerting

---

## 5. DBA_VCC_MEMSQL — Disabled Since May 2026, 14 Dashboards Stale

**What we found:**
All 7 DBA_VCC_MEMSQL jobs were disabled on 2026-05-08 within 90 seconds of each other — a deliberate action, not a failure. 14 Grafana dashboards have been showing stale data ever since. 6 month-end reporting dashboards have no independent data pipeline — June 2026 month-end reporting was impacted silently.

**Why it matters:**
The downstream casualty is DBA_VCC_COST — the SP_INFO procedures that collect client billing data depend on DBA_VCC_MEMSQL ping stats being fresh. When the MEMSQL jobs were disabled, the entire DBA_VCC_COST collection pipeline silently stopped with them. Both databases stopped collecting on the same day for the same root cause.

**Proposed actions:**
- Confirm with DBA team why jobs were disabled — decommission, migration, or pause
- If SingleStore is decommissioned: retire all 7 jobs, archive DBA_VCC_MEMSQL, update or retire all 14 dependent dashboards
- If SingleStore is still active: update linked server connections and re-enable jobs — but investigate why DBA_VCC_MEMSQL_DAILY_CHECKS failed on its last run before being disabled
- Notify dashboard consumers that data has been stale since May 2026 regardless of outcome
- Do not re-enable jobs without understanding the root cause of the DAILY_CHECKS failure on 8 May 2026

---

## 6. Month-End Procedures — Who Calls Them?

**What we found:**
33 REP_MONTHEND stored procedures exist across DBA_VCC_COST (19) and DBA_VCC_MEMSQL (14). 6 Grafana dashboards call them. No SQL Agent job has been found that calls these procedures on a schedule — they are likely called manually each month end. Who calls them and whether the output is client-facing is still open.

**Why it matters:**
If these procedures are called manually by a person each month end, that person needs to be identified before decommission. If the output is client-facing, the procedures cannot be retired without a replacement. The data they report on has been stale since May 2026 — any month-end report run since then has been using stale data.

**Proposed actions:**
- Confirm with tashvir.babulal / rayhaan.suleyman who calls REP_MONTHEND_* each month end
- Confirm whether the output is sent to clients or used internally only
- Run investigation-log.md Q3(C) queries to check for any automated caller
- If manual: document the process and include it in the decommission handover
- If client-facing: this is a decommission blocker — a replacement pipeline must be confirmed before these procedures can be retired
- Note: 7 procedures in DBA_VCC_MEMSQL use the `CLINT` typo (vs `CLIENT`) — both old and new versions exist. The old typo versions should be cleaned up regardless of the decommission outcome

---

## 7. Slack Alerts — Zabbix Is the Only Path

**What we found:**
EW1R-REP-01 does not post directly to Slack. All SlackChatPostMessage calls in stored procedures are commented out. Slack notifications flow exclusively through Zabbix via ZabbixProdNew. Two active channels: `alerts-data-operations` (KAPP config/read failures) and `alert-app-allow2fa-disabled` (client auth alerts). Who receives these channels is still open.

**Why it matters:**
If this server is decommissioned, Zabbix loses its linked server connection to EW1R-REP-01. The deadlock detection and MemSQL sync check data that Zabbix reads from this server stops. The Slack alerts that depend on that data stop with it. This needs to be confirmed before decommission.

**Proposed actions:**
- Confirm with DBA / ops team who receives alerts-data-operations and alert-app-allow2fa-disabled
- Run investigation-log.md Q4(C) queries to confirm Zabbix webhook config
- Confirm with Zabbix / monitoring team what triggers on EW1R-REP-01 would be lost on decommission
- SPSlackCheckSyncStatus is currently dormant (MemSQL jobs disabled) — confirm whether it should be disabled or dropped
- 4 stored procedures reference dead linked servers (P23-P-AGGR-201, p23-p-aggr-301) — drop these regardless of decommission outcome

---

## 8. S3 Backup Targets — Encryption Gaps

**What we found:**
Two S3 buckets receive backups from this server. Neither has encryption confirmed:
- `ksys-ew1r-db-backups` — local SQL Server backups via AWS CLI s3 sync with no `--sse` flag
- `ksys-ew1p-oct-dbbackup` — EW1P-OCT RDS backup with KMS key NULL — unencrypted at rest

**Why it matters:**
DBA_VCC_COST contains client billing data for 280 institutional clients. If that database is included in the unencrypted backups, this is a compliance risk independent of the decommission decision.

**Proposed actions:**
- Add `--sse AES256` (or `--sse aws:kms`) to the AWS CLI s3 sync command in USP_DatabaseBackupMoveToS3
- Fix the KMS key NULL on the EW1P-OCT RDS backup job
- Confirm S3 lifecycle rules on both buckets — retention policy is still TBC
- Confirm with DevOps whether these encryption gaps are a known accepted risk or an oversight
- On decommission: confirm backup retention requirements before deleting buckets or stopping backup jobs

---

## 9. IAM Role / Key for Python AWS API Caller

**What we found:**
Three SQL Agent jobs call Python scripts that make AWS API calls (CloudWatch, S3, Cost Explorer): DBA_VCC_AWS_15MIN_CHECKS, DBA_VCC_AWS_DAILY_CHECKS, DBA_VCC_AWS_WEEKLY_CHECKS. The IAM identity used by these scripts has not been confirmed — it could be an instance role or an access key stored on disk.

**Why it matters:**
If it is an access key stored on disk, it needs to be rotated and ideally migrated to an instance role. On decommission, the key or role must be revoked — leaving an active IAM key attached to a decommissioned server is a security risk.

**Proposed actions:**
- Run investigation-log.md Q5(C) queries to identify the credential type
- If instance role: document the role ARN and confirm it is scoped to minimum required permissions
- If access key: rotate immediately and migrate to instance role
- On decommission: revoke the IAM role or deactivate the access key as part of the decommission checklist

---

## 10. ZabbixProdOld — Confirmed Dead, Safe to Drop

**What we found:**
ZabbixProdOld linked server points to 10.120.8.120:3306 — TCP connection refused, confirmed unreachable. The old prod Zabbix instance at that IP has been decommissioned. The linked server is an orphan.

**Proposed actions:**
- Confirm with infrastructure team that 10.120.8.120 is decommissioned
- Drop ZabbixProdOld linked server
- Drop ZabbixNonProd linked server (same situation — 10.72.8.191:3306 unreachable)
- No job or stored procedure references either — confirmed from investigation queries

---

## Summary — Retire / Replace / Keep

| Target / Consumer | Classification | Reason |
|---|---|---|
| 4 WPv2 linked servers | Retire immediately | DNS gone, platform decommissioned, causing 2 daily job failures |
| 26 gen-rel + gen-prd linked servers | Retire immediately | Platform confirmed retired |
| ZabbixNonProd + ZabbixProdOld linked servers | Retire | Both confirmed dead — pending infrastructure sign-off |
| ew1p-oct short hostname | Retire | Orphan — job uses full RDS hostname |
| 33 partial-cluster dead nodes (ec1p/ew1r/ew2p/ue1p) | Confirm then retire | Need platform team confirmation before dropping |
| SP_AUDIT_WPv2_CLIENTS_DETAILED | Retire | Last modified 2022, references dead servers, causing daily job failures |
| EW2P-MSSQL-01/02 monitoring (24 jobs) | Replace | Replace with CloudWatch native monitoring before decommission |
| DBA_VCC_COST collection pipeline | Fix then decide | Re-enable MEMSQL jobs to restore collection, then assess decommission path |
| DBA_VCC_MEMSQL (7 jobs, 14 dashboards) | Confirm then retire | Confirm why disabled — if SingleStore decommissioned, retire all |
| 33 REP_MONTHEND procedures | Confirm then decide | Who calls them and whether client-facing must be confirmed first |
| Slack alerts (via Zabbix) | Keep — confirm consumers | Alerts active, consumers unconfirmed — must be confirmed before decommission |
| S3 backup encryption | Fix now | Encryption gaps are a compliance risk independent of decommission |
| IAM role/key for Python caller | Confirm then revoke on decommission | Identify credential type, rotate if key, revoke on decommission |
| ZabbixProdOld | Retire | Confirmed dead |
| pmmdev / pmmprod (Clickhouse) | Confirm | Both reachable — purpose and owner not yet confirmed |

---

## Decommission Blockers — Cannot Set a Date Until These Are Answered

| # | Blocker | Who to Ask |
|---|---|---|
| B1 | Who calls REP_MONTHEND_* each month end — manual or automated? Is output client-facing? | tashvir.babulal / rayhaan.suleyman |
| B2 | Is KAPP Client Utilisation and Growth Report shown to clients? | tashvir.babulal / rayhaan.suleyman |
| B3 | Why were DBA_VCC_MEMSQL jobs disabled in May 2026 — is SingleStore decommissioned? | DBA team / yogeshwar.phull |
| B4 | What is the migration plan for EW2P-MSSQL-01/02 monitoring post-decommission? | DBA team |
| B5 | Is the VCC framework replicated anywhere else or is this the only instance? | DBA team |
| B6 | Who receives alerts-data-operations and alert-app-allow2fa-disabled — would they lose visibility? | DBA team / ops team |
