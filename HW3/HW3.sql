-- =====================================================================
-- HW3: Global Energy and Power Plants Relational Model (MySQL)
-- Part 1: Schema creation
-- Run this whole script once in MySQL Workbench, then import the CSVs
-- with the Table Data Import Wizard in this order:
--   countries -> operators -> fuel_types -> power_plants
--   -> generation_records -> emission_metrics
-- =====================================================================

-- Start clean so the script can be re-run safely
DROP DATABASE IF EXISTS assignment3_powerplant;
CREATE DATABASE assignment3_powerplant;
USE assignment3_powerplant;

-- ---------------------------------------------------------------------
-- countries: geographic master table (parent of operators, power_plants)
-- ---------------------------------------------------------------------
CREATE TABLE countries (
    countrycode  CHAR(3)      NOT NULL,          -- ISO 3-letter code, e.g. USA
    countryname  VARCHAR(100) NOT NULL,
    continent    VARCHAR(50)  NOT NULL,
    PRIMARY KEY (countrycode)
);

-- ---------------------------------------------------------------------
-- operators: companies/agencies running plants, linked to HQ country
-- ---------------------------------------------------------------------
CREATE TABLE operators (
    operatorid           INT          NOT NULL,
    operatorname         VARCHAR(100) NOT NULL,
    headquarterscountry  CHAR(3)      NOT NULL,
    PRIMARY KEY (operatorid),
    CONSTRAINT fk_operators_country
        FOREIGN KEY (headquarterscountry) REFERENCES countries (countrycode)
        ON UPDATE CASCADE      -- a renamed country code propagates
        ON DELETE RESTRICT     -- cannot delete a country that has operators
);

-- ---------------------------------------------------------------------
-- fuel_types: energy source classification
-- ---------------------------------------------------------------------
CREATE TABLE fuel_types (
    fuelid        INT         NOT NULL,
    fuelcategory  VARCHAR(50) NOT NULL,          -- Renewable / Fossil / Nuclear
    fuelname      VARCHAR(50) NOT NULL,          -- Hydro / Coal / Uranium ...
    PRIMARY KEY (fuelid)
);

-- ---------------------------------------------------------------------
-- power_plants: central entity, references country, operator, fuel type
-- ---------------------------------------------------------------------
CREATE TABLE power_plants (
    plantid         INT          NOT NULL,
    plantname       VARCHAR(100) NOT NULL,
    countrycode     CHAR(3)      NOT NULL,
    operatorid      INT          NOT NULL,
    fuelid          INT          NOT NULL,
    capacitymw      INT          NOT NULL,
    commissionyear  SMALLINT     NOT NULL,
    PRIMARY KEY (plantid),
    CONSTRAINT fk_plants_country
        FOREIGN KEY (countrycode) REFERENCES countries (countrycode)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_plants_operator
        FOREIGN KEY (operatorid) REFERENCES operators (operatorid)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_plants_fuel
        FOREIGN KEY (fuelid) REFERENCES fuel_types (fuelid)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

-- ---------------------------------------------------------------------
-- generation_records: annual output per plant
-- Composite PK (plantid, year); plantid is also a FK.
-- Deleting a plant deletes its history (CASCADE).
-- ---------------------------------------------------------------------
CREATE TABLE generation_records (
    plantid        INT            NOT NULL,
    year           SMALLINT       NOT NULL,
    generationgwh  DECIMAL(12, 2) NOT NULL,
    PRIMARY KEY (plantid, year),
    CONSTRAINT fk_generation_plant
        FOREIGN KEY (plantid) REFERENCES power_plants (plantid)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

-- ---------------------------------------------------------------------
-- emission_metrics: annual CO2 emissions per plant
-- Composite PK (plantid, year); plantid is also a FK.
-- ---------------------------------------------------------------------
CREATE TABLE emission_metrics (
    plantid             INT            NOT NULL,
    year                SMALLINT       NOT NULL,
    co2emissionstonnes  DECIMAL(15, 2) NOT NULL,
    PRIMARY KEY (plantid, year),
    CONSTRAINT fk_emission_plant
        FOREIGN KEY (plantid) REFERENCES power_plants (plantid)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

-- =====================================================================
-- Part II: SQL Queries
-- Note: no table aliases are used. Join conditions use full table names;
-- column labels (AS ...) only rename output columns.
-- Run each query individually (Ctrl+Enter) after the data is imported.
-- =====================================================================

-- QUERY 1: Retrieve the plant name, country name, operator name, fuel category, fuel name, capacity (in MW), 
-- and commission year for all power plants without using table aliases. Sort the results in descending order by capacity.

select plantname, countryname, operatorname, fuelcategory, fuelname, capacitymw, commissionyear
from power_plants 
				inner join countries on power_plants.countrycode = countries.countrycode
                inner join operators on power_plants.operatorid = operators.operatorid
                inner join fuel_types on power_plants.fuelid = fuel_types.fuelid
order by capacitymw desc;
                
	
-- QUERY 2: Retrieve the plant name, country code, calendar year, 
-- and annual generation (in GWh) for all power plants for the year 2024 without using table aliases. 
-- Sort the results in descending order by generation.

select plantname, countrycode, year, generationgwh 
from power_plants
				-- inner join countries on power_plants.countrycode = countries.countrycode (already done above!)
                inner join generation_records on power_plants.plantid = generation_records.plantid
where year = 2024
order by generationgwh desc;

-- QUERY 3: Retrieve the plant name, country code, calendar year, annual generation (in GWh), 
-- and CO2 emissions (in tonnes) for all power plants for the year 2024 without using table aliases. 
-- Sort the results in ascending order by CO2 emissions.

select plantname, countrycode, generation_records.year, generationgwh, co2emissionstonnes
from power_plants
                inner join generation_records on power_plants.plantid = generation_records.plantid
				inner join emission_metrics on generation_records.plantid = emission_metrics.plantid
				                           and generation_records.year = emission_metrics.year
where generation_records.year = 2024
order by co2emissionstonnes;


-- QUERY 4: Write a SQL query using a Common Table Expression (CTE) 
-- to calculate the total cumulative power generation (in GWh) for each operator across all available years without using table aliases. 
-- Retrieve the operator name, headquarters country, and their total generated power, and sort the results in descending order by total generation.

-- cte creation: (for total power generation each operator )
with operator_totals as (
    select operatorid, sum(generationgwh) as total_generation
    from power_plants
    inner join generation_records on power_plants.plantid = generation_records.plantid
    group by operatorid
)
select operatorname, headquarterscountry, total_generation
from operators
inner join operator_totals on operators.operatorid = operator_totals.operatorid
order by total_generation desc;




-- QUERY 5: Write a SQL query using two separate Common Table Expressions 
-- (CTEs)--one to calculate total power generation by country code and another to calculate total CO2 emissions by country code without using table aliases. 
-- Then, join these CTEs with the countries table to display the country name, total generation (in GWh), 
-- and total CO2 emissions (in tonnes). Sort the results in descending order by total generation.

with total_power_generation as (
    select countrycode, sum(generationgwh) as total_generation
    from power_plants 
                      inner join generation_records on power_plants.plantid = generation_records.plantid
    group by countrycode
),
 total_co2_generation as (
     select countrycode, sum(co2emissionstonnes) as total_emission
     from power_plants
                      inner join emission_metrics on power_plants.plantid = emission_metrics.plantid
	 group by countrycode
)

select countryname, total_generation, total_emission
from countries
               inner join total_power_generation on countries.countrycode = total_power_generation.countrycode
               inner join total_co2_generation on countries.countrycode = total_co2_generation.countrycode
order by total_generation desc;