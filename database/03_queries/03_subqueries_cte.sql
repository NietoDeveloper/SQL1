-- =============================================================================
-- SQL MASTERY TEMPLATE - database/03_queries/03_subqueries_cte.sql
-- Prerequisite: run 01_schema/01_create_database.sql and 01_schema/02_tables.sql first.
-- =============================================================================
SET search_path TO sql_mastery, public;

-- =============================================================================
-- 06. SUBQUERIES & COMMON TABLE EXPRESSIONS
-- =============================================================================

-- Correlated subquery: customers whose spend is above their country's average.
SELECT c.full_name, c.country_code
FROM customers c
WHERE (
    SELECT COALESCE(SUM(o.total_amount), 0)
    FROM orders o WHERE o.customer_id = c.customer_id
) > (
    SELECT AVG(order_totals.total)
    FROM (
        SELECT c2.country_code, COALESCE(SUM(o2.total_amount), 0) AS total
        FROM customers c2
        LEFT JOIN orders o2 ON o2.customer_id = c2.customer_id
        WHERE c2.country_code = c.country_code
        GROUP BY c2.customer_id, c2.country_code
    ) order_totals
    WHERE order_totals.country_code = c.country_code
);

-- Standard CTE: readable multi-step pipeline.
WITH order_totals AS (
    SELECT customer_id, SUM(total_amount) AS spend
    FROM orders
    GROUP BY customer_id
),
ranked_customers AS (
    SELECT customer_id, spend,
           RANK() OVER (ORDER BY spend DESC) AS spend_rank
    FROM order_totals
)
SELECT c.full_name, rc.spend, rc.spend_rank
FROM ranked_customers rc
JOIN customers c ON c.customer_id = rc.customer_id;

-- Recursive CTE: flatten the category tree into a materialized path.
WITH RECURSIVE category_tree AS (
    SELECT category_id, parent_id, name, name::TEXT AS path, 0 AS depth
    FROM categories
    WHERE parent_id IS NULL

    UNION ALL

    SELECT c.category_id, c.parent_id, c.name,
           ct.path || ' > ' || c.name, ct.depth + 1
    FROM categories c
    JOIN category_tree ct ON ct.category_id = c.parent_id
)
SELECT category_id, path, depth
FROM category_tree
ORDER BY path;

