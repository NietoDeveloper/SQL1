-- =============================================================================
-- SQL MASTERY TEMPLATE - database/09_maintenance/02_teardown.sql
-- Prerequisite: run 01_schema/01_create_database.sql and 01_schema/02_tables.sql first.
-- =============================================================================
SET search_path TO sql_mastery, public;

-- =============================================================================
-- 17. CLEANUP / TEARDOWN (disabled by default - uncomment to reset)
-- =============================================================================
-- DROP SCHEMA sql_mastery CASCADE;
-- DROP ROLE IF EXISTS app_readonly;
-- DROP ROLE IF EXISTS app_readwrite;

-- =============================================================================
-- END OF FILE
