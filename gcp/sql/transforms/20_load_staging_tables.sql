-- Flatten raw TMDB pages into one row per movie per day (best rank wins). Rerun-safe.
MERGE staging.tmdb_movie_entries t
USING (
    SELECT snapshot_date, endpoint, page, rank_overall, movie_id, title, movie_payload
    FROM (
        SELECT
            r.snapshot_date,
            r.endpoint,
            r.page,
            ((r.page - 1) * 20) + pos + 1          AS rank_overall,
            LAX_INT64(movie.id)                    AS movie_id,
            JSON_VALUE(movie, '$.title')           AS title,
            movie                                  AS movie_payload
        FROM raw.tmdb_api_responses r,
             UNNEST(JSON_QUERY_ARRAY(r.payload, '$.results')) AS movie WITH OFFSET pos
    )
    WHERE movie_id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY snapshot_date, endpoint, movie_id
        ORDER BY rank_overall
    ) = 1
) s
ON  t.snapshot_date = s.snapshot_date
AND t.endpoint      = s.endpoint
AND t.movie_id      = s.movie_id
WHEN NOT MATCHED THEN
    INSERT (snapshot_date, endpoint, page, rank_overall, movie_id, title, movie_payload)
    VALUES (s.snapshot_date, s.endpoint, s.page, s.rank_overall, s.movie_id, s.title, s.movie_payload);

-- Extract numeric metrics into the daily table. Rerun-safe.
MERGE staging.tmdb_daily_metrics t
USING (
    SELECT
        m.snapshot_date,
        m.movie_id,
        ANY_VALUE(m.title)                                   AS title,
        MIN(m.rank_overall)                                  AS rank_overall,
        ANY_VALUE(LAX_FLOAT64(m.movie_payload.popularity))   AS popularity,
        ANY_VALUE(LAX_FLOAT64(m.movie_payload.vote_average)) AS vote_average,
        ANY_VALUE(LAX_INT64(m.movie_payload.vote_count))     AS vote_count
    FROM staging.tmdb_movie_entries m
    GROUP BY m.snapshot_date, m.movie_id
) s
ON  t.snapshot_date = s.snapshot_date
AND t.movie_id      = s.movie_id
WHEN NOT MATCHED THEN
    INSERT (snapshot_date, movie_id, title, rank_overall, popularity, vote_average, vote_count)
    VALUES (s.snapshot_date, s.movie_id, s.title, s.rank_overall, s.popularity, s.vote_average, s.vote_count);
