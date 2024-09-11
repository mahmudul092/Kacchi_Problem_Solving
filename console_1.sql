CREATE database  kacchi_com;

use kacchi_com;

CREATE TABLE sales (
  customer_id varchar(10),
  order_date date,
  product_id int
);

INSERT INTO sales
  (customer_id, order_date, product_id)
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
  ('B', '2021-01-16', '1'),
  ('B', '2021-01-16', '1'),
  ('B', '2021-01-17', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3'),
  ('A','2021-05-01','3');

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES

  ('A', '2021-01-08', '2'),
  ('A', '2021-01-09', '1'),
  ('B', '2021-01-03', '2');



CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(50),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'kacchi', '250'),
  ('2', 'roast', '120'),
  ('3', 'beef', '200');


CREATE TABLE members (
  customer_id VARCHAR(100),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

select * from menu;
select * from sales;
select * from members;

-- 1. What is the total amount each customer spent at the restaurant?
select sales.customer_id,sum(menu.price) as total_amount from sales join menu
on sales.product_id = menu.product_id
group by customer_id;

-- 2. How many days has each customer visited the restaurant?
select sales.customer_id, count(order_date) as customer_visited from sales
group by customer_id;

select * from sales
where customer_id='c';

-- 3. What was the first item from the menu purchased by each customer?
select
    distinct customer_id,product_name,order_date
from
(
    select
        customer_id,order_date,product_name,sales.product_id,
        dense_rank() over (partition by customer_id order by order_date) as rnk
    from sales
    inner join menu on sales.product_id = menu.product_id
) as t

where rnk=1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
select customer_id,count(*) from
(select sales.product_id,product_name,count(*) as number_of_product from sales join menu
                                                             on sales.product_id=menu.product_id
group by product_name,sales.product_id
order by count(*) desc
limit 1) as t join sales on t.product_id=sales.product_id
group by customer_id;

-- 5. Which item was the most popular for each customer?

select * from (select
    *,
       dense_rank() over (partition by customer_id order by product_count desc ) as rnk

from
(select customer_id,product_name,count(*) as product_count from sales join menu
on sales.product_id=menu.product_id
group by customer_id, product_name) as t) t2
where rnk=1;


-- 6. Which item was purchased first by the customer after they became a member?
-- member,sales,menu
-- join -> members & sales (to find out the customers who got the membership
-- 3 sales -> order_date -> member(join_date)
-- iv use dense_rank() --> customer_id order by order_date


select customer_id, product_name,order_date from
    (select *,
       dense_rank() over (partition by customer_id order by order_date) as rnk from
    (SELECT product_name,sales.* from sales inner join menu
on sales.product_id=menu.product_id
inner join members on members.customer_id=sales.customer_id
where order_date>members.join_date) as t3) t4
where rnk=1;


select * from menu;

-- 7. Which item was purchased just before the customer became a member?

select customer_id, product_name,order_date from
    (select *,
       dense_rank() over (partition by customer_id order by order_date desc ) as rnk from
    (SELECT product_name,sales.* from sales inner join menu
on sales.product_id=menu.product_id
inner join members on members.customer_id=sales.customer_id
where order_date<members.join_date) as t3) t4
where rnk=1;

-- validation check
select * from members;

-- 8. What is the total items and amount spent for each member before they became a member?

SELECT
    sales.customer_id,
    COUNT(sales.product_id) AS total_items,
    SUM(menu.price) AS total_amount_spent
FROM sales
INNER JOIN members ON sales.customer_id = members.customer_id
INNER JOIN menu ON sales.product_id = menu.product_id
WHERE sales.order_date < members.join_date
GROUP BY sales.customer_id;

-- 9. If each 1 Taka spent equates to 10 points and kacchi has a 2x points multiplier - how many points would each customer have?

select customer_id, sum(case when menu.product_id=1 then price*20
else price*10
end) as point
from sales join menu
on sales.product_id=menu.product_id
group by customer_id;

-- or
  select customer_id, sum(point) as tota_points from
(select sales.*,price, case when menu.product_id=1 then price*20
else price*10
end as point
from sales join menu
on sales.product_id=menu.product_id) as t
group by customer_id;


-- 10. In the 3 days after a customer joins the program( (including their join date)
  -- 1. they earn 2x points on all items, not just Kacchi(Only for first 3 days)
   -- 2. After 3 days - If each 1 Taka spent equates to 10 points and kacchi has a 2x points multiplier
   -- how many points do customer A and B have at the end of January, 2021?

select customer_id,sum(case
when rnk between 1 and 3 then price*20
when rnk not between 1 and 3 and product_id=1 then price*20
else price*10
end) as points
from (select sales.*, price, dense_rank() over (partition by sales.customer_id order by order_date) as rnk from sales join members on sales.customer_id = members.customer_id
         inner join menu on menu.product_id=sales.product_id
where order_date>=members.join_date
and order_date>='2021-01-01'
and order_date<'2021-02-01') as t1
group by customer_id








