-- ******************************************************************************************************************************************************
-- campaign_a_vs_b.sql
-- version: 2.4 (standardizing results for unbalanced subsets [Segments: 'Elite Customers' (75/25), Infrequent Customers' (25/75)])
-- Purpose: compare performance of campaign A vs B
-- Dialect: BigQuery
-- Author: Isis Santos Costa
-- Date: 2023-05-19
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
-- Parameter • % Tolerance to split unbalance in A/B testing (see details on comments to CTE 6 `a_vs_b_standardized`)
---------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE pct_tolerance_to_split_unbalance FLOAT64 DEFAULT 5;

---------------------------------------------------------------------------------------------------------------------------------------------------------
-- Function 1 • Standardizing factor for subsets with unbalanced split in A/B testing (see details on comments to CTE 6 `a_vs_b_standardized`)
---------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TEMPORARY FUNCTION std_factor(pct_customer FLOAT64, pct_tolerance_to_split_unbalance FLOAT64) AS (
  CASE WHEN ABS(50 - pct_customer) > pct_tolerance_to_split_unbalance THEN (50 / pct_customer) ELSE 1 END
);

---------------------------------------------------------------------------------------------------------------------------------------------------------
-- Function 2 • Standardized values (see details on comments to CTE 6 `a_vs_b_standardized`)
---------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TEMPORARY FUNCTION std_value(pct_customer FLOAT64, pct_tolerance_to_split_unbalance FLOAT64, original_value FLOAT64, level_id INT64) AS (
  CASE WHEN level_id = 0 THEN NULL
  ELSE std_factor(pct_customer, pct_tolerance_to_split_unbalance) * original_value END
);

---------------------------------------------------------------------------------------------------------------------------------------------------------
-- Function 3 • Winning Campaign after Standardization (see details on comments to CTE 6 `a_vs_b_standardized`)
---------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TEMPORARY FUNCTION std_win(pct_customer_A FLOAT64, pct_customer_B FLOAT64, pct_tolerance_to_split_unbalance FLOAT64
  , campaign_net_revenue_A FLOAT64, campaign_net_revenue_B FLOAT64, level_id INT64) AS (
    CASE 
      WHEN level_id = 0 THEN NULL
      WHEN std_value(pct_customer_A, pct_tolerance_to_split_unbalance, campaign_net_revenue_A, level_id) > 
           std_value(pct_customer_B, pct_tolerance_to_split_unbalance, campaign_net_revenue_B, level_id) THEN 'A | 99% Off' 
           ELSE 'B | BOGO' END
);

---------------------------------------------------------------------------------------------------------------------------------------------------------
-- Function 4 • Standardized % advantage of Winning Campaign (see details on comments to CTE 6 `a_vs_b_standardized`)
---------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TEMPORARY FUNCTION std_pct_advantage(
  pct_customer_A FLOAT64, pct_customer_B FLOAT64, pct_tolerance_to_split_unbalance FLOAT64
  , campaign_net_revenue_A FLOAT64, campaign_net_revenue_B FLOAT64
  , original_value_A FLOAT64, original_value_B FLOAT64
  , level_id INT64) AS (
  CAST(100.0 * (
      CASE 
        WHEN std_win(pct_customer_A, pct_customer_B, pct_tolerance_to_split_unbalance, campaign_net_revenue_A, campaign_net_revenue_B, level_id) like 'A%'
            THEN std_value(pct_customer_A, pct_tolerance_to_split_unbalance, original_value_A, level_id) 
            ELSE std_value(pct_customer_B, pct_tolerance_to_split_unbalance, original_value_B, level_id) 
            END / 
      CASE 
        WHEN std_win(pct_customer_A, pct_customer_B, pct_tolerance_to_split_unbalance, campaign_net_revenue_A, campaign_net_revenue_B, level_id) like 'B%'
            THEN std_value(pct_customer_A, pct_tolerance_to_split_unbalance, original_value_A, level_id) 
            ELSE std_value(pct_customer_B, pct_tolerance_to_split_unbalance, original_value_B, level_id) 
            END 
      - 1) AS INT64)
);

---------------------------------------------------------------------------------------------------------------------------------------------------------
-- CTE 1 • Results of campaigns A and B | Overall
---------------------------------------------------------------------------------------------------------------------------------------------------------
WITH overall AS (
  SELECT
    0 AS segment_id
    , 0 AS profile_id
    , 'OVERALL' AS level_name
    , COUNT(c.id) AS campaign_base_customer_cnt
    , v.campaign_version
    , i.campaign
    , ROUND(SUM(sales.spend), 2) AS campaign_net_revenue
    , COUNT(sales.customer_id) AS active_customer_cnt
    , ROUND(AVG(sales.spend), 2) AS avg_spend
    , APPROX_QUANTILES(sales.spend, 2)[OFFSET(1)] AS med_spend
    , MIN(sales.spend) min_spend
    , MAX(sales.spend) max_spend
    , ROUND(STDDEV(sales.spend) / AVG(sales.spend), 2) AS coeff_of_variation_spend
    , APPROX_QUANTILES(CASE WHEN sales.spend > 0 THEN sales.spend END, 2)[OFFSET(1)] AS med_lifted_spend
    , APPROX_QUANTILES(CASE WHEN sales.spend < 0 THEN sales.spend END, 2)[OFFSET(1)] AS med_churned_spend
    , COUNT(    CASE WHEN sales.spend > 0 THEN sales.customer_id END) AS lifted_customer_cnt
    , COUNT(    CASE WHEN sales.spend < 0 THEN sales.customer_id END) AS churning_customer_cnt
    , ROUND(SUM(CASE WHEN sales.spend > 0 THEN sales.spend END), 2) AS campaign_lifted_revenue
    , ROUND(SUM(CASE WHEN sales.spend < 0 THEN sales.spend END), 2) AS campaign_churned_revenue
  FROM `acadia_growth.customer`                 c
  LEFT JOIN `acadia_growth.campaign_version`    v     ON v.customer_id = c.id
  LEFT JOIN `acadia_growth.post_campaign_sales` sales ON sales.customer_id = c.id
  JOIN `acadia_growth.campaign_version_info`    i     ON i.campaign_version = v.campaign_version  
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
    , COUNT(c.id) AS campaign_base_customer_cnt
    , v.campaign_version
    , i.campaign
    , ROUND(SUM(sales.spend), 2) AS campaign_net_revenue
    , COUNT(sales.customer_id) AS active_customer_cnt
    , ROUND(AVG(sales.spend), 2) AS avg_spend
    , APPROX_QUANTILES(sales.spend, 2)[OFFSET(1)] AS med_spend
    , MIN(sales.spend) min_spend
    , MAX(sales.spend) max_spend
    , ROUND(STDDEV(sales.spend) / AVG(sales.spend), 2) AS coeff_of_variation_spend
    , APPROX_QUANTILES(CASE WHEN sales.spend > 0 THEN sales.spend END, 2)[OFFSET(1)] AS med_lifted_spend
    , APPROX_QUANTILES(CASE WHEN sales.spend < 0 THEN sales.spend END, 2)[OFFSET(1)] AS med_churned_spend
    , COUNT(    CASE WHEN sales.spend > 0 THEN sales.customer_id END) AS lifted_customer_cnt
    , COUNT(    CASE WHEN sales.spend < 0 THEN sales.customer_id END) AS churning_customer_cnt
    , ROUND(SUM(CASE WHEN sales.spend > 0 THEN sales.spend END), 2) AS campaign_lifted_revenue
    , ROUND(SUM(CASE WHEN sales.spend < 0 THEN sales.spend END), 2) AS campaign_churned_revenue
  FROM `acadia_growth.customer`                 c
  LEFT JOIN `acadia_growth.campaign_version`    v     ON v.customer_id = c.id
  LEFT JOIN `acadia_growth.post_campaign_sales` sales ON sales.customer_id = c.id
  JOIN `acadia_growth.segment`                  sgmt  ON sgmt.id = c.segment_id
  JOIN `acadia_growth.campaign_version_info`    i     ON i.campaign_version = v.campaign_version
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
    , COUNT(c.id) AS campaign_base_customer_cnt
    , v.campaign_version
    , i.campaign
    , ROUND(SUM(sales.spend), 2) AS campaign_net_revenue
    , COUNT(sales.customer_id) AS active_customer_cnt
    , ROUND(AVG(sales.spend), 2) AS avg_spend
    , APPROX_QUANTILES(sales.spend, 2)[OFFSET(1)] AS med_spend
    , MIN(sales.spend) min_spend
    , MAX(sales.spend) max_spend
    , ROUND(STDDEV(sales.spend) / AVG(sales.spend), 2) AS coeff_of_variation_spend
    , APPROX_QUANTILES(CASE WHEN sales.spend > 0 THEN sales.spend END, 2)[OFFSET(1)] AS med_lifted_spend
    , APPROX_QUANTILES(CASE WHEN sales.spend < 0 THEN sales.spend END, 2)[OFFSET(1)] AS med_churned_spend
    , COUNT(    CASE WHEN sales.spend > 0 THEN sales.customer_id END) AS lifted_customer_cnt
    , COUNT(    CASE WHEN sales.spend < 0 THEN sales.customer_id END) AS churning_customer_cnt
    , ROUND(SUM(CASE WHEN sales.spend > 0 THEN sales.spend END), 2) AS campaign_lifted_revenue
    , ROUND(SUM(CASE WHEN sales.spend < 0 THEN sales.spend END), 2) AS campaign_churned_revenue
  FROM `acadia_growth.customer`                 c
  LEFT JOIN `acadia_growth.post_campaign_sales` sales ON sales.customer_id = c.id
  LEFT JOIN `acadia_growth.campaign_version`    v     ON v.customer_id = c.id
  JOIN `acadia_growth.profile`                  p     ON p.id = c.profile_id
  JOIN `acadia_growth.campaign_version_info`    i     ON i.campaign_version = v.campaign_version
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
-- CTE 5 • Results of campaigns A and B | Winning Campaign defined by Net Revenue | Compared also by other criteria | Wide Table
---------------------------------------------------------------------------------------------------------------------------------------------------------
, a_vs_b_raw AS (
  SELECT
    level_of_analysis
    , level_id
    , level_name
    , (campaign_base_customer_cnt_A + campaign_base_customer_cnt_B) AS campaign_base_customer_cnt
    , 100.0 * campaign_base_customer_cnt_A / (campaign_base_customer_cnt_A + campaign_base_customer_cnt_B) AS pct_customer_A
    , 100.0 * campaign_base_customer_cnt_B / (campaign_base_customer_cnt_A + campaign_base_customer_cnt_B) AS pct_customer_B
    , CASE WHEN campaign_net_revenue_A > campaign_net_revenue_B THEN 'A | 99% Off' ELSE 'B | BOGO' END AS winning_campaign
    , CAST(ABS(100.0 * (campaign_net_revenue_A / campaign_net_revenue_B - 1)) AS INT64) AS pct_revenue_advantage_of_winning_campaign
    , campaign_net_revenue_A
    , campaign_net_revenue_B
    , CAST(100.0 * (
      CASE WHEN campaign_net_revenue_A >= campaign_net_revenue_B THEN campaign_lifted_revenue_A ELSE campaign_lifted_revenue_B END / 
      CASE WHEN campaign_net_revenue_A <  campaign_net_revenue_B THEN campaign_lifted_revenue_A ELSE campaign_lifted_revenue_B END 
      - 1) AS INT64) AS pct_lifted_revenue_advantage_of_winning_campaign
    , campaign_lifted_revenue_A
    , campaign_lifted_revenue_B
    , CAST(100.0 * (
      CASE WHEN campaign_net_revenue_A >= campaign_net_revenue_B THEN med_lifted_spend_A ELSE med_lifted_spend_B END / 
      CASE WHEN campaign_net_revenue_A <  campaign_net_revenue_B THEN med_lifted_spend_A ELSE med_lifted_spend_B END 
      - 1) AS INT64) AS pct_med_lifted_spend_advantage_of_winning_campaign
    , med_lifted_spend_A
    , med_lifted_spend_B
    , CAST(100.0 * (
      CASE WHEN campaign_net_revenue_A >= campaign_net_revenue_B THEN lifted_customer_cnt_A ELSE lifted_customer_cnt_B END / 
      CASE WHEN campaign_net_revenue_A <  campaign_net_revenue_B THEN lifted_customer_cnt_A ELSE lifted_customer_cnt_B END 
      - 1) AS INT64) AS pct_lifted_customer_cnt_advantage_of_winning_campaign
    , lifted_customer_cnt_A
    , lifted_customer_cnt_B
    , - CAST(100.0 * (
      CASE WHEN campaign_net_revenue_A >= campaign_net_revenue_B THEN campaign_churned_revenue_A ELSE campaign_churned_revenue_B END / 
      CASE WHEN campaign_net_revenue_A <  campaign_net_revenue_B THEN campaign_churned_revenue_A ELSE campaign_churned_revenue_B END 
      - 1) AS INT64) AS pct_churned_revenue_advantage_of_winning_campaign
    , campaign_churned_revenue_A
    , campaign_churned_revenue_B
    , - CAST(100.0 * (
      CASE WHEN campaign_net_revenue_A >= campaign_net_revenue_B THEN med_churned_spend_A ELSE med_churned_spend_B END / 
      CASE WHEN campaign_net_revenue_A <  campaign_net_revenue_B THEN med_churned_spend_A ELSE med_churned_spend_B END 
      - 1) AS INT64) AS pct_med_churned_spend_advantage_of_winning_campaign
    , med_churned_spend_A
    , med_churned_spend_B
    , - CAST(100.0 * (
      CASE WHEN campaign_net_revenue_A >= campaign_net_revenue_B THEN churning_customer_cnt_A ELSE churning_customer_cnt_B END / 
      CASE WHEN campaign_net_revenue_A <  campaign_net_revenue_B THEN churning_customer_cnt_A ELSE churning_customer_cnt_B END 
      - 1) AS INT64) AS pct_churning_customer_cnt_advantage_of_winning_campaign
    , churning_customer_cnt_A
    , churning_customer_cnt_B
  FROM (
    SELECT
    CASE 
      WHEN profile_id = 0 AND segment_id = 0 THEN 'overall'
      WHEN profile_id IS NULL THEN 'segment'
      ELSE 'profile'
    END AS level_of_analysis
    , COALESCE(segment_id, profile_id) AS level_id
    , level_name
    , campaign_base_customer_cnt
    , campaign_version
    , campaign_net_revenue
    , campaign_lifted_revenue
    , med_lifted_spend
    , lifted_customer_cnt
    , campaign_churned_revenue
    , med_churned_spend
    , churning_customer_cnt
  FROM long_table
  )
  PIVOT (
      MAX(campaign_base_customer_cnt) AS campaign_base_customer_cnt
    , MAX(campaign_net_revenue)       AS campaign_net_revenue
    , MAX(campaign_lifted_revenue)    AS campaign_lifted_revenue
    , MAX(med_lifted_spend)           AS med_lifted_spend
    , MAX(lifted_customer_cnt)        AS lifted_customer_cnt
    , MAX(campaign_churned_revenue)   AS campaign_churned_revenue
    , MAX(med_churned_spend)          AS med_churned_spend
    , MAX(churning_customer_cnt)      AS churning_customer_cnt
    FOR campaign_version in ('A', 'B')
  )
)

---------------------------------------------------------------------------------------------------------------------------------------------------------
-- CTE 6 • Results of campaigns A and B | Winning Campaign defined by STANDARDIZED Net Revenue | Compared also by other criteria | Wide Table
---------------------------------------------------------------------------------------------------------------------------------------------------------
-- Note on STANDARDIZATION
-- This CTE standardizes to 50/50 results for customer subsets that were unbalanced in the actual experimentation.
-- Unbalanced subsets: segments 'Elite Customers' (75/25), and Infrequent Customers' (25/75)
-- Each subset is large enough, so that the adjustment is performed by assuming random distribution.
-- The unbalanced split are thus scaled to 50/50 →  e.g. for A/B = 75/25 → Std. Net Revenue A = (Net Revenue / 75 × 50)
---------------------------------------------------------------------------------------------------------------------------------------------------------
-- Affected fields & New fiels
-- ⚠️ MOST IMPORTANT: WINNING CAMPAIGN (as it is a function of an extensive variable)
-- Overall totals of extensive variables are calculated as the sum of STD values for all segments (as -opposed to profiles- segments cover all customers)
-- Extensive variables are adjusted to a standardized version: net revenue, lifted/churned revenue, lifted/churning customer count.
-- Intensive variables (in case, medians) are kept unchanged, as they alone reflect a whole group.
---------------------------------------------------------------------------------------------------------------------------------------------------------
-- Tolerance defined on the top of the query → pct_tolerance_to_split_unbalance
---------------------------------------------------------------------------------------------------------------------------------------------------------
, a_vs_b_standardized AS (
  SELECT
    level_of_analysis
    , level_id
    , level_name
    , campaign_base_customer_cnt
    , pct_customer_A
    , pct_customer_B
    , std_win(pct_customer_A, pct_customer_B, pct_tolerance_to_split_unbalance, campaign_net_revenue_A, campaign_net_revenue_B, level_id) 
        AS winning_campaign
    , std_pct_advantage(pct_customer_A, pct_customer_B, pct_tolerance_to_split_unbalance, campaign_net_revenue_A, campaign_net_revenue_B
        , campaign_net_revenue_A, campaign_net_revenue_B, level_id) AS std_pct_revenue_advantage_of_winning_campaign
    , ROUND(std_value(pct_customer_A, pct_tolerance_to_split_unbalance, campaign_net_revenue_A, level_id), 2) AS std_campaign_net_revenue_A
    , ROUND(std_value(pct_customer_B, pct_tolerance_to_split_unbalance, campaign_net_revenue_B, level_id), 2) AS std_campaign_net_revenue_B
    , pct_revenue_advantage_of_winning_campaign
    , campaign_net_revenue_A
    , campaign_net_revenue_B
    , std_pct_advantage(pct_customer_A, pct_customer_B, pct_tolerance_to_split_unbalance, campaign_net_revenue_A, campaign_net_revenue_B
        , campaign_lifted_revenue_A, campaign_lifted_revenue_B, level_id) AS std_pct_lifted_revenue_advantage_of_winning_campaign
    , ROUND(std_value(pct_customer_A, pct_tolerance_to_split_unbalance, campaign_lifted_revenue_A, level_id), 2) AS std_campaign_lifted_revenue_A
    , ROUND(std_value(pct_customer_B, pct_tolerance_to_split_unbalance, campaign_lifted_revenue_B, level_id), 2) AS std_campaign_lifted_revenue_B
    , pct_lifted_revenue_advantage_of_winning_campaign
    , campaign_lifted_revenue_A
    , campaign_lifted_revenue_B
    , pct_med_lifted_spend_advantage_of_winning_campaign
    , med_lifted_spend_A
    , med_lifted_spend_B
    , std_pct_advantage(pct_customer_A, pct_customer_B, pct_tolerance_to_split_unbalance, campaign_net_revenue_A, campaign_net_revenue_B
        , lifted_customer_cnt_A, lifted_customer_cnt_B, level_id) AS std_pct_lifted_customer_cnt_advantage_of_winning_campaign
    , CAST(std_value(pct_customer_A, pct_tolerance_to_split_unbalance, lifted_customer_cnt_A, level_id) AS INT64) AS std_lifted_customer_cnt_A
    , CAST(std_value(pct_customer_B, pct_tolerance_to_split_unbalance, lifted_customer_cnt_B, level_id) AS INT64) AS std_lifted_customer_cnt_B
    , pct_lifted_customer_cnt_advantage_of_winning_campaign
    , lifted_customer_cnt_A
    , lifted_customer_cnt_B
    , std_pct_advantage(pct_customer_A, pct_customer_B, pct_tolerance_to_split_unbalance, campaign_net_revenue_A, campaign_net_revenue_B
        , campaign_churned_revenue_A, campaign_churned_revenue_B, level_id) AS std_pct_churned_revenue_advantage_of_winning_campaign
    , ROUND(std_value(pct_customer_A, pct_tolerance_to_split_unbalance, campaign_churned_revenue_A, level_id), 2) AS std_campaign_churned_revenue_A
    , ROUND(std_value(pct_customer_B, pct_tolerance_to_split_unbalance, campaign_churned_revenue_B, level_id), 2) AS std_campaign_churned_revenue_B
    , pct_churned_revenue_advantage_of_winning_campaign
    , campaign_churned_revenue_A
    , campaign_churned_revenue_B
    , pct_med_churned_spend_advantage_of_winning_campaign
    , med_churned_spend_A
    , med_churned_spend_B
    , std_pct_advantage(pct_customer_A, pct_customer_B, pct_tolerance_to_split_unbalance, campaign_net_revenue_A, campaign_net_revenue_B
        , churning_customer_cnt_A, churning_customer_cnt_B, level_id) AS std_pct_churning_customer_cnt_advantage_of_winning_campaign
    , CAST(std_value(pct_customer_A, pct_tolerance_to_split_unbalance, churning_customer_cnt_A, level_id) AS INT64) AS std_churning_customer_cnt_A
    , CAST(std_value(pct_customer_B, pct_tolerance_to_split_unbalance, churning_customer_cnt_B, level_id) AS INT64) AS std_churning_customer_cnt_B
    , pct_churning_customer_cnt_advantage_of_winning_campaign
    , churning_customer_cnt_A
    , churning_customer_cnt_B
  FROM a_vs_b_raw
)

---------------------------------------------------------------------------------------------------------------------------------------------------------
-- CTE 7 • OUTPUT: Results of campaigns A and B | Winning Campaign defined by STANDARDIZED Net Revenue | Clean version, STD values only → conclusive
---------------------------------------------------------------------------------------------------------------------------------------------------------
-- ⚠️⚠️⚠️ MISSING → INCLUDE ADJUSTMENT FOR OVERALL ⚠️⚠️⚠️
---------------------------------------------------------------------------------------------------------------------------------------------------------
, a_vs_b AS (
  SELECT
    level_of_analysis
    , level_id
    , level_name
    , campaign_base_customer_cnt
    , pct_customer_A
    , pct_customer_B
    , winning_campaign
    , std_pct_revenue_advantage_of_winning_campaign
    , std_campaign_net_revenue_A
    , std_campaign_net_revenue_B
    , std_pct_lifted_revenue_advantage_of_winning_campaign
    , std_campaign_lifted_revenue_A
    , std_campaign_lifted_revenue_B
    , pct_med_lifted_spend_advantage_of_winning_campaign
    , med_lifted_spend_A
    , med_lifted_spend_B
    , std_pct_lifted_customer_cnt_advantage_of_winning_campaign
    , std_lifted_customer_cnt_A
    , std_lifted_customer_cnt_B
    , std_pct_churned_revenue_advantage_of_winning_campaign
    , std_campaign_churned_revenue_A
    , std_campaign_churned_revenue_B
    , pct_med_churned_spend_advantage_of_winning_campaign
    , med_churned_spend_A
    , med_churned_spend_B
    , std_pct_churning_customer_cnt_advantage_of_winning_campaign
    , std_churning_customer_cnt_A
    , std_churning_customer_cnt_B
  FROM a_vs_b_standardized
)

---------------------------------------------------------------------------------------------------------------------------------------------------------
-- Unit tests / Final query
---------------------------------------------------------------------------------------------------------------------------------------------------------
-- SELECT * FROM overall;
-- SELECT * FROM by_segment;
-- SELECT * FROM by_profile;
-- SELECT * FROM long_table ORDER BY profile_id NULLS FIRST, segment_id NULLS FIRST, campaign_version;
-- SELECT * FROM a_vs_b_raw          ORDER BY CASE WHEN level_of_analysis='overall' THEN 1 WHEN level_of_analysis='segment' THEN 2 ELSE 3 END, level_id;
-- SELECT * FROM a_vs_b_standardized ORDER BY CASE WHEN level_of_analysis='overall' THEN 1 WHEN level_of_analysis='segment' THEN 2 ELSE 3 END, level_id;
   SELECT * FROM a_vs_b              ORDER BY CASE WHEN level_of_analysis='overall' THEN 1 WHEN level_of_analysis='segment' THEN 2 ELSE 3 END, level_id;
---------------------------------------------------------------------------------------------------------------------------------------------------------
