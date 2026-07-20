# EW1R-REP-01 — Monitoring & Reporting Server

## Purpose of This Repository

This repository is the **evidence and proof layer** for the EW1R-REP-01 decommission investigation.

It contains raw query outputs, screenshots, and supporting artefacts collected during discovery.

Full documentation, findings, analysis, and decisions live in **Confluence**.

> Confluence: [EW1R-REP-01 Decommission Investigation] — add link here

---

## Related Jira Tickets

| Ticket | Theme | Status | Scope |
|---|---|---|---|
| TECH-3535 | Planning & Discovery | In Progress | Read-only discovery — feeds all theme tickets |
| TECH-3560 | Theme A — SQL Server | In Progress | SQL Server inventory, jobs, databases, linked servers |
| TECH-3561 | Theme B — Grafana | In Progress | Grafana datasources, dashboards, users, alerts |
| TECH-3562 | Theme C — Targets & Consumers | In Progress | External targets, consumers, dependencies, firewall |
| TECH-3563 | Theme D — Classification & Topology | In Progress | Topology, classification, decommission decision |

---

## Repository Structure

Each folder maps directly to a Jira ticket. Everything inside belongs to that ticket's scope.

```
TECH-3535-planning-and-discovery/
│
│   discovery-queries.sql            ← All SQL queries used during investigation (14 sections)
│   discovery-summary.md             ← Master consolidation doc — all themes, findings, blockers
│   open-questions.md                ← All open questions, blockers, and active findings (36 questions)
│   investigation-log.md             ← Critical findings with query evidence (6 findings)
│   presentation.md                  ← Full presentation document — architecture, themes, decommission readiness
│   ew1r-rep-01-architecture.drawio  ← Architecture diagram — 4 AWS region swimlanes
│
TECH-3560-theme-a-sql-server/
│
│   sql-server-inventory.md          ← Databases, jobs, linked servers, service accounts, stored procs
│   investigation-log.md             ← Theme A findings
│
TECH-3561-theme-b-grafana/
│
│   grafana-inventory.md             ← Datasources, dashboards (74 confirmed), users, alert rules
│   investigation-log.md             ← Theme B findings
│
TECH-3562-theme-c-targets-and-consumers/
│
│   external-targets.md              ← External targets and connections
│   consumers-and-dependencies.md    ← Consumers, service accounts, firewall rules
│   investigation-log.md             ← Theme C findings
│
TECH-3563-theme-d-classification-and-topology/
│
│   topology-and-classification.md   ← Topology map and classification outputs
│   investigation-log.md             ← Theme D findings
│
TECH-3410-current-sprint/
│
│   decommission-readiness.md        ← 40/40/20 split, 6 blockers, 5-phase plan
│   open-questions.md                ← Sprint-level open questions tracker
│   database-inventory.md            ← Per-database findings and resolutions
│   job-inventory.md                 ← 63 jobs — status, failures, proposed resolutions
│   linked-server-inventory.md       ← 109 linked servers — reachability and cleanup plan
│   theme-a-summary.md               ← Theme A consolidated summary
│   theme-b-grafana-inventory.md     ← Theme B Grafana full inventory
│   zabbix-alert-inventory.md        ← Zabbix alert inventory
│   slack-alert-inventory.md         ← Slack alert inventory
│   sql-agent-alerts.md              ← SQL Agent alert configuration
│
README.md                            ← This file
```

---

## Progress at a Glance

| Ticket | What Has Been Done |
|---|---|
| TECH-3535 | Server confirmed live. 8 databases (369 GB — exact sizes confirmed 2026-07-20). 63 jobs (52 enabled, 11 disabled). 109 linked servers. ~600 stored procs across 8 databases. All discovery queries written and run across 14 sections. 36 open questions raised. 6 critical findings documented with query evidence. S3 backup buckets confirmed — retention TBC (check S3 lifecycle rules). |
| TECH-3560 | SQL Server inventory complete — databases, jobs, linked servers, service accounts, stored proc inventory all confirmed. Critical findings: WPv2 linked servers dead (26 consecutive daily failures since 2026-06-12), MemSQL jobs disabled since May 2026, AWS cost ETL silently broken since Sept 2024, MERGE performance risk on 563M row table. SP_AUDIT_WPv2_CLIENTS_DETAILED last modified 2022-11-01 — never updated after WPv2 decommission. |
| TECH-3561 | Grafana inventory complete — 21 datasources, 74 dashboards confirmed (query 9.5 + 13.7), 8 users (5 admins, 3 viewers — 3 active admins, 2 inactive), 3 alert rules, 3 contact points (2 active Slack, 1 broken email placeholder). Inactive credentials flagged (donovan.vangraan still used in 4 Zabbix datasources). Default admin account flagged. 10 dashboards actively maintained in 2025. |
| TECH-3562 | External targets identified. DBA_VCC_COST confirmed active Grafana datasource (4 dashboards). DBA_VCC_MEMSQL confirmed broken datasource (14 dashboards stale since May 2026). DBA_VCC_COST confirmed client billing data — 280 real institutional clients across EW2, UE1, EC1. KAPP Client Utilisation and Growth Report confirmed client-facing. All 9 collection tables stale since 4 May 2026 — 11+ consecutive silent zero-row runs confirmed 2026-07-20. S3 backup buckets confirmed — retention TBC (check S3 lifecycle rules). |
| TECH-3563 | Topology map and component classification written. Validated 2026-07-20 — all Theme C findings re-confirmed from live queries. Preliminary decommission recommendation documented — server not safe to decommission until 6 stakeholder questions answered (Q13, Q21, Q22, Q23, Q35, Q36). Blocked on consumer confirmation from tashvir.babulal / rayhaan.suleyman / yogeshwar.phull. |

---

## Server Details

| Property | Value |
|---|---|
| Hostname | EW1R-REP-01 |
| IP Address | 10.72.8.216 |
| DNS (Replication) | ew1r-rep-01.ad.shnonprd.kurtosys-internal.net |
| DNS (Primary) | dbe-reports.shnonprd.kurtosys-internal.net |
| Platform | AWS EC2 — Ireland (eu-west-1) |
| Environment | Shared NonProd (REL) |
| SQL Server Version | Microsoft SQL Server 2019 (RTM-CU32-GDR) 15.0.4455.2 |
| Edition | Developer Edition (64-bit) |
| OS | Windows Server 2019 Datacenter (AWS EC2 — Hypervisor) |
| Grafana Version | 9.5.2 — port 443 (HTTPS) |
| Monitoring role | Non-production host monitoring production systems |
