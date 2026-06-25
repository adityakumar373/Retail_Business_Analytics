/* Total Sales */

SELECT ROUND(SUM(sales),2) as total_sales
FROM orders;

--Total Profit

SELECT ROUND(SUM(profit),2) as total_profit
FROM orders;

--total orders

SELECT COUNT(DISTINCT order_id) as total_orders
FROM orders;

--total customers
SELECT COUNT(DISTINCT customer_id) as total_customers
FROM orders;

--sales by category

SELECT category, ROUND(SUM(sales),2) as total_sales
FROM orders
GROUP BY category
ORDER BY total_sales DESC;

--profit by category
SELECT category, ROUND(SUM(profit),2) as total_profit
FROM orders
GROUP BY category
ORDER BY total_profit DESC;

/*Insight:
Technology generated the highest profit,
while Furniture had the lowest profit.*/

--sales by region
SELECT region, ROUND(SUM(sales),2) as total_Sales
FROM orders
GROUP BY region
ORDER BY total_sales DESC;

--profit by region
SELECT region, ROUND(SUM(profit),2) as total_profit
FROM orders
GROUP BY region
ORDER BY total_profit DESC;
/*Business Insight:
West region generated the highest profit (~USD 108K).
East ranked second with ~USD 92K.
South generated ~USD 47K.
Central recorded the lowest profit (~USD 40K).*/

--top 10 customers by sales
SELECT customer_name, ROUND(SUM(sales),2) as total_sales
from orders
group by customer_name
order by total_sales desc
limit 10;

--top 10 most profitable products

select product_name,round(sum(profit),2) as total_profit
from orders
group by product_name
order by total_profit desc
limit 10;

--top 10 least profitable products

select product_name,round(sum(profit),2) as total_profit
from orders
group by product_name
order by total_profit
limit 10;

ALTER TABLE orders
ALTER COLUMN order_date TYPE DATE
USING (
    CASE
        WHEN order_date LIKE '%/%'
            THEN TO_DATE(order_date, 'MM/DD/YYYY')
        WHEN order_date LIKE '%-%'
            THEN TO_DATE(order_date, 'MM-DD-YYYY')
    END
);

ALTER TABLE orders
ALTER COLUMN ship_date TYPE DATE
USING (
    CASE
        WHEN ship_date LIKE '%/%'
            THEN TO_DATE(ship_date, 'MM/DD/YYYY')
        WHEN ship_date LIKE '%-%'
            THEN TO_DATE(ship_date, 'MM-DD-YYYY')
    END
);

--Monthly sales record
SELECT
    DATE_TRUNC('month', order_date) AS month,
    ROUND(SUM(sales),2) AS total_sales
FROM orders
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month;

/*Sales generally increased over the four-year period.
November and December consistently recorded the highest sales,
indicating strong year-end seasonal demand.
November 2017 was the best-performing month with sales exceeding USD 118K.*/

SELECT category,ROUND(SUM(sales),2) AS total_sales
FROM orders
GROUP BY category
HAVING SUM(sales) > 500000
ORDER BY total_sales DESC;
/*All three product categories generated sales exceeding USD 500K.
-- HAVING was used to filter aggregated results after GROUP BY.*/

-- product profit classify
SELECT product_name,ROUND(SUM(profit),2) AS total_profit,
    CASE
        WHEN SUM(profit) >= 1000 THEN 'High Profit'
        WHEN SUM(profit) BETWEEN 0 AND 999.99 THEN 'Medium Profit'
        ELSE 'Loss Making'
    END AS profit_category
FROM orders
GROUP BY product_name
ORDER BY total_profit DESC;
/*Out of 1,850 products analyzed, 1,479 products (≈80%) generated
medium profit, 70 products (≈4%) were highly profitable, and
301 products (≈16%) were loss-making.
The business should focus on expanding high-profit products while
reviewing the pricing, discount strategy, or demand for loss-making products.*/

-- CTE - Sales Contribution by Category
WITH category_sales AS (
    SELECT category, SUM(sales) AS total_sales
    FROM orders
    GROUP BY category
)
SELECT category, ROUND(total_sales,2) AS total_sales,
    ROUND( total_sales * 100.0 /(SELECT SUM(total_sales) FROM category_sales),2) AS sales_percentage
FROM category_sales
ORDER BY total_sales DESC;

/*Technology contributed approximately 36% of total sales,
making it the largest revenue-generating category.
Furniture and Office Supplies contributed around 32% each,
indicating a relatively balanced sales distribution.*/

--View Regional Sales Summary
CREATE VIEW regional_sales_summary AS
SELECT region,ROUND(SUM(sales),2) AS total_sales, ROUND(SUM(profit),2) AS total_profit, 
COUNT(DISTINCT order_id) AS total_orders
FROM orders
GROUP BY region;
/*The view provides a reusable summary of regional sales, profit, and order count for reporting and dashboarding.
It eliminates the need to rewrite the same aggregation query.*/

--top 10 customer according to sale
SELECT customer_name, ROUND(SUM(sales),2) AS total_sales,
DENSE_RANK() OVER(ORDER BY SUM(sales) DESC) AS customer_rank
FROM orders
GROUP BY customer_name
ORDER BY customer_rank
LIMIT 10;
/*Sean Miller ranked as the highest-value customer with total purchases of approximately USD 25K.
The top 10 customers represent the most valuable customer segment and could be targeted with loyalty programs, personalized marketing campaigns, or premium services to maximize customer retention and revenue.*/

--Month by Month sales growth
WITH monthly_sales AS 
(SELECT DATE_TRUNC('month', order_date) AS month, ROUND(SUM(sales),2) AS total_sales
FROM orders
GROUP BY DATE_TRUNC('month', order_date)
)

SELECT month, total_sales,
LAG(total_sales) OVER(ORDER BY month) AS previous_month_sales,
ROUND((total_sales - LAG(total_sales) OVER(ORDER BY month))
/LAG(total_sales) OVER(ORDER BY month)* 100,2) AS growth_percentage
FROM monthly_sales
ORDER BY month;
/*Month-over-Month (MoM) analysis revealed significant fluctuations in sales throughout the four-year period. Strong sales growth was consistently observed during September to November, indicating seasonal demand,
while January experienced sharp declines after the holiday season. The highest monthly sales were recorded in November 2017 (USD 118.45K), making it the best-performing month in the dataset.*/