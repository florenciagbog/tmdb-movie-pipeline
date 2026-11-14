CREATE TABLE IF NOT EXISTS raw.tmdb_movie_videos (
    movie_id integer NOT NULL,
    fetched_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    payload jsonb NOT NULL,

    PRIMARY KEY (movie_id, fetched_at)
);