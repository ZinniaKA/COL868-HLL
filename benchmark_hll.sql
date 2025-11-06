-- ============================================================
-- HyperLogLog (HLL) Benchmarking Script
-- Tests: Accuracy, Speed, Memory vs Exact COUNT(DISTINCT)
-- ============================================================

-- Clean start
DROP TABLE IF EXISTS benchmark_data CASCADE;
DROP TABLE IF EXISTS results_exact CASCADE;
DROP TABLE IF EXISTS results_hll CASCADE;

-- ============================================================
-- 1. DATA GENERATION
-- ============================================================

-- Create test table with variable cardinality
CREATE TABLE benchmark_data (
    id SERIAL PRIMARY KEY,
    user_id INTEGER,
    session_id TEXT,
    timestamp TIMESTAMP DEFAULT NOW()
);

-- Generate data: 1M rows with ~100K distinct user_ids
-- Adjust this to test different sizes: 10K, 100K, 1M, 10M
INSERT INTO benchmark_data (user_id, session_id)
SELECT 
    (random() * 100000)::INTEGER as user_id,
    md5(random()::text) as session_id
FROM generate_series(1, 1000000);

CREATE INDEX idx_user_id ON benchmark_data(user_id);
ANALYZE benchmark_data;

-- ============================================================
-- 2. EXACT COUNT BASELINE
-- ============================================================

-- Create results table
CREATE TABLE results_exact (
    test_name TEXT,
    row_count BIGINT,
    distinct_count BIGINT,
    duration_ms NUMERIC,
    memory_mb NUMERIC,
    run_number INTEGER
);

-- Warmup run
SELECT COUNT(DISTINCT user_id) FROM benchmark_data;

-- Run 5 times for exact count
DO $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    duration_ms NUMERIC;
    distinct_cnt BIGINT;
    i INTEGER;
BEGIN
    FOR i IN 1..5 LOOP
        start_time := clock_timestamp();
        
        SELECT COUNT(DISTINCT user_id) INTO distinct_cnt
        FROM benchmark_data;
        
        end_time := clock_timestamp();
        duration_ms := EXTRACT(EPOCH FROM (end_time - start_time)) * 1000;
        
        INSERT INTO results_exact VALUES (
            'exact_count',
            (SELECT COUNT(*) FROM benchmark_data),
            distinct_cnt,
            duration_ms,
            NULL,
            i
        );
        
        RAISE NOTICE 'Run %: Exact count = %, Duration = % ms', i, distinct_cnt, duration_ms;
    END LOOP;
END $$;

-- ============================================================
-- 3. HLL APPROXIMATE COUNT - Multiple Precisions
-- ============================================================

CREATE TABLE results_hll (
    test_name TEXT,
    precision INTEGER,
    row_count BIGINT,
    hll_estimate NUMERIC,
    exact_count BIGINT,
    relative_error NUMERIC,
    duration_ms NUMERIC,
    storage_bytes INTEGER,
    run_number INTEGER
);

-- Test HLL with precision 10, 12, 14
DO $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    duration_ms NUMERIC;
    hll_result hll;
    hll_estimate NUMERIC;
    exact_cnt BIGINT;
    prec INTEGER;
    i INTEGER;
    storage_size INTEGER;
BEGIN
    -- Get exact count once
    SELECT COUNT(DISTINCT user_id) INTO exact_cnt FROM benchmark_data;
    
    -- Test different precisions
    FOREACH prec IN ARRAY ARRAY[10, 12, 14] LOOP
        RAISE NOTICE 'Testing HLL with precision %', prec;
        
        -- Warmup
        SELECT hll_add_agg(hll_hash_integer(user_id), prec) 
        FROM benchmark_data INTO hll_result;
        
        -- Run 5 times
        FOR i IN 1..5 LOOP
            start_time := clock_timestamp();
            
            SELECT hll_add_agg(hll_hash_integer(user_id), prec) 
            INTO hll_result
            FROM benchmark_data;
            
            end_time := clock_timestamp();
            duration_ms := EXTRACT(EPOCH FROM (end_time - start_time)) * 1000;
            
            hll_estimate := hll_cardinality(hll_result);
            storage_size := octet_length(hll_result::bytea);
            
            INSERT INTO results_hll VALUES (
                'hll_precision_' || prec,
                prec,
                (SELECT COUNT(*) FROM benchmark_data),
                hll_estimate,
                exact_cnt,
                ABS(hll_estimate - exact_cnt) / exact_cnt * 100,
                duration_ms,
                storage_size,
                i
            );
            
            RAISE NOTICE 'Run %: HLL estimate = %, Error = %%, Duration = % ms', 
                i, hll_estimate, ABS(hll_estimate - exact_cnt) / exact_cnt * 100, duration_ms;
        END LOOP;
    END LOOP;
END $$;

-- ============================================================
-- 4. RESULTS SUMMARY
-- ============================================================

-- Exact count statistics
SELECT 
    'EXACT COUNT' as method,
    NULL as precision,
    AVG(distinct_count) as avg_count,
    AVG(duration_ms) as avg_duration_ms,
    STDDEV(duration_ms) as stddev_duration_ms
FROM results_exact
WHERE test_name = 'exact_count';

-- HLL statistics by precision
SELECT 
    'HLL' as method,
    precision,
    AVG(hll_estimate) as avg_estimate,
    AVG(relative_error) as avg_error_pct,
    AVG(duration_ms) as avg_duration_ms,
    STDDEV(duration_ms) as stddev_duration_ms,
    AVG(storage_bytes) as avg_storage_bytes
FROM results_hll
GROUP BY precision
ORDER BY precision;

-- Speed comparison
SELECT 
    'Speedup (Exact/HLL)' as metric,
    precision,
    (SELECT AVG(duration_ms) FROM results_exact) / AVG(duration_ms) as speedup_factor
FROM results_hll
GROUP BY precision
ORDER BY precision;

-- Export results for plotting (copy these)
\echo '=== EXACT COUNT RESULTS ==='
SELECT * FROM results_exact ORDER BY run_number;

\echo '=== HLL RESULTS ==='
SELECT * FROM results_hll ORDER BY precision, run_number;

-- Save to CSV (if you have file write permissions)
\copy results_exact TO '/tmp/results_exact.csv' CSV HEADER;
\copy results_hll TO '/tmp/results_hll.csv' CSV HEADER;