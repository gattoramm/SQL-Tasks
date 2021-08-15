/*
*	Выдать список названий всех книг в алфавитном порядке, стоимость которых строго меньше 100000
*/
select distinct name from mtr.dbo.BOOKS
where cost < 100000
order by name

/*
**	Список имён ныне живущих авторов и количество их книг – детективов.
** (Название в таблице стилей - «Детективы»). Сортировать по количеству 
** книг в порядке по-убыванию.
*/
select au.name as au_name, count(au.name) as count_au_name
from mtr.dbo.AUTHORS as au, mtr.dbo.BOOKS as bk, mtr.dbo.STYLES as st
where au.DEATHDATE is null and au.ID = bk.AUTHORID and st.ID = bk.STYLEID
and st.name in
(
	select distinct name from mtr.dbo.STYLES
	where name like ('[K-T]%')
)
group by au.name
order by count desc

/*
*	Выдать список самых дорогих книг каждого автора в каждом из жанров.
*/
WITH cte(st_name, au_name, bk_name, cost)
AS (
	select st.name as st_name, au.name as au_name, bk.name as bk_name, max(bk.COST) as cost
	from mtr.dbo.AUTHORS as au, mtr.dbo.BOOKS as bk, mtr.dbo.STYLES as st
	where au.ID = bk.AUTHORID and st.ID = bk.STYLEID
	group by au.name, st.name, bk.name
   )

SELECT cte.st_name, cte.au_name, cte.bk_name
FROM cte join
	(
	SELECT st_name, au_name, max(cost) as cost
	FROM cte
	group by st_name, au_name
	) cte2
on cte.au_name = cte2.au_name and cte.st_name = cte2.st_name and cte.cost = cte2.cost
order by 1, 2, 3

/*
*	Вывести реестр количества выдачи книг (сколько раз выдавали и количество уникальных книг) по жанрам.
*/
select st.name as st_name, bk.name as bk_name, count(bk.name) as count_bk_name
from mtr.dbo.BOOKS as bk, mtr.dbo.DELIVERY as dv, mtr.dbo.STYLES as st
where dv.BOOKID = bk.ID and st.ID = bk.STYLEID
group by st.name, bk.name
order by st.name, bk.name

/*
*	Вывести список секций со свободными на текущий момент ячейками
*/
select name from mtr.dbo.RACKS as r
where MAXCOUNT is null