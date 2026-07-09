# External Targets — EW1R-REP-01

EW1R-REP-01 connects to 109 external systems via linked servers.
11 confirmed stale. Full reachability audit across all 109 still needed.

---

## SQL Server Targets

| Server | Environment | Location | Status |
|---|---|---|---|
| EW1P-OCT.CNMEBXZBEDLW.EU-WEST-1.RDS.AMAZONAWS.COM | Production | AWS RDS eu-west-1 | Active — backup job running |
| EW2P-MSSQL-01 | Production | eu-west-2 | Active — monitored |
| EW2P-MSSQL-02 | Production | eu-west-2 | Active — monitored |
| EW1D-MSSQL-01 | Dev | eu-west-1 | Monitoring disabled |
| EW1R-MSSQL-01 | Release | eu-west-1 | Monitoring disabled |

---

## SingleStore / MemSQL Cluster Nodes

> All DBA_VCC_MEMSQL jobs are currently disabled. Connectivity for all nodes needs verification.

| Node | Type | Region | Environment | Status |
|---|---|---|---|---|
| ec1p-aggr-01/02/03/04 | Aggregator | eu-central-1 | Production | Unknown |
| ec1p-leaf-01/02/03/04/51/52/53/54 | Leaf | eu-central-1 | Production | Unknown |
| ec1p-dxm | DXM | eu-central-1 | Production | Unknown |
| ec1p-dxm-logging | DXM Logging | eu-central-1 | Production | Unknown |
| ew1r-aggr-01/02/03/04/05 | Aggregator | eu-west-1 | Release | Unknown |
| ew1r-aggr-03.gen-rel | Aggregator | eu-west-1 | Generic Release | ⚠️ Stale — Can't connect (111) |
| ew1r-aggr-05.gen-rel | Aggregator | eu-west-1 | Generic Release | ⚠️ Stale — Can't connect (111) |
| ew1r-leaf-01/02/03/04/05/06/07/08 | Leaf | eu-west-1 | Release | Unknown |
| ew1r-leaf-11/12/14.gen-rel | Leaf | eu-west-1 | Generic Release | Unknown |
| ew1r-dxm | DXM | eu-west-1 | Release | Unknown |
| ew1r-dxm-logging | DXM Logging | eu-west-1 | Release | Unknown |
| ew1d-aggr-05 | Aggregator | eu-west-1 | Dev | ⚠️ Stale — Not online |
| ew1d-aggr-15 | Aggregator | eu-west-1 | Dev | ⚠️ Stale — Not online |
| ew2p-aggr-01/02/03/04 | Aggregator | eu-west-2 | Production | Unknown |
| ew2p-aggr-01/02/10/11.gen-prd | Aggregator | eu-west-2 | Generic Prod | ⚠️ Stale — Can't connect (111) |
| ew2p-leaf-01/02/03/04/05/06 | Leaf | eu-west-2 | Production | Unknown |
| ew2p-leaf-51/52/53/54/55/56 | Leaf | eu-west-2 | Production | Unknown |
| ew2p-leaf-01-04.gen-prd | Leaf | eu-west-2 | Generic Prod | Unknown |
| ew2p-leaf-11-14.gen-prd | Leaf | eu-west-2 | Generic Prod | Unknown |
| ew2p-leaf-21-24.gen-prd | Leaf | eu-west-2 | Generic Prod | Unknown |
| ew2p-leaf-51-54/61.gen-prd | Leaf | eu-west-2 | Generic Prod | Unknown |
| ew2p-dxm | DXM | eu-west-2 | Production | Unknown |
| ew2p-dxm-repl | DXM Replication | eu-west-2 | Production | Unknown |
| ew2p-dxm-logging | DXM Logging | eu-west-2 | Production | Unknown |
| ue1p-aggr-01/02/03/04 | Aggregator | us-east-1 | Production | Unknown |
| ue1p-leaf-01/02/03/04/51/52/53/54 | Leaf | us-east-1 | Production | Unknown |
| ue1p-dxm | DXM | us-east-1 | Production | Unknown |
| ue1p-dxm-repl | DXM Replication | us-east-1 | Production | Unknown |
| ue1p-dxm-logging | DXM Logging | us-east-1 | Production | Unknown |

---

## MySQL / WPv2 Targets

| Server | Type | Region | Status |
|---|---|---|---|
| ew2p-wpv2 | MySQL | eu-west-2 | ⚠️ Decommissioned — DNS gone, jobs failing daily |
| ew2r-wpv2 | MySQL | eu-west-2 | ⚠️ Decommissioned — DNS gone |
| ue1p-wpv2 | MySQL | us-east-1 | ⚠️ Decommissioned — DNS gone, jobs failing daily |
| ue1r-wpv2 | MySQL | us-east-1 | ⚠️ Decommissioned — DNS gone |

---

## Other External Systems

| Server | Type | Purpose | Status |
|---|---|---|---|
| Zabbix NonProd | MySQL | Non-prod infrastructure monitoring | Active — Grafana datasource confirmed |
| Zabbix Prod | MySQL | Prod infrastructure monitoring | Active — Grafana datasource confirmed |
| ZabbixProdOld | MySQL | Old prod Zabbix instance | Likely stale — needs confirmation |
| EW1P-NIFIREG-01 | Apache NiFi | NiFi pipeline registry | Active — Grafana JSON API datasource confirmed |
| pmmdev | Clickhouse (PMM) | Percona Monitoring dev | Unknown |
| pmmprod | Clickhouse (PMM) | Percona Monitoring prod | Unknown |
| EW1R-TC | TeamCity | TeamCity CI/CD Release environment | Confirmed — LU_EntityList Shared_Services_Non-Prod |
| ew1d-admin-01/02 | Admin servers | Dev admin | Unknown |
| EW2P-MARKETING-DB | Unknown | Marketing database | ⚠️ Stale — Not online, owner confirmed as Marketing account (AccountId 232173278818) |
| AWS CloudWatch | Python API | AWS monitoring | Active — 15-min job running |
| AWS S3 | Python API | Backup storage | Active — daily job running |
