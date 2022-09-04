CREATE DATABASE data_mart;
USE data_mart;
/*  IMPORTANT NOTES
- Week 0: The first week of a year
- Week 52: The last week of a year
- The sales metric 'actual value' represents the difference between the total sum of sales before and after the specified time period.
- The sales metric 'percent' value represents the growth rate or the reduction rate between a specified time period.
There are incomplete weekly records for the months of September and March.To avoid bias, insights drawn based on MONTHS for both September and March would excluded.
*/
-- PART A (Data Cleansing Steps)
DROP TABLE IF EXISTS clean_weekly_sales;
CREATE TABLE clean_weekly_sales (
id INT,
week_date DATE,
week_number INT,
month_number INT,
calendar_year INT,
region VARCHAR(13),
platform VARCHAR(7),
segment VARCHAR(10),
age_band VARCHAR(25),
demographics VARCHAR(10),
customer_type VARCHAR(8),
transactions INT,
sales INT,
avg_transactions FLOAT,
PRIMARY KEY(id)
);
/* Using a single query to clean the data. I created a subquery which consisted of the STR_TO_DATE function that converted the week_date in string format to DATE data type. 
Also I used multiple CASE statements to return matching values in this process I got rid of all 'null' instances and replaced then with 'unknown'. 
Then I calculated for the 'avg_transactions' column dividng the sales by the number of transaction*/ 
INSERT INTO clean_weekly_sales(id, week_date, week_number, month_number, calendar_year, region, platform, segment, age_band, demographics, customer_type, transactions, sales,avg_transactions)
SELECT id, week_date, WEEK(week_date) week_number, MONTH(week_date) month_number, YEAR(week_date) calendar_year,
 region, platform, segment, age_band, demographics, customer_type, transactions, sales, avg_transactions
   FROM(
		SELECT id, STR_TO_DATE(week_date,'%d/%m/%y') week_date, region,platform,customer_type,transactions, sales,ROUND((Sales/transactions),2) avg_transactions,
        CASE WHEN segment LIKE '_1' THEN 'Young Adults'
		WHEN segment LIKE '_2' THEN 'Middle Aged'
        WHEN segment LIKE '_3' OR segment LIKE '_4' THEN 'Retirees'
        ELSE 'unknown' END AS age_band,
        CASE WHEN segment LIKE 'C%' THEN 'Couples'
		WHEN segment LIKE 'F%' THEN 'Families'
		ELSE 'unknown' END AS demographics,
        CASE WHEN segment LIKE 'C%' OR segment LIKE 'F%' THEN segment ELSE 'unknown' END AS segment
		FROM weekly_sales) cleaning;

SELECT *
FROM clean_weekly_sales;
SELECT WEEK('2020-12-31');

-- PART B (Data Exploration)

-- 1. What day of the week is used for each week_date value?
/* I used the **DAYNAME** function to return the coresponding name of each 'week_date'. I used the **GROUP BY** function to categorize the results*/
SELECT DAYNAME(week_date) day_of_week, COUNT(week_date) total_records
FROM clean_weekly_sales
GROUP BY 1;
/*Monday is the start day for every week_date in this datatset consiting of 17,117 records*/

-- 2. What range of week numbers are missing from the dataset?
/* I used the RECURSIVE CTE called numbers to generate a table with a column 'weeks' of values ranging from 0-52.
 Then used a nested query and the NOT IN function to filter weeks that are missing(not in the dataset)*/

WITH RECURSIVE numbers as(
					SELECT 0 AS weeks
                    UNION
                    SELECT weeks + 1
                    FROM numbers
                    WHERE weeks<52)
SELECT weeks FROM numbers 
WHERE weeks NOT IN (SELECT DISTINCT(week_number) weekly_number FROM clean_weekly_sales);
/*There are 29 weeks missing out of 53 weeks in a year from the dataset*/

-- 3. How many total transactions were there for each year in the dataset?
/*I used the SUM function to calculate the total number of transactions, the SUM function to calculate the total amount sold and used the GROUP BY function to categorize results per year*/ 
SELECT calendar_year, SUM(transactions) total_transactions, SUM(sales) total_amount
FROM clean_weekly_sales
GROUP BY 1;
/*From the results we can see there has been a steady increase in sales and in number of transactions carried out from 2018 till 2020*/

-- 4.  What is the total sales for each region for each month?
SELECT region, MONTHNAME(week_date) months, COUNT(sales) number_of_sales, SUM(sales) total_sales
FROM clean_weekly_sales
GROUP BY 1,2
ORDER BY 4 DESC,STR_TO_DATE(months,'%M');
/* 
The region of OCEANIA recorded the highest total_sales in April, May, June, July and August. 
Region with the peak sales was OCEANIA, occured in April with a total of 2,599,767,620 
Region with the least sales was EUROPE, occured in May with a total of 109,338,389. 
 */

-- 5. What is the total count of transactions for each platform
/* Check PART B Q3 for steps taken*/
SELECT platform, SUM(transactions) total_transactions, SUM(sales) total_sales
FROM clean_weekly_sales
GROUP BY 1;
/*
The Retail platform had 99.4% of the total transactions.
*/

-- 6. What is the percentage of sales for Retail vs Shopify for each month?
/* With a SUBQUERY, I used CASE statements to create two columns 'retail' and 'shopify' which consists of the total sales done through the Retail platform and the total sales done on the online platform(Shopify) respectively.
I calculated both platform's percentage of total sales and used a GROUP BY function to categorize both platforms and show records per month.*/
SELECT calendar_year, MONTHNAME(week_date) months, ROUND((SUM(retail)/SUM(total_sales))*100,1) retail_percent, ROUND((SUM(shopify)/SUM(total_sales))*100,1) shopify_percent
FROM(
		SELECT platform, calendar_year,month_number,week_date, SUM(sales) total_sales,
		CASE WHEN platform ='Retail' THEN SUM(sales) ELSE 0 END AS retail,
        CASE WHEN platform ='Shopify' THEN SUM(sales) ELSE 0 END AS shopify
		FROM clean_weekly_sales
        GROUP BY 1,4
		) sales_per_platform
GROUP BY month_number
ORDER BY 1,STR_TO_DATE(months,'%M');
/*The Retail platform accounts for over 97% of all sales but we can notice the slight consistent increase in the shopify platform sales over the year*/

-- 7. What is the percentage of sales by demographic for each year in the dataset?
/* Using multiple CASE statements I created columns with each demographic category. 
Then calculated the percentage of sales each demograpic category contributed to the total sales in each year.*/
SELECT calendar_year, ROUND((SUM(couples)/SUM(total_sales))*100,1) couples_percent, ROUND((SUM(families)/SUM(total_sales))*100,1) families_percent,
ROUND((SUM(unknowns)/SUM(total_sales))*100,1) unknowns_percent
FROM(
		SELECT demographics, calendar_year, week_date, SUM(sales) total_sales,
		CASE WHEN demographics ='Couples' THEN SUM(sales) ELSE 0 END AS couples,
        CASE WHEN demographics='Families' THEN SUM(sales) ELSE 0 END AS families,
        CASE WHEN demographics='unknown' THEN SUM(sales) ELSE 0 END AS unknowns
		FROM clean_weekly_sales
        GROUP BY 1,2
		) sales_per_platform
GROUP BY 1;
/* 
The "unknown" category cotributes the highest sales every year.
The yearly reduction of the "unknown" category can be mainly attributed to the increase in sales generated by the "Couples" and "Families" category. 
*/

-- 8. Which age_band and demographic values contribute the most to Retail sales?

SELECT demographics,age_band,SUM(sales) total_sales
FROM clean_weekly_sales
WHERE platform='Retail' AND demographics !='unknown'
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 1;
/* Here I added an additional filter condition to exclude the "unknown" demographic values and returned the next highest values*/

-- 9. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?
/* I was able to get my Average Transaction Size/Value(ATV) using the avg_transactions column since the column is calculated by using the total sales in a week divided by the total number of transactions in that same week. */
SELECT calendar_year, ROUND(SUM(retail),2) retail_atv, ROUND(SUM(shopify),2) shopify_atv
FROM(
		SELECT platform, calendar_year,week_date,
		CASE WHEN platform ='Retail' THEN AVG(avg_transactions) ELSE 0 END AS retail,
        CASE WHEN platform ='Shopify' THEN AVG(avg_transactions) ELSE 0 END AS shopify
		FROM clean_weekly_sales
        GROUP BY 1,2
		) atv_per_platform
GROUP BY 1;

-- PART C (Before & After Analysis)
/* 
This technique is usually used when we inspect an important event and want to inspect the impact before and after a certain point in time.
Taking the week_date value of 2020-06-15 as the baseline week where the Data Mart sustainable packaging changes came into effect.
We would include all week_date values for 2020-06-15 as the start of the period after the change and the previous week_date values would be before
Using this analysis approach - answer the following questions:
*/
-- 1. What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?
/*With the WHERE clause I set multiple conditions such as my start date and what range my week number can be found in. I used the WEEK function to return the coresponding week number of the date specified and the BETWEEN function to set boundaries
I subtracted the total sales before the change from the total sales after the change to get thee diffrence in value, I also calculated for the growth/reduction rate.*/
WITH after_changes AS(	SELECT SUM(sales) total_sales_after
						FROM clean_weekly_sales
						WHERE week_date>='2020-06-15' AND week_number BETWEEN WEEK('2020-06-15') AND WEEK('2020-06-15')+3),
before_changes AS(	SELECT SUM(sales) total_sales_before
						FROM clean_weekly_sales
						WHERE week_date<'2020-06-15' AND week_number BETWEEN WEEK('2020-06-15')-4 AND WEEK('2020-06-15')-1)
 SELECT (total_sales_after-total_sales_before) actual_value, ROUND(((total_sales_after-total_sales_before)/total_sales_before)*100,1) percent
 FROM after_changes,before_changes;
/* Comparing the growth/retention rate between the sum of sales, four weeks before implementing the Data Mart sustainable packaging changes and four weeks after implementing the changes . The rentention rate is -65.5% and the actutal value is -4,402,014,793 
*/

-- 2. What about the entire 12 weeks before and after?
WITH after_changes AS(	SELECT SUM(sales) total_sales_after
						FROM clean_weekly_sales
						WHERE week_date>='2020-06-15' AND week_number BETWEEN WEEK('2020-06-15') AND WEEK('2020-06-15')+11),
before_changes AS(	SELECT SUM(sales) total_sales_before
						FROM clean_weekly_sales
						WHERE week_date<'2020-06-15' AND week_number BETWEEN WEEK('2020-06-15')-12 AND WEEK('2020-06-15')-1)
 SELECT (total_sales_after-total_sales_before) actual_value, ROUND(((total_sales_after-total_sales_before)/total_sales_before)*100,1) percent
 FROM after_changes,before_changes;
/* Comparing the growth/retention rate between the sum of sales, four weeks before implementing the Data Mart sustainable packaging changes and four weeks after implementing the changes . The rentention rate is -65.8% and the actutal value is -13,432,274,108 
*/

-- 3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
/*In this query I assumed I was asked to calculate the 4weeks/12weeks before and after period for the year of 2020(third),2019(second) and 2018(first) using 2020-06-15 as the baseline week*/
-- FOR THE YEAR 2020
WITH before_third_12weeks AS( SELECT calendar_year,SUM(sales) sales_12weeks_before
				FROM clean_weekly_sales
				WHERE week_date<'2020-06-15' AND week_number BETWEEN WEEK('2020-06-15')-12 AND WEEK('2020-06-15')-1),
after_third_12weeks AS(SELECT calendar_year,SUM(sales) sales_12weeks_after
						FROM clean_weekly_sales
						WHERE week_date>='2020-06-15' AND week_number BETWEEN WEEK('2020-06-15') AND WEEK('2020-06-15')+11),
before_third_4weeks AS ( SELECT calendar_year,SUM(sales) sales_4weeks_before
				FROM clean_weekly_sales
				WHERE week_date<'2020-06-15' AND week_number BETWEEN WEEK('2020-06-15')-4 AND WEEK('2020-06-15')-1),
after_third_4weeks AS (SELECT calendar_year, SUM(sales) sales_4weeks_after
						FROM clean_weekly_sales
						WHERE week_date>='2020-06-15' AND week_number BETWEEN WEEK('2020-06-15') AND WEEK('2020-06-15')+3),
third_year AS(
SELECT b.calendar_year, (sales_12weeks_after-sales_12weeks_before) value_12weeks, 
ROUND(((sales_12weeks_after-sales_12weeks_before)/sales_12weeks_before)*100,1) percent_12weeks,
(sales_4weeks_after-sales_4weeks_before) value_4weeks, ROUND(((sales_4weeks_after-sales_4weeks_before)/sales_4weeks_before)*100,1) percent_4weeks
 FROM before_third_12weeks b 
 JOIN after_third_12weeks a ON b.calendar_year=a.calendar_year
 JOIN after_third_4weeks a2 ON b.calendar_year=a2.calendar_year
 JOIN before_third_4weeks b2 ON b.calendar_year=b2.calendar_year),
-- FOR THE YEAR 2019
before_second_12weeks AS( SELECT calendar_year,SUM(sales) sales_12weeks_before
				FROM clean_weekly_sales
				WHERE week_date<'2019-06-15' AND week_number BETWEEN WEEK('2019-06-15')-11 AND WEEK('2019-06-15')-1),
after_second_12weeks AS(SELECT calendar_year,SUM(sales) sales_12weeks_after
						FROM clean_weekly_sales
						WHERE week_date>='2019-06-15' AND week_date<'2020-01-01' AND week_number BETWEEN WEEK('2019-06-15') AND WEEK('2019-06-15')+12),
before_second_4weeks AS ( SELECT calendar_year,SUM(sales) sales_4weeks_before
				FROM clean_weekly_sales
				WHERE week_date<'2019-06-15' AND week_number BETWEEN WEEK('2019-06-15')-3 AND WEEK('2019-06-15')),
after_second_4weeks AS (SELECT calendar_year, SUM(sales) sales_4weeks_after
						FROM clean_weekly_sales
						WHERE week_date>='2019-06-15' AND week_date<'2020-01-01' AND week_number BETWEEN WEEK('2019-06-15') AND WEEK('2019-06-15')+4),
second_year AS(
SELECT b.calendar_year, (sales_12weeks_after-sales_12weeks_before) value_12weeks,
 ROUND(((sales_12weeks_after-sales_12weeks_before)/sales_12weeks_before)*100,1) percent_12weeks,
(sales_4weeks_after-sales_4weeks_before) value_4weeks, ROUND(((sales_4weeks_after-sales_4weeks_before)/sales_4weeks_before)*100,1) percent_4weeks
 FROM before_second_12weeks b 
 JOIN after_second_12weeks a ON b.calendar_year=a.calendar_year
 JOIN after_second_4weeks a2 ON b.calendar_year=a2.calendar_year
 JOIN before_second_4weeks b2 ON b.calendar_year=b2.calendar_year), 
 -- FOR THE YEAR 2018
 before_first_12weeks AS( SELECT calendar_year,SUM(sales) sales_12weeks_before
				FROM clean_weekly_sales
				WHERE week_date<'2018-06-15' AND week_number BETWEEN WEEK('2018-06-15')-11 AND WEEK('2018-06-15')-1),
after_first_12weeks AS(SELECT calendar_year,SUM(sales) sales_12weeks_after
						FROM clean_weekly_sales
						WHERE week_date>='2018-06-15' AND week_date<'2019-01-01' AND week_number BETWEEN WEEK('2018-06-15') AND WEEK('2018-06-15')+12),
before_first_4weeks AS ( SELECT calendar_year,SUM(sales) sales_4weeks_before
				FROM clean_weekly_sales
				WHERE week_date<'2018-06-15' AND week_number BETWEEN WEEK('2018-06-15')-3 AND WEEK('2018-06-15')),
after_first_4weeks AS (SELECT calendar_year, SUM(sales) sales_4weeks_after
						FROM clean_weekly_sales
						WHERE week_date>='2018-06-15' AND week_date<'2019-01-01' AND week_number BETWEEN WEEK('2018-06-15') AND WEEK('2018-06-15')+4),
first_year AS(
SELECT b.calendar_year, (sales_12weeks_after-sales_12weeks_before) value_12weeks, 
ROUND(((sales_12weeks_after-sales_12weeks_before)/sales_12weeks_before)*100,1) percent_12weeks,
(sales_4weeks_after-sales_4weeks_before) value_4weeks_value, ROUND(((sales_4weeks_after-sales_4weeks_before)/sales_4weeks_before)*100,1) percent_4weeks
 FROM before_first_12weeks b 
 JOIN after_first_12weeks a ON b.calendar_year=a.calendar_year
 JOIN after_first_4weeks a2 ON b.calendar_year=a2.calendar_year
 JOIN before_first_4weeks b2 ON b.calendar_year=b2.calendar_year)
 
 SELECT *
 FROM third_year
 UNION
 SELECT *
 FROM second_year
 UNION
 SELECT *
 FROM first_year;
/* 
After the implementation of the Data Mart sustainable packaging changes:
In 2020, the sales reduced by 65.5% after 4 weeks and 65.8% after 12 weeks.
In 2019, the sales reduced by 48.5% after 4 weeks and 43.7% after 12 weeks.
In 2018, the sales increased by 0.2% after 4 weeks and 10.9% after 12 weeks.
 */
 
-- PART D (Bonus Question)
/*Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?
- region
- platform
- age_band
- demographic
- customer_type
 */
-- BASED ON REGION
WITH after_region AS(	SELECT calendar_year,region,SUM(sales) total_after_region
						FROM clean_weekly_sales
						WHERE week_date>='2020-06-15' AND week_number BETWEEN WEEK('2020-06-15') AND WEEK('2020-06-15')+11
                        GROUP BY region),
before_region AS(		SELECT calendar_year,region,SUM(sales) total_before_region
						FROM clean_weekly_sales
						WHERE week_date<'2020-06-15' AND week_number BETWEEN WEEK('2020-06-15')-12 AND WEEK('2020-06-15')-1
                        GROUP BY region),
region_area AS(	SELECT calendar_year, ROUND(AVG(region_percent),2) region_impact
				FROM( SELECT a.calendar_year,a.region, (total_after_region-total_before_region) region_actual_value,
				 ROUND(((total_after_region-total_before_region)/total_before_region)*100,1) region_percent
				 FROM after_region a
				 JOIN before_region b ON a.region=b.region) region_avg),
 -- BASED ON PLATFORM
 after_platform AS(	SELECT calendar_year,platform,SUM(sales) total_after_platform
						FROM clean_weekly_sales
						WHERE week_date>='2020-06-15' AND week_number BETWEEN WEEK('2020-06-15') AND WEEK('2020-06-15')+11
                        GROUP BY 2),
before_platform AS(	SELECT calendar_year,platform,SUM(sales) total_before_platform
						FROM clean_weekly_sales
						WHERE week_date<'2020-06-15' AND week_number BETWEEN WEEK('2020-06-15')-12 AND WEEK('2020-06-15')-1
                        GROUP BY 2),
platform_area AS( SELECT calendar_year, ROUND(AVG(platform_percent),2) platform_impact
				FROM( SELECT a.calendar_year,a.platform, (total_after_platform-total_before_platform) platform_actual_value,
					 ROUND(((total_after_platform-total_before_platform)/total_before_platform)*100,1) platform_percent
					 FROM after_platform a
					 JOIN before_platform b ON a.platform=b.platform) platform_avg),
 -- BASED ON AGE BAND
after_age_band AS(	SELECT calendar_year,age_band,SUM(sales) total_after_age_band
						FROM clean_weekly_sales
						WHERE week_date>='2020-06-15' AND week_number BETWEEN WEEK('2020-06-15') AND WEEK('2020-06-15')+11
                        GROUP BY 2),
before_age_band AS(	SELECT calendar_year,age_band,SUM(sales) total_before_age_band
						FROM clean_weekly_sales
						WHERE week_date<'2020-06-15' AND week_number BETWEEN WEEK('2020-06-15')-12 AND WEEK('2020-06-15')-1
                        GROUP BY 2),
age_band_area AS(SELECT calendar_year, ROUND(AVG(age_band_percent),2) age_band_impact
				FROM( SELECT a.calendar_year,a.age_band, (total_after_age_band-total_before_age_band) age_band_actual_value,
				 ROUND(((total_after_age_band-total_before_age_band)/total_before_age_band)*100,1) age_band_percent
				 FROM after_age_band a
				 JOIN before_age_band b ON a.age_band=b.age_band) age_band_avg),
-- BASED ON DEMOGRAPHICS
after_demographics AS( SELECT calendar_year,demographics,SUM(sales) total_after_demographics
						FROM clean_weekly_sales
						WHERE week_date>='2020-06-15' AND week_number BETWEEN WEEK('2020-06-15') AND WEEK('2020-06-15')+11
                        GROUP BY 2),
before_demographics AS(	SELECT calendar_year,demographics,SUM(sales) total_before_demographics
						FROM clean_weekly_sales
						WHERE week_date<'2020-06-15' AND week_number BETWEEN WEEK('2020-06-15')-12 AND WEEK('2020-06-15')-1
                        GROUP BY 2),
demographics_area AS(SELECT calendar_year, ROUND(AVG(demographics_percent),2) demographics_impact
				FROM( SELECT a.calendar_year,a.demographics, (total_after_demographics-total_before_demographics) demographics_actual_value,
					 ROUND(((total_after_demographics-total_before_demographics)/total_before_demographics)*100,1) demographics_percent
					 FROM after_demographics a
					 JOIN before_demographics b ON a.demographics=b.demographics) demographics_avg),
 -- BASED ON CUSTOMER TYPE
after_customer_type AS( SELECT calendar_year,customer_type,SUM(sales) total_after_customer_type
						FROM clean_weekly_sales
						WHERE week_date>='2020-06-15' AND week_number BETWEEN WEEK('2020-06-15') AND WEEK('2020-06-15')+11
                        GROUP BY 2),
before_customer_type AS(	SELECT calendar_year,customer_type,SUM(sales) total_before_customer_type
						FROM clean_weekly_sales
						WHERE week_date<'2020-06-15' AND week_number BETWEEN WEEK('2020-06-15')-12 AND WEEK('2020-06-15')-1
                        GROUP BY 2),
customer_type_area AS(	
				SELECT calendar_year, ROUND(AVG(customer_type_percent),2) customer_type_impact
				FROM	(SELECT a.calendar_year,a.customer_type, (total_after_customer_type-total_before_customer_type) customer_type_actual_value,
					 ROUND(((total_after_customer_type-total_before_customer_type)/total_before_customer_type)*100,1) customer_type_percent
					 FROM after_customer_type a
					 JOIN before_customer_type b ON a.customer_type=b.customer_type) customer_type_avg)
                     
SELECT a.calendar_year,region_impact,platform_impact,age_band_impact,demographics_impact,customer_type_impact
FROM region_area r 
JOIN platform_area p ON r.calendar_year=p.calendar_year
JOIN age_band_area a ON r.calendar_year=a.calendar_year
JOIN demographics_area d ON r.calendar_year=d.calendar_year
JOIN customer_type_area c ON r.calendar_year=c.calendar_year;

/*The area with the highest negative impact is the CUSTOMER_TYPE with a negative impact of 66.13%
NOTE: all 'impact' results are in (%)
*/
