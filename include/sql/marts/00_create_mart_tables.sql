CREATE TABLE IF NOT EXISTS mart_transaction_analytics (
    period_type             VARCHAR(10),
    period_start_date       DATE,
    total_transactions      INTEGER,
    total_amount            NUMERIC(18,2),
    avg_transaction_amount  NUMERIC(18,2),
    success_transactions    INTEGER,
    failed_transactions     INTEGER,
    pending_transactions    INTEGER,
    previous_total_amount   NUMERIC(18,2),
    growth_amount_pct       NUMERIC(10,2),
    etl_loaded_at           TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS mart_customer_360 (
    customer_id             INTEGER,
    customer_code           VARCHAR(20),
    full_name               VARCHAR(150),
    segment                 VARCHAR(20),
    job_segment             VARCHAR(100),
    city                    VARCHAR(100),
    province                VARCHAR(100),
    branch_id               INTEGER,
    total_transactions      INTEGER,
    total_amount            NUMERIC(18,2),
    avg_transaction_amount  NUMERIC(18,2),
    max_transaction_amount  NUMERIC(18,2),
    active_days             INTEGER,
    first_transaction_date  DATE,
    last_transaction_date   DATE,
    frequency_rank          INTEGER,
    amount_rank             INTEGER,
    customer_value_segment  VARCHAR(20),
    etl_loaded_at           TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS mart_branch_performance (
    region                  VARCHAR(100),
    province                VARCHAR(100),
    city                    VARCHAR(100),
    branch_id               INTEGER,
    branch_code             VARCHAR(20),
    branch_name             VARCHAR(150),
    branch_type             VARCHAR(20),
    total_transactions      INTEGER,
    total_amount            NUMERIC(18,2),
    avg_transaction_amount  NUMERIC(18,2),
    active_customers        INTEGER,
    transaction_rank_region INTEGER,
    amount_rank_region      INTEGER,
    etl_loaded_at           TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS mart_channel_analysis (
    period_month             DATE,
    channel_id               INTEGER,
    channel_code             VARCHAR(20),
    channel_name             VARCHAR(100),
    channel_category         VARCHAR(50),
    is_digital               BOOLEAN,
    channel_group            VARCHAR(30),
    total_transactions       INTEGER,
    total_amount             NUMERIC(18,2),
    active_customers         INTEGER,
    channel_usage_rank       INTEGER,
    digital_transactions     INTEGER,
    non_digital_transactions INTEGER,
    digital_share_pct        NUMERIC(10,2),
    etl_loaded_at            TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS mart_product_performance (
    period_month            DATE,
    account_type            VARCHAR(50),
    product_name            VARCHAR(100),
    currency                VARCHAR(10),
    total_accounts          INTEGER,
    total_transactions      INTEGER,
    total_amount            NUMERIC(18,2),
    avg_transaction_amount  NUMERIC(18,2),
    avg_balance_before      NUMERIC(18,2),
    avg_balance_after       NUMERIC(18,2),
    product_volume_rank     INTEGER,
    product_balance_rank    INTEGER,
    etl_loaded_at           TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS mart_risk_fraud_detection (
    transaction_id            INTEGER,
    transaction_code          VARCHAR(30),
    transaction_date          DATE,
    transaction_at            TIMESTAMP,
    customer_id               INTEGER,
    customer_code             VARCHAR(20),
    full_name                 VARCHAR(150),
    segment                   VARCHAR(20),
    channel_id                INTEGER,
    channel_code              VARCHAR(20),
    channel_name              VARCHAR(100),
    transaction_type          VARCHAR(50),
    amount                    NUMERIC(18,2),
    status                    VARCHAR(20),
    daily_customer_txn_count  INTEGER,
    daily_customer_amount     NUMERIC(18,2),
    failed_count_per_day      INTEGER,
    avg_customer_amount       NUMERIC(18,2),
    anomaly_amount_flag       BOOLEAN,
    high_frequency_flag       BOOLEAN,
    repeated_failed_flag      BOOLEAN,
    fraud_label_flag          BOOLEAN,
    fraud_type                VARCHAR(50),
    fraud_score               NUMERIC(6,4),
    risk_level                VARCHAR(20),
    anomaly_reason            TEXT,
    etl_loaded_at             TIMESTAMP DEFAULT NOW()
);