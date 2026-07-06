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
| TECH-3478 | Theme A — SQL Server | Not Started | SQL Server inventory, jobs, databases, linked servers |
| TECH-3479 | Theme B — Grafana | Not Started | Grafana datasources, dashboards, users, alerts |
| TECH-3480 | Theme C — Targets & Consumers | Not Started | External targets, consumers, dependencies, firewall |
| TECH-3481 | Theme D — Classification & Topology | Not Started | Topology, classification, decommission decision |

---

## Repository Structure

Each folder maps directly to a Jira ticket. Everything inside belongs to that ticket's scope.

```
TECH-3535-planning-and-discovery/
│
│   discovery-queries.sql        ← All SQL queries used during investigation (11 sections)
│   open-questions.md            ← All open questions, blockers, and active findings
│   ew1r-rep-01-architecture.drawio  ← Architecture diagram
│
TECH-3478-theme-a-sql-server/
│
│   sql-server-inventory.md      ← Databases, jobs, linked servers, service accounts
│
TECH-3479-theme-b-grafana/
│
│   grafana-inventory.md         ← Datasources, dashboards, users, alert rules
│
TECH-3480-theme-c-targets-and-consumers/
│
│   external-targets.md          ← External targets and connections
│   consumers-and-dependencies.md ← Consumers, service accounts, firewall rules
│
TECH-3481-theme-d-classification-and-topology/
│
│   topology-and-classification.md ← Topology map and classification outputs
│
CHANGELOG.md                     ← Plain English investigation log — every finding with query + evidence
README.md                        ← This file
```

---

## Progress at a Glance

| Ticket | What Has Been Done |
|---|---|
| TECH-3535 | Server confirmed live. 8 databases (378 GB). 63 jobs (52 enabled, 11 disabled). 109 linked servers. All discovery queries written across 11 sections. 34 open questions raised. 8 critical/high findings documented. |
| TECH-3478 | SQL Server inventory complete — databases, jobs, linked servers, service accounts all confirmed. Critical findings: WPv2 linked servers dead, MemSQL jobs disabled, AWS cost ETL broken, MERGE performance risk. |
| TECH-3479 | Grafana inventory complete — 21 datasources, 90 dashboards, 8 users, 3 alert rules confirmed. Inactive credentials flagged. Not being investigated further in current sprint. |
| TECH-3480 | External targets identified. Consumer confirmation still needed — who reads DBA_VCC_COST, who uses Grafana dashboards. |
| TECH-3481 | Not started. Blocked on completing Themes A, B, C first. |

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
