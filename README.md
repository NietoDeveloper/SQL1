This


# SQL Advanced Demo — Level 5 Reference Repository

A **self-contained, dialect-explicit SQL template repository** built to demonstrate
production-grade SQL features end to end — from schema design to security,
transactions, performance tuning, and full-text/JSON search. It's designed to
be dropped into a web app or system as an **auxiliary reference/practice
database**, or used standalone as a teaching/onboarding artifact.

- **Dialect:** PostgreSQL 14+ (all syntax is Postgres-specific; ports to other
  engines require adaptation — see [Portability Notes](#portability-notes)).
- **Domain:** `TechMart`, a small e-commerce dataset (customers, products,
  orders, reviews, inventory) — realistic enough to make every query
  meaningful, small enough to read in one sitting.
- **Level:** Advanced (L5) — window functions, recursive CTEs, triggers,
  stored procedures, transactions/isolation levels, RLS, partitioning,
  JSONB, and full-text search are all included with working examples.
- **Status:** Idempotent and re-runnable. Every DDL script can be executed
  repeatedly without manual cleanup (`DROP ... IF EXISTS`, `ON CONFLICT`,
  `CREATE OR REPLACE`).

---

## Folder Map

```
sql-advanced-demo/
├── 00_run_all.sql                     # Master script — builds everything in order
├── LICENSE                            # MIT
├── README.md                          # This file
├── .gitignore
│
├── schema/
│   ├── 01_tables.sql                  # Tables, enums, PK/FK, CHECK constraints
│   └── 02_indexes.sql                 # B-Tree, composite, partial, GIN, expression indexes
│
├── data/
│   └── 03_seed_data.sql               # Deterministic sample dataset
│
├── queries/
│   ├── 04_basic_crud.sql              # SELECT / INSERT / UPDATE / DELETE, UPSERT
│   ├── 05_joins.sql                   # INNER / LEFT / FULL / CROSS / self / anti-joins
│   ├── 06_subqueries_and_ctes.sql     # Scalar, correlated, CTEs, recursive CTE
│   ├── 07_window_functions.sql        # RANK, LAG/LEAD, running totals, NTILE
│   └── 08_aggregation_grouping.sql    # GROUP BY, HAVING, GROUPING SETS, ROLLUP, CUBE
│
├── objects/
│   ├── 09_views.sql                   # Views, security-oriented view, materialized view
│   ├── 10_functions.sql               # Scalar & table-returning PL/pgSQL functions
│   ├── 11_procedures.sql              # Transactional stored procedures (CALL)
│   └── 12_triggers.sql                # Audit log, timestamps, integrity enforcement
│
├── transactions/
│   └── 13_transactions.sql            # BEGIN/COMMIT, SAVEPOINT, isolation levels, locking
│
├── security/
│   └── 14_roles_and_permissions.sql   # Least-privilege roles, RLS, column-level GRANTs
│
├── performance/
│   ├── 15_query_optimization.sql      # EXPLAIN ANALYZE, index verification, anti-patterns
│   └── 16_partitioning.sql            # Range-partitioned tables for time-series data
│
└── advanced/
    └── 17_json_and_fulltext.sql       # JSONB operators, full-text search & ranking
```

---

## Quick Start

### 1. Create a database and run everything

```bash
createdb techmart_demo
psql -d techmart_demo -f 00_run_all.sql
```

`00_run_all.sql` builds the schema, indexes, seed data, views, functions,
procedures, and triggers in the correct dependency order. Everything else
under `queries/`, `transactions/`, `security/`, `performance/`, and
`advanced/` is meant to be opened and run **interactively**, statement by
statement — they're a guided tour, not a batch job.

### 2. Explore interactively

```bash
psql -d techmart_demo
```

```sql
\i queries/07_window_functions.sql
\i objects/09_views.sql
SELECT * FROM vw_order_details;
```

### 3. Try the transactional procedure

```sql
CALL sp_place_order(1, 5, 2, NULL);
SELECT * FROM mvw_product_performance;  -- refresh first if seed data changed
REFRESH MATERIALIZED VIEW CONCURRENTLY mvw_product_performance;
```

---

## What Each Folder Demonstrates

| Folder | Concepts Covered |
|---|---|
| `schema/` | Enums, `CHECK`/`UNIQUE`/`FK` constraints, self-referencing tables, JSONB columns, indexing strategy (B-Tree, partial, expression, GIN) |
| `data/` | Reproducible seed data so every downstream query returns real results |
| `queries/` | CRUD, all JOIN types, `NOT EXISTS` anti-joins, scalar/correlated subqueries, CTEs, **recursive CTEs** (category tree), window functions (`RANK`, `LAG`/`LEAD`, moving averages, `NTILE`), `GROUPING SETS`/`ROLLUP`/`CUBE`, `FILTER` clause, statistical aggregates |
| `objects/` | Views vs. materialized views, PII-safe reporting views, scalar & table-returning functions, atomic stored procedures with row locking (`FOR UPDATE`), triggers for audit logging and integrity enforcement |
| `transactions/` | `BEGIN`/`COMMIT`/`ROLLBACK`, `SAVEPOINT`, explicit row locks, `REPEATABLE READ` and `SERIALIZABLE` isolation levels |
| `security/` | Least-privilege role hierarchy, `GRANT`/`REVOKE`, column-level privileges, **Row-Level Security (RLS)** policies |
| `performance/` | `EXPLAIN (ANALYZE, BUFFERS)`, index-usage verification, common anti-patterns (function-wrapped predicates, `SELECT *`, N+1 queries), declarative **range partitioning** |
| `advanced/` | JSONB containment/merge/patch operators, `jsonb_agg`/`jsonb_build_object` for API-shaped output, full-text search with ranking and highlighted snippets |

---

## Using This as an Auxiliary Database in a Web App

This repository is intentionally decoupled from any framework, so it can be
attached to a project in any of these ways:

1. **Local dev/staging seed** — run `00_run_all.sql` against a disposable
   Postgres instance (Docker, RDS dev tier, Supabase, etc.) to get a
   realistic dataset for frontend/API development without touching
   production data.
2. **ORM reference** — use `schema/01_tables.sql` as the source of truth
   when hand-writing or reverse-engineering models for Prisma, Sequelize,
   TypeORM, SQLAlchemy, etc.
3. **Reporting/BI sidecar** — point a read-only connection (see the
   `techmart_readonly` role in `security/14_roles_and_permissions.sql`) at
   this schema for dashboards, using `vw_order_details` and
   `mvw_product_performance` directly.
4. **SQL training sandbox** — hand this repo to new team members as an
   onboarding exercise: each numbered file builds on the last.

### Docker one-liner

```bash
docker run --name techmart-pg -e POSTGRES_PASSWORD=postgres -p 5432:5432 -d postgres:16
psql -h localhost -U postgres -c "CREATE DATABASE techmart_demo;"
psql -h localhost -U postgres -d techmart_demo -f 00_run_all.sql
```

---

## Security Notes

- No real credentials are ever hard-coded. `security/14_roles_and_permissions.sql`
  shows commented-out `CREATE ROLE ... LOGIN PASSWORD` lines with the
  password left as a placeholder — inject real secrets via environment
  variables or a secrets manager at deploy time, never commit them.
- Application roles follow **least privilege**: `techmart_app` cannot
  `DELETE` or run DDL; only `techmart_admin` (reserved for
  migrations/CI) has full rights.
- `customers.email` is exposed to the app role, but a **sanitized view**
  (`vw_customer_public`) is what gets granted to reporting/read-only roles.
- **Row-Level Security** on `customers` ensures a compromised or
  misconfigured query cannot leak another customer's row, independent of
  application-layer bugs.
- All numeric/state constraints (`CHECK`, `ENUM`, `FOR UPDATE` locking,
  the negative-stock trigger) enforce integrity **at the database layer**,
  as defense in depth against application bugs.

## Performance Notes

- Every foreign key has a supporting index (Postgres does not create these
  automatically).
- Partial indexes keep hot-path indexes small (`idx_orders_pending_processing`).
- The materialized view (`mvw_product_performance`) offloads an expensive
  join+aggregate from the read path; refresh it on a schedule
  (`REFRESH MATERIALIZED VIEW CONCURRENTLY`) rather than computing it live.
- `performance/16_partitioning.sql` shows how to scale an append-only
  `events` table by month so old partitions can be dropped instantly
  instead of run through a slow `DELETE`.

## Portability Notes

This repo intentionally leans into **PostgreSQL-specific features**
(`JSONB`, `TSVECTOR`, `ENUM`, `GENERATED`/`RETURNING`, native partitioning,
`GROUPING SETS`) because they best demonstrate a modern, "level 5" SQL
skill set. If you need to port this to another engine:

- **MySQL 8+**: replace `JSONB` with `JSON`, drop native `ENUM` column
  syntax differences are minor, `RETURNING` is not supported pre-8.0.21
  (MySQL 8.0.21+ InnoDB does not support it either — use a follow-up
  `SELECT LAST_INSERT_ID()`), full-text search uses `FULLTEXT` indexes
  and `MATCH ... AGAINST` instead of `TSVECTOR`.
- **SQL Server**: use `NVARCHAR`, `IDENTITY` instead of `SERIAL`,
  `OUTPUT` instead of `RETURNING`, `TRY_CAST`/`THROW` instead of
  `RAISE EXCEPTION`.
- **SQLite**: no native `ENUM`, `RIGHT`/`FULL OUTER JOIN` support is
  limited pre-3.39, no stored procedures — best suited only for the
  `schema/` and `queries/` folders in simplified form.

---

## License

Released under the [MIT License](./LICENSE) — free to use, modify, and
redistribute in personal or commercial projects.
