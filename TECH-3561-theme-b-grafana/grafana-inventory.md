# Grafana Inventory — EW1R-REP-01

> Status: COMPLETE — validated live from grafana.db via xp_cmdshell/Python 2026-07-21. Dashboard count confirmed 74.

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
| lunga.ndzimande | Lunga Ndzimande | lunga.ndzimande@kurtosys.com | Yes | 2026-07-21 — investigation only, created 2026-07-20 |

> 3 admins actively using Grafana as of June 2026: tashvir.babulal, yogeshwar.phull, rayhaan.suleyman.
> 2 admins inactive: donovan.vangraan (last seen Nov 2024 — credentials still in 4 Zabbix datasources, needs rotation) and default admin account (last seen Nov 2024 — should be disabled).
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

> Validated 2026-07-21 from live grafana.db query. SingleStore Monitoring (v2) does not exist — all SingleStore dashboards are in one folder.

| Folder | Notes |
|---|---|
| General | Ungrouped dashboards — default Grafana folder |
| General Reporting | Top-level reporting folder |
| SingleStore Monitoring | All SingleStore dashboards — active and older copies in same folder |
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

> Total: 74 dashboards — confirmed live from grafana.db 2026-07-21.
> SingleStore Monitoring (v2) folder does not exist — all SingleStore dashboards are in one folder with duplicate titles.
> Amazon EC2 dashboard created and deleted 2026-07-21 by lunga.ndzimande during investigation — accidental, not a production dashboard.

### General (ungrouped)

| Dashboard | Created | Last Updated | Status | Notes |
|---|---|---|---|---|
| Dashboard Servers Windows | 2023-09-05 | 2023-09-05 | ⚠️ Stale credentials | Zabbix — uses donovan.vangraan credentials |
| Grafana Dashboard Exporter/Importer | 2024-10-29 | 2024-10-29 | ✅ Active | Admin utility |
| Home | 2023-08-09 | 2023-08-09 | ✅ Active | Default home dashboard |
| Microsoft SQL Server | 2023-09-05 | 2023-09-05 | ⚠️ Stale credentials | Zabbix — uses donovan.vangraan credentials |
| SQL SERVER | 2023-09-05 | 2023-09-05 | ⚠️ Stale credentials | Zabbix — uses donovan.vangraan credentials |
| Zabbix Server Dashboard | 2023-09-05 | 2023-09-05 | ⚠️ Stale credentials | Zabbix — uses donovan.vangraan credentials |

### AWS

| Dashboard | Created | Last Updated | Status | Notes |
|---|---|---|---|---|
| AWS Cost Report | 2023-07-17 | 2023-08-09 | ❌ Broken | AWS entity cost data frozen at 2024-09-22 — single row only. DBA_VCC_AWS_DAILY_CHECKS step silently failing |
| AWS Cost Report Monthly | 2023-10-06 | 2023-10-06 | ❌ Broken | Same root cause — AWS entity cost frozen Sept 2024 |
| AWS EC2 Report | 2023-08-09 | 2023-08-09 | ⚠️ Stale | No recent updates |
| AWS RDS Report | 2023-08-09 | 2023-08-09 | ⚠️ Stale | No recent updates |
| AWS S3 Report | 2023-06-21 | 2023-07-13 | ⚠️ Stale | Older copy — newer in Database Engineering AWS Reports |
| AWS Security Report | 2023-08-09 | 2023-08-10 | ⚠️ Stale | No recent updates |

### Atlassian Reporting

| Dashboard | Created | Last Updated | Status | Notes |
|---|---|---|---|---|
| Database Engineering Sprint Reporting | 2024-03-08 | 2024-03-08 | ✅ Active | Reads DBA_VCC_COST |
| Jira Projects Info | 2023-12-08 | 2023-12-08 | ⚠️ Stale | No new Jira data since Dec 2023 |

### Database Engineering AWS Reports

| Dashboard | Created | Last Updated | Status | Notes |
|---|---|---|---|---|
| AWS DataTransfer AZ Bytes Report | 2024-01-28 | 2024-02-20 | ⚠️ Stale | No recent updates |
| AWS EC2 Report | 2023-08-09 | 2023-08-09 | ⚠️ Stale | Duplicate — also in AWS folder |
| AWS RDS Report | 2023-08-09 | 2023-08-21 | ⚠️ Stale | Duplicate — also in AWS folder |
| AWS S3 Report | 2023-08-09 | 2023-08-09 | ⚠️ Stale | Duplicate — also in AWS folder |

### Database Engineering Month End Reporting

| Dashboard | Created | Last Updated | Status | Notes |
|---|---|---|---|---|
| Database Engineering Costs | 2024-01-10 | 2024-10-15 | ✅ Active | Reads DBA_VCC_COST — active |
| DXM Month End Reporting | 2023-08-09 | 2023-08-10 | ⚠️ Stale | Duplicate — also in Month End Reporting |
| Encore Month End Reporting | 2023-08-09 | 2023-08-10 | ⚠️ Stale | Duplicate — also in Month End Reporting |
| InvestorPress Month End Reporting | 2023-08-09 | 2023-08-10 | ⚠️ Stale | Duplicate — also in Month End Reporting |
| KAPP Month End Reporting | 2023-08-09 | 2023-08-10 | ⚠️ Stale | Duplicate — also in Month End Reporting |
| WPv2 Month End Reporting | 2023-08-09 | 2024-06-20 | ❌ Broken | WPv2 decommissioned — calls dead stored proc |

### Database Engineering Reports

| Dashboard | Created | Last Updated | Status | Notes |
|---|---|---|---|---|
| Database Engineering Costs | 2023-10-06 | 2023-10-12 | ⚠️ Stale | Older copy — newer version in Database Engineering Month End Reporting (2024-10-15) |
| Database Engineering Sprint Reporting | 2023-07-10 | 2023-09-15 | ⚠️ Stale | Older copy — newer version in Atlassian Reporting (2024-03-08) |

### Encore

| Dashboard | Created | Last Updated | Status | Notes |
|---|---|---|---|---|
| BNY IIS Log Streams | 2023-07-11 | 2023-07-11 | ❌ Broken | Encore IIS logs frozen at 2024-09-23 — confirmed from INFO_AWS_Encore_Cloudwatch_IIS_Logs. BNY Mellon — confirm if client-facing |
| Encore Document Production Runtimes | 2023-07-09 | 2023-07-09 | ⚠️ Stale | Older copy — newer version in Encore Reporting (2023-08-16) |

### Encore Reporting

| Dashboard | Created | Last Updated | Status | Notes |
|---|---|---|---|---|
| Encore Document Production Runtimes | 2023-08-11 | 2023-08-16 | ❌ Broken | Encore IIS log data frozen at 2024-09-23 — DBA_VCC_AWS_DAILY_CHECKS step silently failing |

### General Reporting

| Dashboard | Created | Last Updated | Status | Notes |
|---|---|---|---|---|
| Server States | 2023-05-29 | 2023-05-29 | ⚠️ Stale | No recent updates |

### KAPP

| Dashboard | Created | Last Updated | Status | Notes |
|---|---|---|---|---|
| KAPP Client Growth | 2023-07-09 | 2023-11-16 | ⚠️ Stale | Older copy — newer version in KAPP Reporting (2024-02-28) |
| KAPP Client Utilisation and Growth Report | 2023-07-14 | 2024-02-22 | ❌ Broken + High risk | Reads DBA_VCC_COST — data frozen May 2026 (MemSQL root cause). Name suggests client-facing — confirm with tashvir/rayhaan |
| KAPP Orphaned and Duplicated Records Report | 2023-08-10 | 2023-08-10 | ⚠️ Stale | Older copy — newer version in KAPP Reporting (2024-03-26) |

### KAPP Client Reporting

| Dashboard | Created | Last Updated | Status | Notes |
|---|---|---|---|---|
| KAPP Client Config | 2024-09-02 | 2024-09-02 | ⚠️ Stale | DBA_VCC_MEMSQL jobs disabled May 2026 |
| NTAM Workflow by workflowRunId | 2025-09-07 | 2025-09-07 | ✅ Active | Actively maintained |

### KAPP Reporting

| Dashboard | Created | Last Updated | Status | Notes |
|---|---|---|---|---|
| Prod US Document Generation Run Metrics | 2025-10-22 | 2025-10-29 | ✅ Active | Actively maintained |
| Prod UK Document Generation Run Metrics | 2025-10-22 | 2025-10-29 | ✅ Active | Actively maintained |
| Prod EU Document Generation Run Metrics | 2025-10-22 | 2025-10-29 | ✅ Active | Actively maintained |
| Release Document Generation Run Metrics | 2025-10-22 | 2025-10-29 | ✅ Active | Actively maintained |
| Development Document Generation Run Metrics | 2025-10-22 | 2025-10-29 | ✅ Active | Actively maintained |
| Detailed KAPP Workflow Document Generation Stats | 2025-07-25 | 2025-08-18 | ✅ Active | Actively maintained |
| KAPP Client Application Auth Config | 2024-10-22 | 2024-10-29 | ⚠️ Stale | DBA_VCC_MEMSQL jobs disabled May 2026 |
| KAPP Dataset Query and Source Execution | 2024-11-19 | 2024-11-20 | ⚠️ Stale | DBA_VCC_MEMSQL jobs disabled May 2026 |
| KAPP Dataset Query Execution | 2024-10-18 | 2024-11-07 | ⚠️ Stale | DBA_VCC_MEMSQL jobs disabled May 2026 |
| KAPP Dataset Lambdas Time Outs | 2024-10-23 | 2024-10-23 | ⚠️ Stale | DBA_VCC_MEMSQL jobs disabled May 2026 |
| KAPP Workflow Times History | 2024-06-11 | 2024-06-12 | ⚠️ Stale | DBA_VCC_MEMSQL jobs disabled May 2026 |
| KAPP Orphaned and Duplicated Records Report | 2023-08-10 | 2024-03-26 | ⚠️ Stale | DBA_VCC_MEMSQL jobs disabled May 2026 |
| KAPP API Error Reporting | 2024-03-05 | 2024-03-11 | ⚠️ Stale | DBA_VCC_MEMSQL jobs disabled May 2026 |
| KAPP Workflow History | 2024-02-28 | 2024-03-07 | ⚠️ Stale | DBA_VCC_MEMSQL jobs disabled May 2026 |
| KAPP Client Growth | 2024-02-28 | 2024-02-28 | ⚠️ Stale | DBA_VCC_MEMSQL jobs disabled May 2026 |
| KAPP API Query Reporting | 2024-02-16 | 2024-02-23 | ⚠️ Stale | DBA_VCC_MEMSQL jobs disabled May 2026 |
| Nifi API Reporting | 2023-08-24 | 2024-02-15 | ✅ Active | NiFi data confirmed current — INFO_AWS_Nifi_Loader_API_Detail latest 2026-07-21 |
| Nifi API Reporting Copy | 2023-09-21 | 2023-09-21 | ⚠️ Stale | Duplicate copy |

### Monitoring

| Dashboard | Created | Last Updated | Status | Notes |
|---|---|---|---|---|
| Zabbix Monitoring | 2023-10-24 | 2023-10-27 | ⚠️ Stale credentials | Uses donovan.vangraan credentials |

### Month End Reporting

| Dashboard | Created | Last Updated | Status | Notes |
|---|---|---|---|---|
| DXM Month End Reporting | 2023-07-06 | 2023-07-07 | ⚠️ Stale | No recent updates |
| Encore Month End Reporting | 2023-07-05 | 2023-07-07 | ⚠️ Stale | No recent updates |
| InvestorPress Month End Reporting | 2023-07-05 | 2023-07-05 | ⚠️ Stale | No recent updates |
| KAPP Month End Reporting | 2023-07-04 | 2023-07-05 | ⚠️ Stale | No recent updates |
| Other Services Month End Reporting -- Draft | 2023-07-07 | 2023-07-21 | ❌ Broken | Draft — never completed |
| WPv2 Month End Reporting | 2023-07-06 | 2023-07-07 | ❌ Broken | WPv2 decommissioned |

### Performance Dashboards

| Dashboard | Created | Last Updated | Status | Notes |
|---|---|---|---|---|
| Query Performance Dashboard | 2024-03-04 | 2024-03-07 | ⚠️ Stale | DBA_VCC_MEMSQL jobs disabled May 2026 |

### SingleStore Monitoring

> All SingleStore dashboards are in this one folder. Duplicate titles exist — older and newer copies both present.

| Dashboard | Created | Last Updated | Status | Notes |
|---|---|---|---|---|
| Cluster View | 2023-06-13 | 2025-06-23 | ✅ Active | Current version — original dashboard updated in place |
| Cluster View | 2024-07-12 | 2024-07-12 | ⚠️ Stale | Duplicate — same folder |
| Detailed Cluster View By Node | 2023-06-13 | 2023-09-07 | ⚠️ Stale | Original copy |
| Detailed Cluster View By Node | 2024-07-12 | 2024-07-12 | ⚠️ Stale | Duplicate — same folder |
| Disk Usage | 2024-07-12 | 2024-07-12 | ⚠️ Stale | No recent updates |
| Historical Workload Monitoring | 2023-06-13 | 2025-08-07 | ✅ Active | Current version — original dashboard updated in place |
| Historical Workload Monitoring | 2024-07-12 | 2024-07-12 | ⚠️ Stale | Duplicate — same folder |
| Memory Usage | 2023-06-13 | 2023-09-07 | ⚠️ Stale | Original copy |
| Memory Usage | 2024-07-12 | 2024-07-12 | ⚠️ Stale | Duplicate — same folder |
| Pipeline Performance | 2024-07-12 | 2024-07-12 | ⚠️ Stale | No recent updates |
| Pipeline Summary | 2024-07-12 | 2024-07-12 | ⚠️ Stale | No recent updates |
| Query History | 2024-07-12 | 2025-08-07 | ✅ Active | Actively maintained |
| Resource Pool Monitoring | 2024-07-12 | 2024-07-12 | ⚠️ Stale | No recent updates |

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
- [x] ~~Which dashboards are actively used?~~ — 74 dashboards confirmed live from grafana.db 2026-07-21. 11 updated in 2025+ — actively used. SingleStore Monitoring (v2) folder confirmed not to exist — all SingleStore dashboards in one folder with duplicate titles. Amazon EC2 dashboard created and deleted 2026-07-21 by lunga.ndzimande — accidental investigation artefact.
- [x] ~~Who has admin access to Grafana?~~ — tashvir.babulal, yogeshwar.phull, rayhaan.suleyman, donovan.vangraan
- [x] ~~Is Grafana version current or end-of-life?~~ — v9.5.2, LTS, not latest but supported
- [ ] Are any dashboards client-facing or SLA-related? — Month End Reporting and KAPP Client reports are candidates — confirm with tashvir/rayhaan
- [x] ~~What contact points are configured for Grafana alert rules?~~ — 3 contact points confirmed: alerts-data-operations (Slack, active), alert-app-allow2fa-disabled (Slack, active), email (placeholder — not configured, will not deliver)
- [ ] Is InfluxDB datasource still active — URL not stored in db, needs confirmation

---

## Conclusion — Recommendations and Proposed Solutions

---

### 1. Ex-Employee Credentials in Zabbix Datasources — Immediate Security Risk

**What we found:**
All 4 Zabbix datasources in Grafana are configured using credentials belonging to **donovan.vangraan** — an ex-employee who was last seen on this server in November 2024. His account still has active database access to Zabbix MySQL. This is a live security risk that exists today, completely independent of the decommission decision.

**Supporting evidence:**
- 4 Zabbix datasources confirmed in grafana.db: Zabbix Nonprod old, zabbix-server-data.shnonprd, Zabbix Prod Old, zabbix-server-data.shprd
- donovan.vangraan last seen: 2024-11-13 — no longer active
- donovan.vangraan still holds Grafana admin rights
- Default admin account also still active — last seen 2024-11-29

**Proposed solution:**
- Revoke donovan.vangraan's Grafana admin access immediately
- Rotate the Zabbix MySQL credentials used in all 4 datasources — replace with a service account
- Disable the default admin account — it should never be left active in a production-adjacent system
- This must happen now — not as part of decommission planning

---

### 2. Zabbix Datasources — This Server Is the Middleman, Cut It Out

**What we found:**
Grafana on this server reads from 4 Zabbix MySQL databases to power Zabbix monitoring dashboards (Dashboard Servers Windows, SQL SERVER, Microsoft SQL Server, Zabbix Server Dashboard). This server is acting as a middleman — it sits between the user and Zabbix, adding no value. Zabbix already monitors the infrastructure directly. The dashboards can connect to Zabbix directly without this server in the middle.

**Supporting evidence:**
- 4 Zabbix-related dashboards confirmed: Dashboard Servers Windows (2023-09-05), SQL SERVER (2023-09-05), Microsoft SQL Server (2023-09-05), Zabbix Server Dashboard (2023-09-05)
- Zabbix Nonprod old and Zabbix Prod Old datasources — pointing at dead/old Zabbix instances
- alexanderzobnin-zabbix-app plugin installed — reads Zabbix MySQL directly
- Zabbix agent already running on EW1R-REP-01 (port 10050) — Zabbix watches this server directly

**Proposed solution:**
- Migrate the 4 Zabbix dashboards to **Amazon Managed Grafana** and connect directly to the current Zabbix MySQL instances (10.72.8.186 and 10.120.8.51)
- Remove the 2 dead Zabbix datasources (Zabbix Nonprod old pointing at 10.72.8.191, Zabbix Prod Old pointing at 10.120.8.120)
- Use a proper service account for the Zabbix MySQL connection — not a personal account
- This eliminates EW1R-REP-01 from the Zabbix monitoring chain entirely

---

### 3. Stale and Broken Dashboards — Multiple Root Causes, All Silent

**What we found:**
Three separate silent failures are causing dashboards to show stale or wrong data. None of them fired an alert. None were noticed until this investigation.

**Root cause 1 — MemSQL jobs disabled May 2026:**
- 14 dashboards reading from DBA_VCC_MEMSQL have been stale since May 2026
- DBA_VCC_COST collection also broken as a downstream casualty — all SP_INFO_KAPP_CLIENT_* procs depend on DBA_VCC_MEMSQL.BAS_Ping_Stat to get live servers. With MemSQL jobs disabled, zero servers returned, zero rows written, job reports succeeded
- KAPP Client Utilisation and Growth Report showing data frozen at 2026-05-04 — possible client-facing dashboard

**Root cause 2 — DBA_VCC_AWS_DAILY_CHECKS step silently failing since Sept 2024:**
- INFO_AWS_Encore_Cloudwatch_IIS_Logs frozen at 2024-09-23 — confirmed from live query 2026-07-21
- INFO_AWS_Entity_Cost frozen at 2024-09-22 — single row only, archive also frozen at 2024-06-21
- AWS Cost Report and AWS Cost Report Monthly dashboards showing data that is 10 months stale
- BNY IIS Log Streams (Encore) showing data that is 10 months stale — BNY Mellon is an institutional client
- CATCH blocks in DBA_VCC_AWS_DAILY_CHECKS swallow the error — job reports succeeded every day

**What is still active and current (confirmed 2026-07-21):**
- KAPP API query tracking — INFO_AWS_KAPP_Query_API_Detail latest 2026-07-21
- NiFi pipeline monitoring — INFO_AWS_Nifi_Loader_API_Detail latest 2026-07-21

**Proposed solution:**
- Notify tashvir.babulal, rayhaan.suleyman, yogeshwar.phull of all three silent failures immediately
- Identify and fix the broken step in DBA_VCC_AWS_DAILY_CHECKS — add explicit error handling so step failures surface as job failures
- Add a visible banner to all affected dashboards stating data is stale and from what date
- Do not migrate broken dashboards to Amazon Managed Grafana — fix or retire them first

---

### 4. Duplicate Datasources and Dashboards — Cleanup Before Migration

**What we found:**
There are 2 DBA_VCC datasource entries pointing at the same target with different UIDs. There are multiple duplicate dashboards sitting in different folders — older versions that were never cleaned up. Migrating this mess as-is to Amazon Managed Grafana will create confusion.

**Supporting evidence:**
- DBA_VCC datasource: UIDs a082f27e and e8597015 — both point to localhost DBA_VCC
- Multiple dashboards with identical names in different folders: AWS RDS Report, Encore Document Production Runtimes, WPv2 Month End Reporting, KAPP Orphaned and Duplicated Records Report, and others
- KAPP Monitoring and monitoring datasources — both point to 10.120.8.208, same database

**Proposed solution:**
- Audit all 74 dashboards before migration — identify which version of each duplicate is the current one
- Retire all older duplicate dashboards
- Consolidate the 2 DBA_VCC datasources into 1 before migration
- Target: migrate only the dashboards that are actively used and have live data

---

### 5. Overall Grafana Recommendation

**This server should not be running Grafana.** It is a non-production EC2 instance running a self-hosted Grafana 9.5.2 that requires manual patching, has ex-employee credentials active, and has no proper alerting configured. The platform is in AWS — Grafana should be too.

**Proposed replacement: Amazon Managed Grafana**
- AWS manages the infrastructure, patching, and availability
- Integrates natively with CloudWatch, RDS, and other AWS services
- Supports the same datasources (MySQL, MSSQL, Zabbix, JSON API)
- Proper IAM-based access control — no more personal account credentials in datasources
- Existing dashboards can be exported as JSON and imported directly

**Migration order:**
1. Fix credentials first — rotate donovan.vangraan, disable default admin
2. Audit and retire stale/duplicate dashboards
3. Set up Amazon Managed Grafana workspace
4. Migrate active dashboards one folder at a time
5. Re-point datasources to their targets directly
6. Validate all alerts are firing correctly in the new environment
7. Decommission Grafana on EW1R-REP-01
