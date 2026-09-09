-- =====================================================================
-- 00_run_all.sql
-- Master entry point: builds the full demo database end to end.
-- Run with:  psql -d your_database -f 00_run_all.sql
-- =====================================================================

\echo 'Building schema...'
\i schema/01_tables.sql
\i schema/02_indexes.sql

\echo 'Loading seed data...'
\i data/03_seed_data.sql

\echo 'Creating views...'
\i objects/09_views.sql

\echo 'Creating functions...'
\i objects/10_functions.sql

\echo 'Creating procedures...'
\i objects/11_procedures.sql

\echo 'Creating triggers...'
\i objects/12_triggers.sql

\echo 'Setup complete. Explore queries/, transactions/, security/, performance/, and advanced/ interactively.'
