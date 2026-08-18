-- Audit log: every row that fails a data-quality check lands here
-- instead of being silently discarded.
CREATE TABLE staging.rejected_records (
    rejected_id         SERIAL PRIMARY KEY,
    source_table        TEXT NOT NULL,
    source_pk           TEXT,
    rejection_reason    TEXT NOT NULL,
    raw_data            JSONB,
    rejected_at         TIMESTAMP DEFAULT now()
);