SELECT
    window_start,
    metric_value
FROM metrics
WHERE metric_name = 'click_count'
ORDER BY window_start