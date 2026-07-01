import os
from datetime import datetime, timedelta
from urllib.parse import quote_plus

import pandas as pd
from sqlalchemy import create_engine, text

from airflow.decorators import dag, task
from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator


# ─── Konstanta ────────────────────────────────────────────────────────────────
CONN_ID = "postgres_etl"

SOURCE_FILE = os.path.join(
    os.path.dirname(__file__), "..", "include", "dataset", "dim_date.csv"
)


DDL_STATEMENTS = """
CREATE TABLE IF NOT EXISTS stg_dates (
    date_id       INTEGER,
    full_date     VARCHAR(20),
    year          SMALLINT,
    quarter       SMALLINT,
    month         SMALLINT,
    month_name    VARCHAR(20),
    week_of_year  SMALLINT,
    day_of_month  SMALLINT,
    day_of_week   SMALLINT,
    day_name      VARCHAR(20),
    is_weekend    VARCHAR(10),
    is_holiday    VARCHAR(10)
);

CREATE TABLE IF NOT EXISTS dim_date (
    date_id       INTEGER      PRIMARY KEY,
    full_date     DATE,
    year          SMALLINT,
    quarter       SMALLINT,
    month         SMALLINT,
    month_name    VARCHAR(20),
    week_of_year  SMALLINT,
    day_of_month  SMALLINT,
    day_of_week   SMALLINT,
    day_name      VARCHAR(20),
    is_weekend    BOOLEAN,
    is_holiday    BOOLEAN,
    etl_loaded_at TIMESTAMP    DEFAULT NOW()
);
"""


# ─── DAG ──────────────────────────────────────────────────────────────────────
@dag(
    dag_id="dag_etl_dim_date",
    description="ETL dim_date.csv → stg_dates → dim_date",
    default_args={
        "owner": "airflow",
        "retries": 1,
        "retry_delay": timedelta(minutes=5),
        "email_on_failure": False,
    },
    start_date=datetime(2025, 1, 1),
    schedule=None,
    catchup=False,
    tags=["etl", "date", "dim", "postgresql"],
    template_searchpath=["/opt/airflow/include/sql/dataset"],
)
def dag_etl_dim_date():

    # ── Task 1: Create Tables ────────────────────────────────────────────────
    create_tables = SQLExecuteQueryOperator(
        task_id="create_tables",
        conn_id=CONN_ID,
        sql=DDL_STATEMENTS,
    )

    # ── Task 2: Extract CSV → stg_dates ─────────────────────────────────────
    @task()
    def extract_load():
        from airflow.hooks.base import BaseHook

        conn = BaseHook.get_connection(CONN_ID)

        user = quote_plus(conn.login or "")
        password = quote_plus(conn.password or "")
        host = conn.host
        port = conn.port or 5432
        database = conn.schema

        conn_str = (
            f"postgresql+psycopg2://{user}:{password}"
            f"@{host}:{port}/{database}"
        )

        engine = create_engine(conn_str)

        df = pd.read_csv(
            SOURCE_FILE,
            dtype={
                "full_date": str,
                "month_name": str,
                "day_name": str,
                "is_weekend": str,
                "is_holiday": str,
            },
        )

        df = df.where(pd.notnull(df), None)

        with engine.begin() as c:
            c.execute(text("TRUNCATE TABLE stg_dates"))

        df.to_sql(
            name="stg_dates",
            con=engine,
            if_exists="append",
            index=False,
            method="multi",
            chunksize=1000,
        )

        engine.dispose()

        return len(df)

    # ── Task 3: Transform stg_dates → dim_date ──────────────────────────────
    transform = SQLExecuteQueryOperator(
        task_id="transform",
        conn_id=CONN_ID,
        sql="01_dim_date.sql",
    )

    # ── Dependencies ─────────────────────────────────────────────────────────
    create_tables >> extract_load() >> transform


dag_etl_dim_date()