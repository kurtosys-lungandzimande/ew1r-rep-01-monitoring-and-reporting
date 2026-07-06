# External Targets — EW1R-REP-01

## Overview
EW1R-REP-01 connects to 97 external systems via linked servers. These are the systems this server monitors, queries, or integrates with.

---

## SQL Server Targets

| Server | Provider | Environment | Location | Status |
|---|---|---|---|---|
| EW1P-OCT.CNMEBXZBEDLW.EU-WEST-1.RDS.AMAZONAWS.COM | SQLNCLI | Production | AWS RDS eu-west-1 | Active — backup job running |
| EW1D-MSSQL-01 | SQLNCLI | Dev | EU-West-1 | Monitoring disabled |
| EW1R-MSSQL-01 | SQLNCLI | Release | EU-West-1 | Monitoring disabled |
| EW2P-MSSQL-01 | SQLNCLI | Production | EU-West-2 | Active — monitored |
| EW2P-MSSQL-02 | SQLNCLI | Production | EU-West-2 | Active — monitored |
| ew1p-oct | SQLNCLI | Production | EU-West-1 | Likely alias for RDS above |

---

## SingleStore / MemSQL Cluster Nodes

> Note: All DBA_VCC_MEMSQL jobs are currently disabled. These linked servers may be stale. Connectivity needs verification.

### EC1 Region (eu-central-1)
| Node | Type | Environment |
|---|---|---|
| ec1p-aggr-01/02/03/04 | Aggregator | Production |
| ec1p-leaf-01/02/03/04/51/52/53/54 | Leaf | Production |
| ec1p-dxm | DXM | Production |
| ec1p-dxm-logging | DXM Logging | Production |

### EW1 Region (eu-west-1)
| Node | Type | Environment |
|---|---|---|
| ew1r-aggr-01/02/03/04/05 | Aggregator | Release |
| ew1r-aggr-03.gen-rel / ew1r-aggr-05.gen-rel | Aggregator | Generic Release |
| ew1r-leaf-01/02/03/04/05/06/07/08 | Leaf | Release |
| ew1r-leaf-11/12/14.gen-rel | Leaf | Generic Release |
| ew1r-dxm | DXM | Release |
| ew1r-dxm-logging | DXM Logging | Release |

### EW2 Region (eu-west-2)
| Node | Type | Environment |
|---|---|---|
| ew2p-aggr-01/02/03/04 | Aggregator | Production |
| ew2p-aggr-01/02/10/11.gen-prd | Aggregator | Generic Prod |
| ew2p-leaf-01/02/03/04/05/06 | Leaf | Production |
| ew2p-leaf-51/52/53/54/55/56 | Leaf | Production |
| ew2p-leaf-01-04.gen-prd | Leaf | Generic Prod |
| ew2p-leaf-11-14.gen-prd | Leaf | Generic Prod |
| ew2p-leaf-21-24.gen-prd | Leaf | Generic Prod |
| ew2p-leaf-51-54/61.gen-prd | Leaf | Generic Prod |
| ew2p-dxm | DXM | Production |
| ew2p-dxm-repl | DXM Replication | Production |
| ew2p-dxm-logging | DXM Logging | Production |

### UE1 Region (us-east-1)
| Node | Type | Environment |
|---|---|---|
| ue1p-aggr-01/02/03/04 | Aggregator | Production |
| ue1p-leaf-01/02/03/04/51/52/53/54 | Leaf | Production |
| ue1p-dxm | DXM | Production |
| ue1p-dxm-repl | DXM Replication | Production |
| ue1p-dxm-logging | DXM Logging | Production |

---

## Other External Systems

| Server | Type | Purpose | Status |
|---|---|---|---|
| pmmdev | Clickhouse (PMM) | Percona Monitoring — dev | Unknown |
| pmmprod | Clickhouse (PMM) | Percona Monitoring — prod | Unknown |
| ZabbixNonProd | Zabbix | Non-prod infrastructure monitoring | Unknown |
| ZabbixProdOld | Zabbix | Old prod Zabbix instance | Likely stale |
| ZabbixProdNew | Zabbix | Current prod Zabbix instance | Unknown |
| EW1P-NIFIREG-01 | Apache NiFi Registry | NiFi pipeline registry | Unknown |
| EW1R-TC | Unknown | Likely TeamCity CI/CD | Unknown |
| ew1d-admin-01/02 | Admin servers | Dev admin | Unknown |
| ew2p-wpv2 / ew2r-wpv2 | Web Platform v2 | EW2 web platform nodes | Unknown |
| ue1p-wpv2 / ue1r-wpv2 | Web Platform v2 | UE1 web platform nodes | Unknown |
| ew1r-leaf-01.gen-prd | SingleStore | Generic prod leaf | Unknown |

---

## Open Questions
- [ ] Are all SingleStore linked servers still reachable? Run connectivity test
- [ ] What does EW1R-TC resolve to — is it TeamCity?
- [ ] Are wpv2 nodes web servers or database nodes?
- [ ] Is ZabbixProdOld still active or can it be removed?
- [ ] What credentials are used for each linked server — check vault
