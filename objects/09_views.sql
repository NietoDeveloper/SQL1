-- =====================================================================
-- 09_views.sql
-- Regular views for encapsulation + a materialized view for
-- expensive aggregate reporting.
-- =====================================================================

-- 1) Regular view — flattened, app-friendly order detail
CREATE OR REPLACE VIEW vw_order_details AS
SELECT
    o.order_id,
    o.order_date,
    o.status,
    c.customer_id,
    c.full_name  AS customer_name,
    p.product_id,
    p.name       AS product_name,
    oi.quantity,
    oi.unit_price,
    (oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100.0))::NUMERIC(12,2) AS line_total
FROM orders o
JOIN customers c    ON c.customer_id = o.customer_id
JOIN order_items oi ON oi.order_id   = o.order_id
JOIN products p     ON p.product_id  = oi.product_id;

-- 2) Security-oriented view — hides PII, exposes only what a reporting
--    dashboard needs (pairs well with GRANT SELECT ON this view, see security/)
CREATE OR REPLACE VIEW vw_customer_public AS
SELECT
    customer_id,
    LEFT(full_name, 1) || '.' || SPLIT_PART(full_name, ' ', 2) AS display_name,
    loyalty_points,
    is_active
FROM customers;

-- 3) Materialized view — precomputed, expensive product performance report.
--    Refresh on a schedule (cron / job scheduler) rather than on every read.
DROP MATERIALIZED VIEW IF EXISTS mvw_product_performance;
CREATE MATERIALIZED VIEW mvw_product_performance AS
SELECT
    p.product_id,
    p.name,
    COALESCE(SUM(oi.quantity), 0)                    AS units_sold,
    COALESCE(SUM(oi.quantity * oi.unit_price), 0)     AS gross_revenue,
    COALESCE(ROUND(AVG(r.rating), 2), 0)              AS avg_rating,
    COUNT(DISTINCT r.review_id)                        AS review_count
FROM products p
LEFT JOIN order_items oi ON oi.product_id = p.product_id
LEFT JOIN reviews r      ON r.product_id  = p.product_id
GROUP BY p.product_id, p.name
WITH DATA;

-- A unique index is required for CONCURRENTLY refresh (no read-locking).
CREATE UNIQUE INDEX IF NOT EXISTS uq_mvw_product_performance_id
    ON mvw_product_performance (product_id);

-- Usage: REFRESH MATERIALIZED VIEW CONCURRENTLY mvw_product_performance;
