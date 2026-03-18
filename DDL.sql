-- create retail database
CREATE DATABASE retails_database

-- use database
USE retails_database

-- create table
IF OBJECT_ID('retails','U') IS NOT NULL
DROP TABLE retails;
GO
CREATE TABLE retails 
		(
			transactions_id	INT PRIMARY KEY,
			sale_date	DATE,
			sale_time	TIME,
			customer_id	INT,
			gender	VARCHAR(10),
			age	INT,
			category NVARCHAR(30),	
			quantiy	INT,
			price_per_unit DECIMAL,	
			cogs	DECIMAL,
			total_sale DECIMAL

		)

-- create customer table
CREATE TABLE customers 
		(
			customer_id INT PRIMARY KEY,
			gender VARCHAR(10),
			age INT
		)
-- DATA INSERT INTO TABLE (BULK INSERT)
        --  load data into retails 
        PRINT '>> Truncating Table: retails ';
        TRUNCATE TABLE retails ;

        PRINT '>> Inserting Data Into: retails ';
        BULK INSERT retails 
        FROM 'D:\DE-DA\retails-data-analysis\retails.csv'
              WITH (
              FIRSTROW = 2,
              FIELDTERMINATOR = ',',
              TABLOCK
           );

-- CHECK DATA
SELECT * FROM retails

SELECT COUNT(*) FROM retails
WHERE quantiy IS NULL
  AND price_per_unit IS NULL
  AND cogs IS NULL
  AND total_sale IS NULL;

DELETE FROM retails
WHERE quantiy IS NULL
  AND price_per_unit IS NULL
  AND cogs IS NULL
  AND total_sale IS NULL;

UPDATE retails
SET cogs = price_per_unit * 0.6;

-- data quality check
SELECT distinct gender FROM retails

-- checking for unwanted space
SELECT * FROM retails where category != TRIM(category)

-- checking any null
SELECT
	distinct category
FROM retails

-- checking duplicate transaction_id
SELECT COUNT(*) counts FROM retails GROUP BY transactions_id HAVING COUNT(*) > 1

-- invalid age
SELECT * FROM retails where age > 100

-- looking for invalid total_sale
SELECT * FROM retails WHERE quantiy * price_per_unit != total_sale

-- looking for invalid cogs
SELECT * FROM retails WHERE cogs > price_per_unit


-- INSERT DATA
TRUNCATE TABLE customers
	INSERT INTO customers (customer_id, gender, age)
	SELECT 
		customer_id,
		MAX(gender) AS gender,
		MAX(age) AS age
	FROM retails
	GROUP BY customer_id;

-- final clean retails
CREATE OR ALTER VIEW fact_transaction AS
SELECT
    transactions_id,
    customer_id,
    category,
    quantiy AS quantity,
    price_per_unit,
    cogs AS cost,
    total_sale,
    sale_date,
    sale_time
FROM retails;

select * from fact_transaction

-- final customer view

CREATE OR ALTER VIEW dim_customer AS 
SELECT
	customer_id,
	gender,
	age
FROM customers

             ------- check customer view -------
			 SELECT * FROM  dim_customer