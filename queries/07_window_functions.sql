-- =====================================================================
-- 07_window_functions.sql
-- ROW_NUMBER, RANK, DENSE_RANK, LAG/LEAD, running totals, NTILE.
-- =====================================================================

-- 1) Rank products by price within each category
SELECT
    p.name,
    c.name AS category,
    p.price,
    RANK()       OVER (PARTITION BY p.category_id ORDER BY p.price DESC) AS price_rank,
    DENSE_RANK() OVER (PARTITION BY p.category_id ORDER BY p.price DESC) AS dense_price_rank,
    ROW_NUMBER() OVER (PARTITION BY p.category_id ORDER BY p.price DESC) AS row_num
FROM products p
LEFT JOIN categories c ON c.category_id = p.category_id;

-- 2) Running total of revenue ordered by date
SELECT
    o.order_id,
    o.order_date,
    o.total_amount,
    SUM(o.total_amount) OVER (ORDER BY o.order_date
                               ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total
FROM orders o
ORDER BY o.order_date;

-- 3) LAG/LEAD — compare each order's total to the customer's previous order
SELECT
    customer_id,
    order_id,
    order_date,
    total_amount,
    LAG(total_amount)  OVER (PARTITION BY customer_id ORDER BY order_date) AS previous_order_total,
    LEAD(total_amount) OVER (PARTITION BY customer_id ORDER BY order_date) AS next_order_total,
    total_amount - LAG(total_amount) OVER (PARTITION BY customer_id ORDER BY order_date) AS delta
FROM orders
ORDER BY customer_id, order_date;

-- 4) NTILE — split products into 4 price quartile buckets
SELECT name, price, NTILE(4) OVER (ORDER BY price) AS price_quartile
FROM products;

-- 5) FIRST_VALUE / LAST_VALUE — cheapest and most expensive product per category
SELECT DISTINCT
    category_id,
    FIRST_VALUE(name) OVER w AS cheapest_in_category,
    LAST_VALUE(name)  OVER w AS priciest_in_category
FROM products
WINDOW w AS (
    PARTITION BY category_id
    ORDER BY price
    ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
);

-- 6) Moving average (3-order trailing window) on order totals
SELECT
    order_id,
    order_date,
    total_amount,
    ROUND(AVG(total_amount) OVER (ORDER BY order_date
                                   ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS moving_avg_3
FROM orders
ORDER BY order_date;
