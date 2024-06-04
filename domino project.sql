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
    COUNT(order_id) orders_by_hour
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
    GROUP BY orders.order_date) AS average_pf_pizza_ordered_perday ;

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
            pizzassssss
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