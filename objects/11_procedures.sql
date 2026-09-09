-- =====================================================================
-- 11_procedures.sql
-- Stored PROCEDUREs (transactional units of work, callable with CALL).
-- Unlike functions, procedures may contain internal COMMIT/ROLLBACK.
-- =====================================================================

-- 1) Procedure — place an order atomically: validate stock, insert order +
--    items, decrement stock, log inventory movement. All-or-nothing.
CREATE OR REPLACE PROCEDURE sp_place_order(
    p_customer_id BIGINT,
    p_product_id  BIGINT,
    p_quantity    INTEGER,
    INOUT p_order_id BIGINT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_price     NUMERIC(10,2);
    v_stock     INTEGER;
BEGIN
    -- Lock the product row to prevent a race condition on concurrent orders.
    SELECT price, stock_quantity INTO v_price, v_stock
    FROM products
    WHERE product_id = p_product_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Product % not found', p_product_id;
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

    UPDATE products
    SET stock_quantity = stock_quantity - p_quantity
    WHERE product_id = p_product_id;

    INSERT INTO inventory_logs (product_id, change_qty, reason)
    VALUES (p_product_id, -p_quantity, 'order_sale');

    -- No explicit COMMIT here: keep the whole placement atomic with the
    -- caller's transaction. Call COMMIT inside only for long batch jobs.
END;
$$;

-- Usage:
-- CALL sp_place_order(1, 5, 2, NULL);

-- 2) Procedure — batch-cancel stale pending orders older than N days
CREATE OR REPLACE PROCEDURE sp_cancel_stale_orders(p_days_old INTEGER DEFAULT 14)
LANGUAGE plpgsql
AS $$
DECLARE
    v_cancelled_count INTEGER;
BEGIN
    UPDATE orders
    SET status = 'cancelled'
    WHERE status = 'pending'
      AND order_date < now() - (p_days_old || ' days')::INTERVAL;

    GET DIAGNOSTICS v_cancelled_count = ROW_COUNT;

    RAISE NOTICE 'Cancelled % stale order(s)', v_cancelled_count;
    COMMIT;  -- batch/maintenance procedures may commit independently
END;
$$;

-- Usage: CALL sp_cancel_stale_orders(14);
