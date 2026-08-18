CREATE TABLE clean_categories (
    category_id     INTEGER PRIMARY KEY,
    category_name   TEXT NOT NULL
);

INSERT INTO clean_categories (category_id, category_name)
SELECT
    category_id::INTEGER,
    TRIM(category_name)
FROM raw_categories;

SELECT * FROM clean_categories;