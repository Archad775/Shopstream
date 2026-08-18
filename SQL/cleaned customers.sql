select * from raw_categ
/* 02_clean_customers.sql
   raw_customers -> clean_customers

   raw_customers is a straight text dump, so everything needs typing + tidying.
   Main headache is the region column - 17 different spellings of 4 regions,
   plus a chunk of blanks. Names came in padded with spaces too.
   Building a fresh clean_customers table off raw so I can always diff back
   to the source if a mapping looks off later.
*/


CREATE TABLE clean_customers (
    customer_id             INTEGER PRIMARY KEY,
    customer_name           TEXT NOT NULL,
    signup_date             DATE NOT NULL,
    acquisition_channel     TEXT NOT NULL,   -- 'Unknown' where missing
    region                  TEXT NOT NULL    -- 'Unknown' where missing
);


INSERT INTO clean_customers (customer_id, customer_name, signup_date, acquisition_channel, region)
SELECT
    customer_id::INTEGER,
    TRIM(REGEXP_REPLACE(customer_name, '\s+', ' ', 'g'))               AS customer_name, --regexp is used in case there are extra spaces betweem the names
    signup_date::DATE                                                   AS signup_date,
    COALESCE(NULLIF(TRIM(acquisition_channel), ''), 'Unknown')          AS acquisition_channel,
    CASE UPPER(TRIM(region))
        WHEN 'NORTH' THEN 'North'
        WHEN 'NORT'  THEN 'North'   -- typo
        WHEN 'SOUTH' THEN 'South'
        WHEN 'EAST'  THEN 'East'
        WHEN 'WEST'  THEN 'West'
        WHEN 'WST'   THEN 'West'    -- typo
        ELSE 'Unknown'              -- covers NULL / blank / anything unrecognized
    END AS region
FROM raw_customers;

select * from raw_customers
select * from clean_customers
