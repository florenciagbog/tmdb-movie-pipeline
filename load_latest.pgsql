-- 1) Flatten latest snapshot into one-row-per-movie (dedup by best rank)
DELETE FROM raw.tmdb_trending_movies_raw
WHERE snapshot_date = (SELECT MAX(snapshot_date) FROM raw.tmdb_trending_raw);

INSERT INTO raw.tmdb_trending_movies_raw (
    snapshot_date, endpoint, page, rank_overall, movie_id, title, movie_payload
)
SELECT snapshot_date, endpoint, page, rank_overall, movie_id, title, movie_payload
FROM (
    SELECT
        r.snapshot_date,
        r.endpoint,
        r.page,
        ((r.page - 1) * 20) + ordinality AS rank_overall,
        (movie->>'id')::int AS movie_id,
        movie->>'title' AS title,
        movie AS movie_payload,
        ROW_NUMBER() OVER (
            PARTITION BY r.snapshot_date, r.endpoint, (movie->>'id')::int
            ORDER BY ((r.page - 1) * 20) + ordinality
        ) AS rn
    FROM raw.tmdb_trending_raw r,
    LATERAL jsonb_array_elements(r.payload->'results') WITH ORDINALITY AS movie(movie, ordinality)
    WHERE r.snapshot_date = (SELECT MAX(snapshot_date) FROM raw.tmdb_trending_raw)
) x
WHERE rn = 1;

-- 2) Load latest day into clean daily fact table (ignore if already loaded)
INSERT INTO raw.tmdb_trending_daily (
  snapshot_date, movie_id, title, rank_overall, popularity, vote_average, vote_count
)
SELECT
  snapshot_date,
  movie_id,
  title,
  rank_overall,
  (movie_payload->>'popularity')::numeric,
  (movie_payload->>'vote_average')::numeric,
  (movie_payload->>'vote_count')::int
FROM raw.tmdb_trending_movies_raw
WHERE snapshot_date = (SELECT MAX(snapshot_date) FROM raw.tmdb_trending_movies_raw)
ON CONFLICT (snapshot_date, movie_id) DO NOTHING;