-- =============================================================================
-- SQL MASTERY TEMPLATE - database/01_schema/03_indexes.sql
-- Prerequisite: run 01_schema/01_create_database.sql and 01_schema/02_tables.sql first.
-- =============================================================================
SET search_path TO sql_mastery, public;

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

