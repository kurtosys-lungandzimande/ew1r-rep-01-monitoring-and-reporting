# Investigation Summary — ew1r-aggr-04 Disk Space & SingleStore Cluster Audit
**Date:** 2026-07-28
**Investigated by:** Lunga Ndzimande
**Status:** Investigation complete — pending approval and stakeholder confirmation
**Covers:** Zabbix disk space alert + full SingleStore cluster audit

---

## 1. What Triggered This Investigation

Zabbix fired a disk space warning on **ew1r-aggr-04.rel.kurtosys-internal.net** at 09:31 on 2026-07-28. Disk was at **15.55% free**. Alert resolved 2 minutes later. Investigation confirmed the alert was genuine — the underlying problem remains.

---

## 2. The Server

`ew1r-aggr-04` is the **Child Aggregator** in the Ireland Release SingleStore cluster.

| Role | Host | IP |
|---|---|---|
| Admin Server | ew1r-admin-01.rel.kurtosys-internal.net | 10.77.11.227 |
| Master Aggregator | ew1r-aggr-03.rel.kurtosys-internal.net | 10.77.6.161 |
| **Child Aggregator** | **ew1r-aggr-04.rel.kurtosys-internal.net** | **10.77.2.255** |
| Leaf | ew1r-leaf-05.rel.kurtosys-internal.net | 10.77.9.93 |
| Leaf | ew1r-leaf-06.rel.kurtosys-internal.net | 10.77.10.114 |
| Leaf | ew1r-leaf-07.rel.kurtosys-internal.net | 10.77.1.69 |
| Leaf | ew1r-leaf-08.rel.kurtosys-internal.net | 10.77.8.81 |

**Environment:** KAPP — REL — Ireland — KurtosysApp_Non-Prod
**Instance ID:** i-0d36d94a301b8ddbc
**SingleStore version:** 8.5.18

---

## 3. Cluster Disk Health

| Node | Host | Role | Total Disk | Free | % Free | Status |
|---|---|---|---|---|---|---|
| 23 | ew1r-aggr-03 | Master Aggregator | 99 GB | 43 GB | 44% | ✅ Healthy |
| 2 | ew1r-aggr-04 | Child Aggregator | 78 GB | 18 GB | 22% | ⚠️ Low |
| 3 | ew1r-leaf-05 | Leaf | 317 GB | 184 GB | 58% | ✅ Healthy |
| 4 | ew1r-leaf-06 | Leaf | 317 GB | 187 GB | 59% | ✅ Healthy |
| 5 | ew1r-leaf-07 | Leaf | 317 GB | 186 GB | 59% | ✅ Healthy |
| 6 | ew1r-leaf-08 | Leaf | 317 GB | 182 GB | 57% | ✅ Healthy |

`ew1r-aggr-04` is the only node provisioned below 99 GB. All leaf nodes are healthy now but each carries ~108 GB of user data — see Finding 3 below.

---

## 4. Disk Breakdown on ew1r-aggr-04

**Baseline (pre-remediation):**
```
Filesystem      Size  Used Avail Use% Mounted on
/dev/root        78G   60G   18G  78% /
```

| Folder | Size | Notes |
|---|---|---|
| /var/lib/memsql | 42 GB | SingleStore snapshots — see Finding 1 |
| /var/log/journal | 3.8 GB | ⚠️ Bloated — no size cap configured |
| /var/swapfile | 3.1 GB | Normal |
| /var/lib/snapd | 1.1 GB | Normal |
| /var/lib/apt | 308 MB | Safe to clean |
| /var/log/amazon | 238 MB | Normal |
| /var/lib/clamav | 108 MB | Antivirus — see Finding 4 |

---

## 5. Findings

---

### Finding 1 — Orphaned SingleStore Snapshots on aggr-04 (14.2 GB)

**Location:** `/var/lib/memsql/11dbd517-1c12-42f7-87f1-ac38eb9a2ad4/data/snapshots/`

Full snapshot inventory:

| File | Size | Date | Classification |
|---|---|---|---|
| UDM1_Kurtosys_snapshot_v1_0_176143646078 | 6.2 GB | Aug 6 2025 | ⚠️ Orphaned — safe to delete |
| UDM1_Kurtosys_snapshot_v1_0_176144118380 | 8.0 GB | Aug 25 2025 | ⚠️ Orphaned — safe to delete |
| SearchTest_snapshot_v1_0_1139 | 1.2 MB | Aug 6 2025 | ⚠️ Orphaned — safe to delete |
| SearchTest_snapshot_v1_0_834 | 1.2 MB | Aug 6 2025 | ⚠️ Orphaned — safe to delete |
| DBAdmin_snapshot_v1_0_1758789 | 137 KB | Jul 15 2025 | ⚠️ Orphaned — safe to delete |
| DBAdmin_snapshot_v1_0_1781617 | 137 KB | Jul 15 2025 | ⚠️ Orphaned — safe to delete |
| UDM___snapshot_v1_0_176154955667 | 12 GB | Jul 24 2026 | ✅ Active — retain |
| UDM___snapshot_v1_0_176155093643 | 12 GB | Jul 28 2026 | ✅ Active — retain |
| cluster_snapshot_v1_0_15024271 | 54 MB | Jul 28 2026 | ✅ Active — retain |
| cluster_snapshot_v1_0_15022222 | 54 MB | Jul 28 2026 | ✅ Active — retain |
| memsql_snapshot_v1_0_12974405 | 4.1 KB | Jul 28 2026 | ✅ Active — retain |
| memsql_snapshot_v1_0_12972354 | 4.1 KB | Jul 28 2026 | ✅ Active — retain |
| information_schema_snapshot_v1_0_0 | 4.1 KB | Oct 7 2025 | ✅ Active — retain |
| DBAdmin_24062026_* (4 files) | ~692 KB | Jun 24 2026 | ✅ Active — retain |

**Total orphaned space: 14.2 GB**

`lsof +L1 /var` confirmed no active processes are holding these files. Deletion will immediately release 14.2 GB.

---

### Finding 2 — Bloated Journal Logs (3.8 GB)

`/var/log/journal` has accumulated 3.8 GB with no size cap configured. This is preventable and fixable at zero cost. `dmesg` confirmed no kernel disk pressure errors — the node has not yet hit a critical state.

**Fix:** `journalctl --vacuum-time=7d` + set `SystemMaxUse=500M` in `/etc/systemd/journald.conf`

---

### Finding 3 — UDM1_Kurtosys Is a Live Orphaned Database (Estimated 50–60 GB on leaf nodes)

This is the biggest finding of the investigation.

Two databases exist simultaneously on the cluster with identical schemas:

| Database | Tables | First Created | Last Modified | Status |
|---|---|---|---|---|
| UDM__ | 249 | 2025-08-06 04:39 | 2026-06-26 15:32 | ✅ Active — current |
| UDM1_Kurtosys | 215 | 2025-08-06 07:09 | 2025-08-06 09:56 | ⚠️ Frozen since Aug 2025 |

`UDM1_Kurtosys` was created 3 hours after `UDM__` on the same day, populated with data, and never modified again. `UDM__` has been actively maintained up to June 2026 and has 34 additional tables — it is the current version.

`UDM1_Kurtosys` has real row data:

| Table | Rows |
|---|---|
| ApplicationTemplateAsset | 51,230 |
| RolePermission | 18,640 |
| FundList | 17,437 |
| Sequence | 10,000 |
| UserRole | 7,855 |
| Properties | 7,676 |

Every table in `UDM1_Kurtosys` exists in `UDM__` — they are structurally identical. `UDM1_Kurtosys` appears to be a migration artefact from August 2025 that was never cleaned up.

The orphaned snapshots in Finding 1 (14.2 GB) are the snapshot files for this database.

The leaf nodes each carry ~108 GB of user data. A significant portion of this is likely `UDM1_Kurtosys` data. Dropping this database could free an estimated **50–60 GB across the 4 leaf nodes**.

**Blocker:** Cannot drop without confirmation from the application team that nothing is still connecting to `UDM1_Kurtosys`.

---

### Finding 4 — ClamAV Running on a Database Node

ClamAV antivirus is installed and active on `ew1r-aggr-04`:
- `/var/lib/clamav` — 108 MB of virus definitions
- `/var/log/clamav` — 127 MB of scan logs

Running antivirus on a SingleStore database node is unusual and potentially harmful — scheduled scans of `/var/lib/memsql` can cause I/O spikes and interfere with database performance. This should be reviewed.

**Recommendation:** Either disable ClamAV entirely on database nodes, or configure it to exclude `/var/lib/memsql` from scans.

---

### Finding 5 — Undersized Disk (Provisioning Oversight)

`ew1r-aggr-04` was provisioned on 2025-10-07 with a 78 GB disk. Every other node in the cluster has 99–317 GB. This was a provisioning oversight. Even after all cleanup, the active UDM__ snapshots alone are 24 GB and will grow — the disk will need expanding long term.

---

### Finding 6 — No SSM Agent on SingleStore Nodes

During investigation, AWS SSM Session Manager could not connect to any SingleStore node — the SSM agent is not installed. EC2 Instance Connect was the only working access method. This means:
- Future incident investigations require AWS Console access
- No automated patching or remote command execution via SSM
- If EC2 Instance Connect is restricted, nodes become inaccessible without SSH keys

---

### Finding 7 — SSH Keys Not on Jumpbox

The `kappeurel.pem` SSH key for the release environment is not stored on `ew1r-jump-01`. Only `authorized_keys` exists. Future SSH access to SingleStore nodes requires either EC2 Instance Connect or retrieving the key from a secrets manager.

---

## 6. Space Recovery Summary

| Action | Space Recovered | Cost | Risk |
|---|---|---|---|
| Delete orphaned snapshots (Finding 1) | 14.2 GB on aggr-04 | Free | None — confirmed by lsof |
| Clean journal logs (Finding 2) | 3.8 GB on aggr-04 | Free | None |
| Clean apt cache | 308 MB on aggr-04 | Free | None |
| Drop UDM1_Kurtosys (Finding 3) | ~50–60 GB across leaf nodes | Free | Requires app team confirmation |
| **Total immediate (free fixes)** | **~18.3 GB on aggr-04** | **Free** | |
| **Total if UDM1_Kurtosys dropped** | **~68–78 GB cluster-wide** | **Free** | Needs sign-off |

**Disk after immediate cleanup:**
```
Before:  78G total / 60G used / 18G free / 78% used
After:   78G total / 42G used / 36G free / 54% used
```

---

## 7. Remediation Commands (Pending Approval)

```bash
# Connect via EC2 Instance Connect → ew1r-aggr-04 → sudo su

# Step 1 — delete orphaned snapshots
cd /var/lib/memsql/11dbd517-1c12-42f7-87f1-ac38eb9a2ad4/data/snapshots/
rm -f UDM1_Kurtosys_snapshot_v1_0_176143646078
rm -f UDM1_Kurtosys_snapshot_v1_0_176144118380
rm -f SearchTest_snapshot_v1_0_1139
rm -f SearchTest_snapshot_v1_0_834
rm -f DBAdmin_snapshot_v1_0_1758789
rm -f DBAdmin_snapshot_v1_0_1781617

# Step 2 — clean journal logs
journalctl --vacuum-time=7d

# Step 3 — cap journal size permanently
echo 'SystemMaxUse=500M' >> /etc/systemd/journald.conf
systemctl restart systemd-journald

# Step 4 — clean apt cache
apt clean

# Step 5 — verify
df -h /
```

---

## 8. Actions Required

| # | Action | Owner | Priority | Effort |
|---|---|---|---|---|
| A1 | Approve and execute remediation commands above | Manager + Lunga | Critical | 10 min |
| A2 | Confirm with application team — is anything still connecting to UDM1_Kurtosys? | Application team | High | 1 day |
| A3 | Drop UDM1_Kurtosys once confirmed unused — frees ~50–60 GB | DBA / DevOps | High | 30 min |
| A4 | Expand EBS volume on aggr-04 from 78 GB to 150 GB | DevOps | High | 30 min |
| A5 | Set up automated snapshot cleanup — cron job for files older than 90 days | DevOps | Medium | 1 hour |
| A6 | Install SSM agent on all SingleStore nodes | DevOps | Medium | 30 min |
| A7 | Review ClamAV on database nodes — disable or exclude /var/lib/memsql | DevOps | Medium | 15 min |
| A8 | Lower Zabbix disk alert threshold from 20% to 30% on aggr-04 | Monitoring team | Low | 5 min |
| A9 | Store kappeurel.pem in secrets manager and document access procedure | DevOps | Low | 30 min |

---

## 9. Questions Requiring Stakeholder Answers

| # | Question | Who to Ask |
|---|---|---|
| Q1 | Is any application still connecting to UDM1_Kurtosys on the Ireland Release cluster? | Application / KAPP team |
| Q2 | Was UDM1_Kurtosys intentionally kept alongside UDM__ or is it a migration artefact? | Application / KAPP team |
| Q3 | Is ClamAV on SingleStore nodes a security requirement or was it installed by mistake? | Security / DevOps |
| Q4 | Why was aggr-04 provisioned with 78 GB when all other nodes have 99–317 GB? | DevOps / Platform Engineering |

---

## 10. Related Incident Reports

| Report | Location |
|---|---|
| Zabbix alerts 2026-07-25 (errorlog + CHECKDB) | TECH-3410-current-sprint/incident-report-2026-07-25.md |
| Disk space alert 2026-07-28 (detailed) | TECH-3410-current-sprint/incident-report-2026-07-28-disk-space.md |
| This summary | TECH-3410-current-sprint/investigation-summary-2026-07-28.md |
