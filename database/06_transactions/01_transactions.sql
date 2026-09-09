-- =============================================================================
-- SQL MASTERY TEMPLATE - database/06_transactions/01_transactions.sql
-- Prerequisite: run 01_schema/01_create_database.sql and 01_schema/02_tables.sql first.
-- =============================================================================
SET search_path TO sql_mastery, public;

-- =============================================================================
-- 11. TRANSACTIONS & CONCURRENCY CONTROL
-- =============================================================================
-- Explicit transaction: fund transfer style pattern, fully atomic.

BEGIN;

SAVEPOINT before_transfer;

UPDATE products SET stock_quantity = stock_quantity - 5 WHERE sku = 'SKU-003';
UPDATE products SET stock_quantity = stock_quantity + 5 WHERE sku = 'SKU-004';

-- If a business rule is violated, roll back only to the savepoint.
DO $$
BEGIN
    IF (SELECT stock_quantity FROM products WHERE sku = 'SKU-003') < 0 THEN
        RAISE EXCEPTION 'Stock cannot go negative';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO SAVEPOINT before_transfer;
        RAISE NOTICE 'Transfer rolled back: %', SQLERRM;
END;
$$;

COMMIT;

-- Isolation level example for reporting reads that must not block writers.
-- SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

