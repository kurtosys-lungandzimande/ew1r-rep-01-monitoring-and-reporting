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
| 24 | **All 4 WPv2 linked servers fully decommissioned** — `ew2p-wpv2`, `ew2r-wpv2`, `ue1p-wpv2`, `ue1r-wpv2` all return `Unknown MySQL server host`. DNS no longer resolves for any of them across both eu-west-2 and us-east-1. WPv2 platform confirmed decommissioned. `DBA_VCC_MYSQL_DAILY_CHECKS` and `DBA_VCC_MYSQL_AUDIT_DXM_CLIENT_DETAILED` have been failing silently every day since at least 25 June 2026. No alert configured — nobody was notified. All 4 linked servers and all referencing job steps must be cleaned up. | Critical | DBA team | Open — action required |
| 25 | **Additional stale linked servers confirmed beyond WPv2** — `BASELINE_CONNECTIONS` job history reveals further unreachable targets: `ew1d-aggr-05`, `ew1d-aggr-15` (Not Online), `ew1r-aggr-03.gen-rel` (ODBC driver not found — misconfigured), `ew1r-aggr-05.gen-rel`, `ew2p-aggr-01.gen-prd`, `ew2p-aggr-02.gen-prd` (all Can't connect), `EW2P-MARKETING-DB` (Not Online — unknown owner). Scope of stale linked servers is wider than WPv2 alone. Full reachability audit needed across all 109 linked servers. | Critical | DBA team | Open |
| 26 | **Who owns EW2P-MARKETING-DB?** It appears in BASELINE_CONNECTIONS job history as Not Online. Unknown what this is, who owns it, and whether it was decommissioned or just unreachable. | High | Unknown | Open |
| 27 | **Operational cost of stale linked servers** — multiple jobs are running daily and every 15 minutes against targets that no longer exist, generating errors in job history and consuming execution time. Until stale linked servers are removed or disabled, this noise will continue. Cleanup is blocked on confirming which targets are permanently gone vs temporarily unreachable. | High | DBA team | Open |

---

## Jobs & Linked Server Mapping

| # | Question | Priority | Assigned To | Status |
|---|---|---|---|---|
| 28 | Which linked servers are referenced by zero job steps or stored procedures — true orphans safe to drop? | High | DBA team | Open — run query 11.3 and 11.4 |
| 29 | Which stored procedures inside DBA_VCC, DBA_VCC_MYSQL, and KURTOSYS_BASELINE reference the stale linked servers (WPv2, gen-rel, gen-prd, EW2P-MARKETING-DB)? | High | DBA team | Open — run query 11.2 |
| 30 | For each enabled job — what database does it feed and what breaks if it stops? | Critical | DBA team | Open — run query 11.5 |
| 31 | Why does BASELINE_CONNECTIONS still have steps for ew1d-aggr-05 and ew1d-aggr-15 — were these ever decommissioned or just unreachable? | Medium | Unknown | Open |
| 32 | Are the gen-rel and gen-prd SingleStore nodes permanently retired or just a different generation still in use somewhere? | High | SingleStore / Platform team | Open |
| 33 | **MERGE performance on INFO_AWS_KAPP_Query_API_Detail (563M rows) is already taking 9+ minutes per run on a 30-minute schedule** — SP_AUDIT_KAPP_QUERY_ETL_CLEANUP does a full DISTINCT scan + MERGE with no partitioning. As the table grows this will exceed the schedule interval and runs will overlap. Needs redesign before RDS migration. Written by donovan.vangraan (Feb 2024) who is no longer active. | High | DBA team | Open — decommission blocker for RDS migration |
| 34 | **AWS cost ETL silently failing since September 2024 — 2.4M rows stuck in MON_AWS_Entity_Cost staging table** — SP_AUDIT_COST_ETL_CLEANUP does `convert(decimal(20,10), Cost)` but Cost column is nvarchar. Suspected bad data causing full MERGE rollback. CATCH block swallows the error so job reports Succeeded. TRUNCATE never runs so staging table keeps growing. INFO_AWS_Entity_Cost stale since 22 Sept 2024. INFO_AWS_DE_Entity_Cost in DBA_VCC_COST stale since 5 Dec 2024 via separate path. Neither failure has been noticed. | High | DBA team | Open — raise as separate ticket, out of scope for TECH-3535 |

---

## Decommission Risk

| # | Question | Priority | Assigned To | Status |
|---|---|---|---|---|
| 21 | If this server went offline today, what would break immediately? | Critical | Unknown | Open |
| 22 | Is any alerting dependent solely on this server — would anyone lose visibility? | Critical | Unknown | Open |
| 23 | Is the VCC framework replicated anywhere else or is this the only instance? | High | Unknown | Open |

---

## Confirmed Findings — Answered by Query Evidence

> These were open questions that have now been answered directly from the server without requiring stakeholder input.
> Each answer is backed by a specific query run during the investigation.

---

### Grafana

| # | Question | Answer | Evidence |
|---|---|---|---|
| Q7 | What is the Grafana URL/DNS? | https://ew1r-rep-01 on port 443 (HTTPS) | query 9.1 — netstat confirmed grafana.exe listening on 0.0.0.0:443, PID 3844 |
| Q8 | Who has access to Grafana? | tashvir.babulal (last seen 2026-06-09), yogeshwar.phull (2026-06-22), rayhaan.suleyman (2026-06-30) — all active admins. donovan.vangraan last seen 2024-11-13 — inactive but credentials still used in 4 Zabbix datasources | query 9.4 — user table from grafana.db |
| Q11 | What datasources does Grafana use? | 21 datasources confirmed — DBA_VCC (localhost MSSQL, 2 entries with different UIDs), KAPP MySQL (Dev/Rel/UK/EU/US Prod), SingleStore (Dev/Rel/UK/EU/US Prod querying UDM__ schema), Zabbix MySQL (x4), NiFi JSON API, CloudWatch, InfluxDB | query 12.6 — data_source table from grafana.db with UIDs and json_data |
| Q12 | Are alert channels configured in Grafana? | Yes — 2 active Slack channels: `alerts-data-operations` (default route) and `alert-app-allow2fa-disabled` (Client Auth alerts only). Email contact point is a placeholder with no real address — it will not deliver | query 9.8 — alert_configuration table from grafana.db |

---

### Dashboards — Consumer Mapping

| # | Question | Answer | Evidence |
|---|---|---|---|
| Q-A | Which dashboards read from DBA_VCC_COST? | 4 confirmed: Database Engineering Costs (2024-10-15), Database Engineering Sprint Reporting (2024-03-08), KAPP Client Utilisation and Growth Report (2024-02-22), AWS Cost Report Monthly (2023-10-06) | query 12.3 — full scan of all dashboard JSON in grafana.db |
| Q-B | Which dashboards call REP_MONTHEND stored procedures? | 6 confirmed: WPv2 Month End Reporting (2024-06-20), Encore Month End Reporting (2023-08-10), DXM Month End Reporting (2023-08-10), InvestorPress Month End Reporting (2023-08-10), KAPP Month End Reporting (2023-08-10), Other Services Month End Reporting Draft (2023-07-21) | query 12.4 — full scan of all dashboard JSON in grafana.db |
| Q-C | Which dashboards read from DBA_VCC_MEMSQL? | 14 confirmed — all currently showing stale data since May 2026 when collection jobs were disabled. Key dashboards: KAPP Dataset Query and Source Execution (2024-11-20), KAPP Client Application Auth Config (2024-10-29), KAPP Client Config (2024-09-02), KAPP Client Growth (2024-02-28), plus 10 others | query 12.5 — full scan of all dashboard JSON in grafana.db |
| Q-D | Are there duplicate datasource entries? | Yes — DBA_VCC has two entries with different UIDs (a082f27e and e8597015) both pointing to localhost DBA_VCC. Dashboards may be split across both UIDs — must be resolved before any migration | query 12.6 — data_source table from grafana.db |

---

### Infrastructure

| # | Question | Answer | Evidence |
|---|---|---|---|
| Q17 | What DNS name resolves to this server? | EW1R-REP-01 resolves to 10.72.8.216 | query 9.1 — netstat output confirmed IP |
| Q19 | What service accounts run the SQL Agent jobs? | SHNONPRD\sqlagent (SQL Agent), SHNONPRD\sqlsrv (SQL Server engine), NT Service\MSSQLLaunchpad (Python extensibility) — all running, all set to Automatic startup | query 1.3 — sys.dm_server_services |

---

### Active Failures — Confirmed by Query Evidence

| # | Finding | Confirmed By |
|---|---|---|
| F1 | DBA_VCC_MEMSQL collection jobs disabled since May 2026 — 14 Grafana dashboards showing stale data, no alert fired, no one notified | query 12.5 (dashboard JSON scan) + query 2.3 (job last run history) |
| F2 | 6 month-end dashboards calling REP_MONTHEND procedures with no fresh data since May 2026 — June 2026 month-end reporting impacted | query 12.4 (dashboard JSON scan) |
| F3 | DBA_VCC_COST confirmed active Grafana datasource — KAPP Client Utilisation and Growth Report is highest risk, name suggests client-facing use, consumer not yet confirmed | query 12.3 (dashboard JSON scan) |
| F4 | All 4 WPv2 linked servers dead — DNS does not resolve. DBA_VCC_MYSQL_DAILY_CHECKS and DBA_VCC_MYSQL_AUDIT_DXM_CLIENT_DETAILED failing silently every day since 25 June 2026 | query 4.2 (job failure history — Error 7303 on ew2p-wpv2 and ew2r-wpv2) |
| F5 | AWS cost ETL silently broken since September 2024 — SP_AUDIT_COST_ETL_CLEANUP CATCH block swallows nvarchar-to-decimal conversion error, job reports Succeeded, 2.4M rows stuck in staging, INFO_AWS_Entity_Cost stale 22 months | query 5.4 (data freshness) + stored procedure definition review |

---

### Still Open — Requires Stakeholder Input

| # | Question | Who to Ask | Why It Blocks Decommission |
|---|---|---|---|
| Q2 | Who consumes DBA_VCC_COST — billing or internal reporting? | tashvir.babulal / rayhaan.suleyman | If billing — cannot decommission without a confirmed replacement |
| Q10 | Is KAPP Client Utilisation and Growth Report client-facing? | tashvir.babulal / rayhaan.suleyman | If client-facing — decommission directly impacts clients |
| Q13 | Who owns the KAPP monitoring data in DBA_VCC_AWS? Is it used for SLA reporting? | KAPP engineering / platform team | If SLA — cannot decommission without a confirmed replacement |
| Q21 | If this server went offline today, what would break immediately? | yogeshwar.phull / tashvir.babulal | Required for decommission risk assessment |
| Q22 | Is any alerting dependent solely on this server? | yogeshwar.phull / tashvir.babulal | Required for decommission risk assessment |
| Q23 | Is the VCC framework replicated anywhere else? | DBA team | If not replicated — this is a single point of failure |
