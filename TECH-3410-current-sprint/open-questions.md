# Open Questions — TECH-3478
**Ticket:** TECH-3478 — Theme A SQL Server Inventory  
**Date:** 2026-07-17 (updated with product status verification)  
**Total open questions:** 24  
**Decommission blockers:** 6  

---

## Critical — Blocks Decommission Date 🔴

These questions must be answered before any decommission date can be set.

| # | Question | Who to Ask | Source |
|---|---|---|---|
| Q1 | Is KAPP Client Utilisation and Growth Report client-facing? | tashvir.babulal / rayhaan.suleyman | DBA_VCC_COST |
| Q2 | Who consumes DBA_VCC_COST data — internal only or external? | tashvir.babulal / rayhaan.suleyman | DBA_VCC_COST |
| Q3 | Why were all 7 DBA_VCC_MEMSQL jobs disabled in May 2026 — decommission, migration, or pause? | yogeshwar.phull / tashvir.babulal | DBA_VCC_MEMSQL / Jobs |
| Q4 | Who consumes the VCC monitoring data for EW2P-MSSQL-01/02 — what breaks if this server goes away? | DBA team | DBA_VCC / Jobs |
| Q5 | What is the migration plan for VCC monitoring of EW2P-MSSQL-01/02 post-decommission? | DBA team | Jobs |
| Q6 | Who consumes AWS cost and KAPP API data from DBA_VCC_AWS — what breaks if this server goes away? | tashvir.babulal / rayhaan.suleyman | DBA_VCC_AWS |

---

## High — Immediate Action Required ⚠️

These questions relate to active failures or compliance risks that need resolution independent of decommission.

| # | Question | Who to Ask | Source |
|---|---|---|---|
| Q7 | Who is receiving the currently firing MSSQL errorlog alerts on ew2p-mssql-01 and ew2p-mssql-02 — are they being actioned? | DBA team | Zabbix |
| Q8 | Who is responsible for the missing backups and KAPP backup integrity check alerts currently firing in Zabbix? | DBA team | Zabbix |
| Q9 | Which specific step in DBA_VCC_AWS_DAILY_CHECKS is silently failing — CATCH blocks mask individual step errors? | DBA team | DBA_VCC_AWS |
| Q10 | Are the S3 backup encryption gaps (no --sse flag, NULL KMS key on EW1P-OCT) a known risk or an oversight? | DBA team / DevOps | Jobs |
| Q11 | Why is EW1R-REP-01 not in Zabbix — was it intentionally excluded from monitoring? | DBA / Monitoring team | Zabbix |
| Q12 | Should dba@kurtosys.com be wired to severity 19–25 and IO error SQL Agent alerts before decommission work begins? | DBA team | SQL Agent Alerts |

---

## Medium — Needs Answer Before Cleanup Can Proceed

| # | Question | Who to Ask | Source |
|---|---|---|---|
| Q13 | What SSIS packages does DBA - SSISStatusCheck monitor — where do they run? | DBA team | Jobs |
| Q14 | Is DBA - Maintenance - SQL Backup EW1P-OCT still needed — who owns that RDS instance? | DBA team | Jobs |
| Q15 | Why is xp_cmdshell commented out in SP_MON_PING_STATS — was this intentional? | DBA team | Jobs / DBA_VCC_MYSQL |
| Q16 | What writes to DBA_VCC_ATLASSIAN and who reads from it? | DBA team | DBA_VCC_ATLASSIAN |
| Q17 | What are EW1R-TC and EW1P-NIFIREG-01 linked servers used for? | DBA team | Linked Servers |
| Q18 | What are pmmdev and pmmprod (Clickhouse) linked servers used for — who owns them? | DBA team / Platform team | Linked Servers |
| Q19 | Can ZabbixNonProd and ZabbixProdOld linked servers be dropped — both dead? | DBA / Monitoring team | Linked Servers |
| Q20 | Confirm EW1D-MSSQL-01 and ew1r-mssql-01 are permanently retired — remove from LU_Serverlist? | DBA team | DBA_VCC |
| Q21 | Should SPSlackCheckSyncStatus be disabled given all MemSQL jobs are disabled? | DBA team | Slack Alerts |
| Q22 | When EW1R-REP-01 is decommissioned, does Zabbix connect to ew2p-mssql-01/02 directly or via this server? | Monitoring team | Zabbix |

---

## Low — Housekeeping

| # | Question | Who to Ask | Source |
|---|---|---|---|
| Q23 | Is incident.io being adopted as the primary incident management tool — should Zabbix be wired to it? | Platform / DevOps team | Zabbix |
| Q24 | Is Jabber still a valid notification channel in Zabbix — disable if not? | Monitoring team | Zabbix |

---

## Questions Answered ✅

| # | Question | Answer | Source |
|---|---|---|---|
| Q-closed-1 | Are gen-rel and gen-prd SingleStore nodes permanently retired? | Yes — confirmed dead, all 26 nodes unreachable, disabled in Zabbix | Linked Servers |
| Q-closed-2 | Is DBA_VCC_COST_Entity_Count_Collection running weekly intentionally? | Yes — confirmed weekly every Monday (freq_type=8, freq_interval=2) | Database Inventory |
| Q-closed-3 | Is MON_AWS_Entity_Cost data stale since Sept 2024? | No — last updated 2026-07-15, data is current. Specific broken step in DBA_VCC_AWS_DAILY_CHECKS still to be identified | Database Inventory |
| Q-closed-4 | Is InvestorPress still an active product? | No — confirmed decommissioned. Procs last modified May 2023, 2,047 rows in live table, zero Zabbix triggers firing. Safe to clean up | Product Verification |
| Q-closed-5 | Is Encore still an active product? | Yes — confirmed active. `INFO_Encore_Document_Production_Detail` collecting as of 2026-07-17 today. Independent of MemSQL | Product Verification |
| Q-closed-6 | Was KAPP affected by the May 2026 MemSQL job disable? | Yes — KAPP workflow history stopped 2026-05-08. 268K + 296K rows. Procs maintained Nov 2024. Was active product when jobs were disabled | Product Verification |
| Q-closed-7 | Was FinancialPortal affected by the May 2026 MemSQL job disable? | Yes — FP client data stopped 2026-05-08. 556K rows. Most recently maintained proc on server (Oct 2024). Was active product when jobs were disabled | Product Verification |

---

## Summary by Owner

| Owner | Open Questions |
|---|---|
| tashvir.babulal / rayhaan.suleyman | Q1, Q2, Q6 |
| yogeshwar.phull / tashvir.babulal | Q3 |
| DBA team | Q4, Q5, Q7, Q8, Q9, Q10, Q11, Q12, Q13, Q14, Q15, Q16, Q17, Q18, Q19, Q20, Q21 |
| DBA team / DevOps | Q10 |
| Monitoring team | Q19, Q22, Q24 |
| Platform / DevOps team | Q23 |
