# EW1R-REP-01 — Monitoring & Reporting Server Discovery

## Purpose
This repository documents the discovery and investigation of `EW1R-REP-01`, a self-managed SQL Server EC2 instance that serves as a custom monitoring and reporting hub for the Kurtosys platform.

## Background
This server was built by a former team member with no documentation. It runs a custom monitoring framework called **VCC** that collects data from SQL Server instances, SingleStore clusters, MySQL/RDS instances, and AWS infrastructure. The goal of this investigation is to fully understand what it does before any decommission or migration decision is made.

## Server Details
| Property | Value |
|---|---|
| Hostname | EW1R-REP-01 |
| SQL Server Version | Microsoft SQL Server 2019 (RTM-CU32-GDR) 15.0.4455.2 |
| Edition | Developer Edition (64-bit) |
| OS | Windows Server 2019 Datacenter (Hypervisor/VM) |
| Collation | Latin1_General_CI_AS |
| Environment | Release/Non-Production host, monitoring Production systems |

## Repository Structure
```
01-sql-server-inventory/     # Databases, jobs, linked servers
02-grafana-inventory/        # Dashboards, datasources, alerts
03-external-targets/         # SingleStore, MySQL, RDS, AWS targets
04-consumers-and-dependencies/ # Teams, DNS, firewall, service accounts
05-classification-and-topology/ # Topology diagram, retire/replace/move
06-open-questions/           # Unknowns and escalation items
queries/                     # All SQL queries used during discovery
```

## Related Tickets
- TECH-3431 — SQL Server EC2 to Amazon RDS feasibility evaluation
- TECH-3428 — Unified database performance and capacity insights
- TECH-3409 — Aurora PostgreSQL Serverless v2 monitoring review

## Status
- [ ] SQL Server inventory complete
- [ ] Grafana inventory complete
- [ ] External targets documented
- [ ] Consumers identified
- [ ] Topology diagram published
- [ ] Retire/replace/move classification done
- [ ] Manager sign-off received
