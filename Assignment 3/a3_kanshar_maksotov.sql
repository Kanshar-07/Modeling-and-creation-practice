BEGIN;
WITH new_films AS (
    SELECT
        'Interstellar'          AS title,
        'A team of explorers travel through a wormhole in space in an attempt to ensure humanity''s survival.' AS description,
        2014                    AS release_year,
        (SELECT language_id FROM language WHERE name = 'English') AS language_id,
        7                       AS rental_duration,
        4.99                    AS rental_rate,
        169                     AS length,
        'PG-13'::mpaa_rating    AS rating
    UNION ALL
    SELECT
        'The Dark Knight'       AS title,
        'When the menace known as the Joker wreaks havoc and chaos on the people of Gotham, Batman must accept one of the greatest psychological and physical tests of his ability to fight injustice.' AS description,
        2008                    AS release_year,
        (SELECT language_id FROM language WHERE name = 'English') AS language_id,
        14                      AS rental_duration,
        9.99                    AS rental_rate,
        152                     AS length,
        'PG-13'::mpaa_rating    AS rating
    UNION ALL
    SELECT
        'Inception'             AS title,
        'A thief who steals corporate secrets through the use of dream-sharing technology is given the inverse task of planting an idea into the mind of a C.E.O.' AS description,
        2010                    AS release_year,
        (SELECT language_id FROM language WHERE name = 'English') AS language_id,
        21                      AS rental_duration,
        19.99                   AS rental_rate,
        148                     AS length,
        'PG-13'::mpaa_rating    AS rating
),
inserted_films AS (
    INSERT INTO film (title, description, release_year, language_id, rental_duration, rental_rate, length, rating, last_update)
    SELECT
        nf.title,
        nf.description,
        nf.release_year,
        nf.language_id,
        nf.rental_duration,
        nf.rental_rate,
        nf.length,
        nf.rating,
        CURRENT_DATE AS last_update
    FROM new_films nf
    WHERE NOT EXISTS (
        SELECT 1 FROM film f WHERE f.title = nf.title AND f.release_year = nf.release_year
    )
    RETURNING film_id, title, rental_rate, rental_duration, last_update
)
SELECT film_id, title, rental_rate, rental_duration, last_update FROM inserted_films;
INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Matthew', 'McConaughey', CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM actor WHERE first_name = 'Matthew' AND last_name = 'McConaughey'
);
INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Anne', 'Hathaway', CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM actor WHERE first_name = 'Anne' AND last_name = 'Hathaway'
);
INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Christian', 'Bale', CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM actor WHERE first_name = 'Christian' AND last_name = 'Bale'
);
INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Heath', 'Ledger', CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM actor WHERE first_name = 'Heath' AND last_name = 'Ledger'
);
INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Leonardo', 'DiCaprio', CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM actor WHERE first_name = 'Leonardo' AND last_name = 'DiCaprio'
);
INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Joseph', 'Gordon-Levitt', CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM actor WHERE first_name = 'Joseph' AND last_name = 'Gordon-Levitt'
);
INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Tom', 'Hardy', CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM actor WHERE first_name = 'Tom' AND last_name = 'Hardy'
);
INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT
    (SELECT actor_id FROM actor WHERE first_name = 'Matthew' AND last_name = 'McConaughey'),
    (SELECT film_id  FROM film  WHERE title = 'Interstellar' AND release_year = 2014),
    CURRENT_DATE
ON CONFLICT DO NOTHING;
INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT
    (SELECT actor_id FROM actor WHERE first_name = 'Anne' AND last_name = 'Hathaway'),
    (SELECT film_id  FROM film  WHERE title = 'Interstellar' AND release_year = 2014),
    CURRENT_DATE
ON CONFLICT DO NOTHING;
INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT
    (SELECT actor_id FROM actor WHERE first_name = 'Christian' AND last_name = 'Bale'),
    (SELECT film_id  FROM film  WHERE title = 'The Dark Knight' AND release_year = 2008),
    CURRENT_DATE
ON CONFLICT DO NOTHING;
INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT
    (SELECT actor_id FROM actor WHERE first_name = 'Heath' AND last_name = 'Ledger'),
    (SELECT film_id  FROM film  WHERE title = 'The Dark Knight' AND release_year = 2008),
    CURRENT_DATE
ON CONFLICT DO NOTHING;
INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT
    (SELECT actor_id FROM actor WHERE first_name = 'Leonardo' AND last_name = 'DiCaprio'),
    (SELECT film_id  FROM film  WHERE title = 'Inception' AND release_year = 2010),
    CURRENT_DATE
ON CONFLICT DO NOTHING;
INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT
    (SELECT actor_id FROM actor WHERE first_name = 'Joseph' AND last_name = 'Gordon-Levitt'),
    (SELECT film_id  FROM film  WHERE title = 'Inception' AND release_year = 2010),
    CURRENT_DATE
ON CONFLICT DO NOTHING;
INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT
    (SELECT actor_id FROM actor WHERE first_name = 'Tom' AND last_name = 'Hardy'),
    (SELECT film_id  FROM film  WHERE title = 'Inception' AND release_year = 2010),
    CURRENT_DATE
ON CONFLICT DO NOTHING;
INSERT INTO inventory (film_id, store_id, last_update)
SELECT
    (SELECT film_id FROM film WHERE title = 'Interstellar' AND release_year = 2014),
    (SELECT MIN(store_id) FROM store),
    CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM inventory
    WHERE film_id = (SELECT film_id FROM film WHERE title = 'Interstellar' AND release_year = 2014)
      AND store_id = (SELECT MIN(store_id) FROM store)
);
INSERT INTO inventory (film_id, store_id, last_update)
SELECT
    (SELECT film_id FROM film WHERE title = 'The Dark Knight' AND release_year = 2008),
    (SELECT MIN(store_id) FROM store),
    CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM inventory
    WHERE film_id = (SELECT film_id FROM film WHERE title = 'The Dark Knight' AND release_year = 2008)
      AND store_id = (SELECT MIN(store_id) FROM store)
);
INSERT INTO inventory (film_id, store_id, last_update)
SELECT
    (SELECT film_id FROM film WHERE title = 'Inception' AND release_year = 2010),
    (SELECT MIN(store_id) FROM store),
    CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM inventory
    WHERE film_id = (SELECT film_id FROM film WHERE title = 'Inception' AND release_year = 2010)
      AND store_id = (SELECT MIN(store_id) FROM store)
);
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(DISTINCT r.rental_id)  AS rental_count,
    COUNT(DISTINCT p.payment_id) AS payment_count
FROM customer c
JOIN rental  r ON c.customer_id = r.customer_id
JOIN payment p ON c.customer_id = p.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING COUNT(DISTINCT r.rental_id)  >= 43
   AND COUNT(DISTINCT p.payment_id) >= 43
ORDER BY rental_count DESC
LIMIT 5;
UPDATE customer
SET
    first_name  = 'Kanshar',
    last_name   = 'Maksotov',
    email       = 'kanshar.maksotov@email.com',
    address_id  = (SELECT MIN(address_id) FROM address),
    last_update = CURRENT_DATE
WHERE customer_id = (
    SELECT c.customer_id
    FROM customer c
    JOIN rental  r ON c.customer_id = r.customer_id
    JOIN payment p ON c.customer_id = p.customer_id
    GROUP BY c.customer_id
    HAVING COUNT(DISTINCT r.rental_id)  >= 43
       AND COUNT(DISTINCT p.payment_id) >= 43
    ORDER BY COUNT(DISTINCT r.rental_id) DESC
    LIMIT 1
)
AND NOT (first_name = 'Kanshar' AND last_name = 'Maksotov');
SELECT *
FROM payment
WHERE customer_id = (
    SELECT customer_id FROM customer
    WHERE first_name = 'Kanshar' AND last_name = 'Maksotov'
);
DELETE FROM payment
WHERE customer_id = (
    SELECT customer_id FROM customer
    WHERE first_name = 'Kanshar' AND last_name = 'Maksotov'
);
SELECT *
FROM rental
WHERE customer_id = (
    SELECT customer_id FROM customer
    WHERE first_name = 'Kanshar' AND last_name = 'Maksotov'
);
DELETE FROM rental
WHERE customer_id = (
    SELECT customer_id FROM customer
    WHERE first_name = 'Kanshar' AND last_name = 'Maksotov'
);
INSERT INTO rental (rental_date, inventory_id, customer_id, return_date, staff_id, last_update)
SELECT
    '2017-01-15 10:00:00'::TIMESTAMP,
    (
        SELECT i.inventory_id FROM inventory i
        JOIN film f ON i.film_id = f.film_id
        WHERE f.title = 'Interstellar'
          AND f.release_year = 2014
          AND i.store_id = (SELECT MIN(store_id) FROM store)
        LIMIT 1
    ),
    (SELECT customer_id FROM customer WHERE first_name = 'Kanshar' AND last_name = 'Maksotov'),
    '2017-01-15'::DATE + (
        SELECT rental_duration FROM film WHERE title = 'Interstellar' AND release_year = 2014
    ) * INTERVAL '1 day',
    (SELECT MIN(staff_id) FROM staff),
    CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM rental
    WHERE customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Kanshar' AND last_name = 'Maksotov')
      AND inventory_id = (
          SELECT i.inventory_id FROM inventory i
          JOIN film f ON i.film_id = f.film_id
          WHERE f.title = 'Interstellar' AND f.release_year = 2014
            AND i.store_id = (SELECT MIN(store_id) FROM store)
          LIMIT 1
      )
)
RETURNING rental_id, rental_date, return_date, customer_id, inventory_id;
INSERT INTO rental (rental_date, inventory_id, customer_id, return_date, staff_id, last_update)
SELECT
    '2017-02-10 11:00:00'::TIMESTAMP,
    (
        SELECT i.inventory_id FROM inventory i
        JOIN film f ON i.film_id = f.film_id
        WHERE f.title = 'The Dark Knight'
          AND f.release_year = 2008
          AND i.store_id = (SELECT MIN(store_id) FROM store)
        LIMIT 1
    ),
    (SELECT customer_id FROM customer WHERE first_name = 'Kanshar' AND last_name = 'Maksotov'),
    '2017-02-10'::DATE + (
        SELECT rental_duration FROM film WHERE title = 'The Dark Knight' AND release_year = 2008
    ) * INTERVAL '1 day',
    (SELECT MIN(staff_id) FROM staff),
    CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM rental
    WHERE customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Kanshar' AND last_name = 'Maksotov')
      AND inventory_id = (
          SELECT i.inventory_id FROM inventory i
          JOIN film f ON i.film_id = f.film_id
          WHERE f.title = 'The Dark Knight' AND f.release_year = 2008
            AND i.store_id = (SELECT MIN(store_id) FROM store)
          LIMIT 1
      )
);
INSERT INTO rental (rental_date, inventory_id, customer_id, return_date, staff_id, last_update)
SELECT
    '2017-03-05 09:00:00'::TIMESTAMP,
    (
        SELECT i.inventory_id FROM inventory i
        JOIN film f ON i.film_id = f.film_id
        WHERE f.title = 'Inception'
          AND f.release_year = 2010
          AND i.store_id = (SELECT MIN(store_id) FROM store)
        LIMIT 1
    ),
    (SELECT customer_id FROM customer WHERE first_name = 'Kanshar' AND last_name = 'Maksotov'),
    '2017-03-05'::DATE + (
        SELECT rental_duration FROM film WHERE title = 'Inception' AND release_year = 2010
    ) * INTERVAL '1 day',
    (SELECT MIN(staff_id) FROM staff),
    CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM rental
    WHERE customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Kanshar' AND last_name = 'Maksotov')
      AND inventory_id = (
          SELECT i.inventory_id FROM inventory i
          JOIN film f ON i.film_id = f.film_id
          WHERE f.title = 'Inception' AND f.release_year = 2010
            AND i.store_id = (SELECT MIN(store_id) FROM store)
          LIMIT 1
      )
);
INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT
    (SELECT customer_id FROM customer WHERE first_name = 'Kanshar' AND last_name = 'Maksotov'),
    (SELECT MIN(staff_id) FROM staff),
    (
        SELECT r.rental_id FROM rental r
        JOIN inventory i ON r.inventory_id = i.inventory_id
        JOIN film f ON i.film_id = f.film_id
        WHERE f.title = 'Interstellar'
          AND f.release_year = 2014
          AND r.customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Kanshar' AND last_name = 'Maksotov')
        LIMIT 1
    ),
    4.99,
    '2017-01-15 10:30:00'::TIMESTAMP
WHERE NOT EXISTS (
    SELECT 1 FROM payment
    WHERE rental_id = (
        SELECT r.rental_id FROM rental r
        JOIN inventory i ON r.inventory_id = i.inventory_id
        JOIN film f ON i.film_id = f.film_id
        WHERE f.title = 'Interstellar'
          AND f.release_year = 2014
          AND r.customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Kanshar' AND last_name = 'Maksotov')
        LIMIT 1
    )
);
INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT
    (SELECT customer_id FROM customer WHERE first_name = 'Kanshar' AND last_name = 'Maksotov'),
    (SELECT MIN(staff_id) FROM staff),
    (
        SELECT r.rental_id FROM rental r
        JOIN inventory i ON r.inventory_id = i.inventory_id
        JOIN film f ON i.film_id = f.film_id
        WHERE f.title = 'The Dark Knight'
          AND f.release_year = 2008
          AND r.customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Kanshar' AND last_name = 'Maksotov')
        LIMIT 1
    ),
    9.99,
    '2017-02-10 11:30:00'::TIMESTAMP
WHERE NOT EXISTS (
    SELECT 1 FROM payment
    WHERE rental_id = (
        SELECT r.rental_id FROM rental r
        JOIN inventory i ON r.inventory_id = i.inventory_id
        JOIN film f ON i.film_id = f.film_id
        WHERE f.title = 'The Dark Knight'
          AND f.release_year = 2008
          AND r.customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Kanshar' AND last_name = 'Maksotov')
        LIMIT 1
    )
);
INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT
    (SELECT customer_id FROM customer WHERE first_name = 'Kanshar' AND last_name = 'Maksotov'),
    (SELECT MIN(staff_id) FROM staff),
    (
        SELECT r.rental_id FROM rental r
        JOIN inventory i ON r.inventory_id = i.inventory_id
        JOIN film f ON i.film_id = f.film_id
        WHERE f.title = 'Inception'
          AND f.release_year = 2010
          AND r.customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Kanshar' AND last_name = 'Maksotov')
        LIMIT 1
    ),
    19.99,
    '2017-03-05 09:30:00'::TIMESTAMP
WHERE NOT EXISTS (
    SELECT 1 FROM payment
    WHERE rental_id = (
        SELECT r.rental_id FROM rental r
        JOIN inventory i ON r.inventory_id = i.inventory_id
        JOIN film f ON i.film_id = f.film_id
        WHERE f.title = 'Inception'
          AND f.release_year = 2010
          AND r.customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Kanshar' AND last_name = 'Maksotov')
        LIMIT 1
    )
);
SELECT
    f.title,
    r.rental_date,
    r.return_date,
    p.amount,
    p.payment_date
FROM rental r
JOIN inventory i  ON r.inventory_id = i.inventory_id
JOIN film f       ON i.film_id = f.film_id
JOIN payment p    ON p.rental_id = r.rental_id
WHERE r.customer_id = (
    SELECT customer_id FROM customer WHERE first_name = 'Kanshar' AND last_name = 'Maksotov'
)
ORDER BY r.rental_date;
COMMIT;
