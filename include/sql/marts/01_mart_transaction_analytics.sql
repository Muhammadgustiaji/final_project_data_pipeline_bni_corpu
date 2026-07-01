TRUNCATE TABLE mart_transaction_analytics;

INSERT INTO mart_transaction_analytics (
    period_type,
    period_start_date,
    total_transactions,
    total_amount,
    avg_transaction_amount,
    success_transactions,
    failed_transactions,
    pending_transactions,
    previous_total_amount,
    growth_amount_pct
)
WITH base AS (
    SELECT
        'DAY' AS period_type,
        transaction_date AS period_start_date,
        COUNT(*) AS total_transactions,
        SUM(amount) AS total_amount,
        AVG(amount) AS avg_transaction_amount,
        COUNT(*) FILTER (WHERE UPPER(status) IN ('SUCCESS', 'SUCCESSFUL', 'BERHASIL', 'COMPLETED')) AS success_transactions,
        COUNT(*) FILTER (WHERE UPPER(status) IN ('FAILED', 'FAIL', 'GAGAL', 'REJECTED')) AS failed_transactions,
        COUNT(*) FILTER (WHERE UPPER(status) = 'PENDING') AS pending_transactions
    FROM fact_transactions
    GROUP BY transaction_date

    UNION ALL

    SELECT
        'WEEK' AS period_type,
        DATE_TRUNC('week', transaction_date)::DATE AS period_start_date,
        COUNT(*) AS total_transactions,
        SUM(amount) AS total_amount,
        AVG(amount) AS avg_transaction_amount,
        COUNT(*) FILTER (WHERE UPPER(status) IN ('SUCCESS', 'SUCCESSFUL', 'BERHASIL', 'COMPLETED')) AS success_transactions,
        COUNT(*) FILTER (WHERE UPPER(status) IN ('FAILED', 'FAIL', 'GAGAL', 'REJECTED')) AS failed_transactions,
        COUNT(*) FILTER (WHERE UPPER(status) = 'PENDING') AS pending_transactions
    FROM fact_transactions
    GROUP BY DATE_TRUNC('week', transaction_date)::DATE

    UNION ALL

    SELECT
        'MONTH' AS period_type,
        DATE_TRUNC('month', transaction_date)::DATE AS period_start_date,
        COUNT(*) AS total_transactions,
        SUM(amount) AS total_amount,
        AVG(amount) AS avg_transaction_amount,
        COUNT(*) FILTER (WHERE UPPER(status) IN ('SUCCESS', 'SUCCESSFUL', 'BERHASIL', 'COMPLETED')) AS success_transactions,
        COUNT(*) FILTER (WHERE UPPER(status) IN ('FAILED', 'FAIL', 'GAGAL', 'REJECTED')) AS failed_transactions,
        COUNT(*) FILTER (WHERE UPPER(status) = 'PENDING') AS pending_transactions
    FROM fact_transactions
    GROUP BY DATE_TRUNC('month', transaction_date)::DATE
),
growth_calc AS (
    SELECT
        *,
        LAG(total_amount) OVER (
            PARTITION BY period_type
            ORDER BY period_start_date
        ) AS previous_total_amount
    FROM base
)
SELECT
    period_type,
    period_start_date,
    total_transactions,
    total_amount,
    avg_transaction_amount,
    success_transactions,
    failed_transactions,
    pending_transactions,
    previous_total_amount,
    CASE
        WHEN previous_total_amount IS NULL OR previous_total_amount = 0 THEN NULL
        ELSE ROUND(((total_amount - previous_total_amount) / previous_total_amount) * 100, 2)
    END AS growth_amount_pct
FROM growth_calc
ORDER BY period_type, period_start_date;