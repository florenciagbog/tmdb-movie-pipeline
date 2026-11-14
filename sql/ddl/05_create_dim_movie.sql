CREATE TABLE IF NOT EXISTS analytics.dim_movie (
    movie_id          INTEGER      NOT NULL PRIMARY KEY,
    title              TEXT,
    original_title     TEXT,
    original_language  TEXT,
    language_name      TEXT,
    release_date       DATE,
    adult              BOOLEAN,
    overview           TEXT,
    poster_path        TEXT,
    trailer_url        TEXT,
    inserted_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);


-- ALTER TABLE analytics.dim_movie
-- ADD COLUMN IF NOT EXISTS trailer_url text;