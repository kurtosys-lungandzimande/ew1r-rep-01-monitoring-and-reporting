# Incident Report — Disk Space Alert ew1r-aggr-04
**Date:** 2026-07-28
**Investigated by:** Lunga Ndzimande
**Status:** Investigation complete — awaiting approval to remediate
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

---

## What Is This Server

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
**SingleStore version:** 8.5.18

---

## Investigation

### Access path
- Connected via release jumpbox `ew1r-jump-01.rel.kurtosys-internal.net`
- SSH to aggregator nodes not possible — credentials not available on jumpbox
- Connected via MySQL client to Master Aggregator (ew1r-aggr-03) port 3306
- Queried `information_schema.MV_NODES` and `information_schema.MV_DISK_USAGE`

### Cluster health — all nodes online
All 6 nodes confirmed online at time of investigation (2026-07-28 ~12:00 UTC).

### Disk usage across all nodes

| Node | Host | Role | Total Disk | Free | % Free | Status |
|---|---|---|---|---|---|---|
| 23 | ew1r-aggr-03 | Master Aggregator | 99 GB | 43 GB | 44% | ✅ Healthy |
| 2 | ew1r-aggr-04 | Child Aggregator | 77 GB | 17.6 GB | 22% | ⚠️ Low |
| 3 | ew1r-leaf-05 | Leaf | 317 GB | 184 GB | 58% | ✅ Healthy |
| 4 | ew1r-leaf-06 | Leaf | 317 GB | 187 GB | 59% | ✅ Healthy |
| 5 | ew1r-leaf-07 | Leaf | 317 GB | 186 GB | 59% | ✅ Healthy |
| 6 | ew1r-leaf-08 | Leaf | 317 GB | 182 GB | 57% | ✅ Healthy |

### Disk breakdown on ew1r-aggr-04 (Node 2)

| Directory | Used |
|---|---|
| user_data | 41.69 GB |
| plancache | 0.05 GB |
| tracelogs | ~0 GB |
| other_data | ~0 GB |
| **Total accounted by SingleStore** | **41.74 GB** |
| **Total disk used (OS level)** | **59.7 GB** |
| **Unaccounted gap** | **~18 GB** |

The ~18 GB gap outside SingleStore's data directory is likely OS files, system logs, or SingleStore binaries. SSH access to the node is required to confirm.

---

## Root Cause

`ew1r-aggr-04` was provisioned with a **77 GB disk** — significantly smaller than every other node in the cluster (99–317 GB). The disk is genuinely low and hovering around the 20% warning threshold. This is not a data spike — it is an undersized disk relative to the workload.

The alert resolved after 2 minutes because disk usage fluctuated back above the 20% threshold temporarily. The underlying problem remains.

---

## Risk

If nothing is done this alert will keep firing. If the disk fills completely the child aggregator node will go offline, degrading the SingleStore cluster for the Ireland Release environment.

---

## Actions Required

| # | Action | Owner | Priority |
|---|---|---|---|
| A1 | Expand EBS volume on ew1r-aggr-04 from 77 GB to at least 99 GB to match master aggregator | DevOps / Platform Engineering | High |
| A2 | SSH into ew1r-aggr-04 and identify what is filling the ~18 GB gap outside SingleStore data directory | DevOps / Platform Engineering | Medium |
| A3 | Review why ew1r-aggr-04 was provisioned with a smaller disk than other nodes — check if this was intentional | Platform Engineering | Low |

---

## Detailed OS Level Investigation

Accessed `ew1r-aggr-04` via **EC2 Instance Connect** from AWS Console (instance `i-0d36d94a301b8ddbc`).

### Disk usage confirmed

```
Filesystem      Size  Used Avail Use% Mounted on
/dev/root        78G   60G   18G  78% /
```

### Top level folders by size

| Folder | Size | Notes |
|---|---|---|
| /var | 51 GB | Dominant — drill down needed |
| /opt | 5.7 GB | Application files |
| /usr | 3.0 GB | OS binaries |
| /snap | 2.5 GB | Snap packages |
| /boot | 219 MB | Boot files |

### /var breakdown

| Folder | Size | Notes |
|---|---|---|
| /var/lib | 44 GB | SingleStore data + other libs |
| /var/log | 4.2 GB | ⚠️ Logs — too large |
| /var/swapfile | 3.1 GB | Normal — swap file |
| /var/cache | 221 MB | Normal |

### /var/lib breakdown

| Folder | Size | Notes |
|---|---|---|
| /var/lib/memsql | **42 GB** | SingleStore data files |
| /var/lib/snapd | 1.1 GB | Snap daemon |
| /var/lib/apt | 308 MB | Package manager cache |
| /var/lib/clamav | 108 MB | Antivirus definitions |

### /var/log breakdown

| Folder | Size | Notes |
|---|---|---|
| /var/log/journal | **3.8 GB** | ⚠️ System journal logs — bloated, safe to clean |
| /var/log/amazon | 238 MB | AWS agent logs — normal |
| /var/log/clamav | 127 MB | Antivirus logs |
| /var/log/auth.log.1 | 23 MB | Auth logs |
| /var/log/zabbix | 360 KB | Zabbix agent logs |

### Journal log size confirmed
```
Archived and active journals take up 3.7G in the file system.
```

---

## Root Cause — Confirmed

Two contributing factors:

1. **Undersized disk** — `ew1r-aggr-04` has a 78 GB disk. Every other node in the cluster has 99–317 GB. This was a provisioning oversight when the node was launched (2025-10-07).

2. **Bloated journal logs** — `/var/log/journal` has accumulated 3.8 GB of system logs with no size cap configured. This is preventable and fixable at zero cost.

---

## Access Investigation

During investigation the following access paths were attempted:

| Method | Result |
|---|---|
| SSH from jumpbox as CSE | Permission denied |
| SSH from jumpbox as ubuntu | Permission denied |
| SSH from master aggregator | Permission denied |
| MySQL via FundPressDataReader | Connected but insufficient privileges |
| MySQL via admin user | Connected — cluster data retrieved |
| AWS SSM Session Manager | SSM plugin not installed on jumpbox |
| EC2 Instance Connect (AWS Console) | ✅ Connected successfully |
| SSH key (kappeurel.pem) on jumpbox | Not present — only authorized_keys exists |

**Note:** The `kappeurel.pem` SSH key for the release environment is not stored on the jumpbox. Future SSH access to SingleStore nodes requires either EC2 Instance Connect or the key from a secrets manager.

---

## Recommendations — In Priority Order

| # | Action | Cost | Effort | Impact |
|---|---|---|---|---|
| 1 | Clean journal logs older than 7 days — `journalctl --vacuum-time=7d` | Free | 1 minute | Frees 3.8 GB immediately |
| 2 | Cap journal log size permanently — set `SystemMaxUse=500M` in `/etc/systemd/journald.conf` | Free | 5 minutes | Prevents recurrence |
| 3 | Check `/var/lib/memsql` for old snapshots or backups that can be removed | Free | 30 minutes | May free additional space |
| 4 | Clean apt cache — `apt clean` | Free | 1 minute | Frees ~308 MB |
| 5 | Expand EBS volume from 78 GB to 150 GB | ~$6/month extra | DevOps — 30 min | Permanent fix |
| 6 | Standardise disk sizes across all cluster nodes | ~$6/month extra | DevOps | Prevents same issue on other nodes |
| 7 | Install SSM agent on all SingleStore nodes | Free | DevOps | Enables future remote access without EC2 Instance Connect |
| 8 | Lower Zabbix disk alert threshold from 20% to 30% on this node | Free | 5 minutes | Earlier warning before disk fills |

**Recommended immediate action (pending approval):**
```bash
# Step 1 — clean journal logs
journalctl --vacuum-time=7d

# Step 2 — cap journal size permanently
echo 'SystemMaxUse=500M' >> /etc/systemd/journald.conf
systemctl restart systemd-journald

# Step 3 — verify
df -h /
```
Expected result: disk drops from 78% to ~73% used (frees ~3.8 GB).

---

## Queries Used

```sql
-- Cluster node health and disk
SELECT * FROM information_schema.MV_NODES;

-- Disk usage breakdown per node
SELECT 
    NODE_ID,
    MEMSQL_DIR,
    ROUND(DISK_USED_B / 1024 / 1024 / 1024, 2) AS disk_used_gb
FROM information_schema.MV_DISK_USAGE
ORDER BY NODE_ID, DISK_USED_B DESC;
```

## OS Commands Used

```bash
# Disk usage
df -h /

# Top level folder sizes
du -sh /* 2>/dev/null | sort -rh | head -20

# Drill into /var
du -sh /var/* 2>/dev/null | sort -rh | head -20

# Drill into /var/lib
du -sh /var/lib/* 2>/dev/null | sort -rh | head -20

# Drill into /var/log
du -sh /var/log/* 2>/dev/null | sort -rh | head -20

# Journal log size
journalctl --disk-usage
```
