--1
select count(distinct c.name) count
from client c
join firm f on c.firm_id = f.id;

--2
select c.surname || ' ' || c.name person, f.name firm_name, o.ord_time date_order, sum(o.amount) sum_order
from client c
join orders o on c.id = o.client_id
left join firm f on c.firm_id = f.id
group by c.surname || ' ' || c.name, f.name, o.ord_time
order by person, firm_name, date_order, sum_order

--3
select sum(o.amount*0.1)
from client c
join orders o on c.id = o.client_id
where EXTRACT(DAY FROM c.birthday) = EXTRACT(DAY FROM o.ord_time)
and EXTRACT(MONTH FROM c.birthday) = EXTRACT(MONTH FROM o.ord_time)
and EXTRACT(YEAR FROM o.ord_time) = 2021

--4
select f.name, f.address, sum(o.amount)
from client c
join orders o on c.id = o.client_id
join firm f on c.firm_id = f.id
group by f.name, f.address
having sum(o.amount) > 1000000

--5
select c.surname || ' ' || c.name person, f.name, sum(o.amount)
from client c
join orders o on c.id = o.client_id
left outer join firm f on c.firm_id = f.id
where f.id is null and EXTRACT(YEAR FROM o.ord_time) = 2021 and rownum <=3
group by c.surname || ' ' || c.name, f.name