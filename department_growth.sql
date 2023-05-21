-- ******************************************************************************************************************************************************
-- department_growth.sql
-- version: 1.0
-- Purpose: assess department growth
-- Dialect: BigQuery
-- Author: Isis Santos Costa
-- Date: 2023-05-12
-- ******************************************************************************************************************************************************

SELECT 
  department_id
  , ROUND(100.0 * (SAFE_DIVIDE(sales_2000, sales_1999) - 1), 1) AS pct_growth
  , ROUND(sales_2000, 2) as sales_2000
  , ROUND(sales_1999, 2) as sales_1999
FROM (
  SELECT  
    department_id
    , year
    , ROUND(total_sales, 2) total_sales
  FROM `acadia-growth.acadia_growth.department_annual_sales`
  )
  PIVOT(
    SUM(total_sales) AS sales
    FOR year in (1999, 2000)
  )
ORDER BY pct_growth DESC
;

