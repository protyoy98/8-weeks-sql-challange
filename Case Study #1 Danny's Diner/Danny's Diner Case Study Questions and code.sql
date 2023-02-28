/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
select
	sales.customer_id,
	sum(menu.price) as total_spent
from
	dannys_diner.sales
inner join 
	dannys_diner.menu
on
	sales.product_id = menu.product_id
group by
	sales.customer_id
order by
	sales.customer_id;

-- 2. How many days has each customer visited the restaurant?
select
	sales.customer_id,
    count(distinct sales.order_date) as no_of_days
from
	dannys_diner.sales
group by
	sales.customer_id
order by
	sales.customer_id;


-- 3. What was the first item from the menu purchased by each customer?

with rank_of_items_ordered as 
(select
	sales.customer_id,
    menu.product_name,
    row_number() over
		(partition by sales.customer_id
        order by sales.order_date) as rank_of_items
from
	dannys_diner.sales
inner join
	dannys_diner.menu
on
	sales.product_id = menu.product_id)

select
	customer_id,
    product_name
from
	rank_of_items_ordered
where
	rank_of_items = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

select
	menu.product_name,
    count(sales.order_date) as ordered_count
from
	dannys_diner.menu
inner join
	dannys_diner.sales
on
	menu.product_id = sales.product_id
group by
	menu.product_name
order by
	count(sales.order_date) desc;

-- 5. Which item was the most popular for each customer?

with popular_dish_per_customer as
(select
	sales.customer_id,
    menu.product_name,
    count(sales.order_date) as no_ordered,
    row_number() over
		(partition by sales.customer_id
        order by count(sales.order_date) desc, menu.product_name asc) as popularity_of_items
from
	dannys_diner.sales
inner join
	dannys_diner.menu
on
	sales.product_id = menu.product_id
group  by
	sales.customer_id,
    menu.product_name)

select
	customer_id,
    product_name
from
	popular_dish_per_customer
where
	popularity_of_items = 1;

-- 6. Which item was purchased first by the customer after they became a member?

with orders_member as 
(select
	members.customer_id,
    menu.product_name,
    members.join_date,
    sales.order_date,
    row_number() over
		(partition by members.customer_id
        order by sales.order_date) as rank_of_order
from
	dannys_diner.members
inner join
	dannys_diner.sales
on
	members.customer_id = sales.customer_id
    and sales.order_date > members.join_date
inner join
	dannys_diner.menu
on
	sales.product_id = menu.product_id)

select
	customer_id,
    product_name
from
	orders_member
where
	rank_of_order = 1;


-- 7. Which item was purchased just before the customer became a member?

with orders_before_member as 
(select
	members.customer_id,
    menu.product_name,
    members.join_date,
    sales.order_date,
    row_number() over
		(partition by members.customer_id
        order by sales.order_date desc) as rank_orders_desc
from
	dannys_diner.members
inner join
	dannys_diner.sales
on
	members.customer_id = sales.customer_id
    and sales.order_date < members.join_date
inner join
	dannys_diner.menu
on
	sales.product_id = menu.product_id)

select
	customer_id,
    product_name
from
	orders_before_member
where
	rank_orders_desc = 1;

-- 8. What is the total items and amount spent for each member before they became a member?

select
	members.customer_id,
    count(menu.product_id) as total_items,
    sum(menu.price) as amount_spent    
from
	dannys_diner.members
inner join
	dannys_diner.sales
on
	members.customer_id = sales.customer_id
    and sales.order_date < members.join_date
inner join
	dannys_diner.menu
on
	sales.product_id = menu.product_id
group by
	members.customer_id
order by
	members.customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

select
	sales.customer_id,
    sum(case
			when menu.product_name = 'sushi' then 20*menu.price
			else 10*menu.price
        end) as total_points
from
	dannys_diner.sales
inner join
	dannys_diner.menu
on
	sales.product_id = menu.product_id
group by
	sales.customer_id
order by
	sales.customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

select
	members.customer_id,
    sum(case
			when
                sales.order_date between 
					members.join_date and date_add(members.join_date, interval 1 week)
                then 20*menu.price
			when 
				menu.product_name = 'sushi' 
                then 20*menu.price
			else 10*menu.price
        end) as total_points
from
	dannys_diner.members
inner join
	dannys_diner.sales
on
	members.customer_id = sales.customer_id
inner join
	dannys_diner.menu
on
	sales.product_id = menu.product_id
where
 	sales.order_date <= '2021-01-31'
group by
	members.customer_id
order by
	members.customer_id;
    
    
/* --------------------
   Bonus Questions
   --------------------*/
   
-- #1. Join all the tables to recreate the given output
select
	sales.customer_id,
    sales.order_date,
    menu.product_name,
    menu.price,
    case
		when members.join_date is null then 'N'
        when sales.order_date < members.join_date then 'N'
        else 'Y'
	end as 'member'
from
	dannys_diner.sales
left join
	dannys_diner.members
on
	sales.customer_id = members.customer_id
left join
	dannys_diner.menu
on
	sales.product_id = menu.product_id;
    
-- #2. Rank all the things - Danny also requires further information about the ranking of customer products, 
-- but he purposely does not need the ranking for non-member purchases so he expects null ranking values for 
-- the records when customers are not yet part of the loyalty program.

with all_joins as 
(select
	sales.customer_id,
    sales.order_date,
    menu.product_name,
    menu.price,
    case
		when members.join_date is null then 'N'
        when sales.order_date < members.join_date then 'N'
        else 'Y'
	end as 'member'
from
	dannys_diner.sales
left join
	dannys_diner.members
on
	sales.customer_id = members.customer_id
left join
	dannys_diner.menu
on
	sales.product_id = menu.product_id)
    
select
	*,
    case
		when member = 'Y' then 
			dense_rank() over (partition by customer_id, member order by order_date )
		else null
	end as ranking
from
	all_joins;