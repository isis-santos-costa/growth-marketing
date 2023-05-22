-- ******************************************************************************************************************************************************
-- department_growth_by_subset.sql
-- version: 1.1 (including department name)
-- Purpose: assess department growth | by customer subsets segment and profile (separatedly)
-- Dialect: BigQuery
-- Author: Isis Santos Costa
-- Date: 2023-05-21
-- ******************************************************************************************************************************************************
WITH by_segment AS (
SELECT 
  department_id
  , department_name
  , 'segment' AS subset_type
  , segment_id AS subset_id
  , segment_name AS subset_name
  , ROUND(100.0 * (SAFE_DIVIDE(sales_2000, sales_1999) - 1), 1) AS pct_growth
  , ROUND(sales_2000 - sales_1999, 2) AS growth
  , ROUND(sales_2000, 2) AS sales_2000
  , ROUND(sales_1999, 2) AS sales_1999
FROM (
  SELECT  
    sales.department_id
    , d.description AS department_name
    , sales.segment_id
    , sgmt.description AS segment_name
    , sales.year
    , ROUND(sales.total_sales, 2) sales
  FROM `acadia-growth.acadia_growth.department_annual_sales` sales
  JOIN `acadia-growth.acadia_growth.segment` sgmt
    ON sgmt.id = sales.segment_id
  JOIN `acadia-growth.acadia_growth.department` d
    ON d.id = sales.department_id
  )
  PIVOT(
    SUM(sales) AS sales
    FOR year IN (1999, 2000)
  )
)

, by_profile AS (
SELECT 
  department_id
  , department_name
  , 'profile' AS subset_type
  , profile_id AS subset_id
  , profile_name AS subset_name
  , ROUND(100.0 * (SAFE_DIVIDE(sales_2000, sales_1999) - 1), 1) AS pct_growth
  , ROUND(sales_2000 - sales_1999, 2) AS growth
  , ROUND(sales_2000, 2) AS sales_2000
  , ROUND(sales_1999, 2) AS sales_1999
FROM (
  SELECT  
    sales.department_id
    , d.description AS department_name
    , sales.profile_id
    , p.description AS profile_name
    , sales.year
    , ROUND(sales.total_sales, 2) sales
  FROM `acadia-growth.acadia_growth.department_annual_sales` sales
  JOIN `acadia-growth.acadia_growth.profile` p
    ON p.id = sales.profile_id
  JOIN `acadia-growth.acadia_growth.department` d
    ON d.id = sales.department_id
  )
  PIVOT(
    SUM(sales) AS sales
    FOR year IN (1999, 2000)
  )
) 

SELECT * FROM by_segment UNION ALL
SELECT * FROM by_profile
ORDER BY AVG(pct_growth) OVER (PARTITION BY department_id) DESC, subset_type DESC, subset_id;
