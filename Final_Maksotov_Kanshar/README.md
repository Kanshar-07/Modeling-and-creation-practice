# Final Project — Online Shop

**Student:** Dias Yermekov  
**Domain:** Online Shop  
**Database:** `online_shop_db`  
**Schema:** `online_shop`

---

## Domain description

E-commerce platform where customers browse products by category, place orders with delivery to saved addresses, pay online, and apply discount coupons. The system tracks the full order lifecycle from placement to delivery.

---

## Files

| File | Description |
|------|-------------|
| `01_model_conceptual.png` | Conceptual ERD — entities and relationships with cardinality |
| `01_model_logical.png` | Logical model — all tables with columns, types, and constraints |
| `02_final.sql` | Full database script |
| `README.md` | This file |

---

## How to run

1. Connect to PostgreSQL as superuser:
   ```bash
   psql -U postgres
   ```
2. Run the script:
   ```bash
   \i 02_final.sql
   ```
3. Run it a second time to verify re-runnability — zero errors expected.

> The script creates the database and schema automatically if they do not exist.

---

## Schema overview

11 tables total, organized in 3NF:

| Table | Description |
|-------|-------------|
| `countries` | Reference table for country codes |
| `cities` | Cities linked to countries |
| `customers` | Registered customers |
| `addresses` | Shipping addresses per customer |
| `categories` | Product categories |
| `products` | Product catalog |
| `orders` | Customer orders |
| `order_items` | Bridge table: orders ↔ products (M:N) |
| `payments` | One payment per order (1:1) |
| `coupons` | Discount coupons |
| `customer_coupons` | Bridge table: customers ↔ coupons (M:N) |

---

## Design decisions

**3NF compliance**  
`city_name` and `country_name` are extracted into separate reference tables so no non-key column depends on another non-key column inside `customers` or `addresses`.

**M:N relationships**  
- `order_items` resolves the many-to-many between `orders` and `products`. It stores a price snapshot (`unit_price`) at the time of order and a `GENERATED` column `line_total`.  
- `customer_coupons` resolves the many-to-many between `customers` and `coupons`.

**GENERATED columns**  
- `customers.full_name` — generated from `first_name || ' ' || last_name`  
- `order_items.line_total` — generated from `quantity * unit_price`

**ON DELETE behaviour**  
- `CASCADE` — addresses cascade-delete with their customer; order items cascade-delete with their order  
- `RESTRICT` — orders, products, and payments are protected from accidental parent deletion

**ALTER TABLE evolution**  
Five different operations are used: `ADD COLUMN` (phone), `RENAME COLUMN` (stock_qty → quantity_in_stock), `ALTER COLUMN TYPE` (coupon_code widened to VARCHAR(50)), `SET DEFAULT` (orders.status), `DROP COLUMN` (orders.note).

**DELETE safety**  
The DELETE statement is wrapped in `BEGIN … ROLLBACK` so demo data is preserved for the defense session.

**Roles**  
- `online_shop_readonly` — analytics team, SELECT only  
- `online_shop_writer` — checkout service, INSERT on orders/payments; UPDATE revoked after security review
