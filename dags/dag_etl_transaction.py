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
    os.path.dirname(__file__), "..", "include", "dataset", "transactions.csv"
)


DDL_STATEMENTS = """
DROP TABLE IF EXISTS fact_transactions;
DROP TABLE IF EXISTS stg_transactions;

CREATE TABLE stg_transactions (
    transaction_id      INTEGER,
    transaction_code    VARCHAR(30),
    account_id          INTEGER,
    customer_id         INTEGER,
    branch_id           INTEGER,
    channel_id          INTEGER,
    transaction_date    VARCHAR(20),
    transaction_at      VARCHAR(30),
    transaction_type    VARCHAR(50),
    amount              NUMERIC(18,2),
    balance_before      NUMERIC(18,2),
    balance_after       NUMERIC(18,2),
    status              VARCHAR(20),
    reference_no        VARCHAR(50)
);

CREATE TABLE fact_transactions (
    transaction_id      INTEGER      PRIMARY KEY,
    transaction_code    VARCHAR(30),
    account_id          INTEGER,
    customer_id         INTEGER,
    branch_id           INTEGER,
    channel_id          INTEGER,
    date_id             INTEGER,
    transaction_date    DATE,
    transaction_at      TIMESTAMP,
    transaction_type    VARCHAR(50),
    amount              NUMERIC(18,2),
    balance_before      NUMERIC(18,2),
    balance_after       NUMERIC(18,2),
    status              VARCHAR(20),
    reference_no        VARCHAR(50),

    -- derived columns
    transaction_hour    SMALLINT,
    balance_change      NUMERIC(18,2),
    is_success          BOOLEAN,
    amount_segment      VARCHAR(20),

    etl_loaded_at       TIMESTAMP DEFAULT NOW()
);
"""


# ─── DAG ──────────────────────────────────────────────────────────────────────
@dag(
    dag_id="dag_etl_transactions",
    description="ETL transactions.csv → stg_transactions → fact_transactions",
    default_args={
        "owner": "airflow",
        "retries": 1,
        "retry_delay": timedelta(minutes=5),
        "email_on_failure": False,
    },
    start_date=datetime(2025, 1, 1),
    schedule=None,
    catchup=False,
    tags=["etl", "transactions", "fact", "postgresql"],
    template_searchpath=["/opt/airflow/include/sql/dataset"],
)
def dag_etl_transactions():

    # ── Task 1: Create Tables ────────────────────────────────────────────────
    create_tables = SQLExecuteQueryOperator(
        task_id="create_tables",
        conn_id=CONN_ID,
        sql=DDL_STATEMENTS,
        split_statements=True,
    )

    # ── Task 2: Extract CSV → stg_transactions ──────────────────────────────
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
                "transaction_code": str,
                "transaction_date": str,
                "transaction_at": str,
                "transaction_type": str,
                "status": str,
                "reference_no": str,
            },
        )

        df = df.where(pd.notnull(df), None)

        with engine.begin() as c:
            c.execute(text("TRUNCATE TABLE stg_transactions"))

        df.to_sql(
            name="stg_transactions",
            con=engine,
            if_exists="append",
            index=False,
            method="multi",
            chunksize=1000,
        )

        engine.dispose()

        return len(df)

    # ── Task 3: Transform stg_transactions → fact_transactions ──────────────
    transform = SQLExecuteQueryOperator(
        task_id="transform",
        conn_id=CONN_ID,
        sql="01_transactions.sql",
        split_statements=True,
    )

    # ── Dependencies ─────────────────────────────────────────────────────────
    create_tables >> extract_load() >> transform


dag_etl_transactions()