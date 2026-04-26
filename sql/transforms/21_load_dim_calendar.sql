INSERT INTO analytics.dim_calendar (
    date_key,
    full_date,
    day_number,
    month_number,
    month_name,
    quarter_number,
    year_number,
    week_number,
    day_name,
    is_weekend
)
SELECT DISTINCT
    TO_CHAR(snapshot_date, 'YYYYMMDD')::INTEGER AS date_key,
    snapshot_date AS full_date,
    EXTRACT(DAY FROM snapshot_date)::INTEGER AS day_number,
    EXTRACT(MONTH FROM snapshot_date)::INTEGER AS month_number,
    TRIM(TO_CHAR(snapshot_date, 'Month')) AS month_name,
    EXTRACT(QUARTER FROM snapshot_date)::INTEGER AS quarter_number,
    EXTRACT(YEAR FROM snapshot_date)::INTEGER AS year_number,
    EXTRACT(WEEK FROM snapshot_date)::INTEGER AS week_number,
    TRIM(TO_CHAR(snapshot_date, 'Day')) AS day_name,
    CASE
        WHEN EXTRACT(ISODOW FROM snapshot_date) IN (6, 7) THEN TRUE
        ELSE FALSE
    END AS is_weekend
FROM staging.tmdb_daily_metrics
WHERE snapshot_date IS NOT NULL
ON CONFLICT (date_key) DO NOTHING;