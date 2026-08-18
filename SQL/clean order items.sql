CREATE TABLE clean_order_items (
    item_id     INTEGER PRIMARY KEY,
    order_id    INTEGER NOT NULL REFERENCES clean_orders(order_id),
    product_id  INTEGER NOT NULL REFERENCES clean_products(product_id),
    quantity    INTEGER NOT NULL,
    unit_price  NUMERIC(10,2) NOT NULL,
    discount    NUMERIC(5,3) NOT NULL
);

INSERT INTO clean_order_items (item_id, order_id, product_id, quantity, unit_price, discount)
SELECT
    item_id::INTEGER,
    order_id::INTEGER,
    product_id::INTEGER,
    quantity::INTEGER,
    -- price came in as text with $ and commas: '$1,299.00' -> strip both, then cast
    REPLACE(REPLACE(unit_price, '$', ''), ',', '')::NUMERIC(10,2)  AS unit_price,
    discount::NUMERIC(5,3)                                          AS discount
FROM raw_order_items
WHERE quantity::INTEGER > 0                          -- drop the 187 negative/zero quantities
  AND product_id::INTEGER IN (SELECT product_id FROM clean_products);  -- drop the 25 orphan product_ids

SELECT * FROM clean_order_items;