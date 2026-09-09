-- =====================================================================
-- 08_aggregation_grouping.sql
-- GROUP BY, HAVING, GROUPING SETS, ROLLUP, CUBE, FILTER clause.
-- =====================================================================

-- 1) Basic aggregation — revenue and order count per status
SELECT status, COUNT(*) AS order_count, SUM(total_amount) AS revenue
FROM orders
GROUP BY status
ORDER BY revenue DESC;

-- 2) HAVING — customers who have placed more than 1 order
SELECT customer_id, COUNT(*) AS order_count
FROM orders
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- 3) FILTER clause — conditional aggregates in a single pass (no CASE needed)
SELECT
    COUNT(*)                                   AS total_orders,
    COUNT(*) FILTER (WHERE status = 'delivered') AS delivered_orders,
    COUNT(*) FILTER (WHERE status = 'cancelled') AS cancelled_orders,
    SUM(total_amount) FILTER (WHERE status = 'delivered') AS delivered_revenue
FROM orders;

-- 4) GROUPING SETS — multiple grouping levels in one query
SELECT
    category_id,
    is_discontinued,
    COUNT(*) AS product_count,
    SUM(stock_quantity) AS total_stock
FROM products
GROUP BY GROUPING SETS (
    (category_id),
    (is_discontinued),
    ()                      -- grand total row
);

-- 5) ROLLUP — subtotals by category, then a grand total
SELECT
    COALESCE(c.name, 'ALL CATEGORIES') AS category,
    COUNT(p.product_id) AS product_count,
    SUM(p.stock_quantity) AS total_stock
FROM products p
LEFT JOIN categories c ON c.category_id = p.category_id
GROUP BY ROLLUP (c.name)
ORDER BY category;

-- 6) CUBE — every combination of the two dimensions
SELECT
    o.status,
    o.payment_method,
    COUNT(*) AS order_count
FROM orders o
GROUP BY CUBE (o.status, o.payment_method)
ORDER BY o.status, o.payment_method;

-- 7) Statistical aggregates
SELECT
    ROUND(AVG(rating), 2)               AS avg_rating,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY rating) AS median_rating,
    MODE() WITHIN GROUP (ORDER BY rating) AS most_common_rating,
    STDDEV(rating)                       AS rating_stddev
FROM reviews;
