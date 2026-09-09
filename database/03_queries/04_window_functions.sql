-- =============================================================================
-- SQL MASTERY TEMPLATE - database/03_queries/04_window_functions.sql
-- Prerequisite: run 01_schema/01_create_database.sql and 01_schema/02_tables.sql first.
-- =============================================================================
SET search_path TO sql_mastery, public;

-- =============================================================================
-- 07. WINDOW FUNCTIONS
-- =============================================================================

SELECT
    o.order_id,
    o.customer_id,
    o.total_amount,
    ROW_NUMBER() OVER (PARTITION BY o.customer_id ORDER BY o.placed_at) AS order_sequence,
    SUM(o.total_amount) OVER (PARTITION BY o.customer_id ORDER BY o.placed_at
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total,
    LAG(o.total_amount) OVER (PARTITION BY o.customer_id ORDER BY o.placed_at) AS previous_order_amount,
    NTILE(4) OVER (ORDER BY o.total_amount DESC) AS spend_quartile
FROM orders o;

