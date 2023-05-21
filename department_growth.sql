-- ******************************************************************************************************************************************************
-- department_growth.sql
-- version: 1.1 (department description)
-- Purpose: assess department growth
-- Dialect: BigQuery
-- Author: Isis Santos Costa
-- Date: 2023-05-21
-- ******************************************************************************************************************************************************
SELECT 
  department_id
  , department_name
  , ROUND(100.0 * (SAFE_DIVIDE(sales_2000, sales_1999) - 1), 1) AS pct_growth
  , ROUND(sales_2000, 2) as sales_2000
  , ROUND(sales_1999, 2) as sales_1999
FROM (
  SELECT  
    sales.department_id
    , d.description AS department_name
    , sales.year
    , ROUND(sales.total_sales, 2) sales
  FROM `acadia-growth.acadia_growth.department_annual_sales` sales
  JOIN `acadia-growth.acadia_growth.department` d
    ON d.id = sales.department_id
  )
  PIVOT(
    SUM(sales) AS sales
    FOR year in (1999, 2000)
  )
ORDER BY pct_growth DESC
;

