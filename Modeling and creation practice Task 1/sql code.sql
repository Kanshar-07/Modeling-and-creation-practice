CREATE TABLE owners (
    id          SERIAL PRIMARY KEY,
    full_name   VARCHAR(100) NOT NULL,
    phone       VARCHAR(20)  UNIQUE NOT NULL,
    email       VARCHAR(100) UNIQUE NOT NULL,
    registered  DATE         NOT NULL DEFAULT CURRENT_DATE
                             CHECK (registered >= '2026-01-01'),
    is_active   BOOLEAN      DEFAULT true
);

CREATE TABLE trucks (
    id            SERIAL PRIMARY KEY,
    owner_id      INT          NOT NULL REFERENCES owners(id),
    truck_name    VARCHAR(100) NOT NULL,
    license_plate VARCHAR(20)  UNIQUE NOT NULL,
    cuisine_type  VARCHAR(50)  NOT NULL,
    capacity      INT          NOT NULL CHECK (capacity >= 0),
    joined_date   DATE         NOT NULL DEFAULT CURRENT_DATE
                               CHECK (joined_date >= '2026-01-01')
);

CREATE TABLE locations (
    id            SERIAL PRIMARY KEY,
    location_name VARCHAR(100)  NOT NULL,
    city          VARCHAR(100)  NOT NULL,
    daily_fee     NUMERIC(10,2) NOT NULL CHECK (daily_fee >= 0),
    max_spots     INT           NOT NULL CHECK (max_spots >= 0),
    is_available  BOOLEAN       DEFAULT true
);

CREATE TABLE bookings (
    id           SERIAL PRIMARY KEY,
    truck_id     INT           NOT NULL REFERENCES trucks(id),
    location_id  INT           NOT NULL REFERENCES locations(id),
    booking_date DATE          NOT NULL DEFAULT CURRENT_DATE
                               CHECK (booking_date >= '2026-01-01'),
    total_fee    NUMERIC(10,2) NOT NULL CHECK (total_fee >= 0),
    status       VARCHAR(20)   NOT NULL DEFAULT 'pending'
);

INSERT INTO owners (full_name, phone, email, registered) VALUES
('Amir Seitkali',      '+77011234567', 'amir@mail.com',   '2026-01-10'),
('Dana Bekova',        '+77027654321', 'dana@mail.com',   '2026-02-05'),
('Timur Omarov',       '+77031112233', 'timur@mail.com',  '2026-03-01'),
('Aliya Nurova',       '+77044445566', 'aliya@mail.com',  '2026-03-15'),
('Ruslan Dzhaksybekov','+77055556677', 'ruslan@mail.com', '2026-04-01');

INSERT INTO trucks (owner_id, truck_name, license_plate, cuisine_type, capacity, joined_date) VALUES
(1, 'Kazakh Bites',    'KZ001AA', 'Kazakh',   30, '2026-01-15'),
(2, 'Burger Bliss',    'KZ002BB', 'American', 25, '2026-02-10'),
(3, 'Spice Route',     'KZ003CC', 'Indian',   20, '2026-03-05'),
(4, 'Pasta Palace',    'KZ004DD', 'Italian',  35, '2026-03-20'),
(5, 'Sushi on Wheels', 'KZ005EE', 'Japanese', 15, '2026-04-02');

INSERT INTO locations (location_name, city, daily_fee, max_spots) VALUES
('Central Park Market', 'Aktau',    5000.00, 10),
('Harbor Square',       'Aktau',    7500.00,  5),
('Riverside Fest Zone', 'Almaty',   6000.00,  8),
('Tech Hub Plaza',      'Astana',   8000.00,  6),
('Old Town Bazaar',     'Shymkent', 4500.00, 12);

INSERT INTO bookings (truck_id, location_id, booking_date, total_fee, status) VALUES
(1, 1, '2026-02-01', 5000.00, 'confirmed'),
(2, 2, '2026-02-15', 7500.00, 'confirmed'),
(3, 3, '2026-03-10', 6000.00, 'pending'),
(4, 4, '2026-03-25', 8000.00, 'confirmed'),
(5, 5, '2026-04-05', 4500.00, 'pending');


SELECT * FROM owners;   
SELECT * FROM trucks;   
SELECT * FROM locations;
SELECT * FROM bookings; 