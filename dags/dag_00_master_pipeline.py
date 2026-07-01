from datetime import datetime, timedelta

from airflow.decorators import dag
from airflow.operators.empty import EmptyOperator
from airflow.operators.trigger_dagrun import TriggerDagRunOperator


@dag(
    dag_id="dag_00_master_pipeline",
    description="Master DAG untuk menjalankan seluruh ETL dan mart secara berurutan",
    default_args={
        "owner": "airflow",
        "retries": 1,
        "retry_delay": timedelta(minutes=5),
        "email_on_failure": False,
    },
    start_date=datetime(2025, 1, 1),
    schedule=None,
    catchup=False,
    tags=["master", "etl", "mart", "pipeline"],
)
def master_pipeline():

    start = EmptyOperator(task_id="start")

    run_dim_date = TriggerDagRunOperator(
        task_id="01_run_dim_date",
        trigger_dag_id="dag_etl_dim_date",
        wait_for_completion=True,
        poke_interval=30,
        allowed_states=["success"],
        failed_states=["failed"],
    )

    run_branches = TriggerDagRunOperator(
        task_id="02_run_branches",
        trigger_dag_id="dag_etl_branches",
        wait_for_completion=True,
        poke_interval=30,
        allowed_states=["success"],
        failed_states=["failed"],
    )

    run_channels = TriggerDagRunOperator(
        task_id="03_run_channels",
        trigger_dag_id="dag_etl_channels",
        wait_for_completion=True,
        poke_interval=30,
        allowed_states=["success"],
        failed_states=["failed"],
    )

    run_customers = TriggerDagRunOperator(
        task_id="04_run_customers",
        trigger_dag_id="dag_etl_customers",
        wait_for_completion=True,
        poke_interval=30,
        allowed_states=["success"],
        failed_states=["failed"],
    )

    run_accounts = TriggerDagRunOperator(
        task_id="05_run_accounts",
        trigger_dag_id="dag_etl_accounts",
        wait_for_completion=True,
        poke_interval=30,
        allowed_states=["success"],
        failed_states=["failed"],
    )

    run_transactions = TriggerDagRunOperator(
        task_id="06_run_transactions",
        trigger_dag_id="dag_etl_transactions",
        wait_for_completion=True,
        poke_interval=30,
        allowed_states=["success"],
        failed_states=["failed"],
    )

    run_fraud_labels = TriggerDagRunOperator(
        task_id="07_run_fraud_labels",
        trigger_dag_id="dag_etl_fraud_labels",
        wait_for_completion=True,
        poke_interval=30,
        allowed_states=["success"],
        failed_states=["failed"],
    )

    run_marts = TriggerDagRunOperator(
        task_id="08_run_marts",
        trigger_dag_id="dag_build_marts",
        wait_for_completion=True,
        poke_interval=30,
        allowed_states=["success"],
        failed_states=["failed"],
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