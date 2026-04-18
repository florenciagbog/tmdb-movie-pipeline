create table analytics.bridge_movie_genre (
    movie_key integer not null,
    genre_id integer not null,
    primary key (movie_key, genre_id),
    foreign key (movie_key) references analytics.dim_movie(movie_key),
    foreign key (genre_id) references analytics.dim_genre(genre_id)
);