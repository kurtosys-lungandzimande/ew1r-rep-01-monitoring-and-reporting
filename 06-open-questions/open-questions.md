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

---

## Decommission Risk

| # | Question | Priority | Assigned To | Status |
|---|---|---|---|---|
| 21 | If this server went offline today, what would break immediately? | Critical | Unknown | Open |
| 22 | Is any alerting dependent solely on this server — would anyone lose visibility? | Critical | Unknown | Open |
| 23 | Is the VCC framework replicated anywhere else or is this the only instance? | High | Unknown | Open |
