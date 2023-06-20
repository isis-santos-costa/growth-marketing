-- ***********************************************************************************************************************************************************************************************
-- campaign_a_vs_b.sql
-- version: 3.0 (Standardizing ALL subsets to 50/50 (with no tolerance to deviations). Also adding efficiency and readability: 474 rows ==> 250 rows)
-- Purpose: Generate a report comparing performance of Campaign A vs B
-- Author: Isis Santos Costa
-- Date: 2023-06-20
-- Dialect: BigQuery
-- Running on: https://console.cloud.google.com/bigquery?sq=223570122894:efedb7a9dfbc4c10a43f292f210d4ff2
-- ***********************************************************************************************************************************************************************************************

-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Campaign A vs B: assessing and comparing Growth Marketing performance
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Business Questions
--  Overall, which version generated better incremental results?
--  Did a particular version perform better for a particular set of customers?  If so, what are the marketing implications of this result?
--  What changes can be made to this marketing campaign in order to improve future results?
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- WINNING CRITERION & STANDARDIZATION
-- Winning criterion
--   ↳ The Winning Campaign is chosen as the one with highest (net) incrementality: sum of surplus revenue vs contrl group - sum of churned revenue versus control group
-- Standardization
--   ↳ Segments and profiles for which th A/B split was different than 50/50 had their results scaled to 50/50.
--   ↳ e.g.: supposing A being sent to 75% customers of a certain subset and the corresponding incrementality for it being $90k:
--     ↳ std_incrementaility = $90k / 0.75 * 0.50   →   std_incrementaility = $60k
--   ↳ OVERALL STD values are the sum of values for all segments (as all custoomers are classified into a segment, what doesn't happen for profiles).
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Database
-- `acadia-growth.acadia_growth`
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Source Tables
-- campaign_version         `acadia_growth.campaign_version`        →   relates campaign version to customer ID
-- customer                 `acadia_growth.customer`                →   relates segment and profile to customer ID (segment: all customers | profile: some customers)
-- campaign_incrementality  `acadia_growth.post_campaign_sales`     →   sales after campaign (non-shoppers not included)
-- profile                  `acadia_growth.profile`                 →   info on customer profiles (not all customers are classified into a profile)
-- segment                  `acadia_growth.segment`                 →   info on customer segments (all customers are classified into a segment)
-- campaign_version_info    `acadia_growth.campaign_version_info`   →   info on campaign versions
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Assumption
-- Field `spend` of `sales` table assumed to be   →   increase in customer spend relative to baseline sales realized by the control group
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Reference
-- "Analytics Presentation Questions & Data.xlsx"
-- https://docs.google.com/spreadsheets/d/1H8AvUnwQO8APc5vr6cfUISoxNP9Sx38o/edit?usp=sharing&ouid=106534574815446903983&rtpof=true&sd=true
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Function 1 • win | Returns the winning campaign A or B, as the one with the highest STANDARDIZED incrementality (see « WINNING CRITERION & STANDARDIZATION » at the top)
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TEMP FUNCTION win(std_incrementality_A FLOAT64, std_incrementality_B FLOAT64)
RETURNS STRING
AS (
  CASE
    WHEN std_incrementality_A > std_incrementality_B THEN 'A'
    WHEN std_incrementality_A < std_incrementality_B THEN 'B'
  END
);

-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Function 2 • win_advantage | Returns % advantage of the winning campaign versus the other for chosen success criteria (incrementality and others)
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TEMP FUNCTION win_advantage(std_incrementality_A FLOAT64, std_incrementality_B FLOAT64, field_A FLOAT64, field_B FLOAT64)
RETURNS INT64
AS (
  CAST(100.0 *
  CASE WHEN std_incrementality_A >= std_incrementality_B THEN field_A ELSE field_B END / 
  CASE WHEN std_incrementality_A >= std_incrementality_B THEN field_B ELSE field_A END - 100 AS INT64)
);

-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CTE 1 • Joins data from the source tables
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
WITH campaign_data AS (
  SELECT
    campaign_version.campaign_version AS campaign
    , customer.profile_id
    , customer.segment_id
    , profile.description AS profile_name
    , segment.description AS segment_name
    , customer.id AS customer_id
    , campaign_incrementality.spend
  FROM `acadia_growth.campaign_version`    campaign_version
  JOIN `acadia_growth.customer`            customer                ON customer.id = campaign_version.customer_id
  JOIN `acadia_growth.post_campaign_sales` campaign_incrementality ON campaign_incrementality.customer_id = customer.id
  LEFT JOIN `acadia_growth.profile`        profile                 ON profile.id = customer.profile_id
  JOIN `acadia_growth.segment`             segment                 ON segment.id = customer.segment_id
)

-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CTE 2 • Calculates campaign KPIs at different levels: OVERALL and profile/segment, generating a long table (A/B results in different rows).
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
, a_vs_b_long_table_raw AS (
  SELECT
    'overall'   AS level_of_analysis
    , 0         AS level_id
    , 'OVERALL' AS level_name
    , campaign
    , COUNT(customer_id)                                                                         AS campaign_customer_cnt
    ,       100.0 * COUNT(customer_id) / SUM(COUNT(customer_id)) OVER ()                         AS pct_customer_cnt
    , 50 / (100.0 * COUNT(customer_id) / SUM(COUNT(customer_id)) OVER ())                        AS std_factor
    , ROUND(SUM(spend), 2)                                       AS campaign_incrementality
    , ROUND(SUM(CASE WHEN spend > 0 THEN spend END), 2)          AS campaign_lifted_revenue
    , APPROX_QUANTILES(CASE WHEN spend > 0 THEN spend END, 2)[1] AS med_lifted_spend
    ,            COUNT(CASE WHEN spend > 0 THEN customer_id END) AS lifted_customer_cnt
    ,        ROUND(SUM(CASE WHEN spend < 0 THEN spend END), 2)   AS campaign_churned_revenue
    , APPROX_QUANTILES(CASE WHEN spend < 0 THEN spend END, 2)[1] AS med_churned_spend
    ,            COUNT(CASE WHEN spend < 0 THEN customer_id END) AS churning_customer_cnt
  FROM campaign_data
  GROUP BY campaign
  UNION ALL
  SELECT
    'profile'      AS level_of_analysis
    , profile_id   AS level_id
    , profile_name AS level_name
    , campaign
    , COUNT(customer_id)                                                                         AS campaign_customer_cnt
    ,       100.0 * COUNT(customer_id) / SUM(COUNT(customer_id)) OVER (PARTITION BY profile_id)  AS pct_customer_cnt
    , 50 / (100.0 * COUNT(customer_id) / SUM(COUNT(customer_id)) OVER (PARTITION BY profile_id)) AS std_factor
    , ROUND(SUM(spend), 2)                                       AS campaign_incrementality
    , ROUND(SUM(CASE WHEN spend > 0 THEN spend END), 2)          AS campaign_lifted_revenue
    , APPROX_QUANTILES(CASE WHEN spend > 0 THEN spend END, 2)[1] AS med_lifted_spend
    ,            COUNT(CASE WHEN spend > 0 THEN customer_id END) AS lifted_customer_cnt
    ,        ROUND(SUM(CASE WHEN spend < 0 THEN spend END), 2)   AS campaign_churned_revenue
    , APPROX_QUANTILES(CASE WHEN spend < 0 THEN spend END, 2)[1] AS med_churned_spend
    ,            COUNT(CASE WHEN spend < 0 THEN customer_id END) AS churning_customer_cnt
  FROM campaign_data
  WHERE campaign_data.profile_id IS NOT NULL
  GROUP BY campaign, level_id, level_name
  UNION ALL
  SELECT
    'segment'      AS level_of_analysis
    , segment_id   AS level_id
    , segment_name AS level_name
    , campaign
    , COUNT(customer_id)                                                                         AS campaign_customer_cnt
    ,       100.0 * COUNT(customer_id) / SUM(COUNT(customer_id)) OVER (PARTITION BY segment_id)  AS pct_customer_cnt
    , 50 / (100.0 * COUNT(customer_id) / SUM(COUNT(customer_id)) OVER (PARTITION BY segment_id)) AS std_factor
    , ROUND(SUM(spend), 2)                                       AS campaign_incrementality
    , ROUND(SUM(CASE WHEN spend > 0 THEN spend END), 2)          AS campaign_lifted_revenue
    , APPROX_QUANTILES(CASE WHEN spend > 0 THEN spend END, 2)[1] AS med_lifted_spend
    ,            COUNT(CASE WHEN spend > 0 THEN customer_id END) AS lifted_customer_cnt
    ,        ROUND(SUM(CASE WHEN spend < 0 THEN spend END), 2)   AS campaign_churned_revenue
    , APPROX_QUANTILES(CASE WHEN spend < 0 THEN spend END, 2)[1] AS med_churned_spend
    ,            COUNT(CASE WHEN spend < 0 THEN customer_id END) AS churning_customer_cnt
  FROM campaign_data
  GROUP BY campaign, level_id, level_name
)

-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CTE 3 • Pivots campaign KPIs bringing A/B results to the same row, side by side. Calculates 50/50 STANDARDIZED values of the KPIs. See note on « STANDARDIZATION » at the top.
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
, a_vs_b_wide_table_standardized AS (
  SELECT
    level_of_analysis
    , level_id
    , level_name
    , campaign_customer_cnt_A + campaign_customer_cnt_B AS campaign_customer_cnt
    , ROUND(pct_customer_cnt_A) || '/' || ROUND(pct_customer_cnt_B) AS original_AB_split
    , '50/50' AS std_AB_split
    , CASE WHEN level_id <> 0 THEN std_incrementality_A ELSE ROUND(SUM(CASE WHEN level_of_analysis = 'segment' THEN std_incrementality_A END) OVER (), 2) END AS std_incrementality_A
    , CASE WHEN level_id <> 0 THEN std_incrementality_B ELSE ROUND(SUM(CASE WHEN level_of_analysis = 'segment' THEN std_incrementality_B END) OVER (), 2) END AS std_incrementality_B
    , CASE WHEN level_id <> 0 THEN std_lifted_revenue_A ELSE ROUND(SUM(CASE WHEN level_of_analysis = 'segment' THEN std_lifted_revenue_A END) OVER (), 2) END AS std_lifted_revenue_A
    , CASE WHEN level_id <> 0 THEN std_lifted_revenue_B ELSE ROUND(SUM(CASE WHEN level_of_analysis = 'segment' THEN std_lifted_revenue_B END) OVER (), 2) END AS std_lifted_revenue_B
    , med_lifted_spend_A
    , med_lifted_spend_B
    , CASE WHEN level_id <> 0 THEN std_lifted_customer_cnt_A ELSE ROUND(SUM(CASE WHEN level_of_analysis = 'segment' THEN std_lifted_customer_cnt_A END) OVER (), 2) END AS std_lifted_customer_cnt_A
    , CASE WHEN level_id <> 0 THEN std_lifted_customer_cnt_B ELSE ROUND(SUM(CASE WHEN level_of_analysis = 'segment' THEN std_lifted_customer_cnt_B END) OVER (), 2) END AS std_lifted_customer_cnt_B
    , CASE WHEN level_id <> 0 THEN std_churned_revenue_A     ELSE ROUND(SUM(CASE WHEN level_of_analysis = 'segment' THEN std_churned_revenue_A     END) OVER (), 2) END AS std_churned_revenue_A    
    , CASE WHEN level_id <> 0 THEN std_churned_revenue_B     ELSE ROUND(SUM(CASE WHEN level_of_analysis = 'segment' THEN std_churned_revenue_B     END) OVER (), 2) END AS std_churned_revenue_B    
    , med_churned_spend_A
    , med_churned_spend_B
    , CASE WHEN level_id <> 0 THEN std_churning_customer_cnt_A ELSE ROUND(SUM(CASE WHEN level_of_analysis = 'segment' THEN std_churning_customer_cnt_A END) OVER (), 2) END AS std_churning_customer_cnt_A
    , CASE WHEN level_id <> 0 THEN std_churning_customer_cnt_B ELSE ROUND(SUM(CASE WHEN level_of_analysis = 'segment' THEN std_churning_customer_cnt_B END) OVER (), 2) END AS std_churning_customer_cnt_B
  FROM
  (
    SELECT
      campaign
      , level_of_analysis
      , level_id
      , level_name
      , campaign_customer_cnt
      , pct_customer_cnt
      , CASE WHEN level_id <> 0 THEN std_factor END std_factor -- OVERALL (level_id = 0) is calculated as the sum of values for all the segments in the next step
      , campaign_incrementality
      , campaign_lifted_revenue
      , med_lifted_spend
      , lifted_customer_cnt
      , campaign_churned_revenue
      , med_churned_spend
      , churning_customer_cnt
    FROM a_vs_b_long_table_raw
  )
  PIVOT (
      SUM(campaign_customer_cnt) AS campaign_customer_cnt
    , SUM(pct_customer_cnt)      AS pct_customer_cnt
    , SUM(ROUND(std_factor * campaign_incrementality , 2)) AS std_incrementality
    , SUM(ROUND(std_factor * campaign_lifted_revenue , 2)) AS std_lifted_revenue
    , SUM(med_lifted_spend)                                AS med_lifted_spend
    , SUM(ROUND(std_factor * lifted_customer_cnt     , 2)) AS std_lifted_customer_cnt
    , SUM(ROUND(std_factor * campaign_churned_revenue, 2)) AS std_churned_revenue
    , SUM(med_churned_spend)                               AS med_churned_spend
    , SUM(ROUND(std_factor * churning_customer_cnt   , 2)) AS std_churning_customer_cnt
    FOR campaign IN ('A', 'B')
  )
)

-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CTE 4 • Final report, indicating the winning campign for each subset in terms of (net) incrementality. Shows also the % advantage of the winning campaign for the other KPIs.
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
, a_vs_b_final_report AS (
  SELECT
    level_of_analysis
    , level_id
    , level_name
    , campaign_customer_cnt
    , original_AB_split
    , std_AB_split
    , win(std_incrementality_A, std_incrementality_B) AS winning_campaign
    , win_advantage(std_incrementality_A, std_incrementality_B,        std_incrementality_A,        std_incrementality_B) AS winning_campaign_advantage
    , std_incrementality_A
    , std_incrementality_B
    , win_advantage(std_incrementality_A, std_incrementality_B,        std_lifted_revenue_A,        std_lifted_revenue_B) AS winning_campaign_advantage_in_pct_std_lifted_revenue
    , std_lifted_revenue_A
    , std_lifted_revenue_B
    , win_advantage(std_incrementality_A, std_incrementality_B,          med_lifted_spend_A,          med_lifted_spend_B) AS winning_campaign_advantage_in_pct_med_lifted_spend
    , med_lifted_spend_A
    , med_lifted_spend_B
    , win_advantage(std_incrementality_A, std_incrementality_B,   std_lifted_customer_cnt_A,   std_lifted_customer_cnt_B) AS winning_campaign_advantage_in_pct_std_lifted_customer_cnt
    , std_lifted_customer_cnt_A
    , std_lifted_customer_cnt_B
    , win_advantage(std_incrementality_A, std_incrementality_B,       std_churned_revenue_A,       std_churned_revenue_B) AS winning_campaign_advantage_in_pct_std_churned_revenue
    , std_churned_revenue_A
    , std_churned_revenue_B
    , win_advantage(std_incrementality_A, std_incrementality_B,         med_churned_spend_A,         med_churned_spend_B) AS winning_campaign_advantage_in_pct_med_churned_spend
    , med_churned_spend_A
    , med_churned_spend_B
    , win_advantage(std_incrementality_A, std_incrementality_B, std_churning_customer_cnt_A, std_churning_customer_cnt_B) AS winning_campaign_advantage_in_pct_std_churning_customer_cnt
    , std_churning_customer_cnt_A
    , std_churning_customer_cnt_B
  FROM a_vs_b_wide_table_standardized
)

-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Unit tests / Final query
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- SELECT * FROM campaign_data;
-- SELECT * FROM a_vs_b_long_table_raw          ORDER BY level_of_analysis, level_id, campaign;
-- SELECT * FROM a_vs_b_wide_table_standardized ORDER BY level_of_analysis, level_id;
   SELECT * FROM a_vs_b_final_report            ORDER BY level_of_analysis, level_id;
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
