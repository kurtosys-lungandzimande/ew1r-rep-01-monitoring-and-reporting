# TECH-3479 — Theme B: Grafana — Investigation Log

Scope: Grafana inventory — datasources, dashboards, users, alert rules, contact points.
Each entry has the question, the query, the evidence, and the finding.

> Status: Initial inventory complete. Not being investigated further in current sprint (TECH-3535).
> Full Grafana investigation deferred to when TECH-3479 is picked up.

---

## 2026-07-01 — Full Grafana inventory extracted from grafana.db

**Question:** What datasources, dashboards, users, and alert rules does Grafana have?

**Method:** Python scripts via xp_cmdshell reading grafana.db (SQLite) directly.
Full queries in TECH-3535-planning-and-discovery/discovery-queries.sql — Section 9.

**Evidence:**
```
Datasources: 21 total
  DBA_VCC (localhost MSSQL — Windows auth)
  KAPP MySQL: Dev, Rel, UK Prod, EU Prod, US Prod
  SingleStore: Dev, Rel, UK Prod, EU Prod, US Prod
  Zabbix MySQL: NonProd, Prod Old, Prod New, Prod 4  ← all use donovan.vangraan credentials
  NiFi JSON API, CloudWatch (IAM role), InfluxDB
  [3 additional]

Users: 8 total
  tashvir.babulal    admin   last_seen 2026-06-28   active
  yogeshwar.phull    admin   last_seen 2026-06-15   active
  rayhaan.suleyman   admin   last_seen 2026-06-30   active
  donovan.vangraan   editor  last_seen 2024-11-12   INACTIVE — credentials still in 4 datasources
  [4 additional viewer accounts]

Dashboards: 90 across 16 folders
  KAPP and SingleStore dashboards last updated Oct/Nov 2025 — actively used
  Month End Reporting dashboards exist but data stale since May 2026

Alert rules: 3
  Failed Read Queries per Second        → alerts-data-operations (Slack)
  KAPP Client Config Alert              → alerts-data-operations (Slack)
  KAPP Client Application Auth Config   → alert-app-allow2fa-disabled (Slack)

Contact points:
  alerts-data-operations       Slack  active
  alert-app-allow2fa-disabled  Slack  active
  email                        Email  placeholder — no address set, will not deliver
```

**Finding:** Grafana reads directly from DBA_VCC on localhost. 4 Zabbix datasources use donovan.vangraan credentials — he has not logged in since November 2024 and is no longer active. His credentials need to be rotated before decommission. Email contact point is a placeholder and will never deliver alerts. Month-end dashboards are showing stale data since May 2026 due to MemSQL jobs being disabled — nobody has flagged this.

**Open questions for TECH-3479:**
- Are any dashboards client-facing or SLA-related? (Month End Reporting and KAPP Client reports are candidates)
- Which teams use the dashboards — engineering only or wider?
- Confirm with tashvir.babulal / rayhaan.suleyman before decommission decision
