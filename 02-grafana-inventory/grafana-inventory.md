# Grafana Inventory — EW1R-REP-01

> Status: PENDING — Grafana URL/port not yet confirmed. Discovery steps documented below.

---

## Access Details

| Property | Value |
|---|---|
| Expected URL | http://ew1r-rep-01:3000 (default Grafana port — unconfirmed) |
| Actual URL/DNS | Unknown — pending discovery |
| Auth method | Unknown |
| Version | Unknown |

### How to Find Grafana Port
Run on the server via xp_cmdshell (if enabled):
```sql
EXEC xp_cmdshell 'netstat -ano | findstr LISTENING | findstr ":3000"';
EXEC xp_cmdshell 'sc query grafana';
EXEC xp_cmdshell 'sc query "Grafana"';
```

Or check Windows services via RDP:
- Open services.msc
- Search for "Grafana"
- Note the port from the service properties or grafana.ini config file
- Default config location: C:\Program Files\GrafanaLabs\grafana\conf\grafana.ini

---

## Datasources

> To be completed once Grafana access is confirmed.

| Name | Type | Host/Target | Database | Notes |
|---|---|---|---|---|
| TBC | TBC | TBC | TBC | Likely reads from DBA_VCC_* databases |

---

## Dashboard Inventory

> To be completed once Grafana access is confirmed.
> Folder names are sufficient — flag any business-critical items.

| Folder | Dashboard Name | Business Critical | Notes |
|---|---|---|---|
| TBC | TBC | TBC | TBC |

---

## Alert Rules

> To be completed once Grafana access is confirmed.

| Alert Name | Condition | Notification Channel | Recipients | Notes |
|---|---|---|---|---|
| TBC | TBC | TBC | TBC | TBC |

---

## Users and Access

> To be completed once Grafana access is confirmed.

| User/Team | Role | Notes |
|---|---|---|
| TBC | TBC | TBC |

---

## Open Questions

- [ ] What is the Grafana URL and port?
- [ ] What datasources are configured — do they point to DBA_VCC_* databases?
- [ ] Which dashboards are actively used vs abandoned?
- [ ] Are any dashboards client-facing or SLA-related?
- [ ] Who has admin access to Grafana?
- [ ] Are there active alert notification channels (email, Slack, PagerDuty)?
- [ ] Is Grafana version current or end-of-life?
