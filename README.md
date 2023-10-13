<!-- -------------------------------------------------------------------------------------------------------------------------------------->
<!-- Metadata badges -->

[![pull requests](https://img.shields.io/github/issues-pr-closed/isis-santos-costa/growth-marketing?color=brightgreen)](https://github.com/isis-santos-costa/growth-marketing/pulls?q=is%3Apr)
[![commit activity](https://img.shields.io/github/commit-activity/y/isis-santos-costa/growth-marketing)](https://github.com/isis-santos-costa/growth-marketing/)
[![Data Analyst](https://img.shields.io/badge/%20data%20analyst-%E2%98%95-purple)](https://www.linkedin.com/in/isis-santos-costa/)   

<!-- -------------------------------------------------------------------------------------------------------------------------------------->
<!-- Intro -->
#  Growth marketing analysis (WIP)
🧐 __*A/B Testing & GROWTH Analysis • 2023*__
&nbsp;&nbsp;<img src='https://github.com/isis-santos-costa/growth-marketing/assets/58894233/f07607fb-0030-4d13-9b93-6cbb66a5ef57' height=36 alt='Google-BigQuery' valign='middle'></img>
&nbsp;&nbsp;<img src='https://github.com/isis-santos-costa/growth-marketing/assets/58894233/7cf85c82-ca7d-4d2e-a1c0-b22a78ae42a2' height=36 alt='SQL' valign='middle'></img>  

This repository presents the **analysis of an A/B test**, and visually summarizes **departmental growth trends** for sales data of a hypothetical **retail store**. For A/B testing, revenues are compared following different marketing campaign versions sent to **a base of 110,000 customers**. For departmental growth analysis, **8,234 sales transactions** from two subsequent years are summarized using different **data visualization** approaches to (i) display the **department ranking** in terms of growth, year-over-year (YoY), (ii) **reveal large-scale shifts in purchasing habits** of subsets of customers, and (iii) **unveil overall trends across departments**, to be mitigated and to be boosted, **for future sales growth**.  

The detailed analysis of the A/B testing is presented below, as well as the final visualizations answering to business questions on departmental growth. The SQL code used in analyzing departmental growth are available in the repository directory, and the one used in the A/B analysis (v.2.5.1) is available [here](https://github.com/isis-santos-costa/growth-marketing/blob/51b0ab7d7a5aef18f99a279130488e04b6bc50f7/campaign_a_vs_b.sql) and on [BigQuery](https://console.cloud.google.com/bigquery?sq=223570122894:545353684b9a417e91434b62d2a23de2).  


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

[Parameter &nbsp; |&nbsp; % Tolerance to split unbalance in A/B testing]()  
[Function 1 &nbsp;|&nbsp; Standardizing factor for subsets with unbalanced split in the A/B test]()  
[Function 2 &nbsp;|&nbsp; Standardized values]()  
[Function 3 &nbsp;|&nbsp; Winning Campaign, considering Standardization]()  
[Function 4 &nbsp;|&nbsp; Standardized % advantage of the Winning Campaign]()  
[CTE &nbsp;&nbsp;1 &nbsp;|&nbsp; Campaign results | Overall]()  
[CTE &nbsp;&nbsp;2 &nbsp;|&nbsp; Campaign results | by Customer Segment]()  
[CTE &nbsp;&nbsp;3 &nbsp;|&nbsp; Campaign results | by Customer Profile]()  
[CTE &nbsp;&nbsp;4 &nbsp;|&nbsp; Campaign results | Overall & by Customer Segment & by Customer Profile | Long Table]()  
[CTE &nbsp;&nbsp;5 &nbsp;|&nbsp; Campaign results | Winning as per Net Revenue | showing also by other criteria | Wide Table]()  
[CTE &nbsp;&nbsp;6 &nbsp;|&nbsp; Campaign results | Winning as per STANDARDIZED Net Revenue | showing also other criteria | Wide Table]()  
[CTE &nbsp;&nbsp;7 &nbsp;|&nbsp; Campaign results | Winning as per STANDARDIZED Net Revenue | with OVERALL total of STD values]()  
[CTE &nbsp;&nbsp;8 &nbsp;|&nbsp; Campaign results | Winning as per STANDARDIZED Net Revenue | with OVERALL total and % of STD values]()  
[Unit tests / Final query]()  

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

Standardization was performed in three steps:  
> (i)   Setting a **parameter** for the tolerance to deviation from 50/50  
> (ii)  Calculating **standardizing factors** for customer subsets with unbalanced split  
> (iii) **Standardizing** substsets of revenues  

As these calculations are performed multiple times along the query that generates the A/B testing analysis report, they were defined as temporary functions in [BigQuery](https://console.cloud.google.com/bigquery?sq=223570122894:545353684b9a417e91434b62d2a23de2). The SQL code corresponding to each step is presented below:

### Parameter &nbsp; |&nbsp; % Tolerance to split unbalance in A/B testing
```sql
---------------------------------------------------------------------------------------------------------------------------------------------------------
-- Parameter • % Tolerance to split unbalance in A/B testing (see details on comments to CTE 6 `a_vs_b_standardized`)
---------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE pct_tolerance_to_split_unbalance FLOAT64 DEFAULT 5;
```

### Function 1 &nbsp;|&nbsp; Standardizing factor for subsets with unbalanced split in the A/B test
```sql
---------------------------------------------------------------------------------------------------------------------------------------------------------
-- Function 1 • Standardizing factor for subsets with unbalanced split in A/B testing (see details on comments to CTE 6 `a_vs_b_standardized`)
---------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TEMPORARY FUNCTION std_factor(pct_customer FLOAT64, pct_tolerance_to_split_unbalance FLOAT64) AS (
  CASE WHEN ABS(50 - pct_customer) > pct_tolerance_to_split_unbalance THEN (50 / pct_customer) ELSE 1 END
);
```

### Function 2 &nbsp;|&nbsp; Standardized values
```sql
---------------------------------------------------------------------------------------------------------------------------------------------------------
-- Function 2 • Standardized values (see details on comments to CTE 6 `a_vs_b_standardized`)
---------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TEMPORARY FUNCTION std_value(pct_customer FLOAT64, pct_tolerance_to_split_unbalance FLOAT64, original_value FLOAT64, level_id INT64) AS (
  CASE WHEN level_id = 0 THEN NULL
  ELSE std_factor(pct_customer, pct_tolerance_to_split_unbalance) * original_value END
);
```

[↑](#contents)

___

