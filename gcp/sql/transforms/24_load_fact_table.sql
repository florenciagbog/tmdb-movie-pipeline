-- 1. Insert new rows / refresh metrics for existing ones
MERGE analytics.fact_daily_movie t
USING (
    SELECT
        CAST(FORMAT_DATE('%Y%m%d', snapshot_date) AS INT64) AS snapshot_date_key,
        movie_id,
        rank_overall                                        AS rank,
        ROUND(CAST(popularity AS NUMERIC), 4)               AS popularity,
        ROUND(CAST(vote_average AS NUMERIC), 2)             AS vote_average,
        vote_count
    FROM staging.tmdb_daily_metrics
    WHERE snapshot_date IS NOT NULL
      AND movie_id IS NOT NULL
) s
ON  t.snapshot_date_key = s.snapshot_date_key
AND t.movie_id          = s.movie_id
WHEN MATCHED THEN UPDATE SET
    rank         = s.rank,
    popularity   = s.popularity,
    vote_average = s.vote_average,
    vote_count   = s.vote_count
WHEN NOT MATCHED THEN
    INSERT (snapshot_date_key, movie_id, rank, popularity, vote_average, vote_count)
    VALUES (s.snapshot_date_key, s.movie_id, s.rank, s.popularity, s.vote_average, s.vote_count);

-- 2. Rank-change tracking for rows still missing it (negative rank_change = improving)
UPDATE analytics.fact_daily_movie f
SET
    previous_rank = r.calc_previous_rank,
    rank_change   = f.rank - r.calc_previous_rank,
    is_new_entry  = (r.calc_previous_rank IS NULL)
FROM (
    SELECT
        snapshot_date_key,
        movie_id,
        LAG(rank) OVER (PARTITION BY movie_id ORDER BY snapshot_date_key) AS calc_previous_rank
    FROM analytics.fact_daily_movie
) r
WHERE f.movie_id          = r.movie_id
  AND f.snapshot_date_key = r.snapshot_date_key
  AND (f.previous_rank IS NULL OR f.rank_change IS NULL);
