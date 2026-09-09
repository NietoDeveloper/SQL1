-- =============================================================================
-- SQL MASTERY TEMPLATE - database/04_procedures/02_triggers.sql
-- Prerequisite: run 01_schema/01_create_database.sql and 01_schema/02_tables.sql first.
-- =============================================================================
SET search_path TO sql_mastery, public;

-- =============================================================================
-- 10. TRIGGERS & AUDIT LOGGING
-- =============================================================================

CREATE OR REPLACE FUNCTION fn_audit_trigger()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        INSERT INTO audit_log (table_name, operation, row_id, old_data)
        VALUES (TG_TABLE_NAME, TG_OP, OLD.order_id::TEXT, to_jsonb(OLD));
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_log (table_name, operation, row_id, old_data, new_data)
        VALUES (TG_TABLE_NAME, TG_OP, NEW.order_id::TEXT, to_jsonb(OLD), to_jsonb(NEW));
        RETURN NEW;
    ELSE
        INSERT INTO audit_log (table_name, operation, row_id, new_data)
        VALUES (TG_TABLE_NAME, TG_OP, NEW.order_id::TEXT, to_jsonb(NEW));
        RETURN NEW;
    END IF;
END;
$$;

CREATE TRIGGER trg_orders_audit
AFTER INSERT OR UPDATE OR DELETE ON orders
FOR EACH ROW EXECUTE FUNCTION fn_audit_trigger();

-- Trigger: keep products.search_vector current automatically.
CREATE OR REPLACE FUNCTION fn_products_search_vector_update()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.search_vector := to_tsvector('english', NEW.name || ' ' || COALESCE(NEW.description, ''));
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_products_search_vector
BEFORE INSERT OR UPDATE ON products
FOR EACH ROW EXECUTE FUNCTION fn_products_search_vector_update();

