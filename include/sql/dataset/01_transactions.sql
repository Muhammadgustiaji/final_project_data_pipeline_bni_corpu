-- Transform: stg_transactions → fact_transactions
-- Cast tipe data, tambah derived columns, deduplikasi

TRUNCATE TABLE fact_transactions;

INSERT INTO fact_transactions (
    transaction_id,
    transaction_code,
    account_id,
    customer_id,
    branch_id,
    channel_id,
    date_id,
    transaction_date,
    transaction_at,
    transaction_type,
    amount,
    balance_before,
    balance_after,
    status,
    reference_no,

    -- derived columns
    transaction_hour,
    balance_change,
    is_success,
    amount_segment
)
SELECT DISTINCT ON (transaction_id)
    transaction_id,
    transaction_code,
    account_id,
    customer_id,
    branch_id,
    channel_id,

    -- date_id untuk relasi ke dim_date
    CASE
        WHEN NULLIF(transaction_date, '') IS NOT NULL THEN
            TO_CHAR(NULLIF(transaction_date, '')::DATE, 'YYYYMMDD')::INTEGER
        ELSE NULL
    END AS date_id,

    NULLIF(transaction_date, '')::DATE AS transaction_date,
    NULLIF(transaction_at, '')::TIMESTAMP AS transaction_at,

    transaction_type,
    amount::NUMERIC(18,2),
    balance_before::NUMERIC(18,2),
    balance_after::NUMERIC(18,2),
    status,
    reference_no,

    -- jam transaksi
    CASE
        WHEN NULLIF(transaction_at, '') IS NOT NULL THEN
            EXTRACT(HOUR FROM NULLIF(transaction_at, '')::TIMESTAMP)::SMALLINT
        ELSE NULL
    END AS transaction_hour,

    -- perubahan saldo setelah transaksi
    (
        balance_after::NUMERIC(18,2) - balance_before::NUMERIC(18,2)
    )::NUMERIC(18,2) AS balance_change,

    -- status transaksi berhasil atau tidak
    CASE
        WHEN UPPER(status) IN ('SUCCESS', 'SUCCESSFUL', 'BERHASIL', 'COMPLETED') THEN TRUE
        ELSE FALSE
    END AS is_success,

    -- segmentasi nominal transaksi
    CASE
        WHEN amount IS NULL THEN 'Unknown'
        WHEN amount::NUMERIC(18,2) < 1000000 THEN 'Low'
        WHEN amount::NUMERIC(18,2) < 5000000 THEN 'Medium'
        WHEN amount::NUMERIC(18,2) < 10000000 THEN 'High'
        ELSE 'Very High'
    END AS amount_segment

FROM stg_transactions
WHERE transaction_id IS NOT NULL
ORDER BY transaction_id;