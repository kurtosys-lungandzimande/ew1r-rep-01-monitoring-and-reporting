# TECH-3306 — Remove Temporary Read-Only Access from TROWEPRICE

## Ticket summary
Remove the temporary `db_datareader` access granted to `ram.jeyaraman` on the `TROWEPRICE` production database (`ew2p-mssql-01.gen-prd.kurtosys-internal.net`), originally granted under KSYS-11462 / TECH-2245.

## Definition of Done
- [ ] Confirmation received from Ram that access is no longer needed
- [ ] Read-only access revoked
- [ ] `ram.jeyaraman` user removed
- [ ] Changes verified and documented in this ticket

---

## Pre-requisites
- [ ] Ram Jeyaraman has confirmed in TECH-3306 comments that access is no longer required
- [ ] Dev test passed: `dev_setup_test_kuhle_konke.sql` → `dev_test_revoke_kuhle_konke.sql` on `Utilities` dev database

---

## Execution order

| Step | Script | Environment |
|------|--------|-------------|
| 1 | `dev_setup_test_kuhle_konke.sql` | DEV — Utilities |
| 2 | `dev_test_revoke_kuhle_konke.sql` | DEV — Utilities |
| 3 | `revoke_ram_jeyaraman_TROWEPRICE.sql` | PROD — ew2p-mssql-01 / TROWEPRICE |

---

## Change log

| Date | Action | Executed by | Result |
|------|--------|-------------|--------|
|      | Dev setup: created kuhle.konke on Utilities | | |
|      | Dev revoke test: removed kuhle.konke from Utilities | | |
|      | Production: revoked ram.jeyaraman from TROWEPRICE | | |

---

## Post-revoke verification results
Paste Step 5 output from `revoke_ram_jeyaraman_TROWEPRICE.sql` here (all queries must return 0 rows).

```
-- database_user query: 0 rows
-- role membership query: 0 rows
-- server_login query: 0 rows
```

---

## Related tickets
- TECH-2245 — original access grant
- KSYS-11462 — investigation that required the access
- SB-23093 / Salesforce case 00204716 — client ticket
