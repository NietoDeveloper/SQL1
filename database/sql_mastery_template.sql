-- =============================================================================
--  SQL MASTERY TEMPLATE
--  Level: 5 (Advanced / Expert)
--  Dialect: PostgreSQL 14+  (portable notes included where syntax differs)
--  Purpose: Single self-contained, runnable file that showcases the full
--           breadth of SQL functionality. Designed to be attached as an
--           auxiliary/reference database to any web app or system.
--  License: MIT (see /LICENSE)
-- =============================================================================
--  HOW TO RUN
--  ----------
--  psql -U <user> -d <database> -f sql_mastery_template.sql
--
--  The script is idempotent: it drops and recreates its own schema, so it is
--  safe to run multiple times against a scratch/dev database.
-- =============================================================================
--  TABLE OF CONTENTS
--  -----------------
--  00. Safety switches & schema bootstrap
--  01. Data Definition Language (DDL)         - tables, constraints, types
--  02. Indexing strategy
--  03. Data Manipulation Language (DML)       - seed data, upsert
--  04. Core querying                          - filtering, sorting, joins
--  05. Aggregation & grouping
--  06. Subqueries & Common Table Expressions  - incl. recursive CTE
--  07. Window functions
--  08. Views & materialized views
--  09. Stored procedures & functions
--  10. Triggers & audit logging
--  11. Transactions & concurrency control
--  12. Security                               - roles, grants, row-level security
--  13. Performance                            - EXPLAIN, query tuning notes
--  14. JSON / semi-structured data
--  15. Full-text search
--  16. Error handling patterns
--  17. Cleanup / teardown (commented out by default)
-- =============================================================================


-- =============================================================================
-- 00. SAFETY SWITCHES & SCHEMA BOOTSTRAP
-- =============================================================================
-- Isolate everything in its own schema so this template never collides with
-- an existing application schema when attached as an auxiliary database.

DROP SCHEMA IF EXISTS sql_mastery CASCADE;
CREATE SCHEMA sql_mastery;
SET search_path TO sql_mastery, public;

-- =============================================================================
-- 01. DATA DEFINITION LANGUAGE (DDL)
-- =============================================================================
-- Custom types demonstrate ENUM and composite domain constraints.

CREATE TYPE order_status AS ENUM ('pending', 'paid', 'shipped', 'delivered', 'cancelled');

CREATE DOMAIN positive_numeric AS NUMERIC(12, 2)
    CHECK (VALUE >= 0);

-- Parent table: customers
CREATE TABLE customers (
    customer_id     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name       VARCHAR(120) NOT NULL,
    email           VARCHAR(160) NOT NULL,
    country_code    CHAR(2)      NOT NULL,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    metadata        JSONB        NOT NULL DEFAULT '{}'::jsonb,
    CONSTRAINT uq_customers_email UNIQUE (email),
    CONSTRAINT chk_country_code CHECK (country_code ~ '^[A-Z]{2}$')
);

-- Product catalog
CREATE TABLE products (
    product_id      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sku             VARCHAR(40)  NOT NULL,
    name            VARCHAR(160) NOT NULL,
    description     TEXT,
    price           positive_numeric NOT NULL,
    stock_quantity  INTEGER NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
    search_vector   TSVECTOR,
    CONSTRAINT uq_products_sku UNIQUE (sku)
);

-- Orders: parent/child relationship with ON DELETE behavior
CREATE TABLE orders (
    order_id        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id     BIGINT NOT NULL REFERENCES customers(customer_id) ON DELETE RESTRICT,
    status          order_status NOT NULL DEFAULT 'pending',
    placed_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    total_amount    positive_numeric NOT NULL DEFAULT 0
);

CREATE TABLE order_items (
    order_item_id   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id        BIGINT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id      BIGINT NOT NULL REFERENCES products(product_id) ON DELETE RESTRICT,
    quantity        INTEGER NOT NULL CHECK (quantity > 0),
    unit_price      positive_numeric NOT NULL,
    CONSTRAINT uq_order_product UNIQUE (order_id, product_id)
);

-- Self-referencing table: demonstrates hierarchical data (category tree)
CREATE TABLE categories (
    category_id     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    parent_id       BIGINT REFERENCES categories(category_id) ON DELETE CASCADE,
    name            VARCHAR(100) NOT NULL
);

-- Audit log table used by triggers (section 10)
CREATE TABLE audit_log (
    audit_id        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    table_name      TEXT NOT NULL,
    operation       TEXT NOT NULL,
    row_id          TEXT NOT NULL,
    changed_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    changed_by      TEXT NOT NULL DEFAULT current_user,
    old_data        JSONB,
    new_data        JSONB
);

-- =============================================================================
-- 02. INDEXING STRATEGY
-- =============================================================================
-- B-tree for equality/range lookups, GIN for JSONB and full-text search.

CREATE INDEX idx_orders_customer_id      ON orders (customer_id);
CREATE INDEX idx_orders_status_placed_at ON orders (status, placed_at DESC);
CREATE INDEX idx_order_items_order_id    ON order_items (order_id);
CREATE INDEX idx_customers_metadata_gin  ON customers USING GIN (metadata);
CREATE INDEX idx_products_search_gin     ON products USING GIN (search_vector);

-- Partial index: only index the "hot path" of unfulfilled orders.
CREATE INDEX idx_orders_pending_only ON orders (placed_at)
    WHERE status IN ('pending', 'paid');

-- =============================================================================
-- 03. DATA MANIPULATION LANGUAGE (DML) - SEED DATA
-- =============================================================================

INSERT INTO customers (full_name, email, country_code, metadata) VALUES
    ('Ada Lovelace',   'ada@example.com',   'GB', '{"tier": "gold"}'),
    ('Grace Hopper',   'grace@example.com', 'US', '{"tier": "platinum"}'),
    ('Alan Turing',    'alan@example.com',  'GB', '{"tier": "silver"}'),
    ('Katherine Johnson', 'katherine@example.com', 'US', '{"tier": "gold"}');

INSERT INTO categories (parent_id, name) VALUES
    (NULL, 'Electronics'),
    (NULL, 'Books');

INSERT INTO categories (parent_id, name) VALUES
    ((SELECT category_id FROM categories WHERE name = 'Electronics'), 'Laptops'),
    ((SELECT category_id FROM categories WHERE name = 'Electronics'), 'Accessories'),
    ((SELECT category_id FROM categories WHERE name = 'Books'), 'Fiction');

INSERT INTO products (sku, name, description, price, stock_quantity) VALUES
    ('SKU-001', 'Mechanical Keyboard', 'Tactile switches, RGB backlight', 89.99, 120),
    ('SKU-002', 'Wireless Mouse',       'Ergonomic, 2.4GHz receiver',      29.50, 300),
    ('SKU-003', 'Ultrawide Monitor',    '34-inch curved display',        449.00, 45),
    ('SKU-004', 'USB-C Hub',            '7-in-1 dock',                    39.90, 200);

-- Keep the full-text index in sync with seed data.
UPDATE products
SET search_vector = to_tsvector('english', name || ' ' || COALESCE(description, ''));

-- UPSERT pattern (INSERT ... ON CONFLICT): idempotent write.
INSERT INTO products (sku, name, description, price, stock_quantity)
VALUES ('SKU-001', 'Mechanical Keyboard', 'Tactile switches, RGB backlight', 94.99, 110)
ON CONFLICT (sku)
DO UPDATE SET price = EXCLUDED.price, stock_quantity = EXCLUDED.stock_quantity;

INSERT INTO orders (customer_id, status, total_amount)
SELECT customer_id, 'paid', 0 FROM customers WHERE email = 'ada@example.com';

INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT o.order_id, p.product_id, 2, p.price
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
JOIN products p ON p.sku = 'SKU-002'
WHERE c.email = 'ada@example.com';

-- Recompute order total from its line items.
UPDATE orders o
SET total_amount = sub.total
FROM (
    SELECT order_id, SUM(quantity * unit_price) AS total
    FROM order_items
    GROUP BY order_id
) sub
WHERE o.order_id = sub.order_id;

-- =============================================================================
-- 04. CORE QUERYING - filtering, sorting, joins
-- =============================================================================

-- Basic filter + sort
SELECT customer_id, full_name, country_code
FROM customers
WHERE country_code = 'US'
ORDER BY full_name ASC;

-- INNER JOIN: orders with customer names
SELECT o.order_id, c.full_name, o.status, o.total_amount
FROM orders o
INNER JOIN customers c ON c.customer_id = o.customer_id;

-- LEFT JOIN: every product, whether ordered or not
SELECT p.name, oi.quantity
FROM products p
LEFT JOIN order_items oi ON oi.product_id = p.product_id;

-- Self-join: category with its parent name
SELECT child.name AS category, parent.name AS parent_category
FROM categories child
LEFT JOIN categories parent ON parent.category_id = child.parent_id;

-- =============================================================================
-- 05. AGGREGATION & GROUPING
-- =============================================================================

SELECT c.customer_id, c.full_name, COUNT(o.order_id) AS order_count,
       COALESCE(SUM(o.total_amount), 0) AS lifetime_value
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.full_name
HAVING COUNT(o.order_id) >= 0
ORDER BY lifetime_value DESC;

-- GROUPING SETS: subtotal by country and grand total in one pass.
SELECT country_code, COUNT(*) AS customer_count
FROM customers
GROUP BY GROUPING SETS ((country_code), ());

-- =============================================================================
-- 06. SUBQUERIES & COMMON TABLE EXPRESSIONS
-- =============================================================================

-- Correlated subquery: customers whose spend is above their country's average.
SELECT c.full_name, c.country_code
FROM customers c
WHERE (
    SELECT COALESCE(SUM(o.total_amount), 0)
    FROM orders o WHERE o.customer_id = c.customer_id
) > (
    SELECT AVG(order_totals.total)
    FROM (
        SELECT c2.country_code, COALESCE(SUM(o2.total_amount), 0) AS total
        FROM customers c2
        LEFT JOIN orders o2 ON o2.customer_id = c2.customer_id
        WHERE c2.country_code = c.country_code
        GROUP BY c2.customer_id, c2.country_code
    ) order_totals
    WHERE order_totals.country_code = c.country_code
);

-- Standard CTE: readable multi-step pipeline.
WITH order_totals AS (
    SELECT customer_id, SUM(total_amount) AS spend
    FROM orders
    GROUP BY customer_id
),
ranked_customers AS (
    SELECT customer_id, spend,
           RANK() OVER (ORDER BY spend DESC) AS spend_rank
    FROM order_totals
)
SELECT c.full_name, rc.spend, rc.spend_rank
FROM ranked_customers rc
JOIN customers c ON c.customer_id = rc.customer_id;

-- Recursive CTE: flatten the category tree into a materialized path.
WITH RECURSIVE category_tree AS (
    SELECT category_id, parent_id, name, name::TEXT AS path, 0 AS depth
    FROM categories
    WHERE parent_id IS NULL

    UNION ALL

    SELECT c.category_id, c.parent_id, c.name,
           ct.path || ' > ' || c.name, ct.depth + 1
    FROM categories c
    JOIN category_tree ct ON ct.category_id = c.parent_id
)
SELECT category_id, path, depth
FROM category_tree
ORDER BY path;

-- =============================================================================
-- 07. WINDOW FUNCTIONS
-- =============================================================================

SELECT
    o.order_id,
    o.customer_id,
    o.total_amount,
    ROW_NUMBER() OVER (PARTITION BY o.customer_id ORDER BY o.placed_at) AS order_sequence,
    SUM(o.total_amount) OVER (PARTITION BY o.customer_id ORDER BY o.placed_at
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total,
    LAG(o.total_amount) OVER (PARTITION BY o.customer_id ORDER BY o.placed_at) AS previous_order_amount,
    NTILE(4) OVER (ORDER BY o.total_amount DESC) AS spend_quartile
FROM orders o;

-- =============================================================================
-- 08. VIEWS & MATERIALIZED VIEWS
-- =============================================================================

CREATE VIEW vw_customer_summary AS
SELECT
    c.customer_id,
    c.full_name,
    c.email,
    COUNT(o.order_id) AS total_orders,
    COALESCE(SUM(o.total_amount), 0) AS lifetime_value
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.full_name, c.email;

-- Materialized view: precomputed for expensive/reporting queries.
-- Refresh on a schedule (cron, pg_cron, or app job): REFRESH MATERIALIZED VIEW CONCURRENTLY.
CREATE MATERIALIZED VIEW mv_daily_sales AS
SELECT
    DATE_TRUNC('day', placed_at) AS sales_day,
    COUNT(*) AS order_count,
    SUM(total_amount) AS revenue
FROM orders
GROUP BY DATE_TRUNC('day', placed_at)
WITH DATA;

CREATE UNIQUE INDEX idx_mv_daily_sales_day ON mv_daily_sales (sales_day);

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

-- =============================================================================
-- 13. PERFORMANCE - EXPLAIN & tuning notes
-- =============================================================================
-- Always validate index usage with EXPLAIN (ANALYZE, BUFFERS) in real workloads.

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT o.order_id, c.full_name
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.status = 'paid';

-- Tuning notes:
--  * idx_orders_status_placed_at supports the WHERE + implicit ORDER BY above.
--  * Prefer covering indexes for read-heavy endpoints (INCLUDE columns).
--  * Use partial indexes (see section 02) to keep hot-path indexes small.
--  * VACUUM/ANALYZE regularly; enable autovacuum tuning for high-write tables.
--  * Avoid SELECT *; only project required columns to reduce I/O and network cost.

-- =============================================================================
-- 14. JSON / SEMI-STRUCTURED DATA
-- =============================================================================

-- Query inside JSONB, add/update keys immutably.
SELECT customer_id, full_name, metadata ->> 'tier' AS tier
FROM customers
WHERE metadata @> '{"tier": "gold"}';

UPDATE customers
SET metadata = jsonb_set(metadata, '{last_campaign}', '"autumn_sale"', true)
WHERE country_code = 'US';

-- Expand a JSON array into rows.
SELECT * FROM jsonb_array_elements('[{"a":1},{"a":2},{"a":3}]'::jsonb) AS elem;

-- =============================================================================
-- 15. FULL-TEXT SEARCH
-- =============================================================================

SELECT product_id, name, ts_rank(search_vector, query) AS rank
FROM products, to_tsquery('english', 'keyboard | monitor') AS query
WHERE search_vector @@ query
ORDER BY rank DESC;

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

-- =============================================================================
-- 17. CLEANUP / TEARDOWN (disabled by default - uncomment to reset)
-- =============================================================================
-- DROP SCHEMA sql_mastery CASCADE;
-- DROP ROLE IF EXISTS app_readonly;
-- DROP ROLE IF EXISTS app_readwrite;

-- =============================================================================
-- END OF FILE
-- =============================================================================
