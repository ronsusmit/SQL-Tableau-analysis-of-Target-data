# What does 'good' look like?

## 1. Import the dataset and do usual exploratory analysis steps like checking the structure & characteristics of the dataset:
### 1. Data type of all columns in the "customers" table.
select table_name, column_name, data_type from
`target.INFORMATION_SCHEMA.COLUMNS` where table_name = "customers"
### 2. Get the time range between which the orders were placed.
select min(o.order_purchase_timestamp) fist_purchase_time , max(o.order_purchase_timestamp) last_purchase_time, 
date_diff(max(o.order_purchase_timestamp),min(o.order_purchase_timestamp), day) as days from `target.orders` o
### 3. Count the Cities & States of customers who ordered during the given period.
select distinct c.customer_state, c.customer_city, count(o.order_id) as no_of_orders from `target.customers` c left join `target.orders` o
on c.customer_id = o.customer_id 
group by 1,2
order by 1,3

## 2. In-depth Exploration:
### 1. Is there a growing trend in the no. of orders placed over the past years?
select extract(year from o.order_purchase_timestamp) as year , count(o.order_id) as no_of_order, round(sum(p.payment_value),2) as payment_amount 
from target.orders o left join `target.payments` p
on o.order_id = p.order_id
group by 1
order by 1
### 2. Can we see some kind of monthly seasonality in terms of the no. of orders being placed?
with msi as
(select extract(year from o.order_purchase_timestamp) as year,extract(month from o.order_purchase_timestamp) as month, format_date("%B", o.order_purchase_timestamp) as month_name , count(o.order_id) as no_of_order, round(sum(p.payment_value),2) as payment_amount 
from `target.orders` o left join `target.payments` p
on o.order_id = p.order_id
group by 1,2,3
order by 1,2)
select year, month_name, no_of_order, payment_amount from msi 
### 3. During what time of the day, do the Brazilian customers mostly place their orders? (Dawn, Morning, Afternoon or Night)
### 0-6 hrs : Dawn
### 7-12 hrs : Mornings
### 13-18 hrs : Afternoon
### 19-23 hrs : Night
select 
 case
 when
  extract(time from o.order_purchase_timestamp) between "00:00:00" and "06:00:00" then "Dawn"
 when
  extract(time from o.order_purchase_timestamp) between "06:00:01" and "12:00:00" then "Morning"
 when
  extract(time from o.order_purchase_timestamp) between "12:00:01" and "18:00:00" then "Afternoon"
 when
  extract(time from o.order_purchase_timestamp) between "18:00:01" and "23:59:59" then "Night"
 else "NA"
end as time_of_day, count(o.order_purchase_timestamp) as order_count from `target.orders` o
group by 1
order by 2 desc

## 3. Evolution of E-commerce orders in the Brazil region:
### 1. Get the month on month no. of orders placed in each state.
with mom as
(select c.customer_state, extract(month from o.order_purchase_timestamp) as month ,format_date("%B", o.order_purchase_timestamp) as month_name, count(o.order_id) as no_of_order from `target.customers` c join `target.orders` o
on c.customer_id = o.customer_id
group by 1,2,3
order by 1,2)
select customer_state, month_name, no_of_order from mom
### 2. How are the customers distributed across all the states?
select c.customer_state , count(c.customer_id) as no_of_customers 
from `target.customers` c
group by 1
order by 2 desc

## 4. Impact on Economy: Analyze the money movement by e-commerce by looking at order prices, freight and others.
### 1. Get the % increase in the cost of orders from year 2017 to 2018 (include months between Jan to Aug only).
###    You can use the "payment_value" column in the payments table to get the cost of orders.
with mom as
(select extract(year from o.order_purchase_timestamp) as year, round(sum(p.payment_value),2) as sum_of_payment from `target.orders` o left join `target.payments` p
on o.order_id = p.order_id
where extract(year from o.order_purchase_timestamp) in (2017,2018) and extract(month from o.order_purchase_timestamp) between 1 and 8
group by 1
order by 1)
select *, round(((sum_of_payment - lag(sum_of_payment,1)over(order by year))/ lag(sum_of_payment,1)over(order by year)*100),2) as percent_increase_from_previous_year from mom
order by year
### 2. Calculate the Total & Average value of order price for each state.
select c.customer_state, round(sum(oi.price),2) as total_value , round(avg(oi.price),2) as avg_value 
from `target.customers` c left join `target.orders` o
on c.customer_id = o.customer_id left join `target.order_items` oi
on o.order_id = oi.order_id
group by 1
order by 1
### 3. Calculate the Total & Average value of order freight for each state.
select c.customer_state, round(sum(oi.freight_value),2) as total_freight_value , round(avg(oi.freight_value),2) as avg_freight_value 
from `target.customers` c left join `target.orders` o
on c.customer_id = o.customer_id left join `target.order_items` oi
on o.order_id = oi.order_id
group by 1
order by 1

## 5. Analysis based on sales, freight and delivery time.
### 1. Find the no. of days taken to deliver each order from the order’s purchase date as delivery time.
###    Also, calculate the difference (in days) between the estimated & actual delivery date of an order.
###    Do this in a single query.
###   You can calculate the delivery time and the difference between the estimated & actual delivery date using the given formula:
###    > time_to_deliver = order_delivered_customer_date - order_purchase_timestamp
###    > diff_estimated_delivery = order_estimated_delivery_date - order_delivered_customer_date
select o.order_id , date_diff(o.order_delivered_customer_date, o.order_purchase_timestamp, day) as time_to_deliver,
date_diff(o.order_estimated_delivery_date, o.order_delivered_customer_date, day) as diff_estimated_delivery  from `target.orders` o
### 2. Find out the top 5 states with the highest & lowest average freight value.
#### > Highest >
select c.customer_state, round(avg(oi.freight_value),2) as avg_freight_value from `target.customers` c join `target.orders` o
on c.customer_id = o.customer_id join `target.order_items` oi
on o.order_id = oi.order_id
group by 1
order by 2 desc
limit 5
#### > Lowest >
select c.customer_state, round(avg(oi.freight_value),2) as avg_freight_value from `target.customers` c join `target.orders` o
on c.customer_id = o.customer_id join `target.order_items` oi
on o.order_id = oi.order_id
group by 1
order by 2
limit 5
### 3. Find out the top 5 states with the highest & lowest average delivery time.
#### > Highest >
select c.customer_state, round(avg(date_diff(o.order_delivered_customer_date,o.order_purchase_timestamp,day)),2) as avg_delivery_time 
from `target.customers` c right join `target.orders` o
on c.customer_id = o.customer_id
group by 1
order by 2 desc
limit 5
#### > Lowest >
select c.customer_state, round(avg(date_diff(o.order_delivered_customer_date,o.order_purchase_timestamp,day)),2) as avg_delivery_time 
from `target.customers` c right join `target.orders` o
on c.customer_id = o.customer_id
group by 1
order by 2
limit 5
### 4. Find out the top 5 states where the order delivery is really fast as compared to the estimated date of delivery.
###   You can use the difference between the averages of actual & estimated delivery date to figure out how fast the delivery was for each state.
select c.customer_state,round(avg(date_diff(o.order_estimated_delivery_date,o.order_delivered_customer_date,day)),2) as avg_diff_estimated_delivery 
from `target.customers` c right join `target.orders` o
on c.customer_id = o.customer_id
group by 1
order by 2
limit 5

## 6. Analysis based on the payments:
### 1. Find the month on month no. of orders placed using different payment types.
with mom as
(select format_date("%B", o.order_purchase_timestamp) as month, extract(month from o.order_purchase_timestamp) as int_month, p.payment_type , count(o.order_id) as no_of_order_placed  
from `target.payments` p left join `target.orders` o
on p.order_id = o.order_id
group by 1,2,3
order by 2,3)
select month, payment_type, no_of_order_placed from mom
#>> Just the number of orders placed using different payment types :-
with mom as
(select format_date("%B", o.order_purchase_timestamp) as month, extract(month from o.order_purchase_timestamp) as int_month, p.payment_type , count(o.order_id) as no_of_order_placed  
from `target.payments` p left join `target.orders` o
on p.order_id = o.order_id
group by 1,2,3
order by 2,3)
select payment_type,sum(no_of_order_placed) total_orders from mom
group by 1
order by 2 desc
### 2. Find the no. of orders placed on the basis of the payment installments that have been paid.
select p.payment_installments,count(p.order_id) as count_of_orders
from `target.payments` p
group by 1
order by 1




# Converting states short name to full name (For Tableau).

#>>>>>>>>

with con as
(select customer_state,case
 when tac.customer_state = "AC" then "State of Acre"
 when tac.customer_state = "AL" then "Alagoas"
 when tac.customer_state = "AM" then "Amazonas"
 when tac.customer_state = "AP" then "Amapa"
 when tac.customer_state = "BA"  then "Bahia"
 when tac.customer_state =  "CE" then "Ceara"
 when tac.customer_state  = "DF" then  "Distrito Federal"
 when tac.customer_state  =  "ES" then "Espirito Santo"
 when tac.customer_state  = "GO" then "Goiás"
 when tac.customer_state  = "MA"  then "Maranhão"
 when tac.customer_state  = "MG"  then "Minas Gerais"
 when tac.customer_state  = "MS"  then "Mato Grosso do Sul"
 when tac.customer_state   = "MT"  then "Mato Grosso"
 when tac.customer_state  = "PA"  then "Pará"
 when  tac.customer_state = "PB"   then "Paraíba"
 when tac.customer_state = "PE" then "Pernambuco"
 when tac.customer_state = "PI" then "Piauí"
 when tac.customer_state = "PR" then "Paraná"
 when  tac.customer_state = "RJ" then "Rio de Janeiro"
 when  tac.customer_state = "RN" then "Rio Grande do Norte"
 when  tac.customer_state = "RO" then "Rondônia"
 when  tac.customer_state = "RR" then "Roraima"
 when tac.customer_state = "RS" then "Rio Grande do Sul"
 when tac.customer_state = "SC" then "Santa Catarina"
 when tac.customer_state = "SE"  then "Sergipe"
 when tac.customer_state = "SP"  then "São Paulo"
 else "Tocantis" end as name_of_state,tac.customer_city,count(o.order_id) as no_of_orders from `target.customers` tac join `target.orders` o
 on tac.customer_id = o.customer_id
 group by 1,2,3
 order by 1,2)
 select name_of_state, customer_city, no_of_orders from con

