# Firewall Rules — EW1R-REP-01
**Ticket:** TECH-3480 — Q18
**Date captured:** 2026-08-11
**Source:** netstat -ano + netsh advfirewall on EW1R-REP-01 via SSM Session Manager

> Note: Windows Firewall rules documented here are the host-level rules only.
> AWS Security Group rules are the outer boundary — must be confirmed with DevOps / cloud team separately.

---

## Inbound — Listening Ports (confirmed from netstat)

| Port | Protocol | PID | Service | Purpose |
|---|---|---|---|---|
| 443 | TCP | 3844 | grafana.exe | Grafana — dashboard access for DBA team |
| 1433 | TCP | 3096 | sqlservr.exe | SQL Server — SSMS connections, linked server queries from EW2P-MSSQL-01/02 |
| 3389 | TCP | 360 | svchost.exe | RDP — remote management |
| 5985 | TCP | 4 | System | WinRM — Windows Remote Management |
| 10050 | TCP | 5700 | zabbix_agentd.exe | Zabbix Agent — Zabbix server polls this port |
| 135 | TCP | 920 | svchost.exe | RPC Endpoint Mapper — Windows standard |
| 445 | TCP | 4 | System | SMB — Windows file sharing |
| 139 | TCP | 4 | System | NetBIOS Session — Windows standard |
| 1434 | TCP | 3096 | sqlservr.exe | SQL Server Browser — loopback only |
| 47001 | TCP | 4 | System | WinRM — Windows standard |
| 59563 | TCP | 9148 | Unknown | Purpose unknown — not previously documented |

---

## Inbound — Windows Firewall Rules (relevant rules only)

| Rule Name | Port | Protocol | Direction | Purpose |
|---|---|---|---|---|
| World Wide Web Services (HTTPS Traffic-In) | 443 | TCP | Inbound | Grafana HTTPS access |
| World Wide Web Services (HTTP Traffic-In) | 80 | TCP | Inbound | HTTP (redirects to HTTPS) |
| Remote Desktop - User Mode (TCP-In) | 3389 | TCP | Inbound | RDP access |
| Remote Desktop - User Mode (UDP-In) | 3389 | UDP | Inbound | RDP access |
| Windows Remote Management (HTTP-In) | 5985 | TCP | Inbound | WinRM |
| Zabbix Agent listen port | 10050 | TCP | Inbound | Zabbix agent — custom rule |
| File and Printer Sharing (SMB-In) | 445 | TCP | Inbound | SMB |
| Windows Management Instrumentation (DCOM-In) | 135 | TCP | Inbound | WMI / RPC |
| Google Chrome (mDNS-In) | — | UDP | Inbound | Chrome mDNS — not relevant to server function |
| Block network access for AppContainer-00 to 20 (SQL Server) | — | — | — | SQL Server AppContainer isolation — standard SQL Server 2019 rules |

---

## Outbound — Key Rules

| Direction | Destination | Port | Purpose |
|---|---|---|---|
| Outbound | SingleStore nodes (46 reachable) | 3306 | ODBC linked server queries |
| Outbound | MySQL / DXM nodes | 3306 | MySQL monitoring jobs |
| Outbound | EW2P-MSSQL-01/02 | 1433 | SQL Server linked server queries |
| Outbound | AWS APIs (CloudWatch, S3, Cost Explorer) | 443 | Python API calls — DBA_VCC_AWS jobs |
| Outbound | Jira | 443 | Sprint data collection — DBA_VCC_JIRA_MONTHEND_CHECKS |
| Outbound | S3 (ksys-ew1r-db-backups, ksys-ew1p-oct-dbbackup) | 443 | Backup uploads via AWS CLI |
| Outbound | DNS | 53 | DNS resolution — Core Networking rule |

> Windows Firewall outbound rules are mostly default Windows rules — no custom application-specific outbound rules found. Outbound traffic is controlled at the AWS Security Group level.

---

## Notes

- No custom inbound rules for SQL Server port 1433 found in Windows Firewall — SQL Server access is controlled at the AWS Security Group level
- Zabbix Agent listen port (10050) has a dedicated custom Windows Firewall rule — confirms Zabbix monitoring is intentionally configured
- Port 59563 (PID 9148) is listening on loopback only — low risk but purpose still unknown
- AWS Security Group rules for this instance (10.72.8.216, eu-west-1) must be confirmed with DevOps to complete the full firewall picture

---

## Outstanding — AWS Security Group Rules

The Windows Firewall rules above are the host-level boundary. The AWS Security Group attached to this EC2 instance is the outer boundary and controls what traffic can reach the server from outside the VPC.

**Action required:** Request Security Group inbound/outbound rules for EW1R-REP-01 (10.72.8.216) from DevOps / cloud team.

Expected inbound rules to confirm:
- Port 443 — Grafana access (from internal network / VPN)
- Port 1433 — SQL Server (from DBA team IPs / bastion)
- Port 3389 — RDP (from bastion / DBA team IPs)
- Port 10050 — Zabbix agent (from Zabbix server IP)

Expected outbound rules to confirm:
- Port 3306 — to SingleStore / MySQL nodes
- Port 1433 — to EW2P-MSSQL-01/02
- Port 443 — to AWS APIs and S3
