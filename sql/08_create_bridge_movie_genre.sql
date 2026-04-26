CREATE TABLE IF NOT EXISTS analytics.bridge_movie_genre (
    movie_key  INTEGER  NOT NULL,
    genre_id   INTEGER  NOT NULL,
    PRIMARY KEY (movie_key, genre_id),
    FOREIGN KEY (movie_key) REFERENCES analytics.dim_movie(movie_key),
    FOREIGN KEY (genre_id)  REFERENCES analytics.dim_genre(genre_id)
);