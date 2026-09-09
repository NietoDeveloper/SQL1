-- =====================================================================
-- 06_subqueries_and_ctes.sql
-- Scalar/correlated subqueries, CTEs, and recursive CTEs.
-- =====================================================================

-- 1) Scalar subquery — products priced above the overall average
SELECT name, price
FROM products
WHERE price > (SELECT AVG(price) FROM products);

-- 2) Correlated subquery — each customer's most recent order date
SELECT
    c.full_name,
    (SELECT MAX(o.order_date) FROM orders o WHERE o.customer_id = c.customer_id) AS last_order
FROM customers c;

-- 3) CTE — readable multi-step report: revenue per customer
WITH customer_revenue AS (
    SELECT
        o.customer_id,
        SUM(oi.quantity * oi.unit_price) AS gross_revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.status NOT IN ('cancelled', 'refunded')
    GROUP BY o.customer_id
)
SELECT c.full_name, COALESCE(cr.gross_revenue, 0) AS gross_revenue
FROM customers c
LEFT JOIN customer_revenue cr ON cr.customer_id = c.customer_id
ORDER BY gross_revenue DESC;

-- 4) Multiple CTEs chained together
WITH paid_orders AS (
    SELECT * FROM orders WHERE status IN ('paid', 'shipped', 'delivered', 'processing')
),
order_totals AS (
    SELECT customer_id, SUM(total_amount) AS spent
    FROM paid_orders
    GROUP BY customer_id
)
SELECT c.full_name, ot.spent
FROM order_totals ot
JOIN customers c ON c.customer_id = ot.customer_id
ORDER BY ot.spent DESC;

-- 5) Recursive CTE — flatten the category tree with depth and full path
WITH RECURSIVE category_tree AS (
    -- anchor: top-level categories
    SELECT category_id, name, parent_id, 1 AS depth, name::TEXT AS path
    FROM categories
    WHERE parent_id IS NULL

    UNION ALL

    -- recursive step: children of the previous level
    SELECT c.category_id, c.name, c.parent_id, ct.depth + 1, ct.path || ' > ' || c.name
    FROM categories c
    JOIN category_tree ct ON c.parent_id = ct.category_id
)
SELECT category_id, depth, path
FROM category_tree
ORDER BY path;

-- 6) EXISTS vs IN — customers who reviewed at least one product they bought
SELECT DISTINCT c.full_name
FROM customers c
WHERE EXISTS (
    SELECT 1
    FROM reviews r
    JOIN order_items oi ON oi.product_id = r.product_id
    JOIN orders o ON o.order_id = oi.order_id AND o.customer_id = r.customer_id
    WHERE r.customer_id = c.customer_id
);
