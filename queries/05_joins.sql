-- =====================================================================
-- 05_joins.sql
-- INNER, LEFT, RIGHT, FULL, CROSS, and self joins.
-- =====================================================================

-- 1) INNER JOIN — orders with customer names
SELECT o.order_id, c.full_name, o.status, o.total_amount
FROM orders o
INNER JOIN customers c ON c.customer_id = o.customer_id
ORDER BY o.order_date DESC;

-- 2) LEFT JOIN — every product, even those never ordered
SELECT p.name, oi.order_id, oi.quantity
FROM products p
LEFT JOIN order_items oi ON oi.product_id = p.product_id
ORDER BY p.name;

-- 3) Multi-table JOIN — full order detail (order + customer + product + category)
SELECT
    o.order_id,
    c.full_name        AS customer,
    p.name              AS product,
    cat.name            AS category,
    oi.quantity,
    oi.unit_price,
    (oi.quantity * oi.unit_price)::NUMERIC(12,2) AS line_total
FROM orders o
JOIN customers c   ON c.customer_id = o.customer_id
JOIN order_items oi ON oi.order_id  = o.order_id
JOIN products p     ON p.product_id = oi.product_id
LEFT JOIN categories cat ON cat.category_id = p.category_id
ORDER BY o.order_id;

-- 4) FULL OUTER JOIN — reconcile customers vs. orders (find customers with no orders
--    and, hypothetically, orphaned orders)
SELECT c.customer_id, c.full_name, o.order_id
FROM customers c
FULL OUTER JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL OR c.customer_id IS NULL;

-- 5) Self JOIN — employees with their manager's name
SELECT e.full_name AS employee, m.full_name AS manager
FROM employees e
LEFT JOIN employees m ON m.employee_id = e.manager_id;

-- 6) CROSS JOIN — every product x every payment_method (e.g. building a report matrix)
SELECT p.name, pm.enum_val AS payment_option
FROM products p
CROSS JOIN (SELECT unnest(enum_range(NULL::payment_method)) AS enum_val) pm
LIMIT 12;

-- 7) Anti-join pattern with NOT EXISTS (preferred over NOT IN for NULL-safety)
SELECT c.customer_id, c.full_name
FROM customers c
WHERE NOT EXISTS (
    SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id
);
