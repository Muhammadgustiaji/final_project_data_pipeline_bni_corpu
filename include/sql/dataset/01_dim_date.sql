-- Transform: stg_dates → dim_date
-- Cast tipe data, konversi boolean, deduplikasi

TRUNCATE TABLE dim_date;

INSERT INTO dim_date (
    date_id,
    full_date,
    year,
    quarter,
    month,
    month_name,
    week_of_year,
    day_of_month,
    day_of_week,
    day_name,
    is_weekend,
    is_holiday
)
SELECT DISTINCT ON (date_id)
    date_id,
    NULLIF(full_date, '')::DATE AS full_date,
    year,
    quarter,
    month,
    month_name,
    week_of_year,
    day_of_month,
    day_of_week,
    day_name,

    -- konversi is_weekend dari text ke boolean
    CASE
        WHEN LOWER(is_weekend) IN ('true', 't', '1', 'yes', 'y') THEN TRUE
        ELSE FALSE
    END AS is_weekend,

    -- konversi is_holiday dari text ke boolean
    CASE
        WHEN LOWER(is_holiday) IN ('true', 't', '1', 'yes', 'y') THEN TRUE
        ELSE FALSE
    END AS is_holiday

FROM stg_dates
WHERE date_id IS NOT NULL
ORDER BY date_id;