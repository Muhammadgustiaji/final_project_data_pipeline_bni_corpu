-- Index untuk mempercepat query mart analytics

CREATE INDEX IF NOT EXISTS idx_fact_transactions_date
ON fact_transactions (transaction_date);

CREATE INDEX IF NOT EXISTS idx_fact_transactions_customer
ON fact_transactions (customer_id);

CREATE INDEX IF NOT EXISTS idx_fact_transactions_branch
ON fact_transactions (branch_id);

CREATE INDEX IF NOT EXISTS idx_fact_transactions_channel
ON fact_transactions (channel_id);

CREATE INDEX IF NOT EXISTS idx_fact_transactions_account
ON fact_transactions (account_id);

CREATE INDEX IF NOT EXISTS idx_fact_transactions_status
ON fact_transactions (status);

CREATE INDEX IF NOT EXISTS idx_fact_transactions_customer_date
ON fact_transactions (customer_id, transaction_date);

CREATE INDEX IF NOT EXISTS idx_fact_transactions_transaction_id
ON fact_transactions (transaction_id);

CREATE INDEX IF NOT EXISTS idx_dim_customers_customer_id
ON dim_customers (customer_id);

CREATE INDEX IF NOT EXISTS idx_dim_accounts_account_id
ON dim_accounts (account_id);

CREATE INDEX IF NOT EXISTS idx_dim_branches_branch_id
ON dim_branches (branch_id);

CREATE INDEX IF NOT EXISTS idx_dim_channels_channel_id
ON dim_channels (channel_id);

CREATE INDEX IF NOT EXISTS idx_dim_fraud_labels_transaction_id
ON dim_fraud_labels (transaction_id);

ANALYZE fact_transactions;
ANALYZE dim_customers;
ANALYZE dim_accounts;
ANALYZE dim_branches;
ANALYZE dim_channels;
ANALYZE dim_fraud_labels;