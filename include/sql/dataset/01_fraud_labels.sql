-- Transform: stg_fraud_labels → dim_fraud_labels
-- Cast tipe data, tambah derived columns, deduplikasi

TRUNCATE TABLE dim_fraud_labels;

INSERT INTO dim_fraud_labels (
    transaction_id,
    transaction_code,
    is_fraud,
    fraud_type,
    fraud_score,
    flagged_at,
    -- derived columns
    fraud_risk_level
)
SELECT DISTINCT ON (transaction_id)
    transaction_id,
    transaction_code,

    -- konversi is_fraud dari text ke boolean
    CASE
        WHEN LOWER(is_fraud) IN ('true', 't', '1', 'yes', 'y') THEN TRUE
        ELSE FALSE
    END AS is_fraud,

    fraud_type,
    fraud_score::NUMERIC(6,4),
    NULLIF(flagged_at, '')::TIMESTAMP AS flagged_at,

    -- segmentasi risiko fraud berdasarkan fraud_score
    CASE
        WHEN fraud_score >= 0.9000 THEN 'Critical'
        WHEN fraud_score >= 0.7500 THEN 'High'
        WHEN fraud_score >= 0.5000 THEN 'Medium'
        ELSE 'Low'
    END AS fraud_risk_level

FROM stg_fraud_labels
WHERE transaction_id IS NOT NULL
ORDER BY transaction_id;