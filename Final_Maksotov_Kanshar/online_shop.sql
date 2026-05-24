DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_database WHERE datname = 'online_shop_db') THEN
        EXECUTE 'CREATE DATABASE online_shop_db';
    END IF;
END $$;

CREATE SCHEMA IF NOT EXISTS online_shop;

-- 2: CREATE TABLE
CREATE TABLE IF NOT EXISTS online_shop.countries (
    country_id   SERIAL PRIMARY KEY,
    country_code VARCHAR(3)   NOT NULL UNIQUE,
    country_name VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS online_shop.cities (
    city_id    SERIAL PRIMARY KEY,
    city_name  VARCHAR(100) NOT NULL,
    country_id INT NOT NULL REFERENCES online_shop.countries(country_id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS online_shop.customers (
    customer_id SERIAL PRIMARY KEY,
    email       VARCHAR(120) NOT NULL UNIQUE,                                          
    first_name  VARCHAR(80)  NOT NULL,
    last_name   VARCHAR(80)  NOT NULL,
    full_name   VARCHAR(162) GENERATED ALWAYS AS (first_name || ' ' || last_name) STORED,
    gender      VARCHAR(10)  NOT NULL,                                                 
    birth_date  DATE,
    created_at  TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS online_shop.addresses (
    address_id  SERIAL PRIMARY KEY,
    customer_id INT     NOT NULL REFERENCES online_shop.customers(customer_id) ON DELETE CASCADE,
    city_id     INT     NOT NULL REFERENCES online_shop.cities(city_id) ON DELETE RESTRICT,
    street      VARCHAR(200) NOT NULL,
    postal_code VARCHAR(20),
    is_default  BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS online_shop.categories (
    category_id   SERIAL PRIMARY KEY,
    category_name VARCHAR(80) NOT NULL UNIQUE,
    description   TEXT
);

CREATE TABLE IF NOT EXISTS online_shop.products (
    product_id   SERIAL PRIMARY KEY,
    sku          VARCHAR(50)   NOT NULL UNIQUE,
    product_name VARCHAR(200)  NOT NULL,
    category_id  INT           NOT NULL REFERENCES online_shop.categories(category_id) ON DELETE RESTRICT,
    unit_price   NUMERIC(12,2) NOT NULL,                                               
    stock_qty    INT           NOT NULL DEFAULT 0,
    is_active    BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMP     NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS online_shop.orders (
    order_id    SERIAL PRIMARY KEY,
    customer_id INT         NOT NULL REFERENCES online_shop.customers(customer_id) ON DELETE RESTRICT,
    address_id  INT         NOT NULL REFERENCES online_shop.addresses(address_id)  ON DELETE RESTRICT,
    order_date  DATE        NOT NULL,
    status      VARCHAR(20) NOT NULL DEFAULT 'pending',
    note        TEXT
);

-- Bridge table: orders ↔ products (M:N)
CREATE TABLE IF NOT EXISTS online_shop.order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id      INT           NOT NULL REFERENCES online_shop.orders(order_id)    ON DELETE CASCADE,
    product_id    INT           NOT NULL REFERENCES online_shop.products(product_id) ON DELETE RESTRICT,
    quantity      INT           NOT NULL,
    unit_price    NUMERIC(12,2) NOT NULL,
    line_total    NUMERIC(14,2) GENERATED ALWAYS AS (quantity * unit_price) STORED    
);

CREATE TABLE IF NOT EXISTS online_shop.payments (
    payment_id     SERIAL PRIMARY KEY,
    order_id       INT           NOT NULL UNIQUE REFERENCES online_shop.orders(order_id) ON DELETE RESTRICT,
    payment_date   DATE          NOT NULL,
    amount         NUMERIC(14,2) NOT NULL,
    payment_method VARCHAR(30)   NOT NULL,
    status         VARCHAR(20)   NOT NULL DEFAULT 'completed'
);

CREATE TABLE IF NOT EXISTS online_shop.coupons (
    coupon_id    SERIAL PRIMARY KEY,
    coupon_code  VARCHAR(30)  NOT NULL UNIQUE,
    discount_pct NUMERIC(5,2) NOT NULL,
    valid_from   DATE         NOT NULL,
    valid_until  DATE         NOT NULL,
    is_active    BOOLEAN      NOT NULL DEFAULT TRUE
);

-- Bridge table: customers ↔ coupons (M:N)
CREATE TABLE IF NOT EXISTS online_shop.customer_coupons (
    customer_coupon_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES online_shop.customers(customer_id) ON DELETE CASCADE,
    coupon_id   INT NOT NULL REFERENCES online_shop.coupons(coupon_id)    ON DELETE CASCADE,
    used_at     TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (customer_id, coupon_id)
);

-- 3: ALTER TABLE

-- Guard: reset all changes before restarting
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_customer_gender') THEN
        ALTER TABLE online_shop.customers DROP CONSTRAINT chk_customer_gender;
    END IF;
    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_order_date_2026') THEN
        ALTER TABLE online_shop.orders DROP CONSTRAINT chk_order_date_2026;
    END IF;
    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_product_price') THEN
        ALTER TABLE online_shop.products DROP CONSTRAINT chk_product_price;
    END IF;
    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_order_item_qty') THEN
        ALTER TABLE online_shop.order_items DROP CONSTRAINT chk_order_item_qty;
    END IF;
    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_coupon_discount') THEN
        ALTER TABLE online_shop.coupons DROP CONSTRAINT chk_coupon_discount;
    END IF;
    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_payment_method') THEN
        ALTER TABLE online_shop.payments DROP CONSTRAINT chk_payment_method;
    END IF;
    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_order_status') THEN
        ALTER TABLE online_shop.orders DROP CONSTRAINT chk_order_status;
    END IF;
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'online_shop' AND table_name = 'products' AND column_name = 'quantity_in_stock'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'online_shop' AND table_name = 'products' AND column_name = 'stock_qty'
    ) THEN
        ALTER TABLE online_shop.products RENAME COLUMN quantity_in_stock TO stock_qty;
    END IF;
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'online_shop' AND table_name = 'customers' AND column_name = 'phone'
    ) THEN
        ALTER TABLE online_shop.customers DROP COLUMN phone;
    END IF;
END $$;

-- ALTER 1: ADD COLUMN — Marketing requested a phone number for SMS notifications
ALTER TABLE online_shop.customers
    ADD COLUMN phone VARCHAR(25);

-- ALTER 2: RENAME COLUMN — 'stock_qty' too abbreviated, renamed for clarity
ALTER TABLE online_shop.products
    RENAME COLUMN stock_qty TO quantity_in_stock;

-- ALTER 3: ALTER COLUMN TYPE — Partner coupon codes can be up to 50 characters long.
ALTER TABLE online_shop.coupons
    ALTER COLUMN coupon_code TYPE VARCHAR(50);

-- ALTER 4: SET DEFAULT — We explicitly set the 'pending' status for new orders.
ALTER TABLE online_shop.orders
    ALTER COLUMN status SET DEFAULT 'pending';

-- ALTER 5: DROP COLUMN — 'note' has not been used by any service for 6 months
ALTER TABLE online_shop.orders
    DROP COLUMN IF EXISTS note;

-- ALTER 6: CHECK — gender only from acceptable values
ALTER TABLE online_shop.customers
    ADD CONSTRAINT chk_customer_gender CHECK (gender IN ('M', 'F', 'Other'));

-- ALTER 7: CHECK — order date after 2026-01-01 (system launched in 2026)
ALTER TABLE online_shop.orders
    ADD CONSTRAINT chk_order_date_2026 CHECK (order_date > DATE '2026-01-01');

-- ALTER 8: CHECK — the price of a product cannot be negative
ALTER TABLE online_shop.products
    ADD CONSTRAINT chk_product_price CHECK (unit_price >= 0);

-- ALTER 9: CHECK — the order quantity cannot be negative
ALTER TABLE online_shop.order_items
    ADD CONSTRAINT chk_order_item_qty CHECK (quantity >= 0);

-- ALTER 10: CHECK — coupon discount from 0 to 100%
ALTER TABLE online_shop.coupons
    ADD CONSTRAINT chk_coupon_discount CHECK (discount_pct BETWEEN 0 AND 100);

-- ALTER 11: CHECK — only connected payment methods
ALTER TABLE online_shop.payments
    ADD CONSTRAINT chk_payment_method CHECK (payment_method IN ('Card', 'Cash', 'Transfer'));

-- ALTER 12: CHECK — order status from the acceptable life cycle values
ALTER TABLE online_shop.orders
    ADD CONSTRAINT chk_order_status CHECK (status IN ('pending', 'paid', 'shipped', 'delivered', 'cancelled'));

-- 4: INSERT
TRUNCATE TABLE
    online_shop.customer_coupons,
    online_shop.payments,
    online_shop.order_items,
    online_shop.orders,
    online_shop.addresses,
    online_shop.products,
    online_shop.coupons,
    online_shop.customers,
    online_shop.categories,
    online_shop.cities,
    online_shop.countries
RESTART IDENTITY CASCADE;

-- COUNTRIES
INSERT INTO online_shop.countries (country_code, country_name) VALUES
    ('KZ', 'Kazakhstan'),
    ('RU', 'Russia'),
    ('US', 'United States'),
    ('DE', 'Germany');

-- CITIES
INSERT INTO online_shop.cities (city_name, country_id) VALUES
    ('Almaty',   (SELECT country_id FROM online_shop.countries WHERE country_code = 'KZ')),
    ('Astana',   (SELECT country_id FROM online_shop.countries WHERE country_code = 'KZ')),
    ('Shymkent', (SELECT country_id FROM online_shop.countries WHERE country_code = 'KZ')),
    ('Moscow',   (SELECT country_id FROM online_shop.countries WHERE country_code = 'RU')),
    ('New York', (SELECT country_id FROM online_shop.countries WHERE country_code = 'US')),
    ('Berlin',   (SELECT country_id FROM online_shop.countries WHERE country_code = 'DE'));

-- CUSTOMERS
INSERT INTO online_shop.customers (email, first_name, last_name, gender, birth_date) VALUES
    ('asel.nurlanovna@mail.kz', 'Asel',   'Nurlanovna', 'F', DATE '1995-03-14'),
    ('bekzat.omarov@gmail.com', 'Bekzat', 'Omarov',     'M', DATE '1990-07-22'),
    ('dana.seitkali@mail.kz',   'Dana',   'Seitkali',   'F', DATE '2001-11-05'),
    ('marat.dosanov@yandex.ru', 'Marat',  'Dosanov',    'M', DATE '1988-01-30'),
    ('zarina.bekova@gmail.com', 'Zarina', 'Bekova',     'F', DATE '1998-06-18'),
    ('arman.tuleev@mail.kz',    'Arman',  'Tuleev',     'M', DATE '1993-09-09');

-- ADDRESSES
INSERT INTO online_shop.addresses (customer_id, city_id, street, postal_code, is_default) VALUES
    (
        (SELECT customer_id FROM online_shop.customers WHERE email = 'asel.nurlanovna@mail.kz'),
        (SELECT city_id FROM online_shop.cities WHERE city_name = 'Almaty'),
        'ул. Абая 12, кв. 4', '050000', TRUE
    ),
    (
        (SELECT customer_id FROM online_shop.customers WHERE email = 'bekzat.omarov@gmail.com'),
        (SELECT city_id FROM online_shop.cities WHERE city_name = 'Astana'),
        'пр. Республики 55, кв. 18', '010000', TRUE
    ),
    (
        (SELECT customer_id FROM online_shop.customers WHERE email = 'dana.seitkali@mail.kz'),
        (SELECT city_id FROM online_shop.cities WHERE city_name = 'Shymkent'),
        'ул. Байтурсынова 3', '160000', TRUE
    ),
    (
        (SELECT customer_id FROM online_shop.customers WHERE email = 'marat.dosanov@yandex.ru'),
        (SELECT city_id FROM online_shop.cities WHERE city_name = 'Moscow'),
        'ул. Тверская 88', '125009', TRUE
    ),
    (
        (SELECT customer_id FROM online_shop.customers WHERE email = 'zarina.bekova@gmail.com'),
        (SELECT city_id FROM online_shop.cities WHERE city_name = 'Almaty'),
        'мкр. Алмагуль, д. 7', '050060', TRUE
    ),
    (
        (SELECT customer_id FROM online_shop.customers WHERE email = 'arman.tuleev@mail.kz'),
        (SELECT city_id FROM online_shop.cities WHERE city_name = 'Astana'),
        'ул. Кенесары 100, кв. 2', '010008', TRUE
    );

-- CATEGORIES
INSERT INTO online_shop.categories (category_name, description) VALUES
    ('Electronics',   'Phones, laptops, accessories'),
    ('Clothing',      'Apparel for men and women'),
    ('Books',         'Fiction, non-fiction, educational'),
    ('Home & Garden', 'Furniture, tools, decor'),
    ('Sports',        'Equipment and activewear');

-- PRODUCTS
INSERT INTO online_shop.products (sku, product_name, category_id, unit_price, quantity_in_stock) VALUES
    ('SKU-ELEC-001', 'Samsung Galaxy A54',
        (SELECT category_id FROM online_shop.categories WHERE category_name = 'Electronics'),
        149990.00, 25),
    ('SKU-ELEC-002', 'Apple AirPods Pro',
        (SELECT category_id FROM online_shop.categories WHERE category_name = 'Electronics'),
        89990.00, 40),
    ('SKU-CLTH-001', 'Adidas Running Jacket',
        (SELECT category_id FROM online_shop.categories WHERE category_name = 'Clothing'),
        24990.00, 60),
    ('SKU-CLTH-002', 'Nike Air Force 1',
        (SELECT category_id FROM online_shop.categories WHERE category_name = 'Clothing'),
        39990.00, 35),
    ('SKU-BOOK-001', 'Clean Code — Robert Martin',
        (SELECT category_id FROM online_shop.categories WHERE category_name = 'Books'),
        4990.00, 100),
    ('SKU-BOOK-002', 'SQL для чайников',
        (SELECT category_id FROM online_shop.categories WHERE category_name = 'Books'),
        3490.00, 80),
    ('SKU-HOME-001', 'Philips Air Purifier',
        (SELECT category_id FROM online_shop.categories WHERE category_name = 'Home & Garden'),
        54990.00, 15),
    ('SKU-SPRT-001', 'Decathlon Yoga Mat',
        (SELECT category_id FROM online_shop.categories WHERE category_name = 'Sports'),
        8990.00, 50);

-- ORDERS
INSERT INTO online_shop.orders (customer_id, address_id, order_date, status) VALUES
    (
        (SELECT customer_id FROM online_shop.customers WHERE email = 'asel.nurlanovna@mail.kz'),
        (SELECT address_id FROM online_shop.addresses
            WHERE customer_id = (SELECT customer_id FROM online_shop.customers WHERE email = 'asel.nurlanovna@mail.kz')
              AND is_default = TRUE),
        DATE '2026-02-10', 'delivered'
    ),
    (
        (SELECT customer_id FROM online_shop.customers WHERE email = 'bekzat.omarov@gmail.com'),
        (SELECT address_id FROM online_shop.addresses
            WHERE customer_id = (SELECT customer_id FROM online_shop.customers WHERE email = 'bekzat.omarov@gmail.com')
              AND is_default = TRUE),
        DATE '2026-03-01', 'shipped'
    ),
    (
        (SELECT customer_id FROM online_shop.customers WHERE email = 'dana.seitkali@mail.kz'),
        (SELECT address_id FROM online_shop.addresses
            WHERE customer_id = (SELECT customer_id FROM online_shop.customers WHERE email = 'dana.seitkali@mail.kz')
              AND is_default = TRUE),
        DATE '2026-03-15', 'paid'
    ),
    (
        (SELECT customer_id FROM online_shop.customers WHERE email = 'zarina.bekova@gmail.com'),
        (SELECT address_id FROM online_shop.addresses
            WHERE customer_id = (SELECT customer_id FROM online_shop.customers WHERE email = 'zarina.bekova@gmail.com')
              AND is_default = TRUE),
        DATE '2026-04-02', 'pending'
    ),
    (
        (SELECT customer_id FROM online_shop.customers WHERE email = 'arman.tuleev@mail.kz'),
        (SELECT address_id FROM online_shop.addresses
            WHERE customer_id = (SELECT customer_id FROM online_shop.customers WHERE email = 'arman.tuleev@mail.kz')
              AND is_default = TRUE),
        DATE '2026-04-10', 'cancelled'
    ),
    (
        (SELECT customer_id FROM online_shop.customers WHERE email = 'marat.dosanov@yandex.ru'),
        (SELECT address_id FROM online_shop.addresses
            WHERE customer_id = (SELECT customer_id FROM online_shop.customers WHERE email = 'marat.dosanov@yandex.ru')
              AND is_default = TRUE),
        DATE '2026-05-01', 'delivered'
    );

-- ORDER_ITEMS — INSERT … SELECT (bridge table, FK via natural keys)
INSERT INTO online_shop.order_items (order_id, product_id, quantity, unit_price)
SELECT o.order_id, p.product_id, x.qty, p.unit_price
FROM (VALUES
    ('asel.nurlanovna@mail.kz',  DATE '2026-02-10', 'SKU-ELEC-001', 1),
    ('asel.nurlanovna@mail.kz',  DATE '2026-02-10', 'SKU-BOOK-001', 2),
    ('bekzat.omarov@gmail.com',  DATE '2026-03-01', 'SKU-ELEC-002', 1),
    ('bekzat.omarov@gmail.com',  DATE '2026-03-01', 'SKU-CLTH-002', 1),
    ('dana.seitkali@mail.kz',    DATE '2026-03-15', 'SKU-CLTH-001', 2),
    ('dana.seitkali@mail.kz',    DATE '2026-03-15', 'SKU-SPRT-001', 1),
    ('zarina.bekova@gmail.com',  DATE '2026-04-02', 'SKU-HOME-001', 1),
    ('arman.tuleev@mail.kz',     DATE '2026-04-10', 'SKU-BOOK-002', 3),
    ('marat.dosanov@yandex.ru',  DATE '2026-05-01', 'SKU-ELEC-001', 1),
    ('marat.dosanov@yandex.ru',  DATE '2026-05-01', 'SKU-SPRT-001', 2)
) AS x(email, ord_date, sku, qty)
JOIN online_shop.customers c ON c.email = x.email
JOIN online_shop.orders    o ON o.customer_id = c.customer_id AND o.order_date = x.ord_date
JOIN online_shop.products  p ON p.sku = x.sku;

-- PAYMENTS
INSERT INTO online_shop.payments (order_id, payment_date, amount, payment_method, status) VALUES
    (
        (SELECT o.order_id FROM online_shop.orders o
            JOIN online_shop.customers c ON c.customer_id = o.customer_id
            WHERE c.email = 'asel.nurlanovna@mail.kz' AND o.order_date = DATE '2026-02-10'),
        DATE '2026-02-10', 159970.00, 'Card', 'completed'
    ),
    (
        (SELECT o.order_id FROM online_shop.orders o
            JOIN online_shop.customers c ON c.customer_id = o.customer_id
            WHERE c.email = 'bekzat.omarov@gmail.com' AND o.order_date = DATE '2026-03-01'),
        DATE '2026-03-01', 129980.00, 'Card', 'completed'
    ),
    (
        (SELECT o.order_id FROM online_shop.orders o
            JOIN online_shop.customers c ON c.customer_id = o.customer_id
            WHERE c.email = 'dana.seitkali@mail.kz' AND o.order_date = DATE '2026-03-15'),
        DATE '2026-03-15', 58970.00, 'Transfer', 'completed'
    ),
    (
        (SELECT o.order_id FROM online_shop.orders o
            JOIN online_shop.customers c ON c.customer_id = o.customer_id
            WHERE c.email = 'marat.dosanov@yandex.ru' AND o.order_date = DATE '2026-05-01'),
        DATE '2026-05-01', 167970.00, 'Cash', 'completed'
    );

-- COUPONS
INSERT INTO online_shop.coupons (coupon_code, discount_pct, valid_from, valid_until) VALUES
    ('SUMMER10',  10.00, DATE '2026-06-01', DATE '2026-08-31'),
    ('WELCOME5',   5.00, DATE '2026-01-01', DATE '2026-12-31'),
    ('FLASH20',   20.00, DATE '2026-04-01', DATE '2026-04-30'),
    ('LOYALTY15', 15.00, DATE '2026-03-01', DATE '2026-09-30');

-- CUSTOMER_COUPONS (M:N bridge: customers ↔ coupons)
INSERT INTO online_shop.customer_coupons (customer_id, coupon_id) VALUES
    (
        (SELECT customer_id FROM online_shop.customers WHERE email = 'asel.nurlanovna@mail.kz'),
        (SELECT coupon_id FROM online_shop.coupons WHERE coupon_code = 'WELCOME5')
    ),
    (
        (SELECT customer_id FROM online_shop.customers WHERE email = 'bekzat.omarov@gmail.com'),
        (SELECT coupon_id FROM online_shop.coupons WHERE coupon_code = 'SUMMER10')
    ),
    (
        (SELECT customer_id FROM online_shop.customers WHERE email = 'dana.seitkali@mail.kz'),
        (SELECT coupon_id FROM online_shop.coupons WHERE coupon_code = 'FLASH20')
    ),
    (
        (SELECT customer_id FROM online_shop.customers WHERE email = 'zarina.bekova@gmail.com'),
        (SELECT coupon_id FROM online_shop.coupons WHERE coupon_code = 'LOYALTY15')
    ),
    (
        (SELECT customer_id FROM online_shop.customers WHERE email = 'arman.tuleev@mail.kz'),
        (SELECT coupon_id FROM online_shop.coupons WHERE coupon_code = 'WELCOME5')
    ),
    (
        (SELECT customer_id FROM online_shop.customers WHERE email = 'marat.dosanov@yandex.ru'),
        (SELECT coupon_id FROM online_shop.coupons WHERE coupon_code = 'LOYALTY15')
    );

-- 5: UPDATE
-- -- Deactivate expired coupons
UPDATE online_shop.coupons
SET is_active = FALSE
WHERE valid_until < CURRENT_DATE;

-- We recalculate payment amounts from actual order lines (UPDATE … FROM)
UPDATE online_shop.payments p
SET amount = sub.recalculated_total
FROM (
    SELECT order_id, SUM(line_total) AS recalculated_total
    FROM online_shop.order_items
    GROUP BY order_id
) sub
WHERE p.order_id = sub.order_id;

-- 5: DELETE

-- Delete cancelled orders older than 30 days; ROLLBACK stores data for security purposes
BEGIN;
    DELETE FROM online_shop.orders
    WHERE status = 'cancelled'
      AND order_date < CURRENT_DATE - INTERVAL '30 days'
    RETURNING order_id, customer_id, order_date, status;
ROLLBACK;

-- 6: GRANT / REVOKE
DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'online_shop_readonly') THEN
        REASSIGN OWNED BY online_shop_readonly TO CURRENT_USER;
        DROP OWNED BY online_shop_readonly;
        DROP ROLE online_shop_readonly;
    END IF;
    IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'online_shop_writer') THEN
        REASSIGN OWNED BY online_shop_writer TO CURRENT_USER;
        DROP OWNED BY online_shop_writer;
        DROP ROLE online_shop_writer;
    END IF;
END $$;

CREATE ROLE online_shop_readonly;
CREATE ROLE online_shop_writer;

GRANT USAGE ON SCHEMA online_shop TO online_shop_readonly, online_shop_writer;

-- Analysts: read only
GRANT SELECT ON ALL TABLES IN SCHEMA online_shop TO online_shop_readonly;

-- Order processing service: inserting orders and payments
GRANT INSERT, UPDATE ON online_shop.orders     TO online_shop_writer;
GRANT INSERT         ON online_shop.order_items TO online_shop_writer;
GRANT INSERT         ON online_shop.payments    TO online_shop_writer;

-- After security audit: UPDATE orders only through a separate service with logging
REVOKE UPDATE ON online_shop.orders FROM online_shop_writer;