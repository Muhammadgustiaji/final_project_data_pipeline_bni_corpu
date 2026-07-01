TRUNCATE TABLE mart_branch_performance;

INSERT INTO mart_branch_performance (
    region,
    province,
    city,
    branch_id,
    branch_code,
    branch_name,
    branch_type,
    total_transactions,
    total_amount,
    avg_transaction_amount,
    active_customers,
    transaction_rank_region,
    amount_rank_region
)
WITH branch_summary AS (
    SELECT
        b.region,
        b.province,
        b.city,
        b.branch_id,
        b.branch_code,
        b.branch_name,
        b.branch_type,
        COUNT(t.transaction_id) AS total_transactions,
        COALESCE(SUM(t.amount), 0) AS total_amount,
        COALESCE(AVG(t.amount), 0) AS avg_transaction_amount,
        COUNT(DISTINCT t.customer_id) AS active_customers
    FROM dim_branches b
    LEFT JOIN fact_transactions t
        ON b.branch_id = t.branch_id
    GROUP BY
        b.region,
        b.province,
        b.city,
        b.branch_id,
        b.branch_code,
        b.branch_name,
        b.branch_type
)
SELECT
    region,
    province,
    city,
    branch_id,
    branch_code,
    branch_name,
    branch_type,
    total_transactions,
    total_amount,
    avg_transaction_amount,
    active_customers,
    RANK() OVER (
        PARTITION BY region
        ORDER BY total_transactions DESC
    ) AS transaction_rank_region,
    RANK() OVER (
        PARTITION BY region
        ORDER BY total_amount DESC
    ) AS amount_rank_region
FROM branch_summary;