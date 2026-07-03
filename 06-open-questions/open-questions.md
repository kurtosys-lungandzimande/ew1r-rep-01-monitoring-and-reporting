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
| 4 | Are all 97 SingleStore linked servers still reachable or are most stale? | Medium | Unknown | Open |
| 5 | What credentials are used for linked server connections — where are they stored in vault? | High | Unknown | Open |
| 6 | Who is `dba@kurtosys.com` — is it a team mailbox or individual? Who monitors it? | Medium | Unknown | Open |

---

## Grafana

| # | Question | Priority | Assigned To | Status |
|---|---|---|---|---|
| 7 | What is the Grafana URL/DNS for this server? | High | Unknown | Open |
| 8 | Who has access to Grafana on this server? | High | Unknown | Open |
| 9 | Which teams use the Grafana dashboards — engineering, ops, client-facing? | High | Unknown | Open |
| 10 | Are any dashboards client-facing or SLA-related? | Critical | Unknown | Open |
| 11 | What datasources does Grafana use — does it read from DBA_VCC_* databases directly? | High | Unknown | Open |
| 12 | Are there alert notification channels configured in Grafana? Who receives them? | High | Unknown | Open |

---

## KAPP & Applications

| # | Question | Priority | Assigned To | Status |
|---|---|---|---|---|
| 13 | Who owns the KAPP monitoring data in `DBA_VCC_AWS`? Is it used for SLA reporting? | Critical | Unknown | Open |
| 14 | Is `INFO_AWS_KAPP_Query_API_Detail` (563M rows) actively read by any application or dashboard? | Critical | Unknown | Open |
| 15 | What is Encore — is it a separate product? Who owns it? | Medium | Unknown | Open |
| 16 | What does `DBA_VCC_ATLASSIAN` feed into Jira/Confluence — reports, metrics? | Medium | Unknown | Open |

---

## Infrastructure

| # | Question | Priority | Assigned To | Status |
|---|---|---|---|---|
| 17 | What DNS name(s) point to EW1R-REP-01? | High | Unknown | Open |
| 18 | What firewall rules allow inbound/outbound connections to this server? | High | Unknown | Open |
| 19 | What service accounts run the SQL Agent jobs? | Medium | Unknown | Open |
| 20 | Is there a runbook or any existing documentation for this server anywhere? | Medium | Unknown | Open |

---

## Decommission Risk

| # | Question | Priority | Assigned To | Status |
|---|---|---|---|---|
| 21 | If this server went offline today, what would break immediately? | Critical | Unknown | Open |
| 22 | Is any alerting dependent solely on this server — would anyone lose visibility? | Critical | Unknown | Open |
| 23 | Is the VCC framework replicated anywhere else or is this the only instance? | High | Unknown | Open |
