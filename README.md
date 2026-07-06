# EW1R-REP-01 — Monitoring & Reporting Server

## Purpose of This Repository

This repository is the **evidence and proof layer** for the EW1R-REP-01 decommission investigation.

It contains raw query outputs, screenshots, and supporting artefacts collected during discovery.

Full documentation, findings, analysis, and decisions live in **Confluence**.

> Confluence: [EW1R-REP-01 Decommission Investigation] — add link here

---

## Related Jira Tickets

| Ticket | Description |
|---|---|
| TECH-3535 | Initial Investigation and Discovery Planning |
| TECH-3478 | Theme A — SQL Server |
| TECH-3479 | Theme B — Grafana |
| TECH-3480 | Theme C — Targets & Consumers |
| TECH-3481 | Theme D — Classification & Topology |

---

## Repository Structure

```
queries/                        # SQL discovery queries used during investigation
01-sql-server-inventory/        # Raw evidence — jobs, databases, linked servers
02-grafana-inventory/           # Raw evidence — datasources, dashboards, users, alerts
03-external-targets/            # Raw evidence — external targets and connections
04-consumers-and-dependencies/  # Raw evidence — consumers, service accounts, firewall
05-classification-and-topology/ # Raw evidence — topology and classification outputs
06-open-questions/              # Tracked open questions and blockers
07-architecture/                # Architecture diagram
```

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
