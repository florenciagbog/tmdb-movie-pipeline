INSERT INTO staging.tmdb_movie_trailers (
    movie_id,
    trailer_url,
    trailer_checked_at
)
SELECT
    r.movie_id,
    trailer.trailer_url,
    r.fetched_at
FROM  (
    SELECT DISTINCT ON (movie_id)
        movie_id,
        payload,
        fetched_at
    FROM raw.tmdb_movie_videos
    ORDER BY movie_id, fetched_at DESC
) r

LEFT JOIN LATERAL (
    SELECT
        'https://www.youtube.com/watch?v=' || (video->>'key')
            AS trailer_url
    FROM jsonb_array_elements(r.payload->'results') AS videos(video)
    WHERE video->>'site' = 'YouTube'
      AND video->>'type' = 'Trailer'
    ORDER BY
        CASE
            WHEN (video->>'official')::boolean = true THEN 1
            ELSE 2
        END
    LIMIT 1
) trailer ON true

ON CONFLICT (movie_id) DO UPDATE
SET
    trailer_url = EXCLUDED.trailer_url,
    trailer_checked_at = EXCLUDED.trailer_checked_at;



