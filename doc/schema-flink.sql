CREATE TABLE events (
  user_id INT,
  action STRING,
  ts TIMESTAMP(3),
  WATERMARK FOR ts AS ts - INTERVAL '5' SECOND
) WITH (
  'connector' = 'kafka',
  'topic' = 'events',
  'properties.bootstrap.servers' = 'kafka:9092',
  'scan.startup.mode' = 'earliest-offset',
  'format' = 'json'
);


CREATE TABLE metrics (
  metric_name STRING,
  metric_value DOUBLE,
  window_start TIMESTAMP(3),
  window_end TIMESTAMP(3)
) WITH (
  'connector' = 'clickhouse',
  'url' = 'clickhouse://clickhouse:8123',
  'database-name' = 'default',
  'table-name' = 'metrics',
  'sink.batch-size' = '500',
  'sink.flush-interval' = '1000',
  'sink.max-retries' = '3',
  'sink.ignore-delete'='false'
);


INSERT INTO metrics
SELECT
  action AS metric_name,
  COUNT(*) AS metric_value,
  window_start,
  window_end
FROM TABLE(
  TUMBLE(TABLE events, DESCRIPTOR(ts), INTERVAL '1' MINUTE)
)
GROUP BY action, window_start, window_end;

