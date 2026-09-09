-- =====================================================================
-- 02_indexes.sql
-- Indexing strategy: B-Tree, composite, partial, expression, and GIN
-- indexes for JSONB / full-text search.
-- =====================================================================

-- Foreign-key lookups are NOT auto-indexed by Postgres — add them.
CREATE INDEX idx_orders_customer_id      ON orders (customer_id);
CREATE INDEX idx_orders_employee_id      ON orders (employee_id);
CREATE INDEX idx_products_category_id    ON products (category_id);
CREATE INDEX idx_reviews_product_id      ON reviews (product_id);
CREATE INDEX idx_inventory_logs_product  ON inventory_logs (product_id);

-- Composite index supporting "orders by customer within a date range"
CREATE INDEX idx_orders_customer_date ON orders (customer_id, order_date DESC);

-- Partial index: only index the "active" hot subset (smaller, faster).
CREATE INDEX idx_orders_pending_processing
    ON orders (order_date)
    WHERE status IN ('pending', 'processing');

-- Expression index: case-insensitive email lookups without a functional scan.
CREATE INDEX idx_customers_email_lower ON customers (LOWER(email));

-- GIN index for JSONB containment queries: attributes @> '{"color":"red"}'
CREATE INDEX idx_products_attributes_gin ON products USING GIN (attributes);
CREATE INDEX idx_customers_metadata_gin  ON customers USING GIN (metadata);

-- Full-text search index (search_vector kept in sync by trigger, see 12_triggers.sql)
CREATE INDEX idx_products_search_vector ON products USING GIN (search_vector);

-- Unique index enforcing "one active SKU" even though sku is already UNIQUE
-- (kept here to demonstrate partial-unique pattern for soft-deleted rows).
-- CREATE UNIQUE INDEX uq_products_sku_active ON products (sku) WHERE NOT is_discontinued;
