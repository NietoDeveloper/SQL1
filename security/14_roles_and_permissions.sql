-- =====================================================================
-- 14_roles_and_permissions.sql
-- Principle of least privilege: dedicated roles per application concern,
-- column/row-level security, and safe credential practices.
-- =====================================================================

-- 1) Create role hierarchy (NOLOGIN group roles + LOGIN app roles)
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'techmart_readonly') THEN
        CREATE ROLE techmart_readonly NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'techmart_app') THEN
        CREATE ROLE techmart_app NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'techmart_admin') THEN
        CREATE ROLE techmart_admin NOLOGIN;
    END IF;
END $$;

-- Login role used by the web app's connection pool. Replace the password
-- via an environment-injected secret at deploy time — never commit real
-- credentials to source control.
-- CREATE ROLE web_app_user LOGIN PASSWORD :'app_user_password';
-- GRANT techmart_app TO web_app_user;

-- 2) Read-only role — reporting dashboards, BI tools
GRANT CONNECT ON DATABASE current_database() TO techmart_readonly; -- run manually with real db name
GRANT USAGE ON SCHEMA public TO techmart_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO techmart_readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO techmart_readonly;

-- Reporting should use the sanitized view, not the raw customers table.
REVOKE SELECT ON customers FROM techmart_readonly;
GRANT SELECT ON vw_customer_public TO techmart_readonly;

-- 3) Application role — day-to-day CRUD, no DDL, no direct DELETE on audit_log
GRANT USAGE ON SCHEMA public TO techmart_app;
GRANT SELECT, INSERT, UPDATE ON customers, orders, order_items, reviews, products TO techmart_app;
GRANT SELECT, INSERT ON inventory_logs, audit_log TO techmart_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO techmart_app;
GRANT EXECUTE ON FUNCTION fn_customer_lifetime_value(BIGINT) TO techmart_app;
GRANT EXECUTE ON FUNCTION fn_top_selling_products(INTEGER) TO techmart_app;
GRANT EXECUTE ON PROCEDURE sp_place_order(BIGINT, BIGINT, INTEGER, BIGINT) TO techmart_app;
-- Notice: no DELETE grant, and no direct table DDL rights for techmart_app.

-- 4) Admin role — full control, used only by migration/CI pipelines
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO techmart_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO techmart_admin;

-- 5) Row-Level Security (RLS) — a customer-facing app connection can only
--    ever see its own row, even if a query is crafted incorrectly.
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;

CREATE POLICY customer_self_access ON customers
    USING (customer_id = current_setting('app.current_customer_id', true)::BIGINT);

-- Application sets this per-connection/per-request before running queries:
-- SET app.current_customer_id = '1';

-- 6) Column-level privilege example — hide `salary` from anyone but admins
REVOKE SELECT ON employees FROM techmart_app;
GRANT SELECT (employee_id, full_name, email, role, manager_id, hired_at) ON employees TO techmart_app;
GRANT SELECT ON employees TO techmart_admin;
