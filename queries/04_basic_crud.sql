-- =====================================================================
-- 04_basic_crud.sql
-- SELECT / INSERT / UPDATE / DELETE fundamentals, with safe patterns.
-- =====================================================================

-- 1) Basic filtering, sorting, pagination
SELECT product_id, name, price, stock_quantity
FROM products
WHERE is_discontinued = FALSE
ORDER BY price DESC
LIMIT 5 OFFSET 0;

-- 2) Pattern matching (ILIKE = case-insensitive LIKE in Postgres)
SELECT name, sku FROM products WHERE name ILIKE '%phone%';

-- 3) UPSERT (idempotent insert) — safe to re-run without duplicate errors
INSERT INTO categories (name, parent_id)
VALUES ('Tablets', 1)
ON CONFLICT (name, parent_id) DO NOTHING
RETURNING category_id, name;

-- 4) Conditional UPDATE with RETURNING to see exactly what changed
UPDATE products
SET stock_quantity = stock_quantity - 1,
    updated_at = now()
WHERE product_id = 3
  AND stock_quantity > 0          -- guard against negative stock
RETURNING product_id, name, stock_quantity;

-- 5) Safe DELETE scoped by a narrow, indexed predicate (never DELETE without WHERE)
DELETE FROM reviews
WHERE review_id = -1;  -- placeholder id; replace with a real target in practice

-- 6) UPDATE ... FROM (correlated update across tables)
UPDATE orders o
SET total_amount = sub.computed_total
FROM (
    SELECT order_id, SUM(quantity * unit_price * (1 - discount_pct / 100.0)) AS computed_total
    FROM order_items
    GROUP BY order_id
) AS sub
WHERE o.order_id = sub.order_id;
