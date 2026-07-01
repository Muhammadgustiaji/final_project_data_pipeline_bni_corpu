TRUNCATE TABLE mart_risk_fraud_detection;

INSERT INTO mart_risk_fraud_detection (
    transaction_id,
    transaction_code,
    transaction_date,
    transaction_at,
    customer_id,
    customer_code,
    full_name,
    segment,
    channel_id,
    channel_code,
    channel_name,
    transaction_type,
    amount,
    status,
    daily_customer_txn_count,
    daily_customer_amount,
    failed_count_per_day,
    avg_customer_amount,
    anomaly_amount_flag,
    high_frequency_flag,
    repeated_failed_flag,
    fraud_label_flag,
    fraud_type,
    fraud_score,
    risk_level,
    anomaly_reason
)
WITH customer_stats AS (
    SELECT
        customer_id,
        AVG(amount) AS avg_customer_amount,
        STDDEV_POP(amount) AS stddev_customer_amount
    FROM fact_transactions
    GROUP BY customer_id
),
daily_stats AS (
    SELECT
        customer_id,
        transaction_date,
        COUNT(*) AS daily_customer_txn_count,
        SUM(amount) AS daily_customer_amount,
        COUNT(*) FILTER (
            WHERE UPPER(status) IN ('FAILED', 'FAIL', 'GAGAL', 'REJECTED')
        ) AS failed_count_per_day
    FROM fact_transactions
    GROUP BY customer_id, transaction_date
),
base AS (
    SELECT
        t.transaction_id,
        t.transaction_code,
        t.transaction_date,
        t.transaction_at,
        t.customer_id,
        c.customer_code,
        c.full_name,
        c.segment,
        t.channel_id,
        ch.channel_code,
        ch.channel_name,
        t.transaction_type,
        t.amount,
        t.status,
        ds.daily_customer_txn_count,
        ds.daily_customer_amount,
        ds.failed_count_per_day,
        cs.avg_customer_amount,
        cs.stddev_customer_amount,
        fl.is_fraud AS fraud_label_flag,
        fl.fraud_type,
        fl.fraud_score
    FROM fact_transactions t
    LEFT JOIN dim_customers c
        ON t.customer_id = c.customer_id
    LEFT JOIN dim_channels ch
        ON t.channel_id = ch.channel_id
    LEFT JOIN customer_stats cs
        ON t.customer_id = cs.customer_id
    LEFT JOIN daily_stats ds
        ON t.customer_id = ds.customer_id
       AND t.transaction_date = ds.transaction_date
    LEFT JOIN dim_fraud_labels fl
        ON t.transaction_id = fl.transaction_id
),
flagged AS (
    SELECT
        *,
        CASE
            WHEN amount >= 10000000 THEN TRUE
            WHEN stddev_customer_amount IS NOT NULL
                 AND amount > avg_customer_amount + (3 * stddev_customer_amount)
            THEN TRUE
            ELSE FALSE
        END AS anomaly_amount_flag,

        CASE
            WHEN daily_customer_txn_count >= 10 THEN TRUE
            ELSE FALSE
        END AS high_frequency_flag,

        CASE
            WHEN failed_count_per_day >= 3 THEN TRUE
            ELSE FALSE
        END AS repeated_failed_flag
    FROM base
)
SELECT
    transaction_id,
    transaction_code,
    transaction_date,
    transaction_at,
    customer_id,
    customer_code,
    full_name,
    segment,
    channel_id,
    channel_code,
    channel_name,
    transaction_type,
    amount,
    status,
    daily_customer_txn_count,
    daily_customer_amount,
    failed_count_per_day,
    avg_customer_amount,
    anomaly_amount_flag,
    high_frequency_flag,
    repeated_failed_flag,
    COALESCE(fraud_label_flag, FALSE) AS fraud_label_flag,
    fraud_type,
    fraud_score,

    CASE
        WHEN COALESCE(fraud_label_flag, FALSE) = TRUE
          OR anomaly_amount_flag = TRUE
          OR repeated_failed_flag = TRUE
        THEN 'High'
        WHEN high_frequency_flag = TRUE THEN 'Medium'
        ELSE 'Low'
    END AS risk_level,

    CONCAT_WS(
        '; ',
        CASE WHEN anomaly_amount_flag = TRUE THEN 'Nilai transaksi sangat besar/anomali' END,
        CASE WHEN high_frequency_flag = TRUE THEN 'Frekuensi transaksi harian tidak wajar' END,
        CASE WHEN repeated_failed_flag = TRUE THEN 'Status failed berulang dalam satu hari' END,
        CASE WHEN COALESCE(fraud_label_flag, FALSE) = TRUE THEN 'Terdapat label fraud' END
    ) AS anomaly_reason

FROM flagged
WHERE anomaly_amount_flag = TRUE
   OR high_frequency_flag = TRUE
   OR repeated_failed_flag = TRUE
   OR COALESCE(fraud_label_flag, FALSE) = TRUE
ORDER BY risk_level DESC, amount DESC;