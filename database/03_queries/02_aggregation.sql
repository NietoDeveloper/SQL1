-- =============================================================================
-- SQL MASTERY TEMPLATE - database/03_queries/02_aggregation.sql
-- Prerequisite: run 01_schema/01_create_database.sql and 01_schema/02_tables.sql first.
-- =============================================================================
SET search_path TO sql_mastery, public;

-- =============================================================================
-- 05. AGGREGATION & GROUPING
-- =============================================================================

SELECT c.customer_id, c.full_name, COUNT(o.order_id) AS order_count,
       COALESCE(SUM(o.total_amount), 0) AS lifetime_value
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.full_name
HAVING COUNT(o.order_id) >= 0
ORDER BY lifetime_value DESC;

-- GROUPING SETS: subtotal by country and grand total in one pass.
SELECT country_code, COUNT(*) AS customer_count
FROM customers
GROUP BY GROUPING SETS ((country_code), ());

