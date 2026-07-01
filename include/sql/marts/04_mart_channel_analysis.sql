TRUNCATE TABLE mart_channel_analysis;

INSERT INTO mart_channel_analysis (
    period_month,
    channel_id,
    channel_code,
    channel_name,
    channel_category,
    is_digital,
    channel_group,
    total_transactions,
    total_amount,
    active_customers,
    channel_usage_rank,
    digital_transactions,
    non_digital_transactions,
    digital_share_pct
)
WITH base AS (
    SELECT
        DATE_TRUNC('month', t.transaction_date)::DATE AS period_month,
        ch.channel_id,
        ch.channel_code,
        ch.channel_name,
        ch.channel_category,
        ch.is_digital,
        ch.channel_group,
        COUNT(t.transaction_id) AS total_transactions,
        COALESCE(SUM(t.amount), 0) AS total_amount,
        COUNT(DISTINCT t.customer_id) AS active_customers
    FROM fact_transactions t
    JOIN dim_channels ch
        ON t.channel_id = ch.channel_id
    GROUP BY
        DATE_TRUNC('month', t.transaction_date)::DATE,
        ch.channel_id,
        ch.channel_code,
        ch.channel_name,
        ch.channel_category,
        ch.is_digital,
        ch.channel_group
),
monthly_total AS (
    SELECT
        period_month,
        SUM(CASE WHEN is_digital = TRUE THEN total_transactions ELSE 0 END) AS digital_transactions,
        SUM(CASE WHEN is_digital = FALSE THEN total_transactions ELSE 0 END) AS non_digital_transactions,
        SUM(total_transactions) AS all_transactions
    FROM base
    GROUP BY period_month
)
SELECT
    b.period_month,
    b.channel_id,
    b.channel_code,
    b.channel_name,
    b.channel_category,
    b.is_digital,
    b.channel_group,
    b.total_transactions,
    b.total_amount,
    b.active_customers,
    RANK() OVER (
        PARTITION BY b.period_month
        ORDER BY b.total_transactions DESC
    ) AS channel_usage_rank,
    mt.digital_transactions,
    mt.non_digital_transactions,
    CASE
        WHEN mt.all_transactions = 0 THEN 0
        ELSE ROUND((mt.digital_transactions::NUMERIC / mt.all_transactions) * 100, 2)
    END AS digital_share_pct
FROM base b
JOIN monthly_total mt
    ON b.period_month = mt.period_month;