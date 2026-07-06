# Changelog — EW1R-REP-01 Investigation

All changes to this repository, in plain English. Most recent first.

---

## 2026-07-06 — Job failure query added, counts finalised

**Ticket:** TECH-3535

- Added query 4.2 to discovery-queries.sql to investigate failed jobs via sysjobhistory
- Section 2 header updated to reflect confirmed 63 total jobs
- Section 4 header updated to reflect confirmed 109 linked servers
- WPv2 stale linked server findings documented in query comments

---

## 2026-07-06 — Stale linked server findings expanded

**Ticket:** TECH-3535

- All 4 WPv2 linked servers confirmed decommissioned (ew2p-wpv2, ew2r-wpv2, ue1p-wpv2, ue1r-wpv2)
- Additional stale SingleStore gen-rel and gen-prd nodes identified
- EW2P-MARKETING-DB confirmed unreachable — unknown owner
- open-questions.md updated with questions 24–27 covering full scope

---

## 2026-07-06 — Critical finding: WPv2 jobs failing silently

**Ticket:** TECH-3535

- Confirmed ew2p-wpv2 and ew2r-wpv2 point to decommissioned RDS instances
- DNS no longer resolves across eu-west-2 and us-east-1
- Jobs have been failing silently since 25 June 2026 with no alert firing
- Finding raised as open question — no alert target on affected MySQL jobs

---

## 2026-07-05 — Database sizes corrected, duplicate job rows removed

**Ticket:** TECH-3535

- Database sizes updated to confirmed July 2026 values — total now 378 GB
- DBA_VCC_AWS confirmed at 189,088 MB, DBA_VCC at 24,625 MB
- Duplicate job rows removed from sql-server-inventory.md

---

## 2026-07-05 — Job and linked server counts corrected

**Ticket:** TECH-3535

- SQL Agent job count corrected: 60 → 63 total, 50 → 52 enabled, 10 → 11 disabled
- Three missing jobs identified: DBA_VCC_WEEKLY_CHECKS, DBA_VCC_BASE_SERVER_MEMORY_PRESSURE_DETAILED, one additional disabled job
- Linked server count corrected: 97 → 109 total
- Extra 12 servers are gen-rel and gen-prd generation-tagged variants plus ew1d-dxm/logging, ue1p-wpv2, ue1r-wpv2

---

## 2026-07-04 — Repo aligned to evidence-only layer

**Ticket:** TECH-3535

- README rewritten — evidence/proof layer only, points to Confluence for full docs
- Jira tickets listed: TECH-3535, TECH-3478, TECH-3479, TECH-3480, TECH-3481
- .gitignore added — excludes .DS_Store and *.dtmp
- Architecture diagram committed to 07-architecture/
- Discovery queries updated

---

## 2026-07-03 — Discovery queries replaced with full verification set

- All 10 sections of discovery-queries.sql rewritten
- Covers SQL Server inventory, jobs, alerts, linked servers, cost freshness, Grafana, consumers, firewall, classification, topology

---

## 2026-07-03 — README rewritten with full investigation summary

- Critical findings documented
- Decommission blockers listed
- Aligned to TECH-3535 ticket background

---

## 2026-07-02 — Critical finding: MemSQL jobs disabled, stale data

- DBA_VCC_MEMSQL jobs confirmed disabled since May 2026
- Month-end Grafana dashboards now showing stale data
- AWS cost data stale since November 2024

---

## 2026-07-02 — DBA_VCC_COST deep dive

- Full collection flow documented — 9 entity types, 19 month-end report procedures
- Environments mapped, business impact assessed

---

## 2026-07-01 — Server value summary and topology updated

- Inbound dependencies documented
- Credential map added
- Grafana data confirmed and topology updated

---

## 2026-07-01 — Grafana alert contact points confirmed

- 2 Slack channels confirmed active
- Email placeholder confirmed not configured

---

## 2026-07-01 — Full Grafana inventory extracted

- 21 datasources, 90 dashboards, 8 users, 3 alert rules, 16 folders
- All extracted from grafana.db

---

## 2026-06-30 — Alert mechanisms and service accounts updated

- Confirmed server IP: 10.72.8.216
- Grafana port confirmed: 443 (HTTPS)
- Zabbix agent confirmed present

---

## 2026-06-30 — Job details and consumers documented

- Full job purpose details added for all SQL Agent jobs
- Consumers and dependencies section populated
- Alert mechanisms documented

---

## 2026-06-29 — Initial discovery documentation

- SQL Server inventory created
- Linked servers, jobs, databases, topology, open questions — first pass
