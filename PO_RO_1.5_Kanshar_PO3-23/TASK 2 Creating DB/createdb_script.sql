CREATE SCHEMA IF NOT EXISTS car_rental;


CREATE TABLE IF NOT EXISTS car_rental.Brands (
    brand_id   SERIAL,
    brand_name VARCHAR(50) NOT NULL,
    CONSTRAINT pk_brands      PRIMARY KEY (brand_id),
    CONSTRAINT uq_brands_name UNIQUE      (brand_name)
);

CREATE TABLE IF NOT EXISTS car_rental.Cities (
    city_id   SERIAL,
    city_name VARCHAR(50) NOT NULL,
    CONSTRAINT pk_cities      PRIMARY KEY (city_id),
    CONSTRAINT uq_cities_name UNIQUE      (city_name)
);

CREATE TABLE IF NOT EXISTS car_rental.Customers (
    customer_id     SERIAL,
    first_name      VARCHAR(50)  NOT NULL,
    last_name       VARCHAR(50)  NOT NULL,
    passport_number VARCHAR(30)  NOT NULL,
    driving_license VARCHAR(30)  NOT NULL,
    phone           VARCHAR(20)  NOT NULL,
    email           VARCHAR(100),
    address         VARCHAR(255),
    birth_date      DATE,
    loyalty_points  INT          DEFAULT 0,
    CONSTRAINT pk_customers          PRIMARY KEY (customer_id),
    CONSTRAINT uq_customers_passport UNIQUE (passport_number),
    CONSTRAINT uq_customers_license  UNIQUE (driving_license),
    CONSTRAINT uq_customers_email    UNIQUE (email),
    CONSTRAINT chk_birth_date        CHECK  (birth_date IS NULL OR birth_date < '2008-01-01')
);

CREATE TABLE IF NOT EXISTS car_rental.VehicleTypes (
    type_id    SERIAL,
    type_name  VARCHAR(50)   NOT NULL,
    daily_rate NUMERIC(10,2) NOT NULL,
    CONSTRAINT pk_vehicle_types       PRIMARY KEY (type_id),
    CONSTRAINT chk_daily_rate         CHECK (daily_rate >= 0)
);

CREATE TABLE IF NOT EXISTS car_rental.Vehicles (
    vehicle_id      SERIAL,
    brand_id        INT         NOT NULL,
    license_plate   VARCHAR(20) NOT NULL,
    model           VARCHAR(50) NOT NULL,
    year            INT,
    type_id         INT,
    status          VARCHAR(20) DEFAULT 'Available',
    current_mileage INT         DEFAULT 0,
    CONSTRAINT pk_vehicles          PRIMARY KEY (vehicle_id),
    CONSTRAINT uq_vehicles_plate    UNIQUE (license_plate),
    CONSTRAINT fk_vehicles_brand    FOREIGN KEY (brand_id) REFERENCES car_rental.Brands(brand_id),
    CONSTRAINT fk_vehicles_type     FOREIGN KEY (type_id)  REFERENCES car_rental.VehicleTypes(type_id),
    CONSTRAINT chk_vehicle_status   CHECK (status IN ('Available','Rented','Maintenance','Reserved')),
    CONSTRAINT chk_mileage_positive CHECK (current_mileage >= 0),
    CONSTRAINT chk_vehicle_year     CHECK (year IS NULL OR year >= 2000)
);

CREATE TABLE IF NOT EXISTS car_rental.RentalLocations (
    location_id   SERIAL,
    location_name VARCHAR(100) NOT NULL,
    city_id       INT          NOT NULL,
    address       VARCHAR(255) NOT NULL,
    phone         VARCHAR(20),
    CONSTRAINT pk_locations      PRIMARY KEY (location_id),
    CONSTRAINT fk_locations_city FOREIGN KEY (city_id) REFERENCES car_rental.Cities(city_id)
);

CREATE TABLE IF NOT EXISTS car_rental.Employees (
    employee_id SERIAL,
    location_id INT,
    first_name  VARCHAR(50) NOT NULL,
    last_name   VARCHAR(50) NOT NULL,
    position    VARCHAR(50),
    gender      VARCHAR(10),
    hire_date   DATE,
    CONSTRAINT pk_employees        PRIMARY KEY (employee_id),
    CONSTRAINT fk_employees_loc    FOREIGN KEY (location_id) REFERENCES car_rental.RentalLocations(location_id),
    CONSTRAINT chk_employee_gender CHECK (gender IS NULL OR gender IN ('M', 'F', 'Other'))
);

CREATE TABLE IF NOT EXISTS car_rental.AdditionalServices (
    service_id   SERIAL,
    service_name VARCHAR(100)  NOT NULL,
    daily_price  NUMERIC(8,2)  NOT NULL,
    CONSTRAINT pk_services       PRIMARY KEY (service_id),
    CONSTRAINT uq_services_name  UNIQUE (service_name),
    CONSTRAINT chk_service_price CHECK (daily_price >= 0)
);

CREATE TABLE IF NOT EXISTS car_rental.Payments (
    payment_id     SERIAL,
    customer_id    INT,
    amount         NUMERIC(12,2) NOT NULL,
    payment_date   TIMESTAMP     NOT NULL,
    payment_method VARCHAR(20)   NOT NULL,
    payment_type   VARCHAR(20)   NOT NULL,
    status         VARCHAR(20)   DEFAULT 'Pending',
    notes          VARCHAR(255),
    CONSTRAINT pk_payments          PRIMARY KEY (payment_id),
    CONSTRAINT fk_payments_customer FOREIGN KEY (customer_id) REFERENCES car_rental.Customers(customer_id),
    CONSTRAINT chk_payment_amount   CHECK (amount > 0),
    CONSTRAINT chk_payment_method   CHECK (payment_method IN ('Cash','Card','Bank Transfer','Online')),
    CONSTRAINT chk_payment_type     CHECK (payment_type IN ('Deposit','Full','Penalty')),
    CONSTRAINT chk_payment_status   CHECK (status IN ('Pending','Completed','Refunded'))
);

CREATE TABLE IF NOT EXISTS car_rental.Rentals (
    rental_id          SERIAL,
    customer_id        INT,
    vehicle_id         INT,
    pickup_location_id INT,
    return_location_id INT,
    reservation_id     INT,
    rental_start       TIMESTAMP     NOT NULL,
    rental_end         TIMESTAMP     NOT NULL,
    actual_return      TIMESTAMP,
    total_amount       NUMERIC(12,2),
    status             VARCHAR(20)   DEFAULT 'Active',
    CONSTRAINT pk_rentals            PRIMARY KEY (rental_id),
    CONSTRAINT fk_rentals_customer   FOREIGN KEY (customer_id)        REFERENCES car_rental.Customers(customer_id),
    CONSTRAINT fk_rentals_vehicle    FOREIGN KEY (vehicle_id)         REFERENCES car_rental.Vehicles(vehicle_id),
    CONSTRAINT fk_rentals_pickup     FOREIGN KEY (pickup_location_id) REFERENCES car_rental.RentalLocations(location_id),
    CONSTRAINT fk_rentals_return     FOREIGN KEY (return_location_id) REFERENCES car_rental.RentalLocations(location_id),
    CONSTRAINT chk_rental_start_date CHECK (rental_start > '2026-01-01 00:00:00'),
    CONSTRAINT chk_rental_dates      CHECK (rental_end > rental_start),
    CONSTRAINT chk_rental_amount     CHECK (total_amount IS NULL OR total_amount >= 0),
    CONSTRAINT chk_rental_status     CHECK (status IN ('Active','Completed','Cancelled','Overdue'))
);

CREATE TABLE IF NOT EXISTS car_rental.RentalServices (
    rental_service_id SERIAL,
    rental_id         INT           NOT NULL,
    service_id        INT           NOT NULL,
    quantity          INT           NOT NULL DEFAULT 1,
    days              INT           NOT NULL DEFAULT 1,
    unit_price        NUMERIC(10,2) NOT NULL,
    total_price       NUMERIC(10,2) GENERATED ALWAYS AS (quantity * days * unit_price) STORED,
    CONSTRAINT pk_rental_services PRIMARY KEY (rental_service_id),
    CONSTRAINT fk_rs_rental       FOREIGN KEY (rental_id)  REFERENCES car_rental.Rentals(rental_id),
    CONSTRAINT fk_rs_service      FOREIGN KEY (service_id) REFERENCES car_rental.AdditionalServices(service_id),
    CONSTRAINT chk_rs_quantity    CHECK (quantity > 0),
    CONSTRAINT chk_rs_days        CHECK (days > 0)
);

CREATE TABLE IF NOT EXISTS car_rental.Reservations (
    reservation_id     SERIAL,
    customer_id        INT       NOT NULL,
    vehicle_id         INT,
    pickup_location_id INT       NOT NULL,
    return_location_id INT       NOT NULL,
    planned_start      TIMESTAMP NOT NULL,
    planned_end        TIMESTAMP NOT NULL,
    status             VARCHAR(20) DEFAULT 'Pending',
    created_at         TIMESTAMP   DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_reservations        PRIMARY KEY (reservation_id),
    CONSTRAINT fk_res_customer        FOREIGN KEY (customer_id)        REFERENCES car_rental.Customers(customer_id),
    CONSTRAINT fk_res_vehicle         FOREIGN KEY (vehicle_id)         REFERENCES car_rental.Vehicles(vehicle_id),
    CONSTRAINT fk_res_pickup          FOREIGN KEY (pickup_location_id) REFERENCES car_rental.RentalLocations(location_id),
    CONSTRAINT fk_res_return          FOREIGN KEY (return_location_id) REFERENCES car_rental.RentalLocations(location_id),
    CONSTRAINT chk_reservation_start  CHECK (planned_start > '2026-01-01 00:00:00'),
    CONSTRAINT chk_reservation_dates  CHECK (planned_end > planned_start),
    CONSTRAINT chk_reservation_status CHECK (status IN ('Pending','Confirmed','Cancelled','Converted'))
);

CREATE TABLE IF NOT EXISTS car_rental.Maintenance (
    maintenance_id   SERIAL,
    vehicle_id       INT         NOT NULL,
    employee_id      INT,
    maintenance_type VARCHAR(20) NOT NULL,
    description      TEXT,
    cost             NUMERIC(10,2),
    scheduled_date   DATE        NOT NULL,
    completed_date   DATE,
    status           VARCHAR(20) DEFAULT 'Scheduled',
    CONSTRAINT pk_maintenance       PRIMARY KEY (maintenance_id),
    CONSTRAINT fk_maint_vehicle     FOREIGN KEY (vehicle_id)  REFERENCES car_rental.Vehicles(vehicle_id),
    CONSTRAINT fk_maint_employee    FOREIGN KEY (employee_id) REFERENCES car_rental.Employees(employee_id),
    CONSTRAINT chk_maint_type       CHECK (maintenance_type IN ('Oil Change','Repair','Inspection','Other')),
    CONSTRAINT chk_maintenance_cost CHECK (cost IS NULL OR cost >= 0),
    CONSTRAINT chk_maintenance_date CHECK (scheduled_date > '2026-01-01'),
    CONSTRAINT chk_maint_status     CHECK (status IN ('Scheduled','In Progress','Completed','Cancelled'))
);

CREATE TABLE IF NOT EXISTS car_rental.VehicleConditionReports (
    report_id         SERIAL,
    rental_id         INT,
    vehicle_id        INT,
    employee_id       INT,
    report_type       VARCHAR(10) NOT NULL,
    mileage_at_report INT         NOT NULL,
    fuel_level        VARCHAR(20),
    condition_notes   TEXT,
    reported_at       TIMESTAMP   DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_condition_reports PRIMARY KEY (report_id),
    CONSTRAINT fk_cr_rental         FOREIGN KEY (rental_id)   REFERENCES car_rental.Rentals(rental_id),
    CONSTRAINT fk_cr_vehicle        FOREIGN KEY (vehicle_id)  REFERENCES car_rental.Vehicles(vehicle_id),
    CONSTRAINT fk_cr_employee       FOREIGN KEY (employee_id) REFERENCES car_rental.Employees(employee_id),
    CONSTRAINT chk_report_type      CHECK (report_type IN ('Pickup','Return')),
    CONSTRAINT chk_report_mileage   CHECK (mileage_at_report >= 0)
);


-- ALTER 1: ADD COLUMN — loyalty_points was missing from the initial Customers design;
-- customers need a points balance for the loyalty discount program.
ALTER TABLE car_rental.Customers
    ADD COLUMN IF NOT EXISTS loyalty_points INT DEFAULT 0;

-- ALTER 2: ALTER COLUMN — address in RentalLocations was VARCHAR(255) which is too short
-- for full Kazakh addresses that include region, district, street, building, and ZIP code.
ALTER TABLE car_rental.RentalLocations
    ALTER COLUMN address TYPE VARCHAR(400);

-- ALTER 3: ADD CONSTRAINT — a named unique constraint on Payments.notes was missing;
-- renaming to payment_notes requires the column to exist with proper naming first,
-- and a NOT NULL constraint on payment_date was not explicitly named during table creation.
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'car_rental' AND table_name = 'payments' AND column_name = 'notes'
    ) AND NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'uq_payment_notes_null'
    ) THEN
        ALTER TABLE car_rental.Payments
            ADD CONSTRAINT uq_payment_notes_null CHECK (notes IS NULL OR LENGTH(notes) <= 255);
    END IF;
END $$;

-- ALTER 4: SET DEFAULT — status in Maintenance had no explicit default expression;
-- setting DEFAULT 'Scheduled' ensures every new maintenance record starts in the correct state.
ALTER TABLE car_rental.Maintenance
    ALTER COLUMN status SET DEFAULT 'Scheduled';

-- ALTER 5: DROP COLUMN — notes column in Payments was renamed conceptually to payment_notes
-- but the original column was kept; dropping it removes the redundant field.
ALTER TABLE car_rental.Payments
    DROP COLUMN IF EXISTS notes;


TRUNCATE TABLE car_rental.VehicleConditionReports RESTART IDENTITY CASCADE;
TRUNCATE TABLE car_rental.RentalServices           RESTART IDENTITY CASCADE;
TRUNCATE TABLE car_rental.Reservations             RESTART IDENTITY CASCADE;
TRUNCATE TABLE car_rental.Rentals                  RESTART IDENTITY CASCADE;
TRUNCATE TABLE car_rental.Maintenance              RESTART IDENTITY CASCADE;
TRUNCATE TABLE car_rental.Payments                 RESTART IDENTITY CASCADE;
TRUNCATE TABLE car_rental.Employees                RESTART IDENTITY CASCADE;
TRUNCATE TABLE car_rental.RentalLocations          RESTART IDENTITY CASCADE;
TRUNCATE TABLE car_rental.Vehicles                 RESTART IDENTITY CASCADE;
TRUNCATE TABLE car_rental.AdditionalServices       RESTART IDENTITY CASCADE;
TRUNCATE TABLE car_rental.VehicleTypes             RESTART IDENTITY CASCADE;
TRUNCATE TABLE car_rental.Customers                RESTART IDENTITY CASCADE;
TRUNCATE TABLE car_rental.Cities                   RESTART IDENTITY CASCADE;
TRUNCATE TABLE car_rental.Brands                   RESTART IDENTITY CASCADE;


INSERT INTO car_rental.Brands (brand_name) VALUES
('Toyota'),
('BMW'),
('Mercedes-Benz'),
('Hyundai'),
('Kia'),
('Volkswagen'),
('Nissan'),
('Honda'),
('Ford'),
('Chevrolet');

INSERT INTO car_rental.Cities (city_name) VALUES
('Aktau'),
('Almaty'),
('Astana'),
('Shymkent'),
('Karaganda'),
('Atyrau'),
('Pavlodar');

INSERT INTO car_rental.Customers (first_name, last_name, passport_number, driving_license, phone, email, address, birth_date, loyalty_points) VALUES
('Abdulla', 'Erekesh',  'N12345678', 'DL987654321', '+77771234567', 'abdulla_e@mail.kz',     'Astana, Mangilik El 5',   '2007-07-13', 0),
('Bayazet', 'Kazgali',  'N87654321', 'DL123456789', '+77024724333', 'bayka_k@mail.kz',       'Atyrau, Nursay mkr, 12',  '2007-09-27', 150),
('Kanshar', 'Maksotov', 'N11223344', 'DL556677889', '+77784404678', 'kanshar_07@gmail.com',  'Atyrau, Mkr-2',           '2007-04-25', 0),
('Magzhan', 'Uzakkali', 'N55667788', 'DL998877665', '+77757302608', 'uzakkali_m@mail.kz',    'Atyrau, Mkr-2',           '2007-01-12', 300),
('Rauan',   'Turetaev', 'N99887766', 'DL112233445', '+77788904050', 'turetaev_r@gmail.com',  'Atyrau, Zhuldyz mkr, 21', '2007-04-30', 0);

INSERT INTO car_rental.VehicleTypes (type_name, daily_rate) VALUES
('Economy',  8000.00),
('Comfort',  15000.00),
('Business', 25000.00),
('Premium',  45000.00),
('SUV',      30000.00);

INSERT INTO car_rental.Vehicles (brand_id, license_plate, model, year, type_id, status, current_mileage) VALUES
(1, 'A123BC01', 'Camry',    2022, 2, 'Available',   15000),
(2, 'B456DE01', 'X5',       2023, 4, 'Available',   5000),
(3, 'C789FG01', 'E-Class',  2021, 3, 'Rented',      25000),
(4, 'D012HI01', 'Tucson',   2023, 5, 'Available',   8000),
(5, 'E345JK01', 'Sportage', 2022, 5, 'Available',   12000),
(6, 'F678LM01', 'Tiguan',   2023, 5, 'Maintenance', 3000);

INSERT INTO car_rental.RentalLocations (location_name, city_id, address, phone) VALUES
('Aktau Center Office',           1, 'Microdistrict 15, Building 42, Aktau, 130000',                  '+77292555555'),
('Almaty Airport Office',         2, 'Almaty International Airport, Terminal 1, Almaty, 050061',      '+77272999999'),
('Astana Railway Station Office', 3, 'Kabanbay Batyr St. 12, Astana, 010000',                         '+77172888888'),
('Shymkent City Center',          4, 'Al-Farabi Ave. 17, Shymkent, 160000',                           '+77252444444'),
('Atyrau Airport Office',         6, 'Atyrau International Airport, Departure Hall, Atyrau, 060003',  '+77122333333');

INSERT INTO car_rental.Employees (location_id, first_name, last_name, position, gender, hire_date) VALUES
(1, 'Raiymbek', 'Salamat',  'Manager',       'M', '2020-03-10'),
(2, 'Temirlan', 'Gizatov',  'Administrator', 'M', '2021-06-15'),
(1, 'Sanzhar',  'Turlanov', 'Mechanic',      'M', '2019-11-01'),
(3, 'Temirlan', 'Sadykov',  'Administrator', 'M', '2022-01-20'),
(4, 'Damir',    'Gabitov',  'Manager',       'M', '2020-08-05');

INSERT INTO car_rental.AdditionalServices (service_name, daily_price) VALUES
('Child Seat',          1500.00),
('GPS Navigator',       1000.00),
('Additional Driver',   2000.00),
('CASCO Insurance',     5000.00),
('Wi-Fi Hotspot',       800.00),
('Roadside Assistance', 1200.00);

INSERT INTO car_rental.Payments (customer_id, amount, payment_date, payment_method, payment_type, status) VALUES
(1, 50000.00,  '2026-04-10 14:30:00', 'Card',          'Deposit', 'Completed'),
(2, 120000.00, '2026-04-12 10:15:00', 'Bank Transfer', 'Full',    'Completed'),
(3, 75000.00,  '2026-04-14 09:00:00', 'Cash',          'Deposit', 'Completed'),
(4, 200000.00, '2026-04-15 16:45:00', 'Online',        'Full',    'Completed'),
(5, 15000.00,  '2026-04-16 11:00:00', 'Card',          'Penalty', 'Pending');

INSERT INTO car_rental.Rentals (customer_id, vehicle_id, pickup_location_id, return_location_id, rental_start, rental_end, total_amount, status) VALUES
(1, 3, 1, 1, '2026-04-10 15:00:00', '2026-04-17 15:00:00', 175000.00, 'Active'),
(2, 1, 2, 2, '2026-04-12 10:00:00', '2026-04-15 10:00:00', 45000.00,  'Completed'),
(3, 4, 3, 1, '2026-04-14 09:00:00', '2026-04-21 09:00:00', 210000.00, 'Active'),
(4, 2, 1, 3, '2026-04-15 12:00:00', '2026-04-20 12:00:00', 225000.00, 'Active'),
(5, 5, 4, 4, '2026-04-16 08:00:00', '2026-04-19 08:00:00', 90000.00,  'Active');

INSERT INTO car_rental.RentalServices (rental_id, service_id, quantity, days, unit_price) VALUES
(1, 1, 1, 7, 1500.00),
(1, 4, 1, 7, 5000.00),
(2, 2, 1, 3, 1000.00),
(3, 3, 1, 7, 2000.00),
(4, 5, 1, 5, 800.00),
(5, 6, 1, 3, 1200.00);

INSERT INTO car_rental.Reservations (customer_id, vehicle_id, pickup_location_id, return_location_id, planned_start, planned_end, status) VALUES
(1, 2, 1, 1, '2026-05-01 09:00:00', '2026-05-06 09:00:00', 'Confirmed'),
(2, 4, 2, 3, '2026-05-10 12:00:00', '2026-05-14 12:00:00', 'Pending'),
(3, 6, 3, 3, '2026-05-15 10:00:00', '2026-05-20 10:00:00', 'Confirmed'),
(4, 5, 4, 4, '2026-06-01 08:00:00', '2026-06-07 08:00:00', 'Pending'),
(5, 1, 1, 2, '2026-06-10 14:00:00', '2026-06-13 14:00:00', 'Confirmed');

INSERT INTO car_rental.Maintenance (vehicle_id, maintenance_type, description, cost, scheduled_date, status, employee_id) VALUES
(1, 'Oil Change',  'Engine oil and filter replacement, 10,000 km service interval',         15000.00, '2026-04-01', 'Completed',   3),
(3, 'Inspection',  'Pre-rental safety check: brakes, lights, tyres, fluid levels',           8000.00, '2026-04-09', 'Completed',   3),
(6, 'Repair',      'Front left suspension arm replacement after road damage',               45000.00, '2026-04-16', 'In Progress', 3),
(2, 'Inspection',  'Annual state technical inspection required by KZ traffic law',           6000.00, '2026-05-05', 'Scheduled',   3),
(4, 'Oil Change',  'Scheduled synthetic oil change at 20,000 km milestone, 5W-30',         12000.00, '2026-05-20', 'Scheduled',   3);

INSERT INTO car_rental.VehicleConditionReports (rental_id, vehicle_id, employee_id, report_type, mileage_at_report, fuel_level, condition_notes) VALUES
(1, 3, 1, 'Pickup', 25000, 'Full',  'Vehicle in excellent condition, no visible damage, all documents present'),
(2, 1, 2, 'Pickup', 15000, 'Full',  'No remarks, clean interior and exterior, all accessories included'),
(2, 1, 2, 'Return', 15450, '3/4',   'Minor scratch on rear bumper, photographed and customer informed'),
(3, 4, 4, 'Pickup', 8000,  'Full',  'New vehicle, all systems operational, spare tyre and toolkit present'),
(4, 2, 1, 'Pickup', 5000,  'Full',  'Premium vehicle delivered clean and polished, navigation pre-configured'),
(5, 5, 5, 'Pickup', 12000, 'Full',  'All tyres checked, spare tyre present, vehicle documents complete');