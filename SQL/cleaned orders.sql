CREATE TABLE clean_orders (
    order_id            INTEGER PRIMARY KEY,
    order_date          DATE NOT NULL,
    customer_id         INTEGER NOT NULL REFERENCES clean_customers(customer_id),
    channel             TEXT NOT NULL,          -- 'Unknown' where missing
    order_discount      NUMERIC(5,3) NOT NULL   -- rate, e.g. 0.180 = 18%
);

INSERT INTO clean_orders (order_id, order_date, customer_id, channel, order_discount)
SELECT DISTINCT ON (order_id)          -- kills the 40 exact-duplicate order rows
    order_id::INTEGER,

    -- three date formats in one column: ISO, DD/MM/YYYY (day-first!), and text
    CASE
        WHEN order_date ~ '^\d{4}-\d{2}-\d{2}$'       THEN TO_DATE(order_date, 'YYYY-MM-DD')
        WHEN order_date ~ '^\d{2}/\d{2}/\d{4}$'       THEN TO_DATE(order_date, 'DD/MM/YYYY')
        WHEN order_date ~ '^[A-Za-z]{3} \d{2} \d{4}$' THEN TO_DATE(order_date, 'Mon DD YYYY')
    END                                                         AS order_date,

    customer_id::INTEGER,
    COALESCE(NULLIF(TRIM(channel), ''), 'Unknown')              AS channel,
    order_discount::NUMERIC(5,3)                                AS order_discount
FROM raw_orders
ORDER BY order_id;   -- required alongside DISTINCT ON

SELECT * FROM clean_orders;
SELECT * FROM raw_orders;