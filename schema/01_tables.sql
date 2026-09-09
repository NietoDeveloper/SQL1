-- =====================================================================
-- 01_tables.sql
-- Level 5 SQL Demo Repository — Core Schema
-- Dialect: PostgreSQL 14+
-- Domain: "TechMart" — a small e-commerce auxiliary database
-- Purpose: demonstrate production-grade DDL (types, constraints,
--          relationships, defaults) that can be embedded as an
--          auxiliary/reference database inside a larger web app.
-- =====================================================================

-- Safe re-run: drop in dependency order (children first).
DROP TABLE IF EXISTS audit_log CASCADE;
DROP TABLE IF EXISTS inventory_logs CASCADE;
DROP TABLE IF EXISTS reviews CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS customers CASCADE;

DROP TYPE IF EXISTS order_status CASCADE;
DROP TYPE IF EXISTS payment_method CASCADE;

-- ---------------------------------------------------------------------
-- Enumerated types (stronger than free-text status columns)
-- ---------------------------------------------------------------------
CREATE TYPE order_status AS ENUM (
    'pending', 'paid', 'processing', 'shipped', 'delivered', 'cancelled', 'refunded'
);

CREATE TYPE payment_method AS ENUM (
    'credit_card', 'debit_card', 'paypal', 'bank_transfer', 'crypto'
);

-- ---------------------------------------------------------------------
-- customers
-- ---------------------------------------------------------------------
CREATE TABLE customers (
    customer_id     BIGSERIAL PRIMARY KEY,
    full_name       VARCHAR(120)  NOT NULL,
    email           VARCHAR(255)  NOT NULL,
    phone           VARCHAR(30),
    date_of_birth   DATE,
    loyalty_points  INTEGER       NOT NULL DEFAULT 0 CHECK (loyalty_points >= 0),
    metadata        JSONB         NOT NULL DEFAULT '{}'::jsonb,  -- flexible profile data
    is_active       BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ   NOT NULL DEFAULT now(),
    CONSTRAINT uq_customers_email UNIQUE (email),
    CONSTRAINT chk_customers_email_format CHECK (email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$')
);

-- ---------------------------------------------------------------------
-- employees (self-referencing hierarchy: manager_id -> employees)
-- ---------------------------------------------------------------------
CREATE TABLE employees (
    employee_id     SERIAL PRIMARY KEY,
    full_name       VARCHAR(120) NOT NULL,
    email           VARCHAR(255) NOT NULL UNIQUE,
    role            VARCHAR(60)  NOT NULL,
    manager_id      INTEGER      REFERENCES employees(employee_id) ON DELETE SET NULL,
    hired_at        DATE         NOT NULL DEFAULT CURRENT_DATE,
    salary          NUMERIC(12,2) NOT NULL CHECK (salary > 0)
);

-- ---------------------------------------------------------------------
-- categories (self-referencing tree for nested categories)
-- ---------------------------------------------------------------------
CREATE TABLE categories (
    category_id     SERIAL PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,
    parent_id       INTEGER REFERENCES categories(category_id) ON DELETE CASCADE,
    CONSTRAINT uq_categories_name_parent UNIQUE (name, parent_id)
);

-- ---------------------------------------------------------------------
-- products
-- ---------------------------------------------------------------------
CREATE TABLE products (
    product_id      BIGSERIAL PRIMARY KEY,
    sku             VARCHAR(40)   NOT NULL UNIQUE,
    name            VARCHAR(200)  NOT NULL,
    description     TEXT,
    category_id     INTEGER REFERENCES categories(category_id) ON DELETE SET NULL,
    price           NUMERIC(10,2) NOT NULL CHECK (price >= 0),
    stock_quantity  INTEGER       NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
    attributes      JSONB         NOT NULL DEFAULT '{}'::jsonb,  -- color, size, specs...
    search_vector   TSVECTOR,                                    -- full-text search index target
    is_discontinued BOOLEAN       NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ   NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- orders
-- ---------------------------------------------------------------------
CREATE TABLE orders (
    order_id        BIGSERIAL PRIMARY KEY,
    customer_id     BIGINT NOT NULL REFERENCES customers(customer_id) ON DELETE RESTRICT,
    employee_id     INTEGER REFERENCES employees(employee_id) ON DELETE SET NULL,
    status          order_status   NOT NULL DEFAULT 'pending',
    payment_method  payment_method,
    order_date      TIMESTAMPTZ    NOT NULL DEFAULT now(),
    shipped_date    TIMESTAMPTZ,
    total_amount    NUMERIC(12,2)  NOT NULL DEFAULT 0 CHECK (total_amount >= 0),
    CONSTRAINT chk_orders_shipped_after_order
        CHECK (shipped_date IS NULL OR shipped_date >= order_date)
);

-- ---------------------------------------------------------------------
-- order_items (composite PK, defensive numeric constraints)
-- ---------------------------------------------------------------------
CREATE TABLE order_items (
    order_id        BIGINT  NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id      BIGINT  NOT NULL REFERENCES products(product_id) ON DELETE RESTRICT,
    quantity        INTEGER NOT NULL CHECK (quantity > 0),
    unit_price      NUMERIC(10,2) NOT NULL CHECK (unit_price >= 0),
    discount_pct    NUMERIC(4,2)  NOT NULL DEFAULT 0 CHECK (discount_pct BETWEEN 0 AND 100),
    PRIMARY KEY (order_id, product_id)
);

-- ---------------------------------------------------------------------
-- reviews
-- ---------------------------------------------------------------------
CREATE TABLE reviews (
    review_id       BIGSERIAL PRIMARY KEY,
    product_id      BIGINT NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
    customer_id     BIGINT NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE,
    rating          SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment         TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_reviews_one_per_customer_product UNIQUE (product_id, customer_id)
);

-- ---------------------------------------------------------------------
-- inventory_logs (append-only audit of stock movements)
-- ---------------------------------------------------------------------
CREATE TABLE inventory_logs (
    log_id          BIGSERIAL PRIMARY KEY,
    product_id      BIGINT NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
    change_qty      INTEGER NOT NULL,               -- positive = restock, negative = sale
    reason          VARCHAR(60) NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- audit_log (generic trigger target, see objects/12_triggers.sql)
-- ---------------------------------------------------------------------
CREATE TABLE audit_log (
    audit_id        BIGSERIAL PRIMARY KEY,
    table_name      VARCHAR(60)  NOT NULL,
    operation       VARCHAR(10)  NOT NULL,
    row_pk          TEXT         NOT NULL,
    changed_data    JSONB,
    changed_by      TEXT         NOT NULL DEFAULT current_user,
    changed_at      TIMESTAMPTZ  NOT NULL DEFAULT now()
);
