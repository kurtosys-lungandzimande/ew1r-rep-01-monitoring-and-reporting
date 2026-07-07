# Grafana Inventory — EW1R-REP-01

> Status: COMPLETE — all data extracted directly from grafana.db via Python/SQLite

---

## Access Details

| Property | Value |
|---|---|
| URL (hostname) | https://ew1r-rep-01 |
| URL (IP) | https://10.72.8.216 |
| Port | 443 (HTTPS — confirmed via netstat, PID 3844 = grafana.exe) |
| Version | 9.5.2 (confirmed from C:\Program Files\GrafanaLabs\svc-9.5.2.0) |
| Database | C:\Program Files\GrafanaLabs\grafana\data\grafana.db (162 MB) |
| Install path | C:\Program Files\GrafanaLabs\grafana\ |
| Config path | C:\Program Files\GrafanaLabs\grafana\conf\grafana.ini |

> Browser access unreachable from outside network — requires VPN or RDP from within the server network.

---

## Users and Access

| Login | Name | Email | Admin | Last Seen |
|---|---|---|---|---|
| admin | (default) | admin@localhost | Yes | 2024-11-29 |
| donovan.vangraan | donovan.vangraan | donovan.vangraan@kurtosys.com | Yes | 2024-11-13 — builder, no longer active |
| tashvir.babulal | Tashvir Babulal | tashvir.babulal@kurtosys.com | Yes | 2026-06-09 — **actively using** |
| yogeshwar.phull | Yogeshwar Phull | yogeshwar.phull@kurtosys.com | Yes | 2026-06-22 — **actively using** |
| rayhaan.suleyman | Rayhaan Suleyman | rayhaan.suleyman@kurtosys.com | Yes | 2026-06-30 — **actively using** |
| ram.jeyaraman | Ram Jeyaraman | ram@kurtosys.com | No | 2025-09-11 |
| jason.wolmarans | Jason Wolmarans | jason.wolmarans@kurtosys.com | No | 2025-02-12 |
| sunil.odedra | Sunil Odedra | sunil.odedra@kurtosys.com | No | 2023-07-12 — likely inactive |

> 3 admins actively using Grafana as of June 2026: tashvir.babulal, yogeshwar.phull, rayhaan.suleyman.
> These are the key contacts before any decommission or migration decision.

---

## Datasources

> Confirmed from grafana.db via query 12.6 (2026-07-07). UIDs are what dashboard JSON references internally.

| UID | Name | Type | Host/IP | Database | Notes |
|---|---|---|---|---|---|
| a082f27e | DBA_VCC | mssql | localhost | DBA_VCC | Local SQL Server — primary datasource for VCC dashboards |
| e8597015 | DBA_VCC | mssql | localhost | DBA_VCC | Duplicate entry — same target, two UIDs. Dashboards may reference either |
| da173cae | KAPP Dev | mysql | 10.61.11.70:3306 | metrics | KAPP Dev MySQL |
| d1679f57 | KAPP Rel | mysql | 10.77.3.236 | metrics | KAPP Release MySQL |
| cd097e22 | KAPP UK Prod | mysql | 10.121.29.82 | metrics | KAPP UK Production MySQL |
| e792d174 | KAPP EU Prod | mysql | 10.125.6.134 | metrics | KAPP EU Production MySQL |
| db3d6c01 | KAPP US Prod | mysql | 10.128.30.6 | metrics | KAPP US Production MySQL |
| f4830a0f | KAPP Monitoring | mysql | 10.120.8.208 | metrics | KAPP monitoring — tlsSkipVerify=true |
| dce83066 | monitoring | mysql | 10.120.8.208 | metrics | Duplicate of KAPP Monitoring — same IP, same database |
| f2ca52be | MySQL | mysql | 10.77.3.236:3306 | metrics | Generic MySQL — same IP as KAPP Rel |
| d8b0939b | SingleStore-Dev | mysql | 10.61.0.95 | UDM__ | SingleStore Dev — queries UDM__ schema |
| f1d911af | SingleStore-Release | mysql | 10.77.6.161 | UDM__ | SingleStore Release — queries UDM__ schema |
| a6046586 | SingleStore-Production-UK | mysql | 10.121.22.219 | UDM__ | SingleStore UK Prod — queries UDM__ schema |
| df309b44 | SingleStore-Production-EU | mysql | 10.125.12.126 | UDM__ | SingleStore EU Prod — queries UDM__ schema |
| bfe8f780 | SingleStore-Production-US | mysql | 10.128.24.122 | UDM__ | SingleStore US Prod — queries UDM__ schema |
| aafbf2f7 | Zabbix Nonprod old | mysql | 10.72.8.191 | zabbix | Old non-prod Zabbix MySQL |
| b10bf74c | zabbix-server-data.shnonprd.kurtosys-internal | mysql | 10.72.8.186 | zabbix | Current non-prod Zabbix MySQL |
| dbafc322 | Zabbix Prod Old | mysql | 10.120.8.120 | zabbix | Old prod Zabbix MySQL |
| d68a35f0 | zabbix-server-data.shprd.kurtosys-internal | mysql | 10.120.8.51 | zabbix | Current prod Zabbix MySQL |
| b7838f71 | JSON API | marcusolsson-json-datasource | 10.125.9.192:8443 | — | NiFi API — tlsSkipVerify=true |
| bae6c95e | CloudWatch | cloudwatch | — | — | AWS CloudWatch — no URL stored |
| aa82f021 | InfluxDB | influxdb | — | — | InfluxDB — no URL stored, needs confirmation |

> Critical: Two DBA_VCC datasource entries exist with different UIDs (a082f27e and e8597015) pointing to the same localhost target. Dashboards may be split across both UIDs — this needs to be checked before any migration.
> Critical: Grafana connects directly to production MySQL instances (KAPP UK/EU/US Prod, SingleStore Prod UK/EU/US) using the UDM__ schema. These connections will break if this server is decommissioned or network access is removed.
> Note: All four Zabbix datasources use donovan.vangraan credentials — this account is no longer active. Credentials need rotation before or during decommission.

---

## Folders

| Folder | Created | Notes |
|---|---|---|
| General Reporting | 2023-05-29 | Top-level reporting folder |
| SingleStore Monitoring | 2023-06-13 | SingleStore cluster dashboards |
| AWS | 2023-06-21 | AWS infrastructure reports |
| Month End Reporting | 2023-07-04 | Month-end business reports |
| Encore | 2023-07-09 | Encore product dashboards |
| Database Engineering Reports | 2023-07-09 | Internal DB engineering reports |
| KAPP | 2023-07-09 | KAPP product dashboards |
| Database Engineering Month End Reporting | 2023-08-09 | DB engineering month-end |
| Database Engineering AWS Reports | 2023-08-09 | DB engineering AWS reports |
| KAPP Reporting | 2023-08-10 | KAPP reporting dashboards |
| Encore Reporting | 2023-08-11 | Encore reporting dashboards |
| Monitoring | 2023-10-24 | Infrastructure monitoring |
| Atlassian Reporting | 2023-12-08 | Jira/Confluence reports |
| Performance Dashboards | 2024-03-04 | Query/performance dashboards |
| SingleStore Monitoring (v2) | 2024-03-11 | Updated SingleStore monitoring |
| KAPP Client Reporting | 2024-09-02 | KAPP client-level reporting |

---

## Dashboard Inventory

> Total: 74 dashboards confirmed — query 9.5 / query 13.7 both run 2026-07-07, results match.
> Several dashboard names appear more than once — these are older versions sitting in different folders, not the same dashboard.
> Duplicates are noted in the Notes column.

### Actively Maintained — updated 2025

| Dashboard | Last Updated | Notes |
|---|---|---|
| Prod US Document Generation Run Metrics | 2025-10-29 | Production — actively maintained |
| Prod UK Document Generation Run Metrics | 2025-10-29 | Production — actively maintained |
| Prod EU Document Generation Run Metrics | 2025-10-29 | Production — actively maintained |
| Release Document Generation Run Metrics | 2025-10-29 | Actively maintained |
| Development Document Generation Run Metrics | 2025-10-29 | Actively maintained |
| NTAM Workflow by workflowRunId | 2025-09-07 | Very recent — created Sep 2025 |
| Detailed KAPP Workflow Document Generation Stats | 2025-08-18 | Actively maintained |
| Query History | 2025-08-07 | SingleStore — actively maintained |
| Historical Workload Monitoring | 2025-08-07 | SingleStore v2 — actively maintained. Older copy also exists (2024-07-12) |
| Cluster View | 2025-06-23 | SingleStore v2 — actively maintained. Older copy also exists (2024-07-12) |

### KAPP Reporting — updated 2024

| Dashboard | Last Updated | Notes |
|---|---|---|
| KAPP Dataset Query and Source Execution | 2024-11-20 | Stale data — DBA_VCC_MEMSQL jobs disabled May 2026 |
| KAPP Dataset Query Execution | 2024-11-07 | Stale data — DBA_VCC_MEMSQL jobs disabled May 2026 |
| Grafana Dashboard Exporter/Importer | 2024-10-29 | Admin utility |
| KAPP Client Application Auth Config | 2024-10-29 | Stale data — DBA_VCC_MEMSQL jobs disabled May 2026 |
| KAPP Dataset Lambdas Time Outs | 2024-10-23 | Stale data — DBA_VCC_MEMSQL jobs disabled May 2026 |
| Database Engineering Costs | 2024-10-15 | Reads DBA_VCC_COST — active. Older copy also exists (2023-10-12) |
| KAPP Client Config | 2024-09-02 | Stale data — DBA_VCC_MEMSQL jobs disabled May 2026 |
| WPv2 Month End Reporting | 2024-06-20 | Calls REP_MONTHEND — stale. Older copy also exists (2023-07-07) |
| KAPP Workflow Times History | 2024-06-12 | Stale data — DBA_VCC_MEMSQL jobs disabled May 2026 |
| KAPP Orphaned and Duplicated Records Report | 2024-03-26 | Stale data. Older copy also exists (2023-08-10) |
| KAPP API Error Reporting | 2024-03-11 | Stale data — DBA_VCC_MEMSQL jobs disabled May 2026 |
| Database Engineering Sprint Reporting | 2024-03-08 | Reads DBA_VCC_COST. Older copy also exists (2023-09-15) |
| Query Performance Dashboard | 2024-03-07 | Stale data — DBA_VCC_MEMSQL jobs disabled May 2026 |
| KAPP Workflow History | 2024-03-07 | Stale data — DBA_VCC_MEMSQL jobs disabled May 2026 |
| KAPP Client Growth | 2024-02-28 | Stale data. Older copy also exists (2023-11-16) |
| KAPP API Query Reporting | 2024-02-23 | Stale data — DBA_VCC_MEMSQL jobs disabled May 2026 |
| KAPP Client Utilisation and Growth Report | 2024-02-22 | Reads DBA_VCC_COST — **high risk, name suggests client-facing** |
| AWS DataTransfer AZ Bytes Report | 2024-02-20 | AWS data transfer costs |
| Nifi API Reporting | 2024-02-15 | NiFi pipeline reporting |

### SingleStore Monitoring — older copies (2024-07-12)

| Dashboard | Last Updated | Notes |
|---|---|---|
| Resource Pool Monitoring | 2024-07-12 | SingleStore monitoring |
| Pipeline Summary | 2024-07-12 | SingleStore monitoring |
| Pipeline Performance | 2024-07-12 | SingleStore monitoring |
| Memory Usage | 2024-07-12 | Older copy — newer version exists (2023-09-07) |
| Historical Workload Monitoring | 2024-07-12 | Older copy — newer version exists (2025-08-07) |
| Disk Usage | 2024-07-12 | SingleStore monitoring |
| Detailed Cluster View By Node | 2024-07-12 | Older copy — newer version exists (2023-09-07) |
| Cluster View | 2024-07-12 | Older copy — newer version exists (2025-06-23) |

### Other Reporting — 2023

| Dashboard | Last Updated | Notes |
|---|---|---|
| Jira Projects Info | 2023-12-08 | Jira sprint data |
| Zabbix Monitoring | 2023-10-27 | Zabbix infrastructure |
| Database Engineering Costs | 2023-10-12 | Older copy — newer version exists (2024-10-15) |
| AWS Cost Report Monthly | 2023-10-06 | Reads DBA_VCC_COST — AWS data stale since Sept 2024 |
| Nifi API Reporting Copy | 2023-09-21 | Stale data — DBA_VCC_MEMSQL jobs disabled May 2026 |
| Database Engineering Sprint Reporting | 2023-09-15 | Older copy — newer version exists (2024-03-08) |
| Memory Usage | 2023-09-07 | SingleStore monitoring |
| Detailed Cluster View By Node | 2023-09-07 | SingleStore monitoring |
| Dashboard Servers Windows | 2023-09-05 | Zabbix — Windows server monitoring |
| SQL SERVER | 2023-09-05 | Zabbix — SQL Server monitoring |
| Microsoft SQL Server | 2023-09-05 | Zabbix — SQL Server monitoring |
| Zabbix Server Dashboard | 2023-09-05 | Zabbix server dashboard |
| AWS RDS Report | 2023-08-21 | RDS inventory. Older copy also exists (2023-08-09) |
| Encore Document Production Runtimes | 2023-08-16 | Encore runtimes. Older copy also exists (2023-07-09) |
| Encore Month End Reporting | 2023-08-10 | Calls REP_MONTHEND — stale. Older copy also exists (2023-07-07) |
| DXM Month End Reporting | 2023-08-10 | Calls REP_MONTHEND — stale. Older copy also exists (2023-07-07) |
| InvestorPress Month End Reporting | 2023-08-10 | Calls REP_MONTHEND — stale. Older copy also exists (2023-07-05) |
| KAPP Month End Reporting | 2023-08-10 | Calls REP_MONTHEND — stale. Older copy also exists (2023-07-05) |
| AWS Security Report | 2023-08-10 | AWS security config |
| KAPP Orphaned and Duplicated Records Report | 2023-08-10 | Older copy — newer version exists (2024-03-26) |
| AWS S3 Report | 2023-08-09 | S3 bucket report. Older copy also exists (2023-07-13) |
| AWS EC2 Report | 2023-08-09 | EC2 inventory. Duplicate also exists same date |
| AWS RDS Report | 2023-08-09 | Older copy — newer version exists (2023-08-21) |
| Home | 2023-08-09 | Default home dashboard |
| AWS Cost Report | 2023-08-09 | AWS cost report |
| Other Services Month End Reporting -- Draft | 2023-07-21 | Draft — calls REP_MONTHEND |
| AWS S3 Report | 2023-07-13 | Older copy — newer version exists (2023-08-09) |
| BNY IIS Log Streams | 2023-07-11 | BNY IIS log data |
| Encore Document Production Runtimes | 2023-07-09 | Older copy — newer version exists (2023-08-16) |
| DXM Month End Reporting | 2023-07-07 | Older copy — newer version exists (2023-08-10) |
| WPv2 Month End Reporting | 2023-07-07 | Older copy — newer version exists (2024-06-20) |
| Encore Month End Reporting | 2023-07-07 | Older copy — newer version exists (2023-08-10) |
| KAPP Month End Reporting | 2023-07-05 | Older copy — newer version exists (2023-08-10) |
| InvestorPress Month End Reporting | 2023-07-05 | Older copy — newer version exists (2023-08-10) |
| Server States | 2023-05-29 | Server state monitoring |

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
| grafana-default-email | Email | `<example@email.com>` | **Placeholder — not configured. No real email set.** |
| alerts-data-operations | Slack | Encrypted token/URL | Active Slack channel — default route for all alerts |
| alert-app-allow2fa-disabled | Slack | Encrypted token/URL | Separate Slack channel — only fires when `Client Auth = Yes` |

## Alert Routing

- Default route → `alerts-data-operations` Slack channel
- If alert label `Client Auth = Yes` → `alert-app-allow2fa-disabled` Slack channel
- Grouped by `grafana_folder` and `alertname`

> The email contact point has a placeholder address and will not deliver. All active alerts route to Slack. The actual Slack webhook URLs are encrypted in the database — need Grafana admin login to view.

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

- [x] ~~What is the Grafana URL and port?~~ — https://ew1r-rep-01 on port 443
- [x] ~~What datasources are configured?~~ — 21 datasources confirmed, see above
- [x] ~~Which dashboards are actively used?~~ — 74 dashboards total confirmed (query 9.5, 2026-07-07). 10 updated in 2025 — actively used. Several duplicate dashboard names exist across folders — older versions not cleaned up.
- [x] ~~Who has admin access to Grafana?~~ — tashvir.babulal, yogeshwar.phull, rayhaan.suleyman, donovan.vangraan
- [x] ~~Is Grafana version current or end-of-life?~~ — v9.5.2, LTS, not latest but supported
- [ ] Are any dashboards client-facing or SLA-related? — Month End Reporting and KAPP Client reports are candidates — confirm with tashvir/rayhaan
- [ ] What contact points are configured for Grafana alert rules? — Check via Grafana UI or grafana.ini
- [ ] Is InfluxDB datasource still active — URL not stored in db, needs confirmation
