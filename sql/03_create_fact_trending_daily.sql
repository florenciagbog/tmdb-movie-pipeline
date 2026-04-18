create table analytics.fact_trending_daily (
    snapshot_date_key integer not null,
    movie_key integer not null,
    rank integer,
    popularity numeric(12,4),
    vote_average numeric(5,2),
    vote_count integer,

    primary key (snapshot_date_key, movie_key),

    foreign key (snapshot_date_key) references analytics.dim_calendar(date_key),
    foreign key (movie_key) references analytics.dim_movie(movie_key)
);