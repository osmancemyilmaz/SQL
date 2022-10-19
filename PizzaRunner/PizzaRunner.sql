-- CREATING THE EXISTING TABLES

DROP TABLE IF EXISTS runners;
CREATE TABLE runners (
  "runner_id" INTEGER,
  "registration_date" DATE
);
INSERT INTO runners
  ("runner_id", "registration_date")
VALUES
  (1, '2021-01-01'),
  (2, '2021-01-03'),
  (3, '2021-01-08'),
  (4, '2021-01-15');


DROP TABLE IF EXISTS customer_orders;
CREATE TABLE customer_orders (
  "order_id" INTEGER,
  "customer_id" INTEGER,
  "pizza_id" INTEGER,
  "exclusions" VARCHAR(4),
  "extras" VARCHAR(4),
  "order_time" TIMESTAMP
);

INSERT INTO customer_orders
  ("order_id", "customer_id", "pizza_id", "exclusions", "extras", "order_time")
VALUES
  ('1', '101', '1', '', '', '2020-01-01 18:05:02'),
  ('2', '101', '1', '', '', '2020-01-01 19:00:52'),
  ('3', '102', '1', '', '', '2020-01-02 23:51:23'),
  ('3', '102', '2', '', NULL, '2020-01-02 23:51:23'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '2', '4', '', '2020-01-04 13:23:46'),
  ('5', '104', '1', 'null', '1', '2020-01-08 21:00:29'),
  ('6', '101', '2', 'null', 'null', '2020-01-08 21:03:13'),
  ('7', '105', '2', 'null', '1', '2020-01-08 21:20:29'),
  ('8', '102', '1', 'null', 'null', '2020-01-09 23:54:33'),
  ('9', '103', '1', '4', '1, 5', '2020-01-10 11:22:59'),
  ('10', '104', '1', 'null', 'null', '2020-01-11 18:34:49'),
  ('10', '104', '1', '2, 6', '1, 4', '2020-01-11 18:34:49');


DROP TABLE IF EXISTS runner_orders;
CREATE TABLE runner_orders (
  "order_id" INTEGER,
  "runner_id" INTEGER,
  "pickup_time" VARCHAR(19),
  "distance" VARCHAR(7),
  "duration" VARCHAR(10),
  "cancellation" VARCHAR(23)
);

INSERT INTO runner_orders
  ("order_id", "runner_id", "pickup_time", "distance", "duration", "cancellation")
VALUES
  ('1', '1', '2020-01-01 18:15:34', '20km', '32 minutes', ''),
  ('2', '1', '2020-01-01 19:10:54', '20km', '27 minutes', ''),
  ('3', '1', '2020-01-03 00:12:37', '13.4km', '20 mins', NULL),
  ('4', '2', '2020-01-04 13:53:03', '23.4', '40', NULL),
  ('5', '3', '2020-01-08 21:10:57', '10', '15', NULL),
  ('6', '3', 'null', 'null', 'null', 'Restaurant Cancellation'),
  ('7', '2', '2020-01-08 21:30:45', '25km', '25mins', 'null'),
  ('8', '2', '2020-01-10 00:15:02', '23.4 km', '15 minute', 'null'),
  ('9', '2', 'null', 'null', 'null', 'Customer Cancellation'),
  ('10', '1', '2020-01-11 18:50:20', '10km', '10minutes', 'null');


DROP TABLE IF EXISTS pizza_names;
CREATE TABLE pizza_names (
  "pizza_id" INTEGER,
  "pizza_name" TEXT
);
INSERT INTO pizza_names
  ("pizza_id", "pizza_name")
VALUES
  (1, 'Meatlovers'),
  (2, 'Vegetarian');


DROP TABLE IF EXISTS pizza_recipes;
CREATE TABLE pizza_recipes (
  "pizza_id" INTEGER,
  "toppings" TEXT
);
INSERT INTO pizza_recipes
  ("pizza_id", "toppings")
VALUES
  (1, '1, 2, 3, 4, 5, 6, 8, 10'),
  (2, '4, 6, 7, 9, 11, 12');


DROP TABLE IF EXISTS pizza_toppings;
CREATE TABLE pizza_toppings (
  "topping_id" INTEGER,
  "topping_name" TEXT
);
INSERT INTO pizza_toppings
  ("topping_id", "topping_name")
VALUES
  (1, 'Bacon'),
  (2, 'BBQ Sauce'),
  (3, 'Beef'),
  (4, 'Cheese'),
  (5, 'Chicken'),
  (6, 'Mushrooms'),
  (7, 'Onions'),
  (8, 'Pepperoni'),
  (9, 'Peppers'),
  (10, 'Salami'),
  (11, 'Tomatoes'),
  (12, 'Tomato Sauce');

-- CLEANING DATA
UPDATE customer_orders
SET exclusions = CASE exclusions WHEN 'null' THEN NULL WHEN '' THEN NULL ELSE exclusions END,
    extras = CASE extras WHEN 'null' THEN NULL WHEN '' THEN NULL ELSE extras END;

UPDATE runner_orders
SET pickup_time = CASE pickup_time WHEN 'null' THEN NULL ELSE pickup_time END,
    distance = CASE distance WHEN 'null' THEN NULL ELSE distance END,
    duration = CASE duration WHEN 'null' THEN NULL ELSE duration END,
    cancellation = CASE cancellation WHEN 'null' THEN NULL WHEN '' THEN NULL ELSE cancellation END;

ALTER TABLE runner_orders RENAME TO runner_orders_old;
CREATE TABLE runner_orders AS
  SELECT
    order_id,
	  runner_id,
	  pickup_time,
	  CASE WHEN distance like '%km' THEN TRIM(distance, 'km')
	    ELSE distance END as distance,
	  CASE WHEN duration like '%minutes' THEN TRIM(duration, 'minutes')
	    WHEN duration like '%mins' then trim(duration, 'mins')
	    WHEN duration like '%minute' THEN TRIM(duration, 'minute')
	    ELSE duration END as duration,
	  cancellation
  FROM runner_orders_old;

DROP TABLE IF EXISTS runner_orders_old;
ALTER TABLE runner_orders RENAME TO runner_orders_old;
CREATE TABLE runner_orders (
  "order_id" INTEGER,
  "runner_id" INTEGER,
  "pickup_time" TIMESTAMP,
  "distance" INTEGER,
  "duration" INTEGER,
  "cancellation" VARCHAR(23)
);

INSERT INTO runner_orders (order_id, runner_id, pickup_time, distance, duration, cancellation)
SELECT order_id, runner_id, pickup_time, distance, duration, cancellation
FROM runner_orders_old;

DROP TABLE IF EXISTS runner_orders_old;

-- A. PIZZA METRICS
-- 1. How many pizzas were ordered?
SELECT COUNT(order_id) as number_of_pizzas
FROM customer_orders;

-- 2. How many unique customer orders were made?
SELECT COUNT(DISTINCT order_id) as number_of_orders
FROM customer_orders;

-- 3. How many successful orders were delivered by each runner?
SELECT runner_id, COUNT(order_id) as number_of_orders
FROM runner_orders
WHERE cancellation IS NULL
GROUP BY runner_id;

-- 4. How many of each type of pizza was delivered?
SELECT c.pizza_id, COUNT(c.order_id) as number_of_pizzas
FROM customer_orders c
LEFT JOIN runner_orders r ON c.order_id=r.order_id
WHERE r.cancellation IS NULL
GROUP BY c.pizza_id;

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT c.customer_id, p.pizza_name, COUNT(c.order_id) as number_of_pizzas
FROM customer_orders c
LEFT JOIN pizza_names p ON c.pizza_id=p.pizza_id
GROUP BY c.customer_id, p.pizza_name;

-- 6. What was the maximum number of pizzas delivered in a single order?
SELECT c.order_id, COUNT(c.pizza_id) as number_of_pizzas
FROM customer_orders c
LEFT JOIN runner_orders r ON c.order_id=r.order_id
WHERE r.cancellation IS NULL
GROUP BY c.order_id
ORDER BY COUNT(c.pizza_id) DESC
LIMIT 1;

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT c.customer_id,
       SUM(CASE WHEN (exclusions IS NOT NULL) or (extras IS NOT NULL ) THEN 1 ELSE 0 END) as at_least_one_change,
       SUM(CASE WHEN (exclusions IS NULL) and (extras IS NULL ) THEN 1 ELSE 0 END) as no_change
FROM customer_orders c
LEFT JOIN runner_orders r ON c.order_id=r.order_id
WHERE r.cancellation IS NULL
GROUP BY c.customer_id;

-- 8. How many pizzas were delivered that had both exclusions and extras?
SELECT COUNT() as number_of_pizzas
FROM customer_orders c
LEFT JOIN runner_orders r ON c.order_id=r.order_id
WHERE r.cancellation IS NULL and c.exclusions IS NOT NULL and c.extras IS NOT NULL;

-- 9. What was the total volume of pizzas ordered for each hour of the day?
SELECT STRFTIME('%H', order_time) as hour, COUNT() as number_of_pizzas
FROM customer_orders
GROUP BY STRFTIME('%H', order_time)
ORDER BY STRFTIME('%H', order_time);

-- 10. What was the volume of orders for each day of the week?
SELECT STRFTIME('%w', order_time) as day_of_week, COUNT() as number_of_pizzas
FROM customer_orders
GROUP BY STRFTIME('%w', order_time)
ORDER BY STRFTIME('%w', order_time);

-- B. RUNNER AND CUSTOMER EXPERIENCE

-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT STRFTIME('%W', registration_date) as week, COUNT() as runners
FROM runners
GROUP BY STRFTIME('%W', registration_date)
ORDER BY STRFTIME('%W', registration_date);

-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
SELECT r.runner_id, ROUND(AVG((JULIANDAY(r.pickup_time) - JULIANDAY(c.order_time)) * 1440),1) as minutes
FROM runner_orders r
LEFT JOIN customer_orders c ON c.order_id=r.order_id
WHERE r.cancellation IS NULL
GROUP BY r.runner_id;

-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
WITH CTE AS(
SELECT c.order_id, COUNT(c.pizza_id) as number_of_pizza, ROUND(AVG((JULIANDAY(r.pickup_time) - JULIANDAY(c.order_time)) * 1440),1) as minutes
FROM customer_orders c
LEFT JOIN runner_orders r ON c.order_id=r.order_id
WHERE r.cancellation IS NULL
GROUP BY c.order_id)
SELECT number_of_pizza, minutes
FROM CTE
GROUP BY number_of_pizza;

-- 4. What was the average distance travelled for each customer?
SELECT c.customer_id, ROUND(AVG(r.distance),1) as average_distance
FROM customer_orders c
LEFT JOIN runner_orders r ON c.order_id=r.order_id
WHERE r.cancellation IS NULL
GROUP BY c.customer_id;

-- 5. What was the difference between the longest and shortest delivery times for all orders?
SELECT max-min as difference_longest_shortest
FROM
  (
  SELECT MAX(duration+prep_time) as max, MIN(duration+prep_time) as min
  FROM
    (
    SELECT c.order_id, AVG(r.duration) as duration, AVG(ROUND((JULIANDAY(r.pickup_time) - JULIANDAY(c.order_time))*1440,1)) as prep_time
    FROM customer_orders c
    LEFT JOIN runner_orders r ON c.order_id=r.order_id
    GROUP BY c.order_id
    )
  );

-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT runner_id, order_id, round((distance*60/duration),2) as speed
FROM runner_orders
WHERE cancellation IS NULL;

-- 7. What is the successful delivery percentage for each runner?
SELECT runner_id, ((total_success_delivery * 100) / total_delivery)as success_percentage
FROM
  (
  SELECT
    runner_id,
    SUM(CASE WHEN cancellation IS NULL THEN 1 ELSE 0 END) as total_success_delivery,
    COUNT() as total_delivery
  FROM runner_orders
  GROUP BY runner_id
  );

-- C. INGREDIENT OPTIMISATION

-- 1. What are the standard ingredients for each pizza?
WITH ssvrec(i, l, c, r) AS (
  SELECT
    pizza_id,
	  '',-- Forcing a space for vLength
    toppings || ', ',
		'' -- Forcing a space at the end of ssvCol removes complicated checking later
  FROM pizza_recipes
  WHERE 1
  UNION ALL
  SELECT i,
    INSTR( c, ', ' ) AS vLength,
    SUBSTR( c, INSTR( c, ', ' ) + 1) AS vRemainder,
    TRIM(SUBSTR( c, 1, INSTR( c, ', ' ) - 1) ) AS vSSV
  FROM ssvrec
  WHERE INSTR( c, ', ' ) > 0
  )
SELECT p.pizza_id, CAST(s.r as INT) as toppings, t.topping_name
FROM ssvrec s
LEFT JOIN pizza_recipes p ON s.i = p.pizza_id
LEFT JOIN pizza_toppings t ON s.r = t.topping_id
WHERE s.r <> ''
ORDER BY p.pizza_id, toppings;

-- 2. What was the most commonly added extra?
WITH ssvrec(i, l, c, r) AS (
  SELECT
    order_id,
	  '',-- Forcing a space for vLength
    extras || ', ',
	  '' -- Forcing a space at the end of ssvCol removes complicated checking later
  FROM customer_orders
  WHERE 1
  UNION ALL
  SELECT
    i,
    INSTR(c, ', ' ) AS vLength,
    SUBSTR(c, INSTR( c, ', ' ) + 1) AS vRemainder,
    TRIM(SUBSTR(c, 1, INSTR( c, ', ' ) - 1) ) AS vSSV
  FROM ssvrec
  WHERE INSTR(c, ', ' ) > 0
  )
SELECT s.i as order_id, CAST(s.r as INT) as toppings, t.topping_name, ROW_NUMBER() OVER (PARTITION BY t.topping_name) as number_of_times
FROM ssvrec s
LEFT JOIN pizza_toppings t ON s.r = t.topping_id
WHERE s.r <> ''
ORDER BY order_id, toppings;

-- 3. What was the most common exclusion?
WITH ssvrec(i, l, c, r) AS (
  SELECT
    order_id,
	'',-- Forcing a space for vLength
    exclusions || ', ',
	'' -- Forcing a space at the end of ssvCol removes complicated checking later
  FROM customer_orders
  WHERE 1
  UNION ALL
  SELECT
    i,
    INSTR(c, ', ' ) AS vLength,
    SUBSTR(c, INSTR( c, ', ' ) + 1) AS vRemainder,
    TRIM(SUBSTR(c, 1, INSTR( c, ', ' ) - 1) ) AS vSSV
  FROM ssvrec
  WHERE INSTR(c, ', ' ) > 0
  )
SELECT DISTINCT s.i as order_id, CAST(s.r as INT) as toppings, t.topping_name, ROW_NUMBER() OVER (PARTITION BY t.topping_name) as number_of_times
FROM ssvrec s
LEFT JOIN pizza_toppings t ON s.r = t.topping_id
WHERE r <> ''
ORDER BY order_id, toppings;

-- 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
-- * Meat Lovers
-- * Meat Lovers - Exclude Beef
-- * Meat Lovers - Extra Bacon
-- * Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
SELECT
  CASE
    WHEN exc_second IS NOT NULL AND ext_second IS NOT NULL THEN pizza_name || ' - Exclude ' || exc_first || ', ' || exc_second || ' - Extra ' || ext_first || ', ' || ext_second
	  WHEN exc_first IS NOT NULL AND ext_second IS NOT NULL THEN pizza_name || ' - Exclude ' || exc_first || ' - Extra ' || ext_first || ', ' || ext_second
	  WHEN exc_first IS NULL AND ext_first IS NOT NULL THEN pizza_name ||  ' - Extra ' || ext_first
	  WHEN exc_first IS NOT NULL AND ext_first IS NULL THEN pizza_name || ' - Exclude ' || exc_first
 	  WHEN exc_first IS NULL AND ext_first IS NULL THEN pizza_name
	  END as order_detail
FROM
  (
  SELECT
    a.order_id,
    a.customer_id,
    a.pizza_id,
    n.pizza_name,
    a.first_exclusion,
    t.topping_name as exc_first,
    a.second_exclusion,
    t1.topping_name as exc_second,
    a.first_extra,
    t2.topping_name as ext_first,
    a.second_extra,
    t3.topping_name as ext_second
  FROM
    (
    SELECT
      c.order_id,
      c.customer_id,
	    c.pizza_id,
      SUBSTR(c.exclusions, 1, 1) as first_exclusion,
      SUBSTR(c.exclusions, 4, 4) as second_exclusion,
      SUBSTR(c.extras, 1, 1) as first_extra,
      SUBSTR(c.extras, 4, 4) as second_extra
    FROM customer_orders c
    ) a
  LEFT JOIN pizza_names n ON a.pizza_id = n.pizza_id
  LEFT JOIN pizza_toppings t ON a.first_exclusion = t.topping_id
  LEFT JOIN pizza_toppings t1 ON a.second_exclusion = t1.topping_id
  LEFT JOIN pizza_toppings t2 ON a.first_extra = t2.topping_id
  LEFT JOIN pizza_toppings t3 ON a.second_extra = t3.topping_id
  );

-- 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients.
-- * For example: "Meat Lovers: 2xBacon, Beef, ..., Salami"

-- Still trying to solve

-- 6. What is the total quantity of each ingredient used in all delivered pizza sorted by most frequent first?

-- Still trying to solve

-- D. PRICING AND RATINGS
-- 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
SELECT
  SUM
    (CASE
       WHEN pizza_name == 'Meatlovers' THEN 12
	     WHEN pizza_name == 'Vegetarian' THEN 10
	     END) as total_orders
FROM
  (
  SELECT
    c.order_id,
    c.customer_id,
    c.pizza_id,
    n.pizza_name
  FROM
    customer_orders c
  LEFT JOIN pizza_names n ON c.pizza_id = n.pizza_id
  );

--2. What if there was an additional $1 charge for any pizza extras?
--* Add cheese is $1 extra
SELECT
  SUM
    (CASE
	  WHEN pizza_name = 'Meatlovers' AND ext_second = 'Cheese' THEN 13
	  WHEN pizza_name = 'Meatlovers' THEN 12
	  WHEN pizza_name = 'Vegetarian' THEN 10
	  END) as total_orders
FROM
  (SELECT
    a.order_id,
    a.customer_id,
    a.pizza_id,
    n.pizza_name,
    a.first_extra,
    t1.topping_name as ext_first,
    a.second_extra,
    t2.topping_name as ext_second
  FROM
    (
    SELECT
      c.order_id,
      c.customer_id,
	  c.pizza_id,
      SUBSTR(c.extras, 1, 1) as first_extra,
      SUBSTR(c.extras, 4, 4) as second_extra
    FROM customer_orders c
    ) a
  LEFT JOIN pizza_names n ON a.pizza_id = n.pizza_id
  LEFT JOIN pizza_toppings t1 ON a.first_extra = t1.topping_id
  LEFT JOIN pizza_toppings t2 ON a.second_extra = t2.topping_id
  );

--3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset
-- generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
DROP TABLE IF EXISTS runner_ratings;
CREATE TABLE runner_ratings (
  "order_id" INTEGER,
  "runner_id" INTEGER,
    "rating" INTEGER
);

INSERT INTO runner_ratings (order_id, runner_id)
SELECT order_id, runner_id
FROM runner_orders
WHERE cancellation IS NULL;

UPDATE runner_ratings
SET rating = abs(random() % 4) + 1
WHERE order_id = 1 and runner_id = 1;

UPDATE runner_ratings
SET rating = abs(random() % 4) + 1
WHERE order_id = 2 and runner_id = 1;

UPDATE runner_ratings
SET rating = abs(random() % 4) + 1
WHERE order_id = 3 and runner_id = 1;

UPDATE runner_ratings
SET rating = abs(random() % 4) + 1
WHERE order_id = 4 and runner_id = 2;

UPDATE runner_ratings
SET rating = abs(random() % 4) + 1
WHERE order_id = 5 and runner_id = 3;

UPDATE runner_ratings
SET rating = abs(random() % 4) + 1
WHERE order_id = 7 and runner_id = 2;

UPDATE runner_ratings
SET rating = abs(random() % 4) + 1
WHERE order_id = 8 and runner_id = 2;

UPDATE runner_ratings
SET rating = abs(random() % 4) + 1
WHERE order_id = 10 and runner_id = 1;

--4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
-- *customer_id
-- *order_id
-- *runner_id
-- *rating
-- *order_time
-- *pickup_time
-- *Time between order and pickup
-- *Delivery duration
-- *Average speed
-- *Total number of pizza_names

SELECT
  c.customer_id,
  c.order_id,
  AVG(r.runner_id),
  AVG(ra.rating),
  AVG(c.order_time),
  AVG(r.pickup_time),
  ROUND(AVG((JULIANDAY(r.pickup_time) - JULIANDAY(c.order_time)) * 1440),1) as time_between_order_and_pickup,
  AVG(r.duration),
  ROUND(AVG((r.distance*60/r.duration)),2) as speed,
  COUNT(c.pizza_id) as number_of_pizza
FROM customer_orders c
LEFT JOIN runner_orders r ON c.order_id = r.order_id
LEFT JOIN runner_ratings ra ON c.order_id = ra.order_id
GROUP BY c.customer_id, c.order_id;

--5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?
SELECT
  s.order_id,
  SUM(CASE WHEN s.pizza_name = 'Meatlovers' THEN 12 ELSE 10 END) as pizza_cost,
  AVG(r.distance * 0.4) as delivery_cost,
  (SUM(CASE WHEN s.pizza_name = 'Meatlovers' THEN 12 ELSE 10 END) - AVG(r.distance * 0.4)) as left_over
FROM
  (
  SELECT
    c.order_id,
    c.pizza_id,
    p.pizza_name
  FROM customer_orders c
  LEFT JOIN pizza_names p ON c.pizza_id = p.pizza_id
  ) s
LEFT JOIN runner_orders r ON s.order_id = r.order_id
GROUP BY s.order_id;

--E. BONUS QUESTIONS
--If Danny wants to expand his range of pizzas - how would this impact the existing data design?
--Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?
INSERT INTO pizza_names (pizza_id, pizza_name)
VALUES (3, 'Supreme');

INSERT INTO pizza_recipes (pizza_id, toppings)
VALUES (3, '1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12');
