CREATE TABLE IF NOT EXISTS staging.tmdb_movie_trailers (
    movie_id integer PRIMARY KEY,
    trailer_url text,
    trailer_checked_at timestamp NOT NULL
);