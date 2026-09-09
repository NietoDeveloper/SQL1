-- =====================================================================
-- 16_partitioning.sql
-- Declarative table partitioning for high-volume, time-series data
-- (e.g. an events / audit table growing millions of rows per month).
-- =====================================================================

-- 1) Range-partitioned table by month — ideal for append-heavy log data.
DROP TABLE IF EXISTS events CASCADE;
CREATE TABLE events (
    event_id    BIGSERIAL,
    customer_id BIGINT REFERENCES customers(customer_id),
    event_type  VARCHAR(50) NOT NULL,
    payload     JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (event_id, created_at)   -- partition key must be part of the PK
) PARTITION BY RANGE (created_at);

-- 2) Create monthly partitions (a job/migration would automate this rollover).
CREATE TABLE events_2026_08 PARTITION OF events
    FOR VALUES FROM ('2026-08-01') TO ('2026-09-01');

CREATE TABLE events_2026_09 PARTITION OF events
    FOR VALUES FROM ('2026-09-01') TO ('2026-10-01');

-- Catch-all default partition for anything outside defined ranges.
CREATE TABLE events_default PARTITION OF events DEFAULT;

-- 3) Indexes are defined per-partition automatically when created on the
--    parent (Postgres propagates them):
CREATE INDEX idx_events_customer_id ON events (customer_id);
CREATE INDEX idx_events_type        ON events (event_type);

-- 4) List partitioning example — split products by category group for
--    very large catalogs (thousands of categories, millions of SKUs).
-- CREATE TABLE products_partitioned (
--     LIKE products INCLUDING ALL
-- ) PARTITION BY LIST (category_id);

-- 5) Query the parent table normally — the planner prunes irrelevant
--    partitions automatically when the WHERE clause matches the key.
EXPLAIN ANALYZE
SELECT * FROM events
WHERE created_at >= '2026-09-01' AND created_at < '2026-09-08';

-- 6) Dropping an old partition is a near-instant metadata operation,
--    far cheaper than DELETE FROM events WHERE created_at < ...
-- DROP TABLE events_2026_08;
