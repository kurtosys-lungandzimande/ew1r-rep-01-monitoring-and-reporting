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

| Dashboard | Folder | Last Updated | Business Critical | Notes |
|---|---|---|---|---|
| Detailed KAPP Workflow Document Generation Stats | KAPP Reporting | 2025-08-18 | **Yes** | Actively maintained |
| Query History | SingleStore Monitoring v2 | 2025-08-07 | **Yes** | Actively maintained |
| Historical Workload Monitoring | SingleStore Monitoring v2 | 2025-08-07 | **Yes** | Actively maintained |
| NTAM Workflow by workflowRunId | KAPP Client Reporting | 2025-09-07 | **Yes** | Very recent — created Sep 2025 |
| Development Document Generation Run Metrics | KAPP Reporting | 2025-10-29 | **Yes** | Actively maintained Oct 2025 |
| Release Document Generation Run Metrics | KAPP Reporting | 2025-10-29 | **Yes** | Actively maintained Oct 2025 |
| Prod UK Document Generation Run Metrics | KAPP Reporting | 2025-10-29 | **Yes** | Production — actively maintained |
| Prod EU Document Generation Run Metrics | KAPP Reporting | 2025-10-29 | **Yes** | Production — actively maintained |
| Prod US Document Generation Run Metrics | KAPP Reporting | 2025-10-29 | **Yes** | Production — actively maintained |
| KAPP Client Utilisation and Growth Report | KAPP Reporting | 2024-02-22 | **Yes** | Client-level reporting |
| KAPP Orphaned and Duplicated Records Report | KAPP Reporting | 2024-03-26 | Yes | Data quality reporting |
| KAPP Dataset Query Execution | KAPP Reporting | 2024-11-07 | Yes | Query execution tracking |
| KAPP Client Application Auth Config | KAPP Reporting | 2024-10-29 | Yes | Auth config reporting |
| KAPP Dataset Lambdas Time Outs | KAPP Reporting | 2024-10-23 | Yes | Lambda timeout monitoring |
| KAPP Dataset Query and Source Execution | KAPP Reporting | 2024-11-20 | Yes | Dataset execution tracking |
| Database Engineering Costs | DB Eng Month End | 2024-10-15 | Yes | Cost tracking |
| WPv2 Month End Reporting | DB Eng Month End | 2024-06-20 | Yes | Month-end business report |
| Nifi API Reporting | KAPP Reporting | 2024-02-15 | Yes | NiFi pipeline reporting |
| KAPP Client Growth | KAPP Reporting | 2024-02-28 | Yes | Client growth tracking |
| KAPP Workflow History | KAPP Reporting | 2024-03-07 | Yes | Workflow history |
| KAPP Workflow Times History | KAPP Reporting | 2024-06-12 | Yes | Workflow timing |
| KAPP API Query Reporting | KAPP Reporting | 2024-02-23 | Yes | API query reporting |
| KAPP API Error Reporting | KAPP Reporting | 2024-03-11 | Yes | API error tracking |
| Cluster View | SingleStore Monitoring v2 | 2025-06-23 | Yes | SingleStore cluster view |
| AWS RDS Report | DB Eng AWS Reports | 2023-08-21 | Medium | RDS inventory |
| AWS DataTransfer AZ Bytes Report | DB Eng AWS Reports | 2024-02-20 | Medium | Data transfer costs |
| Zabbix Monitoring | Monitoring | 2023-10-27 | Medium | Zabbix infrastructure |
| Jira Projects Info | Atlassian Reporting | 2023-12-08 | Medium | Jira sprint data |
| Query Performance Dashboard | Performance Dashboards | 2024-03-07 | Medium | SQL query performance |
| Encore Document Production Runtimes | Encore Reporting | 2023-08-16 | Medium | Encore runtimes |
| BNY IIS Log Streams | Encore | 2023-07-11 | Medium | BNY IIS log data |
| Grafana Dashboard Exporter/Importer | — | 2024-10-29 | No | Admin utility |

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
- [x] ~~Which dashboards are actively used?~~ — 9 dashboards updated Oct/Nov 2025, actively used
- [x] ~~Who has admin access to Grafana?~~ — tashvir.babulal, yogeshwar.phull, rayhaan.suleyman, donovan.vangraan
- [x] ~~Is Grafana version current or end-of-life?~~ — v9.5.2, LTS, not latest but supported
- [ ] Are any dashboards client-facing or SLA-related? — Month End Reporting and KAPP Client reports are candidates — confirm with tashvir/rayhaan
- [ ] What contact points are configured for Grafana alert rules? — Check via Grafana UI or grafana.ini
- [ ] Is InfluxDB datasource still active — URL not stored in db, needs confirmation
