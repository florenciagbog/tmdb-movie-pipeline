CREATE TABLE IF NOT EXISTS analytics.dim_snapshot (
    snapshot_date_key INTEGER PRIMARY KEY,
    snapshot_date DATE NOT NULL,
    is_latest BOOLEAN NOT NULL DEFAULT FALSE
);