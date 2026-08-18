drop table clean_products
CREATE TABLE clean_products (
    product_id      INTEGER PRIMARY KEY,
    product_name    TEXT NOT NULL,
    category_id     INTEGER NOT NULL REFERENCES clean_categories(category_id),
    unit_cost       NUMERIC(10,2) NOT NULL,
    unit_price      NUMERIC(10,2) NOT NULL
);

INSERT INTO clean_products (product_id, product_name, category_id, unit_cost, unit_price)
SELECT DISTINCT ON (product_id)        -- drops the 1 duplicate product row
    product_id::INTEGER,
    TRIM(REGEXP_REPLACE(product_name, '\s+', ' ', 'g'))  AS product_name,  -- trim + collapse spaces
    category_id::INTEGER,
    unit_cost::NUMERIC(10,2),
    unit_price::NUMERIC(10,2)
FROM raw_products
ORDER BY product_id;

SELECT * FROM clean_products;