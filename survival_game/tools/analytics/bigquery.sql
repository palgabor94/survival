-- Standard SQL. Replace project and property IDs; pass YYYYMMDD date parameters.
-- Export normalized rows as JSONL for analyze.py. IDs deduplicate SDK retries.
WITH normalized AS (
  SELECT event_name AS name,
    FORMAT_TIMESTAMP('%Y-%m-%dT%H:%M:%E6SZ', TIMESTAMP_MILLIS(COALESCE((SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'client_time_ms'), DIV(event_timestamp, 1000))), 'UTC') AS at,
    user_id AS player_id, event_timestamp,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'event_id') AS event_id,
    (SELECT AS STRUCT
      (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'event_id') AS event_id,
      (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'event_index') AS event_index,
      (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'session_id') AS session_id,
      (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'run_id') AS run_id,
      (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'screen') AS screen,
      (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'location') AS location,
      (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'fatal_location') AS fatal_location,
      (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'day') AS day,
      (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'duration_ms') AS duration_ms,
      (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'idle_seconds') AS idle_seconds,
      (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'outcome') AS outcome,
      (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'target') AS target,
      (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'event') AS event,
      (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'choice') AS choice
    ) AS parameters
  FROM `YOUR_PROJECT.analytics_YOUR_PROPERTY_ID.events_*`
  WHERE _TABLE_SUFFIX BETWEEN @start_date AND @end_date
    AND STARTS_WITH(event_name, 'lc_')
)
SELECT name, at, player_id, parameters FROM normalized
WHERE event_id IS NOT NULL
QUALIFY ROW_NUMBER() OVER (PARTITION BY event_id ORDER BY event_timestamp) = 1
ORDER BY at;
