-- =============================================================================
-- SQL MASTERY TEMPLATE - database/08_performance/01_explain_tuning.sql
-- Prerequisite: run 01_schema/01_create_database.sql and 01_schema/02_tables.sql first.
-- =============================================================================
SET search_path TO sql_mastery, public;

-- =============================================================================
-- 13. PERFORMANCE - EXPLAIN & tuning notes
-- =============================================================================
-- Always validate index usage with EXPLAIN (ANALYZE, BUFFERS) in real workloads.

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT o.order_id, c.full_name
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.status = 'paid';

-- Tuning notes:
--  * idx_orders_status_placed_at supports the WHERE + implicit ORDER BY above.
--  * Prefer covering indexes for read-heavy endpoints (INCLUDE columns).
--  * Use partial indexes (see section 02) to keep hot-path indexes small.
--  * VACUUM/ANALYZE regularly; enable autovacuum tuning for high-write tables.
--  * Avoid SELECT *; only project required columns to reduce I/O and network cost.

