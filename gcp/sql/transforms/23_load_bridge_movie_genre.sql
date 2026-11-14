MERGE analytics.bridge_movie_genre t
USING (
    SELECT DISTINCT
        e.movie_id,
        LAX_INT64(g) AS genre_id
    FROM staging.tmdb_movie_entries e,
         UNNEST(JSON_QUERY_ARRAY(e.movie_payload, '$.genre_ids')) AS g
) s
ON  t.movie_id = s.movie_id
AND t.genre_id = s.genre_id
WHEN NOT MATCHED AND s.genre_id IS NOT NULL THEN
    INSERT (movie_id, genre_id) VALUES (s.movie_id, s.genre_id);
