CREATE TABLE clean_returns (
    return_id           INTEGER PRIMARY KEY,
    order_id            INTEGER NOT NULL REFERENCES clean_orders(order_id),
    product_id          INTEGER NOT NULL REFERENCES clean_products(product_id),
    quantity_returned   INTEGER NOT NULL,
    reason              TEXT NOT NULL
);

INSERT INTO clean_returns (return_id, order_id, product_id, quantity_returned, reason)
SELECT
    return_id::INTEGER,
    order_id::INTEGER,
    product_id::INTEGER,
    quantity_returned::INTEGER,
    TRIM(reason)
FROM raw_returns
WHERE order_id::INTEGER IN (SELECT order_id FROM clean_orders)          -- guard: only returns for orders we kept
  AND product_id::INTEGER IN (SELECT product_id FROM clean_products);   -- guard: only valid products

select * from clean_returns;