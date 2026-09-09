-- =============================================================================
-- SQL MASTERY TEMPLATE - database/05_views/01_views.sql
-- Prerequisite: run 01_schema/01_create_database.sql and 01_schema/02_tables.sql first.
-- =============================================================================
SET search_path TO sql_mastery, public;

-- =============================================================================
-- 08. VIEWS & MATERIALIZED VIEWS
-- =============================================================================

CREATE VIEW vw_customer_summary AS
SELECT
    c.customer_id,
    c.full_name,
    c.email,
    COUNT(o.order_id) AS total_orders,
    COALESCE(SUM(o.total_amount), 0) AS lifetime_value
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.full_name, c.email;

-- Materialized view: precomputed for expensive/reporting queries.
-- Refresh on a schedule (cron, pg_cron, or app job): REFRESH MATERIALIZED VIEW CONCURRENTLY.
CREATE MATERIALIZED VIEW mv_daily_sales AS
SELECT
    DATE_TRUNC('day', placed_at) AS sales_day,
    COUNT(*) AS order_count,
    SUM(total_amount) AS revenue
FROM orders
GROUP BY DATE_TRUNC('day', placed_at)
WITH DATA;

CREATE UNIQUE INDEX idx_mv_daily_sales_day ON mv_daily_sales (sales_day);

