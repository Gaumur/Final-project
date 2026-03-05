CREATE DATABASE customers_transactions;

UPDATE customers SET Gender = NULL WHERE Gender = '';
UPDATE customers SET Age = NULL WHERE Age = '';
ALTER TABLE customers MODIFY AGE INT NULL;

SELECT * FROM customers;

CREATE TABLE transactions
(date_new DATE,
Id_check INT,
ID_client INT,
Count_products DECIMAL (10,3),
Sum_payment DECIMAL (10,2));

SELECT * FROM transactions;

LOAD DATA INFILE "C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\transactions_final.csv"
INTO TABLE transactions
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SHOW VARIABLES LIKE 'secure_file_priv';

# 1
WITH active_client AS 
	(SELECT 
    ID_client,
    COUNT(DISTINCT YEAR(date_new), MONTH(date_new)) AS active_month,
    ROUND(AVG(Sum_payment),2) AS avg_check,
    ROUND(SUM(Sum_payment)/12,2) AS avg_sum_month,
    COUNT(DISTINCT Id_check) AS total_count
	FROM transactions
	WHERE date_new >= '2015-06-01' AND date_new < '2016-06-01'
	GROUP BY ID_client)
SELECT * FROM active_client
WHERE active_month = 12;

# 2
WITH m AS
	(SELECT 
    YEAR(date_new) AS yr, 
    MONTH(date_new) AS mn,
    SUM(Sum_payment) AS total_sum_month,
    COUNT(DISTINCT Id_check) AS total_count_month_check,
    COUNT(DISTINCT ID_client) AS total_count_month_client
    FROM transactions
    WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY YEAR(date_new), MONTH(date_new)),
 y AS
	(SELECT 
    SUM(total_sum_month) AS total_sum_year,
    SUM(total_count_month_check) AS total_sum_check_year
    FROM m)
SELECT
m.yr,
m.mn,
ROUND(m.total_sum_month/m.total_count_month_check,2) AS avg_check_month,
ROUND(m.total_count_month_check/m.total_count_month_client,2) AS avg_op_month,
m.total_count_month_client,
ROUND((m.total_count_month_check/y.total_sum_check_year)*100,2) AS op_share_year,
ROUND((m.total_sum_month/y.total_sum_year)*100,2) AS sum_share_year
FROM m, y
ORDER BY m.yr, m.mn;
    
# 2e    
WITH data AS
	(SELECT 
    YEAR(t.date_new) AS yr, 
    MONTH(t.date_new) AS mn,
    CASE WHEN c.Gender IS NULL OR TRIM(c.Gender) = '' THEN 'NA'
    ELSE c.Gender
    END AS gender,
    COUNT(DISTINCT t.ID_client) AS client_count,
    SUM(t.Sum_payment) AS sum
    FROM transactions t
    LEFT JOIN customers c ON c.Id_client = t.ID_client
    WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY YEAR(t.date_new), MONTH(t.date_new), gender),
    
month_total AS
    (SELECT 
    yr, mn,
    SUM(client_count) AS total_client,
    SUM(sum) AS total_sum
    FROM data
    GROUP BY yr,mn)
SELECT
d.yr,
d.mn,
d.gender,
ROUND(d.client_count/mt.total_client*100,2) AS count_share,
ROUND(d.sum/mt.total_sum*100,2) AS sum_share
FROM data d
JOIN month_total mt ON mt.yr = d.yr AND mt.mn = d.mn
ORDER BY d.yr, d.mn, d.gender;

# 3
WITH warp AS
	(SELECT
    t.Id_check,
	t.Sum_payment,
    YEAR(t.date_new) AS yr,
    QUARTER(t.date_new) AS qtr,
	CASE
	WHEN c.Age IS NULL THEN 'Unknown'
	WHEN c.Age BETWEEN 1 AND 9 THEN '1-9'
	WHEN c.Age BETWEEN 10 AND 19 THEN '10-19'
	WHEN c.Age BETWEEN 20 AND 29 THEN '20-29'
	WHEN c.Age BETWEEN 30 AND 39 THEN '30-39'
	WHEN c.Age BETWEEN 40 AND 49 THEN '40-49'
	WHEN c.Age BETWEEN 50 AND 59 THEN '50-59'
	WHEN c.Age BETWEEN 60 AND 69 THEN '60-69'
	WHEN c.Age >=70 THEN '70+'
	END AS age_group
	FROM transactions t
	LEFT JOIN customers c ON t.ID_client = c.Id_client
	WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'),
q_total AS
	(SELECT 
    yr, qtr,
	COUNT(DISTINCT Id_check) AS op_total_qtr,
	SUM(Sum_payment) AS sum_total_qtr
	FROM warp
    GROUP BY yr,qtr)
SELECT
w.age_group,
w.yr,
w.qtr,
SUM(w.Sum_payment) AS group_sum,
COUNT(DISTINCT w.Id_check) AS group_op,
ROUND(AVG(w.Sum_payment),2) AS avg_check,
ROUND((SUM(w.Sum_payment)/ qt.sum_total_qtr) * 100,2) AS share_sum_qtr,
ROUND((COUNT(w.Id_check)/ qt.op_total_qtr) * 100,2) AS share_op_share
FROM warp w
JOIN q_total qt ON qt.yr = w.yr AND qt.qtr = w.qtr
GROUP BY w.age_group, w.yr, w.qtr
ORDER BY w.age_group, w.yr, w.qtr;
    
