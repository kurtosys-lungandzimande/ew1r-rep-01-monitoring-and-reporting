# TECH-3480 — Theme C: Targets & Consumers — Investigation Log

Scope: External targets, consumers, service accounts, firewall rules, dependencies.
Each entry has the question, the query, the evidence, and the finding.

> Status: External targets mapped — 109 linked servers inventoried, 11 confirmed stale. Consumers identified from query evidence — stakeholder confirmation still needed for billing/client-facing use. Full detail in consumers-and-dependencies.md and external-targets.md.

---

## 2026-07-06 — External targets: confirmed reachable vs confirmed stale

**Question:** Which external targets is this server connecting to and which are still alive?

**Method:** Job history errors from sysjobhistory and linked server list from sys.servers.
Full queries in TECH-3535-planning-and-discovery/discovery-queries.sql — Sections 4 and 11.

**Evidence — confirmed reachable:**
```
EW2P-MSSQL-01          SQL Server   Production eu-west-2   reachable (jobs succeed daily)
EW2P-MSSQL-02          SQL Server   Production eu-west-2   reachable (jobs succeed daily)
EW1P-OCT RDS           SQL Server   Production eu-west-1   reachable (backup job succeeds daily)
SingleStore aggr nodes  ODBC        eu-west-1/2, us-east-1  majority reachable
AWS CloudWatch          Python API  eu-west-2               reachable (15-min job running)
AWS S3                  Python API  eu-west-2               reachable (daily job running)
Zabbix (NonProd/Prod)   MySQL       internal                reachable (Grafana datasources active)
```

**Evidence — confirmed stale / unreachable:**
```
ew2p-wpv2    MySQL  WPv2 platform decommissioned — DNS gone eu-west-2
ew2r-wpv2    MySQL  WPv2 platform decommissioned — DNS gone eu-west-2
ue1p-wpv2    MySQL  WPv2 platform decommissioned — DNS gone us-east-1
ue1r-wpv2    MySQL  WPv2 platform decommissioned — DNS gone us-east-1
ew1d-aggr-05          SingleStore  Not online
ew1d-aggr-15          SingleStore  Not online
ew1r-aggr-03.gen-rel  SingleStore  ODBC misconfigured + unreachable
ew1r-aggr-05.gen-rel  SingleStore  Can't connect (111)
ew2p-aggr-01.gen-prd  SingleStore  Can't connect (111)
ew2p-aggr-02.gen-prd  SingleStore  Can't connect (111)
EW2P-MARKETING-DB     Unknown      Not online — owner unknown
```

**Finding:** 11 confirmed stale targets out of 109 linked servers. Full reachability audit across all 109 still needed. WPv2 cleanup is urgent — jobs failing daily. gen-rel and gen-prd nodes need platform team confirmation before removal.

---

## Consumers — not yet confirmed

**What still needs to be answered for TECH-3480:**
- Who reads DBA_VCC_COST — Finance, billing, or internal only?
- Who calls the 19 REP_MONTHEND_* stored procedures in DBA_VCC_COST?
- Are any Grafana dashboards used by clients or for SLA reporting?
- What firewall rules allow inbound connections to port 1433 and 443?
- Who depends on the Grafana alerts (Slack channels)?
