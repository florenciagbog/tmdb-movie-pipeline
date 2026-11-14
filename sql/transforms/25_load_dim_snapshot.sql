TRUNCATE TABLE analytics.dim_snapshot;

INSERT INTO analytics.dim_snapshot (
    snapshot_date_key,
    snapshot_date,
    is_latest
)
SELECT
    snapshot_date_key,
    TO_DATE(snapshot_date_key::text, 'YYYYMMDD') AS snapshot_date,
    snapshot_date_key = MAX(snapshot_date_key) OVER () AS is_latest
FROM (
    SELECT DISTINCT snapshot_date_key
    FROM analytics.fact_daily_movie
) s
ORDER BY snapshot_date_key;