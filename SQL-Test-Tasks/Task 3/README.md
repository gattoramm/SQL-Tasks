There is a simple method of detecting outliers in data called “three sigma rule”. It says that for the normal distribution 99.7 % of the values are within 3 standard deviations of the [mean (average)](http://en.wikipedia.org/wiki/68-95-99.7_rule).
The database consists of the following tables:

```sql
create table dbo.customer	(
customer_id	int	identity primary key clustered
		,	customer_name	nvarchar(256)	not null
)
;
create table	dbo.purchase_order	(
				purchase_order_id	int	identity primary key clustered
			,	customer_id		int	not null
			,	amount			money	not null
			,	order_date		date	not null
)
;
```

Implement a query for the report that will provide the following information: for each customer output at most 5 different dates which contain abnormally high or low amounts, for each of these dates output minimum and maximum amounts as well.

Possible result:

| **customer_name** | **order_date** | **min_amt** | **max_amt** |
|-|-|-|-|
| Bond, James | 1/10/2011 | 10082 | 32041 |
| Bond, James | 2/5/2011 | 10047 | 33229 |
| Bond, James | 3/19/2011 | 5 | 30526 |
| Bond, James | 3/25/2011 | 10027 | 36804 |
| Bond, James | 3/29/2011 | 10147 | 33545 |
| Dow, Jons | 1/2/2011 | 10000 | 34674 |
| Dow, Jons | 1/5/2011 | 10024 | 33128 |
| Dow, Jons | 1/15/2011 | 10076 | 39672 |
| Dow, Jons | 1/26/2011 | 10118 | 39939 |
| Dow, Jons | 2/2/2011 | 5 | 19912 |
| McCormick, Kenny | 1/22/2011 | 10034 | 39138 |
| McCormick, Kenny | 2/5/2011 | 5 | 31609 |
| McCormick, Kenny | 2/17/2011 | 5 | 19982 |
| McCormick, Kenny | 3/19/2011 | 10011 | 32874 |
| McCormick, Kenny | 3/24/2011 | 10119 | 34659 |

Внедрите запрос для отчета, который предоставит следующую информацию: для каждого клиента выведите не более 5 разных дат, которые содержат аномально высокие или низкие суммы, для каждой из этих дат выводятся минимальные и максимальные суммы.