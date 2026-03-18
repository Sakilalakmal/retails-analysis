-- ========================================Data Analysis & Findings=============================================
use retails_database

-- 1 Write a SQL query to retrieve all columns for sales made on '2022-11-05

select * from fact_transaction where sale_date = '2022-11-05'

-- 2 Write a SQL query to retrieve all transactions where the category is 'Clothing' and the quantity sold is more than 4 in the month of Nov-2022

select * 
from fact_transaction 
where category = 'Clothing' 
AND quantity > 4 
 AND sale_date >= '2022-11-01'
  AND sale_date < '2022-12-01';

-- 3 Write a SQL query to calculate the total sales (total_sale) for each category
SELECT
	category,
	SUM(total_sale) AS total_sales,
	COUNT(*) AS transaction_count
FROM fact_transaction
GROUP BY category
ORDER BY SUM(total_sale) DESC

-- 4 Write a SQL query to find the average age of customers who purchased items from the 'Beauty' category

select 
	AVG(cust.age) AS avg_age 
from fact_transaction AS trans
	LEFT JOIN dim_customer AS cust
	ON trans.customer_id = cust.customer_id
	WHERE category = 'Beauty'

-- 5 Write a SQL query to find all transactions where the total_sale is greater than 1000

SELECT * FROM fact_transaction WHERE total_sale > 1000

-- 6 Write a SQL query to find the total number of transactions (transaction_id) made by each gender in each category

SELECT
	cust.gender,
	trans.category,
	count(distinct trans.transactions_id) AS tsction_count
FROM fact_transaction AS trans
	LEFT JOIN dim_customer AS cust
	ON trans.customer_id = cust.customer_id
	GROUP BY cust.gender , trans.category
	ORDER BY tsction_count DESC

-- 7 Write a SQL query to calculate the average sale for each month. Find out best selling month in each year
SELECT *,
	FORMAT(month,'MMM-yyyy') AS formatted
FROM (
	SELECT
		DATETRUNC(MONTH,sale_date) AS month,
		DATETRUNC(YEAR,sale_date) AS year,
		AVG(total_sale) AS avg_sales,
		RANK() OVER(PARTITION BY DATETRUNC(YEAR,sale_date) ORDER BY AVG(total_sale) DESC) AS ranks_sales
	FROM fact_transaction
		GROUP BY DATETRUNC(MONTH,sale_date) , DATETRUNC(YEAR,sale_date)
	) t
		WHERE ranks_sales = 1
		ORDER BY year , month
-- 8 Write a SQL query to find the top 5 customers based on the highest total sales

SELECT * FROM (
	SELECT
		cust.customer_id,
		SUM(fact.total_sale) AS total_sales,
		RANK() OVER(ORDER BY SUM(fact.total_sale) DESC) AS ranks
	FROM fact_transaction AS fact
		LEFT JOIN dim_customer AS cust
		ON fact.customer_id = cust.customer_id
		GROUP BY cust.customer_id
		) t
		WHERE ranks <= 5

-- 9 Write a SQL query to find the number of unique customers who purchased items from each category

SELECT
	category,
	COUNT(distinct customer_id) as unique_customer_count
FROM fact_transaction
	GROUP BY category

--10 Write a SQL query to create each shift and number of orders (Example Morning <12, Afternoon Between 12 & 17, Evening >17)

SELECT 
	CASE WHEN DATEPART(HOUR,sale_time) < 12 THEN 'Morning'
		 WHEN DATEPART(HOUR,sale_time) BETWEEN 12 AND 17 THEN 'Afternoon'
		 WHEN DATEPART(HOUR,sale_time) > 17 THEN 'Evening'
	END AS shift,
	COUNT(distinct transactions_id) AS orders_count
	FROM fact_transaction
	GROUP BY CASE WHEN DATEPART(HOUR,sale_time) < 12 THEN 'Morning'
		 WHEN DATEPART(HOUR,sale_time) BETWEEN 12 AND 17 THEN 'Afternoon'
		 WHEN DATEPART(HOUR,sale_time) > 17 THEN 'Evening'
	END

-- Monthly Revenue Trend (time-series)
SELECT
	YEAR(sale_date) AS year,
	MONTH(sale_date) AS month,
	SUM(total_sale) AS total_sales
FROM fact_transaction
GROUP BY YEAR(sale_date),MONTH(sale_date)
ORDER BY year , month

-- Best-Selling Category

SELECT
	category,
	SUM(quantity) AS selling_units,
	COUNT(distinct transactions_id) AS trsction_count
FROM fact_transaction
GROUP BY category
ORDER BY SUM(quantity) DESC

-- Most Profitable Category

SELECT
	category,
	SUM((price_per_unit - cost) * quantity) AS profit
FROM fact_transaction
GROUP BY category
ORDER BY profit DESC

-- Customer Spending Segmentation

WITH custmr_segments AS (
SELECT
	customer_id,
	SUM(total_sale) AS custmr_sales,
	CASE WHEN SUM(total_sale) > 5000 THEN 'Impresive'
		 WHEN SUM(total_sale) > 1000 AND SUM(total_sale) <= 5000 THEN 'High'
		 WHEN SUM(total_sale) BETWEEN 500 AND 1000 THEN 'Medium'
		 ELSE 'Low'
    END AS custmr_segment
FROM fact_transaction
GROUP BY customer_id
)
SELECT
	custmr_segment,
	COUNT(customer_id) AS customer_count
FROM custmr_segments
GROUP BY custmr_segment

-- Repeat vs One-Time Customers

SELECT 
	segment,
	COUNT(customer_id) AS segmnt_customers
	FROM (
	SELECT
	customer_id,
		CASE WHEN COUNT(*) = 1 THEN 'One-time'
			 ELSE 'Repeat'
		END AS segment,
		COUNT(customer_id) AS custmr_count 
	FROM fact_transaction
	GROUP BY customer_id
	) t 
	GROUP BY segment

-- sales by weekday

SELECT 
	DATENAME(WEEKDAY,sale_date) day_name, 
	SUM(total_sale) AS total_sales 
FROM fact_transaction 
	group by DATENAME(WEEKDAY,sale_date)
	ORDER BY SUM(total_sale) DESC

-- Rank Customers by Total Spending (RANK vs DENSE_RANK)

SELECT
	customer_id,
	SUM(total_sale) AS total_sales,
	RANK() OVER(ORDER BY SUM(total_sale) DESC) AS rank,
	DENSE_RANK() OVER(ORDER BY SUM(total_sale) DESC) AS dense_rank
FROM fact_transaction
GROUP BY customer_id

-- Month-over-Month Growth

SELECT *,
	CASE WHEN prev_month_sale = 0 
		OR prev_month_sale IS NULL 
			THEN NULL
	ELSE CONCAT(CAST
		((total_sales - prev_month_sale)
			* 100 / prev_month_sale 
				AS DECIMAL(18,2) ),'%')
	END	
		AS growth_percentage
FROM (
	SELECT 
		DATETRUNC(YEAR,sale_date) AS sale_year,
		DATETRUNC(MONTH,sale_date) AS sale_month,
		SUM(total_sale) AS total_sales,
		LAG(SUM(total_sale)) 
			OVER(PARTITION BY DATETRUNC(YEAR,sale_date) 
				ORDER BY DATETRUNC(MONTH,sale_date) ASC) 
					AS prev_month_sale
	FROM fact_transaction
		GROUP BY DATETRUNC(YEAR,sale_date) , DATETRUNC(MONTH,sale_date)
	) t

-- Running Total

SELECT
	sale_date,
	SUM(total_sale) AS total_sales,
	SUM(SUM(total_sale)) OVER(ORDER BY sale_date ASC) AS cumulative_total
FROM fact_transaction
	GROUP BY sale_date;

-- What is each customer�s cohort (first purchase month)

WITH month AS (
	SELECT 
		customer_id,
		MIN(sale_date) AS first_date
	FROM fact_transaction
	GROUP BY customer_id
	)
	SELECT
		customer_id,
		FORMAT(first_date,'MMM-yyyy') first_date
	FROM month;

-- How many customers per cohort

WITH month AS (
	SELECT 
		customer_id,
		MIN(sale_date) AS first_date
	FROM fact_transaction
		GROUP BY customer_id
	)
	SELECT
		FORMAT(first_date,'yyyy-MMM') cohort_month,
		COUNT(customer_id) AS customer_count
	FROM month
		GROUP BY FORMAT(first_date,'yyyy-MMM')
		ORDER BY FORMAT(first_date,'yyyy-MMM') ASC

-- Retention: How many customers return each month

WITH first_order_date AS (
	SELECT
		customer_id,
		MIN(sale_date) AS first_order_date
	FROM fact_transaction
		GROUP BY customer_id
	)
	,
	second_cte AS (
	SELECT
		f.customer_id,
		FORMAT(s.first_order_date, 'yyyy-MMM') AS first_order_month,
		FORMAT(f.sale_date,'yyyy-MMM') AS every_month
	FROM fact_transaction AS f
		LEFT JOIN first_order_date AS s
		ON f.customer_id = s.customer_id
	)
	SELECT
		first_order_month,
		every_month,
		COUNT(distinct customer_id) customer_count
	FROM second_cte
		WHERE every_month > first_order_month
		GROUP BY first_order_month,every_month
		ORDER BY first_order_month,every_month

-- Cohort retention rate
-- cohort
-- activity
-- cohort_size
-- final select
-- cohort customers count / total_customers in chort
WITH first_order_date AS (
	SELECT
		customer_id,
		MIN(sale_date) AS first_purchase_date
	FROM fact_transaction
		GROUP BY customer_id
	),
	activity AS (
	SELECT
		f.customer_id,
		FORMAT(fo.first_purchase_date, 'yyyy-MMM') AS cohort_month,
		FORMAT(f.sale_date,'yyyy-MMM') AS activity_month
	FROM fact_transaction AS f
		LEFT JOIN first_order_date AS fo
		ON f.customer_id = fo.customer_id
	),
	cohort_size AS (
	SELECT
		cohort_month,
		COUNT(DISTINCT customer_id) AS cohort_customers
	FROM activity
		GROUP BY cohort_month
	)
	SELECT
		a.cohort_month,
		a.activity_month,
		COUNT(DISTINCT a.customer_id) AS active_customers,
		c.cohort_customers,
		CONCAT(CAST(COUNT(DISTINCT a.customer_id) * 100 / c.cohort_customers AS decimal(18,2)), '%') AS retention_rate
	FROM activity AS a
		LEFT JOIN cohort_size AS c
		ON a.cohort_month = c.cohort_month
		GROUP BY a.cohort_month, a.activity_month, c.cohort_customers
		ORDER BY a.cohort_month, a.activity_month

-- Calculate a 7-day rolling average of total sales based on sale_date

SELECT
	sale_date,
	SUM(total_sale) AS total_sales,
	CAST(AVG(SUM(total_sale)) 
	OVER(ORDER BY sale_date 
		ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS decimal(18,2)) 
			AS rolling_avg_7d
FROM fact_transaction
	GROUP BY sale_date;


-- Calculate the difference between current transaction sales and the average of the previous 3 transactions (per customer)

SELECT *,
	(total_sales - avg_previous_3_transactions) AS sales_difference
 FROM (
SELECT
	customer_id,
	sale_date,
	SUM(total_sale) AS total_sales,
	CAST(AVG(SUM(total_sale)) 
		OVER (PARTITION BY customer_id ORDER BY sale_date 
			ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING
				) AS decimal(18,2)) AS avg_previous_3_transactions
FROM fact_transaction
GROUP BY customer_id, sale_date
) t


--* Identify customers whose spending is accelerating (momentum customers)
--* 👉 These are customers whose recent purchases are higher than their historical average

WITH customer_sales AS (
	SELECT
		customer_id,
		sale_date,
		total_sale,
		AVG(total_sale) OVER(PARTITION BY customer_id ORDER BY sale_date
			ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS historical_avg,
		AVG(total_sale)  OVER(PARTITION BY customer_id ORDER BY sale_date
			ROWS BETWEEN 3 PRECEDING AND CURRENT ROW) AS avg_previous_3_transactions
	FROM fact_transaction
	)
		SELECT
		*
		FROM customer_sales
		WHERE avg_previous_3_transactions > historical_avg


--* Find the top spending customer in each age group, along with their rank inside that age group
WITH customer_total_sales AS (
	SELECT 
		cust.customer_id,
		cust.age,
		SUM(fact.total_sale) AS total_sales,
		COUNT(fact.transactions_id) AS transaction_count
	FROM fact_transaction AS fact
		LEFT JOIN dim_customer AS cust 
		ON fact.customer_id = cust.customer_id
		GROUP BY cust.customer_id, cust.age
	),
	customer_rank AS (
	SELECT
		RANK() 
			OVER(PARTITION BY age ORDER BY total_sales DESC) 
				AS age_group_rank,
		customer_id,
		age,
		transaction_count
	FROM customer_total_sales
	)
	SELECT
		*
	FROM customer_rank
		WHERE age_group_rank = 1

--* Find customers whose last purchase is significantly higher than their previous purchase, and include their age + gender
WITH customer_sales AS (
	SELECT
		customer_id,
		sale_date,
		total_sale,
		LAG(total_sale) OVER(PARTITION BY customer_id ORDER BY sale_date) AS previous_sale,
		ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY sale_date DESC) AS rn
	FROM fact_transaction
	),
	sale_difference AS (
	SELECT 
		customer_id,
		sale_date,
		total_sale,
		previous_sale,
		rn,
		total_sale - previous_sale AS sale_difference
	FROM customer_sales
		WHERE rn = 1
	)
	SELECT
		cs.customer_id,
		cs.sale_date,
		cs.total_sale,
		cs.previous_sale,
		cs.sale_difference,
		cust.age,
		cust.gender
	FROM sale_difference AS cs
		LEFT JOIN dim_customer AS cust
		ON cs.customer_id = cust.customer_id
		WHERE cs.total_sale > cs.previous_sale * 1.5;