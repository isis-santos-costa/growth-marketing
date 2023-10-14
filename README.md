<!-- -------------------------------------------------------------------------------------------------------------------------------------->
<!-- Metadata badges -->

[![pull requests](https://img.shields.io/github/issues-pr-closed/isis-santos-costa/growth-marketing?color=brightgreen)](https://github.com/isis-santos-costa/growth-marketing/pulls?q=is%3Apr)
[![commit activity](https://img.shields.io/github/commit-activity/y/isis-santos-costa/growth-marketing)](https://github.com/isis-santos-costa/growth-marketing/)
[![Data Analyst](https://img.shields.io/badge/%20data%20analyst-%E2%98%95-purple)](https://www.linkedin.com/in/isis-santos-costa/)   

<!-- -------------------------------------------------------------------------------------------------------------------------------------->
<!-- Intro -->
#  Growth marketing analysis (WIP)
🧐 __*A/B Testing & GROWTH Analysis • 2023*__
&nbsp;&nbsp;<img src='https://github.com/isis-santos-costa/isis-santos-costa/blob/main/img/Looker-Studio.png'   height=36 alt='Looker Studio'   valign='middle'></img>
&nbsp;&nbsp;<img src='https://github.com/isis-santos-costa/isis-santos-costa/blob/main/img/Google-BigQuery.png' height=36 alt='Google BigQuery' valign='middle'></img>
&nbsp;&nbsp;<img src='https://github.com/isis-santos-costa/isis-santos-costa/blob/main/img/SQL.png'             height=36 alt='SQL'             valign='middle'></img>  

This repository presents the **analysis of an A/B test**, and visually summarizes **departmental growth trends** for sales data of a hypothetical **retail store**. For A/B testing, revenues are compared following different marketing campaign versions sent to **a base of 110,000 customers**. For departmental growth analysis, **8,234 sales transactions** from two subsequent years are summarized using different **data visualization** approaches to (i) display the **department ranking** in terms of growth, year-over-year (YoY), (ii) **reveal large-scale shifts in purchasing habits** of subsets of customers, and (iii) **unveil overall trends across departments**, to be mitigated and to be boosted, **for future growth**.  

The detailed analysis of the A/B testing is presented below, as well as the final visualizations answering to business questions on departmental growth. The SQL code used in analyzing departmental growth are available in the repository directory, and the one used in the A/B analysis (v.2.5.1) is available [here](https://github.com/isis-santos-costa/growth-marketing/blob/51b0ab7d7a5aef18f99a279130488e04b6bc50f7/campaign_a_vs_b.sql) and on [BigQuery](https://console.cloud.google.com/bigquery?sq=223570122894:545353684b9a417e91434b62d2a23de2).  

For readability, code snippets along the text are collapsed by default. Please, click '⏵' to expand.  

Tags: `growth`, `analytics`, `ab-testing`  

___

<!-- -------------------------------------------------------------------------------------------------------------------------------------->
<!-- Body -->
# Executive Summary

[<img src='img/growth-marketing-analysis.png' />](https://docs.google.com/presentation/d/e/2PACX-1vT2yxVCsu9-GdrpG_4nMwfy12o2fSy7Lo31T8bFn3PI9Ic8AArolBb5uaBdZHwtF8L3aUkPv_ONVJCv/pub?start=true&loop=false&delayms=60000)
___

<!---------------------------------------------------------------------------------------------------------------------------------------->
<!-- Contents -->

## Contents  

[Step 1 • Business question](#step-1--business-question)  
[Step 2 • Data collection](#step-2--data-collection)  
[Step 3 • Data wrangling](#step-3--data-wrangling)  
[Step 4 • Analysis](#step-4--analysis)  
[Step 5 • Synthesis](#step-5--synthesis)  

___

<!---------------------------------------------------------------------------------------------------------------------------------------->
<!-- Resources -->

## Resources  

[Spreadsheet • Google Sheets](https://docs.google.com/spreadsheets/d/1H8AvUnwQO8APc5vr6cfUISoxNP9Sx38o/edit?usp=sharing&ouid=106534574815446903983&rtpof=true&sd=true)  
[SQL Code • (on BigQuery)](https://console.cloud.google.com/bigquery?sq=223570122894:545353684b9a417e91434b62d2a23de2)  
[SQL Code • (Github file)](https://github.com/isis-santos-costa/growth-marketing/blob/51b0ab7d7a5aef18f99a279130488e04b6bc50f7/campaign_a_vs_b.sql)  

___

<!---------------------------------------------------------------------------------------------------------------------------------------->
<!-- Query structure -->

## Query structure  

[Parameter &nbsp; |&nbsp; % Tolerance to split unbalance in A/B testing](#parameter----tolerance-to-split-unbalance-in-ab-testing)  
[Function 1 &nbsp;|&nbsp; Standardizing factor for subsets with unbalanced split in the A/B test](#function-1--standardizing-factor-for-subsets-with-unbalanced-split-in-the-ab-test)  
[Function 2 &nbsp;|&nbsp; Standardized values](#function-2--standardized-values)  
[Function 3 &nbsp;|&nbsp; Winning Campaign, considering Standardization](#function-3--winning-campaign-considering-standardization)  
[Function 4 &nbsp;|&nbsp; Standardized % advantage of the Winning Campaign](#function-4--standardized--advantage-of-the-winning-campaign)  
[CTE &nbsp;&nbsp;1 &nbsp;|&nbsp; Campaign results | Overall](#cte-1--campaign-results--overall)  
[CTE &nbsp;&nbsp;2 &nbsp;|&nbsp; Campaign results | by Customer Segment](#cte-2--campaign-results--by-customer-segment)  
[CTE &nbsp;&nbsp;3 &nbsp;|&nbsp; Campaign results | by Customer Profile](#cte-3--campaign-results--by-customer-profile)  
[CTE &nbsp;&nbsp;4 &nbsp;|&nbsp; Campaign results | Overall & by Customer Segment & by Customer Profile | Long Table](#cte-4--campaign-results--overall--by-segment--by-profile--long-table)  
[CTE &nbsp;&nbsp;5 &nbsp;|&nbsp; Campaign results | Winning as per Net Revenue | showing also by other criteria | Wide Table](#cte-5--campaign-results--as-per-net-revenue--wide-table)  
[CTE &nbsp;&nbsp;6 &nbsp;|&nbsp; Campaign results | Winning as per STANDARDIZED Net Revenue | showing also other criteria | Wide Table](#cte-6--campaign-results--as-per-standardized-net-revenue--wide-table)  
[CTE &nbsp;&nbsp;7 &nbsp;|&nbsp; Campaign results | Winning as per STANDARDIZED Net Revenue | with OVERALL total of STD values](#cte-7--campaign-results--as-per-standardized-net-revenue--overall-total)  
[CTE &nbsp;&nbsp;8 &nbsp;|&nbsp; Campaign results | Winning as per STANDARDIZED Net Revenue | with OVERALL total and % of STD values](#cte-8--campaign-results--as-per-standardized-net-revenue--overall-total--)  
[Unit tests / Final query](#unit-tests--final-query)  

___

<!---------------------------------------------------------------------------------------------------------------------------------------->
<!-- Step 1 -->

## Step 1 • Business question  

The search in the A/B testing is for insight into the following question and its unfoldings:

> <i> « Overall, which version generated better incremental results? » </i>  
>> <i> « Did a particular version perform better for a particular set of customers? » </i>  
>> <i> « What changes can be made to this marketing campaign in order to improve future results? » </i>  

For departmental growth, the analysis aims at answering:

> <i> « Overall, which Department grew the most from year to year? » </i>  
> <i> « Are there any particular groups of customers that are showing notable shifts in their purchasing habits from year to year? » </i>  
> <i> « Based on this data, what marketing efforts or strategies will reinforce positive trends or mitigate negative trends to grow future sales? » </i>  

[↑](#contents)

___

<!---------------------------------------------------------------------------------------------------------------------------------------->
<!-- Step 2 -->

## Step 2 • Data collection  

The data sets for the analysis were exported from a [spreadsheet](https://docs.google.com/spreadsheets/d/1H8AvUnwQO8APc5vr6cfUISoxNP9Sx38o/edit?usp=sharing&ouid=106534574815446903983&rtpof=true&sd=true) into csv files, with naming tidied up in `snake_case`:

![csv-files](https://github.com/isis-santos-costa/growth-marketing/assets/58894233/f7e24458-4fca-40fd-a1af-959a93d4356e)

The files were then loaded into BigQuery following the steps [presented in this repository](https://github.com/isis-santos-costa/kaggle-datasets-in-bigquery):

![image](https://github.com/isis-santos-costa/growth-marketing/assets/58894233/059f68c4-c295-4f07-8bb6-5ebf480b4ec7)

[↑](#contents)

___

<!---------------------------------------------------------------------------------------------------------------------------------------->
<!-- Step 3 -->

## Step 3 • Data wrangling  

**The A/B test at hand refers to a base of 110,000 customers.** The base was split into two exact halves, and the customers in each of them received one version of a marketing campaign, A or B.

**Success** is measured in terms of the **revenue attributable to the campaing**, defined as the total value of purchases by the customer above what would have happened without the campaing, which is simulated by means of keeping a control group, a set of customers who are not exposed to the campaign.

While the overall split between A and B has targeted the exact half of customers with each of the marketing campaign versions, data is not evenly splitted for some groups of customers, at the subset level. Thus, in order to enable performance comparisons at the customer subset level, data has to be standardized, with A/B revenues being scaled to emulate a 50/50.

This is performed by multiplying the revenue by a factor calculated as 50 divided by the corresponding percentage of customers receiving that campaign version in the considered subset. For example, supposing in a certain subset **70% of customers were targeted with campaign A** and the other **30% with B**, the revenues would be **scaled to 50/50** as follows:

<p align='center'> 
  $standardized\_revenue_A = (revenue_A) × (50/70)$<br>
  $standardized\_revenue_B = (revenue_B) × (50/30)$
</p>

Standardization was performed as follows:  
> (i)   Setting a **parameter** for the tolerance to deviation from 50/50  
> (ii)  Calculating **standardizing factors** for customer subsets with unbalanced split  
> (iii) **Standardizing** substsets of revenues  
> (iv)  Assessing the **winning campaign**, based on standardized revenues  
> (v)   Calculating the **% standardized advantage** of the winning campaign  

As these calculations are performed multiple times along the query that generates the A/B testing analysis report, they were defined as temporary functions in [BigQuery](https://console.cloud.google.com/bigquery?sq=223570122894:545353684b9a417e91434b62d2a23de2). The SQL code corresponding to each step is presented below:  

<details><summary>
    
### Parameter &nbsp; |&nbsp; % Tolerance to split unbalance in A/B testing

</summary>
  
```sql
---------------------------------------------------------------------------------------------------------------------------------------------------------
-- Parameter • % Tolerance to split unbalance in A/B testing (see details on comments to CTE 6 `a_vs_b_standardized`)
---------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE pct_tolerance_to_split_unbalance FLOAT64 DEFAULT 5;
```
</details>


<details><summary>
    
### Function 1 &nbsp;|&nbsp; Standardizing factor for subsets with unbalanced split in the A/B test

</summary>
  
```sql
---------------------------------------------------------------------------------------------------------------------------------------------------------
-- Function 1 • Standardizing factor for subsets with unbalanced split in A/B testing (see details on comments to CTE 6 `a_vs_b_standardized`)
---------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TEMPORARY FUNCTION std_factor(pct_customer FLOAT64, pct_tolerance_to_split_unbalance FLOAT64) AS (
  CASE WHEN ABS(50 - pct_customer) > pct_tolerance_to_split_unbalance THEN (50 / pct_customer) ELSE 1 END
);
```
</details>


<details><summary>

### Function 2 &nbsp;|&nbsp; Standardized values

</summary>
  
```sql
---------------------------------------------------------------------------------------------------------------------------------------------------------
-- Function 2 • Standardized values (see details on comments to CTE 6 `a_vs_b_standardized`)
---------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TEMPORARY FUNCTION std_value(pct_customer FLOAT64, pct_tolerance_to_split_unbalance FLOAT64, original_value FLOAT64, level_id INT64) AS (
  CASE WHEN level_id = 0 THEN NULL
  ELSE std_factor(pct_customer, pct_tolerance_to_split_unbalance) * original_value END
);
```
</details>


<details><summary>

### Function 3 &nbsp;|&nbsp; Winning Campaign, considering Standardization  

</summary>
  
```sql
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
```
</details>


<details><summary>

### Function 4 &nbsp;|&nbsp; Standardized % advantage of the Winning Campaign  

</summary>
  
```sql
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
```
</details>


[↑](#contents)

___

<!---------------------------------------------------------------------------------------------------------------------------------------->
<!-- Step 4 -->

## Step 4 • Analysis  

<details><summary>

### CTE &nbsp;&nbsp;1 &nbsp;|&nbsp; Campaign results | Overall

</summary>
  
```sql
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
    , i.name AS campaign
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
  JOIN `acadia_growth.campaign_version_info`    i     ON i.id = v.campaign_version  
  GROUP BY campaign_version, campaign
)
```
</details>


<details><summary>

### CTE &nbsp;&nbsp;2 &nbsp;|&nbsp; Campaign results | by Customer Segment

</summary>
  
```sql
---------------------------------------------------------------------------------------------------------------------------------------------------------
-- CTE 2 • Results of campaigns A and B | by Customer Segment
---------------------------------------------------------------------------------------------------------------------------------------------------------
, by_segment AS (
  SELECT
    c.segment_id
    , NULL AS profile_id
    , sgmt.name AS segment_name
    , COUNT(c.id) AS campaign_base_customer_cnt
    , v.campaign_version
    , i.name AS campaign
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
  JOIN `acadia_growth.campaign_version_info`    i     ON i.id = v.campaign_version
  GROUP BY c.segment_id, segment_name, campaign_version, campaign
)
```
</details>


<details><summary>

### CTE &nbsp;&nbsp;3 &nbsp;|&nbsp; Campaign results | by Customer Profile

</summary>
  
```sql
---------------------------------------------------------------------------------------------------------------------------------------------------------
-- CTE 3 • Results of campaigns A and B | by Customer Profile
---------------------------------------------------------------------------------------------------------------------------------------------------------
, by_profile AS (
  SELECT
    NULL AS segment_id
    , c.profile_id
    , p.name AS profile_name
    , COUNT(c.id) AS campaign_base_customer_cnt
    , v.campaign_version
    , i.name AS campaign
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
  JOIN `acadia_growth.campaign_version_info`    i     ON i.id = v.campaign_version
  WHERE c.profile_id IS NOT NULL
  GROUP BY c.profile_id, profile_name, campaign_version, campaign
)
```
</details>


<details><summary>

### CTE &nbsp;&nbsp;4 &nbsp;|&nbsp; Campaign results | Overall & by Segment & by Profile | Long Table

</summary>
  
```sql
---------------------------------------------------------------------------------------------------------------------------------------------------------
-- CTE 4 • Long Table: Results of campaigns A and B | Overall & by Customer Segment & by Customer Profile
---------------------------------------------------------------------------------------------------------------------------------------------------------
, long_table AS (
  SELECT * FROM overall    UNION ALL 
  SELECT * FROM by_segment UNION ALL 
  SELECT * FROM by_profile
)
```
</details>


<details><summary>

### CTE &nbsp;&nbsp;5 &nbsp;|&nbsp; Campaign results | as per Net Revenue | Wide Table

</summary>
  
```sql
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
```
</details>


<details><summary>

### CTE &nbsp;&nbsp;6 &nbsp;|&nbsp; Campaign results | as per STANDARDIZED Net Revenue | Wide Table

</summary>
  
```sql
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
```
![image](https://github.com/isis-santos-costa/growth-marketing/assets/58894233/b20fcb1e-e788-4884-bbcb-1b47ee5bcf7b)

</details>


<details><summary>

### CTE &nbsp;&nbsp;7 &nbsp;|&nbsp; Campaign results | as per STANDARDIZED Net Revenue | OVERALL total

</summary>
  
```sql
---------------------------------------------------------------------------------------------------------------------------------------------------------
-- CTE 7 • Results of campaigns A and B | Winning Campaign defined by STANDARDIZED Net Revenue | with OVERALL total of STD values
---------------------------------------------------------------------------------------------------------------------------------------------------------
, a_vs_b_std_w_overall AS (
  SELECT
    level_of_analysis
    , level_id
    , level_name
    , campaign_base_customer_cnt
    , pct_customer_A
    , pct_customer_B
    , winning_campaign
    , std_pct_revenue_advantage_of_winning_campaign
    , CASE WHEN level_id = 0 THEN SUM(CASE WHEN level_of_analysis='segment' THEN std_campaign_net_revenue_A END) OVER () 
           ELSE std_campaign_net_revenue_A END 
           AS std_campaign_net_revenue_A
    , CASE WHEN level_id = 0 THEN SUM(CASE WHEN level_of_analysis='segment' THEN std_campaign_net_revenue_B END) OVER () 
           ELSE std_campaign_net_revenue_B END 
           AS std_campaign_net_revenue_B 
    , std_pct_lifted_revenue_advantage_of_winning_campaign
    , CASE WHEN level_id = 0 THEN SUM(CASE WHEN level_of_analysis='segment' THEN std_campaign_lifted_revenue_A END) OVER () 
           ELSE std_campaign_lifted_revenue_A END 
           AS std_campaign_lifted_revenue_A
    , CASE WHEN level_id = 0 THEN SUM(CASE WHEN level_of_analysis='segment' THEN std_campaign_lifted_revenue_B END) OVER () 
           ELSE std_campaign_lifted_revenue_B END 
           AS std_campaign_lifted_revenue_B
    , pct_med_lifted_spend_advantage_of_winning_campaign
    , med_lifted_spend_A
    , med_lifted_spend_B
    , std_pct_lifted_customer_cnt_advantage_of_winning_campaign
    , CASE WHEN level_id = 0 THEN SUM(CASE WHEN level_of_analysis='segment' THEN std_lifted_customer_cnt_A END) OVER () 
           ELSE std_lifted_customer_cnt_A END 
           AS std_lifted_customer_cnt_A
    , CASE WHEN level_id = 0 THEN SUM(CASE WHEN level_of_analysis='segment' THEN std_lifted_customer_cnt_B END) OVER () 
           ELSE std_lifted_customer_cnt_B END 
           AS std_lifted_customer_cnt_B
    , std_pct_churned_revenue_advantage_of_winning_campaign
    , CASE WHEN level_id = 0 THEN SUM(CASE WHEN level_of_analysis='segment' THEN std_campaign_churned_revenue_A END) OVER () 
           ELSE std_campaign_churned_revenue_A END 
           AS std_campaign_churned_revenue_A
    , CASE WHEN level_id = 0 THEN SUM(CASE WHEN level_of_analysis='segment' THEN std_campaign_churned_revenue_B END) OVER () 
           ELSE std_campaign_churned_revenue_B END 
           AS std_campaign_churned_revenue_B
    , pct_med_churned_spend_advantage_of_winning_campaign
    , med_churned_spend_A
    , med_churned_spend_B
    , std_pct_churning_customer_cnt_advantage_of_winning_campaign
    , CASE WHEN level_id = 0 THEN SUM(CASE WHEN level_of_analysis='segment' THEN std_churning_customer_cnt_A END) OVER () 
           ELSE std_churning_customer_cnt_A END 
           AS std_churning_customer_cnt_A
    , CASE WHEN level_id = 0 THEN SUM(CASE WHEN level_of_analysis='segment' THEN std_churning_customer_cnt_B END) OVER () 
           ELSE std_churning_customer_cnt_B END 
           AS std_churning_customer_cnt_B
  FROM a_vs_b_standardized
)
```

![image](https://github.com/isis-santos-costa/growth-marketing/assets/58894233/7cfacc57-dc53-4ab7-912d-5bd0ae3ed012)

</details>


<details><summary>

### CTE &nbsp;&nbsp;8 &nbsp;|&nbsp; Campaign results | as per STANDARDIZED Net Revenue | OVERALL total + %

</summary>
  
```sql
---------------------------------------------------------------------------------------------------------------------------------------------------------
-- CTE 8 • OUTPUT: Results of campaigns A and B | Winning Campaign defined by STANDARDIZED Net Revenue | with OVERALL total and % of STD values
---------------------------------------------------------------------------------------------------------------------------------------------------------
, a_vs_b AS (
  SELECT
    level_of_analysis
    , level_id
    , level_name
    , campaign_base_customer_cnt
    , pct_customer_A
    , pct_customer_B
    , CASE WHEN std_campaign_net_revenue_A > std_campaign_net_revenue_B THEN 'A | 99% Off' ELSE 'B | BOGO' END AS winning_campaign
    , CAST(100.0 * (
      CASE WHEN std_campaign_net_revenue_A >= std_campaign_net_revenue_B THEN std_campaign_net_revenue_A ELSE std_campaign_net_revenue_B END / 
      CASE WHEN std_campaign_net_revenue_A <  std_campaign_net_revenue_B THEN std_campaign_net_revenue_A ELSE std_campaign_net_revenue_B END 
      - 1) AS INT64) AS std_pct_revenue_advantage_of_winning_campaign
    , std_campaign_net_revenue_A
    , std_campaign_net_revenue_B
    , CAST(100.0 * (
      CASE WHEN std_campaign_net_revenue_A >= std_campaign_net_revenue_B THEN std_campaign_lifted_revenue_A ELSE std_campaign_lifted_revenue_B END / 
      CASE WHEN std_campaign_net_revenue_A <  std_campaign_net_revenue_B THEN std_campaign_lifted_revenue_A ELSE std_campaign_lifted_revenue_B END 
      - 1) AS INT64) AS std_pct_lifted_revenue_advantage_of_winning_campaign
    , std_campaign_lifted_revenue_A
    , std_campaign_lifted_revenue_B
    , CAST(100.0 * (
      CASE WHEN std_campaign_net_revenue_A >= std_campaign_net_revenue_B THEN med_lifted_spend_A ELSE med_lifted_spend_B END / 
      CASE WHEN std_campaign_net_revenue_A <  std_campaign_net_revenue_B THEN med_lifted_spend_A ELSE med_lifted_spend_B END 
      - 1) AS INT64) AS pct_med_lifted_spend_advantage_of_winning_campaign
    , med_lifted_spend_A
    , med_lifted_spend_B
    , CAST(100.0 * (
      CASE WHEN std_campaign_net_revenue_A >= std_campaign_net_revenue_B THEN std_lifted_customer_cnt_A ELSE std_lifted_customer_cnt_B END / 
      CASE WHEN std_campaign_net_revenue_A <  std_campaign_net_revenue_B THEN std_lifted_customer_cnt_A ELSE std_lifted_customer_cnt_B END 
      - 1) AS INT64) AS std_pct_lifted_customer_cnt_advantage_of_winning_campaign
    , std_lifted_customer_cnt_A
    , std_lifted_customer_cnt_B 
    , - CAST(100.0 * (
      CASE WHEN std_campaign_net_revenue_A >= std_campaign_net_revenue_B THEN std_campaign_churned_revenue_A ELSE std_campaign_churned_revenue_B END / 
      CASE WHEN std_campaign_net_revenue_A <  std_campaign_net_revenue_B THEN std_campaign_churned_revenue_A ELSE std_campaign_churned_revenue_B END 
      - 1) AS INT64) AS std_pct_churned_revenue_advantage_of_winning_campaign
    , std_campaign_churned_revenue_A
    , std_campaign_churned_revenue_B
    , - CAST(100.0 * (
      CASE WHEN std_campaign_net_revenue_A >= std_campaign_net_revenue_B THEN med_churned_spend_A ELSE med_churned_spend_B END / 
      CASE WHEN std_campaign_net_revenue_A <  std_campaign_net_revenue_B THEN med_churned_spend_A ELSE med_churned_spend_B END 
      - 1) AS INT64) AS pct_med_churned_spend_advantage_of_winning_campaign
    , med_churned_spend_A
    , med_churned_spend_B    
    , - CAST(100.0 * (
      CASE WHEN std_campaign_net_revenue_A >= std_campaign_net_revenue_B THEN std_churning_customer_cnt_A ELSE std_churning_customer_cnt_B END / 
      CASE WHEN std_campaign_net_revenue_A <  std_campaign_net_revenue_B THEN std_churning_customer_cnt_A ELSE std_churning_customer_cnt_B END 
      - 1) AS INT64) AS std_pct_churning_customer_cnt_advantage_of_winning_campaign
    , std_churning_customer_cnt_A
    , std_churning_customer_cnt_B
  FROM a_vs_b_std_w_overall
)
```

![image](https://github.com/isis-santos-costa/growth-marketing/assets/58894233/b93c2b92-db3c-4bfb-8363-43d3fb5ec563)

</details>


<details><summary>

### Unit tests / Final query

</summary>
  
```sql
---------------------------------------------------------------------------------------------------------------------------------------------------------
-- Unit tests / Final query
---------------------------------------------------------------------------------------------------------------------------------------------------------
-- SELECT * FROM overall;
-- SELECT * FROM by_segment;
-- SELECT * FROM by_profile;
-- SELECT * FROM long_table ORDER BY profile_id NULLS FIRST, segment_id NULLS FIRST, campaign_version;
-- SELECT * FROM a_vs_b_raw           ORDER BY CASE WHEN level_of_analysis='overall' THEN 1 WHEN level_of_analysis='segment' THEN 2 ELSE 3 END, level_id;
-- SELECT * FROM a_vs_b_standardized  ORDER BY CASE WHEN level_of_analysis='overall' THEN 1 WHEN level_of_analysis='segment' THEN 2 ELSE 3 END, level_id;
-- SELECT * FROM a_vs_b_std_w_overall ORDER BY CASE WHEN level_of_analysis='overall' THEN 1 WHEN level_of_analysis='segment' THEN 2 ELSE 3 END, level_id;
   SELECT * FROM a_vs_b               ORDER BY CASE WHEN level_of_analysis='overall' THEN 1 WHEN level_of_analysis='segment' THEN 2 ELSE 3 END, level_id;
---------------------------------------------------------------------------------------------------------------------------------------------------------
```
</details>


[↑](#contents)

___

<!---------------------------------------------------------------------------------------------------------------------------------------->
<!-- Step 5 -->

## Step 5 • Synthesis  

The A/B testing assessment is summarized in the following image. **Version B** of the marketing campaign is identified as the **overall winning one**, with **version A being successful for some customer profiles**. It stands out that, although A had shown clear advantage in some subsets, it does not happen for segments. A remark is made here: all customers are classified into a segment, not all customers are classified into a profile. Segments are derived from data, based on transaction history. Profiles result from survey, being defined according to cusstomer demography and general traits.

The practical result of the study is a **mapping of A/B preferences at the customer subset level**, as a tool to potencialize future results.

![image](https://github.com/isis-santos-costa/growth-marketing/assets/58894233/71473c11-2dba-4314-8359-f283fd94a7e7)

Regarding **departmental growth**, answer to th first question, on which department grew the most in the period, is presented in the image below. The horizontal axis in the chart was set to logarithmic, in order that growth is emphasized, rather than volumes. It can be seen that **'Boots' is the top performer**, in % growth. The colossal value, together with a relative small sales volume in the first year of the period, points out to a presumed recent introduction of the department.

Following it, the **second largest** increase in sales is observed for related department **'Boot Accessories'**.

![image](https://github.com/isis-santos-costa/growth-marketing/assets/58894233/ff87fda4-b0b0-4821-bf68-b8153f6988d5)

A **breakdown** of **% growth by department and subset of customers** is presented in the picture below. The noticeable red region blooding into the green growth region to the left of the image, indicates a **risk of churning** of the key segments of **'Power Shoppers'** and **'Core Customers'**. For the subsets of profiles, **'City Slickers'**, **'Blue Collar Royalty'** and **'Normal Families'** present an overall concerning trend.

![image](https://github.com/isis-santos-costa/growth-marketing/assets/58894233/d84e4331-ce12-45af-a9cc-b931c1e60db1)

**Shifts in purchasing habits** can be observed from the chart below. The **left region records decreases in sales**, and **tones of gray** were attributed to the departments with most of their sales falling into this region, indicating their **trend towards vanishing**. Departments in this situation are 'Miscellaneous' (Misc), 'Women's Jeans', 'Beachwear', and 'Formalwear'. The colorful bars on the right side of the chart indicate positive sales, compared to the previous year, and reveal a **strong positive trend for thematic departments** of **'Boots'**, **'Boot Accesssories'**, and **'Cowboys' Hats'**.  

The chart is a **powerful tool** for data-informed decision making, **concisely summarizing critical information** for strategic positioning. It can support, e.g., the definition of a plan to **recover and retain** the 'gray' departments, or to **go all-in** and reinforce with initiatives, campaigns, and visual identity **the observed thematic trend**.

![image](https://github.com/isis-santos-costa/growth-marketing/assets/58894233/4b7e9b85-a3f4-4b8f-82b6-1c02ba2a551b)

The study is summarized in the presentation [here](https://docs.google.com/presentation/d/e/2PACX-1vT2yxVCsu9-GdrpG_4nMwfy12o2fSy7Lo31T8bFn3PI9Ic8AArolBb5uaBdZHwtF8L3aUkPv_ONVJCv/pub?start=true&loop=false&delayms=60000) and in the leaflet below:

![Growth marketing analysis](https://raw.githubusercontent.com/isis-santos-costa/growth-marketing/main/img/growth-marketing-analysis.png)

[↑](#contents)

___

<!---------------------------------------------------------------------------------------------------------------------------------------->
