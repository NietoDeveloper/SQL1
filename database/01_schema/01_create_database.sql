-- =============================================================================
-- SQL MASTERY TEMPLATE - 01_schema/01_create_database.sql
-- Run this file FIRST. Creates the isolated schema used by every other file.
-- =============================================================================

-- =============================================================================
-- 00. SAFETY SWITCHES & SCHEMA BOOTSTRAP
-- =============================================================================
-- Isolate everything in its own schema so this template never collides with
-- an existing application schema when attached as an auxiliary database.

DROP SCHEMA IF EXISTS sql_mastery CASCADE;
CREATE SCHEMA sql_mastery;
SET search_path TO sql_mastery, public;

