-- =============================================================================
-- SQL MASTERY TEMPLATE - database/09_maintenance/01_error_handling.sql
-- Prerequisite: run 01_schema/01_create_database.sql and 01_schema/02_tables.sql first.
-- =============================================================================
SET search_path TO sql_mastery, public;

-- =============================================================================
-- 16. ERROR HANDLING PATTERNS
-- =============================================================================

DO $$
BEGIN
    BEGIN
        INSERT INTO order_items (order_id, product_id, quantity, unit_price)
        VALUES (999999, 1, 1, 10.00); -- invalid order_id on purpose
    EXCEPTION
        WHEN foreign_key_violation THEN
            RAISE NOTICE 'Handled expected FK violation: %', SQLERRM;
        WHEN OTHERS THEN
            RAISE NOTICE 'Unexpected error [%]: %', SQLSTATE, SQLERRM;
    END;
END;
$$;

