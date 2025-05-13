create database domino;
use domino;
CREATE TABLE orders (
    order_id INT NOT NULL,
    order_date DATE NOT NULL,
    order_time TIME NOT NULL,
    PRIMARY KEY (order_id)
);

CREATE TABLE domino.order_details (
    order_details_id INT NOT NULL,
    order_id INT NOT NULL,
    pizza_id TEXT NOT NULL,
    quantity TEXT NOT NULL,
    PRIMARY KEY (order_details_id)
);


-- QUESTIONS 

-- Retrieve the total number of orders placed.
SELECT 
    COUNT(order_id) AS total_orders
FROM
    orders;
-- SELECT COUNT(order_id) AS t_o FROM order_details;

-- Calculate the total revenue generated from pizza sales
SELECT 
    ROUND(SUM(order_details.quantity * pizzas.price),
            2)
FROM
    order_details
        JOIN
    pizzas ON pizzas.pizza_id = order_details.pizza_id;

-- Identify the highest-priced pizza.
SELECT 
    pizza_types.name, pizzas.price
FROM
    pizza_types
        JOIN
    pizzas ON pizzas.pizza_type_id = pizza_types.pizza_type_id
ORDER BY pizzas.price DESC
LIMIT 1; 
-- OR
SELECT 
    pizza_types.name, pizzas.price
FROM
    pizzas
        JOIN
    pizza_types ON pizzas.pizza_type_id = pizza_types.pizza_type_id
WHERE
    pizzas.price = (SELECT 
            MAX(price)
        FROM
            pizzas);
 
-- Identify the most common pizza size ordered.
SELECT 
    pizzas.size, COUNT(order_details.quantity) AS order_count
FROM
    pizzas
        JOIN
    order_details ON pizzas.pizza_id = order_details.pizza_id
GROUP BY pizzas.size
ORDER BY order_count DESC;

-- List the top 5 most ordered pizza types along with their quantities.

SELECT 
    pizza_types.name,
    SUM(order_details.quantity) AS pizza_quantity
FROM
    pizza_types
        JOIN
    pizzas ON pizza_types.pizza_type_id = pizzas.pizza_type_id
        JOIN
    order_details ON order_details.pizza_id = pizzas.pizza_id
GROUP BY pizza_types.name
ORDER BY pizza_quantity DESC
LIMIT 5;

-- Join the necessary tables to find the total quantity of each pizza category ordered.
use domino;
SELECT 
    SUM(order_details.quantity) AS category_quantity,
    pizza_types.category
FROM
    pizzas
        JOIN
    pizza_types ON pizzas.pizza_type_id = pizza_types.pizza_type_id
        JOIN
    order_details ON pizzas.pizza_id = order_details.pizza_id
GROUP BY pizza_types.category
ORDER BY category_quantity DESC;

-- Determine the distribution of orders by hour of the day.
SELECT 
    HOUR(order_time) AS hour_of_the_day,
    COUNT(order_id) AS orders_by_hour
FROM
    orders
GROUP BY hour_of_the_day;

-- Join relevant tables to find the category-wise distribution of pizzas.
SELECT 
    category, COUNT(name)
FROM
    pizza_types
GROUP BY category;

-- Group the orders by date and calculate the average number of pizzas ordered per day.
SELECT 
    ROUND(AVG(pizza_ordered_perday), 3) 
FROM
    (SELECT 
        orders.order_date,
            SUM(order_details.quantity) AS pizza_ordered_perday
    FROM
        orders
    JOIN order_details ON orders.order_id = order_details.order_id
    GROUP BY orders.order_date) AS average_pf_pizza_ordered_perday;

-- Determine the top 3 most ordered pizza types based on revenue.
SELECT 
    pizza_types.name,
    ROUND(SUM(order_details.quantity * pizzas.price),
            0) AS revenue_per_pizza
FROM
    pizza_types
        JOIN
    pizzas ON pizzas.pizza_type_id = pizza_types.pizza_type_id
        JOIN
    order_details ON order_details.pizza_id = pizzas.pizza_id
GROUP BY pizza_types.name
ORDER BY revenue_per_pizza DESC
LIMIT 3;

-- Calculate the percentage contribution of each pizza category to total revenue.
SELECT 
    pizza_types.category,
    (SUM(pizzas.price * order_details.quantity) / (SELECT 
            SUM(pizzas.price * order_details.quantity) AS total_revenue
        FROM
            pizzas
                JOIN
            order_details ON pizzas.pizza_id = order_details.pizza_id)) * 100 AS percentage_contribution_of_each_pizza_category
FROM
    pizza_types
        JOIN
    pizzas ON pizzas.pizza_type_id = pizza_types.pizza_type_id
        JOIN
    order_details ON order_details.pizza_id = pizzas.pizza_id
GROUP BY pizza_types.category
ORDER BY percentage_contribution_of_each_pizza_category DESC;

-- Analyze the cumulative revenue generated over time.
use domino;
select order_date, sum(revenue_perday) over (order by order_date) as cumulative_revenue from
(select orders.order_date, sum(pizzas.price * order_details.quantity) as revenue_perday
from order_details join pizzas 
on order_details.pizza_id = pizzas.pizza_id
join orders on orders.order_id = order_details.order_id
group by orders.order_date) as sales;

-- Determine the top 3 most ordered pizza types based on revenue for each pizza category.
select name, revenue_on_category_and_name from  
(select category, name, revenue_on_category_and_name, rank() over(partition by category order by revenue_on_category_and_name desc) as rn
from 
(select pizza_types.category, pizza_types.name, sum(order_details.quantity * pizzas.price) as revenue_on_category_and_name 
from pizzas join pizza_types 
on pizzas.pizza_type_id = pizza_types.pizza_type_id 
join order_details on pizzas.pizza_id = order_details.pizza_id 
group by pizza_types.category, pizza_types.name) as a) as b 
where rn <= 3;

-- Which day of the week generates the highest average revenue?
SELECT 
    DAYNAME(order_date) AS day_of_week,
    ROUND(AVG(daily_revenue), 2) AS avg_revenue
FROM (
    SELECT 
        order_date,
        SUM(pizzas.price * order_details.quantity) AS daily_revenue
    FROM 
        orders
    JOIN order_details ON orders.order_id = order_details.order_id
    JOIN pizzas ON order_details.pizza_id = pizzas.pizza_id
    GROUP BY order_date
) AS daily_sales
GROUP BY day_of_week
ORDER BY avg_revenue DESC;

-- What is the week-over-week revenue growth?
WITH weekly_revenue AS (
    SELECT 
        YEAR(order_date) AS yr,
        WEEK(order_date) AS wk,
        SUM(pizzas.price * order_details.quantity) AS revenue
    FROM orders
    JOIN order_details ON orders.order_id = order_details.order_id
    JOIN pizzas ON order_details.pizza_id = pizzas.pizza_id
    GROUP BY YEAR(order_date), WEEK(order_date)
),
revenue_growth AS (
    SELECT *,
        LAG(revenue) OVER (ORDER BY yr, wk) AS previous_week_revenue
    FROM weekly_revenue
)
SELECT 
    yr, wk,
    revenue,
    previous_week_revenue,
    ROUND(((revenue - previous_week_revenue) / previous_week_revenue) * 100, 2) AS percentage_growth
FROM revenue_growth
WHERE previous_week_revenue IS NOT NULL;

-- What are the top 3 revenue-generating hours for each day of the week?
WITH hourly_sales AS (
    SELECT 
        DAYNAME(order_date) AS day_of_week,
        HOUR(order_time) AS hour,
        SUM(order_details.quantity * pizzas.price) AS revenue
    FROM orders
    JOIN order_details ON orders.order_id = order_details.order_id
    JOIN pizzas ON order_details.pizza_id = pizzas.pizza_id
    GROUP BY day_of_week, hour
),
ranked_sales AS (
    SELECT *,
        RANK() OVER (PARTITION BY day_of_week ORDER BY revenue DESC) AS rk
    FROM hourly_sales
)
SELECT day_of_week, hour, revenue
FROM ranked_sales
WHERE rk <= 3;

-- What is the average revenue on holidays versus non-holidays?
--(Assume weekends as holidays for this query)
WITH daily_revenue AS (
    SELECT 
        order_date,
        SUM(order_details.quantity * pizzas.price) AS revenue,
        CASE 
            WHEN DAYOFWEEK(order_date) IN (1, 7) THEN 'Holiday'
            ELSE 'Non-Holiday'
        END AS day_type
    FROM orders
    JOIN order_details ON orders.order_id = order_details.order_id
    JOIN pizzas ON order_details.pizza_id = pizzas.pizza_id
    GROUP BY order_date
)
SELECT day_type, ROUND(AVG(revenue), 2) AS avg_daily_revenue
FROM daily_revenue
GROUP BY day_type;

-- How many customers (orders) placed orders on multiple different days?
-- (Assumes one order = one customer due to lack of customer ID)

WITH order_days AS (
    SELECT order_id, COUNT(DISTINCT order_date) AS days_active
    FROM orders
    GROUP BY order_id
)
SELECT COUNT(*) AS repeat_order_customers
FROM order_days
WHERE days_active > 1;

-- How does each day's revenue rank compared to all previous days?

WITH daily_revenue AS (
    SELECT 
        order_date,
        Round(SUM(order_details.quantity * pizzas.price),2) AS total_revenue
    FROM orders
    JOIN order_details ON orders.order_id = order_details.order_id
    JOIN pizzas ON order_details.pizza_id = pizzas.pizza_id
    GROUP BY order_date
)
SELECT 
    order_date,
    total_revenue,
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM daily_revenue;

-- Flag orders as ‘High’, ‘Medium’, or ‘Low’ based on their revenue contribution compared to other orders.

WITH order_revenue AS (
    SELECT 
        orders.order_id,
        SUM(order_details.quantity * pizzas.price) AS order_total
    FROM orders
    JOIN order_details ON orders.order_id = order_details.order_id
    JOIN pizzas ON pizzas.pizza_id = order_details.pizza_id
    GROUP BY orders.order_id
),
ranked_orders AS (
    SELECT 
        order_id,
        order_total,
        NTILE(4) OVER (ORDER BY order_total) AS quartile
    FROM order_revenue
)
SELECT 
    order_id,
    order_total,
    CASE 
        WHEN quartile = 4 THEN 'High'
        WHEN quartile = 3 THEN 'Medium'
        ELSE 'Low'
    END AS revenue_category
FROM ranked_orders;


-- What is the 7-day rolling average revenue?

WITH daily_revenue AS (
    SELECT 
        order_date,
        SUM(order_details.quantity * pizzas.price) AS daily_total
    FROM orders
    JOIN order_details ON orders.order_id = order_details.order_id
    JOIN pizzas ON pizzas.pizza_id = order_details.pizza_id
    GROUP BY order_date
)
SELECT 
    order_date,
    daily_total,
    ROUND(AVG(daily_total) OVER (ORDER BY order_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 2) AS rolling_avg_7day
FROM daily_revenue;

-- What is the month-on-month revenue change for each pizza category?

WITH monthly_category_sales AS (
    SELECT 
        pizza_types.category,
        DATE_FORMAT(orders.order_date, '%Y-%m') AS month,
        SUM(order_details.quantity * pizzas.price) AS total_revenue
    FROM orders
    JOIN order_details ON orders.order_id = order_details.order_id
    JOIN pizzas ON order_details.pizza_id = pizzas.pizza_id
    JOIN pizza_types ON pizzas.pizza_type_id = pizza_types.pizza_type_id
    GROUP BY category, month
),
revenue_change AS (
    SELECT *,
        LAG(total_revenue) OVER (PARTITION BY category ORDER BY month) AS previous_month_revenue
    FROM monthly_category_sales
)
SELECT 
    category,
    month,
    total_revenue,
    previous_month_revenue,
    ROUND(((total_revenue - previous_month_revenue) / previous_month_revenue) * 100, 2) AS mom_growth
FROM revenue_change
WHERE previous_month_revenue IS NOT NULL;
