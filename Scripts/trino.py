import time
from pathlib import Path
import requests


def execute(query):
    session = requests.Session()
    session.headers.update({"X-Trino-User": "lab", "X-Trino-Catalog": "clickhouse", "X-Trino-Schema": "lab"})
    response = session.post("http://trino:8080/v1/statement", data=query.encode("utf-8"), timeout=120)
    response.raise_for_status()
    rows = []
    while True:
        result = response.json()
        if "error" in result:
            raise RuntimeError(result["error"])
        rows.extend(result.get("data", []))
        if "nextUri" not in result:
            return rows
        time.sleep(0.1)
        response = session.get(result["nextUri"], timeout=120)
        response.raise_for_status()


def main():
    files = [Path("sql/02_star.sql"), *sorted(Path("sql/reports").glob("*.sql"))]
    for path in files:
        for query in path.read_text().split(";"):
            if query.strip():
                execute(query)
        print(f"Выполнен {path}")
    result = execute("SELECT count(*), count(DISTINCT sale_key) FROM clickhouse.lab.fact_sales")
    if result != [[10000, 10000]]:
        raise ValueError(f"Неверное количество продаж: {result}")
    result = execute("SELECT sum(sale_quantity), sum(sale_total_price) FROM clickhouse.lab.fact_sales EXCEPT SELECT sum(CAST(sale_quantity AS INTEGER)), sum(CAST(sale_total_price AS DECIMAL(18,2))) FROM clickhouse.lab.stage")
    if result:
        raise ValueError(f"Не совпадают суммы: {result}")
    print("Проверки количества и сумм пройдены")


if __name__ == "__main__":
    main()
