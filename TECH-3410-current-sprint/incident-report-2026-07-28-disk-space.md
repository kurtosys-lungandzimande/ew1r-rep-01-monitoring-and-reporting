# Incident Report — Disk Space Alert ew1r-aggr-04
**Date:** 2026-07-28
**Investigated by:** Lunga Ndzimande
**Status:** Closed — root cause confirmed, action required

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
