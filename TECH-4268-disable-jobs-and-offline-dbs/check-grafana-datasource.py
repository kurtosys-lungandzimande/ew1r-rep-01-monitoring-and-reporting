import sqlite3, json

db = sqlite3.connect(r"C:\Program Files\GrafanaLabs\grafana\data\grafana.db")
cur = db.cursor()

cur.execute("""
    SELECT title, data
    FROM dashboard
    WHERE is_folder = 0
    AND (title LIKE '%Client Config%' OR title LIKE '%Auth Config%')
""")

rows = cur.fetchall()

for title, data_json in rows:
    print("=" * 60)
    print("Dashboard:", title)
    d = json.loads(data_json)
    for panel in d.get("panels", []):
        ds = panel.get("datasource")
        if ds:
            print("  Panel:", panel.get("title", "(no title)"))
            print("  Datasource:", ds)
    # also check alert definitions inside panels
    for panel in d.get("panels", []):
        alert = panel.get("alert")
        if alert:
            print("  Alert name:", alert.get("name"))
            for cond in alert.get("conditions", []):
                q = cond.get("query", {})
                print("  Alert datasource:", q.get("datasourceId"), q.get("params"))

db.close()
