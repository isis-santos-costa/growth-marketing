-- ******************************************************************************************************************************************************
-- department_growth_by_profile.sql
-- version: 1.0
-- Purpose: assess department growth | by customer profile
-- Dialect: BigQuery
-- Author: Isis Santos Costa
-- Date: 2023-05-12
-- ******************************************************************************************************************************************************
WITH overall AS (
SELECT 
  profile_id
  , department_id
  , ROUND(100.0 * (SAFE_DIVIDE(sales_2000, sales_1999) - 1), 1) AS pct_growth
  , ROUND(sales_2000, 2) as sales_2000
  , ROUND(sales_1999, 2) as sales_1999
FROM (
  SELECT  
    profile_id
    , department_id
    , year
    , ROUND(total_sales, 2) total_sales
  FROM `acadia-growth.acadia_growth.department_annual_sales`
  )
  PIVOT(
    SUM(total_sales) AS sales
    FOR year in (1999, 2000)
  )
ORDER BY avg(pct_growth) over (partition by department_id) DESC, profile_id
)

SELECT * FROM 
  ( SELECT
    department_id
    , profile_id
    , pct_growth
    FROM overall
  )
  PIVOT(
    AVG(pct_growth) profile
    FOR profile_id IN (1, 2, 3, 4, 5)
)
ORDER BY profile_1 + profile_2 + profile_3 + profile_4 + profile_5 DESC
;

