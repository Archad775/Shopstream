CREATE TABLE clean_marketing_spend (
    spend_id    INTEGER PRIMARY KEY,
    month       DATE NOT NULL,          -- first day of the month
    channel     TEXT NOT NULL,
    spend_usd   NUMERIC(12,2) NOT NULL
);

INSERT INTO clean_marketing_spend (spend_id, month, channel, spend_usd)
SELECT
    spend_id::INTEGER,
    month::DATE,
    TRIM(channel),
    spend_usd::NUMERIC(12,2)
FROM raw_marketing_spend;

select * from clean_marketing_spend