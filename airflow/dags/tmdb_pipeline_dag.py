from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime

with DAG(
    dag_id="tmdb_movie_pipeline",
    start_date=datetime(2026, 3, 14),
    schedule= None,
    catchup=False,
) as dag:

    run_ingestion = BashOperator(
        task_id="run_ingestion",
        bash_command="python /Users/FlorGonzalez/Documents/tmdb-movie-pipeline/ingest_tmdb.py",
    )