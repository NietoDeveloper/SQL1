-- =============================================================================
-- SQL MASTERY TEMPLATE - database/01_schema/02_tables.sql
-- Prerequisite: run 01_schema/01_create_database.sql and 01_schema/02_tables.sql first.
-- =============================================================================
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

