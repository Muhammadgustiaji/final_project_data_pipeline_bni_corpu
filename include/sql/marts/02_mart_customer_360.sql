TRUNCATE TABLE mart_customer_360;

INSERT INTO mart_customer_360 (
    customer_id,
    customer_code,
    full_name,
    segment,
    job_segment,
    city,
    province,
    branch_id,
    total_transactions,
    total_amount,
    avg_transaction_amount,
    max_transaction_amount,
    active_days,
    first_transaction_date,
    last_transaction_date,
    frequency_rank,
    amount_rank,
    customer_value_segment
)
WITH customer_summary AS (
    SELECT
        c.customer_id,
        c.customer_code,
        c.full_name,
        c.segment,
        c.job_segment,
        c.city,
        c.province,
        c.branch_id,
        COUNT(t.transaction_id) AS total_transactions,
        COALESCE(SUM(t.amount), 0) AS total_amount,
        COALESCE(AVG(t.amount), 0) AS avg_transaction_amount,
        COALESCE(MAX(t.amount), 0) AS max_transaction_amount,
        COUNT(DISTINCT t.transaction_date) AS active_days,
        MIN(t.transaction_date) AS first_transaction_date,
        MAX(t.transaction_date) AS last_transaction_date
    FROM dim_customers c
    LEFT JOIN fact_transactions t
        ON c.customer_id = t.customer_id
    GROUP BY
        c.customer_id,
        c.customer_code,
        c.full_name,
        c.segment,
        c.job_segment,
        c.city,
        c.province,
        c.branch_id
),
ranked AS (
    SELECT
        *,
        RANK() OVER (ORDER BY total_transactions DESC) AS frequency_rank,
        RANK() OVER (ORDER BY total_amount DESC) AS amount_rank
    FROM customer_summary
)
SELECT
    customer_id,
    customer_code,
    full_name,
    segment,
    job_segment,
    city,
    province,
    branch_id,
    total_transactions,
    total_amount,
    avg_transaction_amount,
    max_transaction_amount,
    active_days,
    first_transaction_date,
    last_transaction_date,
    frequency_rank,
    amount_rank,
    CASE
        WHEN total_amount >= 50000000 THEN 'VIP'
        WHEN total_amount >= 15000000 THEN 'Priority'
        ELSE 'Retail'
    END AS customer_value_segment
FROM ranked;