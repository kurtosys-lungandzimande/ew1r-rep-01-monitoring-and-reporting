# TECH-4268 — Investigation Log

**Server:** EW1R-REP-01 (10.72.8.216)
**Branch:** TECH-4268-disable-jobs-and-offline-dbs
**Last updated:** 2026-09-28
**Updated by:** Lunga Ndzimande

---

## Summary of current status

| Item | Status |
|---|---|
| Step 02 — Disable 50 jobs | ✅ Complete |
| Step 03 — 6 databases offline | ✅ Complete |
| Backups confirmed in S3 | ✅ Complete |
| Step 04 — Re-enable DBA_VCC_MEMSQL_DAILY_CHECKS | ⏳ BLOCKED — see blocker section below |
| Grafana 2FA alerts confirmed healthy | ⏳ BLOCKED — depends on step 04 |
| DBA Team notified | ❓ Pending confirmation |
| Monitoring team notified | ❓ Pending confirmation |
| Backup decision Option A or B recorded | ❓ Pending |
| Observation period agreed | ❓ Pending |

---

## Q35 — DBA_VCC_MEMSQL_DAILY_CHECKS failure root cause

### Full investigation timeline

| Date | Action | Finding |
|---|---|---|
| 2026-05-08 06:00 | Job ran at scheduled time | Failed — disabled immediately after |
| 2026-09-27 | Checked job history | History purged — oldest entry is 2026-08-28. Failure detail gone. |
| 2026-09-27 | Ran `sp_testlinkedserver` on ew1r-aggr-01 | Failed — `Can't connect to MySQL server on '10.77.0.130:3306' (10060)` |
| 2026-09-27 | Ran `sp_testlinkedserver` on ew1r-aggr-02 | Failed — `Can't connect to MySQL server on '10.77.1.253:3306' (10060)` |
| 2026-09-27 | Ran ping to 10.77.0.130 | 100% packet loss |
| 2026-09-27 | Ran ping to 10.77.1.253 | 100% packet loss |
| 2026-09-27 | Confirmed with DBA team | EW1R SingleStore cluster is live — not a cluster outage |
| 2026-09-27 | Ran `nslookup ew1r-aggr-03` on EW1R-REP-01 | Non-existent domain — DNS resolution failing |
| 2026-09-27 | Ran `nslookup ew1r-aggr-03.rel.kurtosys-internal.net` | Non-existent domain — still failing |
| 2026-09-28 | Checked AWS EC2 console for ew1r-aggr-03 | Instance running — new IP 10.77.6.161 (old was 10.77.0.130) |
| 2026-09-28 | Checked AWS EC2 console for ew1r-aggr-04 | Instance running — new IP 10.77.2.255 (old was 10.77.1.253) |
| 2026-09-28 | Checked Route53 `rel.kurtosys-internal.net` | Record exists: `ew1r-aggr-03.rel.kurtosys-internal.net` → 10.77.6.161 ✅ |
| 2026-09-28 | Checked hosted zone associated VPCs | Only `vpc-0f04064c60dcbe579` (ew1r-kapp) associated — EW1R-REP-01 VPC missing |
| 2026-09-28 | Checked EW1R-REP-01 VPC | `vpc-0312c2efa75e26a4d` (ew1r-shared) — NOT associated with rel.kurtosys-internal.net |
| 2026-09-28 | Ran Step 1 — cross-account VPC association authorization | ✅ Done from ew1r-aggr-03 (SingleStore account) |
| 2026-09-28 | Ran Step 2 — associate VPC from EW1R-REP-01 | ❌ FAILED — IAM role `KurtosysEC2InstanceProfileRoleRep` lacks `route53:AssociateVPCWithHostedZone` permission |
| 2026-09-28 | Tried CloudShell in reporting account | ❌ FAILED — `AWSReservedSSO_Ksys-DBA-Support-NonProd` role lacks `cloudshell:CreateEnvironment` permission |

---

### Evidence

**Linked server test — ew1r-aggr-01 (2026-09-27):**
```
OLE DB provider "MSDASQL" for linked server "ew1r-aggr-01" returned message
"[MySQL][ODBC 8.0(w) Driver]Can't connect to MySQL server on '10.77.0.130:3306' (10060)".
Msg 7303 — Cannot initialize the data source object of OLE DB provider "MSDASQL"
for linked server "ew1r-aggr-01".
```

**Linked server test — ew1r-aggr-02 (2026-09-27):**
```
OLE DB provider "MSDASQL" for linked server "ew1r-aggr-02" returned message
"[MySQL][ODBC 8.0(w) Driver]Can't connect to MySQL server on '10.77.1.253:3306' (10060)".
Msg 7303 — Cannot initialize the data source object of OLE DB provider "MSDASQL"
for linked server "ew1r-aggr-02".
```

**Ping test — 10.77.0.130 (ew1r-aggr-01):**
```
Packets: Sent = 2, Received = 0, Lost = 2 (100% loss)
```

**Ping test — 10.77.1.253 (ew1r-aggr-02):**
```
Packets: Sent = 2, Received = 0, Lost = 2 (100% loss)
```

**nslookup ew1r-aggr-03 on EW1R-REP-01:**
```
*** ip-10-72-8-2.eu-west-1.compute.internal can't find ew1r-aggr-03: Non-existent domain
DNS server: 10.72.8.2
```

**nslookup ew1r-aggr-03.rel.kurtosys-internal.net on EW1R-REP-01:**
```
*** ip-10-72-8-2.eu-west-1.compute.internal can't find ew1r-aggr-03.rel.kurtosys-internal.net: Non-existent domain
DNS server: 10.72.8.2
```

**Step 2 — associate VPC attempt from EW1R-REP-01:**
```
An error occurred (AccessDenied) when calling the AssociateVPCWithHostedZone operation:
User: arn:aws:sts::649997393595:assumed-role/KurtosysEC2InstanceProfileRoleRep/i-07772df4e22bad8ae
is not authorized to perform: route53:AssociateVPCWithHostedZone on resource:
arn:aws:route53:::hostedzone/Z089788836L79G874CNG8
because no identity-based policy allows the route53:AssociateVPCWithHostedZone action
```

---

### Root cause — fully confirmed 2026-09-28

The instances `ew1r-aggr-03` and `ew1r-aggr-04` were relaunched at some point after 8 May 2026 with new private IPs:

| Node | Old IP (pre-May 2026) | New IP (current) |
|---|---|---|
| ew1r-aggr-03 | 10.77.0.130 | 10.77.6.161 |
| ew1r-aggr-04 | 10.77.1.253 | 10.77.2.255 |

The DNS record `ew1r-aggr-03.rel.kurtosys-internal.net` exists in Route53 and correctly points to `10.77.6.161`. However EW1R-REP-01 cannot resolve it because:

- `rel.kurtosys-internal.net` private hosted zone is only associated with `vpc-0f04064c60dcbe579` (ew1r-kapp)
- EW1R-REP-01 lives in `vpc-0312c2efa75e26a4d` (ew1r-shared)
- `vpc-0312c2efa75e26a4d` is not associated with the hosted zone
- EW1R-REP-01's DNS server (`10.72.8.2`) therefore cannot resolve any `*.rel.kurtosys-internal.net` hostname

---

### Stored procedure analysis — SP_AUDIT_FP_Client_Sizes_DETAILED

The procedure does not hardcode linked server names. It dynamically selects which servers to connect to by querying:
- `DBA_VCC_MEMSQL..LU_Serverlist` — WHERE Role = 'Master Aggregator' AND SERVERNAME NOT LIKE '%gen%'
- `DBA_VCC_MEMSQL.dbo.BAS_Ping_Stat` — only servers with Status = 1 within last 40 minutes
- `DBA_VCC_MEMSQL.dbo.BAS_SQL_Status` — only servers with Status = 1 within last 40 minutes

It then uses `OPENQUERY([SERVERNAME], ...)` to connect to each qualifying server.

**Master Aggregators in LU_Serverlist (non-gen):**
- ec1p-aggr-01
- ew1d-admin-01
- ew1d-aggr-05
- EW1R-AGGR-03 ← the EW1R environment node
- ew2p-aggr-03
- ue1p-aggr-03

**BAS_Ping_Stat and BAS_SQL_Status** — last updated 2026-05-08 12:00:00. All servers showed Status = 1 at that time including EW1R-AGGR-03. Data frozen since job was disabled.

---

## Current blocker — IAM permission required

### What needs to happen

Associate `vpc-0312c2efa75e26a4d` (ew1r-shared — EW1R-REP-01's VPC) with the `rel.kurtosys-internal.net` private hosted zone (`Z089788836L79G874CNG8`). This is a cross-account operation.

### Progress

| Step | Action | Status |
|---|---|---|
| Step 1 | Create VPC association authorization in SingleStore account | ✅ Done 2026-09-28 from ew1r-aggr-03 |
| Step 2 | Associate VPC from reporting account | ❌ Blocked — IAM permission missing |

**⚠️ Step 1 authorization expires in 7 days from 2026-09-28 — Step 2 must be completed before 2026-10-05.**

### IAM permission needed

Add the following inline policy to role `KurtosysEC2InstanceProfileRoleRep` in account `649997393595`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "route53:AssociateVPCWithHostedZone",
      "Resource": "arn:aws:route53:::hostedzone/Z089788836L79G874CNG8"
    }
  ]
}
```

This is a **one-time action** — the policy can be removed immediately after Step 2 completes.

### Command to run after IAM permission is granted

From EW1R-REP-01 PowerShell (Session Manager):
```powershell
aws route53 associate-vpc-with-hosted-zone `
  --hosted-zone-id Z089788836L79G874CNG8 `
  --vpc VPCRegion=eu-west-1,VPCId=vpc-0312c2efa75e26a4d
```

### Why this is needed

Without this fix:
- EW1R-REP-01 cannot resolve `ew1r-aggr-03.rel.kurtosys-internal.net`
- Linked servers remain broken
- `DBA_VCC_MEMSQL_DAILY_CHECKS` cannot be re-enabled
- `DBA_VCC_MEMSQL` tables remain stale since 8 May 2026
- Both Grafana 2FA alert rules evaluate against 4-month-old data
- A real 2FA configuration change could go undetected

### Who to contact

Raise with whoever has IAM admin access in account `649997393595` (reporting account):
- Tashvir Babulal
- Yogeshwar Phull
- Rayhaan Suleyman

---

## Next steps once IAM permission is granted

1. Run Step 2 from EW1R-REP-01 PowerShell — associate VPC with hosted zone
2. Test DNS resolution:
   ```sql
   EXEC xp_cmdshell 'nslookup ew1r-aggr-03.rel.kurtosys-internal.net';
   ```
   Expected: resolves to `10.77.6.161`
3. Test linked server connectivity:
   ```sql
   EXEC sp_testlinkedserver N'ew1r-aggr-03';
   EXEC sp_testlinkedserver N'ew1r-aggr-04';
   ```
   Expected: both pass with no error
4. Remove the temporary IAM policy from `KurtosysEC2InstanceProfileRoleRep`
5. Proceed to `04-reenable-2fa-job.sql`
6. Wait for 06:00 UTC run or trigger manually
7. Run `T05-post-2fa-reenable.sql` — confirm data is flowing
8. Verify Grafana 2FA alert rules in UI — confirm Normal/Pending state

---

## Execution progress

### Backups — ✅ CONFIRMED (2026-09-26)

Automated backup jobs confirmed backups in S3 for all 8 databases:

| Database | Last Backup | Size |
|---|---|---|
| DBA_VCC | 2026-09-26 00:03 | 21.9 GB |
| DBA_VCC_ATLASSIAN | 2026-09-26 00:04 | 61 MB |
| DBA_VCC_AWS | 2026-09-26 00:18 | 90.2 GB |
| DBA_VCC_COST | 2026-09-26 00:19 | 2.8 GB |
| DBA_VCC_MEMSQL | 2026-09-26 00:33 | 77.2 GB |
| DBA_VCC_MYSQL | 2026-09-26 00:41 | 27.1 GB |
| KURTOSYS_BASELINE | 2026-09-26 00:49 | 53.1 GB |
| Utilities | 2026-09-26 00:50 | 201 MB |

S3 folders confirmed present in ksys-ew1r-db-backups. No manual backup required.

### Step 02 — Disable jobs ✅ COMPLETE (2026-09-27)

- 50 jobs disabled successfully
- `DBA - Maintenance - SQL Backup EW1P-OCT` — confirmed ENABLED
- `syspolicy_purge_history` — confirmed ENABLED
- `DBA_VCC_MEMSQL_DAILY_CHECKS` — confirmed DISABLED (re-enable pending blocker fix)
- `DBA - SSISStatusCheck` was missed in first run — manually disabled and confirmed

### Step 03 — Databases offline ✅ COMPLETE (2026-09-28 05:18 UTC)

Note: Databases were briefly brought back online on 2026-09-28 to verify backup status.
Confirmed automated backups existed in S3. Databases taken offline again at 05:18 UTC.

| Database | State |
|---|---|
| DBA_VCC | ONLINE ✅ — Grafana 2FA connection proxy |
| DBA_VCC_MEMSQL | ONLINE ✅ — 2FA job writes here |
| DBA_VCC_ATLASSIAN | OFFLINE ✅ |
| DBA_VCC_AWS | OFFLINE ✅ |
| DBA_VCC_COST | OFFLINE ✅ |
| DBA_VCC_MYSQL | OFFLINE ✅ |
| KURTOSYS_BASELINE | OFFLINE ✅ |
| Utilities | OFFLINE ✅ |

### Step 04 — Re-enable DBA_VCC_MEMSQL_DAILY_CHECKS ⏳ BLOCKED

Blocked on IAM permission for Route53 VPC association. See blocker section above.

---

## Definition of Done — current status

- ✅ Pre-job state of all 63 jobs captured
- ✅ Final backups confirmed in S3 (automated — 2026-09-26)
- ✅ Grafana 2FA datasource dependency confirmed — DBA_VCC stays ONLINE
- ✅ All 50 jobs disabled
- ✅ Retained jobs confirmed still enabled
- ✅ 6 databases set OFFLINE
- ✅ DBA_VCC confirmed ONLINE
- ✅ DBA_VCC_MEMSQL confirmed ONLINE
- ⏳ DBA_VCC_MEMSQL_DAILY_CHECKS re-enabled — blocked on IAM permission (expires 2026-10-05)
- ⏳ DBA_VCC_MEMSQL data freshness confirmed — blocked on step 04
- ⏳ Both 2FA Grafana alert rules confirmed healthy — blocked on step 04
- ❓ DBA Team notified (Tashvir, Yogeshwar, Rayhaan) — confirm
- ❓ Monitoring team notified — Zabbix checks stop — confirm
- ❓ Backup decision Option A or B recorded
- ❓ Observation period agreed with follow-up date
