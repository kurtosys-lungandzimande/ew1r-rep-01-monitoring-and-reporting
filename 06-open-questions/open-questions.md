# Open Questions — EW1R-REP-01

> Items that need a second pair of eyes, confirmation from other teams, or further investigation.
> Do not guess — flag and escalate.

---

## SQL Server

| # | Question | Priority | Assigned To | Status |
|---|---|---|---|---|
| 1 | What SSIS packages are being checked by `DBA - SSISStatusCheck`? Where do they run? | High | Unknown | Open |
| 2 | Who consumes the data in `DBA_VCC_COST` — is it used for client billing or internal reporting? | High | Unknown | Open |
| 3 | Is the `DBA - Maintenance - SQL Backup EW1P-OCT` job still needed? Who owns that RDS instance? | High | Unknown | Open |
| 4 | Are all 109 SingleStore linked servers still reachable or are most stale? | Medium | Unknown | Open |
| 5 | What credentials are used for linked server connections — where are they stored in vault? | High | Unknown | Open |
| 6 | Who is `dba@kurtosys.com` — is it a team mailbox or individual? Who monitors it? | Medium | Unknown | Open |

---

## Grafana

| # | Question | Priority | Assigned To | Status |
|---|---|---|---|---|
| 7 | What is the Grafana URL/DNS for this server? | High | Unknown | **Closed** — https://ew1r-rep-01 (port 443, HTTPS) |
| 8 | Who has access to Grafana on this server? | High | Unknown | **Closed** — tashvir.babulal, yogeshwar.phull, rayhaan.suleyman (active admins), donovan.vangraan (inactive builder) |
| 9 | Which teams use the Grafana dashboards — engineering, ops, client-facing? | High | Unknown | **Partial** — DB engineering confirmed. Client-facing TBC — ask tashvir.babulal / rayhaan.suleyman |
| 10 | Are any dashboards client-facing or SLA-related? | Critical | tashvir.babulal / rayhaan.suleyman | Open — Month End Reporting and KAPP Client reports are strong candidates |
| 11 | What datasources does Grafana use — does it read from DBA_VCC_* databases directly? | High | Unknown | **Closed** — 21 datasources confirmed: DBA_VCC (localhost MSSQL), KAPP MySQL (Dev/Rel/UK/EU/US Prod), SingleStore (Dev/Rel/UK/EU/US Prod), Zabbix MySQL (x4), NiFi JSON API, CloudWatch, InfluxDB |
| 12 | Are there alert notification channels configured in Grafana? Who receives them? | High | Unknown | **Closed** — 2 Slack channels: `alerts-data-operations` (default) and `alert-app-allow2fa-disabled` (Client Auth alerts). Email contact point is a placeholder — not configured. |

---

## KAPP & Applications

| # | Question | Priority | Assigned To | Status |
|---|---|---|---|---|
| 13 | Who owns the KAPP monitoring data in `DBA_VCC_AWS`? Is it used for SLA reporting? | Critical | Unknown | Open |
| 14 | Is `INFO_AWS_KAPP_Query_API_Detail` (563M rows) actively read by any application or dashboard? | Critical | Unknown | **Partial** — Grafana has KAPP MySQL datasources and active KAPP dashboards updated Oct 2025. DBA_VCC on localhost also read by Grafana. Confirm if dashboards query this specific table. |
| 15 | What is Encore — is it a separate product? Who owns it? | Medium | Unknown | Open |
| 16 | What does `DBA_VCC_ATLASSIAN` feed into Jira/Confluence — reports, metrics? | Medium | Unknown | Open |

---

## Infrastructure

| # | Question | Priority | Assigned To | Status |
|---|---|---|---|---|
| 17 | What DNS name(s) point to EW1R-REP-01? | High | Unknown | **Closed** — EW1R-REP-01 resolves to 10.72.8.216 (confirmed via netstat) |
| 18 | What firewall rules allow inbound/outbound connections to this server? | High | Unknown | Open |
| 19 | What service accounts run the SQL Agent jobs? | Medium | Unknown | **Closed** — SHNONPRD\\sqlagent (Agent), SHNONPRD\\sqlsrv (Engine), NT Service\\MSSQLLaunchpad (Launchpad) |
| 20 | Is there a runbook or any existing documentation for this server anywhere? | Medium | Unknown | Open |

---

## Active Failures — Requires Immediate Action

| # | Finding | Priority | Assigned To | Status |
|---|---|---|---|---|
| 24 | **WPv2 linked servers `ew2p-wpv2` and `ew2r-wpv2` are pointing to RDS instances that no longer exist** — DNS resolution fails with `Unknown MySQL server host`. Both `DBA_VCC_MYSQL_DAILY_CHECKS` and `DBA_VCC_MYSQL_AUDIT_DXM_CLIENT_DETAILED` have been failing silently every day since at least 25 June 2026. No alert is configured on either job so nobody was notified. WPv2 monitoring data has not been collected for 2+ weeks. | Critical | Unknown — find owner of ew2p-wpv2 / ew2r-wpv2 RDS | Open |
| 25 | **What happened to the WPv2 RDS instances?** Were they decommissioned, renamed, or migrated? If decommissioned, the linked servers and job steps referencing them must be cleaned up. If renamed, the linked server data source must be updated. Either way these jobs are wasting execution time pointing at nothing. | Critical | DevOps / cloud team | Open |
| 26 | **Cost and operational impact of stale linked servers** — jobs are running daily against non-existent targets, consuming SQL Agent execution time and generating noise in job history. How many other linked servers across the 109 are pointing at decommissioned or renamed targets? A full reachability check is needed before any decommission decision. | High | DBA team | Open |

---

## Decommission Risk

| # | Question | Priority | Assigned To | Status |
|---|---|---|---|---|
| 21 | If this server went offline today, what would break immediately? | Critical | Unknown | Open |
| 22 | Is any alerting dependent solely on this server — would anyone lose visibility? | Critical | Unknown | Open |
| 23 | Is the VCC framework replicated anywhere else or is this the only instance? | High | Unknown | Open |
