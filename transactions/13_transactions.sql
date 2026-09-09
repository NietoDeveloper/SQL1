-- =====================================================================
-- 13_transactions.sql
-- Transactions, savepoints, isolation levels, and explicit locking.
-- =====================================================================

-- 1) Basic transaction — all-or-nothing transfer of loyalty points
BEGIN;

UPDATE customers SET loyalty_points = loyalty_points - 50 WHERE customer_id = 1;
UPDATE customers SET loyalty_points = loyalty_points + 50 WHERE customer_id = 2;

-- Sanity check before committing
SELECT customer_id, loyalty_points FROM customers WHERE customer_id IN (1, 2);

COMMIT;
-- If anything looked wrong above, use ROLLBACK; instead of COMMIT;

-- 2) SAVEPOINT — partial rollback within a larger transaction
BEGIN;

INSERT INTO categories (name, parent_id) VALUES ('Wearables', 1);
SAVEPOINT before_risky_step;

-- Simulate a step that might fail business validation
UPDATE products SET price = price * 1.10 WHERE category_id = 1;

-- Suppose we decide this pricing change was wrong: roll back only that part.
ROLLBACK TO SAVEPOINT before_risky_step;

-- The category insert above is still staged; commit just that.
COMMIT;

-- 3) Explicit row locking to prevent lost updates (pairs with sp_place_order)
BEGIN;
SELECT stock_quantity FROM products WHERE product_id = 1 FOR UPDATE;
-- ... application logic decides new stock level here ...
UPDATE products SET stock_quantity = stock_quantity - 1 WHERE product_id = 1;
COMMIT;

-- 4) Isolation levels — demonstrate an explicit REPEATABLE READ transaction
--    (prevents non-repeatable reads; still allows phantom reads to be
--    handled by SERIALIZABLE if needed for stricter guarantees)
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT SUM(total_amount) FROM orders WHERE status = 'delivered';
-- ... other work reading the same snapshot ...
COMMIT;

-- 5) SERIALIZABLE — strictest isolation for financial-style consistency;
--    application must retry on serialization_failure (SQLSTATE 40001).
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT * FROM products WHERE product_id = 1;
UPDATE products SET stock_quantity = stock_quantity - 1 WHERE product_id = 1;
COMMIT;
