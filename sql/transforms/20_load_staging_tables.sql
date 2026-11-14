-- Flatten raw TMDB data into one row per movie per day, deduplicating by best rank and safe to rerun via ON CONFLICT.
INSERT INTO staging.tmdb_movie_entries (
    snapshot_date,
    endpoint,
    page,
    rank_overall,
    movie_id,
    title,
    movie_payload
)
SELECT
    snapshot_date,
    endpoint,
    page,
    rank_overall,
    movie_id,
    title,
    movie_payload
FROM (
    SELECT
        r.snapshot_date,
        r.endpoint,
        r.page,
        ((r.page - 1) * 20) + ordinality AS rank_overall,
        (movie.movie->>'id')::int AS movie_id,
        movie.movie->>'title' AS title,
        movie.movie AS movie_payload,
        ROW_NUMBER() OVER (
            PARTITION BY r.snapshot_date, r.endpoint, (movie.movie->>'id')::int
            ORDER BY ((r.page - 1) * 20) + ordinality
        ) AS rn
    FROM raw.tmdb_api_responses r
    CROSS JOIN LATERAL jsonb_array_elements(r.payload->'results')
        WITH ORDINALITY AS movie(movie, ordinality)
) x
WHERE rn = 1
ON CONFLICT (snapshot_date, endpoint, movie_id) DO NOTHING;

-- Load all flattened data into daily table, safely skipping duplicates via ON CONFLICT.

INSERT INTO staging.tmdb_daily_metrics (
  snapshot_date,
  movie_id,
  title,
  rank_overall,
  popularity,
  vote_average,
  vote_count
)
SELECT
  m.snapshot_date,
  m.movie_id,
  m.title,
  m.rank_overall,
  (m.movie_payload->>'popularity')::numeric,
  (m.movie_payload->>'vote_average')::numeric,
  (m.movie_payload->>'vote_count')::int
FROM staging.tmdb_movie_entries m
ON CONFLICT (snapshot_date, movie_id) DO NOTHING;