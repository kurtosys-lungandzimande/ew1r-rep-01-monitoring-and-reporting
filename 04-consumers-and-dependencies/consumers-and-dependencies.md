# Consumers and Dependencies — EW1R-REP-01

> Status: IN PROGRESS — team identification pending. Items marked "unknown" require escalation.

---

## Alert Mechanisms

### SQL Server Alerts
All 17 SQL Server alerts (severity 19-25, IO errors 823-825, AG errors) are defined but have `has_notification = 0` — **no operator is notified when these fire. They are silent.**

### SQL Agent Job Alerts
One operator is configured:

| Operator | Email | Pager |
|---|---|---|
| dba@kurtosys.com | dba@kurtosys.com | None |

| Job Alert Category | Alert Target | Channel |
|---|---|---|
| CHECKDB failures | dba@kurtosys.com | Email |
| Backup failures (FULL/DIFF/LOG) | dba@kurtosys.com | Email |
| Low disk space | dba@kurtosys.com | Email |
| Server restart required | dba@kurtosys.com | Email |
| Errorlog size alerts | dba@kurtosys.com | Email |
| VLF count report | dba@kurtosys.com | Email |
| Memory pressure | dba@kurtosys.com | Email |
| SSIS long-running packages | Slack | Slack (channel unknown — needs confirmation) |
| Most VCC monitoring jobs | None | No alert configured — data written to DB tables only |

> Critical gap: SQL Server severity alerts are all silent. If the server hits a fatal error (severity 19-25) or IO failure, no one is automatically notified.

---

## Known Data Consumers

| Data | Likely Consumer | Confidence | Notes |
|---|---|---|---|
| KAPP API query logs (DBA_VCC_AWS) | KAPP engineering / platform team | High | 563M rows actively collected every 15 min — someone depends on this |
| Encore IIS logs / BNY IIS logs (DBA_VCC) | Encore team / BNY integration team | Medium | Hourly collection — BNY named explicitly in job step |
| Cost entity counts (DBA_VCC_COST) | Finance / platform management | Medium | FULL recovery model suggests this data is considered critical |
| Jira sprint data (DBA_VCC_ATLASSIAN) | Engineering management / delivery team | Medium | Month-end Jira sprint pull — likely used for reporting |
| MySQL / DXM client sizes (DBA_VCC_MYSQL) | DXM platform team | Medium | Active daily collection of DXM and WPv2 client data |
| Grafana dashboards | Unknown | Unknown | Pending Grafana access — needs team identification |
| ObjectIDValidationReport | Unknown | Low | Job disabled — dba@kurtosys.com was recipient |
| Production Logon Report | Unknown | Low | Job disabled |

---

## Infrastructure Dependencies

### Service Accounts
| Service | Account | Notes |
|---|---|---|
| SQL Server Engine | SHNONPRD\sqlsrv | Domain service account on SHNONPRD domain |
| SQL Server Agent | SHNONPRD\sqlagent | Domain service account on SHNONPRD domain |
| SQL Server Launchpad | NT Service\MSSQLLaunchpad | Built-in service account |
| Linked server credentials (ODBC/MSDASQL) | Unknown | Used for all SingleStore, MySQL, Zabbix, PMM connections — check vault |
| Linked server credentials (SQLNCLI) | Unknown | Used for SQL Server linked servers — likely Windows auth or SQL auth |
| AWS API access (Python calls) | Unknown | SP_AUDIT_AWS_PY_CALL_DETAILED makes Python API calls — IAM role or key stored somewhere on server |

> Do not document actual credentials here. Reference vault path only once identified.

### Backup Storage
| Type | Location | Notes |
|---|---|---|
| Local backup staging | D:\SQL\Backup\ | Intermediate location before S3 copy |
| S3 backup destination | Unknown — ARN referenced in job | Needs S3 bucket name confirmed |
| EW1P-OCT RDS backup | S3 via ARN | Separate job backing up RDS instance directly to S3 |

### DNS
| Name | Resolves To | Notes |
|---|---|---|
| EW1R-REP-01 | 10.72.8.216 | Confirmed IP from netstat |
| Grafana URL | https://10.72.8.216 or https://ew1r-rep-01 | Grafana running on port 443 (HTTPS) — browser access pending confirmation |

### Additional Services Confirmed Running
| Service | Port | PID | Notes |
|---|---|---|---|
| Grafana | 443 | 3844 | Running as grafana.exe — HTTPS |
| Zabbix Agent | 10050 | 5700 | This server reports into Zabbix |
| SQL Server | 1433 | 3096 | Standard SQL Server port |
| RDP | 3389 | 360 | Remote desktop enabled |
| WinRM | 5985 | 4 | Windows Remote Management |

### Firewall Rules
| Direction | Source | Destination | Port | Purpose |
|---|---|---|---|---|
| Outbound | EW1R-REP-01 | SingleStore nodes (97) | Unknown | ODBC connections to MemSQL clusters |
| Outbound | EW1R-REP-01 | MySQL/DXM/WPv2 nodes | 3306 | MySQL monitoring |
| Outbound | EW1R-REP-01 | EW2P-MSSQL-01/02 | 1433 | SQL Server monitoring |
| Outbound | EW1R-REP-01 | AWS APIs | 443 | Python API calls for AWS data collection |
| Outbound | EW1R-REP-01 | Jira | 443 | Jira sprint data collection |
| Outbound | EW1R-REP-01 | S3 | 443 | Backup uploads |
| Inbound | Grafana clients | EW1R-REP-01 | Unknown (3000?) | Grafana dashboard access |
| Inbound | DBA team | EW1R-REP-01 | 1433 | SQL Server management |

> Firewall rules need confirmation from network/infrastructure team.

### Runbooks
| Item | Location | Notes |
|---|---|---|
| VCC framework runbook | Unknown | No runbook found — original author left the company |
| Backup restore procedure | Unknown | Needs to be created if not exists |
| Grafana admin procedure | Unknown | Needs to be created if not exists |

---

## Open Items for Consumer Identification

| # | Item | Who to Ask |
|---|---|---|
| 1 | Who owns and reads the Grafana dashboards on this server? | Engineering leads / ops team |
| 2 | Who receives the Slack alerts from SSISStatusCheck? | DBA team / ops team |
| 3 | Is DBA_VCC_COST data used for client billing? | Finance / platform management |
| 4 | Who is the BNY contact for IIS log collection? | Account management / BNY integration team |
| 5 | What IAM role/key does the Python AWS API caller use? | DevOps / cloud team |
| 6 | What S3 bucket do backups go to? | DevOps / cloud team |
| 7 | Are any dashboards or reports client-facing? | Platform / account management |
