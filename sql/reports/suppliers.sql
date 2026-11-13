DROP TABLE IF EXISTS clickhouse.lab.report_suppliers;
CREATE TABLE clickhouse.lab.report_suppliers AS
WITH sales AS (SELECT f.*, c.customer_first_name, c.customer_last_name, c.customer_age, c.customer_email, c.customer_country, c.customer_postal_code, c.customer_pet_type, c.customer_pet_name, c.customer_pet_breed, p.product_name, p.product_category, p.product_price, p.product_quantity, p.pet_category, p.product_weight, p.product_color, p.product_size, p.product_brand, p.product_material, p.product_description, p.product_rating, p.product_reviews, p.product_release_date, p.product_expiry_date, st.store_name, st.store_location, st.store_city, st.store_state, st.store_country, st.store_phone, st.store_email, sp.supplier_name, sp.supplier_contact, sp.supplier_email, sp.supplier_phone, sp.supplier_address, sp.supplier_city, sp.supplier_country, d.year_key, d.month_key
FROM clickhouse.lab.fact_sales f
JOIN clickhouse.lab.dim_customer c ON f.customer_key = c.customer_key
JOIN clickhouse.lab.dim_product p ON f.product_key = p.product_key
JOIN clickhouse.lab.dim_store st ON f.store_key = st.store_key
JOIN clickhouse.lab.dim_supplier sp ON f.supplier_key = sp.supplier_key
JOIN clickhouse.lab.dim_date d ON f.date_key = d.date_key
),
products AS (SELECT * FROM clickhouse.lab.dim_product)
SELECT 'top_revenue' AS metric, entity, period, CAST(value AS DOUBLE) AS value FROM (SELECT supplier_name AS entity, '' AS period, SUM(sale_total_price) AS value FROM sales  GROUP BY supplier_name ORDER BY value DESC, entity LIMIT 5) result
UNION ALL
SELECT 'average_price' AS metric, entity, period, CAST(value AS DOUBLE) AS value FROM (SELECT supplier_name AS entity, '' AS period, AVG(CAST(product_price AS DOUBLE)) AS value FROM sales  GROUP BY supplier_name) result
UNION ALL
SELECT 'country_revenue' AS metric, entity, period, CAST(value AS DOUBLE) AS value FROM (SELECT supplier_country AS entity, '' AS period, SUM(sale_total_price) AS value FROM sales  GROUP BY supplier_country) result;
