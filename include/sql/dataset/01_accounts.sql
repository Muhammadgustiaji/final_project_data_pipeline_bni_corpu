-- Transform: stg_accounts → dim_accounts
-- Cast tipe data, tambah derived columns, deduplikasi

TRUNCATE TABLE dim_accounts;

INSERT INTO dim_accounts (
    account_id,
    account_no,
    account_type,
    product_name,
    currency,
    open_date,
    close_date,
    status,
    interest_rate,
    customer_id,
    branch_id,
    -- derived columns
    is_active,
    account_age_year
)
SELECT DISTINCT ON (account_id)
    account_id,
    account_no,
    account_type,
    product_name,
    currency,
    NULLIF(open_date, '')::DATE AS open_date,
    NULLIF(close_date, '')::DATE AS close_date,
    status,
    interest_rate::NUMERIC(5,2),
    customer_id,
    branch_id,

    -- status rekening aktif
    CASE
        WHEN UPPER(status) = 'ACTIVE' THEN TRUE
        ELSE FALSE
    END AS is_active,

    -- umur rekening dari tanggal pembukaan rekening
    CASE
        WHEN NULLIF(open_date, '') IS NOT NULL THEN
            DATE_PART('year', AGE(CURRENT_DATE, NULLIF(open_date, '')::DATE))::SMALLINT
        ELSE NULL
    END AS account_age_year

FROM stg_accounts
WHERE account_id IS NOT NULL
ORDER BY account_id;