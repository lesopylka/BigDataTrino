import csv
import os
from pathlib import Path
import psycopg
import requests


def main():
    mode = os.getenv("LOAD_MODE", "postgres")
    files = sorted(Path("data").glob("*.csv"), key=lambda p: 0 if p.stem == "MOCK_DATA" else int(p.stem.split("(")[1].rstrip(")")))
    if len(files) != 10:
        raise ValueError("Ожидалось 10 CSV")
    if mode == "split":
        response = requests.post("http://clickhouse:8123/", auth=("lab", "lab"), data="TRUNCATE TABLE lab.mock_data", timeout=30)
        response.raise_for_status()
    with psycopg.connect("host=postgres dbname=postgres user=postgres password=postgres") as conn:
        with conn.cursor() as cur:
            cur.execute("TRUNCATE public.mock_data")
            for number, path in enumerate(files):
                with path.open(encoding="utf-8", newline="") as source:
                    rows = list(csv.DictReader(source))
                if len(rows) != 1000:
                    raise ValueError(f"Неверное количество строк: {path}")
                for row in rows:
                    row = {"source_file": path.name, "sale_key": f"{path.name}:{row['id']}", **row}
                    if mode == "split" and number < 5:
                        response = requests.post("http://clickhouse:8123/", params={"query": "INSERT INTO lab.mock_data FORMAT JSONEachRow"}, auth=("lab", "lab"), data=__import__('json').dumps(row).encode(), timeout=30)
                        response.raise_for_status()
                    else:
                        names = ", ".join(row)
                        placeholders = ", ".join(["%s"] * len(row))
                        cur.execute(f"INSERT INTO public.mock_data ({names}) VALUES ({placeholders})", list(row.values()))
    print("Исходные данные загружены")


if __name__ == "__main__":
    main()
