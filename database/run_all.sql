-- =============================================================================
-- RUN ALL MODULES IN ORDER (psql only - uses \i meta-command)
-- Usage: psql -U <user> -d <database> -f database/run_all.sql
--
-- This is the "repository" entry point: it stitches together every modular
-- file under database/ in dependency order. If you only need a single
-- portable file (e.g. to paste into a GUI client), use
-- database/sql_mastery_template.sql instead - it contains identical content.
-- =============================================================================

\i database/01_schema/01_create_database.sql
\i database/01_schema/02_tables.sql
\i database/01_schema/03_indexes.sql
\i database/02_data/01_seed_data.sql
\i database/03_queries/01_core_queries.sql
\i database/03_queries/02_aggregation.sql
\i database/03_queries/03_subqueries_cte.sql
\i database/03_queries/04_window_functions.sql
\i database/03_queries/05_json.sql
\i database/03_queries/06_full_text_search.sql
\i database/04_procedures/01_procedures_functions.sql
\i database/04_procedures/02_triggers.sql
\i database/05_views/01_views.sql
\i database/06_transactions/01_transactions.sql
\i database/07_security/01_roles_rls.sql
\i database/08_performance/01_explain_tuning.sql
\i database/09_maintenance/01_error_handling.sql

-- Teardown (09_maintenance/02_teardown.sql) is intentionally NOT included here.
-- Run it manually only when you want to drop the schema.
