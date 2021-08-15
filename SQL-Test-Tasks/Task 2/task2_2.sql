SELECT SUM(Sum) AS Total_Sum, DAY(Date) AS Day
FROM lore.dbo.Transactions
WHERE Type = 'C' AND CONVERT(Date, Date) BETWEEN '2012-04-20' AND '2012-04-25'
GROUP BY DAY(Date)