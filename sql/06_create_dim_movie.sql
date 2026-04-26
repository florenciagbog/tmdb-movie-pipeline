CREATE TABLE IF NOT EXISTS analytics.dim_movie (
    movie_key          INTEGER      NOT NULL PRIMARY KEY,
    title              TEXT,
    original_title     TEXT,
    original_language  TEXT,
    release_date       DATE,
    adult              BOOLEAN,
    overview           TEXT,
    poster_path        TEXT,
    inserted_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);