-- 1. INSERT new data
INSERT INTO analytics.fact_daily_movie (
    snapshot_date_key,
    movie_id,
    rank,
    popularity,
    vote_average,
    vote_count
)
SELECT
    to_char(snapshot_date, 'YYYYMMDD')::integer AS snapshot_date_key,
    movie_id AS movie_id,
    rank_overall AS rank,
    popularity,
    round(vote_average::numeric, 2) AS vote_average,
    vote_count
FROM staging.tmdb_daily_metrics
WHERE snapshot_date IS NOT NULL
  AND movie_id IS NOT NULL
-- ON CONFLICT (snapshot_date_key, movie_id) DO NOTHING;
ON CONFLICT (snapshot_date_key, movie_id) DO UPDATE
SET rank = excluded.rank,
    popularity = excluded.popularity,
    vote_average = excluded.vote_average,
    vote_count = excluded.vote_count;




-- 2. UPDATE all rows still missing metrics
WITH ranked AS (
    SELECT
        snapshot_date_key,
        movie_id,
        rank,
        LAG(rank) OVER (
            PARTITION BY movie_id
            ORDER BY snapshot_date_key
        ) AS calc_previous_rank
    FROM analytics.fact_daily_movie
)
UPDATE analytics.fact_daily_movie f
SET
    previous_rank = r.calc_previous_rank,
    rank_change = f.rank - r.calc_previous_rank,
    is_new_entry = (r.calc_previous_rank IS NULL)
FROM ranked r
WHERE f.movie_id = r.movie_id
  AND f.snapshot_date_key = r.snapshot_date_key
  AND (f.previous_rank IS NULL OR f.rank_change IS NULL);



