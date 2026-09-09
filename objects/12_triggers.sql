-- =====================================================================
-- 12_triggers.sql
-- BEFORE/AFTER triggers: auto-timestamps, full-text sync, generic audit
-- log, and stock-integrity enforcement.
-- =====================================================================

-- 1) Auto-update updated_at on customers and products (uses fn_set_updated_at)
DROP TRIGGER IF EXISTS trg_customers_updated_at ON customers;
CREATE TRIGGER trg_customers_updated_at
    BEFORE UPDATE ON customers
    FOR EACH ROW
    EXECUTE FUNCTION fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_products_updated_at ON products;
CREATE TRIGGER trg_products_updated_at
    BEFORE UPDATE ON products
    FOR EACH ROW
    EXECUTE FUNCTION fn_set_updated_at();

-- 2) Keep the full-text search_vector column in sync automatically
DROP TRIGGER IF EXISTS trg_products_search_vector ON products;
CREATE TRIGGER trg_products_search_vector
    BEFORE INSERT OR UPDATE OF name, description ON products
    FOR EACH ROW
    EXECUTE FUNCTION tsvector_update_trigger(search_vector, 'pg_catalog.english', name, description);

-- 3) Generic audit trigger — logs every INSERT/UPDATE/DELETE on `orders`
CREATE OR REPLACE FUNCTION fn_audit_orders()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        INSERT INTO audit_log (table_name, operation, row_pk, changed_data)
        VALUES ('orders', TG_OP, OLD.order_id::TEXT, to_jsonb(OLD));
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_log (table_name, operation, row_pk, changed_data)
        VALUES ('orders', TG_OP, NEW.order_id::TEXT,
                jsonb_build_object('old', to_jsonb(OLD), 'new', to_jsonb(NEW)));
        RETURN NEW;
    ELSE
        INSERT INTO audit_log (table_name, operation, row_pk, changed_data)
        VALUES ('orders', TG_OP, NEW.order_id::TEXT, to_jsonb(NEW));
        RETURN NEW;
    END IF;
END;
$$;

DROP TRIGGER IF EXISTS trg_orders_audit ON orders;
CREATE TRIGGER trg_orders_audit
    AFTER INSERT OR UPDATE OR DELETE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION fn_audit_orders();

-- 4) Data-integrity trigger — block negative stock at the database layer,
--    independent of any application logic (defense in depth).
CREATE OR REPLACE FUNCTION fn_prevent_negative_stock()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.stock_quantity < 0 THEN
        RAISE EXCEPTION 'Stock for product % cannot go negative (attempted %)',
            NEW.product_id, NEW.stock_quantity
            USING ERRCODE = 'check_violation';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_products_no_negative_stock ON products;
CREATE TRIGGER trg_products_no_negative_stock
    BEFORE UPDATE OF stock_quantity ON products
    FOR EACH ROW
    EXECUTE FUNCTION fn_prevent_negative_stock();
