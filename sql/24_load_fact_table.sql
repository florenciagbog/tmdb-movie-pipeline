-- 1. INSERT new data
INSERT INTO analytics.fact_trending_daily (
    snapshot_date_key,
    movie_key,
    rank,
    popularity,
    vote_average,
    vote_count
)
SELECT
    to_char(snapshot_date, 'YYYYMMDD')::integer AS snapshot_date_key,
    movie_id AS movie_key,
    rank_overall AS rank,
    popularity,
    round(vote_average::numeric, 2) AS vote_average,
    vote_count
FROM raw.tmdb_trending_daily
WHERE snapshot_date IS NOT NULL
  AND movie_id IS NOT NULL
-- ON CONFLICT (snapshot_date_key, movie_key) DO NOTHING;
ON CONFLICT (snapshot_date_key, movie_key) DO UPDATE
SET rank = excluded.rank,
    popularity = excluded.popularity,
    vote_average = excluded.vote_average,
    vote_count = excluded.vote_count;




-- 2. UPDATE all rows still missing metrics
WITH ranked AS (
    SELECT
        snapshot_date_key,
        movie_key,
        rank,
        LAG(rank) OVER (
            PARTITION BY movie_key
            ORDER BY snapshot_date_key
        ) AS calc_previous_rank
    FROM analytics.fact_trending_daily
)
UPDATE analytics.fact_trending_daily f
SET
    previous_rank = r.calc_previous_rank,
    rank_change = f.rank - r.calc_previous_rank,
    is_new_entry = (r.calc_previous_rank IS NULL)
FROM ranked r
WHERE f.movie_key = r.movie_key
  AND f.snapshot_date_key = r.snapshot_date_key
  AND (f.previous_rank IS NULL OR f.rank_change IS NULL);