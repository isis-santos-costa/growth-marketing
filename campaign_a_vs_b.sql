-- ******************************************************************************************************************************************************
-- campaign_a_vs_b.sql
-- version: 2.1 (looking separately at positive vs negative revenue)
-- Purpose: compare performance of campaign A vs B
-- Dialect: BigQuery
-- Author: Isis Santos Costa
-- Date: 2023-05-17
-- ******************************************************************************************************************************************************
---------------------------------------------------------------------------------------------------------------------------------------------------------
-- Campaign A vs B: assessing and comparing Growth Marketing performance
---------------------------------------------------------------------------------------------------------------------------------------------------------
-- Business Questions
--  Overall, which version generated better incremental results?
--  Did a particular version perform better for a particular set of customers?  If so, what are the marketing implications of this result?
--  What changes can be made to this marketing campaign in order to improve future results?
---------------------------------------------------------------------------------------------------------------------------------------------------------
-- Database
-- `acadia-growth.acadia_growth`
---------------------------------------------------------------------------------------------------------------------------------------------------------
-- Source Tables
-- sales  `acadia_growth.post_campaign_sales`     →   sales after campaign (non-shoppers not included)
-- v      `acadia_growth.campaign_version`        →   relates campaign version to customer ID
-- i      `acadia_growth.campaign_version_info`   →   info on campaign versions
-- c      `acadia_growth.customer`                →   relates segment and profile to customer ID
-- sgmt   `acadia_growth.segment`                 →   info on customer segments
-- p      `acadia_growth.profile`                 →   info on customer profiles
---------------------------------------------------------------------------------------------------------------------------------------------------------
-- Assumption
-- Field `spend` of `sales` table assumed to be   →   increase in customer spend relative to baseline sales realized by the control group
---------------------------------------------------------------------------------------------------------------------------------------------------------
-- Reference
-- "Analytics Presentation Questions & Data.xlsx"
-- https://docs.google.com/spreadsheets/d/1H8AvUnwQO8APc5vr6cfUISoxNP9Sx38o/edit?usp=sharing&ouid=106534574815446903983&rtpof=true&sd=true
---------------------------------------------------------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------------------------------------------------------
-- CTE 1 • Results of campaigns A and B | Overall
---------------------------------------------------------------------------------------------------------------------------------------------------------
WITH overall AS (
  SELECT
    0 AS segment_id
    , 0 AS profile_id
    , 'OVERALL' AS level_name
    , v.campaign_version
    , i.campaign
    , ROUND(SUM(sales.spend), 2) AS campaign_net_revenue
    , COUNT(sales.customer_id) AS customer_cnt
    , ROUND(AVG(sales.spend), 2) AS avg_spend
    , APPROX_QUANTILES(sales.spend, 2)[OFFSET(1)] AS med_spend
    , MIN(sales.spend) min_spend
    , MAX(sales.spend) max_spend
    , ROUND(STDDEV(sales.spend) / AVG(sales.spend), 2) AS coeff_of_variation_spend
    , APPROX_QUANTILES(CASE WHEN sales.spend > 0 THEN sales.spend END, 2)[OFFSET(1)] AS med_earned_spend
    , APPROX_QUANTILES(CASE WHEN sales.spend < 0 THEN sales.spend END, 2)[OFFSET(1)] AS med_churned_spend
    , COUNT(    CASE WHEN sales.spend > 0 THEN sales.customer_id END) AS engaged_customer_cnt
    , COUNT(    CASE WHEN sales.spend < 0 THEN sales.customer_id END) AS churned_customer_cnt
    , ROUND(SUM(CASE WHEN sales.spend > 0 THEN sales.spend END), 2) AS campaign_earned_revenue
    , ROUND(SUM(CASE WHEN sales.spend < 0 THEN sales.spend END), 2) AS campaign_churned_revenue
  FROM `acadia_growth.post_campaign_sales`   sales
  JOIN `acadia_growth.campaign_version`      v ON v.customer_id = sales.customer_id
  JOIN `acadia_growth.campaign_version_info` i ON i.campaign_version = v.campaign_version
  JOIN `acadia_growth.customer`              c ON c.id = sales.customer_id
  GROUP BY campaign_version, campaign
)

---------------------------------------------------------------------------------------------------------------------------------------------------------
-- CTE 2 • Results of campaigns A and B | by Customer Segment
---------------------------------------------------------------------------------------------------------------------------------------------------------
, by_segment AS (
  SELECT
    c.segment_id
    , NULL AS profile_id
    , sgmt.description AS segment_name
    , v.campaign_version
    , i.campaign
    , ROUND(SUM(sales.spend), 2) AS campaign_net_revenue
    , COUNT(sales.customer_id) AS customer_cnt
    , ROUND(AVG(sales.spend), 2) AS avg_spend
    , APPROX_QUANTILES(sales.spend, 2)[OFFSET(1)] AS med_spend
    , MIN(sales.spend) min_spend
    , MAX(sales.spend) max_spend
    , ROUND(STDDEV(sales.spend) / AVG(sales.spend), 2) AS coeff_of_variation_spend
    , APPROX_QUANTILES(CASE WHEN sales.spend > 0 THEN sales.spend END, 2)[OFFSET(1)] AS med_earned_spend
    , APPROX_QUANTILES(CASE WHEN sales.spend < 0 THEN sales.spend END, 2)[OFFSET(1)] AS med_churned_spend
    , COUNT(    CASE WHEN sales.spend > 0 THEN sales.customer_id END) AS engaged_customer_cnt
    , COUNT(    CASE WHEN sales.spend < 0 THEN sales.customer_id END) AS churned_customer_cnt
    , ROUND(SUM(CASE WHEN sales.spend > 0 THEN sales.spend END), 2) AS campaign_earned_revenue
    , ROUND(SUM(CASE WHEN sales.spend < 0 THEN sales.spend END), 2) AS campaign_churned_revenue
  FROM `acadia_growth.post_campaign_sales`   sales
  JOIN `acadia_growth.campaign_version`      v    ON v.customer_id = sales.customer_id
  JOIN `acadia_growth.campaign_version_info` i    ON i.campaign_version = v.campaign_version
  JOIN `acadia_growth.customer`              c    ON c.id = sales.customer_id
  JOIN `acadia_growth.segment`               sgmt ON sgmt.id = c.segment_id
  GROUP BY c.segment_id, segment_name, campaign_version, campaign
)

---------------------------------------------------------------------------------------------------------------------------------------------------------
-- CTE 3 • Results of campaigns A and B | by Customer Profile
---------------------------------------------------------------------------------------------------------------------------------------------------------
, by_profile AS (
  SELECT
    NULL AS segment_id
    , c.profile_id
    , p.description AS profile_name
    , v.campaign_version
    , i.campaign
    , ROUND(SUM(sales.spend), 2) AS campaign_net_revenue
    , COUNT(sales.customer_id) AS customer_cnt
    , ROUND(AVG(sales.spend), 2) AS avg_spend
    , APPROX_QUANTILES(sales.spend, 2)[OFFSET(1)] AS med_spend
    , MIN(sales.spend) min_spend
    , MAX(sales.spend) max_spend
    , ROUND(STDDEV(sales.spend) / AVG(sales.spend), 2) AS coeff_of_variation_spend
    , APPROX_QUANTILES(CASE WHEN sales.spend > 0 THEN sales.spend END, 2)[OFFSET(1)] AS med_earned_spend
    , APPROX_QUANTILES(CASE WHEN sales.spend < 0 THEN sales.spend END, 2)[OFFSET(1)] AS med_churned_spend
    , COUNT(    CASE WHEN sales.spend > 0 THEN sales.customer_id END) AS engaged_customer_cnt
    , COUNT(    CASE WHEN sales.spend < 0 THEN sales.customer_id END) AS churned_customer_cnt
    , ROUND(SUM(CASE WHEN sales.spend > 0 THEN sales.spend END), 2) AS campaign_earned_revenue
    , ROUND(SUM(CASE WHEN sales.spend < 0 THEN sales.spend END), 2) AS campaign_churned_revenue
  FROM `acadia_growth.post_campaign_sales`   sales
  JOIN `acadia_growth.campaign_version`      v ON v.customer_id = sales.customer_id
  JOIN `acadia_growth.campaign_version_info` i ON i.campaign_version = v.campaign_version
  JOIN `acadia_growth.customer`              c ON c.id = sales.customer_id
  JOIN `acadia_growth.profile`               p ON p.id = c.profile_id
  WHERE c.profile_id IS NOT NULL
  GROUP BY c.profile_id, profile_name, campaign_version, campaign
)

---------------------------------------------------------------------------------------------------------------------------------------------------------
-- CTE 4 • Long Table: Results of campaigns A and B | Overall & by Customer Segment & by Customer Profile
---------------------------------------------------------------------------------------------------------------------------------------------------------
, long_table AS (
  SELECT * FROM overall    UNION ALL 
  SELECT * FROM by_segment UNION ALL 
  SELECT * FROM by_profile
)

---------------------------------------------------------------------------------------------------------------------------------------------------------
-- CTE 5 • Results of campaigns A and B | Defining the Winning Campaign by Net Revenue | Comparing to the other by other criteria | All data side by side
---------------------------------------------------------------------------------------------------------------------------------------------------------
, a_vs_b_full AS (
  SELECT
    level_of_analysis
    , level_id
    , level_name
    , CASE WHEN campaign_net_revenue_A > campaign_net_revenue_B THEN 'A | 99% Off' ELSE 'B | BOGO' END AS winning_campaign
    , CAST(ABS(100.0 * (campaign_net_revenue_A / campaign_net_revenue_B - 1)) AS INT64) AS pct_revenue_advantage_of_winning_campaign
    , campaign_net_revenue_A
    , campaign_net_revenue_B
    , CAST(100.0 * (
      CASE WHEN campaign_net_revenue_A > campaign_net_revenue_B THEN campaign_earned_revenue_A ELSE campaign_earned_revenue_B END / 
      CASE WHEN campaign_net_revenue_A < campaign_net_revenue_B THEN campaign_earned_revenue_A ELSE campaign_earned_revenue_B END 
      - 1) AS INT64) AS pct_earned_revenue_advantage_of_winning_campaign
    , campaign_earned_revenue_A
    , campaign_earned_revenue_B
    , CAST(100.0 * (
      CASE WHEN campaign_net_revenue_A > campaign_net_revenue_B THEN med_earned_spend_A ELSE med_earned_spend_B END / 
      CASE WHEN campaign_net_revenue_A < campaign_net_revenue_B THEN med_earned_spend_A ELSE med_earned_spend_B END 
      - 1) AS INT64) AS pct_med_earned_spend_advantage_of_winning_campaign
    , med_earned_spend_A
    , med_earned_spend_B
    , CAST(100.0 * (
      CASE WHEN campaign_net_revenue_A > campaign_net_revenue_B THEN engaged_customer_cnt_A ELSE engaged_customer_cnt_B END / 
      CASE WHEN campaign_net_revenue_A < campaign_net_revenue_B THEN engaged_customer_cnt_A ELSE engaged_customer_cnt_B END 
      - 1) AS INT64) AS pct_engaged_customer_cnt_advantage_of_winning_campaign
    , engaged_customer_cnt_A
    , engaged_customer_cnt_B
    , - CAST(100.0 * (
      CASE WHEN campaign_net_revenue_A > campaign_net_revenue_B THEN campaign_churned_revenue_A ELSE campaign_churned_revenue_B END / 
      CASE WHEN campaign_net_revenue_A < campaign_net_revenue_B THEN campaign_churned_revenue_A ELSE campaign_churned_revenue_B END 
      - 1) AS INT64) AS pct_churned_revenue_advantage_of_winning_campaign
    , campaign_churned_revenue_A
    , campaign_churned_revenue_B
    , - CAST(100.0 * (
      CASE WHEN campaign_net_revenue_A > campaign_net_revenue_B THEN med_churned_spend_A ELSE med_churned_spend_B END / 
      CASE WHEN campaign_net_revenue_A < campaign_net_revenue_B THEN med_churned_spend_A ELSE med_churned_spend_B END 
      - 1) AS INT64) AS pct_med_churned_spend_advantage_of_winning_campaign
    , med_churned_spend_A
    , med_churned_spend_B
    , - CAST(100.0 * (
      CASE WHEN campaign_net_revenue_A > campaign_net_revenue_B THEN churned_customer_cnt_A ELSE churned_customer_cnt_B END / 
      CASE WHEN campaign_net_revenue_A < campaign_net_revenue_B THEN churned_customer_cnt_A ELSE churned_customer_cnt_B END 
      - 1) AS INT64) AS pct_churned_customer_cnt_advantage_of_winning_campaign
    , churned_customer_cnt_A
    , churned_customer_cnt_B
  FROM (
    SELECT
    CASE 
      WHEN profile_id = 0 AND segment_id = 0 THEN 'overall'
      WHEN profile_id IS NULL THEN 'segment'
      ELSE 'profile'
    END AS level_of_analysis
    , COALESCE(segment_id, profile_id) AS level_id
    , level_name
    , campaign_version
    , campaign_net_revenue
    , campaign_earned_revenue
    , med_earned_spend
    , engaged_customer_cnt
    , campaign_churned_revenue
    , med_churned_spend
    , churned_customer_cnt
  FROM long_table
  )
  PIVOT (
      MAX(campaign_net_revenue)     AS campaign_net_revenue
    , MAX(campaign_earned_revenue)  AS campaign_earned_revenue
    , MAX(med_earned_spend)         AS med_earned_spend
    , MAX(engaged_customer_cnt)     AS engaged_customer_cnt
    , MAX(campaign_churned_revenue) AS campaign_churned_revenue
    , MAX(med_churned_spend)        AS med_churned_spend
    , MAX(churned_customer_cnt)     AS churned_customer_cnt
    FOR campaign_version in ('A', 'B')
  )
)

---------------------------------------------------------------------------------------------------------------------------------------------------------
-- CTE 6 • OUTPUT: Results of campaigns A and B | Defining the Winning Campaign by Net Revenue | Comparing to the other by other criteria | Summary
---------------------------------------------------------------------------------------------------------------------------------------------------------
, a_vs_b AS (
  SELECT
    level_of_analysis
    , level_id
    , level_name
    , winning_campaign
    , pct_revenue_advantage_of_winning_campaign
    , campaign_net_revenue_A
    , campaign_net_revenue_B
    , pct_earned_revenue_advantage_of_winning_campaign
    , pct_med_earned_spend_advantage_of_winning_campaign
    , pct_engaged_customer_cnt_advantage_of_winning_campaign
    , pct_churned_revenue_advantage_of_winning_campaign
    , pct_med_churned_spend_advantage_of_winning_campaign
    , pct_churned_customer_cnt_advantage_of_winning_campaign
  FROM a_vs_b_full
)

---------------------------------------------------------------------------------------------------------------------------------------------------------
-- Unit tests / Final query
---------------------------------------------------------------------------------------------------------------------------------------------------------
-- SELECT * FROM overall;
-- SELECT * FROM by_segment;
-- SELECT * FROM by_profile;
-- SELECT * FROM long_table ORDER BY profile_id NULLS FIRST, segment_id NULLS FIRST, campaign_version;
-- SELECT * FROM a_vs_b_full ORDER BY CASE WHEN level_of_analysis='overall' THEN 1 WHEN level_of_analysis='segment' THEN 2 ELSE 3 END, level_id;
   SELECT * FROM a_vs_b      ORDER BY CASE WHEN level_of_analysis='overall' THEN 1 WHEN level_of_analysis='segment' THEN 2 ELSE 3 END, level_id;
---------------------------------------------------------------------------------------------------------------------------------------------------------
