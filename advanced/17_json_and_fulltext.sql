-- =====================================================================
-- 17_json_and_fulltext.sql
-- JSONB manipulation and PostgreSQL full-text search — common needs for
-- a web app's flexible-attribute product catalog and search bar.
-- =====================================================================

-- 1) Containment query — products with color = red (uses idx_products_attributes_gin)
SELECT name, attributes FROM products WHERE attributes @> '{"color": "red"}';

-- 2) Extract a specific JSON field, with a fallback
SELECT name, (attributes ->> 'ram_gb')::INT AS ram_gb
FROM products
WHERE attributes ? 'ram_gb'
ORDER BY ram_gb DESC;

-- 3) Update a nested JSON field without rewriting the whole document
UPDATE products
SET attributes = jsonb_set(attributes, '{warranty_months}', '24', true)
WHERE product_id = 1;

-- 4) Merge/patch a JSON object (add or override multiple keys at once)
UPDATE customers
SET metadata = metadata || '{"newsletter": false, "last_campaign": "sept_2026"}'::jsonb
WHERE customer_id = 2;

-- 5) Remove a key from a JSON document
UPDATE customers
SET metadata = metadata - 'last_campaign'
WHERE customer_id = 2;

-- 6) Expand a JSON array/object into rows (jsonb_each / jsonb_array_elements)
SELECT p.name, kv.key, kv.value
FROM products p, jsonb_each_text(p.attributes) AS kv(key, value)
ORDER BY p.name, kv.key;

-- 7) Build JSON output directly from relational data (handy for an API layer)
SELECT jsonb_build_object(
    'order_id', o.order_id,
    'customer', c.full_name,
    'items', jsonb_agg(jsonb_build_object(
        'product', p.name,
        'quantity', oi.quantity,
        'unit_price', oi.unit_price
    ))
) AS order_json
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p ON p.product_id = oi.product_id
GROUP BY o.order_id, c.full_name;

-- 8) Full-text search — rank results by relevance (search_vector kept in
--    sync by trg_products_search_vector, see objects/12_triggers.sql)
SELECT
    name,
    ts_rank(search_vector, query) AS relevance
FROM products, plainto_tsquery('english', 'gaming laptop') AS query
WHERE search_vector @@ query
ORDER BY relevance DESC;

-- 9) Highlight matched terms in search results (useful for UI snippets)
SELECT
    name,
    ts_headline('english', description, plainto_tsquery('english', 'camera')) AS snippet
FROM products, plainto_tsquery('english', 'camera') AS query
WHERE search_vector @@ query;
