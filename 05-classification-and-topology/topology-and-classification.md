# Topology & Classification — EW1R-REP-01

> Status: IN PROGRESS — Grafana and consumer sections incomplete pending access

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
│   │   └── wpv2 nodes (Web Platform v2 — EW2, UE1)
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
└── Grafana (port TBC)
    ├── Datasources → likely DBA_VCC_* databases (TBC)
    ├── Dashboards → TBC (pending access)
    ├── Alert rules → TBC
    └── Consumers → TBC (pending team identification)
```

---

## Component Classification

> Legend: **Retire** = no longer needed | **Replace** = move to another platform | **Move** = keep but relocate

| Component | Classification | Rationale | Target (if Replace/Move) |
|---|---|---|---|
| DBA_VCC_AWS (KAPP monitoring) | Replace | Core KAPP observability — cannot retire | TECH-3428 unified monitoring |
| DBA_VCC_MYSQL (MySQL monitoring) | Replace | Active MySQL/RDS monitoring | TECH-3428 or CloudWatch |
| DBA_VCC_COST (Cost tracking) | Replace | FULL recovery model — someone needs this | TBC — identify consumer first |
| DBA_VCC_MEMSQL (MemSQL monitoring) | Retire | All jobs disabled, likely superseded | N/A |
| DBA_VCC_ATLASSIAN (Jira integration) | Investigate | Unknown consumer — needs confirmation | TBC |
| KURTOSYS_BASELINE | Investigate | Large (51GB) — unknown active consumer | TBC |
| SingleStore linked servers (97) | Retire | All MemSQL jobs disabled | N/A |
| SQL Server linked servers (active) | Move | Still needed for monitoring EW2P servers | New monitoring host |
| Grafana dashboards | Replace/Move | TBC pending inventory | Grafana Cloud or new host |
| DBA Maintenance jobs | Move | Standard maintenance — needed on any host | New SQL Server host |
| VCC AWS jobs (15min/daily/weekly) | Replace | AWS monitoring — move to CloudWatch/native | TECH-3428 |
| VCC MySQL jobs | Replace | MySQL monitoring | TECH-3428 or CloudWatch |
| VCC MemSQL jobs | Retire | All disabled | N/A |
| Jira month-end job | Investigate | Unknown consumer | TBC |
| EW1P-OCT backup job | Investigate | Is this RDS backup still needed? | TBC |

---

## Risk Assessment

| Risk | Severity | Notes |
|---|---|---|
| KAPP API monitoring loss | Critical | 563M rows actively collected — likely used for SLA/troubleshooting |
| Grafana dashboard loss | High | Unknown consumers — could affect engineering/ops visibility |
| Cost tracking loss | High | DBA_VCC_COST on FULL recovery — someone values this data |
| MySQL/RDS monitoring loss | High | Active jobs monitoring production RDS |
| Backup job loss (EW1P-OCT) | Medium | RDS backup may have native alternatives |
| MemSQL linked servers | Low | All jobs disabled — likely already migrated |

---

## Recommendation (Preliminary)

> **Do not decommission until:**
> 1. Grafana consumers are identified
> 2. KAPP monitoring data ownership is confirmed
> 3. DBA_VCC_COST consumer is identified
> 4. Replacement monitoring is in place (TECH-3428)

This server is **not safe to decommission** based on current evidence. It is actively collecting production KAPP data and monitoring production SQL Server and MySQL instances.
