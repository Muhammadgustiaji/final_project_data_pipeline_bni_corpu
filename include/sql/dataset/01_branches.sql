-- Transform: stg_branches → dim_branches
-- Cast tipe data, tambah derived columns, deduplikasi

TRUNCATE TABLE dim_branches;

INSERT INTO dim_branches (
    branch_id,
    branch_code,
    branch_name,
    city,
    province,
    region,
    branch_type,
    open_date,
    is_active,
    -- derived columns
    branch_age_year
)
SELECT DISTINCT ON (branch_id)
    branch_id,
    branch_code,
    branch_name,
    city,
    province,
    region,
    branch_type,
    NULLIF(open_date, '')::DATE AS open_date,

    -- konversi is_active dari text ke boolean
    CASE
        WHEN LOWER(is_active) IN ('true', 't', '1', 'yes', 'y') THEN TRUE
        ELSE FALSE
    END AS is_active,

    -- umur cabang dari tanggal pembukaan cabang
    CASE
        WHEN NULLIF(open_date, '') IS NOT NULL THEN
            DATE_PART('year', AGE(CURRENT_DATE, NULLIF(open_date, '')::DATE))::SMALLINT
        ELSE NULL
    END AS branch_age_year

FROM stg_branches
WHERE branch_id IS NOT NULL
ORDER BY branch_id;