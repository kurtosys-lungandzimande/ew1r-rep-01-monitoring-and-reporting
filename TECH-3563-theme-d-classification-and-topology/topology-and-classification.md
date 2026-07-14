# Topology & Classification — EW1R-REP-01

> Status: IN PROGRESS — Themes A, B, C complete. All confirmed findings incorporated. Remaining blockers are stakeholder input (Q13, Q21, Q22, Q23, Q35, Q36) — documented in open-questions.md.

---

## Topology (Current Understanding)

```
EW1R-REP-01 (Custom VCC Monitoring Hub)
│
├── SQL Server 2019 Developer Edition
│   │
│   ├── COLLECTS FROM (SQL Server — SQLNCLI)
│   │   ├── EW2P-MSSQL-01 (Production — EU-West-2) ← Active
│   │   ├── EW2P-MSSQL-02 (Production — EU-West-2) ← Active
│   │   ├── EW1P-OCT RDS (Production RDS — EU-West-1) ← Backup job active
│   │   ├── EW1D-MSSQL-01 (Dev) ← Monitoring disabled
│   │   └── EW1R-MSSQL-01 (Release) ← Monitoring disabled
│   │
│   ├── COLLECTS FROM (SingleStore — MSDASQL/ODBC)
│   │   ├── EC1 cluster (4 aggr + 8 leaf + 2 dxm nodes) ← Jobs DISABLED
│   │   ├── EW1 cluster (5 aggr + 11 leaf + 2 dxm nodes) ← Jobs DISABLED
│   │   ├── EW2 cluster (6 aggr + 20 leaf + 3 dxm nodes) ← Jobs DISABLED
│   │   └── UE1 cluster (4 aggr + 8 leaf + 3 dxm nodes) ← Jobs DISABLED
│   │
│   ├── COLLECTS FROM (Other — MSDASQL)
│   │   ├── pmmdev / pmmprod (Clickhouse/PMM)
│   │   ├── ZabbixNonProd / ZabbixProdOld / ZabbixProdNew
│   │   ├── EW1P-NIFIREG-01 (NiFi Registry)
│   │   └── wpv2 nodes (Web Platform v2 — EW2, UE1) ← DECOMMISSIONED — DNS gone, jobs failing
│   │
│   ├── STORES IN (Local databases)
│   │   ├── DBA_VCC_AWS (180 GB) — AWS + KAPP API monitoring
│   │   ├── DBA_VCC_MEMSQL (77 GB) — SingleStore monitoring (inactive)
│   │   ├── KURTOSYS_BASELINE (51 GB) — Performance baselines
│   │   ├── DBA_VCC_MYSQL (26 GB) — MySQL/RDS monitoring
│   │   ├── DBA_VCC (21 GB) — Core framework + Encore logs
│   │   ├── DBA_VCC_COST (5 GB) — Cost tracking per entity
│   │   └── DBA_VCC_ATLASSIAN (2 GB) — Jira/Confluence integration
│   │
│   └── INTEGRATES WITH
│       ├── Jira/Confluence (DBA_VCC_JIRA_MONTHEND_CHECKS)
│       └── dba@kurtosys.com (maintenance alerts)
│
└── Grafana 9.5.2 (port 443 HTTPS)
    ├── READS FROM (Datasources — 21 confirmed)
    │   ├── DBA_VCC on localhost (MSSQL)
    │   ├── KAPP MySQL — Dev, Release, UK/EU/US Prod
    │   ├── SingleStore — Dev, Release, UK/EU/US Prod
    │   ├── Zabbix MySQL — NonProd, Prod Old, Prod New (x4)
    │   ├── NiFi JSON API — https://10.125.9.192:8443
    │   ├── AWS CloudWatch
    │   └── InfluxDB
    ├── DASHBOARDS (74 total across 16 folders)
    │   ├── KAPP Reporting — actively updated Oct/Nov 2025 ← CRITICAL
    │   ├── SingleStore Monitoring — updated Aug 2025 ← CRITICAL
    │   ├── Month End Reporting — KAPP/Encore/DXM/WPv2/InvestorPress
    │   ├── AWS Reports — S3/RDS/EC2/Cost/Security
    │   ├── Encore Reporting
    │   ├── Atlassian/Jira Reporting
    │   ├── Performance Dashboards
    │   └── Zabbix Monitoring
    ├── ALERT RULES (3)
    │   ├── Failed Read Queries per Second → Slack: alerts-data-operations
    │   ├── KAPP Client Config Alert → Slack: alerts-data-operations
    │   └── KAPP Client Application Auth Config Alert → Slack: alert-app-allow2fa-disabled
    └── ACTIVE USERS (last seen 2026)
        ├── tashvir.babulal (admin)
        ├── yogeshwar.phull (admin)
        └── rayhaan.suleyman (admin)
```

---

## What This Server Does — Value Summary

> This section answers: why does this server exist, what value does it provide, and what would break without it.

### What It Collects
| Data Source | Method | Frequency | Stored In | Value |
|---|---|---|---|---|
| KAPP API query logs | Python API calls via SQL Agent | Every 30 min | DBA_VCC_AWS | Core KAPP observability — 563M rows |
| AWS costs per entity | Python API calls | Daily | DBA_VCC_AWS | Cost tracking per client/entity |
| AWS infrastructure (EC2, RDS, S3) | Python API calls | Weekly | DBA_VCC_AWS | AWS inventory and security posture |
| Encore IIS logs | CloudWatch log stream | Hourly | DBA_VCC | Encore document production tracking |
| BNY IIS logs | CloudWatch log stream | Hourly | DBA_VCC | BNY integration monitoring |
| MySQL/DXM/WPv2 client sizes | MySQL linked servers | Daily | DBA_VCC_MYSQL | Client size tracking |
| Cost entity counts | Stored procs | Scheduled | DBA_VCC_COST | Per-client entity billing/reporting |
| Jira sprint data | Python API calls | Monthly | DBA_VCC_ATLASSIAN | Engineering sprint reporting |
| SQL Server health (EW2P-MSSQL-01/02) | Linked servers | Scheduled | DBA_VCC | Production SQL Server monitoring |
| Performance baselines | Linked servers | Scheduled | KURTOSYS_BASELINE | Connection and table size baselines |

### What It Serves
| Consumer | What They Get | How Critical |
|---|---|---|
| tashvir.babulal, yogeshwar.phull, rayhaan.suleyman | 74 Grafana dashboards across KAPP, SingleStore, AWS, Encore, Zabbix, Jira | Critical |
| alerts-data-operations Slack channel | KAPP client config and read query failure alerts | High |
| alert-app-allow2fa-disabled Slack channel | KAPP client auth config alerts | High |
| dba@kurtosys.com | SQL Agent job failure alerts (backups, CHECKDB, disk space) | High |

### What It Needs To Function (Inbound Dependencies)
| Dependency | Type | Port | Purpose | Confirmed |
|---|---|---|---|---|
| Domain controller | Active Directory | 389/636 | Service account auth | Yes |
| AWS APIs (CloudWatch, S3, EC2, RDS, IAM) | HTTPS outbound | 443 | Python API data collection | Yes — jobs running |
| Jira API | HTTPS outbound | 443 | Monthly sprint data pull | Yes — job running |
| KAPP MySQL — Dev (10.61.11.70) | MySQL outbound | 3306 | Grafana datasource | Yes — confirmed in grafana.db |
| KAPP MySQL — Release (10.77.3.236) | MySQL outbound | 3306 | Grafana datasource | Yes — confirmed in grafana.db |
| KAPP MySQL — UK Prod (10.121.29.82) | MySQL outbound | 3306 | Grafana datasource | Yes — confirmed in grafana.db |
| KAPP MySQL — EU Prod (10.125.6.134) | MySQL outbound | 3306 | Grafana datasource | Yes — confirmed in grafana.db |
| KAPP MySQL — US Prod (10.128.30.6) | MySQL outbound | 3306 | Grafana datasource | Yes — confirmed in grafana.db |
| SingleStore UK Prod (10.121.22.219) | MySQL outbound | 3306 | Grafana datasource | Yes — confirmed in grafana.db |
| SingleStore EU Prod (10.125.12.126) | MySQL outbound | 3306 | Grafana datasource | Yes — confirmed in grafana.db |
| SingleStore US Prod (10.128.24.122) | MySQL outbound | 3306 | Grafana datasource | Yes — confirmed in grafana.db |
| Zabbix Prod MySQL (10.120.8.51) | MySQL outbound | 3306 | Grafana datasource | Yes — confirmed in grafana.db |
| Zabbix NonProd MySQL (10.72.8.186) | MySQL outbound | 3306 | Grafana datasource | Yes — confirmed in grafana.db |
| NiFi API (10.125.9.192:8443) | HTTPS outbound | 8443 | Grafana JSON datasource | Yes — confirmed in grafana.db |
| EW2P-MSSQL-01/02 | SQL Server outbound | 1433 | VCC monitoring collection | Yes — jobs running |
| EW1P-OCT RDS | SQL Server outbound | 1433 | Backup job | Yes — job running |
| S3 bucket (ARN unknown) | HTTPS outbound | 443 | Backup destination | Yes — job running, 30-day retention confirmed, bucket ARN TBC |
| Slack webhook (alerts-data-operations) | HTTPS outbound | 443 | Grafana alert delivery | Yes — confirmed in grafana.db |
| Slack webhook (alert-app-allow2fa-disabled) | HTTPS outbound | 443 | Grafana alert delivery | Yes — confirmed in grafana.db |
| Grafana clients (browsers) | HTTPS inbound | 443 | Dashboard access | Yes — 3 active users |
| DBA team (SSMS) | SQL Server inbound | 1433 | Server management | Yes |
| Zabbix server | TCP inbound | 10050 | Infrastructure monitoring of this server | Yes — zabbix_agentd.exe running |

### What Credentials It Uses

> Credential details are not documented here. Contact the DBA team or DevOps for credential information.

| Purpose | Status |
|---|---|
| SQL Server Engine service account | Confirmed — AD domain account |
| SQL Server Agent service account | Confirmed — AD domain account |
| AWS API calls | ⚠️ Still unknown — needs DevOps/cloud team |
| Grafana → SQL Server | Confirmed — SQL login on localhost |
| Grafana → KAPP MySQL | Confirmed — confirmed in grafana.db |
| Grafana → SingleStore | Confirmed — confirmed in grafana.db |
| Grafana → Zabbix MySQL | ⚠️ Needs rotation — ex-employee account, inactive since Nov 2024 |
| Linked server → SQL Server targets | ⚠️ Still unknown — needs vault check |
| Linked server → MySQL/SingleStore | ⚠️ Still unknown — needs vault check |
| Slack webhooks | Confirmed — encrypted, Grafana admin required to rotate |

> **Security flag:** Grafana Zabbix datasources use a personal account belonging to an ex-employee inactive since Nov 2024. These credentials need to be rotated immediately regardless of decommission decision.

---

## Component Classification

> Legend: **Retire** = no longer needed | **Replace** = move to another platform | **Move** = keep but relocate

| Component | Classification | Rationale | Target (if Replace/Move) |
|---|---|---|---|
| DBA_VCC_AWS (KAPP monitoring) | Replace | Core KAPP observability — cannot retire | TECH-3428 unified monitoring |
| DBA_VCC_MYSQL (MySQL monitoring) | Replace | Active MySQL/RDS monitoring | TECH-3428 or CloudWatch |
| DBA_VCC_COST (Cost tracking) | Replace | ⚠️ Confirmed client billing data — 200+ institutional clients tracked across EW2, UE1, EC1. Collection stale since 4 May 2026. Cannot retire without confirmed replacement and stakeholder sign-off. | TECH-3428 or dedicated billing host |
| DBA_VCC_MEMSQL (MemSQL monitoring) | Retire | All jobs disabled, likely superseded | N/A |
| DBA_VCC_ATLASSIAN (Jira integration) | Investigate | Unknown consumer — needs confirmation | TBC |
| KURTOSYS_BASELINE | Investigate | Large (51GB) — unknown active consumer | TBC |
| SingleStore linked servers (90) | Retire | All MemSQL jobs disabled | N/A |
| SQL Server linked servers (active) | Move | Still needed for monitoring EW2P servers | New monitoring host |
| Grafana dashboards | Replace/Move | 74 dashboards confirmed, 3 active admins, actively used Oct 2025 — cannot retire | Grafana Cloud or new host |
| DBA Maintenance jobs | Move | Standard maintenance — needed on any host | New SQL Server host |
| VCC AWS jobs (30min/daily/weekly) | Replace | AWS monitoring — move to CloudWatch/native | TECH-3428 |
| VCC MySQL jobs | Replace | MySQL monitoring | TECH-3428 or CloudWatch |
| VCC MemSQL jobs | Retire | All disabled | N/A |
| Jira month-end job | Investigate | Unknown consumer | TBC |
| EW1P-OCT backup job | Investigate | Is this RDS backup still needed? | TBC |

---

## Risk Assessment

| Risk | Severity | Notes |
|---|---|---|
| KAPP API monitoring loss | Critical | 563M rows actively collected — Grafana KAPP dashboards updated Oct 2025, actively used |
| Grafana dashboard loss | Critical | 3 active admins as of June 2026 — 74 dashboards confirmed including production KAPP metrics |
| SingleStore monitoring loss | Critical | Grafana reads directly from SingleStore UK/EU/US Prod — dashboards updated Aug 2025 |
| Cost tracking loss | Critical | DBA_VCC_COST confirmed client billing data — 200+ real institutional clients (BlackRock, BNY Mellon, Aberdeen, Wellington, T. Rowe Price, Nordea and others). Collection already stale since 4 May 2026. Decommissioning without a confirmed replacement directly impacts client invoicing. |
| MySQL/RDS monitoring loss | High | Active jobs monitoring production RDS + Grafana reads KAPP MySQL directly |
| Zabbix datasource loss | High | Grafana reads 4 Zabbix MySQL databases directly — Zabbix monitoring dashboards active |
| NiFi API reporting loss | Medium | Grafana JSON datasource reads NiFi API — NiFi API Reporting dashboard active |
| Backup job loss (EW1P-OCT) | Medium | RDS backup may have native alternatives — confirm Monday |
| MemSQL linked servers | Low | All jobs disabled — likely already migrated |

---

## Recommendation (Preliminary)

> **Do not decommission until:**
> 1. ~~DBA_VCC_COST consumer is identified~~ — **Closed** — confirmed client billing data, 200+ institutional clients
> 2. KAPP monitoring data ownership confirmed — who depends on DBA_VCC_AWS for SLA reporting? (Q13)
> 3. tashvir.babulal / rayhaan.suleyman confirm which Grafana dashboards are client-facing or SLA-related (Q21, Q22)
> 4. Who disabled DBA_VCC_MEMSQL jobs in May 2026 and why — must be understood before any re-enable (Q35)
> 5. Stakeholders notified that DBA_VCC_COST billing data has been stale since 4 May 2026 (Q36)
> 6. donovan.vangraan Zabbix credentials rotated — 4 Grafana datasources still using his account
> 7. Replacement monitoring confirmed in place (TECH-3428)
> 8. All 3 active Grafana admins notified and migrated to replacement
> 9. Slack alert channels (alerts-data-operations, alert-app-allow2fa-disabled) re-routed

This server is **not safe to decommission** based on current evidence. It is:
- Actively collecting production KAPP, MySQL, and AWS data every 30 minutes
- Serving 74 Grafana dashboards to at least 3 active users as of June 2026
- The sole source of SingleStore and Zabbix monitoring dashboards
- Running production Slack alerts for KAPP client config and read query failures

---

## Open Questions — Decommission Blockers

> These must be answered before any decommission or migration action is taken.
> Full question log with all supporting context is in TECH-3535-planning-and-discovery/open-questions.md.

| # | Question | Who to Ask | Status |
|---|---|---|---|
| Q13 | Who owns the KAPP monitoring data in DBA_VCC_AWS? Is it used for SLA reporting? If yes — cannot decommission without a confirmed replacement in place. | KAPP engineering / platform team | ⚠️ Open |
| Q21 | If this server went offline today, what would break immediately? | yogeshwar.phull / tashvir.babulal | ⚠️ Open |
| Q22 | Is any alerting dependent solely on this server — would anyone lose visibility? | yogeshwar.phull / tashvir.babulal | ⚠️ Open |
| Q23 | Is the VCC framework replicated anywhere else or is this the only instance? | DBA team | ⚠️ Open |
| Q35 | Who disabled the DBA_VCC_MEMSQL jobs in May 2026 and why? Was the DAILY_CHECKS failure on 8 May 2026 ever investigated? Jobs must not be re-enabled without understanding the root cause. | yogeshwar.phull / tashvir.babulal | ⚠️ Open |
| Q36 | Has anyone noticed that DBA_VCC_COST client entity counts have been stale since 4 May 2026? The KAPP Client Utilisation and Growth Report dashboard is showing 2-month-old billing data. Whoever uses that report for invoicing has been working with wrong figures since May with no warning. Must be disclosed immediately. | tashvir.babulal / rayhaan.suleyman | ⚠️ Open — must disclose now |
