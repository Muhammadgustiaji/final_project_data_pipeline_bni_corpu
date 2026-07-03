DROP TABLE IF EXISTS mart_product_performance;

CREATE TABLE mart_product_performance AS
WITH product_summary AS (
    SELECT
        DATE_TRUNC(
            'month',
            COALESCE(t.transaction_date, t.transaction_at::DATE)
        )::DATE AS period_month,

        COALESCE(a.account_type, 'UNKNOWN') AS account_type,
        COALESCE(a.product_name, 'Unknown Product') AS product_name,
        COALESCE(a.currency, 'UNKNOWN') AS currency,

        COUNT(DISTINCT t.account_id)::INTEGER AS total_accounts,
        COUNT(t.transaction_id)::INTEGER AS total_transactions,
        COALESCE(SUM(t.amount), 0)::NUMERIC(18,2) AS total_amount,
        COALESCE(AVG(t.amount), 0)::NUMERIC(18,2) AS avg_transaction_amount,
        COALESCE(AVG(t.balance_before), 0)::NUMERIC(18,2) AS avg_balance_before,
        COALESCE(AVG(t.balance_after), 0)::NUMERIC(18,2) AS avg_balance_after
    FROM fact_transactions t
    LEFT JOIN dim_accounts a
        ON t.account_id = a.account_id
    GROUP BY
        DATE_TRUNC(
            'month',
            COALESCE(t.transaction_date, t.transaction_at::DATE)
        )::DATE,
        COALESCE(a.account_type, 'UNKNOWN'),
        COALESCE(a.product_name, 'Unknown Product'),
        COALESCE(a.currency, 'UNKNOWN')
),
ranked AS (
    SELECT
        *,
        RANK() OVER (
            PARTITION BY period_month
            ORDER BY total_transactions DESC
        )::INTEGER AS product_volume_rank,

        RANK() OVER (
            PARTITION BY period_month
            ORDER BY avg_balance_after DESC
        )::INTEGER AS product_balance_rank
    FROM product_summary
)
SELECT
    period_month,
    account_type,
    product_name,
    currency,
    total_accounts,
    total_transactions,
    total_amount,
    avg_transaction_amount,
    avg_balance_before,
    avg_balance_after,
    product_volume_rank,
    product_balance_rank,
    NOW()::TIMESTAMP AS etl_loaded_at
FROM ranked
ORDER BY period_month, product_volume_rank;