-- CREATING THE TABLES

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');


CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');


CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

-- 1. What is the total amount each customer spent at the restaurant?
SELECT s.customer_id, SUM(me.price) as total_order_amount
FROM sales s
INNER JOIN menu me ON s.product_id=me.product_id
GROUP BY s.customer_id;

-- 2. How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT order_date) as days_visited
FROM sales
GROUP BY customer_id;


-- 3. What was the first item from the menu purchased by each customer?
SELECT s.customer_id, s.order_date, s.product_id
FROM sales s
INNER JOIN
  (SELECT customer_id, MIN(order_date) as first_order
   FROM sales
   GROUP BY customer_id) i
ON s.customer_id = i.customer_id AND s.order_date = i.first_order;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT customer_id, product_id, COUNT(*) as number_of_orders
FROM sales
WHERE product_id IN (SELECT product_id
                     FROM sales
                     GROUP BY product_id
                     ORDER BY COUNT(*) DESC
                     LIMIT 1)
GROUP BY customer_id, product_id;

-- 5. Which item was the most popular for each customer?
SELECT customer_id, product_id as favored_item, number_of_orders
FROM (
  SELECT customer_id, product_id, COUNT(order_date) as number_of_orders, ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY count(order_date) desc) as rank_items
  FROM sales
  GROUP BY customer_id, product_id
  )
WHERE rank_items = 1;

-- 6. Which item was purchased first by the customer after they became a member?
WITH CTE as (SELECT s.customer_id, MIN(s.order_date) as first_order
FROM sales s
INNER JOIN members m ON s.customer_id = m.customer_id
WHERE s.order_date >= m.join_date
GROUP BY s.customer_id
)
SELECT s2.customer_id, s2.product_id, s2.order_date
FROM sales s2
INNER JOIN CTE ON s2.customer_id = CTE.customer_id AND s2.order_date = CTE.first_order;

-- 7. Which item was purchased just before the customer became a member?
WITH CTE as (SELECT s.customer_id, MAX(s.order_date) as last_order
FROM sales s
INNER JOIN members m ON s.customer_id = m.customer_id
WHERE s.order_date < m.join_date
GROUP BY s.customer_id
)
SELECT s2.customer_id, s2.product_id, s2.order_date
FROM sales s2
INNER JOIN CTE ON s2.customer_id = CTE.customer_id AND s2.order_date = CTE.last_order;

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT customer_id, COUNT(*) as number_of_orders, SUM(price) as total_orders
FROM (
  SELECT s.customer_id, s.order_date, s.product_id, me.price
  FROM sales s
  INNER JOIN members m ON s.customer_id = m.customer_id
  INNER JOIN menu me ON s.product_id = me.product_id
  WHERE s.order_date <= m.join_date
)
GROUP BY customer_id;

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT
  s.customer_id,
  SUM(CASE WHEN me.product_name = "sushi" THEN me.price * 20 ELSE me.price * 10 END) as total_points
FROM sales s
INNER JOIN menu me ON s.product_id = me.product_id
GROUP BY s.customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT
  s.customer_id,
  SUM(CASE WHEN s.order_date >= m.join_date AND (JULIANDAY(s.order_date) - JULIANDAY(m.join_date)) < 7 THEN me.price * 20
           WHEN me.product_name = "sushi" THEN me.price*20
           ELSE me.price * 10 END) as total_points
FROM sales s
INNER JOIN menu me ON s.product_id = me.product_id
INNER JOIN members m ON s.customer_id = m.customer_id
WHERE s.order_date < '2021-02-01'
GROUP BY s.customer_id;
