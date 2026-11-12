DROP TABLE IF EXISTS clickhouse.lab.stage;
CREATE TABLE clickhouse.lab.stage AS
SELECT raw.*,
    to_hex(sha256(to_utf8(json_format(CAST(ARRAY[customer_first_name, customer_last_name, customer_age, customer_email, customer_country, customer_postal_code, customer_pet_type, customer_pet_name, customer_pet_breed] AS JSON))))) AS customer_key,
    to_hex(sha256(to_utf8(json_format(CAST(ARRAY[seller_first_name, seller_last_name, seller_email, seller_country, seller_postal_code] AS JSON))))) AS seller_key,
    to_hex(sha256(to_utf8(json_format(CAST(ARRAY[product_name, product_category, product_price, product_quantity, pet_category, product_weight, product_color, product_size, product_brand, product_material, product_description, product_rating, product_reviews, product_release_date, product_expiry_date] AS JSON))))) AS product_key,
    to_hex(sha256(to_utf8(json_format(CAST(ARRAY[store_name, store_location, store_city, store_state, store_country, store_phone, store_email] AS JSON))))) AS store_key,
    to_hex(sha256(to_utf8(json_format(CAST(ARRAY[supplier_name, supplier_contact, supplier_email, supplier_phone, supplier_address, supplier_city, supplier_country] AS JSON))))) AS supplier_key,
    date_format(date_parse(sale_date, '%c/%e/%Y'), '%Y-%m-%d') AS date_key
FROM (
    SELECT * FROM clickhouse.lab.mock_data
    UNION ALL
    SELECT * FROM postgresql.public.mock_data
) raw;
DROP TABLE IF EXISTS clickhouse.lab.dim_customer;
CREATE TABLE clickhouse.lab.dim_customer AS
SELECT DISTINCT customer_key, customer_first_name, customer_last_name, customer_age, customer_email, customer_country, customer_postal_code, customer_pet_type, customer_pet_name, customer_pet_breed FROM clickhouse.lab.stage;
DROP TABLE IF EXISTS clickhouse.lab.dim_seller;
CREATE TABLE clickhouse.lab.dim_seller AS
SELECT DISTINCT seller_key, seller_first_name, seller_last_name, seller_email, seller_country, seller_postal_code FROM clickhouse.lab.stage;
DROP TABLE IF EXISTS clickhouse.lab.dim_product;
CREATE TABLE clickhouse.lab.dim_product AS
SELECT DISTINCT product_key, product_name, product_category, product_price, product_quantity, pet_category, product_weight, product_color, product_size, product_brand, product_material, product_description, product_rating, product_reviews, product_release_date, product_expiry_date FROM clickhouse.lab.stage;
DROP TABLE IF EXISTS clickhouse.lab.dim_store;
CREATE TABLE clickhouse.lab.dim_store AS
SELECT DISTINCT store_key, store_name, store_location, store_city, store_state, store_country, store_phone, store_email FROM clickhouse.lab.stage;
DROP TABLE IF EXISTS clickhouse.lab.dim_supplier;
CREATE TABLE clickhouse.lab.dim_supplier AS
SELECT DISTINCT supplier_key, supplier_name, supplier_contact, supplier_email, supplier_phone, supplier_address, supplier_city, supplier_country FROM clickhouse.lab.stage;
DROP TABLE IF EXISTS clickhouse.lab.dim_date;
CREATE TABLE clickhouse.lab.dim_date AS
SELECT DISTINCT date_key, CAST(date_key AS DATE) full_date,
       substr(date_key, 1, 4) year_key, substr(date_key, 1, 7) month_key
FROM clickhouse.lab.stage;
DROP TABLE IF EXISTS clickhouse.lab.fact_sales;
CREATE TABLE clickhouse.lab.fact_sales AS
SELECT sale_key, source_file, CAST(id AS INTEGER) source_id,
       customer_key, seller_key, product_key, store_key, supplier_key, date_key,
       CAST(sale_quantity AS INTEGER) sale_quantity,
       CAST(sale_total_price AS DECIMAL(18, 2)) sale_total_price
FROM clickhouse.lab.stage;
