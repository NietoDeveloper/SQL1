-- =============================================================================
-- SQL MASTERY TEMPLATE - database/03_queries/01_core_queries.sql
-- Prerequisite: run 01_schema/01_create_database.sql and 01_schema/02_tables.sql first.
-- =============================================================================
SET search_path TO sql_mastery, public;

-- =============================================================================
-- 04. CORE QUERYING - filtering, sorting, joins
-- =============================================================================

-- Basic filter + sort
SELECT customer_id, full_name, country_code
FROM customers
WHERE country_code = 'US'
ORDER BY full_name ASC;

-- INNER JOIN: orders with customer names
SELECT o.order_id, c.full_name, o.status, o.total_amount
FROM orders o
INNER JOIN customers c ON c.customer_id = o.customer_id;

-- LEFT JOIN: every product, whether ordered or not
SELECT p.name, oi.quantity
FROM products p
LEFT JOIN order_items oi ON oi.product_id = p.product_id;

-- Self-join: category with its parent name
SELECT child.name AS category, parent.name AS parent_category
FROM categories child
LEFT JOIN categories parent ON parent.category_id = child.parent_id;

