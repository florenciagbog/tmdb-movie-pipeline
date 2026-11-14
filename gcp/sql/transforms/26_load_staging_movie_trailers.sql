-- Pick the best YouTube trailer (official first) from the latest videos payload per movie.
MERGE staging.tmdb_movie_trailers t
USING (
    SELECT
        r.movie_id,
        (
            SELECT CONCAT('https://www.youtube.com/watch?v=', JSON_VALUE(video, '$.key'))
            FROM UNNEST(JSON_QUERY_ARRAY(r.payload, '$.results')) AS video
            WHERE JSON_VALUE(video, '$.site') = 'YouTube'
              AND JSON_VALUE(video, '$.type') = 'Trailer'
            ORDER BY IF(COALESCE(LAX_BOOL(video.official), FALSE), 1, 2)
            LIMIT 1
        )            AS trailer_url,
        r.fetched_at AS trailer_checked_at
    FROM (
        SELECT movie_id, payload, fetched_at
        FROM raw.tmdb_movie_videos
        WHERE TRUE
        QUALIFY ROW_NUMBER() OVER (PARTITION BY movie_id ORDER BY fetched_at DESC) = 1
    ) r
) s
ON t.movie_id = s.movie_id
WHEN MATCHED THEN UPDATE SET
    trailer_url        = s.trailer_url,
    trailer_checked_at = s.trailer_checked_at
WHEN NOT MATCHED THEN
    INSERT (movie_id, trailer_url, trailer_checked_at)
    VALUES (s.movie_id, s.trailer_url, s.trailer_checked_at);
