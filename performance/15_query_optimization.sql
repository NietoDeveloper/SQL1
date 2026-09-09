-- =====================================================================
-- 15_query_optimization.sql
-- EXPLAIN / EXPLAIN ANALYZE usage, index verification, and rewrite
-- patterns that commonly speed up production queries.
-- =====================================================================

-- 1) Always inspect the plan before trusting a query at scale.
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT c.full_name, SUM(o.total_amount) AS spent
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.full_name
ORDER BY spent DESC;

-- 2) Confirm an index is actually used (look for "Index Scan" vs "Seq Scan").
EXPLAIN ANALYZE
SELECT * FROM orders WHERE customer_id = 1 ORDER BY order_date DESC;

-- 3) Anti-pattern: function wrapped around an indexed column defeats the index.
--    BAD:
--        SELECT * FROM customers WHERE LOWER(email) = 'manuel.rios@example.com';
--    GOOD (matches idx_customers_email_lower from 02_indexes.sql):
SELECT * FROM customers WHERE LOWER(email) = 'manuel.rios@example.com';

-- 4) Anti-pattern: SELECT * pulls unnecessary columns/TOAST data over the wire.
--    Prefer explicit column lists in application queries:
SELECT order_id, status, total_amount FROM orders WHERE customer_id = 1;

-- 5) Avoid N+1 queries — use a single JOIN/aggregation instead of looping
--    per-row in application code:
SELECT o.customer_id, COUNT(*) AS order_count, SUM(o.total_amount) AS total_spent
FROM orders o
GROUP BY o.customer_id;

-- 6) Use EXISTS instead of COUNT(*) > 0 when only presence matters
--    (stops scanning as soon as one match is found):
SELECT EXISTS (
    SELECT 1 FROM orders WHERE customer_id = 1 AND status = 'pending'
) AS has_pending_order;

-- 7) Keep planner statistics fresh after large data changes.
ANALYZE orders;
ANALYZE products;

-- 8) VACUUM guidance (run by autovacuum normally; manual example for batch jobs)
-- VACUUM (VERBOSE, ANALYZE) orders;

-- 9) pg_stat_statements-style check (requires the extension) to find your
--    slowest queries in a running system:
-- SELECT query, calls, total_exec_time, mean_exec_time
-- FROM pg_stat_statements
-- ORDER BY mean_exec_time DESC
-- LIMIT 10;
