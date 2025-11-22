# Matrics Mall
## A data streaming process platform

A Flink-based platform that consumes Kafka data, performs real-time calculations, and writes results to ClickHouse with Grafana monitoring.

## Quick Start

```bash
# Start all services
docker-compose up -d

# Check status
docker-compose ps

# Stop services
docker-compose down

# View logs
docker-compose logs -f [service_name]
```

After docker containers have started, [install required libraries](https://medium.com/@rongjin.zh/how-to-build-a-minimal-data-processing-system-with-kafka-flink-and-clickhouse-70de1dd5b1ea#:~:text=yml%20up%20%2Dd-,2,-.%20Installing%20Required%20Libraries).


**Services:**
- Flink Web UI: http://localhost:8081
- Grafana: http://localhost:3000 (admin/admin)
- ClickHouse: http://localhost:8123
- Kafka: localhost:9092, 9093

## Schema Configuration

Refer to `doc/schema-flink.sql` for complete example. Basic schema:

```sql
-- Kafka source table
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

-- ClickHouse sink table
CREATE TABLE metrics (
  metric_name STRING,
  metric_value DOUBLE,
  window_start TIMESTAMP(3),
  window_end TIMESTAMP(3)
) WITH (
  'connector' = 'clickhouse',
  'url' = 'clickhouse://clickhouse:8123',
  'database-name' = 'default',
  'table-name' = 'metrics'
);

-- Stream processing job
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
```

Execute SQL via Flink Web UI at http://localhost:8081

## Test Data

Refer to `test/events_kafka_template.json` for data format:

```json
{"user_id": 12345, "action": "click", "ts": "2024-01-01T12:00:00.000Z"}
```

Send to Kafka:
```bash
echo '{"user_id": 12345, "action": "click", "ts": "2024-01-01T12:00:00.000Z"}' | \
  docker exec -i kafka kafka-console-producer --broker-list localhost:9092 --topic events
```

## Grafana Monitoring

Refer to `doc/grafana.sql` for query examples.

1. Access http://localhost:3000 (admin/admin)
2. Add ClickHouse data source: `localhost:8123`, database `default`
3. Create panel with query:

```sql
SELECT window_start, metric_value
FROM metrics
WHERE metric_name = 'click_count'
ORDER BY window_start
```

## Directory Structure

```
├── docker-compose.yml
├── doc/
│   ├── schema-flink.sql
│   └── grafana.sql
├── test/
│   └── events_kafka_template.json
├── docker/        # Flink libs (gitignored)
└── lib/           # Dependencies (gitignored)
```

## Notes

- Place Flink JARs in `docker/lib/flink-jobs/` and `docker/lib/flink-tasks/`
- Ensure ports 2181, 8081, 9092, 9093, 8123, 9000, 3000 are available
- Recommend at least 4GB memory
