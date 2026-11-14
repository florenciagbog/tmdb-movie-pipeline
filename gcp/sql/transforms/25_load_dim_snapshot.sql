TRUNCATE TABLE analytics.dim_snapshot;

INSERT INTO analytics.dim_snapshot (snapshot_date_key, snapshot_date, is_latest)
SELECT
    snapshot_date_key,
    PARSE_DATE('%Y%m%d', CAST(snapshot_date_key AS STRING))  AS snapshot_date,
    snapshot_date_key = MAX(snapshot_date_key) OVER ()       AS is_latest
FROM (
    SELECT DISTINCT snapshot_date_key
    FROM analytics.fact_daily_movie
);
