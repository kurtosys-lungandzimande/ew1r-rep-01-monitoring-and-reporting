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
- KAPP Client Utilisation and Growth Report confirmed internal use only — not client-facing. No disclosure risk to clients.
- REP_MONTHEND_* procedures confirmed called by Grafana dashboards only. Internal use only.
- Root cause fix: SingleStore is being decommissioned — DBA_VCC_MEMSQL jobs will not be re-enabled. DBA_VCC_COST collection pipeline depends on MEMSQL ping stats and will remain stale until a replacement data source is confirmed
- Long-term: this data should not live on a Developer Edition non-production server. It needs a production-grade home with proper monitoring and alerting as part of the decommission migration plan

---

## 5. DBA_VCC_MEMSQL — Disabled Since May 2026, 14 Dashboards Stale

**What we found:**
All 7 DBA_VCC_MEMSQL jobs were disabled on 2026-05-08 within 90 seconds of each other — a deliberate action, not a failure. 14 Grafana dashboards have been showing stale data ever since. 6 month-end reporting dashboards have no independent data pipeline — June 2026 month-end reporting was impacted silently.

**Why it matters:**
The downstream casualty is DBA_VCC_COST — the SP_INFO procedures that collect client billing data depend on DBA_VCC_MEMSQL ping stats being fresh. When the MEMSQL jobs were disabled, the entire DBA_VCC_COST collection pipeline silently stopped with them. Both databases stopped collecting on the same day for the same root cause.

**Proposed actions:**
- SingleStore is being decommissioned — confirmed B3 closed. All 7 DBA_VCC_MEMSQL jobs are retire candidates
- Retire all 7 DBA_VCC_MEMSQL jobs, archive DBA_VCC_MEMSQL database, update or retire all 14 dependent dashboards
- Notify dashboard consumers that data has been stale since May 2026
- Do not re-enable jobs — SingleStore decommission is confirmed

---

## 6. Month-End Procedures — Who Calls Them?

**What we found:**
33 REP_MONTHEND stored procedures exist across DBA_VCC_COST (19) and DBA_VCC_MEMSQL (14). 6 Grafana dashboards call them. No SQL Agent job calls these procedures on a schedule — confirmed via job history and job step queries. Caller is whoever opens these dashboards in Grafana. Confirmed internal use only — not client-facing.

**Why it matters:**
The procedures are called by Grafana dashboards only — no automated pipeline. The data they report on has been stale since May 2026. Any month-end report run since then has been using stale data. Admins need to be notified before decommission.

**Proposed actions:**
- Notify the DBA team that REP_MONTHEND data has been stale since May 2026 and that the dashboards will be retired on decommission
- Include month-end dashboard retirement in the decommission handover — no replacement pipeline needed (internal use only, no client impact)
- Note: 7 procedures in DBA_VCC_MEMSQL use the `CLINT` typo (vs `CLIENT`) — clean up regardless of decommission outcome

---

## 7. Slack Alerts — Zabbix Is the Only Path

**What we found:**
EW1R-REP-01 does not post directly to Slack. All SlackChatPostMessage calls in stored procedures are commented out. Grafana alert_configuration has a placeholder email only (`grafana-default-email`, `<example@email.com>`). No Slack contact points configured in the database. No provisioning files with Slack config found. No stored procedures reference the alert channels. No active consumer confirmed — Q4(C) closed.

**Why it matters:**
No active Slack consumer means nothing to migrate on decommission. Zabbix is the primary alert path but reads from this server via linked server — that dependency ends on decommission.

**Proposed actions:**
- No Slack migration required — no active consumer confirmed
- SPSlackCheckSyncStatus is dormant (MemSQL jobs disabled) — drop as part of DBA_VCC_MEMSQL cleanup
- 4 stored procedures reference dead linked servers (P23-P-AGGR-201, p23-p-aggr-301) — drop these regardless of decommission outcome
- Confirm with Zabbix / monitoring team what triggers on EW1R-REP-01 would be lost on decommission — Zabbix deadlock and sync check data stops

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
Three SQL Agent jobs call Python scripts that make AWS API calls (CloudWatch, S3, Cost Explorer): DBA_VCC_AWS_15MIN_CHECKS, DBA_VCC_AWS_DAILY_CHECKS, DBA_VCC_AWS_WEEKLY_CHECKS. The EC2 instance uses IAM instance profile `KurtosysEC2InstanceProfileRoleRep`. STS temporary credentials confirmed active (Code: Success, Type: AWS-HMAC, LastUpdated: 2026-08-11T08:25:43Z). No static access key stored on disk. Confirmed 2026-08-11 via instance metadata endpoint.

**Why it matters:**
Instance role is the preferred AWS credential pattern — no key rotation risk, no key on disk. On decommission, the instance profile must be detached and the IAM role reviewed for any permissions that should be revoked.

**Proposed actions:**
- Confirm with DevOps the permissions attached to `KurtosysEC2InstanceProfileRoleRep` — ensure they are scoped to minimum required (CloudWatch read, S3 write to ksys-ew1r-db-backups, Cost Explorer read)
- On decommission: detach the instance profile from the EC2 instance as part of the decommission checklist
- No key rotation required — instance role only, no static credentials

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
| Slack alerts | No consumer — nothing to migrate | Grafana alert_configuration has placeholder email only. No Slack contact points configured. No stored procedures reference the channels. |
| S3 backup encryption | Fix now | Encryption gaps are a compliance risk independent of decommission |
| IAM role/key for Python caller | Revoke on decommission | Instance profile `KurtosysEC2InstanceProfileRoleRep` confirmed. No static key. Detach instance profile on decommission. |
| ZabbixProdOld | Retire | Confirmed dead |
| pmmdev / pmmprod (Clickhouse) | Confirm | Both reachable — purpose and owner not yet confirmed |

---

## Decommission Blockers — Status

| # | Blocker | Status |
|---|---|---|
| B1 | Who calls REP_MONTHEND_* each month end — manual or automated? | CLOSED — called by Grafana dashboards only. No SQL Agent job or external scheduler found. 6 dashboards reference REP_MONTHEND: KAPP, InvestorPress, Encore, DXM, WPv2, Other Services Month End Reporting. Caller is whoever opens these dashboards in Grafana. Internal use only. |
| B2 | Is KAPP Client Utilisation and Growth Report shown to clients? | CLOSED — confirmed internal use only, not client-facing |
| B3 | Why were DBA_VCC_MEMSQL jobs disabled in May 2026 — is SingleStore decommissioned? | CLOSED — SingleStore is being decommissioned. All 7 MEMSQL jobs, DBA_VCC_MEMSQL, and 14 dependent dashboards are retire candidates |
| B4 | What is the migration plan for EW2P-MSSQL-01/02 monitoring post-decommission? | CLOSED — EW2P-MSSQL-01 and EW2P-MSSQL-02 confirmed as SQLNCLI linked servers on this server only. No other monitoring path exists. Migration must be planned before decommission date is set |
| B5 | Is the VCC framework replicated anywhere else or is this the only instance? | CLOSED — VCC framework is unique to this server. No VCC databases found on EW2P-MSSQL-01 or EW2P-MSSQL-02 |
| B6 | Who receives alerts-data-operations and alert-app-allow2fa-disabled — would they lose visibility? | CLOSED — Slack contact points not found in alert_configuration. Only receiver is grafana-default-email with placeholder address. No provisioning files with Slack config. No stored procedures reference these channels. No active consumer — nothing to migrate on decommission |
