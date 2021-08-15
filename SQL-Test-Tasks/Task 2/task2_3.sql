WITH
  core AS
  (
  SELECT
	CAST(DATE AS DATE) as date_,
	COUNT(CAST(DATE AS DATE)) AS Count_Day
  FROM lore.dbo.Transactions
  GROUP BY CAST(DATE AS DATE)
  HAVING COUNT(CAST(DATE AS DATE)) > 60
  ),
  ddate AS
  (
  SELECT
      ROW_NUMBER() OVER (ORDER BY date_) AS rownumber,
      DATEADD(DAY, -ROW_NUMBER() OVER (ORDER BY date_), date_) AS day_minor,
      date_
  FROM core
  )

SELECT
  COUNT(*) AS days,
  MIN(date_) AS min_date,
  MAX(date_) AS max_date
FROM ddate
GROUP BY day_minor
ORDER BY days DESC
