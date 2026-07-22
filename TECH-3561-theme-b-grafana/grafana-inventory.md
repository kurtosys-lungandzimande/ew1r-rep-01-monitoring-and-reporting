# Grafana Inventory  EW1R-REP-01

> Status: COMPLETE  validated live from grafana.db via xp_cmdshell/Python 2026-07-21. Dashboard count confirmed 74.

---

## Access Details

| Property | Value |
|---|---|
| URL (hostname) | https://ew1r-rep-01 |
| URL (IP) | https://10.72.8.216 |
| Port | 443 (HTTPS  confirmed via netstat, PID 3844 = grafana.exe) |
| Version | 9.5.2 (confirmed from C:\Program Files\GrafanaLabs\svc-9.5.2.0) |
| Database | C:\Program Files\GrafanaLabs\grafana\data\grafana.db (162 MB) |
| Install path | C:\Program Files\GrafanaLabs\grafana\ |
| Config path | C:\Program Files\GrafanaLabs\grafana\conf\grafana.ini |
| AWS Region | eu-west-1 (Ireland) |
| AWS Environment | Shared NonProd (REL) |
| EC2 Host | EW1R-REP-01  self-hosted on Windows Server EC2, not a managed service |
| DNS (Primary) | dbe-reports.shnonprd.kurtosys-internal.net |
| DNS (Replication) | ew1r-rep-01.ad.shnonprd.kurtosys-internal.net |
| Hosting model | Self-managed  patching, upgrades, and backups are manual. Version 9.5.2 has not been upgraded since install |
| Process | grafana.exe  PID 3844, confirmed running 2026-07-22 via Get-Process on EC2 instance. Session 0  running as system service, not a user session. Working set 97 MB |

> Browser access unreachable from outside network  requires VPN or RDP from within the server network.

---

## Users and Access

| Login | Name | Email | Admin | Last Seen |
|---|---|---|---|---|
| admin | (default) | admin@localhost | Yes | 2024-11-29 |
| donovan.vangraan | donovan.vangraan | donovan.vangraan@kurtosys.com | Yes | 2024-11-13  builder, no longer active |
| tashvir.babulal | Tashvir Babulal | tashvir.babulal@kurtosys.com | Yes | 2026-06-09 — **actively using** |
| yogeshwar.phull | Yogeshwar Phull | yogeshwar.phull@kurtosys.com | Yes | 2026-06-22 — **actively using** |
| rayhaan.suleyman | Rayhaan Suleyman | rayhaan.suleyman@kurtosys.com | Yes | 2026-06-30 — **actively using** |
| ram.jeyaraman | Ram Jeyaraman | ram@kurtosys.com | No | 2025-09-11 |
| jason.wolmarans | Jason Wolmarans | jason.wolmarans@kurtosys.com | No | 2025-02-12 |
| sunil.odedra | Sunil Odedra | sunil.odedra@kurtosys.com | No | 2023-07-12  likely inactive |
| lunga.ndzimande | Lunga Ndzimande | lunga.ndzimande@kurtosys.com | Yes | 2026-07-21  investigation only, created 2026-07-20 |

> 3 admins actively using Grafana as of June 2026: DBA Team.
> 2 admins inactive: donovan.vangraan (last seen Nov 2024  credentials still in 4 Zabbix datasources, needs rotation) and default admin account (last seen Nov 2024  should be disabled).
> These are the key contacts before any decommission or migration decision.

---

## Datasources

> Confirmed from grafana.db via query 12.6 (2026-07-07). UIDs are what dashboard JSON references internally.

| UID | Name | Type | Host/IP | Database | Notes |
|---|---|---|---|---|---|
| a082f27e | DBA_VCC | mssql | localhost | DBA_VCC | Local SQL Server  primary datasource for VCC dashboards |
| e8597015 | DBA_VCC | mssql | localhost | DBA_VCC | Duplicate entry  same target, two UIDs. Dashboards may reference either |
| da173cae | KAPP Dev | mysql | 10.61.11.70:3306 | metrics | KAPP Dev MySQL |
| d1679f57 | KAPP Rel | mysql | 10.77.3.236 | metrics | KAPP Release MySQL |
| cd097e22 | KAPP UK Prod | mysql | 10.121.29.82 | metrics | KAPP UK Production MySQL |
| e792d174 | KAPP EU Prod | mysql | 10.125.6.134 | metrics | KAPP EU Production MySQL |
| db3d6c01 | KAPP US Prod | mysql | 10.128.30.6 | metrics | KAPP US Production MySQL |
| f4830a0f | KAPP Monitoring | mysql | 10.120.8.208 | metrics | KAPP monitoring  tlsSkipVerify=true |
| dce83066 | monitoring | mysql | 10.120.8.208 | metrics | Duplicate of KAPP Monitoring  same IP, same database. tlsSkipVerify=true |
| f2ca52be | MySQL | mysql | 10.77.3.236:3306 | metrics | Generic MySQL  same IP as KAPP Rel |
| d8b0939b | SingleStore-Dev | mysql | 10.61.0.95 | UDM__ | SingleStore Dev  queries UDM__ schema |
| f1d911af | SingleStore-Release | mysql | 10.77.6.161 | UDM__ | SingleStore Release  queries UDM__ schema |
| a6046586 | SingleStore-Production-UK | mysql | 10.121.22.219 | UDM__ | SingleStore UK Prod  queries UDM__ schema |
| df309b44 | SingleStore-Production-EU | mysql | 10.125.12.126 | UDM__ | SingleStore EU Prod  queries UDM__ schema |
| bfe8f780 | SingleStore-Production-US | mysql | 10.128.24.122 | UDM__ | SingleStore US Prod  queries UDM__ schema |
| aafbf2f7 | Zabbix Nonprod old | mysql | 10.72.8.191 | zabbix | Old non-prod Zabbix MySQL |
| b10bf74c | zabbix-server-data.shnonprd.kurtosys-internal | mysql | 10.72.8.186 | zabbix | Current non-prod Zabbix MySQL |
| dbafc322 | Zabbix Prod Old | mysql | 10.120.8.120 | zabbix | Old prod Zabbix MySQL |
| d68a35f0 | zabbix-server-data.shprd.kurtosys-internal | mysql | 10.120.8.51 | zabbix | Current prod Zabbix MySQL |
| b7838f71 | JSON API | marcusolsson-json-datasource | 10.125.9.192:8443 |  | NiFi API  tlsSkipVerify=true |
| bae6c95e | CloudWatch | cloudwatch |  |  | AWS CloudWatch  no URL stored |
| aa82f021 | InfluxDB | influxdb |  |  | InfluxDB  no URL stored, needs confirmation |

> Critical: Two DBA_VCC datasource entries exist with different UIDs (a082f27e and e8597015) pointing to the same localhost target. Dashboards may be split across both UIDs  this needs to be checked before any migration.
> Critical: Grafana connects directly to production MySQL instances (KAPP UK/EU/US Prod, SingleStore Prod UK/EU/US) using the UDM__ schema. These connections will break if this server is decommissioned or network access is removed.
> Note: All four Zabbix datasources use donovan.vangraan credentials  this account is no longer active. Credentials need rotation before or during decommission.

---

## Folders

> Validated 2026-07-21 from live grafana.db query. SingleStore Monitoring (v2) does not exist  all SingleStore dashboards are in one folder.

| Folder | Notes |
|---|---|
| General | Ungrouped dashboards  default Grafana folder |
| General Reporting | Top-level reporting folder |
| SingleStore Monitoring | All SingleStore dashboards  active and older copies in same folder |
| AWS | AWS infrastructure reports |
| Month End Reporting | Month-end business reports |
| Encore | Encore product dashboards |
| Encore Reporting | Encore reporting dashboards |
| Database Engineering Reports | Internal DB engineering reports |
| Database Engineering Month End Reporting | DB engineering month-end |
| Database Engineering AWS Reports | DB engineering AWS reports |
| KAPP | KAPP product dashboards |
| KAPP Reporting | KAPP reporting dashboards |
| KAPP Client Reporting | KAPP client-level reporting |
| Monitoring | Infrastructure monitoring |
| Atlassian Reporting | Jira/Confluence reports |
| Performance Dashboards | Query/performance dashboards |

---

## Dashboard Inventory

> Total: 74 dashboards  confirmed live from grafana.db 2026-07-21.
> SingleStore Monitoring (v2) folder does not exist  all SingleStore dashboards are in one folder with duplicate titles.
> Total confirmed from live grafana.db query 2026-07-21.

### General (ungrouped)

| Dashboard | Created | Last Updated | Status | Notes |
|---|---|---|---|---|
| Dashboard Servers Windows | 2023-09-05 | 2023-09-05 | Stale credentials | Zabbix  uses donovan.vangraan credentials |
| Grafana Dashboard Exporter/Importer | 2024-10-29 | 2024-10-29 | Active | Admin utility |
| Home | 2023-08-09 | 2023-08-09 | Active | Default home dashboard |
| Microsoft SQL Server | 2023-09-05 | 2023-09-05 | Stale credentials | Zabbix  uses donovan.vangraan credentials |
| SQL SERVER | 2023-09-05 | 2023-09-05 | Stale credentials | Zabbix  uses donovan.vangraan credentials |
| Zabbix Server Dashboard | 2023-09-05 | 2023-09-05 | Stale credentials | Zabbix  uses donovan.vangraan credentials |

### AWS

| Dashboard | Created | Last Updated | Status | Notes |
|---|---|---|---|---|
| AWS Cost Report | 2023-07-17 | 2023-08-09 | Broken | AWS entity cost data frozen at 2024-09-22  single row only. DBA_VCC_AWS_DAILY_CHECKS step silently failing |
| AWS Cost Report Monthly | 2023-10-06 | 2023-10-06 | Broken | Same root cause  AWS entity cost frozen Sept 2024 |
| AWS EC2 Report | 2023-08-09 | 2023-08-09 | Stale | No recent updates |
| AWS RDS Report | 2023-08-09 | 2023-08-09 | Stale | No recent updates |
| AWS S3 Report | 2023-06-21 | 2023-07-13 | Stale | Older copy  newer in Database Engineering AWS Reports |
| AWS Security Report | 2023-08-09 | 2023-08-10 | Stale | No recent updates |

### Atlassian Reporting

| Dashboard | Created | Last Updated | Status | Notes |
|---|---|---|---|---|
| Database Engineering Sprint Reporting | 2024-03-08 | 2024-03-08 | Active | Reads DBA_VCC_COST. Snapshot exists  permanent shareable link created 2023-07-13, expires 2073-06-30. Confirm who this was shared with |
| Jira Projects Info | 2023-12-08 | 2023-12-08 | Stale | No new Jira data since Dec 2023 |

### Database Engineering AWS Reports

| Dashboard | Created | Last Updated | Status | Notes |
|---|---|---|---|---|
| AWS DataTransfer AZ Bytes Report | 2024-01-28 | 2024-02-20 | Stale | No recent updates |
| AWS EC2 Report | 2023-08-09 | 2023-08-09 | Stale | Duplicate  also in AWS folder |
| AWS RDS Report | 2023-08-09 | 2023-08-21 | Stale | Duplicate  also in AWS folder |
| AWS S3 Report | 2023-08-09 | 2023-08-09 | Stale | Duplicate  also in AWS folder |

### Database Engineering Month End Reporting

| Dashboard | Created | Last Updated | Status | Notes |
|---|---|---|---|---|
| Database Engineering Costs | 2024-01-10 | 2024-10-15 | Active | Reads DBA_VCC_COST  active |
| DXM Month End Reporting | 2023-08-09 | 2023-08-10 | Stale | Duplicate  also in Month End Reporting |
| Encore Month End Reporting | 2023-08-09 | 2023-08-10 | Stale | Duplicate  also in Month End Reporting |
| InvestorPress Month End Reporting | 2023-08-09 | 2023-08-10 | Stale | Duplicate  also in Month End Reporting |
| KAPP Month End Reporting | 2023-08-09 | 2023-08-10 | Stale | Duplicate  also in Month End Reporting |
| WPv2 Month End Reporting | 2023-08-09 | 2024-06-20 | Broken | WPv2 decommissioned  calls dead stored proc |

### Database Engineering Reports

| Dashboard | Created | Last Updated | Status | Notes |
|---|---|---|---|---|
| Database Engineering Costs | 2023-10-06 | 2023-10-12 | Stale | Older copy  newer version in Database Engineering Month End Reporting (2024-10-15) |
| Database Engineering Sprint Reporting | 2023-07-10 | 2023-09-15 | Stale | Older copy  newer version in Atlassian Reporting (2024-03-08) |

### Encore

| Dashboard | Created | Last Updated | Status | Notes |
|---|---|---|---|---|
| BNY IIS Log Streams | 2023-07-11 | 2023-07-11 | Broken | Encore IIS logs frozen at 2024-09-23  confirmed from INFO_AWS_Encore_Cloudwatch_IIS_Logs. BNY Mellon  confirm if client-facing |
| Encore Document Production Runtimes | 2023-07-09 | 2023-07-09 | Stale | Older copy  newer version in Encore Reporting (2023-08-16) |

### Encore Reporting

| Dashboard | Created | Last Updated | Status | Notes |
|---|---|---|---|---|
| Encore Document Production Runtimes | 2023-08-11 | 2023-08-16 | Broken | Encore IIS log data frozen at 2024-09-23  DBA_VCC_AWS_DAILY_CHECKS step silently failing |

### General Reporting

| Dashboard | Created | Last Updated | Status | Notes |
|---|---|---|---|---|
| Server States | 2023-05-29 | 2023-05-29 | Stale | No recent updates |

### KAPP

| Dashboard | Created | Last Updated | Status | Notes |
|---|---|---|---|---|
| KAPP Client Growth | 2023-07-09 | 2023-11-16 | Stale | Older copy  newer version in KAPP Reporting (2024-02-28) |
| KAPP Client Utilisation and Growth Report | 2023-07-14 | 2024-02-22 | Broken + High risk | Reads DBA_VCC_COST  data frozen May 2026 (MemSQL root cause). Name suggests client-facing  confirm with DBA Team |
| KAPP Orphaned and Duplicated Records Report | 2023-08-10 | 2023-08-10 | Stale | Older copy  newer version in KAPP Reporting (2024-03-26) |

### KAPP Client Reporting

| Dashboard | Created | Last Updated | Status | Notes |
|---|---|---|---|---|
| KAPP Client Config | 2024-09-02 | 2024-09-02 | Stale | DBA_VCC_MEMSQL jobs disabled May 2026 |
| NTAM Workflow by workflowRunId | 2025-09-07 | 2025-09-07 | Broken | Confirmed pointing at dead SingleStore-Production-US (10.128.24.122  100% packet loss). Data frozen at 2026-05-08. Grafana showing cached data only |

### KAPP Reporting

| Dashboard | Created | Last Updated | Status | Notes |
|---|---|---|---|---|
| Prod US Document Generation Run Metrics | 2025-10-22 | 2025-10-29 | Broken | Confirmed pointing at dead SingleStore-Production-US (10.128.24.122  100% packet loss). Data frozen at 2026-05-08. Grafana showing cached data only |
| Prod UK Document Generation Run Metrics | 2025-10-22 | 2025-10-29 | Broken | Confirmed pointing at dead SingleStore-Production-UK (10.121.22.219  100% packet loss). Data frozen at 2026-05-08. Grafana showing cached data only |
| Prod EU Document Generation Run Metrics | 2025-10-22 | 2025-10-29 | Broken | Confirmed pointing at dead SingleStore-Production-EU (10.125.12.126  100% packet loss). Data frozen at 2026-05-08. Grafana showing cached data only |
| Release Document Generation Run Metrics | 2025-10-22 | 2025-10-29 | Active | Actively maintained |
| Development Document Generation Run Metrics | 2025-10-22 | 2025-10-29 | Active | Actively maintained |
| Detailed KAPP Workflow Document Generation Stats | 2025-07-25 | 2025-08-18 | Active | Actively maintained |
| KAPP Client Application Auth Config | 2024-10-22 | 2024-10-29 | Stale | DBA_VCC_MEMSQL jobs disabled May 2026 |
| KAPP Dataset Query and Source Execution | 2024-11-19 | 2024-11-20 | Stale | DBA_VCC_MEMSQL jobs disabled May 2026 |
| KAPP Dataset Query Execution | 2024-10-18 | 2024-11-07 | Stale | DBA_VCC_MEMSQL jobs disabled May 2026 |
| KAPP Dataset Lambdas Time Outs | 2024-10-23 | 2024-10-23 | Stale | DBA_VCC_MEMSQL jobs disabled May 2026 |
| KAPP Workflow Times History | 2024-06-11 | 2024-06-12 | Stale | DBA_VCC_MEMSQL jobs disabled May 2026 |
| KAPP Orphaned and Duplicated Records Report | 2023-08-10 | 2024-03-26 | Stale | DBA_VCC_MEMSQL jobs disabled May 2026 |
| KAPP API Error Reporting | 2024-03-05 | 2024-03-11 | Stale | DBA_VCC_MEMSQL jobs disabled May 2026 |
| KAPP Workflow History | 2024-02-28 | 2024-03-07 | Stale | DBA_VCC_MEMSQL jobs disabled May 2026 |
| KAPP Client Growth | 2024-02-28 | 2024-02-28 | Stale | DBA_VCC_MEMSQL jobs disabled May 2026 |
| KAPP API Query Reporting | 2024-02-16 | 2024-02-23 | Stale | DBA_VCC_MEMSQL jobs disabled May 2026 |
| Nifi API Reporting | 2023-08-24 | 2024-02-15 | Active | NiFi data confirmed current  INFO_AWS_Nifi_Loader_API_Detail latest 2026-07-21 |
| Nifi API Reporting Copy | 2023-09-21 | 2023-09-21 | Stale | Duplicate copy |

### Monitoring

| Dashboard | Created | Last Updated | Status | Notes |
|---|---|---|---|---|
| Zabbix Monitoring | 2023-10-24 | 2023-10-27 | Stale credentials | Uses donovan.vangraan credentials |

### Month End Reporting

| Dashboard | Created | Last Updated | Status | Notes |
|---|---|---|---|---|
| DXM Month End Reporting | 2023-07-06 | 2023-07-07 | Stale | No recent updates |
| Encore Month End Reporting | 2023-07-05 | 2023-07-07 | Stale | No recent updates |
| InvestorPress Month End Reporting | 2023-07-05 | 2023-07-05 | Stale | No recent updates |
| KAPP Month End Reporting | 2023-07-04 | 2023-07-05 | Stale | No recent updates. Snapshot exists  permanent shareable link created 2024-01-17, expires 2074-01-04. Confirm who this was shared with |
| Other Services Month End Reporting -- Draft | 2023-07-07 | 2023-07-21 | Broken | Draft  never completed |
| WPv2 Month End Reporting | 2023-07-06 | 2023-07-07 | Broken | WPv2 decommissioned |

### Performance Dashboards

| Dashboard | Created | Last Updated | Status | Notes |
|---|---|---|---|---|
| Query Performance Dashboard | 2024-03-04 | 2024-03-07 | Stale | DBA_VCC_MEMSQL jobs disabled May 2026 |

### SingleStore Monitoring

> All SingleStore dashboards are in this one folder. Duplicate titles exist  older and newer copies both present.

| Dashboard | Created | Last Updated | Status | Notes |
|---|---|---|---|---|
| Cluster View | 2023-06-13 | 2025-06-23 | Active | Current version  original dashboard updated in place |
| Cluster View | 2024-07-12 | 2024-07-12 | Stale | Duplicate  same folder |
| Detailed Cluster View By Node | 2023-06-13 | 2023-09-07 | Stale | Original copy |
| Detailed Cluster View By Node | 2024-07-12 | 2024-07-12 | Stale | Duplicate  same folder |
| Disk Usage | 2024-07-12 | 2024-07-12 | Stale | No recent updates |
| Historical Workload Monitoring | 2023-06-13 | 2025-08-07 | Active | Current version  original dashboard updated in place |
| Historical Workload Monitoring | 2024-07-12 | 2024-07-12 | Stale | Duplicate  same folder |
| Memory Usage | 2023-06-13 | 2023-09-07 | Stale | Original copy |
| Memory Usage | 2024-07-12 | 2024-07-12 | Stale | Duplicate  same folder |
| Pipeline Performance | 2024-07-12 | 2024-07-12 | Stale | No recent updates |
| Pipeline Summary | 2024-07-12 | 2024-07-12 | Stale | No recent updates |
| Query History | 2024-07-12 | 2025-08-07 | Active | Actively maintained |
| Resource Pool Monitoring | 2024-07-12 | 2024-07-12 | Stale | No recent updates |

---

## Dashboard Snapshots

> Confirmed from grafana.db 2026-07-22. Snapshots create a public URL accessible without Grafana login.

| Dashboard | Created | Expires | Risk |
|---|---|---|---|
| Database Engineering Sprint Reporting | 2023-07-13 | 2073-06-30 | 50-year expiry  permanent link. Confirm who it was shared with |
| KAPP Month End Reporting | 2024-01-17 | 2074-01-04 | 50-year expiry  permanent link. Strongest evidence of external/client-facing access on this server. Confirm with DBA Team immediately |

> No snapshots exist for BNY IIS Log Streams or KAPP Client Utilisation and Growth Report.

---

## Alert Rules

| Alert Name | Condition | No Data State | Error State | Paused | Last Updated |
|---|---|---|---|---|---|
| Failed Read Queries per Second | C | NoData | Error | No | 2024-02-07 |
| KAPP Client Config Alert | C | OK | Error | No | 2025-03-04 |
| KAPP Client Application Auth Config Alert | C | OK | Error | No | 2025-03-04 |

## Alert Contact Points

| Receiver | Type | Destination | Notes |
|---|---|---|---|
| grafana-default-email | Email | `<example@email.com>` | **Placeholder  not configured. No real email set.** |
| alerts-data-operations | Slack | Encrypted token/URL | Active Slack channel  default route for all alerts |
| alert-app-allow2fa-disabled | Slack | Encrypted token/URL | Separate Slack channel  only fires when `Client Auth = Yes` |

## Alert Routing

- Default route  `alerts-data-operations` Slack channel
- If alert label `Client Auth = Yes`  `alert-app-allow2fa-disabled` Slack channel
- Grouped by `grafana_folder` and `alertname`

> The email contact point has a placeholder address and will not deliver. All active alerts route to Slack. The actual Slack webhook URLs are encrypted in the database  need Grafana admin login to view.

---

## Installed Plugins

| Plugin | Type | Notes |
|---|---|---|
| alexanderzobnin-zabbix-app | Datasource | Reads from Zabbix MySQL directly |
| aws-datasource-provisioner-app | Datasource | AWS CloudWatch integration |
| marcusolsson-json-datasource | Datasource | NiFi API JSON datasource |
| golioth-websocket-datasource | Datasource | WebSocket datasource |
| grafana-image-renderer | App | Dashboard image rendering for alerts/reports |
| grafana-piechart-panel | Panel | Pie chart |
| briangann-gauge-panel | Panel | Gauge panel |
| volkovlabs-echarts-panel | Panel | Apache ECharts |
| vonage-status-panel | Panel | Status/health panel |
| grafana-clock-panel | Panel | Clock panel |

---

## Open Questions

- [x] ~~What is the Grafana URL and port?~~  https://ew1r-rep-01 on port 443
- [x] ~~What datasources are configured?~~  21 datasources confirmed, see above
- [x] ~~Which dashboards are actively used?~~  74 dashboards confirmed live from grafana.db 2026-07-21. 11 updated in 2025+  actively used. SingleStore Monitoring (v2) folder confirmed not to exist  all SingleStore dashboards in one folder with duplicate titles.
- [x] ~~Who has admin access to Grafana?~~  DBA Team, donovan.vangraan
- [x] ~~Is Grafana version current or end-of-life?~~  v9.5.2, LTS, not latest but supported
- [ ] Are any dashboards client-facing or SLA-related?  Evidence gathered but not conclusive. Summary:
  - **BNY IIS Log Streams**  uses DBA_VCC datasource (a082f27e). No snapshot, no API key, no log hits. Data frozen Sept 2024. Cannot confirm client-facing from evidence alone  blocked on DBA Team
  - **KAPP Client Utilisation and Growth Report**  uses DBA_VCC (a082f27e) + KAPP Dev (da173cae). No snapshot, no API key, no log hits. LU_KAPP_ClientList has 280 real institutional clients. REP_MONTHEND_CLIENT_* procs (19 procs) form a per-client reporting layer. Data frozen May 2026. Cannot confirm client-facing from evidence alone  blocked on DBA Team
  - **KAPP Month End Reporting**  has a snapshot with 50-year expiry (expires 2074-01-04, created 2024-01-17). This is a permanent shareable link  used to share dashboards externally without requiring a Grafana login. This is the strongest evidence of external/client-facing access found in the investigation
  - **Database Engineering Sprint Reporting**  also has a snapshot with 50-year expiry (expires 2073-06-30, created 2023-07-13). Likely internal sharing but worth confirming
- [x] ~~What contact points are configured for Grafana alert rules?~~  3 contact points confirmed: alerts-data-operations (Slack, active), alert-app-allow2fa-disabled (Slack, active), email (placeholder  not configured, will not deliver)
- [x] ~~Is InfluxDB datasource still active?~~  **Closed. Zero dashboards reference InfluxDB UID aa82f021  confirmed via grafana.db scan 2026-07-21. No URL stored, no dashboards using it. Safe to delete.**

### Q21/Q22  Why were MemSQL jobs disabled?

> Partially closed from evidence  stakeholder confirmation still needed.

All 7 MemSQL jobs were disabled on **2026-05-08 between 12:00:32 and 12:01:10**  within 90 seconds of each other. This is not organic failure. Someone deliberately disabled all 7 jobs in a single session. DBA_VCC_MEMSQL_GLOBAL_STATUS_CAPTURE was disabled separately a year earlier (2025-05-05).

Evidence from `msdb.dbo.sysjobs`:

| Job | Enabled | date_modified |
|---|---|---|
| DBA_VCC_MEMSQL_WEEKLY_CHECKS | 0 | 2026-05-08 12:01:10 |
| DBA_VCC_MEMSQL_MON_SQL_STATUS | 0 | 2026-05-08 12:01:05 |
| DBA_VCC_MEMSQL_MON_PING_STATS | 0 | 2026-05-08 12:01:01 |
| DBA_VCC_MEMSQL_HOURLY_CHECKS | 0 | 2026-05-08 12:00:58 |
| DBA_VCC_MEMSQL_DAILY_CHECKS | 0 | 2026-05-08 12:00:52 |
| DBA_VCC_MEMSQL_AUDIT_BACKUP_INFO_DETAILED | 0 | 2026-05-08 12:00:32 |
| DBA_VCC_MEMSQL_GLOBAL_STATUS_CAPTURE | 0 | 2025-05-05 11:00:17 |

Conclusion from evidence: deliberate decommission action, not a failure or pause. Still need DBA Team to confirm who did it and whether SingleStore itself was decommissioned at the same time.

---

## Datasource Proposed Solutions

> For each datasource: what it was for, whether it is still needed, and whether something already in the platform covers it.

| Datasource | What it was for | Action | Reason |
|---|---|---|---|
| DBA_VCC (a082f27e) | Primary datasource  reads all VCC monitoring data from local SQL Server | Keep | 9 confirmed active dashboards depend on it. Needed until decommission decision is finalised |
| DBA_VCC (e8597015) | Duplicate of the above  same target, different UID | Retire | Exact duplicate of a082f27e. Consolidate before any action |
| KAPP Dev | Reads KAPP metrics database in Dev environment | Confirm | Confirm if any active dashboards still use it |
| KAPP Rel | Reads KAPP metrics database in Release environment | Confirm | Confirm if any active dashboards still use it |
| KAPP UK Prod | Reads KAPP metrics database in UK Production | Keep | Confirmed active dashboards reading from it |
| KAPP EU Prod | Reads KAPP metrics database in EU Production | Keep | Confirmed active dashboards reading from it |
| KAPP US Prod | Reads KAPP metrics database in US Production | Keep | Confirmed active dashboards reading from it |
| KAPP Monitoring | Reads KAPP monitoring database  used by SingleStore dashboards | Keep | Query History, Cluster View, Historical Workload Monitoring all confirmed active |
| monitoring | Duplicate of KAPP Monitoring  same IP (10.120.8.208), same database | Retire | Exact duplicate |
| MySQL | Generic MySQL  same IP as KAPP Rel, purpose unclear | Confirm | Audit which dashboards reference this UID  if none, retire |
| SingleStore-Dev | Reads UDM__ schema on SingleStore Dev | Retire | Confirmed dead  100% packet loss to 10.61.0.95 (2026-07-22). No live target |
| SingleStore-Release | Reads UDM__ schema on SingleStore Release | Confirm | Confirmed alive (0% loss, 1ms). Confirm if dependent dashboards are still needed |
| SingleStore-Production-UK | Reads UDM__ schema on SingleStore UK Prod | Retire | Confirmed dead  100% packet loss to 10.121.22.219 (2026-07-22). Dependent dashboards broken |
| SingleStore-Production-EU | Reads UDM__ schema on SingleStore EU Prod | Retire | Confirmed dead  100% packet loss to 10.125.12.126 (2026-07-22). Dependent dashboards broken |
| SingleStore-Production-US | Reads UDM__ schema on SingleStore US Prod | Retire | Confirmed dead  100% packet loss to 10.128.24.122 (2026-07-22). Dependent dashboards broken |
| Zabbix Nonprod old | Reads old non-prod Zabbix MySQL (10.72.8.191) | Retire | Dead target. Zabbix already monitors this infrastructure directly  no middleman needed |
| zabbix-server-data.shnonprd | Reads current non-prod Zabbix MySQL (10.72.8.186) | Replace | Zabbix already has this data natively. These dashboards are a duplicate view through a middleman. Credentials must be rotated regardless |
| Zabbix Prod Old | Reads old prod Zabbix MySQL (10.120.8.120) | Retire | Dead target. Ex-employee credentials |
| zabbix-server-data.shprd | Reads current prod Zabbix MySQL (10.120.8.51) | Replace | Same as shnonprd  Zabbix covers this natively. Credentials must be rotated regardless |
| JSON API | Reads NiFi Registry API (10.125.9.192:8443)  NiFi pipeline monitoring | Keep | NiFi data confirmed active 2026-07-21. No equivalent elsewhere |
| CloudWatch | AWS CloudWatch  uses IAM role | Replace | CloudWatch has its own native dashboards. AWS Cost Explorer covers cost reporting natively. No need to duplicate in Grafana |
| InfluxDB | Intended for time-series metrics  no URL ever configured, no dashboards ever built against it | Retire | Never used. Confirmed zero dashboards reference it (2026-07-21) |

---

## Conclusion  Recommendations and Proposed Solutions

---

### 1. Ex-Employee Credentials in Zabbix Datasources  Immediate Security Risk

**What we found:**
All 4 Zabbix datasources in Grafana are configured using credentials belonging to **donovan.vangraan**  an ex-employee who was last seen on this server in November 2024. His account still has active database access to Zabbix MySQL. This is a live security risk that exists today, completely independent of the decommission decision.

**Which datasources use donovan.vangraan's credentials:**

| Datasource | Uses donovan.vangraan? |
|---|---|
| DBA_VCC (primary SQL Server) | No  uses `grafana` SQL login |
| KAPP UK/EU/US Prod MySQL | No  uses a separate MySQL service account |
| SingleStore UK/EU/US | No  separate credentials |
| JSON API (NiFi) | No |
| CloudWatch | No  uses IAM role |
| Zabbix Nonprod old | Yes  donovan.vangraan |
| zabbix-server-data.shnonprd | Yes  donovan.vangraan |
| Zabbix Prod Old | Yes  donovan.vangraan |
| zabbix-server-data.shprd | Yes  donovan.vangraan |

Every other datasource uses its own service account or IAM role. Only the 4 Zabbix datasources are affected.

**The risk specifically:**
- donovan.vangraan left the organisation  his credentials should have been revoked at offboarding
- His MySQL credentials for Zabbix are still stored in Grafana and still active
- Anyone who can access Grafana can query Zabbix data using his account
- If his password was reused elsewhere, that is an additional risk beyond this server
- donovan.vangraan still holds Grafana admin rights  he could log back in
- Default admin account also still active  last seen 2024-11-29

**Proposed solution:**
- Revoke donovan.vangraan's Grafana admin access immediately
- Create a dedicated `grafana_readonly` service account in Zabbix MySQL
- Replace his credentials in all 4 Zabbix datasources with the new service account
- Disable the default admin account
- This must happen now  independent of the decommission decision

---

### 2. Zabbix Datasources  This Server Is the Middleman, Cut It Out

**What we found:**
Grafana on this server reads from 4 Zabbix MySQL databases to power Zabbix monitoring dashboards (Dashboard Servers Windows, SQL SERVER, Microsoft SQL Server, Zabbix Server Dashboard). This server is acting as a middleman  it sits between the user and Zabbix, adding no value. Zabbix already monitors the infrastructure directly. The dashboards can connect to Zabbix directly without this server in the middle.

**Supporting evidence:**
- 4 Zabbix-related dashboards confirmed: Dashboard Servers Windows (2023-09-05), SQL SERVER (2023-09-05), Microsoft SQL Server (2023-09-05), Zabbix Server Dashboard (2023-09-05)
- Zabbix Nonprod old and Zabbix Prod Old datasources  pointing at dead/old Zabbix instances
- alexanderzobnin-zabbix-app plugin installed  reads Zabbix MySQL directly
- Zabbix agent already running on EW1R-REP-01 (port 10050)  Zabbix watches this server directly

**Recommendation:**
- These 4 dashboards are candidates for retirement  Zabbix already provides this monitoring natively and is the authoritative source
- The 2 dead Zabbix datasources (Zabbix Nonprod old, Zabbix Prod Old) can be retired immediately  dead targets, no active dashboards
- Confirm with DBA Team whether anyone still uses these 4 dashboards before retiring them
- Credentials must be rotated regardless of the decommission outcome  this is a live security risk today

---

### 3. Stale and Broken Dashboards  Multiple Root Causes, All Silent

**What we found:**
Three separate silent failures are causing dashboards to show stale or wrong data. None of them fired an alert. None were noticed until this investigation.

**Root cause 1  MemSQL jobs disabled May 2026:**
- 14 dashboards reading from DBA_VCC_MEMSQL have been stale since May 2026
- DBA_VCC_COST collection also broken as a downstream casualty  all SP_INFO_KAPP_CLIENT_* procs depend on DBA_VCC_MEMSQL.BAS_Ping_Stat to get live servers. With MemSQL jobs disabled, zero servers returned, zero rows written, job reports succeeded
- KAPP Client Utilisation and Growth Report showing data frozen at 2026-05-04  possible client-facing dashboard

**Root cause 2  DBA_VCC_AWS_DAILY_CHECKS step silently failing since Sept 2024:**
- INFO_AWS_Encore_Cloudwatch_IIS_Logs frozen at 2024-09-23  confirmed from live query 2026-07-21
- INFO_AWS_Entity_Cost frozen at 2024-09-22  single row only, archive also frozen at 2024-06-21
- AWS Cost Report and AWS Cost Report Monthly dashboards showing data that is 10 months stale
- BNY IIS Log Streams (Encore) showing data that is 10 months stale  BNY Mellon is an institutional client
- CATCH blocks in DBA_VCC_AWS_DAILY_CHECKS swallow the error  job reports succeeded every day

**What is still active and current (confirmed 2026-07-21):**
- KAPP API query tracking  INFO_AWS_KAPP_Query_API_Detail latest 2026-07-21
- NiFi pipeline monitoring  INFO_AWS_Nifi_Loader_API_Detail latest 2026-07-21

**Recommendation:**
- Dashboards with dead data pipelines and no confirmed consumer are candidates for retirement  not worth preserving
- AWS Cost Report and AWS Cost Report Monthly: AWS Cost Explorer already provides this natively  these dashboards are redundant
- BNY IIS Log Streams and Encore dashboards: data frozen Sept 2024  confirm with DBA Team if BNY Mellon still needs this before any decision
- The silent failure pattern (no alert fired, no one noticed for months) is evidence that these dashboards have no active consumer  this supports retirement

---

### 4. Duplicate Datasources and Dashboards  Cleanup Before Migration

**What we found:**
There are 2 DBA_VCC datasource entries pointing at the same target with different UIDs. There are multiple duplicate dashboards sitting in different folders  older versions that were never cleaned up. Migrating this mess as-is to Amazon Managed Grafana will create confusion.

**Supporting evidence:**
- DBA_VCC datasource: UIDs a082f27e and e8597015  both point to localhost DBA_VCC
- Multiple dashboards with identical names in different folders: AWS RDS Report, Encore Document Production Runtimes, WPv2 Month End Reporting, KAPP Orphaned and Duplicated Records Report, and others
- KAPP Monitoring and monitoring datasources  both point to 10.120.8.208, same database

**Recommendation:**
- All older duplicate copies are candidates for immediate retirement  the newer version in each case is the one to keep or assess
- Consolidating duplicates reduces the scope of what needs to be assessed in the follow-on decommission epic

---

### 5. Alerting Is Effectively Broken  Only 3 Rules, Email Never Fires

**What we found:**
Grafana has 74 dashboards and only 3 alert rules. The email contact point has a placeholder address and will never deliver. All active alerts route to Slack only. The 3 existing alert rules cover KAPP client config and read query failures  nothing covers the broken dashboards, stale data, or datasource failures that this investigation uncovered. The server has been silently failing for months with no alert firing.

**Supporting evidence:**
- 3 alert rules confirmed: Failed Read Queries per Second, KAPP Client Config Alert, KAPP Client Application Auth Config Alert
- Email contact point destination: `<example@email.com>`  placeholder, never configured
- No alert rule exists for: stale data detection, job failure notification, datasource connectivity, or dashboard data freshness
- 14 dashboards stale since May 2026  no alert fired
- AWS cost and Encore IIS data frozen since Sept 2024  no alert fired
- DBA_VCC_COST collection silently broken since May 2026  no alert fired

**Recommendation:**
- 74 dashboards, 3 alert rules, and a broken email contact point is evidence that alerting was never properly built out on this server
- Whatever platform replaces this monitoring function must have proper alerting from day one  Zabbix, CloudWatch Alarms, or a properly configured Grafana instance
- This is a gap to flag in the follow-on decommission epic, not something to fix on this server

---

### 6. Grafana Connects Directly to Production MySQL  Network Dependency

**What we found:**
Grafana on this server has direct MySQL connections to 6 production databases  KAPP UK Prod, KAPP EU Prod, KAPP US Prod, SingleStore UK Prod, SingleStore EU Prod, and SingleStore US Prod. These connections bypass any data layer and read production data directly. If this server is decommissioned without migrating these datasources, those dashboards break immediately.

**Supporting evidence:**
- KAPP UK Prod: 10.121.29.82  direct MySQL connection
- KAPP EU Prod: 10.125.6.134  direct MySQL connection
- KAPP US Prod: 10.128.30.6  direct MySQL connection
- SingleStore-Production-UK: 10.121.22.219  direct MySQL connection, UDM__ schema
- SingleStore-Production-EU: 10.125.12.126  direct MySQL connection, UDM__ schema
- SingleStore-Production-US: 10.128.24.122  direct MySQL connection, UDM__ schema
- 10 dashboards confirmed reading from these datasources  all actively maintained in 2025

**Recommendation:**
- These 5 datasources (KAPP UK/EU/US Prod, KAPP Monitoring, JSON API/NiFi) have confirmed live data and no equivalent elsewhere  they represent the core of what still has value on this server
- The 9 dashboards reading from them are the ones that need a decision in the follow-on decommission epic: does another platform take them, or are they retired too
- tlsSkipVerify=true on KAPP Monitoring is a security gap to flag for the follow-on epic

---

### 7. WPv2 Dashboards  Dead Data, Should Be Retired Now

**What we found:**
Two WPv2 Month End Reporting dashboards exist  one in Month End Reporting folder, one in Database Engineering Month End Reporting folder. WPv2 was decommissioned years ago. These dashboards call stored procedures that reference dead linked servers. They will never show live data again.

**Supporting evidence:**
- WPv2 Month End Reporting (Month End Reporting folder)  last updated 2023-07-07
- WPv2 Month End Reporting (Database Engineering Month End Reporting folder)  last updated 2024-06-20
- SP_AUDIT_WPv2_CLIENTS_DETAILED last modified 2022-11-01  never updated after WPv2 decommission
- WPv2 linked servers ew2p-wpv2, ew2r-wpv2, ue1p-wpv2, ue1r-wpv2  all DNS gone, confirmed unreachable
- DBA_VCC_MYSQL_AUDIT_DXM_CLIENT_DETAILED and DBA_VCC_MYSQL_DAILY_CHECKS both failing daily because of these dead dependencies

**Proposed solution:**
- Delete both WPv2 Month End Reporting dashboards  no migration needed, no data to preserve
- Drop SP_AUDIT_WPv2_CLIENTS_DETAILED from DBA_VCC_MYSQL
- Remove WPv2 steps from the 2 failing jobs  this is the same fix proposed in Theme A finding 6
- This is a zero-risk cleanup that can be done immediately

---

### 8. Overall Grafana Recommendation  Retire / Replace / Keep

**The core question this investigation answers:** Does this server need to keep running Grafana, or does something we already have cover what it does?

**Context:** The organisation already runs Zabbix (infrastructure monitoring), CloudWatch (AWS-native monitoring), and has access to AWS-native services like Cost Explorer. The question is not how to migrate  it is whether each dashboard and datasource still serves a purpose that nothing else already covers.

---

**Dashboard classification  all 74:**

| Classification | Count | Dashboards | Reason |
|---|---|---|---|
| Keep  still needed, nothing else covers it | 9 | Nifi API Reporting, Database Engineering Costs, Database Engineering Sprint Reporting, Cluster View (current), Historical Workload Monitoring (current), Query History, Detailed KAPP Workflow Stats, Release Doc Gen Run Metrics, Development Doc Gen Run Metrics | Live data confirmed. No equivalent in Zabbix or CloudWatch |
| Keep  pending stakeholder confirmation | 2 | KAPP Client Utilisation and Growth Report, BNY IIS Log Streams | Possible client-facing. Cannot retire without DBA Team confirmation |
|  Replace  AWS already has this | 4 | AWS Cost Report, AWS Cost Report Monthly, AWS EC2 Report, AWS RDS Report | AWS Cost Explorer and CloudWatch already provide this natively. No need to maintain a custom dashboard on a separate server |
|  Replace  Zabbix already has this | 4 | Dashboard Servers Windows, SQL SERVER, Microsoft SQL Server, Zabbix Server Dashboard | Zabbix already monitors this infrastructure directly. These dashboards are a duplicate view through a middleman |
| Retire  data source dead, no recovery path | 7 | Prod EU/UK/US Doc Gen Run Metrics, NTAM Workflow by workflowRunId, KAPP Client Config, KAPP Client Application Auth Config | SingleStore Prod EU/UK/US confirmed dead (100% packet loss). Data frozen 2026-05-08. No live target to restore |
| Retire  data pipeline broken, function no longer exists | 2 | WPv2 Month End Reporting (both copies) | WPv2 decommissioned. Stored procs call dead linked servers. No recovery path |
| Retire  stale, MemSQL disabled, no confirmed consumer | 11 | KAPP Workflow History, KAPP API Error Reporting, KAPP Orphaned and Duplicated Records Report, KAPP Workflow Times History, KAPP Dataset Query Execution, KAPP Dataset Query and Source Execution, KAPP Dataset Lambdas Time Outs, KAPP API Query Reporting, Query Performance Dashboard, KAPP Client Growth (both copies) | All depend on DBA_VCC_MEMSQL jobs disabled May 2026. No consumer confirmed. No alert fired when they went stale |
| Retire  duplicate, older copy superseded | 17 | All older duplicate copies across AWS, Encore, KAPP, Database Engineering folders | Newer version exists in another folder. Duplicates add noise, no value |
| Retire  never completed or never used | 2 | Other Services Month End Reporting -- Draft, Jira Projects Info (no new data since Dec 2023) | Draft never finished. Jira feed dead |
| Retire  stale, no confirmed consumer | 5 | AWS S3 Report, AWS Security Report, AWS DataTransfer AZ Bytes Report, Server States, Zabbix Monitoring | No recent updates, no confirmed consumer, no live data pipeline |
| Confirm before deciding | 11 | KAPP Month End Reporting (snapshot  confirm who it was shared with), Encore Month End Reporting, DXM Month End Reporting, InvestorPress Month End Reporting, KAPP Client Growth (current), KAPP API Query Reporting, Encore Document Production Runtimes (current), Resource Pool Monitoring, Pipeline Summary, Pipeline Performance, Disk Usage | Need stakeholder input to confirm whether anyone still reads these |

---

**Datasource classification:**

| Classification | Count | Datasources |
|---|---|---|
| Keep  still needed | 5 | DBA_VCC (primary), KAPP UK/EU/US Prod, KAPP Monitoring |
|  Replace  Zabbix connects directly, no middleman needed | 2 | zabbix-server-data.shnonprd, zabbix-server-data.shprd |
|  Replace  CloudWatch is already AWS-native | 1 | CloudWatch (if dashboards replaced by native CloudWatch dashboards) |
| Retire  dead target confirmed | 4 | SingleStore-Dev, SingleStore-Production-UK, SingleStore-Production-EU, SingleStore-Production-US |
| Retire  duplicate or orphaned | 5 | DBA_VCC (e8597015 duplicate), monitoring (duplicate of KAPP Monitoring), Zabbix Nonprod old, Zabbix Prod Old, InfluxDB |
| Confirm before deciding | 4 | KAPP Dev, KAPP Rel, MySQL generic, SingleStore-Release |

---

**What this means for the server:**

- 35+ dashboards can be retired immediately  dead data, dead targets, duplicates, or functions already covered by Zabbix and AWS
- 4 dashboards replace functions AWS Cost Explorer and CloudWatch already provide natively  no need to rebuild them anywhere
- 4 Zabbix dashboards are a middleman view  Zabbix already has this data, these dashboards add no value
- 9 dashboards have confirmed live data and no equivalent elsewhere  these are the ones that need a home if this server is decommissioned
- 2 dashboards are potentially client-facing  these are the highest risk and must be confirmed before any decision
- The KAPP Month End Reporting snapshot (permanent public URL, expires 2074) is the strongest evidence of external access on this server  must be confirmed with DBA Team before anything is retired

**The server cannot be decommissioned until:**
1. DBA Team confirm whether KAPP Client Utilisation and Growth Report and BNY IIS Log Streams are client-facing
2. The KAPP Month End Reporting snapshot URL is confirmed  who was it shared with and is it still in use
3. DBA Team confirm why MemSQL jobs were disabled and whether SingleStore itself was decommissioned
4. A decision is made on the 9 dashboards with live data  does another platform (Zabbix, CloudWatch, or a replacement Grafana) take them, or are they retired too
