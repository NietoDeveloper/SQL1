-- =====================================================================
-- 03_seed_data.sql
-- Deterministic sample data so every query file below returns
-- meaningful, reproducible results.
-- =====================================================================

-- Categories (2-level tree)
INSERT INTO categories (category_id, name, parent_id) VALUES
    (1, 'Electronics', NULL),
    (2, 'Laptops', 1),
    (3, 'Smartphones', 1),
    (4, 'Home & Kitchen', NULL),
    (5, 'Small Appliances', 4);
SELECT setval('categories_category_id_seq', 5);

-- Employees (hierarchy: CEO -> Manager -> Reps)
INSERT INTO employees (employee_id, full_name, email, role, manager_id, hired_at, salary) VALUES
    (1, 'Laura Gomez',  'laura.gomez@techmart.com',  'CEO',            NULL, '2018-01-10', 12000),
    (2, 'Carlos Ruiz',  'carlos.ruiz@techmart.com',  'Sales Manager',  1,    '2019-03-15', 7500),
    (3, 'Ana Torres',   'ana.torres@techmart.com',   'Sales Rep',      2,    '2021-06-01', 3200),
    (4, 'Diego Perez',  'diego.perez@techmart.com',  'Sales Rep',      2,    '2022-02-20', 3100);
SELECT setval('employees_employee_id_seq', 4);

-- Customers
INSERT INTO customers (customer_id, full_name, email, phone, date_of_birth, loyalty_points, metadata) VALUES
    (1, 'Manuel Rios',    'manuel.rios@example.com',    '+57-300-1112233', '1994-05-12', 150, '{"tier":"gold","newsletter":true}'),
    (2, 'Sofia Martinez', 'sofia.martinez@example.com', '+57-301-2223344', '1990-11-02', 40,  '{"tier":"silver"}'),
    (3, 'Jorge Diaz',     'jorge.diaz@example.com',     '+57-302-3334455', '1988-07-23', 0,   '{"tier":"bronze"}'),
    (4, 'Elena Castro',   'elena.castro@example.com',   NULL,               '2001-01-30', 320, '{"tier":"platinum","newsletter":true}');
SELECT setval('customers_customer_id_seq', 4);

-- Products
INSERT INTO products (product_id, sku, name, description, category_id, price, stock_quantity, attributes) VALUES
    (1, 'LAP-001', 'UltraBook Pro 14',   'Lightweight 14" laptop, 16GB RAM, 512GB SSD', 2, 1299.99, 25, '{"color":"silver","ram_gb":16,"storage_gb":512}'),
    (2, 'LAP-002', 'GamerBeast 17',      'High-performance gaming laptop, RTX GPU',      2, 1899.00, 10, '{"color":"black","ram_gb":32,"storage_gb":1000}'),
    (3, 'PHN-001', 'NovaPhone X',        'Flagship smartphone with 108MP camera',        3, 899.50,  40, '{"color":"blue","ram_gb":8,"storage_gb":256}'),
    (4, 'PHN-002', 'NovaPhone Lite',     'Budget-friendly smartphone',                   3, 349.00,  60, '{"color":"white","ram_gb":4,"storage_gb":128}'),
    (5, 'APP-001', 'SpeedBlend 900',     'High-torque kitchen blender',                  5, 79.99,   100,'{"color":"red","watts":900}'),
    (6, 'APP-002', 'AirFry Max',         'Digital air fryer, 5.5L capacity',             5, 129.99,  15, '{"color":"black","capacity_l":5.5}');
SELECT setval('products_product_id_seq', 6);

-- Orders
INSERT INTO orders (order_id, customer_id, employee_id, status, payment_method, order_date, shipped_date, total_amount) VALUES
    (1, 1, 3, 'delivered', 'credit_card',   now() - INTERVAL '30 days', now() - INTERVAL '27 days', 1299.99),
    (2, 1, 3, 'shipped',   'paypal',        now() - INTERVAL '5 days',  now() - INTERVAL '2 days',  429.98),
    (3, 2, 4, 'pending',   NULL,            now() - INTERVAL '1 days',  NULL,                        899.50),
    (4, 3, 4, 'cancelled', 'debit_card',    now() - INTERVAL '10 days', NULL,                        129.99),
    (5, 4, 3, 'delivered', 'crypto',        now() - INTERVAL '60 days', now() - INTERVAL '55 days',  1899.00),
    (6, 4, 3, 'processing','credit_card',   now() - INTERVAL '2 days',  NULL,                        209.98);
SELECT setval('orders_order_id_seq', 6);

-- Order items
INSERT INTO order_items (order_id, product_id, quantity, unit_price, discount_pct) VALUES
    (1, 1, 1, 1299.99, 0),
    (2, 4, 1, 349.00,  0),
    (2, 5, 1, 79.99,   0),
    (3, 3, 1, 899.50,  0),
    (4, 6, 1, 129.99,  0),
    (5, 2, 1, 1899.00, 0),
    (6, 5, 1, 79.99,   0),
    (6, 6, 1, 129.99,  0);

-- Reviews
INSERT INTO reviews (product_id, customer_id, rating, comment) VALUES
    (1, 1, 5, 'Excellent build quality and battery life.'),
    (4, 1, 4, 'Good value for the price.'),
    (2, 4, 5, 'Runs every game I throw at it.'),
    (3, 2, 3, 'Camera is great but battery drains fast.'),
    (6, 3, 2, 'Stopped heating evenly after two months.');

-- Inventory movements
INSERT INTO inventory_logs (product_id, change_qty, reason) VALUES
    (1, 50, 'initial_stock'),
    (1, -1, 'order_sale'),
    (2, 15, 'initial_stock'),
    (2, -1, 'order_sale'),
    (5, 120, 'initial_stock'),
    (5, -2, 'order_sale');
