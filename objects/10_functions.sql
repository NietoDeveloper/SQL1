-- =====================================================================
-- 10_functions.sql
-- PL/pgSQL user-defined functions: scalar, table-returning, and
-- security-definer patterns.
-- =====================================================================

-- 1) Scalar function — compute a customer's lifetime value
CREATE OR REPLACE FUNCTION fn_customer_lifetime_value(p_customer_id BIGINT)
RETURNS NUMERIC
LANGUAGE plpgsql
STABLE               -- promises no data modification; helps the planner
AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(total_amount), 0)
    INTO v_total
    FROM orders
    WHERE customer_id = p_customer_id
      AND status NOT IN ('cancelled', 'refunded');

    RETURN v_total;
END;
$$;

-- Usage: SELECT fn_customer_lifetime_value(1);

-- 2) Table-returning function — reusable "top N products" report with a parameter
CREATE OR REPLACE FUNCTION fn_top_selling_products(p_limit INTEGER DEFAULT 5)
RETURNS TABLE (
    product_id  BIGINT,
    name        VARCHAR,
    units_sold  BIGINT
)
LANGUAGE sql
STABLE
AS $$
    SELECT p.product_id, p.name, SUM(oi.quantity)::BIGINT AS units_sold
    FROM products p
    JOIN order_items oi ON oi.product_id = p.product_id
    GROUP BY p.product_id, p.name
    ORDER BY units_sold DESC
    LIMIT p_limit;
$$;

-- Usage: SELECT * FROM fn_top_selling_products(3);

-- 3) Function with input validation and a raised exception (defensive coding)
CREATE OR REPLACE FUNCTION fn_apply_discount(p_order_id BIGINT, p_percent NUMERIC)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_percent < 0 OR p_percent > 100 THEN
        RAISE EXCEPTION 'Invalid discount percent: % (must be 0-100)', p_percent
            USING ERRCODE = 'invalid_parameter_value';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM orders WHERE order_id = p_order_id) THEN
        RAISE EXCEPTION 'Order % does not exist', p_order_id
            USING ERRCODE = 'no_data_found';
    END IF;

    UPDATE order_items
    SET discount_pct = p_percent
    WHERE order_id = p_order_id;
END;
$$;

-- 4) Trigger-support function — keep updated_at fresh automatically
CREATE OR REPLACE FUNCTION fn_set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;
