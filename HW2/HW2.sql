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
