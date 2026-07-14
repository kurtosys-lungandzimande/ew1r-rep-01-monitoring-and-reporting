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
| TECH-3478 | Theme A — SQL Server | In Progress | SQL Server inventory, jobs, databases, linked servers |
| TECH-3479 | Theme B — Grafana | In Progress | Grafana datasources, dashboards, users, alerts |
| TECH-3480 | Theme C — Targets & Consumers | In Progress | External targets, consumers, dependencies, firewall |
| TECH-3481 | Theme D — Classification & Topology | In Progress | Topology, classification, decommission decision |

---

## Repository Structure

Each folder maps directly to a Jira ticket. Everything inside belongs to that ticket's scope.

```
TECH-3535-planning-and-discovery/
│
│   discovery-queries.sql            ← All SQL queries used during investigation (13 sections)
│   open-questions.md                ← All open questions, blockers, and active findings
│   investigation-log.md             ← Critical findings with query evidence (5 findings)
│   ew1r-rep-01-architecture.drawio  ← Architecture diagram
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
TECH-3481-theme-d-classification-and-topology/
│
│   topology-and-classification.md   ← Topology map and classification outputs
│   investigation-log.md             ← Theme D findings
│
README.md                            ← This file
```

---

## Progress at a Glance

| Ticket | What Has Been Done |
|---|---|
| TECH-3535 | Server confirmed live. 8 databases (378 GB). 63 jobs (52 enabled, 11 disabled). 109 linked servers. ~600 stored procs across 8 databases. All discovery queries written and run across 13 sections. 34 open questions raised. 5 critical findings documented with query evidence. S3 backup retention confirmed — 30-day lifecycle policy. |
| TECH-3478 | SQL Server inventory complete — databases, jobs, linked servers, service accounts, stored proc inventory all confirmed. Critical findings: WPv2 linked servers dead (26 consecutive daily failures since 2026-06-12), MemSQL jobs disabled since May 2026, AWS cost ETL silently broken since Sept 2024, MERGE performance risk on 563M row table. SP_AUDIT_WPv2_CLIENTS_DETAILED last modified 2022-11-01 — never updated after WPv2 decommission. |
| TECH-3479 | Grafana inventory complete — 21 datasources, 74 dashboards confirmed (query 9.5 + 13.7), 8 users (5 admins, 3 viewers — 3 active admins, 2 inactive), 3 alert rules, 3 contact points (2 active Slack, 1 broken email placeholder). Inactive credentials flagged (donovan.vangraan still used in 4 Zabbix datasources). Default admin account flagged. 10 dashboards actively maintained in 2025. |
| TECH-3480 | External targets identified. DBA_VCC_COST confirmed active Grafana datasource (4 dashboards). DBA_VCC_MEMSQL confirmed broken datasource (14 dashboards stale since May 2026). Consumer confirmation still needed — who reads DBA_VCC_COST, is KAPP Client Utilisation and Growth Report client-facing. S3 backup retention confirmed — 30-day lifecycle. |
| TECH-3481 | Topology map and component classification written. Preliminary decommission recommendation documented — server not safe to decommission until 5 stakeholder questions answered. Blocked on consumer confirmation from tashvir.babulal / rayhaan.suleyman / yogeshwar.phull. |

---

## Server Details

| Property | Value |
|---|---|
| Hostname | EW1R-REP-01 |
| IP Address | 10.72.8.216 |
| SQL Server Version | Microsoft SQL Server 2019 (RTM-CU32-GDR) 15.0.4455.2 |
| Edition | Developer Edition (64-bit) |
| OS | Windows Server 2019 Datacenter |
| Grafana Version | 9.5.2 — port 443 (HTTPS) |
| Environment | Non-production host monitoring production systems |
