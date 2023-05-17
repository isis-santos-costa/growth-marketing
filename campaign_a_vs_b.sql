-- *****************************************
-- campaign_a_vs_b.sql
-- Purpose: assess campaign performance
-- Approach: 
-- Dialect: BigQuery
-- Author: Isis Santos Costa
-- Date: 2023-05-12
-- *****************************************  
WITH overall AS (
  SELECT
    NULL AS segment_id
    , NULL AS profile_id
    , v.campaign_version
    , i.campaign
    , count(s.customer_id) AS customer_cnt
    , avg(spend) AS avg_spend
    , approx_quantiles(spend, 2)[offset(1)] AS med_spend
    , min(spend) min_spend
    , max(spend) max_spend
  FROM `acadia_growth.post_campaign_sales` s
  JOIN `acadia_growth.campaign_version` v 
    ON v.customer_id = s.customer_id
  JOIN `acadia_growth.campaign_version_info` i
    ON i.campaign_version = v.campaign_version
  JOIN `acadia_growth.customer` c
    ON c.id = s.customer_id
  GROUP BY campaign_version, campaign
)
, by_segment AS (
  SELECT
    c.segment_id
    , NULL AS profile_id
    , v.campaign_version
    , i.campaign
    , count(s.customer_id) AS customer_cnt
    , avg(spend) AS avg_spend
    , approx_quantiles(spend, 2)[offset(1)] AS med_spend
    , min(spend) min_spend
    , max(spend) max_spend
  FROM `acadia_growth.post_campaign_sales` s
  JOIN `acadia_growth.campaign_version` v 
    ON v.customer_id = s.customer_id
  JOIN `acadia_growth.campaign_version_info` i
    ON i.campaign_version = v.campaign_version
  JOIN `acadia_growth.customer` c
    ON c.id = s.customer_id
  GROUP BY c.segment_id, campaign_version, campaign
)
, by_profile AS (
  SELECT
    NULL AS segment_id
    , c.profile_id
    , v.campaign_version
    , i.campaign
    , count(s.customer_id) AS customer_cnt
    , avg(spend) AS avg_spend
    , approx_quantiles(spend, 2)[offset(1)] AS med_spend
    , min(spend) min_spend
    , max(spend) max_spend
  FROM `acadia_growth.post_campaign_sales` s
  JOIN `acadia_growth.campaign_version` v 
    ON v.customer_id = s.customer_id
  JOIN `acadia_growth.campaign_version_info` i
    ON i.campaign_version = v.campaign_version
  JOIN `acadia_growth.customer` c
    ON c.id = s.customer_id
  WHERE c.profile_id IS NOT NULL
  GROUP BY c.profile_id, campaign_version, campaign
)
, long_table AS (
  SELECT * FROM overall 
  UNION ALL 
  SELECT * FROM by_segment 
  UNION ALL 
  SELECT * FROM by_profile
)
, a_vs_b AS (
  SELECT
    level
    , id
    , CASE WHEN customer_spend_campaign_A > customer_spend_campaign_B THEN 'A' ELSE 'B' END AS winner
    , customer_spend_campaign_A
    , customer_spend_campaign_B
    , customer_cnt_campaign_A
    , customer_cnt_campaign_B
  FROM (
    SELECT
    CASE 
      WHEN segment_id IS NULL AND profile_id IS NULL THEN 'overall'
      WHEN segment_id IS NULL THEN 'profile_id'
      ELSE 'segment_id'
    END AS level
    , COALESCE(segment_id, profile_id) AS id
    , avg_spend
    , customer_cnt
    , campaign_version
  FROM long_table
  )
  PIVOT (
      AVG(ROUND(avg_spend, 2)) customer_spend_campaign
    , MAX(customer_cnt) customer_cnt_campaign
    FOR campaign_version in ('A', 'B')
  )
)
-- SELECT * FROM long_table ORDER BY profile_id NULLS FIRST, segment_id NULLS FIRST, campaign_version NULLS FIRST;
   SELECT * FROM a_vs_b ORDER BY CASE WHEN level='overall' THEN 1 WHEN level='segment_id' THEN 2 ELSE 3 END, ID;
