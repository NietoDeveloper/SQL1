-- =============================================================================
-- SQL MASTERY TEMPLATE - database/02_data/01_seed_data.sql
-- Prerequisite: run 01_schema/01_create_database.sql and 01_schema/02_tables.sql first.
-- =============================================================================
SET search_path TO sql_mastery, public;

-- =============================================================================
-- 03. DATA MANIPULATION LANGUAGE (DML) - SEED DATA
-- =============================================================================

INSERT INTO customers (full_name, email, country_code, metadata) VALUES
    ('Ada Lovelace',   'ada@example.com',   'GB', '{"tier": "gold"}'),
    ('Grace Hopper',   'grace@example.com', 'US', '{"tier": "platinum"}'),
    ('Alan Turing',    'alan@example.com',  'GB', '{"tier": "silver"}'),
    ('Katherine Johnson', 'katherine@example.com', 'US', '{"tier": "gold"}');

INSERT INTO categories (parent_id, name) VALUES
    (NULL, 'Electronics'),
    (NULL, 'Books');

INSERT INTO categories (parent_id, name) VALUES
    ((SELECT category_id FROM categories WHERE name = 'Electronics'), 'Laptops'),
    ((SELECT category_id FROM categories WHERE name = 'Electronics'), 'Accessories'),
    ((SELECT category_id FROM categories WHERE name = 'Books'), 'Fiction');

INSERT INTO products (sku, name, description, price, stock_quantity) VALUES
    ('SKU-001', 'Mechanical Keyboard', 'Tactile switches, RGB backlight', 89.99, 120),
    ('SKU-002', 'Wireless Mouse',       'Ergonomic, 2.4GHz receiver',      29.50, 300),
    ('SKU-003', 'Ultrawide Monitor',    '34-inch curved display',        449.00, 45),
    ('SKU-004', 'USB-C Hub',            '7-in-1 dock',                    39.90, 200);

-- Keep the full-text index in sync with seed data.
UPDATE products
SET search_vector = to_tsvector('english', name || ' ' || COALESCE(description, ''));

-- UPSERT pattern (INSERT ... ON CONFLICT): idempotent write.
INSERT INTO products (sku, name, description, price, stock_quantity)
VALUES ('SKU-001', 'Mechanical Keyboard', 'Tactile switches, RGB backlight', 94.99, 110)
ON CONFLICT (sku)
DO UPDATE SET price = EXCLUDED.price, stock_quantity = EXCLUDED.stock_quantity;

INSERT INTO orders (customer_id, status, total_amount)
SELECT customer_id, 'paid', 0 FROM customers WHERE email = 'ada@example.com';

INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT o.order_id, p.product_id, 2, p.price
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
JOIN products p ON p.sku = 'SKU-002'
WHERE c.email = 'ada@example.com';

-- Recompute order total from its line items.
UPDATE orders o
SET total_amount = sub.total
FROM (
    SELECT order_id, SUM(quantity * unit_price) AS total
    FROM order_items
    GROUP BY order_id
) sub
WHERE o.order_id = sub.order_id;

