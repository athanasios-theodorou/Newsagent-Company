/*
    Project: Newsagent Company Database
    DBMS: Microsoft SQL Server (T-SQL)
    Description:
    A relational database for a newsstand and print distribution company.
    It models publishers, agencies, customers, delivery staff, vehicles, publications,
    publication issues, subscription orders, single-issue orders, and daily delivery runs.
*/

IF DB_ID(N'newsagent_company') IS NULL
BEGIN
    CREATE DATABASE newsagent_company;
END;
GO

USE newsagent_company;
GO

/* Drop tables in dependency order so the script can be re-run safely. */
IF OBJECT_ID(N'dbo.issue_orders', N'U') IS NOT NULL DROP TABLE dbo.issue_orders;
IF OBJECT_ID(N'dbo.subscription_orders', N'U') IS NOT NULL DROP TABLE dbo.subscription_orders;
IF OBJECT_ID(N'dbo.delivery_runs', N'U') IS NOT NULL DROP TABLE dbo.delivery_runs;
IF OBJECT_ID(N'dbo.publication_issues', N'U') IS NOT NULL DROP TABLE dbo.publication_issues;
IF OBJECT_ID(N'dbo.couriers', N'U') IS NOT NULL DROP TABLE dbo.couriers;
IF OBJECT_ID(N'dbo.vehicles', N'U') IS NOT NULL DROP TABLE dbo.vehicles;
IF OBJECT_ID(N'dbo.agencies', N'U') IS NOT NULL DROP TABLE dbo.agencies;
IF OBJECT_ID(N'dbo.publications', N'U') IS NOT NULL DROP TABLE dbo.publications;
IF OBJECT_ID(N'dbo.customers', N'U') IS NOT NULL DROP TABLE dbo.customers;
IF OBJECT_ID(N'dbo.companies', N'U') IS NOT NULL DROP TABLE dbo.companies;
GO

/* 
    Table: companies
    Stores publishing and media companies that own agencies, vehicles, and publications.
*/
CREATE TABLE dbo.companies (
    company_id           INT            NOT NULL,
    company_name         NVARCHAR(100)  NOT NULL,
    tax_id               VARCHAR(15)    NOT NULL,
    headquarters_address NVARCHAR(150)  NOT NULL,
    city                 NVARCHAR(60)   NOT NULL,
    is_active            BIT            NOT NULL,
    created_at           DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_companies PRIMARY KEY (company_id),
    CONSTRAINT UQ_companies_tax_id UNIQUE (tax_id)
);
GO

/* 
    Table: customers
    Stores retail and business customers that place subscriptions or single-issue orders.
*/
CREATE TABLE dbo.customers (
    customer_id          INT            NOT NULL,
    customer_name        NVARCHAR(120)  NOT NULL,
    customer_type        VARCHAR(20)    NOT NULL,
    phone_number         VARCHAR(20)    NOT NULL,
    email                VARCHAR(120)   NULL,
    address_line         NVARCHAR(150)  NOT NULL,
    city                 NVARCHAR(60)   NOT NULL,
    postal_code          VARCHAR(10)    NOT NULL,
    is_active            BIT            NOT NULL,
    CONSTRAINT PK_customers PRIMARY KEY (customer_id),
    CONSTRAINT CK_customers_type CHECK (customer_type IN ('INDIVIDUAL', 'BUSINESS'))
);
GO

/* 
    Table: publications
    Stores newspapers and magazines distributed by the company.
*/
CREATE TABLE dbo.publications (
    publication_id            INT            NOT NULL,
    company_id                INT            NOT NULL,
    title                     NVARCHAR(120)  NOT NULL,
    category                  VARCHAR(30)    NOT NULL,
    frequency                 VARCHAR(20)    NOT NULL,
    launch_year               SMALLINT       NOT NULL,
    editor_in_chief           NVARCHAR(100)  NOT NULL,
    cover_price               DECIMAL(8,2)   NOT NULL,
    is_newspaper              BIT            NOT NULL,
    is_active                 BIT            NOT NULL,
    CONSTRAINT PK_publications PRIMARY KEY (publication_id),
    CONSTRAINT FK_publications_companies FOREIGN KEY (company_id) REFERENCES dbo.companies(company_id),
    CONSTRAINT CK_publications_category CHECK (category IN ('POLITICS', 'SPORTS', 'BUSINESS', 'LIFESTYLE', 'TECH', 'CULTURE', 'TRAVEL', 'SCIENCE')),
    CONSTRAINT CK_publications_frequency CHECK (frequency IN ('DAILY', 'WEEKLY', 'MONTHLY', 'QUARTERLY')),
    CONSTRAINT CK_publications_cover_price CHECK (cover_price > 0)
);
GO

/* 
    Table: agencies
    Stores local distribution agencies that serve customers and manage delivery staff.
*/
CREATE TABLE dbo.agencies (
    agency_id             INT            NOT NULL,
    company_id            INT            NOT NULL,
    agency_name           NVARCHAR(100)  NOT NULL,
    agency_address        NVARCHAR(150)  NOT NULL,
    city                  NVARCHAR(60)   NOT NULL,
    phone_number          VARCHAR(20)    NOT NULL,
    manager_name          NVARCHAR(100)  NOT NULL,
    opening_date          DATE           NOT NULL,
    is_active             BIT            NOT NULL,
    CONSTRAINT PK_agencies PRIMARY KEY (agency_id),
    CONSTRAINT FK_agencies_companies FOREIGN KEY (company_id) REFERENCES dbo.companies(company_id)
);
GO

/* 
    Table: vehicles
    Stores vehicles assigned to agencies for publication deliveries.
*/
CREATE TABLE dbo.vehicles (
    vehicle_id             INT            NOT NULL,
    company_id             INT            NOT NULL,
    agency_id              INT            NOT NULL,
    plate_number           VARCHAR(15)    NOT NULL,
    brand                  NVARCHAR(50)   NOT NULL,
    model                  NVARCHAR(50)   NOT NULL,
    vehicle_type           VARCHAR(20)    NOT NULL,
    engine_cc              INT            NOT NULL,
    load_capacity_kg       INT            NOT NULL,
    purchase_date          DATE           NOT NULL,
    is_active              BIT            NOT NULL,
    CONSTRAINT PK_vehicles PRIMARY KEY (vehicle_id),
    CONSTRAINT UQ_vehicles_plate_number UNIQUE (plate_number),
    CONSTRAINT FK_vehicles_companies FOREIGN KEY (company_id) REFERENCES dbo.companies(company_id),
    CONSTRAINT FK_vehicles_agencies FOREIGN KEY (agency_id) REFERENCES dbo.agencies(agency_id),
    CONSTRAINT CK_vehicles_type CHECK (vehicle_type IN ('SCOOTER', 'CAR', 'VAN')),
    CONSTRAINT CK_vehicles_engine_cc CHECK (engine_cc >= 100),
    CONSTRAINT CK_vehicles_capacity CHECK (load_capacity_kg > 0)
);
GO

/* 
    Table: couriers
    Stores delivery employees working for a specific agency and optionally assigned a vehicle.
*/
CREATE TABLE dbo.couriers (
    courier_id             INT            NOT NULL,
    agency_id              INT            NOT NULL,
    vehicle_id             INT            NOT NULL,
    first_name             NVARCHAR(50)   NOT NULL,
    last_name              NVARCHAR(50)   NOT NULL,
    phone_number           VARCHAR(20)    NOT NULL,
    hire_date              DATE           NOT NULL,
    monthly_salary         DECIMAL(10,2)  NOT NULL,
    employment_status      VARCHAR(20)    NOT NULL,
    CONSTRAINT PK_couriers PRIMARY KEY (courier_id),
    CONSTRAINT FK_couriers_agencies FOREIGN KEY (agency_id) REFERENCES dbo.agencies(agency_id),
    CONSTRAINT FK_couriers_vehicles FOREIGN KEY (vehicle_id) REFERENCES dbo.vehicles(vehicle_id),
    CONSTRAINT CK_couriers_salary CHECK (monthly_salary >= 700),
    CONSTRAINT CK_couriers_status CHECK (employment_status IN ('FULL_TIME', 'PART_TIME', 'SEASONAL'))
);
GO

/* 
    Table: publication_issues
    Stores individual issues/releases for each publication.
*/
CREATE TABLE dbo.publication_issues (
    issue_id                INT            NOT NULL,
    publication_id          INT            NOT NULL,
    issue_code              VARCHAR(30)    NOT NULL,
    issue_date              DATE           NOT NULL,
    page_count              INT            NOT NULL,
    print_quantity          INT            NOT NULL,
    available_quantity      INT            NOT NULL,
    unit_price              DECIMAL(8,2)   NOT NULL,
    return_deadline         DATE           NOT NULL,
    CONSTRAINT PK_publication_issues PRIMARY KEY (issue_id),
    CONSTRAINT UQ_publication_issues_code UNIQUE (issue_code),
    CONSTRAINT FK_publication_issues_publications FOREIGN KEY (publication_id) REFERENCES dbo.publications(publication_id),
    CONSTRAINT CK_publication_issues_pages CHECK (page_count >= 16),
    CONSTRAINT CK_publication_issues_quantities CHECK (print_quantity > 0 AND available_quantity >= 0 AND available_quantity <= print_quantity),
    CONSTRAINT CK_publication_issues_price CHECK (unit_price > 0),
    CONSTRAINT CK_publication_issues_deadline CHECK (return_deadline >= issue_date)
);
GO

/* 
    Table: delivery_runs
    Stores daily delivery routes completed by couriers using assigned vehicles.
*/
CREATE TABLE dbo.delivery_runs (
    delivery_run_id         INT            NOT NULL,
    courier_id              INT            NOT NULL,
    vehicle_id              INT            NOT NULL,
    agency_id               INT            NOT NULL,
    route_name              NVARCHAR(100)  NOT NULL,
    start_time              DATETIME2      NOT NULL,
    end_time                DATETIME2      NOT NULL,
    kilometers_travelled    DECIMAL(8,2)   NOT NULL,
    delivered_orders_count  INT            NOT NULL,
    fuel_cost               DECIMAL(8,2)   NOT NULL,
    CONSTRAINT PK_delivery_runs PRIMARY KEY (delivery_run_id),
    CONSTRAINT FK_delivery_runs_couriers FOREIGN KEY (courier_id) REFERENCES dbo.couriers(courier_id),
    CONSTRAINT FK_delivery_runs_vehicles FOREIGN KEY (vehicle_id) REFERENCES dbo.vehicles(vehicle_id),
    CONSTRAINT FK_delivery_runs_agencies FOREIGN KEY (agency_id) REFERENCES dbo.agencies(agency_id),
    CONSTRAINT CK_delivery_runs_time CHECK (end_time > start_time),
    CONSTRAINT CK_delivery_runs_km CHECK (kilometers_travelled >= 0),
    CONSTRAINT CK_delivery_runs_orders CHECK (delivered_orders_count >= 0),
    CONSTRAINT CK_delivery_runs_fuel CHECK (fuel_cost >= 0)
);
GO

/* 
    Table: subscription_orders
    Stores recurring customer subscriptions for a publication handled by an agency.
*/
CREATE TABLE dbo.subscription_orders (
    subscription_order_id   INT            NOT NULL,
    customer_id             INT            NOT NULL,
    publication_id          INT            NOT NULL,
    agency_id               INT            NOT NULL,
    start_date              DATE           NOT NULL,
    end_date                DATE           NOT NULL,
    copies_per_delivery     INT            NOT NULL,
    payment_method          VARCHAR(20)    NOT NULL,
    total_amount            DECIMAL(10,2)  NOT NULL,
    order_status            VARCHAR(20)    NOT NULL,
    CONSTRAINT PK_subscription_orders PRIMARY KEY (subscription_order_id),
    CONSTRAINT FK_subscription_orders_customers FOREIGN KEY (customer_id) REFERENCES dbo.customers(customer_id),
    CONSTRAINT FK_subscription_orders_publications FOREIGN KEY (publication_id) REFERENCES dbo.publications(publication_id),
    CONSTRAINT FK_subscription_orders_agencies FOREIGN KEY (agency_id) REFERENCES dbo.agencies(agency_id),
    CONSTRAINT CK_subscription_orders_dates CHECK (end_date > start_date),
    CONSTRAINT CK_subscription_orders_copies CHECK (copies_per_delivery > 0),
    CONSTRAINT CK_subscription_orders_payment CHECK (payment_method IN ('CASH', 'CARD', 'BANK_TRANSFER', 'PAYPAL')),
    CONSTRAINT CK_subscription_orders_amount CHECK (total_amount > 0),
    CONSTRAINT CK_subscription_orders_status CHECK (order_status IN ('ACTIVE', 'COMPLETED', 'PAUSED', 'CANCELLED'))
);
GO

/* 
    Table: issue_orders
    Stores one-time orders for specific publication issues.
*/
CREATE TABLE dbo.issue_orders (
    issue_order_id          INT            NOT NULL,
    customer_id             INT            NOT NULL,
    issue_id                INT            NOT NULL,
    agency_id               INT            NOT NULL,
    order_date              DATETIME2      NOT NULL,
    quantity                INT            NOT NULL,
    payment_method          VARCHAR(20)    NOT NULL,
    total_amount            DECIMAL(10,2)  NOT NULL,
    order_status            VARCHAR(20)    NOT NULL,
    CONSTRAINT PK_issue_orders PRIMARY KEY (issue_order_id),
    CONSTRAINT FK_issue_orders_customers FOREIGN KEY (customer_id) REFERENCES dbo.customers(customer_id),
    CONSTRAINT FK_issue_orders_publication_issues FOREIGN KEY (issue_id) REFERENCES dbo.publication_issues(issue_id),
    CONSTRAINT FK_issue_orders_agencies FOREIGN KEY (agency_id) REFERENCES dbo.agencies(agency_id),
    CONSTRAINT CK_issue_orders_quantity CHECK (quantity > 0),
    CONSTRAINT CK_issue_orders_payment CHECK (payment_method IN ('CASH', 'CARD', 'BANK_TRANSFER', 'PAYPAL')),
    CONSTRAINT CK_issue_orders_amount CHECK (total_amount > 0),
    CONSTRAINT CK_issue_orders_status CHECK (order_status IN ('PLACED', 'FULFILLED', 'CANCELLED'))
);
GO

/* Seed data: companies (15 rows) */
INSERT INTO dbo.companies (company_id, company_name, tax_id, headquarters_address, city, is_active) VALUES
(1,  N'Horizon Media Group',      '094582301', '12 Syngrou Avenue',         N'Athens',      1),
(2,  N'Attica Press Network',     '103948275', '44 Patision Street',        N'Athens',      1),
(3,  N'North Star Publications',  '108374926', '9 Tsimiski Street',         N'Thessaloniki',1),
(4,  N'Peloponnese Print House',  '115902847', '25 Korinthou Street',       N'Patras',      1),
(5,  N'Aegean News Company',      '120845763', '18 Ikarou Avenue',          N'Heraklion',   1),
(6,  N'Ionian Daily Editions',    '129384756', '66 Ethnikis Antistaseos',   N'Ioannina',    1),
(7,  N'Urban Stories Publishing', '134875920', '31 Ermou Street',           N'Athens',      1),
(8,  N'Metro Business Media',     '140938562', '87 Egnatia Street',         N'Thessaloniki',1),
(9,  N'Blue Coast Periodicals',   '145928374', '52 Othonos Street',         N'Volos',       1),
(10, N'Capital Insight Press',    '151928374', '101 Kifisias Avenue',       N'Marousi',     1),
(11, N'Weekend Review SA',        '164029385', '7 Navarinou Street',        N'Kalamata',    0),
(12, N'Helios Feature Media',     '170293845', '14 Demokratias Square',     N'Larisa',      1),
(13, N'Agora Print Solutions',    '184756293', '23 Nikis Street',           N'Athens',      1),
(14, N'Prime Report Editions',    '191827364', '3 Kanari Street',           N'Piraeus',     0),
(15, N'CityBeat Publications',    '205938471', '59 Agiou Andreou Street',   N'Patras',      1);
GO

/* Seed data: customers (15 rows) */
INSERT INTO dbo.customers (customer_id, customer_name, customer_type, phone_number, email, address_line, city, postal_code, is_active) VALUES
(1,  N'Nikos Papadopoulos',      'INDIVIDUAL', '2105550101', 'nikos.papadopoulos@email.com', '190 Vouliagmenis Avenue',   N'Athens',       '17235', 1),
(2,  N'Maria Georgiou',          'INDIVIDUAL', '2310550121', 'maria.georgiou@email.com',     '22 Egnatia Street',         N'Thessaloniki', '54625', 1),
(3,  N'BookPoint Kiosk',         'BUSINESS',   '2105550131', 'orders@bookpoint.gr',          '8 Panepistimiou Street',   N'Athens',       '10564', 1),
(4,  N'Patra Corner Market',     'BUSINESS',   '2610550141', 'contact@patracorner.gr',       '41 Riga Fereou Street',    N'Patras',       '26221', 1),
(5,  N'Elena Dimitriou',         'INDIVIDUAL', '2810550151', 'elena.dimitriou@email.com',    '73 Knossou Avenue',        N'Heraklion',    '71306', 1),
(6,  N'The Daily Stand',         'BUSINESS',   '2105550161', 'sales@dailystand.gr',          '15 Stadiou Street',        N'Athens',       '10562', 1),
(7,  N'Ioannis Karalis',         'INDIVIDUAL', '2410550171', 'ioannis.karalis@email.com',    '9 Papakyriazi Street',     N'Larisa',       '41222', 1),
(8,  N'Thess News Hub',          'BUSINESS',   '2310550181', 'hello@thessnewshub.gr',        '117 Tsimiski Street',      N'Thessaloniki', '54621', 1),
(9,  N'Sofia Mavridou',          'INDIVIDUAL', '2421050191', 'sofia.mavridou@email.com',     '28 Dimitriados Street',    N'Volos',        '38221', 1),
(10, N'Central Press Kiosk',     'BUSINESS',   '2105550201', 'store@centralpress.gr',        '64 Athinas Street',        N'Athens',       '10551', 1),
(11, N'Giorgos Alexiou',         'INDIVIDUAL', '2651050211', 'giorgos.alexiou@email.com',    '12 Dodonis Avenue',        N'Ioannina',     '45221', 1),
(12, N'Urban Mini Market',       'BUSINESS',   '2105550221', 'urban.market@email.com',       '49 Acharnon Street',       N'Athens',       '10439', 1),
(13, N'Katerina Vlahou',         'INDIVIDUAL', '2721050231', 'katerina.vlahou@email.com',    '6 Aristomenous Street',    N'Kalamata',     '24100', 1),
(14, N'Sea View Convenience',    'BUSINESS',   '2810550241', 'manager@seaviewconv.gr',       '11 Sofokli Venizelou',     N'Heraklion',    '71202', 1),
(15, N'Andreas Ntovas',          'INDIVIDUAL', '2105550251', 'andreas.ntovas@email.com',     '91 Alexandras Avenue',     N'Athens',       '11474', 1);
GO

/* Seed data: publications (15 rows) */
INSERT INTO dbo.publications (publication_id, company_id, title, category, frequency, launch_year, editor_in_chief, cover_price, is_newspaper, is_active) VALUES
(1, 1,  N'Morning Ledger',       'BUSINESS',  'DAILY',     1998, N'Alexis Romanos',      1.80, 1, 1),
(2, 2,  N'City Politics',        'POLITICS',  'DAILY',     2005, N'Irini Kosta',         1.60, 1, 1),
(3, 3,  N'Sports Pulse',         'SPORTS',    'DAILY',     2010, N'Spyros Danelis',      1.50, 1, 1),
(4, 4,  N'Peloponnese Today',    'CULTURE',   'WEEKLY',    2001, N'Giorgos Ladas',       3.90, 0, 1),
(5, 5,  N'Aegean Living',        'LIFESTYLE', 'MONTHLY',   2014, N'Elena Mertzi',        4.50, 0, 1),
(6, 6,  N'Tech Horizon',         'TECH',      'MONTHLY',   2018, N'Dimitris Kanelos',    5.20, 0, 1),
(7, 7,  N'Urban Week',           'CULTURE',   'WEEKLY',    2011, N'Maria Tsouka',        3.20, 0, 1),
(8, 8,  N'Market Scope',         'BUSINESS',  'WEEKLY',    2009, N'Petros Melis',        4.10, 0, 1),
(9, 9,  N'Travel Blue',          'TRAVEL',    'MONTHLY',   2016, N'Sofia Kaneli',        5.60, 0, 1),
(10,10, N'Capital Brief',        'BUSINESS',  'DAILY',     2007, N'Nikos Delis',         1.90, 1, 1),
(11,12, N'Helios Science',       'SCIENCE',   'MONTHLY',   2019, N'Rania Vrettou',       5.80, 0, 1),
(12,13, N'Agora Review',         'POLITICS',  'WEEKLY',    2013, N'Antonis Vergos',      3.70, 0, 1),
(13,15, N'CityBeat Weekend',     'LIFESTYLE', 'WEEKLY',    2020, N'Katerina Drakou',     3.50, 0, 1),
(14,1,  N'Investor Daily',       'BUSINESS',  'DAILY',     2003, N'Yannis Fotis',        2.10, 1, 1),
(15,3,  N'Stadium Insider',      'SPORTS',    'WEEKLY',    2017, N'Leonidas Karras',     3.90, 0, 1);
GO

/* Seed data: agencies (15 rows) */
INSERT INTO dbo.agencies (agency_id, company_id, agency_name, agency_address, city, phone_number, manager_name, opening_date, is_active) VALUES
(1,  1,  N'Athens Central Agency',       '14 Syngrou Avenue',          N'Athens',       '2106101001', N'Christos Mavros',    '2016-01-15', 1),
(2,  2,  N'North Athens Agency',         '77 Kifisias Avenue',         N'Marousi',      '2106101002', N'Anna Kallia',        '2017-03-01', 1),
(3,  3,  N'Thessaloniki Downtown Hub',   '95 Egnatia Street',          N'Thessaloniki', '23106101003', N'Vasilis Tsonis',     '2015-06-20', 1),
(4,  4,  N'Patras Distribution Point',   '28 Maizonos Street',         N'Patras',       '26106101004', N'Ioanna Petsa',       '2018-02-10', 1),
(5,  5,  N'Heraklion Main Agency',       '33 Kalokairinou Avenue',     N'Heraklion',    '28106101005', N'Manolis Arvanitis',  '2019-05-13', 1),
(6,  6,  N'Ioannina City Agency',        '18 Dodonis Avenue',          N'Ioannina',     '265106101006',N'Panos Rigas',        '2017-09-25', 1),
(7,  7,  N'Athens Retail Network',       '45 Patision Street',         N'Athens',       '2106101007', N'Eleni Galani',       '2016-11-08', 1),
(8,  8,  N'Thess Business Agency',       '12 Monastiriou Street',      N'Thessaloniki', '23106101008', N'Kostas Veris',       '2020-01-18', 1),
(9,  9,  N'Volos Coast Hub',             '51 Iasonos Street',          N'Volos',        '242106101009',N'Natasa Kouri',       '2018-07-07', 1),
(10, 10, N'Marousi Corporate Agency',    '120 Kifisias Avenue',        N'Marousi',      '2106101010', N'Dimitra Kelaidou',   '2021-02-22', 1),
(11, 12, N'Larisa Regional Agency',      '9 Papakyriazi Street',       N'Larisa',       '24106101011', N'Giannis Xenos',      '2019-04-12', 1),
(12, 13, N'Piraeus Agency',              '6 Akti Miaouli',             N'Piraeus',      '2106101012', N'Fotini Marini',      '2018-12-03', 1),
(13, 15, N'Patras West Agency',          '73 Agiou Andreou Street',    N'Patras',       '26106101013', N'Andreas Kotsis',     '2020-10-15', 1),
(14, 1,  N'Athens North Agency',         '88 Mesogeion Avenue',        N'Athens',       '2106101014', N'Rena Gika',          '2022-03-11', 1),
(15, 5,  N'Crete South Agency',          '27 25th August Street',      N'Heraklion',    '28106101015', N'Giorgos Kouris',     '2021-07-05', 1);
GO

/* Seed data: vehicles (15 rows) */
INSERT INTO dbo.vehicles (vehicle_id, company_id, agency_id, plate_number, brand, model, vehicle_type, engine_cc, load_capacity_kg, purchase_date, is_active) VALUES
(1,  1,  1,  'KXO-1101', N'Fiat',     N'Doblo',    'VAN',     1600, 750, '2021-01-20', 1),
(2,  2,  2,  'KHI-2202', N'Renault',  N'Clio',     'CAR',     1400, 420, '2020-04-15', 1),
(3,  3,  3,  'NIK-3303', N'Peugeot',  N'Partner',  'VAN',     1500, 700, '2022-02-10', 1),
(4,  4,  4,  'PAT-4404', N'Ford',     N'Transit',  'VAN',     2000, 1200,'2019-08-12', 1),
(5,  5,  5,  'HER-5505', N'Toyota',   N'Yaris',    'CAR',     1300, 350, '2021-06-08', 1),
(6,  6,  6,  'IOA-6606', N'Honda',    N'SH150',    'SCOOTER', 150,  120, '2023-03-01', 1),
(7,  7,  7,  'ATH-7707', N'SYM',      N'Cruisym',  'SCOOTER', 300,  140, '2022-10-19', 1),
(8,  8,  8,  'THE-8808', N'Volkswagen',N'Caddy',   'VAN',     1600, 730, '2021-11-22', 1),
(9,  9,  9,  'VOL-9909', N'Opel',     N'Corsa',    'CAR',     1200, 320, '2020-07-17', 1),
(10, 10, 10, 'MRS-1010', N'Nissan',   N'NV200',    'VAN',     1500, 680, '2023-01-09', 1),
(11, 12, 11, 'LAR-1111', N'Piaggio',  N'Liberty',  'SCOOTER', 125,  90,  '2022-05-14', 1),
(12, 13, 12, 'PIR-1212', N'Citroen',  N'Berlingo', 'VAN',     1600, 760, '2019-12-02', 1),
(13, 15, 13, 'PTW-1313', N'Hyundai',  N'i20',      'CAR',     1200, 300, '2022-08-30', 1),
(14, 1,  14, 'ATN-1414', N'Yamaha',   N'NMAX',     'SCOOTER', 155,  110, '2024-01-18', 1),
(15, 5,  15, 'CRT-1515', N'Peugeot',  N'Expert',   'VAN',     2000, 1100,'2021-09-27', 1);
GO

/* Seed data: couriers (15 rows) */
INSERT INTO dbo.couriers (courier_id, agency_id, vehicle_id, first_name, last_name, phone_number, hire_date, monthly_salary, employment_status) VALUES
(1,  1,  1,  N'Nikos',      N'Antonopoulos', '6945001001', '2021-02-01', 1150.00, 'FULL_TIME'),
(2,  2,  2,  N'Maria',      N'Tsanti',       '6945001002', '2020-05-10', 1080.00, 'FULL_TIME'),
(3,  3,  3,  N'Giannis',    N'Pappas',       '6945001003', '2022-02-21', 1170.00, 'FULL_TIME'),
(4,  4,  4,  N'Kostas',     N'Rallis',       '6945001004', '2019-09-01', 1260.00, 'FULL_TIME'),
(5,  5,  5,  N'Eleni',      N'Vretta',       '6945001005', '2021-07-15', 1020.00, 'FULL_TIME'),
(6,  6,  6,  N'Petros',     N'Kanelis',      '6945001006', '2023-03-15', 890.00,  'PART_TIME'),
(7,  7,  7,  N'Rania',      N'Zerva',        '6945001007', '2022-11-01', 930.00,  'PART_TIME'),
(8,  8,  8,  N'Spyros',     N'Makris',       '6945001008', '2021-12-06', 1180.00, 'FULL_TIME'),
(9,  9,  9,  N'Andreas',    N'Liosis',       '6945001009', '2020-08-12', 980.00,  'FULL_TIME'),
(10, 10, 10, N'Fotini',     N'Karra',        '6945001010', '2023-02-01', 1210.00, 'FULL_TIME'),
(11, 11, 11, N'Dimitris',   N'Zikos',        '6945001011', '2022-06-01', 850.00,  'PART_TIME'),
(12, 12, 12, N'Natasa',     N'Petraki',      '6945001012', '2020-01-15', 1190.00, 'FULL_TIME'),
(13, 13, 13, N'Alexandros', N'Fotiou',       '6945001013', '2022-09-05', 960.00,  'FULL_TIME'),
(14, 14, 14, N'Christina',  N'Meligkou',     '6945001014', '2024-02-01', 820.00,  'PART_TIME'),
(15, 15, 15, N'Manolis',    N'Kritikos',     '6945001015', '2021-10-10', 1250.00, 'FULL_TIME');
GO

/* Seed data: publication_issues (15 rows) */
INSERT INTO dbo.publication_issues (issue_id, publication_id, issue_code, issue_date, page_count, print_quantity, available_quantity, unit_price, return_deadline) VALUES
(1,  1,  'ML-2026-001', '2026-01-02', 48,  18000, 5200, 1.80, '2026-01-10'),
(2,  2,  'CP-2026-003', '2026-01-03', 40,  15000, 4100, 1.60, '2026-01-09'),
(3,  3,  'SP-2026-005', '2026-01-05', 36,  17000, 3900, 1.50, '2026-01-11'),
(4,  4,  'PT-2026-W02', '2026-01-10', 68,   8000, 1600, 3.90, '2026-01-20'),
(5,  5,  'AL-2026-M01', '2026-01-12', 84,   6000, 1450, 4.50, '2026-02-05'),
(6,  6,  'TH-2026-M01', '2026-01-15', 96,   5500, 1200, 5.20, '2026-02-10'),
(7,  7,  'UW-2026-W03', '2026-01-17', 72,   7000, 1750, 3.20, '2026-01-27'),
(8,  8,  'MS-2026-W03', '2026-01-18', 64,   7200, 1680, 4.10, '2026-01-28'),
(9,  9,  'TB-2026-M02', '2026-02-01', 100,  4500,  980, 5.60, '2026-02-25'),
(10, 10, 'CB-2026-015', '2026-01-19', 44,  16000, 4200, 1.90, '2026-01-26'),
(11, 11, 'HS-2026-M02', '2026-02-03', 108,  4200, 1000, 5.80, '2026-02-27'),
(12, 12, 'AR-2026-W05', '2026-02-05', 70,   6900, 1550, 3.70, '2026-02-15'),
(13, 13, 'CW-2026-W05', '2026-02-07', 60,   7600, 1825, 3.50, '2026-02-17'),
(14, 14, 'ID-2026-021', '2026-01-21', 52,  14000, 3600, 2.10, '2026-01-28'),
(15, 15, 'SI-2026-W06', '2026-02-09', 66,   6800, 1490, 3.90, '2026-02-19');
GO

/* Seed data: delivery_runs (15 rows) */
INSERT INTO dbo.delivery_runs (delivery_run_id, courier_id, vehicle_id, agency_id, route_name, start_time, end_time, kilometers_travelled, delivered_orders_count, fuel_cost) VALUES
(1,  1,  1,  1,  N'Athens Center Route A',      '2026-01-03T05:45:00', '2026-01-03T11:20:00', 42.5, 58, 13.20),
(2,  2,  2,  2,  N'Marousi Morning Route',      '2026-01-03T06:00:00', '2026-01-03T10:40:00', 34.2, 46, 9.60),
(3,  3,  3,  3,  N'Thessaloniki Core Route',    '2026-01-04T05:30:00', '2026-01-04T11:05:00', 47.8, 61, 14.50),
(4,  4,  4,  4,  N'Patras East Route',          '2026-01-04T05:40:00', '2026-01-04T12:10:00', 63.4, 71, 18.80),
(5,  5,  5,  5,  N'Heraklion Retail Route',     '2026-01-05T06:10:00', '2026-01-05T10:25:00', 28.7, 39, 8.10),
(6,  6,  6,  6,  N'Ioannina Old Town Route',    '2026-01-05T06:30:00', '2026-01-05T09:10:00', 18.9, 24, 3.20),
(7,  7,  7,  7,  N'Athens Market Route',        '2026-01-06T05:50:00', '2026-01-06T09:45:00', 21.6, 27, 4.10),
(8,  8,  8,  8,  N'Thess Business District',    '2026-01-06T05:35:00', '2026-01-06T10:50:00', 39.8, 48, 11.70),
(9,  9,  9,  9,  N'Volos Seafront Route',       '2026-01-07T06:05:00', '2026-01-07T10:15:00', 25.1, 33, 6.90),
(10, 10, 10, 10, N'Marousi Corporate Route',    '2026-01-07T05:55:00', '2026-01-07T11:00:00', 41.0, 54, 12.40),
(11, 11, 11, 11, N'Larisa Neighborhood Route',  '2026-01-08T06:20:00', '2026-01-08T09:00:00', 16.4, 20, 2.70),
(12, 12, 12, 12, N'Piraeus Port Route',         '2026-01-08T05:25:00', '2026-01-08T10:55:00', 44.3, 56, 13.90),
(13, 13, 13, 13, N'Patras West Commercial',     '2026-01-09T06:15:00', '2026-01-09T10:35:00', 27.9, 37, 7.50),
(14, 14, 14, 14, N'Athens North Express',       '2026-01-09T06:10:00', '2026-01-09T08:50:00', 17.2, 22, 3.00),
(15, 15, 15, 15, N'Crete South Route',          '2026-01-10T05:20:00', '2026-01-10T11:40:00', 66.8, 73, 21.30);
GO

/* Seed data: subscription_orders (15 rows) */
INSERT INTO dbo.subscription_orders (subscription_order_id, customer_id, publication_id, agency_id, start_date, end_date, copies_per_delivery, payment_method, total_amount, order_status) VALUES
(1,  1,  1,  1,  '2026-01-01', '2026-03-31', 1, 'CARD',          162.00, 'ACTIVE'),
(2,  2,  3,  3,  '2026-01-10', '2026-04-10', 1, 'CARD',          135.00, 'ACTIVE'),
(3,  3,  10, 1,  '2026-01-05', '2026-02-28', 4, 'BANK_TRANSFER', 456.00, 'ACTIVE'),
(4,  4,  4,  4,  '2026-02-01', '2026-07-31', 2, 'BANK_TRANSFER', 187.20, 'ACTIVE'),
(5,  5,  5,  5,  '2026-01-15', '2026-06-15', 1, 'PAYPAL',         27.00, 'ACTIVE'),
(6,  6,  14, 7,  '2026-01-01', '2026-01-31', 3, 'CARD',          195.30, 'COMPLETED'),
(7,  7,  11, 11, '2026-02-01', '2026-08-31', 1, 'CARD',           40.60, 'ACTIVE'),
(8,  8,  2,  8,  '2026-01-03', '2026-03-03', 5, 'BANK_TRANSFER', 480.00, 'ACTIVE'),
(9,  9,  9,  9,  '2026-02-01', '2026-05-31', 1, 'PAYPAL',         22.40, 'ACTIVE'),
(10, 10, 8,  10, '2026-01-12', '2026-04-30', 3, 'BANK_TRANSFER', 213.20, 'ACTIVE'),
(11, 11, 6,  6,  '2026-01-20', '2026-07-20', 1, 'CARD',           36.40, 'PAUSED'),
(12, 12, 12, 12, '2026-02-05', '2026-06-05', 2, 'BANK_TRANSFER', 125.80, 'ACTIVE'),
(13, 13, 13, 13, '2026-01-25', '2026-05-25', 1, 'CASH',           56.00, 'ACTIVE'),
(14, 14, 7,  15, '2026-01-15', '2026-04-15', 2, 'BANK_TRANSFER',  83.20, 'ACTIVE'),
(15, 15, 15, 14, '2026-02-01', '2026-07-31', 1, 'CARD',          101.40, 'ACTIVE');
GO

/* Seed data: issue_orders (15 rows) */
INSERT INTO dbo.issue_orders (issue_order_id, customer_id, issue_id, agency_id, order_date, quantity, payment_method, total_amount, order_status) VALUES
(1,  1,  1,  1,  '2026-01-02T08:15:00', 2, 'CARD',          3.60,  'FULFILLED'),
(2,  2,  3,  3,  '2026-01-05T09:10:00', 3, 'CARD',          4.50,  'FULFILLED'),
(3,  3,  10, 1,  '2026-01-19T06:45:00', 8, 'BANK_TRANSFER', 15.20, 'FULFILLED'),
(4,  4,  4,  4,  '2026-01-10T10:30:00', 5, 'BANK_TRANSFER', 19.50, 'FULFILLED'),
(5,  5,  5,  5,  '2026-01-13T12:10:00', 1, 'PAYPAL',         4.50, 'FULFILLED'),
(6,  6,  14, 7,  '2026-01-21T07:40:00', 10,'CARD',          21.00, 'FULFILLED'),
(7,  7,  11, 11, '2026-02-03T11:20:00', 1, 'CARD',           5.80, 'PLACED'),
(8,  8,  2,  8,  '2026-01-03T08:00:00', 12,'BANK_TRANSFER', 19.20, 'FULFILLED'),
(9,  9,  9,  9,  '2026-02-01T13:45:00', 2, 'PAYPAL',        11.20, 'PLACED'),
(10, 10, 8,  10, '2026-01-18T07:55:00', 6, 'BANK_TRANSFER', 24.60, 'FULFILLED'),
(11, 11, 6,  6,  '2026-01-15T10:05:00', 2, 'CARD',          10.40, 'FULFILLED'),
(12, 12, 12, 12, '2026-02-05T09:35:00', 4, 'BANK_TRANSFER', 14.80, 'PLACED'),
(13, 13, 13, 13, '2026-02-07T17:10:00', 3, 'CASH',          10.50, 'FULFILLED'),
(14, 14, 7,  15, '2026-01-17T08:25:00', 5, 'BANK_TRANSFER', 16.00, 'FULFILLED'),
(15, 15, 15, 14, '2026-02-09T09:50:00', 2, 'CARD',           7.80, 'PLACED');
GO

/* Helpful indexes for common joins and lookups. */
CREATE INDEX IX_agencies_company_id ON dbo.agencies(company_id);
CREATE INDEX IX_vehicles_agency_id ON dbo.vehicles(agency_id);
CREATE INDEX IX_couriers_agency_id ON dbo.couriers(agency_id);
CREATE INDEX IX_publications_company_id ON dbo.publications(company_id);
CREATE INDEX IX_publication_issues_publication_id ON dbo.publication_issues(publication_id);
CREATE INDEX IX_delivery_runs_courier_id ON dbo.delivery_runs(courier_id);
CREATE INDEX IX_subscription_orders_customer_id ON dbo.subscription_orders(customer_id);
CREATE INDEX IX_issue_orders_customer_id ON dbo.issue_orders(customer_id);
GO

/* Optional demo queries

SELECT TOP 10 * FROM dbo.customers;
SELECT p.title, i.issue_code, i.issue_date, i.unit_price
FROM dbo.publications p
JOIN dbo.publication_issues i ON i.publication_id = p.publication_id
ORDER BY i.issue_date DESC;

SELECT c.customer_name, so.order_status, p.title, so.total_amount
FROM dbo.subscription_orders so
JOIN dbo.customers c ON c.customer_id = so.customer_id
JOIN dbo.publications p ON p.publication_id = so.publication_id
ORDER BY so.subscription_order_id;
*/