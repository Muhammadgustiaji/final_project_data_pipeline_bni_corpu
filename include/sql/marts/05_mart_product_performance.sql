TRUNCATE TABLE mart_product_performance;

INSERT INTO mart_product_performance (
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
    product_balance_rank
)
WITH product_summary AS (
    SELECT
        DATE_TRUNC('month', t.transaction_date)::DATE AS period_month,
        a.account_type,
        a.product_name,
        a.currency,
        COUNT(DISTINCT a.account_id) AS total_accounts,
        COUNT(t.transaction_id) AS total_transactions,
        COALESCE(SUM(t.amount), 0) AS total_amount,
        COALESCE(AVG(t.amount), 0) AS avg_transaction_amount,
        COALESCE(AVG(t.balance_before), 0) AS avg_balance_before,
        COALESCE(AVG(t.balance_after), 0) AS avg_balance_after
    FROM fact_transactions t
    JOIN dim_accounts a
        ON t.account_id = a.account_id
    GROUP BY
        DATE_TRUNC('month', t.transaction_date)::DATE,
        a.account_type,
        a.product_name,
        a.currency
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
    RANK() OVER (
        PARTITION BY period_month
        ORDER BY total_transactions DESC
    ) AS product_volume_rank,
    RANK() OVER (
        PARTITION BY period_month
        ORDER BY avg_balance_after DESC
    ) AS product_balance_rank
FROM product_summary;