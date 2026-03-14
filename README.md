# TMDB Movie Trending Data Pipeline

## Overview
This project implements a batch data pipeline that ingests daily trending movie data from the TMDB API, stores raw JSON payloads in PostgreSQL, transforms nested structures into relational tables using SQL, and exposes analytics-ready datasets for reporting in Power BI.

## Architecture
TMDB API 

↓

Python ingestion script

↓

PostgreSQL raw ingestion layer

↓

SQL transformations

↓

Analytics-ready daily table

↓

Reporting view

↓

Power BI dashboard

## Technologies
- Python
- PostgreSQL
- SQL
- TMDB API
- Power BI

## Pipeline Features
- Daily ingestion of trending movies
- Raw JSON storage for traceability
- JSON flattening into relational tables
- Deduplication of movie rankings
- Ranking change analysis

## Tables
raw.tmdb_trending_raw  
raw.tmdb_trending_movies_raw  
raw.tmdb_trending_daily  

## View
raw.v_trending_latest_with_change
