# EW1R-REP-01 — Monitoring & Reporting Server Discovery

## Background — The Problem This Investigation Is Solving

This server started as a SQL Server monitoring box but grew over time to also run Grafana, SQL Agent jobs, and monitoring for RDS MySQL, SingleStore, and other systems. Platform Engineering intends to decommission it, but there was no authoritative inventory of what it runs, what it monitors, who consumes the output, or what would break if it were switched off.

Without a structured discovery pass, decommission risks:
- Silent loss of alerts that teams depend on
- Orphaned Grafana dashboards that people open every month for reporting
- Undocumented SQL Agent jobs that feed business-critical data
- Loss of month-end client reporting data with no replacement in place

This repository is the result of that structured discovery pass.

---

## What We Now Know — Investigation Summary

### The server is not safe to decommission. Here is why:

**1. Grafana is actively used by 3 people right now**
- tashvir.babulal, yogeshwar.phull, and rayhaan.suleyman all logged in as recently as June 2026
- 90 dashboards across 16 folders — KAPP, SingleStore, AWS, Encore, Zabbix, Jira, Month-End Reporting
- Dashboards updated as recently as October/November 2025 — this is not abandoned
- Grafana reads directly from KAPP production MySQL (UK, EU, US), SingleStore production clusters, and Zabbix MySQL databases
- If this server goes offline, all those dashboards go dark immediately

**2. Month-end reporting is broken and nobody may know**
- The Grafana month-end dashboards (KAPP, InvestorPress, Encore, DXM, WPv2) read from DBA_VCC_MEMSQL
- All DBA_VCC_MEMSQL collection jobs were disabled in May 2026 after a daily checks failure
- This means month-end dashboards have shown no current data since May 2026
- AWS cost figures in the reports have been stale since November 2024 — 18 months of wrong data
- Nobody has flagged this — it needs to be raised Monday

**3. A client usage tracking system is running every week**
- DBA_VCC_COST collects entity counts per KAPP client every Sunday at 08:00
- Tracks 9 entity types: allocations, documents, disclaimers, entities, snapshots, statistics, timeseries, historical datasets, users
- Covers UK, EU, and US production environments
- Has 19 month-end reporting stored procedures — summary and per-client versions
- On FULL recovery model — someone deliberately made this data unlosable
- Last successful run: 29 June 2026
- Who calls the reporting procedures and what they do with the output is still unknown — confirm Monday

**4. KAPP API monitoring is collecting every 15 minutes**
- 563 million rows in INFO_AWS_KAPP_Query_API_Detail — actively growing
- Collected via Python API calls every 15 minutes
- Grafana KAPP dashboards updated October 2025 read from this data
- This is the core KAPP observability system

**5. SQL Server alerts are all silent**
- 17 SQL Server severity alerts (fatal errors, IO failures, AG issues) are defined but have no notification configured
- If the server hits a fatal error, nobody gets alerted automatically
- Only SQL Agent job failures go to dba@kurtosys.com

**6. An ex-employee's credentials are still in use**
- Grafana Zabbix datasources use donovan.vangraan@kurtosys.com credentials
- Donovan van Graan last logged into Grafana in November 2024 and is no longer active
- These credentials need to be rotated regardless of decommission decision

---

## Server Details

| Property | Value |
|---|---|
| Hostname | EW1R-REP-01 |
| IP Address | 10.72.8.216 |
| SQL Server Version | Microsoft SQL Server 2019 (RTM-CU32-GDR) 15.0.4455.2 |
| Edition | Developer Edition (64-bit) |
| OS | Windows Server 2019 Datacenter (Hypervisor/VM) |
| SQL Server Engine Account | SHNONPRD\sqlsrv |
| SQL Server Agent Account | SHNONPRD\sqlagent |
| Grafana Version | 9.5.2 — running on port 443 (HTTPS) |
| Zabbix Agent | Running on port 10050 — server is monitored by Zabbix |
| Environment | Non-production host monitoring production systems |

---

## Repository Structure

```
01-sql-server-inventory/        # 60 SQL Agent jobs, 97 linked servers, 8 databases
02-grafana-inventory/           # 90 dashboards, 21 datasources, 8 users, 3 alert rules
03-external-targets/            # SingleStore, MySQL, RDS, AWS targets
04-consumers-and-dependencies/  # Data consumers, alert mechanisms, infrastructure deps
05-classification-and-topology/ # Topology diagram, server value, retire/replace/move
06-open-questions/              # 23 questions — 8 closed, 15 still open for Monday
queries/                        # All SQL queries used during discovery
```

---

## Investigation Status

- [x] SQL Server inventory complete — 60 jobs, 97 linked servers, 8 databases documented
- [x] Grafana inventory complete — 90 dashboards, 21 datasources, 8 users, 3 alert rules confirmed
- [x] External targets documented — SingleStore (4 regions), MySQL, RDS, Zabbix, NiFi, AWS
- [x] Infrastructure dependencies mapped — all ports, IPs, service accounts, credentials
- [ ] Data consumers fully identified — Grafana users confirmed, business consumers TBC Monday
- [x] Topology diagram published — with confirmed Grafana data and server value summary
- [x] Retire/replace/move classification done — preliminary, pending consumer confirmation
- [ ] Manager sign-off received

---

## Critical Actions Before Any Decommission Decision

| # | Action | Who | Priority |
|---|---|---|---|
| 1 | Find out who disabled DBA_VCC_MEMSQL jobs in May 2026 and why | yogeshwar.phull / tashvir.babulal | Critical |
| 2 | Confirm if anyone noticed month-end dashboards stopped showing current data | rayhaan.suleyman / tashvir.babulal | Critical |
| 3 | Identify who calls REP_MONTHEND_* procedures and what they do with the output | Finance / account management | Critical |
| 4 | Confirm if DBA_VCC_COST data is used for client billing | Finance / platform management | Critical |
| 5 | Confirm which Grafana dashboards are client-facing or SLA-related | rayhaan.suleyman / tashvir.babulal | Critical |
| 6 | Rotate donovan.vangraan Grafana Zabbix datasource credentials immediately | DBA team | High |
| 7 | Identify AWS IAM credentials used by Python collection jobs | DevOps / cloud team | High |
| 8 | Confirm S3 bucket ARN for backups | DevOps / cloud team | High |
| 9 | Identify who monitors dba@kurtosys.com | DBA team / manager | Medium |

---

## Related Tickets

- TECH-3431 — SQL Server EC2 to Amazon RDS feasibility evaluation
- TECH-3428 — Unified database performance and capacity insights
- TECH-3409 — Aurora PostgreSQL Serverless v2 monitoring review
