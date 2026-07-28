# Evidence & Queries — ew1r-aggr-04 Disk Space Investigation
**Date:** 2026-07-28
**Investigated by:** Lunga Ndzimande
**Server:** ew1r-aggr-04.rel.kurtosys-internal.net (i-0d36d94a301b8ddbc)
**Access method:** EC2 Instance Connect (AWS Console) + MySQL via Master Aggregator

---

## Part 1 — OS Level Evidence

All commands run as root on ew1r-aggr-04 via EC2 Instance Connect.

---

### OS-01 — Baseline Disk Usage

**Command:**
```bash
df -h /
```

**Output:**
```
Filesystem      Size  Used Avail Use% Mounted on
/dev/root        78G   60G   18G  78% /
```

**Finding:** Disk is 78% full. 60 GB used, 18 GB free on a 78 GB root volume.

---

### OS-02 — Top Level Folder Sizes

**Command:**
```bash
du -sh /* 2>/dev/null | sort -rh | head -20
```

**Output:**
```
51G     /var
5.7G    /opt
3.0G    /usr
2.5G    /snap
219M    /boot
202M    /mnt
125M    /tmp
6.2M    /etc
1.3M    /run
116K    /home
104K    /root
16K     /lost+found
4.0K    /srv
4.0K    /singlestoredb-server8.5.18-a22abb5ba4_8.5.18_amd64.deb
4.0K    /media
```

**Finding:** `/var` is consuming 51 GB — dominant folder. Drill down required.

---

### OS-03 — /var Breakdown

**Command:**
```bash
du -sh /var/* 2>/dev/null | sort -rh
```

**Output:**
```
44G     /var/lib
4.2G    /var/log
3.1G    /var/swapfile
221M    /var/cache
2.3M    /var/backups
112K    /var/snap
32K     /var/tmp
16K     /var/spool
4.0K    /var/opt
4.0K    /var/mail
4.0K    /var/local
4.0K    /var/crash
0       /var/run
0       /var/lock
```

**Finding:** `/var/lib` = 44 GB (SingleStore data). `/var/log` = 4.2 GB (bloated logs).

---

### OS-04 — /var/lib Breakdown

**Command:**
```bash
du -sh /var/lib/* 2>/dev/null | sort -rh | head -20
```

**Output:**
```
42G     /var/lib/memsql
1.1G    /var/lib/snapd
308M    /var/lib/apt
108M    /var/lib/clamav
92M     /var/lib/amazon
47M     /var/lib/dpkg
5.7M    /var/lib/plocate
3.3M    /var/lib/command-not-found
704K    /var/lib/usbutils
624K    /var/lib/systemd
224K    /var/lib/cloud
156K    /var/lib/ucf
80K     /var/lib/nfs
36K     /var/lib/polkit-1
36K     /var/lib/PackageKit
28K     /var/lib/pam
24K     /var/lib/emacsen-common
20K     /var/lib/update-notifier
16K     /var/lib/ubuntu-advantage
16K     /var/lib/grub
```

**Finding:** `/var/lib/memsql` = 42 GB. `/var/lib/clamav` = 108 MB — ClamAV running on a database node.

---

### OS-05 — /var/log Breakdown

**Command:**
```bash
du -sh /var/log/* 2>/dev/null | sort -rh | head -20
```

**Output:**
```
3.8G    /var/log/journal
238M    /var/log/amazon
127M    /var/log/clamav
23M     /var/log/auth.log.1
9.3M    /var/log/sysstat
8.1M    /var/log/auth.log
4.9M    /var/log/aws
4.7M    /var/log/syslog.1
4.4M    /var/log/wtmp
1.8M    /var/log/syslog
1.3M    /var/log/auth.log.4.gz
1.3M    /var/log/auth.log.3.gz
1.3M    /var/log/auth.log.2.gz
756K    /var/log/cloud-init.log
424K    /var/log/syslog.4.gz
404K    /var/log/syslog.3.gz
404K    /var/log/syslog.2.gz
388K    /var/log/dmesg
360K    /var/log/zabbix
232K    /var/log/unattended-upgrades
```

**Finding:** `/var/log/journal` = 3.8 GB — no size cap configured. Safe to clean.

---

### OS-06 — Journal Log Size Confirmation

**Command:**
```bash
journalctl --disk-usage
```

**Output:**
```
Archived and active journals take up 3.7G in the file system.
```

**Finding:** Confirms 3.7 GB in journal logs. No size limit set.

---

### OS-07 — SingleStore Data Directory

**Command:**
```bash
du -sh /var/lib/memsql/* 2>/dev/null | sort -rh | head -20
```

**Output:**
```
42G     /var/lib/memsql/11dbd517-1c12-42f7-87f1-ac38eb9a2ad4
4.0K    /var/lib/memsql/nodes.hcl
0       /var/lib/memsql/nodes.hcl.lock
```

**Finding:** All 42 GB is in one node directory — the SingleStore node instance folder.

---

### OS-08 — SingleStore Node Directory Breakdown

**Command:**
```bash
du -sh /var/lib/memsql/11dbd517-1c12-42f7-87f1-ac38eb9a2ad4/* 2>/dev/null | sort -rh | head -20
```

**Output:**
```
42G     /var/lib/memsql/11dbd517-1c12-42f7-87f1-ac38eb9a2ad4/data
54M     /var/lib/memsql/11dbd517-1c12-42f7-87f1-ac38eb9a2ad4/plancache
2.9M    /var/lib/memsql/11dbd517-1c12-42f7-87f1-ac38eb9a2ad4/tracelogs
4.0K    /var/lib/memsql/11dbd517-1c12-42f7-87f1-ac38eb9a2ad4/memsql.cnf
4.0K    /var/lib/memsql/11dbd517-1c12-42f7-87f1-ac38eb9a2ad4/auditlogs
```

**Finding:** All 42 GB is in the `/data` subdirectory. Drill down required.

---

### OS-09 — Snapshot Directory Full Listing

**Command:**
```bash
ls -lh /var/lib/memsql/11dbd517-1c12-42f7-87f1-ac38eb9a2ad4/data/snapshots/
```

**Output:**
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

**Finding:** 14.2 GB of orphaned snapshots from Aug 2025 confirmed. UDM1_Kurtosys snapshots (6.2 GB + 8.0 GB) are the largest. Active UDM__ snapshots (12 GB x2) must be retained.

---

### OS-10 — Large Files Scan

**Command:**
```bash
sudo find /var/ -type f -size +500M -exec ls -lh {} \;
```

**Output:**
```
-rw------- 1 root   root   3.1G Jun 19  2024 /var/swapfile
-rw------- 1 memsql memsql 6.2G Aug  6  2025 /var/lib/memsql/.../UDM1_Kurtosys_snapshot_v1_0_176143646078
-rw------- 1 memsql memsql 8.0G Aug 25  2025 /var/lib/memsql/.../UDM1_Kurtosys_snapshot_v1_0_176144118380
-rw------- 1 memsql memsql  12G Jul 28 09:33 /var/lib/memsql/.../UDM___snapshot_v1_0_176155093643
-rw------- 1 memsql memsql  12G Jul 24 10:29 /var/lib/memsql/.../UDM___snapshot_v1_0_176154955667
```

**Finding:** Only 5 files over 500 MB on the entire server. Confirms the snapshot files are the dominant space consumers.

---

### OS-11 — Open File Handle Check

**Command:**
```bash
lsof +L1 /var
```

**Output (relevant entries):**
```
COMMAND     PID        USER   FD   TYPE DEVICE SIZE/OFF NLINK NODE NAME
networkd-   533        root  txt    REG  259,1  5937768     0 12474 /usr/bin/python3.10 (deleted)
systemd-l   566        root  txt    REG  259,1   264712     0 29589 /usr/lib/systemd/systemd-logind (deleted)
ruby        821        root  txt    REG  259,1    14488     0  4178 /usr/bin/ruby3.0 (deleted)
sshd     103187        root  txt    REG  259,1   921288     0  9820 /usr/sbin/sshd (deleted)
zabbix_ag 1908656    zabbix    1w   REG  259,1      997     0 518378 /var/log/zabbix/zabbix_agentd.log.1 (deleted)
```

**Finding:** No SingleStore or memsql processes are holding open handles to deleted files. All deleted entries are standard OS binaries updated via package manager. Deleting the orphaned snapshot files will immediately release the full 14.2 GB to the OS.

---

### OS-12 — Kernel Disk Pressure Check

**Command:**
```bash
dmesg -T | grep -iE 'disk|space|memsql|singlestore' | tail -n 10
```

**Output:**
```
[Wed Jun 10 06:33:09 2026] systemd[1]: systemd 249.11-0ubuntu3.21 running in system mode
(+PAM +AUDIT +SELINUX +APPARMOR +IMA +SMACK +SECCOMP ...)
```

**Finding:** Only one entry — a systemd startup message from the last reboot on Jun 10 2026. No kernel disk pressure warnings, no OOM events, no SingleStore disk errors. The node is degraded but has not yet hit a critical failure state.

---

## Part 2 — Database Level Evidence

All queries run via MySQL client connected to Master Aggregator (ew1r-aggr-03.rel.kurtosys-internal.net:3306).

---

### DB-01 — Cluster Node Health and Disk

**Query:**
```sql
SELECT * FROM information_schema.MV_NODES;
```

**Output:**
```
ID | IP_ADDR                                  | PORT | TYPE | STATE  | NUM_CPUS | MAX_MEMORY_MB | MEMORY_USED_MB | TOTAL_DATA_DISK_MB | AVAILABLE_DATA_DISK_MB | VERSION
---+------------------------------------------+------+------+--------+----------+---------------+----------------+--------------------+------------------------+--------
23 | ew1r-aggr-03.rel.kurtosys-internal.net   | 3306 | MA   | online |        8 |         28251 |          21769 |              99053 |                  44317 | 8.5.18
 6 | ew1r-leaf-08.rel.kurtosys-internal.net   | 3306 | LEAF | online |        8 |         56648 |          32503 |             317387 |                 182018 | 8.5.18
 5 | ew1r-leaf-07.rel.kurtosys-internal.net   | 3306 | LEAF | online |        8 |         56648 |          31620 |             317387 |                 185966 | 8.5.18
 4 | ew1r-leaf-06.rel.kurtosys-internal.net   | 3306 | LEAF | online |        8 |         56648 |          32526 |             317387 |                 186952 | 8.5.18
 3 | ew1r-leaf-05.rel.kurtosys-internal.net   | 3306 | LEAF | online |        8 |         56648 |          31903 |             317387 |                 184579 | 8.5.18
 2 | ew1r-aggr-04.rel.kurtosys-internal.net   | 3306 | CA   | online |        8 |         30400 |          20898 |              79205 |                  18045 | 8.5.18
```

**Finding:** All 6 nodes online. aggr-04 (Node 2) has only 79,205 MB (78 GB) total disk vs 99–317 GB on all other nodes. Available disk on aggr-04 = 18,045 MB (18 GB) = 22% free.

---

### DB-02 — Disk Usage Per Node Per Directory

**Query:**
```sql
SELECT NODE_ID, MEMSQL_DIR,
       ROUND(DISK_USED_B / 1024 / 1024 / 1024, 2) AS disk_used_gb
FROM information_schema.MV_DISK_USAGE
ORDER BY DISK_USED_B DESC;
```

**Output:**
```
NODE_ID | MEMSQL_DIR | disk_used_gb
--------+------------+-------------
      6 | user_data  |       111.12
      3 | user_data  |       108.63
      5 | user_data  |       107.46
      4 | user_data  |       106.42
      2 | user_data  |        41.69
     23 | user_data  |        33.49
      3 | plancache  |         1.22
      5 | plancache  |         1.22
      4 | plancache  |         1.22
      6 | plancache  |         1.22
     23 | plancache  |         0.66
     23 | tracelogs  |         0.50
      6 | tracelogs  |         0.19
      3 | tracelogs  |         0.19
      5 | tracelogs  |         0.19
      4 | tracelogs  |         0.19
      2 | plancache  |         0.05
```

**Finding:** Leaf nodes each carry 106–111 GB of user data. aggr-04 carries 41.69 GB. This data includes both UDM__ and UDM1_Kurtosys — see DB-05.

---

### DB-03 — All Databases and Sizes

**Query:**
```sql
SELECT table_schema,
       COUNT(*) AS tables,
       ROUND(SUM(data_length + index_length) / 1024 / 1024 / 1024, 2) AS size_gb
FROM information_schema.tables
GROUP BY table_schema
ORDER BY size_gb DESC;
```

**Output:**
```
table_schema                     | tables | size_gb
---------------------------------+--------+--------
DBAdmin_24062026_standard        |     18 |    0.00
UDM__                            |    249 |    0.00
DBAdmin_24062026_standard_direct |     18 |    0.00
DBAdmin_24062026_Instant_direct  |     18 |    0.00
SearchTest                       |      3 |    0.00
DBAdmin                          |     18 |    0.00
UDM1_Kurtosys                    |    215 |    0.00
information_schema               |    193 |    0.00
DBAdmin_24062026_Instant         |     18 |    0.00
```

**Finding:** All databases show 0.00 GB on the aggregator — expected, as actual row data lives on leaf nodes. Two UDM databases exist simultaneously: `UDM__` (249 tables) and `UDM1_Kurtosys` (215 tables).

---

### DB-04 — UDM1_Kurtosys Row Counts

**Query:**
```sql
SELECT table_name, table_rows
FROM information_schema.tables
WHERE table_schema = 'UDM1_Kurtosys'
ORDER BY table_rows DESC
LIMIT 20;
```

**Output:**
```
table_name                | table_rows
--------------------------+-----------
ApplicationTemplateAsset  |      51230
RolePermission            |      18640
FundList                  |      17437
Sequence                  |      10000
UserRole                  |       7855
Properties                |       7676
ApplicationAsset          |       6213
ApplicationConfiguration  |       5812
Snapshot                  |       4377
ApplicationUpgrade        |       4000
User                      |       3880
Strategies                |       3849
ApplicationStyle          |       3217
ContactGroupRelationship  |       3208
ApplicationTemplateSchema |       2925
Application               |       2772
StatisticProperties       |       1952
AllocationProperties      |       1845
WordpressMultiDomains     |       1115
Cultures                  |        899
```

**Finding:** UDM1_Kurtosys has real data — 51,230 rows in ApplicationTemplateAsset alone. Cannot be dropped without application team confirmation.

---

### DB-05 — Schema Comparison Between UDM__ and UDM1_Kurtosys

**Query:**
```sql
SELECT k.table_name AS in_UDM1_Kurtosys, u.table_name AS in_UDM__
FROM information_schema.tables k
LEFT JOIN information_schema.tables u
    ON k.table_name = u.table_name AND u.table_schema = 'UDM__'
WHERE k.table_schema = 'UDM1_Kurtosys'
AND u.table_name IS NULL
LIMIT 20;
```

**Output:**
```
in_UDM1_Kurtosys | in_UDM__
-----------------+---------
(0 rows)
```

**Finding:** Zero rows returned. Every table in UDM1_Kurtosys exists in UDM__. The schemas are identical — UDM1_Kurtosys is a subset of UDM__. UDM__ has 34 additional tables making it the newer, expanded version.

---

### DB-06 — Database Creation and Last Modified Dates

**Query:**
```sql
SELECT table_schema,
       MIN(create_time) AS first_created,
       MAX(create_time) AS last_created
FROM information_schema.tables
WHERE table_schema IN ('UDM1_Kurtosys', 'UDM__')
GROUP BY table_schema;
```

**Output:**
```
table_schema  | first_created       | last_created
--------------+---------------------+---------------------
UDM__         | 2025-08-06 04:39:06 | 2026-06-26 15:32:53
UDM1_Kurtosys | 2025-08-06 07:09:14 | 2025-08-06 09:56:08
```

**Finding:** UDM__ was created first (04:39) and last modified June 2026 — it is the active database. UDM1_Kurtosys was created 3 hours later (07:09) and never modified after Aug 6 2025 — it is frozen. This confirms UDM1_Kurtosys is a migration artefact.

---

### DB-07 — UDM__ Table Creation Dates (Confirms Active Use)

**Query:**
```sql
SELECT table_name, create_time
FROM information_schema.tables
WHERE table_schema = 'UDM__'
ORDER BY create_time DESC
LIMIT 10;
```

**Purpose:** Confirms UDM__ has had tables added as recently as June 2026, proving it is the current active database.

---

## Part 3 — Evidence Summary

| Evidence ID | Type | What It Proves |
|---|---|---|
| OS-01 | OS | Disk at 78% — alert was genuine |
| OS-02 | OS | /var is the dominant folder at 51 GB |
| OS-03 | OS | /var/lib (44 GB) and /var/log (4.2 GB) are the two problems |
| OS-04 | OS | /var/lib/memsql = 42 GB, ClamAV present on database node |
| OS-05 | OS | /var/log/journal = 3.8 GB, no size cap |
| OS-06 | OS | Journal confirmed at 3.7 GB |
| OS-07 | OS | All 42 GB in one SingleStore node directory |
| OS-08 | OS | All 42 GB in /data subdirectory — snapshots |
| OS-09 | OS | Full snapshot inventory — 14.2 GB orphaned files identified with exact dates |
| OS-10 | OS | Only 5 files over 500 MB on entire server — confirms snapshots are the problem |
| OS-11 | OS | No open file handles on deleted files — deletion will immediately free space |
| OS-12 | OS | No kernel disk errors — node degraded but not critical |
| DB-01 | DB | All 6 nodes online, aggr-04 is the only undersized node |
| DB-02 | DB | Leaf nodes each carry 106–111 GB of user data |
| DB-03 | DB | Two UDM databases exist simultaneously |
| DB-04 | DB | UDM1_Kurtosys has real data — 51k+ rows |
| DB-05 | DB | UDM1_Kurtosys and UDM__ have identical schemas |
| DB-06 | DB | UDM1_Kurtosys frozen since Aug 2025, UDM__ active to Jun 2026 |
