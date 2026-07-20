# Theme B — Grafana Inventory
**Ticket:** TECH-3479 — EW1R-REP-01  
**Date:** 2026-07-17 (validated 2026-07-17 — datasources, users, alert rules, dashboards all confirmed from live grafana.db)  
**Prepared by:** TECH-3479 Investigation  
**Source data:** TECH-3561 discovery sprint — grafana.db extracted via Python/SQLite on 2026-07-07  
**Server:** EW1R-REP-01 — 10.72.8.216 — Grafana 9.5.2 — port 443 HTTPS

---

## The One-Line Answer

> **Grafana is actively used and cannot be decommissioned without a migration plan.**  
> 10 dashboards are actively maintained in 2025. 3 active admins logged in as recently as June 2026. 4 Zabbix datasources use a dead employee's credentials. 14 dashboards are showing stale data since May 2026 — nobody has flagged it.

---

## 1. Access Details

| Property | Value |
|---|---|
| URL (hostname) | https://ew1r-rep-01 |
| URL (IP) | https://10.72.8.216 |
| Port | 443 (HTTPS — confirmed via netstat, PID 3844 = grafana.exe) |
| Version | 9.5.2 (confirmed from C:\Program Files\GrafanaLabs\svc-9.5.2.0) |
| Database | C:\Program Files\GrafanaLabs\grafana\data\grafana.db (162 MB) |
| External access | Requires VPN or RDP — not reachable from outside network |

---

## 2. Users — 8 Total

| Login | Name | Role | Last Seen | Status |
|---|---|---|---|---|
| tashvir.babulal | Tashvir Babulal | Admin | 2026-06-09 | ✅ Active |
| yogeshwar.phull | Yogeshwar Phull | Admin | 2026-06-22 | ✅ Active |
| rayhaan.suleyman | Rayhaan Suleyman | Admin | 2026-07-07 | ✅ Active |
| ram.jeyaraman | Ram Jeyaraman | Viewer | 2026-07-15 | ✅ Active — most recently logged in of all users |
| jason.wolmarans | Jason Wolmarans | Viewer | 2025-02-12 | ✅ Active |
| admin | (default) | Admin | 2024-11-29 | ⚠️ Inactive — default account, should be disabled |
| donovan.vangraan | Donovan van Graan | Admin | 2024-11-13 | ⚠️ Inactive — credentials still used in 4 Zabbix datasources |
| sunil.odedra | Sunil Odedra | Viewer | 2023-07-12 | ⚠️ Inactive since Jul 2023 |

**Key findings:**
- 3 active admins — tashvir, yogeshwar, rayhaan — all logged in June 2026. These are the key contacts for any migration or decommission decision.
- donovan.vangraan has not logged in since Nov 2024. His personal account (`donovan.vangraan`) is used as the MySQL DB login across all 4 Zabbix datasources — not just a Grafana credential, an actual database user. Active security risk.
- All KAPP MySQL datasources (Dev, Rel, UK/EU/US Prod, Monitoring) connect using `root` — root credentials on production MySQL instances is a security finding.
- Default `admin` account is still enabled with a generic email (admin@localhost) — should be disabled.

---

## 3. Datasources — 21 Total

| UID | Name | Type | Host / IP | Database | DB User | Status |
|---|---|---|---|---|---|
| a082f27e | DBA_VCC | mssql | localhost | DBA_VCC | grafana | ✅ Active — primary VCC datasource |
| e8597015 | DBA_VCC | mssql | localhost | DBA_VCC | grafana | ⚠️ Duplicate — same target, same user, different UID. Dashboards split across both |
| da173cae | KAPP Dev | mysql | 10.61.11.70:3306 | metrics | root | ⚠️ Active — root credentials on production MySQL |
| d1679f57 | KAPP Rel | mysql | 10.77.3.236 | metrics | root | ⚠️ Active — root credentials |
| cd097e22 | KAPP UK Prod | mysql | 10.121.29.82 | metrics | root | ⚠️ Active — root credentials on production MySQL |
| e792d174 | KAPP EU Prod | mysql | 10.125.6.134 | metrics | root | ⚠️ Active — root credentials on production MySQL |
| db3d6c01 | KAPP US Prod | mysql | 10.128.30.6 | metrics | root | ⚠️ Active — root credentials on production MySQL |
| f4830a0f | KAPP Monitoring | mysql | 10.120.8.208 | metrics | root | ⚠️ Active — root credentials |
| dce83066 | monitoring | mysql | 10.120.8.208 | metrics | root | ⚠️ Duplicate of KAPP Monitoring — same IP, same user |
| f2ca52be | MySQL | mysql | 10.77.3.236:3306 | metrics | root | ⚠️ Likely duplicate of KAPP Rel — same IP |
| d8b0939b | SingleStore-Dev | mysql | 10.61.0.95 | UDM__ | FundPressDataReader | ✅ Active |
| f1d911af | SingleStore-Release | mysql | 10.77.6.161 | UDM__ | FundPressDataReader | ✅ Active |
| a6046586 | SingleStore-Production-UK | mysql | 10.121.22.219 | UDM__ | FundPressDataReader | ✅ Active — production |
| df309b44 | SingleStore-Production-EU | mysql | 10.125.12.126 | UDM__ | FundPressDataReader | ✅ Active — production |
| bfe8f780 | SingleStore-Production-US | mysql | 10.128.24.122 | UDM__ | FundPressDataReader | ✅ Active — production |
| aafbf2f7 | Zabbix Nonprod old | mysql | 10.72.8.191 | zabbix | donovan.vangraan | ⚠️ Personal account used as DB login — inactive since Nov 2024 |
| b10bf74c | zabbix-server-data.shnonprd | mysql | 10.72.8.186 | zabbix | donovan.vangraan | ⚠️ Personal account used as DB login — inactive since Nov 2024 |
| dbafc322 | Zabbix Prod Old | mysql | 10.120.8.120 | zabbix | donovan.vangraan | ⚠️ Personal account used as DB login — inactive since Nov 2024 |
| d68a35f0 | zabbix-server-data.shprd | mysql | 10.120.8.51 | zabbix | donovan.vangraan | ⚠️ Personal account used as DB login — inactive since Nov 2024 |
| b7838f71 | JSON API | marcusolsson-json-datasource | 10.125.9.192:8443 | — | — | ✅ Active — NiFi API, tlsSkipVerify=true |
| bae6c95e | CloudWatch | cloudwatch | — | — | — | ✅ Active — AWS CloudWatch via IAM role |
| aa82f021 | InfluxDB | influxdb | — | — | — | ⚠️ Empty URL — connection details unconfirmed |

**Key findings:**
- DBA_VCC has 2 entries (UIDs a082f27e and e8597015) pointing to the same localhost target. Dashboards are split across both UIDs — this must be resolved before migration or dashboards will break.
- 4 Zabbix datasources all use donovan.vangraan credentials. He has not logged in since Nov 2024. Credentials need rotation immediately.
- Grafana connects directly to 6 production MySQL instances (KAPP UK/EU/US Prod, SingleStore UK/EU/US Prod). These connections break if the server is decommissioned or network access is removed.
- InfluxDB datasource has no URL stored — purpose and connectivity unconfirmed.

### Duplicate DBA_VCC — Proposed Resolution

| Issue | Detail |
|---|---|
| Problem | Two DBA_VCC datasource entries exist with UIDs a082f27e and e8597015 — same localhost target, different UIDs |
| Risk | Dashboards referencing the wrong UID will silently break after migration if only one UID is migrated |
| Resolution | Before migration: run a dashboard scan to identify which dashboards reference each UID. Consolidate all dashboards onto one UID. Delete the duplicate entry. |
| Owner | tashvir.babulal / rayhaan.suleyman — Grafana admin required |

---

## 4. Dashboards — 74 Total

### Summary by Status

| Status | Count |
|---|---|
| ✅ Active — updated 2025, live data | 10 |
| ⚠️ Stale — data frozen since May 2026 (MemSQL jobs disabled) | 14 |
| ⚠️ Stale — month-end dashboards, no fresh data | 6 |
| ⚠️ Reads DBA_VCC_COST — data stale since May 2026 | 4 |
| ⚠️ Duplicate — older copy of another dashboard | 18 |
| ⚠️ Other stale / broken | 22 |

---

### Active Dashboards — Updated 2025

| Dashboard | Datasource | Last Updated | Status |
|---|---|---|---|
| Prod US Document Generation Run Metrics | SingleStore-Production-US | 2025-10-29 | ✅ Active |
| Prod UK Document Generation Run Metrics | SingleStore-Production-UK | 2025-10-29 | ✅ Active |
| Prod EU Document Generation Run Metrics | SingleStore-Production-EU | 2025-10-29 | ✅ Active |
| Release Document Generation Run Metrics | SingleStore-Release | 2025-10-29 | ✅ Active |
| Development Document Generation Run Metrics | SingleStore-Dev | 2025-10-29 | ✅ Active |
| NTAM Workflow by workflowRunId | SingleStore-Production-US | 2025-09-07 | ✅ Active |
| Detailed KAPP Workflow Document Generation Stats | SingleStore-Dev | 2025-08-18 | ✅ Active |
| Query History | KAPP Monitoring | 2025-08-07 | ✅ Active |
| Historical Workload Monitoring | KAPP Monitoring, SingleStore-Production-UK | 2025-08-07 | ✅ Active |
| Cluster View | SingleStore-Production-UK | 2025-06-23 | ✅ Active |

> These 10 dashboards are actively maintained and read from live production datasources. They must be migrated — they cannot be retired.

---

### Stale Dashboards — MemSQL Jobs Disabled May 2026

These 14 dashboards read from DBA_VCC which was fed by the MemSQL collection jobs. Jobs disabled May 2026 — data frozen since then.

| Dashboard | Datasource | Last Updated | Status |
|---|---|---|---|
| KAPP Dataset Query and Source Execution | DBA_VCC | 2024-11-20 | ⚠️ Stale since May 2026 |
| KAPP Dataset Query Execution | DBA_VCC | 2024-11-07 | ⚠️ Stale since May 2026 |
| KAPP Client Application Auth Config | DBA_VCC | 2024-10-29 | ⚠️ Stale since May 2026 |
| KAPP Dataset Lambdas Time Outs | DBA_VCC | 2024-10-23 | ⚠️ Stale since May 2026 |
| KAPP Client Config | DBA_VCC | 2024-09-02 | ⚠️ Stale since May 2026 |
| KAPP Workflow Times History | DBA_VCC | 2024-06-12 | ⚠️ Stale since May 2026 |
| KAPP Orphaned and Duplicated Records Report | DBA_VCC | 2024-03-26 | ⚠️ Stale since May 2026 |
| KAPP API Error Reporting | DBA_VCC | 2024-03-11 | ⚠️ Stale since May 2026 |
| Query Performance Dashboard | DBA_VCC | 2024-03-07 | ⚠️ Stale since May 2026 |
| KAPP Workflow History | DBA_VCC | 2024-03-07 | ⚠️ Stale since May 2026 |
| KAPP API Query Reporting | DBA_VCC | 2024-02-23 | ⚠️ Stale since May 2026 |
| Nifi API Reporting | DBA_VCC | 2024-02-15 | ⚠️ Stale since May 2026 |
| Nifi API Reporting Copy | DBA_VCC, KAPP Dev | 2023-09-21 | ⚠️ Stale copy |
| WPv2 Month End Reporting | DBA_VCC | 2024-06-20 | ⚠️ Stale — WPv2 decommissioned |

> June 2026 month-end reporting was produced from stale data. Nobody noticed. No alert fired.

---

### DBA_VCC_COST Dashboards — Billing Data Stale Since May 2026

| Dashboard | Datasource | Last Updated | Risk |
|---|---|---|---|
| KAPP Client Utilisation and Growth Report | DBA_VCC, KAPP Dev | 2024-02-22 | ⚠️ High — name suggests client-facing. Reads billing data stale since May 2026 |
| Database Engineering Costs | DBA_VCC | 2024-10-15 | ⚠️ Internal — stale billing data |
| Database Engineering Sprint Reporting | DBA_VCC | 2024-03-08 | ⚠️ Internal |
| AWS Cost Report Monthly | DBA_VCC, KAPP Dev | 2023-10-06 | ⚠️ AWS cost data stale since Sept 2024 |

> KAPP Client Utilisation and Growth Report is the highest risk dashboard on the server. If it is client-facing, stakeholders must be notified that billing data has been stale since 4 May 2026. Confirm with tashvir.babulal / rayhaan.suleyman.

---

### Month-End Dashboards — No Fresh Data

| Dashboard | Datasource | Last Updated | Status |
|---|---|---|---|
| Encore Month End Reporting | DBA_VCC | 2023-08-10 | ⚠️ Stale — calls REP_MONTHEND |
| DXM Month End Reporting | DBA_VCC | 2023-08-10 | ⚠️ Stale — calls REP_MONTHEND |
| InvestorPress Month End Reporting | DBA_VCC | 2023-08-10 | ⚠️ Stale — InvestorPress decommissioned |
| KAPP Month End Reporting | DBA_VCC | 2023-08-10 | ⚠️ Stale — calls REP_MONTHEND |
| Other Services Month End Reporting -- Draft | DBA_VCC | 2023-07-21 | ⚠️ Draft — never completed |
| WPv2 Month End Reporting (older copy) | DBA_VCC | 2023-07-07 | ⚠️ Stale — WPv2 decommissioned |

> Who calls REP_MONTHEND_* procedures each month end is still an open question — confirm with tashvir.babulal / rayhaan.suleyman.

---

### Other Notable Dashboards

| Dashboard | Datasource | Last Updated | Notes |
|---|---|---|---|
| BNY IIS Log Streams | DBA_VCC | 2023-07-11 | ⚠️ BNY Mellon — external client? Confirm before decommission |
| Zabbix Monitoring | All 4 Zabbix datasources | 2023-10-27 | ⚠️ All 4 datasources use donovan.vangraan credentials |
| AWS DataTransfer AZ Bytes Report | DBA_VCC | 2024-02-20 | AWS reporting |
| KAPP Client Growth | DBA_VCC | 2024-02-28 | ⚠️ Duplicate — older copy also exists (2023-11-16) |
| Server States | DBA_VCC | 2023-05-29 | Server state monitoring |

---

## 5. Alert Rules — 3 Total

| Alert Name | Datasource | Contact Point | Channel | No Data State | Functional |
|---|---|---|---|---|---|
| Failed Read Queries per Second | DBA_VCC | alerts-data-operations | Slack | NoData | ✅ Yes — last updated 2024-02-07 |
| KAPP Client Config Alert | DBA_VCC | alerts-data-operations | Slack | OK | ✅ Yes — last updated 2025-03-04, but data stale since May 2026 |
| KAPP Client Application Auth Config Alert | DBA_VCC | alert-app-allow2fa-disabled | Slack | OK | ✅ Yes — last updated 2025-03-04, fires when Client Auth = Yes |

---

## 6. Alert Contact Points — 3 Total

| Name | Type | Destination | Status |
|---|---|---|---|
| alerts-data-operations | Slack | Encrypted webhook token | ✅ Active — default route for all alerts |
| alert-app-allow2fa-disabled | Slack | Encrypted webhook token | ✅ Active — fires on Client Auth = Yes label |
| grafana-default-email | Email | `<example@email.com>` | ❌ Broken — placeholder address, will never deliver |

**Alert routing:**
- Default route → `alerts-data-operations` Slack
- If label `Client Auth = Yes` → `alert-app-allow2fa-disabled` Slack
- Grouped by `grafana_folder` and `alertname`

> The email contact point has never been configured. It is a factory placeholder. Any alert that falls through to email will silently fail. The Slack webhook tokens are encrypted in grafana.db — a Grafana admin login is required to view or rotate them.

---

## 7. Installed Plugins

| Plugin | Type | Purpose |
|---|---|---|
| alexanderzobnin-zabbix-app | Datasource | Reads Zabbix MySQL directly |
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

## 8. Active Problems — Fix Now, Independent of Decommission

| # | Problem | Impact | Owner |
|---|---|---|---|
| P1 | 14 dashboards showing stale data since May 2026 | June 2026 month-end reporting impacted silently | tashvir.babulal / yogeshwar.phull |
| P2 | KAPP Client Utilisation and Growth Report reading stale billing data | Possible client-facing — institutional clients may have received stale reports | tashvir.babulal / rayhaan.suleyman |
| P3 | 4 Zabbix datasources using donovan.vangraan as MySQL DB login | His personal account is the actual database user — not just a Grafana credential. Ex-employee, inactive Nov 2024 | Grafana admin + DBA team |
| P3b | All KAPP MySQL datasources connecting as `root` | Root credentials on production MySQL instances (UK/EU/US Prod) — security risk | DBA team |
| P4 | Default admin account still active | Generic account with no owner — should be disabled | Grafana admin |
| P5 | Email contact point is a placeholder | Any alert routed to email will silently fail | Grafana admin |
| P6 | Duplicate DBA_VCC datasource UIDs | Dashboards split across two UIDs — migration will break dashboards if not resolved first | tashvir.babulal / rayhaan.suleyman |
| P7 | InfluxDB datasource has no URL stored | Connection details unconfirmed — unknown if active or dead | DBA team |

---

## 9. Decommission Readiness — Grafana Components

| Component | Count | Status | Decision |
|---|---|---|---|
| Active dashboards (2025) | 10 | Live data, actively maintained | ❌ Must migrate |
| Stale MemSQL dashboards | 14 | Data frozen since May 2026 | ⚠️ Pending Q3 — archive or migrate once MemSQL status confirmed |
| DBA_VCC_COST dashboards | 4 | Billing data stale since May 2026 | ❌ Must migrate — confirm client-facing status first |
| Month-end dashboards | 6 | No fresh data | ⚠️ Confirm consumer then archive or migrate |
| Duplicate dashboards | 18 | Older copies of active dashboards | ✅ Safe to archive |
| donovan.vangraan credentials | 4 datasources | Ex-employee, inactive Nov 2024 | ❌ Rotate immediately |
| Default admin account | 1 | No real owner | ❌ Disable immediately |
| Duplicate DBA_VCC datasource | 1 | Same target, two UIDs | ❌ Consolidate before migration |
| Broken email contact point | 1 | Placeholder — never configured | ❌ Fix or remove |
| InfluxDB datasource | 1 | URL unknown | ⚠️ Confirm before decommission |

---

## 10. Migration Recommendation

Grafana cannot be decommissioned without a migration plan. The recommended path is **Amazon Managed Grafana** or a new EC2 host in the same VPC.

**Migration order:**
1. Resolve duplicate DBA_VCC datasource UIDs — identify which dashboards reference each UID, consolidate onto one, delete the duplicate
2. Rotate donovan.vangraan credentials across all 4 Zabbix datasources
3. Disable default admin account
4. Confirm InfluxDB datasource status — active or dead
5. Confirm KAPP Client Utilisation and Growth Report — client-facing or internal
6. Migrate 10 active dashboards and their datasources to new Grafana host
7. Archive 18 duplicate dashboards — do not migrate
8. Archive stale MemSQL dashboards once Q3 is answered
9. Fix or remove broken email contact point on new host

**Grafana migration is blocked until databases are migrated first** — all datasources point to databases on this server. Grafana must move after the databases move.

---

## 11. Open Questions

| # | Question | Who to Ask | Status |
|---|---|---|---|
| Q9 | Which teams use the Grafana dashboards — engineering, ops, or client-facing? | tashvir.babulal / rayhaan.suleyman | ❌ Open |
| Q13 | Who owns the KAPP monitoring data in DBA_VCC_AWS? Is it used for SLA reporting? | KAPP engineering / platform team | ❌ Open |
| Q14 | Is INFO_AWS_KAPP_Query_API_Detail (563M rows) actively read by any dashboard? | tashvir.babulal | ❌ Open |
| Q21 | If this server went offline today, what would break immediately? | yogeshwar.phull / tashvir.babulal | ❌ Open |
| Q22 | Is any alerting dependent solely on this server — would anyone lose visibility? | yogeshwar.phull / tashvir.babulal | ❌ Open |
| Q35 | Who disabled the DBA_VCC_MEMSQL jobs in May 2026 and why? | yogeshwar.phull / tashvir.babulal | ❌ Open |
| Q36 | Has anyone noticed that DBA_VCC_COST billing data has been stale since 4 May 2026? | tashvir.babulal / rayhaan.suleyman | ❌ Open — must be disclosed immediately |
| Q37 | Is BNY IIS Log Streams dashboard client-facing or internal? | tashvir.babulal / rayhaan.suleyman | ❌ Open |
| Q38 | Is the InfluxDB datasource still active — what does it connect to? | DBA team | ❌ Open |

---

## 12. Definition of Done — Status

| DoD Item | Status |
|---|---|
| All 21 datasources validated: name, UID, type, target, status | ✅ Done |
| All 74 dashboards validated: datasource(s), last updated, status | ✅ Done |
| All 8 users validated: role, last login, active or inactive | ✅ Done |
| All 3 alert rules validated: contact point, functional or broken | ✅ Done |
| Duplicate DBA_VCC UID conflict documented with proposed resolution | ✅ Done |
| Ex-employee Zabbix credentials flagged for rotation with evidence | ✅ Done |
| Default admin account flagged for disabling | ✅ Done |
| Open questions answered or escalated with evidence | ⚠️ Escalated — Q9, Q13, Q14, Q21, Q22, Q35, Q36, Q37, Q38 open |
| Inventory published to Confluence | ⏳ Pending |
