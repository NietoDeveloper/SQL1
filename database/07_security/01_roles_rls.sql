-- =============================================================================
-- SQL MASTERY TEMPLATE - database/07_security/01_roles_rls.sql
-- Prerequisite: run 01_schema/01_create_database.sql and 01_schema/02_tables.sql first.
-- =============================================================================
SET search_path TO sql_mastery, public;

-- =============================================================================
-- 12. SECURITY - roles, grants, row-level security
-- =============================================================================
-- Principle of least privilege: separate read-only and read-write app roles.

DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'app_readonly') THEN
        CREATE ROLE app_readonly NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'app_readwrite') THEN
        CREATE ROLE app_readwrite NOLOGIN;
    END IF;
END;
$$;

GRANT USAGE ON SCHEMA sql_mastery TO app_readonly, app_readwrite;
GRANT SELECT ON ALL TABLES IN SCHEMA sql_mastery TO app_readonly;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA sql_mastery TO app_readwrite;
GRANT EXECUTE ON ALL PROCEDURES IN SCHEMA sql_mastery TO app_readwrite;

-- Row-Level Security: customers can only see their own orders.
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY orders_owner_only ON orders
    USING (customer_id = current_setting('app.current_customer_id', true)::BIGINT);

-- Application sets this per-connection/session before querying:
-- SET app.current_customer_id = '2';

