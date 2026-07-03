from datetime import datetime, timedelta

from airflow.decorators import dag
from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator


CONN_ID = "postgres_etl"


@dag(
    dag_id="dag_build_marts",
    description="Build semua tabel mart analytics",
    default_args={
        "owner": "airflow",
        "retries": 1,
        "retry_delay": timedelta(minutes=5),
        "email_on_failure": False,
    },
    start_date=datetime(2025, 1, 1),
    schedule=None,
    catchup=False,
    max_active_runs=1,
    tags=["mart", "analytics", "postgresql"],
    template_searchpath=["/opt/airflow/include/sql/marts"],
)
def dag_build_marts():

    create_mart_tables = SQLExecuteQueryOperator(
        task_id="00_create_mart_tables",
        conn_id=CONN_ID,
        sql="00_create_mart_tables.sql",
        split_statements=True,
    )

    create_indexes = SQLExecuteQueryOperator(
        task_id="00_create_indexes",
        conn_id=CONN_ID,
        sql="00_create_indexes.sql",
        split_statements=True,
    )

    mart_transaction_analytics = SQLExecuteQueryOperator(
        task_id="01_mart_transaction_analytics",
        conn_id=CONN_ID,
        sql="01_mart_transaction_analytics.sql",
        split_statements=True,
    )

    mart_customer_360 = SQLExecuteQueryOperator(
        task_id="02_mart_customer_360",
        conn_id=CONN_ID,
        sql="02_mart_customer_360.sql",
        split_statements=True,
    )

    mart_branch_performance = SQLExecuteQueryOperator(
        task_id="03_mart_branch_performance",
        conn_id=CONN_ID,
        sql="03_mart_branch_performance.sql",
        split_statements=True,
    )

    mart_channel_analysis = SQLExecuteQueryOperator(
        task_id="04_mart_channel_analysis",
        conn_id=CONN_ID,
        sql="04_mart_channel_analysis.sql",
        split_statements=True,
    )

    mart_product_performance = SQLExecuteQueryOperator(
        task_id="05_mart_product_performance",
        conn_id=CONN_ID,
        sql="05_mart_product_performance.sql",
        split_statements=True,
    )

    mart_risk_fraud_performance = SQLExecuteQueryOperator(
        task_id="06_mart_risk_fraud_performance",
        conn_id=CONN_ID,
        sql="06_mart_risk_fraud_performance.sql",
        split_statements=True,
    )

    create_mart_tables >> create_indexes

    create_indexes >> [
        mart_transaction_analytics,
        mart_customer_360,
        mart_branch_performance,
        mart_channel_analysis,
        mart_product_performance,
        mart_risk_fraud_performance,
    ]


dag_build_marts()