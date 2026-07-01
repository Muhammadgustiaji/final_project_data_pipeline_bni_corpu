-- Transform: stg_channels → dim_channels
-- Cast tipe data, tambah derived columns, deduplikasi

TRUNCATE TABLE dim_channels;

INSERT INTO dim_channels (
    channel_id,
    channel_code,
    channel_name,
    channel_category,
    is_digital,
    description,
    -- derived columns
    channel_group
)
SELECT DISTINCT ON (channel_id)
    channel_id,
    channel_code,
    channel_name,
    channel_category,

    -- konversi is_digital dari text ke boolean
    CASE
        WHEN LOWER(is_digital) IN ('true', 't', '1', 'yes', 'y') THEN TRUE
        ELSE FALSE
    END AS is_digital,

    description,

    -- pengelompokan channel
    CASE
        WHEN LOWER(is_digital) IN ('true', 't', '1', 'yes', 'y') THEN 'Digital Channel'
        ELSE 'Non-Digital Channel'
    END AS channel_group

FROM stg_channels
WHERE channel_id IS NOT NULL
ORDER BY channel_id;