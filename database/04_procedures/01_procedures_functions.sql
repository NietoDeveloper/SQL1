-- =============================================================================
-- SQL MASTERY TEMPLATE - database/04_procedures/01_procedures_functions.sql
-- Prerequisite: run 01_schema/01_create_database.sql and 01_schema/02_tables.sql first.
-- =============================================================================
SET search_path TO sql_mastery, public;

-- =============================================================================
-- 09. STORED PROCEDURES & FUNCTIONS
-- =============================================================================

-- Function: compute loyalty discount based on lifetime value.
CREATE OR REPLACE FUNCTION fn_loyalty_discount(p_customer_id BIGINT)
RETURNS NUMERIC
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_lifetime_value NUMERIC;
    v_discount       NUMERIC;
BEGIN
    SELECT COALESCE(SUM(total_amount), 0) INTO v_lifetime_value
    FROM orders WHERE customer_id = p_customer_id;

    v_discount := CASE
        WHEN v_lifetime_value >= 1000 THEN 0.15
        WHEN v_lifetime_value >= 500  THEN 0.10
        WHEN v_lifetime_value >= 100  THEN 0.05
        ELSE 0
    END;

    RETURN v_discount;
END;
$$;

-- Procedure: place an order atomically (validates stock, decrements it,
-- inserts order + items, recomputes total). Demonstrates transactional
-- business logic living close to the data.
CREATE OR REPLACE PROCEDURE sp_place_order(
    p_customer_id BIGINT,
    p_product_id  BIGINT,
    p_quantity    INTEGER,
    INOUT p_order_id BIGINT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_price PRODUCTS.price%TYPE;
    v_stock PRODUCTS.stock_quantity%TYPE;
BEGIN
    SELECT price, stock_quantity INTO v_price, v_stock
    FROM products WHERE product_id = p_product_id
    FOR UPDATE;  -- row lock prevents race conditions on stock

    IF v_stock IS NULL THEN
        RAISE EXCEPTION 'Product % does not exist', p_product_id
            USING ERRCODE = 'foreign_key_violation';
    END IF;

    IF v_stock < p_quantity THEN
        RAISE EXCEPTION 'Insufficient stock for product %: requested %, available %',
            p_product_id, p_quantity, v_stock
            USING ERRCODE = 'check_violation';
    END IF;

    INSERT INTO orders (customer_id, status, total_amount)
    VALUES (p_customer_id, 'pending', v_price * p_quantity)
    RETURNING order_id INTO p_order_id;

    INSERT INTO order_items (order_id, product_id, quantity, unit_price)
    VALUES (p_order_id, p_product_id, p_quantity, v_price);

    UPDATE products SET stock_quantity = stock_quantity - p_quantity
    WHERE product_id = p_product_id;
END;
$$;

-- Example call:
-- CALL sp_place_order(p_customer_id => 2, p_product_id => 3, p_quantity => 1, p_order_id => NULL);

