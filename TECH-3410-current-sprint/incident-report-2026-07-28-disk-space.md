# Incident Report — Disk Space Alert ew1r-aggr-04
**Date:** 2026-07-28
**Investigated by:** Lunga Ndzimande
**Status:** Investigation complete — pending approval to remediate
**Last Updated:** 2026-07-28

---

## Alert Received

| Item | Value |
|---|---|
| Host | ew1r-aggr-04.rel.kurtosys-internal.net |
| Alert | Free disk space is less than 20% on volume / |
| Disk at alert time | 15.55% free |
| Alert fired | 2026-07-28 09:31 |
| Alert resolved | 2026-07-28 09:33 |
| Severity | Warning |

The alert resolved 2 minutes after firing because disk usage fluctuated back above the 20% threshold. The underlying problem remains.

---

## Server Context

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
**Instance type:** m7a.2xlarge
**SingleStore version:** 8.5.18

---

## Cluster Disk Health — All Nodes

Queried via `information_schema.MV_NODES` on Master Aggregator (ew1r-aggr-03).

| Node | Host | Role | Total Disk | Free | % Free | Status |
|---|---|---|---|---|---|---|
| 23 | ew1r-aggr-03 | Master Aggregator | 99 GB | 43 GB | 44% | ✅ Healthy |
| 2 | ew1r-aggr-04 | Child Aggregator | 78 GB | 18 GB | 22% | ⚠️ Low |
| 3 | ew1r-leaf-05 | Leaf | 317 GB | 184 GB | 58% | ✅ Healthy |
| 4 | ew1r-leaf-06 | Leaf | 317 GB | 187 GB | 59% | ✅ Healthy |
| 5 | ew1r-leaf-07 | Leaf | 317 GB | 186 GB | 59% | ✅ Healthy |
| 6 | ew1r-leaf-08 | Leaf | 317 GB | 182 GB | 57% | ✅ Healthy |

`ew1r-aggr-04` is the only node with a disk below 99 GB. All other nodes are healthy.

---

## Baseline Disk State (Pre-Remediation)

Captured directly from the server via EC2 Instance Connect:

```
Filesystem      Size  Used Avail Use% Mounted on
/dev/root        78G   60G   18G  78% /
```

---

## OS-Level Disk Breakdown

### Top-level folders

| Folder | Size | Notes |
|---|---|---|
| /var | 51 GB | Dominant — see breakdown below |
| /opt | 5.7 GB | Application files |
| /usr | 3.0 GB | OS binaries |
| /snap | 2.5 GB | Snap packages |
| /boot | 219 MB | Boot files |
| /tmp | 125 MB | Temp files |

### /var breakdown

| Folder | Size | Notes |
|---|---|---|
| /var/lib | 44 GB | SingleStore data + system libs |
| /var/log | 4.2 GB | ⚠️ Logs — bloated |
| /var/swapfile | 3.1 GB | Normal — swap file |
| /var/cache | 221 MB | Package manager cache |
| /var/backups | 2.3 MB | Normal |

### /var/lib breakdown

| Folder | Size | Notes |
|---|---|---|
| /var/lib/memsql | **42 GB** | SingleStore data — see snapshot detail below |
| /var/lib/snapd | 1.1 GB | Snap daemon |
| /var/lib/apt | 308 MB | Package manager cache — safe to clean |
| /var/lib/clamav | 108 MB | Antivirus definitions |

### /var/log breakdown

| Folder | Size | Notes |
|---|---|---|
| /var/log/journal | **3.8 GB** | ⚠️ System journal logs — bloated, no size cap set |
| /var/log/amazon | 238 MB | AWS agent logs — normal |
| /var/log/clamav | 127 MB | Antivirus logs |
| /var/log/auth.log.1 | 23 MB | Auth logs |
| /var/log/zabbix | 360 KB | Zabbix agent logs |

---

## SingleStore Snapshot Inventory — Root Cause

All 42 GB in `/var/lib/memsql` is concentrated in one node directory:

```
/var/lib/memsql/11dbd517-1c12-42f7-87f1-ac38eb9a2ad4/data/snapshots/
```

Full file listing with sizes and modification dates:

```
total 38G
-rw------- 1 memsql memsql 173K Jun 24 13:56 DBAdmin_24062026_Instant_direct_snapshot_v1_0_1782840
-rw------- 1 memsql memsql 173K Jun 24 13:38 DBAdmin_24062026_Instant_snapshot_v1_0_1782840
-rw------- 1 memsql memsql 173K Jun 24 13:55 DBAdmin_24062026_standard_direct_snapshot_v1_0_1782840
-rw------- 1 memsql memsql 173K Jun 24 13:33 DBAdmin_24062026_standard_snapshot_v1_0_1782840
-rw------- 1 memsql memsql 137K Jul 15  2025 DBAdmin_snapshot_v1_0_1758789
-rw------- 1 memsql memsql 137K Jul 15  2025 DBAdmin_snapshot_v1_0_1781617
-rw------- 1 memsql memsql 1.2M Aug  6  2025 SearchTest_snapshot_v1_0_1139
-rw------- 1 memsql memsql 1.2M Aug  6  2025 SearchTest_snapshot_v1_0_834
-rw------- 1 memsql memsql 6.2G Aug  6  2025 UDM1_Kurtosys_snapshot_v1_0_176143646078
-rw------- 1 memsql memsql 8.0G Aug 25  2025 UDM1_Kurtosys_snapshot_v1_0_176144118380
-rw------- 1 memsql memsql  12G Jul 24 10:29 UDM___snapshot_v1_0_176154955667
-rw------- 1 memsql memsql  12G Jul 28 09:33 UDM___snapshot_v1_0_176155093643
-rw------- 1 memsql memsql  54M Jul 28 10:36 cluster_snapshot_v1_0_15022222
-rw------- 1 memsql memsql  54M Jul 28 12:41 cluster_snapshot_v1_0_15024271
-rw------- 1 memsql memsql 4.1K Oct  7  2025 information_schema_snapshot_v1_0_0
-rw------- 1 memsql memsql 4.1K Jul 28 12:46 memsql_snapshot_v1_0_12972354
-rw------- 1 memsql memsql 4.1K Jul 28 14:11 memsql_snapshot_v1_0_12974405
```

### Snapshot classification

**A — Orphaned legacy snapshots (safe to delete — pending approval)**

These files are from databases that no longer exist or have been superseded. Last modified August 2025 — over 11 months old. Not referenced by any active SingleStore process.

| File | Size | Last Modified |
|---|---|---|
| UDM1_Kurtosys_snapshot_v1_0_176143646078 | 6.2 GB | Aug 6 2025 |
| UDM1_Kurtosys_snapshot_v1_0_176144118380 | 8.0 GB | Aug 25 2025 |
| SearchTest_snapshot_v1_0_1139 | 1.2 MB | Aug 6 2025 |
| SearchTest_snapshot_v1_0_834 | 1.2 MB | Aug 6 2025 |
| DBAdmin_snapshot_v1_0_1758789 | 137 KB | Jul 15 2025 |
| DBAdmin_snapshot_v1_0_1781617 | 137 KB | Jul 15 2025 |
| **Total** | **~14.2 GB** | |

**B — Active snapshots (must be retained)**

Current UDM database snapshots updated this month. These are live and must not be touched.

| File | Size | Last Modified |
|---|---|---|
| UDM___snapshot_v1_0_176154955667 | 12 GB | Jul 24 2026 |
| UDM___snapshot_v1_0_176155093643 | 12 GB | Jul 28 2026 |
| **Total** | **24 GB** | |

**C — Active system metadata (must be retained)**

Cluster configuration and system state files updated regularly.

| File | Size | Last Modified |
|---|---|---|
| cluster_snapshot_v1_0_15024271 | 54 MB | Jul 28 2026 12:41 |
| cluster_snapshot_v1_0_15022222 | 54 MB | Jul 28 2026 10:36 |
| memsql_snapshot_v1_0_12974405 | 4.1 KB | Jul 28 2026 14:11 |
| memsql_snapshot_v1_0_12972354 | 4.1 KB | Jul 28 2026 12:46 |
| information_schema_snapshot_v1_0_0 | 4.1 KB | Oct 7 2025 |
| DBAdmin_24062026_* (4 files) | ~692 KB | Jun 24 2026 |
| **Total** | **~108 MB** | |

---

## Open File Handle Check (lsof)

`lsof +L1 /var` was run to confirm no active processes are holding deleted file handles that would prevent space from being reclaimed after deletion.

**Result:** No SingleStore or memsql processes are holding open handles to deleted files in `/var`. All entries in the lsof output are system binaries (sshd, python3, systemd-logind) that were updated via package manager — these are standard OS behaviour and do not affect disk reclamation.

**Conclusion:** Deleting the orphaned snapshot files will immediately release the full 14.2 GB back to the OS.

---

## System Log Check (dmesg)

`dmesg -T | grep -iE 'disk|space|memsql|singlestore'` returned one entry — a systemd startup message from the last reboot (Jun 10 2026). No disk pressure warnings, no kernel OOM events, no SingleStore disk errors in the kernel log.

**Conclusion:** The disk pressure has not yet caused any kernel-level errors. The node is degraded but not in a critical failure state.

---

## Root Cause Summary

Two contributing factors:

1. **Orphaned snapshots** — 14.2 GB of stale SingleStore snapshot files from August 2025 have never been cleaned up. These are from the `UDM1_Kurtosys` and `SearchTest` databases and are no longer active.

2. **Undersized disk** — `ew1r-aggr-04` was provisioned with a 78 GB disk on 2025-10-07. Every other node in the cluster has 99–317 GB. Even after cleaning the orphaned snapshots, the active UDM snapshot footprint alone is 24 GB, which will continue to grow.

Additionally, `/var/log/journal` has accumulated 3.8 GB with no size cap — a secondary contributor that is free to fix.

---

## Remediation Plan

### Immediate — free, zero service impact (requires approval)

```bash
# Step 1 — navigate to snapshot directory
cd /var/lib/memsql/11dbd517-1c12-42f7-87f1-ac38eb9a2ad4/data/snapshots/

# Step 2 — delete orphaned 2025 snapshots (frees 14.2 GB)
rm -f UDM1_Kurtosys_snapshot_v1_0_176143646078
rm -f UDM1_Kurtosys_snapshot_v1_0_176144118380
rm -f SearchTest_snapshot_v1_0_1139
rm -f SearchTest_snapshot_v1_0_834
rm -f DBAdmin_snapshot_v1_0_1758789
rm -f DBAdmin_snapshot_v1_0_1781617

# Step 3 — clean journal logs (frees 3.8 GB)
journalctl --vacuum-time=7d

# Step 4 — cap journal size permanently
echo 'SystemMaxUse=500M' >> /etc/systemd/journald.conf
systemctl restart systemd-journald

# Step 5 — clean apt cache (frees ~308 MB)
apt clean

# Step 6 — verify
df -h /
```

**Expected result after cleanup:**

| Item | Before | After |
|---|---|---|
| Orphaned snapshots | 14.2 GB | 0 GB |
| Journal logs | 3.8 GB | ~0.1 GB |
| Apt cache | 308 MB | ~0 MB |
| **Total disk used** | **60 GB (78%)** | **~42 GB (~54%)** |
| **Free space** | **18 GB** | **~36 GB** |

### Long term — requires DevOps action

| Action | Cost | Notes |
|---|---|---|
| Expand EBS volume from 78 GB to 150 GB | ~$6/month extra | Permanent fix — active UDM snapshots are 24 GB and growing |
| Set up automated snapshot cleanup (cron) for files older than 90 days | Free | Prevents orphaned snapshots accumulating again |
| Install SSM agent on all SingleStore nodes | Free | Enables future access without EC2 Instance Connect |
| Lower Zabbix disk alert threshold from 20% to 30% on this node | Free | Earlier warning before disk fills |

---

## Access Methods Used During Investigation

| Method | Result |
|---|---|
| SSH from jumpbox as CSE/ubuntu/ec2-user | Permission denied — no private key on jumpbox |
| MySQL via FundPressDataReader | Connected — insufficient privileges for cluster queries |
| MySQL via admin user (ew1r-aggr-03) | ✅ Connected — cluster data retrieved |
| AWS SSM Session Manager | SSM plugin not installed on jumpbox |
| EC2 Instance Connect (AWS Console) | ✅ Connected — full OS access as root |

---

## Commands Used

```sql
-- Cluster node health and disk
SELECT * FROM information_schema.MV_NODES;

-- Disk usage per node
SELECT NODE_ID, MEMSQL_DIR,
       ROUND(DISK_USED_B / 1024 / 1024 / 1024, 2) AS disk_used_gb
FROM information_schema.MV_DISK_USAGE
ORDER BY NODE_ID, DISK_USED_B DESC;
```

```bash
df -h /
du -sh /* 2>/dev/null | sort -rh | head -20
du -sh /var/* 2>/dev/null | sort -rh
du -sh /var/lib/* 2>/dev/null | sort -rh | head -20
du -sh /var/log/* 2>/dev/null | sort -rh | head -20
du -sh /var/lib/memsql/* 2>/dev/null | sort -rh | head -20
du -sh /var/lib/memsql/11dbd517-1c12-42f7-87f1-ac38eb9a2ad4/* 2>/dev/null | sort -rh | head -20
du -sh /var/lib/memsql/11dbd517-1c12-42f7-87f1-ac38eb9a2ad4/data/* 2>/dev/null | sort -rh | head -20
ls -lh /var/lib/memsql/11dbd517-1c12-42f7-87f1-ac38eb9a2ad4/data/snapshots/
sudo find /var/ -type f -size +500M -exec ls -lh {} \;
lsof +L1 /var
dmesg -T | grep -iE 'disk|space|memsql|singlestore' | tail -n 10
journalctl --disk-usage
```
