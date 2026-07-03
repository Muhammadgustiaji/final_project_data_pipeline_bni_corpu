from datetime import datetime, timedelta

from airflow.decorators import dag
from airflow.operators.empty import EmptyOperator
from airflow.operators.trigger_dagrun import TriggerDagRunOperator


def trigger_child_dag(task_id, trigger_dag_id):
    return TriggerDagRunOperator(
        task_id=task_id,
        trigger_dag_id=trigger_dag_id,
        wait_for_completion=True,
        deferrable=True,
        poke_interval=60,
        allowed_states=["success"],
        failed_states=["failed"],
        reset_dag_run=True,
        execution_timeout=timedelta(hours=2),
    )


@dag(
    dag_id="dag_00_master_pipeline",
    description="Master DAG untuk menjalankan seluruh ETL dan mart secara berurutan",
    default_args={
        "owner": "airflow",
        "retries": 0,
        "email_on_failure": False,
    },
    start_date=datetime(2025, 1, 1),
    schedule=None,
    catchup=False,
    tags=["master", "etl", "mart", "pipeline"],
)
def master_pipeline():

    start = EmptyOperator(task_id="start")

    run_dim_date = trigger_child_dag(
        task_id="01_run_dim_date",
        trigger_dag_id="dag_etl_dim_date",
    )

    run_branches = trigger_child_dag(
        task_id="02_run_branches",
        trigger_dag_id="dag_etl_branches",
    )

    run_channels = trigger_child_dag(
        task_id="03_run_channels",
        trigger_dag_id="dag_etl_channels",
    )

    run_customers = trigger_child_dag(
        task_id="04_run_customers",
        trigger_dag_id="dag_etl_customers",
    )

    run_accounts = trigger_child_dag(
        task_id="05_run_accounts",
        trigger_dag_id="dag_etl_accounts",
    )

    run_transactions = trigger_child_dag(
        task_id="06_run_transactions",
        trigger_dag_id="dag_etl_transactions",
    )

    run_fraud_labels = trigger_child_dag(
        task_id="07_run_fraud_labels",
        trigger_dag_id="dag_etl_fraud_labels",
    )

    run_marts = TriggerDagRunOperator(
        task_id="08_run_marts",
        trigger_dag_id="dag_build_marts",
        wait_for_completion=False,
        reset_dag_run=True,
    )

    end = EmptyOperator(task_id="end")

    (
        start
        >> run_dim_date
        >> run_branches
        >> run_channels
        >> run_customers
        >> run_accounts
        >> run_transactions
        >> run_fraud_labels
        >> run_marts
        >> end
    )

master_pipeline()