<div align="center">

# 🗄️ SQL Mastery Template

### Advanced (Level 5) PostgreSQL — Schema · Indexing · Procedures · Security · Performance

<img src="https://readme-typing-svg.demolab.com?font=Fira+Code&size=18&pause=1000&color=00B4D8&center=true&vCenter=true&width=650&lines=17+production-grade+SQL+modules+in+one+repo;Schema+%E2%86%92+Indexing+%E2%86%92+Procedures+%E2%86%92+Security+%E2%86%92+Performance;PostgreSQL+14%2B+%7C+Idempotent+%7C+Zero+manual+edits" alt="Typing SVG" />

[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-14%2B-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](./LICENSE)
[![Status](https://img.shields.io/badge/Status-Production--Ready-brightgreen?style=for-the-badge)]()
[![Idempotent](https://img.shields.io/badge/Script-Idempotent-9B59B6?style=for-the-badge)]()

![Divider](https://capsule-render.vercel.app/api?type=rect&color=0:0F2027,100:2C5364&height=3&section=header)

</div>

> Technical. Robust. Secure. Fast. Runnable top to bottom on a scratch database with **zero manual edits**.
>
> A single, self-contained repository that demonstrates advanced PostgreSQL end-to-end — dropped into any project as an **auxiliary/reference database layer**: a web app, a backend service, or a teaching template.

<div align="center">

| 🐘 Dialect | 📦 Sections | 🔒 Security Model | ⚡ Ready For |
|:---:|:---:|:---:|:---:|
| PostgreSQL 14+ | 17 modules | Least-privilege + RLS | Demos · Migrations · Teaching |

</div>

---

## 📑 Table of Contents

- [🚀 Quick Start](#-quick-start)
- [🗂️ Folder Map](#️-folder-map)
- [📦 What's Inside](#-whats-inside)
- [🧭 Two Ways to Use This Repo](#-two-ways-to-use-this-repo)
- [🔌 Integrating With a Web App / System](#-integrating-with-a-web-app--system)
- [🔒 Security Model](#-security-model)
- [⚡ Performance Notes](#-performance-notes)
- [🧰 Requirements](#-requirements)
- [📄 License](#-license)
- [👤 Author](#-author)

---

## 🚀 Quick Start

```bash
# 1. Create a scratch database
createdb sql_mastery_demo

# 2. Option A — run everything as separate modules (recommended for real repos)
psql -U <user> -d sql_mastery_demo -f database/run_all.sql

# 2. Option B — run the single portable file (recommended for quick demos
#    or pasting into a GUI client like DBeaver / TablePlus / pgAdmin)
psql -U <user> -d sql_mastery_demo -f database/sql_mastery_template.sql
```

> ♻️ **Idempotent by design** — the script drops and recreates its own `sql_mastery` schema, so re-running it never conflicts with an existing application schema in the same database.

---

## 🗂️ Folder Map

```
sql-mastery-template/
├── README.md                          <- you are here
├── LICENSE                            <- MIT
└── database/
    ├── sql_mastery_template.sql       <- ★ single-file version (all 17 sections)
    ├── run_all.sql                    <- psql entry point, runs modules in order
    │
    ├── 01_schema/
    │   ├── 01_create_database.sql     <- schema bootstrap (run first)
    │   ├── 02_tables.sql              <- tables, types, domains, constraints
    │   └── 03_indexes.sql             <- B-tree, GIN, partial indexes
    │
    ├── 02_data/
    │   └── 01_seed_data.sql           <- sample rows + UPSERT pattern
    │
    ├── 03_queries/
    │   ├── 01_core_queries.sql        <- filtering, sorting, joins, self-join
    │   ├── 02_aggregation.sql         <- GROUP BY, HAVING, GROUPING SETS
    │   ├── 03_subqueries_cte.sql      <- correlated subqueries, CTE, recursive CTE
    │   ├── 04_window_functions.sql    <- ROW_NUMBER, RANK, LAG, running totals
    │   ├── 05_json.sql                <- JSONB querying and updates
    │   └── 06_full_text_search.sql    <- tsvector / tsquery ranking
    │
    ├── 04_procedures/
    │   ├── 01_procedures_functions.sql<- stored function + transactional procedure
    │   └── 02_triggers.sql            <- audit log trigger, search-vector sync trigger
    │
    ├── 05_views/
    │   └── 01_views.sql               <- regular view + materialized view
    │
    ├── 06_transactions/
    │   └── 01_transactions.sql        <- BEGIN/COMMIT, SAVEPOINT, isolation notes
    │
    ├── 07_security/
    │   └── 01_roles_rls.sql           <- least-privilege roles, row-level security
    │
    ├── 08_performance/
    │   └── 01_explain_tuning.sql      <- EXPLAIN ANALYZE + tuning checklist
    │
    └── 09_maintenance/
        ├── 01_error_handling.sql      <- exception handling patterns (plpgsql)
        └── 02_teardown.sql            <- optional cleanup (disabled by default)
```

---

## 📦 What's Inside

<div align="center">

| # | Topic | File(s) |
|:---:|---|---|
| 1 | DDL — tables, ENUM types, domains, constraints | `01_schema/02_tables.sql` |
| 2 | Indexing — B-tree, GIN, partial indexes | `01_schema/03_indexes.sql` |
| 3 | DML — seed data, `INSERT ... ON CONFLICT` upsert | `02_data/01_seed_data.sql` |
| 4 | Core querying — joins, self-joins, filtering | `03_queries/01_core_queries.sql` |
| 5 | Aggregation — `GROUP BY`, `HAVING`, `GROUPING SETS` | `03_queries/02_aggregation.sql` |
| 6 | Subqueries & CTEs — correlated, recursive | `03_queries/03_subqueries_cte.sql` |
| 7 | Window functions — `RANK`, `LAG`, running totals, `NTILE` | `03_queries/04_window_functions.sql` |
| 8 | Views & materialized views | `05_views/01_views.sql` |
| 9 | Stored functions & procedures with row locking | `04_procedures/01_procedures_functions.sql` |
| 10 | Triggers — audit log, auto-maintained search index | `04_procedures/02_triggers.sql` |
| 11 | Transactions — `SAVEPOINT`, rollback, isolation levels | `06_transactions/01_transactions.sql` |
| 12 | Security — least-privilege roles, Row-Level Security | `07_security/01_roles_rls.sql` |
| 13 | Performance — `EXPLAIN (ANALYZE, BUFFERS)`, tuning notes | `08_performance/01_explain_tuning.sql` |
| 14 | JSON/JSONB — querying and partial updates | `03_queries/05_json.sql` |
| 15 | Full-text search — `tsvector`/`tsquery` with ranking | `03_queries/06_full_text_search.sql` |
| 16 | Error handling — structured `plpgsql` exception blocks | `09_maintenance/01_error_handling.sql` |

</div>

---

## 🧭 Two Ways to Use This Repo

**A. As a modular repository** (`database/run_all.sql`)
Best when this becomes a living part of a codebase: each concern lives in its own file, is easy to diff/review, and can be wired into a migration tool (Flyway, Sqitch, node-pg-migrate, Prisma migrate, etc.) by simply numbering migrations after these files.

**B. As a single portable template** (`database/sql_mastery_template.sql`)
Best for demos, teaching, code review, or pasting into a GUI SQL client in one shot. Functionally identical to option A — same schema, same data, same objects.

---

## 🔌 Integrating With a Web App / System

This repo is designed to sit **beside** your primary application database as an auxiliary/reference schema, not to replace your existing migrations:

1. The entire template lives inside its own `sql_mastery` schema — it will never collide with tables in `public` or any other schema your app uses.
2. Point your app's read replica or a secondary connection string at the same database and set `search_path` to `sql_mastery` when you want to query these tables (e.g. for demos, sandboxing, or internal tooling).
3. To promote a piece of this template into production, copy the relevant file (e.g. `07_security/01_roles_rls.sql`) into your own migrations folder and adjust table/column names to match your domain.
4. For a Node/Express or similar backend, connect with `pg`, `Prisma`, or `Knex` as you normally would — nothing here is engine-specific beyond standard PostgreSQL.

---

## 🔒 Security Model

- **Least privilege**: `app_readonly` (SELECT only) and `app_readwrite` (SELECT/INSERT/UPDATE/DELETE + EXECUTE on procedures) roles are created with no login capability by default — grant login and a password only to the specific database users that need it.
- **Row-Level Security** is enabled on `orders`, scoped to `app.current_customer_id`, showing how to isolate tenant/customer data at the database layer instead of trusting application code alone.
- All dynamic values in procedures use bound parameters (`plpgsql` variables), avoiding string-concatenated SQL and the injection risk that comes with it.

---

## ⚡ Performance Notes

- Composite and partial indexes are chosen to match the actual `WHERE` clauses used in the query modules — see `08_performance/01_explain_tuning.sql` for the `EXPLAIN (ANALYZE, BUFFERS)` walkthrough.
- The materialized view (`mv_daily_sales`) shows how to precompute expensive aggregates for reporting instead of scanning `orders` on every request.
- `FOR UPDATE` row locking in `sp_place_order` prevents overselling under concurrent load without locking the whole table.

---

## 🧰 Requirements

- PostgreSQL 14 or later
- `psql` CLI (for `run_all.sql`) — or any SQL client for the single-file version

---

## 📄 License

Released under the [MIT License](./LICENSE).

---

<div align="center">

## 👤 Author

**Manuel Nieto**
Software Engineer · Full Stack · Architecture & Systems · Cloud & Digital Twins Specialist 🚀

[![GitHub](https://img.shields.io/badge/GitHub-NietoDeveloper-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/NietoDeveloper)
[![Portfolio](https://img.shields.io/badge/Portfolio-manuelnieto.netlify.app-2C5364?style=for-the-badge&logo=netlify&logoColor=white)](https://manuelnieto.netlify.app/)
[![Email](https://img.shields.io/badge/Email-Contact-D14836?style=for-the-badge&logo=microsoftoutlook&logoColor=white)](mailto:NietoSoftwareDeveloper@outlook.com)
[![Committers Top Colombia](https://img.shields.io/badge/Committers.top-%23S%2B_Colombia-00B4D8?style=for-the-badge)](https://committers.top/colombia#NietoDeveloper)

![Divider](https://capsule-render.vercel.app/api?type=rect&color=0:2C5364,100:0F2027&height=3&section=footer)

*"Building scalable systems with 100% discipline. Code that scales, architecture that lasts."*

</div>






