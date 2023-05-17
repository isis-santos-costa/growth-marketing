-- *****************************************
-- campaign_a_vs_b.sql
-- version: 2.0
-- Purpose: assess campaign performance
-- Dialect: BigQuery
-- Author: Isis Santos Costa
-- Date: 2023-05-17
-- *****************************************
WITH overall AS (
  SELECT
    NULL AS segment_id
    , NULL AS profile_id
    , CAST(NULL AS STRING) AS level_name
    , v.campaign_version
    , i.campaign
    , ROUND(SUM(sales.spend), 2) AS campaign_revenue
    , COUNT(sales.customer_id) AS customer_cnt
    , ROUND(AVG(sales.spend), 2) AS avg_spend
    , APPROX_QUANTILES(sales.spend, 2)[OFFSET(1)] AS med_spend
    , MIN(sales.spend) min_spend
    , MAX(sales.spend) max_spend
    , ROUND(STDDEV(sales.spend) / AVG(sales.spend), 2) AS coeff_of_variation_spend
  FROM `acadia_growth.post_campaign_sales`   sales
  JOIN `acadia_growth.campaign_version`      v ON v.customer_id = sales.customer_id
  JOIN `acadia_growth.campaign_version_info` i ON i.campaign_version = v.campaign_version
  JOIN `acadia_growth.customer`              c ON c.id = sales.customer_id
  GROUP BY campaign_version, campaign
)

, by_segment AS (
  SELECT
    c.segment_id
    , NULL AS profile_id
    , sgmt.description AS segment_name
    , v.campaign_version
    , i.campaign
    , ROUND(SUM(sales.spend), 2) AS campaign_revenue
    , COUNT(sales.customer_id) AS customer_cnt
    , ROUND(AVG(sales.spend), 2) AS avg_spend
    , APPROX_QUANTILES(sales.spend, 2)[OFFSET(1)] AS med_spend
    , MIN(sales.spend) min_spend
    , MAX(sales.spend) max_spend
    , ROUND(STDDEV(sales.spend) / AVG(sales.spend), 2) AS coeff_of_variation_spend
  FROM `acadia_growth.post_campaign_sales`   sales
  JOIN `acadia_growth.campaign_version`      v    ON v.customer_id = sales.customer_id
  JOIN `acadia_growth.campaign_version_info` i    ON i.campaign_version = v.campaign_version
  JOIN `acadia_growth.customer`              c    ON c.id = sales.customer_id
  JOIN `acadia_growth.segment`               sgmt ON sgmt.id = c.segment_id
  GROUP BY c.segment_id, segment_name, campaign_version, campaign
)

, by_profile AS (
  SELECT
    NULL AS segment_id
    , c.profile_id
    , p.description AS profile_name
    , v.campaign_version
    , i.campaign
    , ROUND(SUM(sales.spend), 2) AS campaign_revenue
    , COUNT(sales.customer_id) AS customer_cnt
    , ROUND(AVG(sales.spend), 2) AS avg_spend
    , APPROX_QUANTILES(sales.spend, 2)[OFFSET(1)] AS med_spend
    , MIN(sales.spend) min_spend
    , MAX(sales.spend) max_spend
    , ROUND(STDDEV(sales.spend) / AVG(sales.spend), 2) AS coeff_of_variation_spend
  FROM `acadia_growth.post_campaign_sales`   sales
  JOIN `acadia_growth.campaign_version`      v ON v.customer_id = sales.customer_id
  JOIN `acadia_growth.campaign_version_info` i ON i.campaign_version = v.campaign_version
  JOIN `acadia_growth.customer`              c ON c.id = sales.customer_id
  JOIN `acadia_growth.profile`               p ON p.id = c.profile_id
  WHERE c.profile_id IS NOT NULL
  GROUP BY c.profile_id, profile_name, campaign_version, campaign
)

, long_table AS (
  SELECT * FROM overall    UNION ALL 
  SELECT * FROM by_segment UNION ALL 
  SELECT * FROM by_profile
)

, med_a_vs_b AS (
  SELECT
    level_of_analysis
    , level_id
    , level_name
    , CASE WHEN med_increased_customer_spend_A > med_increased_customer_spend_B THEN 'A | 99% Off' ELSE 'B | BOGO' END AS winning_campaign
    , CAST(ABS(100.0 * (med_increased_customer_spend_A / med_increased_customer_spend_B - 1)) AS INT64) AS pct_advantage
    , med_increased_customer_spend_A AS A_med_increased_customer_spend
    , med_increased_customer_spend_B AS B_med_increased_customer_spend
    , CAST(ABS(100.0 * (customer_cnt_A / customer_cnt_B - 1)) AS INT64) AS pct_diff_customer_cnt
    , customer_cnt_A AS A_customer_cnt
    , customer_cnt_B AS B_customer_cnt
  FROM (
    SELECT
    CASE 
      WHEN segment_id IS NULL AND profile_id IS NULL THEN 'overall'
      WHEN segment_id IS NULL THEN 'customer profile'
      ELSE 'customer segment'
    END AS level_of_analysis
    , COALESCE(segment_id, profile_id) AS level_id
    , level_name
    , med_spend
    , customer_cnt
    , campaign_version
  FROM long_table
  )
  PIVOT (
      MAX(med_spend) med_increased_customer_spend
    , MAX(customer_cnt) customer_cnt
    FOR campaign_version in ('A', 'B')
  )
)

, avg_a_vs_b AS (
  SELECT
    level_of_analysis
    , level_id
    , level_name
    , CASE WHEN avg_increased_customer_spend_A > avg_increased_customer_spend_B THEN 'A | 99% Off' ELSE 'B | BOGO' END AS winning_campaign
    , CAST(ABS(100.0 * (avg_increased_customer_spend_A / avg_increased_customer_spend_B - 1)) AS INT64) AS pct_advantage
    , avg_increased_customer_spend_A AS A_avg_increased_customer_spend
    , avg_increased_customer_spend_B AS B_avg_increased_customer_spend
    , CAST(ABS(100.0 * (customer_cnt_A / customer_cnt_B - 1)) AS INT64) AS pct_diff_customer_cnt
    , customer_cnt_A AS A_customer_cnt
    , customer_cnt_B AS B_customer_cnt
  FROM (
    SELECT
    CASE 
      WHEN segment_id IS NULL AND profile_id IS NULL THEN 'overall'
      WHEN segment_id IS NULL THEN 'customer profile'
      ELSE 'customer segment'
    END AS level_of_analysis
    , COALESCE(segment_id, profile_id) AS level_id
    , level_name
    , avg_spend
    , customer_cnt
    , campaign_version
  FROM long_table
  )
  PIVOT (
      MAX(avg_spend) avg_increased_customer_spend
    , MAX(customer_cnt) customer_cnt
    FOR campaign_version in ('A', 'B')
  )
)

-- SELECT * FROM overall;
-- SELECT * FROM by_segment;
-- SELECT * FROM by_profile;
 SELECT * FROM long_table ORDER BY profile_id NULLS FIRST, segment_id NULLS FIRST, campaign_version;
-- SELECT * FROM med_a_vs_b
--  ORDER BY CASE WHEN level_of_analysis='overall' THEN 1 WHEN level_of_analysis='customer segment' THEN 2 ELSE 3 END, level_id;
-- SELECT * FROM avg_a_vs_b
--  ORDER BY CASE WHEN level_of_analysis='overall' THEN 1 WHEN level_of_analysis='customer segment' THEN 2 ELSE 3 END, level_id;
