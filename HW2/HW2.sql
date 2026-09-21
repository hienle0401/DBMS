-- ============================================================
-- HW2: Coffee Shop Database (MySQL)
-- Author: Hien Le
-- ============================================================
-- Sections:
--   PART 1: Schema  (tables, primary keys, composite keys, foreign keys)
--   PART 2: Data    (same rows as the source CSV files)
--   PART 3: Queries (Problems 1-10)
-- ============================================================

CREATE DATABASE IF NOT EXISTS coffee_shop;
USE coffee_shop;

-- ============================================================
-- PART 1: SCHEMA
-- ============================================================

-- Drop in reverse dependency order so the script can be re-run.
DROP TABLE IF EXISTS offers;
DROP TABLE IF EXISTS employs;
DROP TABLE IF EXISTS pastries;
DROP TABLE IF EXISTS baristas;
DROP TABLE IF EXISTS shops;

-- Entity: shops (PK: shopID)
CREATE TABLE shops (
    shopID  INT          NOT NULL,
    name    VARCHAR(100) NOT NULL,
    city    VARCHAR(100) NOT NULL,
    PRIMARY KEY (shopID)
);

-- Entity: baristas (PK: baristaID)
CREATE TABLE baristas (
    baristaID        INT          NOT NULL,
    name             VARCHAR(100) NOT NULL,
    experience_level VARCHAR(20)  NOT NULL,
    PRIMARY KEY (baristaID)
);

-- Entity: pastries (PK: pastryID)
CREATE TABLE pastries (
    pastryID INT           NOT NULL,
    name     VARCHAR(100)  NOT NULL,
    category VARCHAR(50)   NOT NULL,
    price    DECIMAL(5, 2) NOT NULL,
    PRIMARY KEY (pastryID)
);

-- Relationship: employs (baristas M:N shops)
-- Composite PK (baristaID, shopID); each column is also a FK.
CREATE TABLE employs (
    baristaID INT NOT NULL,
    shopID    INT NOT NULL,
    PRIMARY KEY (baristaID, shopID),
    FOREIGN KEY (baristaID) REFERENCES baristas (baristaID),
    FOREIGN KEY (shopID)    REFERENCES shops (shopID)
);

-- Relationship: offers (shops M:N pastries)
-- Composite PK (shopID, pastryID); each column is also a FK.
CREATE TABLE offers (
    shopID     INT  NOT NULL,
    pastryID   INT  NOT NULL,
    date_added DATE NOT NULL,
    PRIMARY KEY (shopID, pastryID),
    FOREIGN KEY (shopID)   REFERENCES shops (shopID),
    FOREIGN KEY (pastryID) REFERENCES pastries (pastryID)
);

-- ============================================================
-- PART 2: DATA (mirrors shops.csv, baristas.csv, pastries.csv,
--               employs.csv, offers.csv)
-- Parent tables first so foreign keys are satisfied.
-- ============================================================

INSERT INTO shops (shopID, name, city) VALUES
    (1, 'Bean Counter',       'Seattle'),
    (2, 'Morning Brew',       'Portland'),
    (3, 'Java Junction',      'Austin'),
    (4, 'Daily Grind',        'Chicago'),
    (5, 'Caffeinated Corner', 'Denver'),
    (6, 'The Daily Cup',      'Boston');

INSERT INTO baristas (baristaID, name, experience_level) VALUES
    (1, 'Emma Watson',     'Junior'),
    (2, 'Liam Chen',       'Senior'),
    (3, 'Sofia Rodriguez', 'Mid-Level'),
    (4, 'Noah Kim',        'Senior'),
    (5, 'Olivia Patel',    'Junior'),
    (6, 'Lucas Smith',     'Mid-Level');

INSERT INTO pastries (pastryID, name, category, price) VALUES
    (1,  'Croissant',        'Pastry',    4.50),
    (2,  'Almond Croissant', 'Pastry',    5.50),
    (3,  'Blueberry Muffin', 'Muffin',    3.75),
    (4,  'Bran Muffin',      'Muffin',    3.50),
    (5,  'Cinnamon Roll',    'Bakery',    4.25),
    (6,  'Apple Turnover',   'Pastry',    4.00),
    (7,  'Chocolate Scone',  'Scone',     3.85),
    (8,  'Blueberry Scone',  'Scone',     3.85),
    (9,  'Avocado Toast',    'Breakfast', 7.50),
    (10, 'Breakfast Burrito','Breakfast', 8.50),
    (11, 'Lemon Loaf',       'Cake',      4.00),
    (12, 'Pound Cake',       'Cake',      3.75);

INSERT INTO employs (baristaID, shopID) VALUES
    (1, 1), (2, 2), (3, 3), (4, 4), (5, 5), (6, 6),
    (1, 3), (2, 1), (3, 4), (4, 2), (5, 6), (6, 5);

INSERT INTO offers (shopID, pastryID, date_added) VALUES
    (1, 1,  '2026-01-10'),
    (1, 2,  '2026-01-11'),
    (2, 3,  '2026-01-12'),
    (2, 4,  '2026-01-13'),
    (3, 5,  '2026-01-14'),
    (3, 6,  '2026-01-15'),
    (4, 7,  '2026-01-16'),
    (4, 8,  '2026-01-17'),
    (5, 9,  '2026-01-18'),
    (5, 10, '2026-01-19'),
    (6, 11, '2026-01-20'),
    (6, 12, '2026-01-21');

-- ============================================================
-- PART 3: QUERIES
-- ============================================================

-- 1. Find the average price of pastries for each category from the pastries table.
select category, avg(price) as avg_price
from pastries
group by category;

-- 2. Find the total number of baristas at each experience level from the baristas table.
select experience_level, count(*)
from baristas
group by experience_level;

-- 3. Count the total number of shops located in each city from the shops table.
select city, count(*) as num_shops
from shops
group by city;

-- 4. Find the maximum price among pastries for each category from the pastries table.
select category, max(price) as max_price
from pastries
group by category;

-- 5. Count how many pastries have been added by each shop using the shopID column from the offers table.
select shopID, count(pastryID) as num_pastries
from offers
group by shopID;

-- 6. Find the name, category, and price of any pastry whose price matches the maximum price within its category.
SELECT p.name, p.category, p.price
FROM pastries p
WHERE p.price = ( 	SELECT MAX(p2.price)
					FROM pastries p2
					WHERE p2.category = p.category);


-- 7. Find the unique shop IDs from the offers table that have offered at least one pastry whose price is strictly greater than the overall average price of all pastries.
SELECT DISTINCT shopID
FROM offers
WHERE pastryID IN (	SELECT pastryID
					FROM pastries
                    WHERE price > (	SELECT AVG(price)
									FROM pastries));

-- 8. Find the shop ID and pastry ID for the records in the offers table that have the earliest date_added (minimum date).
SELECT shopID, pastryID
FROM offers
WHERE date_added = (SELECT MIN(date_added)
					FROM offers);

-- 9. Find the shop ID(s) that offer the highest number of pastries, utilizing a subquery to evaluate the maximum count per shop.
SELECT shopID, COUNT(*) as num_pastries
FROM offers
GROUP BY shopID
HAVING COUNT(*) IN (SELECT MAX(cnt)
					FROM (	SELECT COUNT(*)
							AS cnt FROM offers
                            GROUP BY shopID) AS t);

-- 10. Find the names of baristas who work at shops located in 'Seattle' using nested subqueries.
SELECT name
FROM baristas
WHERE baristaID IN (select baristaID
					from employs
                    where shopID in (select shopID
										from shops
                                    where city = "Seattle"));
