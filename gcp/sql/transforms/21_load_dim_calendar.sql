MERGE analytics.dim_calendar t
USING (
    SELECT DISTINCT
        CAST(FORMAT_DATE('%Y%m%d', snapshot_date) AS INT64) AS date_key,
        snapshot_date                                       AS full_date,
        EXTRACT(DAY FROM snapshot_date)                     AS day_number,
        EXTRACT(MONTH FROM snapshot_date)                   AS month_number,
        FORMAT_DATE('%B', snapshot_date)                    AS month_name,
        EXTRACT(QUARTER FROM snapshot_date)                 AS quarter_number,
        EXTRACT(YEAR FROM snapshot_date)                    AS year_number,
        EXTRACT(ISOWEEK FROM snapshot_date)                 AS week_number,   -- same as Postgres WEEK (ISO)
        FORMAT_DATE('%A', snapshot_date)                    AS day_name,
        EXTRACT(DAYOFWEEK FROM snapshot_date) IN (1, 7)     AS is_weekend     -- 1 = Sunday, 7 = Saturday
    FROM staging.tmdb_daily_metrics
    WHERE snapshot_date IS NOT NULL
) s
ON t.date_key = s.date_key
WHEN NOT MATCHED THEN
    INSERT (date_key, full_date, day_number, month_number, month_name,
            quarter_number, year_number, week_number, day_name, is_weekend)
    VALUES (s.date_key, s.full_date, s.day_number, s.month_number, s.month_name,
            s.quarter_number, s.year_number, s.week_number, s.day_name, s.is_weekend);
