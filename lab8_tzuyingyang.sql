-- ALY6600 Lab 8: Common Table Expressions (BigQuery, Sakila)

-- =====================================================================
-- Session settings: default project and dataset for unqualified tables
-- =====================================================================
SET @@dataset_project_id = 'sakila-aly6600';
SET @@dataset_id = 'sakila';


-- =====================================================================
-- Task 1: Single CTE
-- Customers whose total spending exceeds the average customer total
-- =====================================================================
WITH customer_totals AS (
  SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    SUM(p.amount) AS total_spend
  FROM customer AS c
  JOIN payment AS p
    ON c.customer_id = p.customer_id
  GROUP BY c.customer_id, c.first_name, c.last_name
)
SELECT
  customer_id,
  first_name,
  last_name,
  ROUND(total_spend, 2) AS total_spend
FROM customer_totals
WHERE total_spend > (SELECT AVG(total_spend) FROM customer_totals)
ORDER BY total_spend DESC;


-- =====================================================================
-- Task 2: Chained CTEs
-- Top five cities by number of above-average-spending customers,
-- with each city's total revenue from those customers
-- =====================================================================
WITH customer_totals AS (
  -- Step 1: total spend per customer
  SELECT
    customer_id,
    SUM(amount) AS total_spend
  FROM payment
  GROUP BY customer_id
),
above_avg_customers AS (
  -- Step 2: keep only customers above the average total
  SELECT
    customer_id,
    total_spend
  FROM customer_totals
  WHERE total_spend > (SELECT AVG(total_spend) FROM customer_totals)
),
customer_cities AS (
  -- Step 3: join customer -> address -> city
  SELECT
    a.customer_id,
    a.total_spend,
    ci.city_id,
    ci.city
  FROM above_avg_customers AS a
  JOIN customer AS c
    ON a.customer_id = c.customer_id
  JOIN address AS ad
    ON c.address_id = ad.address_id
  JOIN city AS ci
    ON ad.city_id = ci.city_id
)
-- Final step: aggregate by city, rank, keep the top five
SELECT
  city,
  COUNT(customer_id)         AS above_avg_customers,
  ROUND(SUM(total_spend), 2) AS total_revenue,
  RANK() OVER (
    ORDER BY COUNT(customer_id) DESC, SUM(total_spend) DESC
  ) AS city_rank
FROM customer_cities
GROUP BY city_id, city
ORDER BY city_rank
LIMIT 5;
