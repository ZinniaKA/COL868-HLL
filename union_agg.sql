-- Testing hll_union_agg

\set QUIET on
\timing off
SET client_min_messages TO WARNING;

-- Clean tables from previous experiment if any
DROP TABLE IF EXISTS events CASCADE;
DROP TABLE IF EXISTS daily_sketches CASCADE;
DROP TABLE IF EXISTS results_union CASCADE;
DROP TABLE IF EXISTS results_exact_reagg CASCADE;

\echo ''
\echo '========================================'
\echo 'Generating Test Data'
\echo '========================================'
\echo ''

-- Create main events table
CREATE TABLE events (
    event_id SERIAL,
    timestamp TIMESTAMP,
    user_id INTEGER,
    date DATE
);

\echo '>>> Generating 1M events over 90 days...'
\echo '    (10K-15K events per day, ~50K unique users total)'
\echo ''
SELECT setseed(0.5);

-- Generate realistic event data
INSERT INTO events (timestamp, user_id, date)
SELECT 
    timestamp,
    -- Weighted user distribution
    CASE 
        WHEN random() < 0.1 THEN floor(random() * 1000)::int
        WHEN random() < 0.4 THEN floor(random() * 10000)::int
        ELSE floor(random() * 50000)::int
    END as user_id,
    timestamp::date as date
FROM generate_series(
    CURRENT_DATE - INTERVAL '90 days',
    CURRENT_DATE - INTERVAL '1 day',
    INTERVAL '6 seconds' -- ~10K events per day
) as timestamp;

CREATE INDEX idx_events_date ON events(date);
CREATE INDEX idx_events_user_date ON events(user_id, date);
ANALYZE events;

\echo '>>> Data generation complete!'
SELECT 
    COUNT(*) as total_events,
    COUNT(DISTINCT user_id) as total_unique_users,
    COUNT(DISTINCT date) as total_days
FROM events;

-- ============================================================================
-- STEP 1: Pre-compute Daily Sketches at Different Precisions
-- ============================================================================

\echo ''
\echo '========================================'
\echo 'STEP 1: Pre-computing Daily Sketches'
\echo '========================================'

CREATE TABLE daily_sketches (
    date DATE,
    precision INTEGER,
    user_sketch HLL,
    exact_count INTEGER,
    sketch_size_bytes INTEGER
);

\echo '>>> Creating daily sketches for precision 10, 12, 14...'

INSERT INTO daily_sketches (date, precision, user_sketch, exact_count)
SELECT 
    date,
    p as precision,
    hll_add_agg(hll_hash_integer(user_id), p) as user_sketch,
    COUNT(DISTINCT user_id) as exact_count
FROM events
CROSS JOIN (VALUES (10), (12), (14)) as precisions(p)
GROUP BY date, p;

-- Update actual sketch sizes
UPDATE daily_sketches
SET sketch_size_bytes = pg_column_size(user_sketch);

CREATE INDEX idx_daily_sketches_date_prec ON daily_sketches(date, precision);
ANALYZE daily_sketches;

\echo '>>> Daily sketches created!'

-- ============================================================================
-- STEP 2: Run HLL Union Aggregation (raw timings)
-- ============================================================================

\echo ''
\echo '========================================'
\echo 'PHASE 2: Run hll_union_agg'
\echo '========================================'

CREATE TABLE results_union (
    test_name VARCHAR(100),
    precision INTEGER,
    num_days INTEGER,
    run INTEGER,
    estimated_count BIGINT,
    query_time_ms NUMERIC,
    total_sketch_size_bytes BIGINT
);

SET client_min_messages TO NOTICE;
\timing on

DO $$
DECLARE
    v_start TIMESTAMP;
    v_end TIMESTAMP;
    v_precision INTEGER;
    v_days INTEGER;
    v_run INTEGER;
    v_result BIGINT;
    v_time_ms NUMERIC;
    v_size BIGINT;
BEGIN
    FOREACH v_days IN ARRAY ARRAY[7, 14, 30, 60, 90] LOOP
        FOREACH v_precision IN ARRAY ARRAY[10, 12, 14] LOOP
            RAISE NOTICE '';
            RAISE NOTICE '>>> Testing: % days, precision %', v_days, v_precision;
            FOR v_run IN 1..5 LOOP
                v_start := clock_timestamp();
                
                SELECT 
                    hll_cardinality(hll_union_agg(user_sketch))::bigint,
                    SUM(sketch_size_bytes)
                INTO v_result, v_size
                FROM daily_sketches
                WHERE precision = v_precision
                  AND date >= CURRENT_DATE - (v_days || ' days')::interval;
                
                v_end := clock_timestamp();
                v_time_ms := EXTRACT(EPOCH FROM (v_end - v_start)) * 1000;
                
                INSERT INTO results_union VALUES (
                    'union_' || v_days || 'd',
                    v_precision,
                    v_days,
                    v_run,
                    v_result,
                    v_time_ms,
                    v_size
                );
                RAISE NOTICE '  Run %: Estimated = %, Time = % ms', v_run, v_result, ROUND(v_time_ms, 2);
            END LOOP;
        END LOOP;
    END LOOP;
END $$;

-- ============================================================================
-- STEP 3: Run Exact Re-aggregation (raw timings)
-- ============================================================================

\echo ''
\echo '========================================'
\echo 'STEP 3: Run Exact Re-aggregation'
\echo '========================================'

CREATE TABLE results_exact_reagg (
    test_name VARCHAR(100),
    num_days INTEGER,
    run INTEGER,
    exact_count BIGINT,
    query_time_ms NUMERIC
);

DO $$
DECLARE
    v_start TIMESTAMP;
    v_end TIMESTAMP;
    v_days INTEGER;
    v_run INTEGER;
    v_result BIGINT;
    v_time_ms NUMERIC;
BEGIN
    FOREACH v_days IN ARRAY ARRAY[7, 14, 30, 60, 90] LOOP
        RAISE NOTICE '';
        RAISE NOTICE '>>> Testing exact COUNT(DISTINCT) for % days', v_days;
        FOR v_run IN 1..5 LOOP
            v_start := clock_timestamp();
            
            SELECT COUNT(DISTINCT user_id)::bigint
            INTO v_result
            FROM events
            WHERE date >= CURRENT_DATE - (v_days || ' days')::interval;
            
            v_end := clock_timestamp();
            v_time_ms := EXTRACT(EPOCH FROM (v_end - v_start)) * 1000;
            
            INSERT INTO results_exact_reagg VALUES (
                'exact_' || v_days || 'd',
                v_days,
                v_run,
                v_result,
                v_time_ms
            );
            RAISE NOTICE '  Run %: Count = %, Time = % ms', v_run, v_result, ROUND(v_time_ms, 2);
        END LOOP;
    END LOOP;
END $$;

-- ============================================================================
-- STEP 4: Export Tables
-- ============================================================================

\echo ''
\echo '>>> Exporting tables...'

-- Create directories first
\! mkdir -p '/code/tables/experiment_2'

-- Export raw timing data
\copy results_union TO '/code/tables/experiment_2/union.csv' CSV HEADER
\copy results_exact_reagg TO '/code/tables/experiment_2/exact.csv' CSV HEADER

\echo ''
\echo '========================================'
\echo 'EXPERIMENT 2 COMPLETE!'
\echo '========================================'
\echo ''
\echo 'Results saved to /code/tables/experiment_2'
\echo '  /code/tables/experiment_2/exact.csv'
\echo '  /code/tables/experiment_2/union.csv'
\echo ''
\echo 'Run the following to generate plots:' 
\echo 'docker compose -f docker-compose.graphs.yml run --rm plotter python plot_experiment_2.py'
