-- =============================================================================
-- SQL MASTERY TEMPLATE - database/03_queries/06_full_text_search.sql
-- Prerequisite: run 01_schema/01_create_database.sql and 01_schema/02_tables.sql first.
-- =============================================================================
SET search_path TO sql_mastery, public;

-- =============================================================================
-- 15. FULL-TEXT SEARCH
-- =============================================================================

SELECT product_id, name, ts_rank(search_vector, query) AS rank
FROM products, to_tsquery('english', 'keyboard | monitor') AS query
WHERE search_vector @@ query
ORDER BY rank DESC;

