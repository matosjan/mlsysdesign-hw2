CREATE DATABASE IF NOT EXISTS hw2;

CREATE TABLE IF NOT EXISTS hw2.transactions
(
    transaction_time DateTime,
    merch String,
    cat_id String,
    amount Decimal(12, 2),
    name_1 String,
    name_2 String,
    gender String,
    street String,
    one_city String,
    us_state String,
    post_code String,
    lat Float64,
    lon Float64,
    population_city UInt32,
    jobs String,
    merchant_lat Float64,
    merchant_lon Float64,
    target Nullable(UInt8),
    PROJECTION max_by_state
    (
        SELECT
            us_state,
            argMax(cat_id, tuple(amount, cat_id)),
            max(amount)
        GROUP BY us_state
    )
)
ENGINE = MergeTree
ORDER BY tuple();

CREATE TABLE IF NOT EXISTS hw2.transactions_kafka
(
    transaction_time DateTime,
    merch String,
    cat_id String,
    amount Decimal(12, 2),
    name_1 String,
    name_2 String,
    gender String,
    street String,
    one_city String,
    us_state String,
    post_code String,
    lat Float64,
    lon Float64,
    population_city UInt32,
    jobs String,
    merchant_lat Float64,
    merchant_lon Float64,
    target Nullable(UInt8)
)
ENGINE = Kafka
SETTINGS
    kafka_broker_list = 'kafka:9092',
    kafka_topic_list = 'transactions',
    kafka_group_name = 'clickhouse',
    kafka_format = 'JSONEachRow',
    date_time_input_format = 'best_effort';

CREATE MATERIALIZED VIEW IF NOT EXISTS hw2.transactions_mv
TO hw2.transactions
AS SELECT * FROM hw2.transactions_kafka;
