WITH
  core AS
  (
  SELECT customer_id, count(customer_id) as c_n, AVG(amount) as avg_amount
  FROM purchase_order
  group by customer_id
  )
  ,
  core2 as
  (
  SELECT p.purchase_order_id,c.customer_id, p.amount, c.avg_amount,  c.c_n
  FROM purchase_order p, core c
  WHERE p.customer_id=c.customer_id
  )
  ,
  diff AS
  (
  SELECT *, (amount - avg_amount)*(amount - avg_amount)/c_n as df_sqr
  FROM core2
  )
  ,
  sigm AS
  (
  SELECT customer_id, SQRT(SUM(df_sqr)) as sigma
  FROM diff
  GROUP BY customer_id
  )
  ,
  sss AS
  (
  SELECT c.customer_id, c.avg_amount, s.sigma, c.avg_amount - 3*s.sigma as avg_3sigm_minor, c.avg_amount + 3*s.sigma as avg_3sigm_major
  FROM core c, sigm s
  WHERE c.customer_id=s.customer_id
  )
  ,
  rrr AS
  (
  SELECT p.purchase_order_id, p.customer_id, p.amount
  FROM core2 p, sss
  WHERE p.customer_id=sss.customer_id AND p.amount<sss.avg_3sigm_minor and p.amount>sss.avg_3sigm_major
  )

SELECT *
FROM rrr