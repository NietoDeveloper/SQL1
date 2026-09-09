-- =============================================================================
-- SQL MASTERY TEMPLATE - database/03_queries/05_json.sql
-- Prerequisite: run 01_schema/01_create_database.sql and 01_schema/02_tables.sql first.
-- =============================================================================
SET search_path TO sql_mastery, public;

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

