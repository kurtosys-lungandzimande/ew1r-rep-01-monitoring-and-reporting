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

### DBA_VCC_COST — Cost Tracking Database

> This is one of the most important databases on this server to understand before any decommission decision.

**What it is:**
DBA_VCC_COST is a database that acts like a usage meter for every KAPP client. It was built by Donovan van Graan (the original engineer who left the company). Every time the collection job runs, it connects to each KAPP production environment, counts how many entities each client has, and saves that count with a timestamp. Over time this builds a full history of how each client's usage has grown.

**What it tracks — 9 entity types per client:**

| Entity Type | What It Counts | Table It Writes To |
|---|---|---|
| Allocations | How many allocations each client has (active + backup) | INFO_KAPP_Client_Allocations_Counts |
| Disclaimers & Commentaries | How many disclaimers and commentaries per client | INFO_KAPP_Client_Disclaimers_Commentaries_Counts |
| Documents | How many documents per client | INFO_KAPP_Client_Document_Counts |
| Entities | General entity count per client | INFO_KAPP_Client_Entities_Counts |
| Historical Datasets | How many historical datasets per client | INFO_KAPP_Client_HistoricalDatasets_Counts |
| Snapshots | How many snapshots per client | INFO_KAPP_Client_Snapshots_Counts |
| Statistics | Statistics count per client | INFO_KAPP_Client_Statstics_Counts |
| Time Series | Time series data count per client | INFO_KAPP_Client_TimeSeries_Counts |
| Users | How many users per client | INFO_KAPP_Client_Users_Counts |

**How the collection works — step by step:**
1. The SQL Agent job `DBA_VCC_COST_Entity_Count_Collection` runs on schedule SCHED1
2. It calls 9 stored procedures, one per entity type
3. Each stored procedure connects to the SingleStore Master Aggregator nodes via linked servers
4. It only connects to nodes that are currently online and responding (checked against DBA_VCC_MEMSQL ping stats within the last 40 minutes)
5. For each live node it runs a query directly against the KAPP production database (`UDM__` schema) to count entities per client
6. It counts both active records and backup records separately
7. The counts are saved into the INFO_KAPP_Client_* tables with a timestamp
8. Last confirmed successful run: **29 June 2026 at 08:00**

**Environments it collects from:**

| Environment Code | Region | Environment |
|---|---|---|
| EW1-D | EU West 1 | UK Development |
| EW1-R | EU West 1 | UK Release |
| EW2-P | EU West 2 | UK Production |
| UE1-P | US East 1 | US Production |
| EC1-P | EU Central 1 | EU Production |

**The reporting layer — month-end reports:**
On top of the collection tables there are 19 stored procedures named `REP_MONTHEND_*`. These are the reporting procedures that someone calls every month end to generate client reports. There are two versions of each report:
- A **summary report** across all clients (e.g. `REP_MONTHEND_CLIENT_ALLOCATIONS_REPORT`) — shows all clients side by side
- A **per-client report** (e.g. `REP_MONTHEND_CLIENT_ALLOCATIONS_CLIENT_REPORT`) — shows detail for one specific client

| Report Procedure | What It Produces |
|---|---|
| REP_MONTHEND_CLIENT_ALLOCATIONS_REPORT | All clients — allocation counts by environment and status |
| REP_MONTHEND_CLIENT_ALLOCATIONS_CLIENT_REPORT | Single client — allocation counts |
| REP_MONTHEND_CLIENT_DISCLAIMERS_COMMENTARIES_REPORT | All clients — disclaimer and commentary counts |
| REP_MONTHEND_CLIENT_DOCUMENTS_REPORT | All clients — document counts |
| REP_MONTHEND_CLIENT_ENTITY_REPORT | All clients — general entity counts |
| REP_MONTHEND_CLIENT_HISTORICALDATASETS_REPORT | All clients — historical dataset counts |
| REP_MONTHEND_CLIENT_SNAPSHOTS_REPORT | All clients — snapshot counts |
| REP_MONTHEND_CLIENT_STATSTICS_REPORT | All clients — statistics counts |
| REP_MONTHEND_CLIENT_TIMESERIES_REPORT | All clients — time series counts |
| REP_MONTHEND_CLIENT_USER_REPORT | All clients — user counts |
| REP_MONTHEND_CLIENT_USER_COUNTS_REPORT | All clients — user count summary |
| REP_MONTHEND_CLIENT_TOP5_ALLOCATIONS_REPORT | Top 5 clients by allocation count |
| REP_MONTHEND_TOP5_CLIENTS_DATA_FOOTPRINT_REPORT | Top 5 clients by total data footprint |

**Why it matters — business impact:**
In a SaaS business like Kurtosys, client usage counts like these are almost always tied to one of three things:
- **Billing** — clients are charged based on how many entities or documents they have. If this data disappears, the business may not be able to accurately invoice clients.
- **Capacity planning** — knowing which clients are growing helps the platform team plan infrastructure ahead of time.
- **SLA reporting** — proving to clients exactly what was delivered and when.

The fact that there are both summary and per-client versions of every report strongly suggests these are sent to clients or used in client-facing conversations.

**Evidence that this data is considered critical:**
- The database is on **FULL recovery model** — every other monitoring database on this server is SIMPLE. Someone deliberately set this one to FULL, meaning transaction log backups run against it. This is only done when you cannot afford to lose even a single transaction. That is not a default setting — it was a deliberate decision by the original engineer.
- The collection job is **enabled and actively running** — last successful run was 29 June 2026.
- It collects from **UK, EU, and US production environments** — this is live production data.
- The reporting procedures have been maintained and updated as recently as **January 2023** — someone was actively working on these reports after the original engineer built them.

**Additional tables in this database:**
- `LU_KAPP_ClientList`, `LU_DXM_ClientList`, `LU_Encore_ClientList`, `LU_IP_ClientList`, `LU_WPv2_ClientList` — lookup tables listing all clients per product. These are reference tables used by the reporting procedures.
- `INFO_AWS_Account_Entity_Cost`, `INFO_AWS_DE_Entity_Cost` — AWS cost data per entity, last modified November 2024 — still being updated.
- `MON_AWS_DE_Entity_Cost` — monitoring table for AWS entity costs, created August 2024.
- `INFO_DBE_JIRA_VALUES_Detail` — Jira values detail, linked to the database engineering sprint reporting.

**What we do not know yet — confirm Monday:**
- Who calls the `REP_MONTHEND_*` procedures every month? Is it automated or does someone run them manually?
- Do the reports get emailed to clients or used internally?
- Is there a Grafana dashboard reading from this database? The `Database Engineering Costs` dashboard in Grafana was last updated October 2024 — it likely reads from here.
- Is there another system already capturing this same data that we are not aware of?

**Action required Monday:**
Find the person who owns client billing or usage reporting — likely in finance, account management, or platform management — and ask: do you use data from this server for invoicing or client reporting? If yes, this database cannot be decommissioned until a confirmed replacement is in place.

---

### Other Known Data Consumers

| Data | Likely Consumer | Confidence | Notes |
|---|---|---|---|
| KAPP API query logs (DBA_VCC_AWS) | KAPP engineering / platform team | High | 563M rows actively collected every 15 min — Grafana KAPP dashboards confirmed reading this |
| Grafana dashboards (90 total) | tashvir.babulal, yogeshwar.phull, rayhaan.suleyman | Confirmed | 3 active admins as of June 2026 — actively using dashboards updated Oct 2025 |
| Encore IIS logs / BNY IIS logs (DBA_VCC) | Encore team / BNY integration team | Medium | Hourly collection — BNY named explicitly in job step |
| MySQL / DXM client sizes (DBA_VCC_MYSQL) | DXM platform team | Medium | Active daily collection of DXM and WPv2 client data |
| Jira sprint data (DBA_VCC_ATLASSIAN) | Engineering management / delivery team | Medium | Month-end Jira sprint pull — likely used for sprint reporting |
| Slack alerts (alerts-data-operations) | Unknown Slack channel members | Confirmed | KAPP client config and read query failure alerts routing to this channel |
| ObjectIDValidationReport | Unknown | Low | Job disabled — was emailing dba@kurtosys.com |
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
| Inbound | Grafana clients (browsers) | EW1R-REP-01 | 443 | Grafana dashboard access — confirmed HTTPS |
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
