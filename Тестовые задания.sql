CREATE DATABASE final;

CREATE TABLE Audit (
	date DATETIME,
    user_id VARCHAR(50),
    view_adverts INT
);
SELECT * FROM Audit;

ALTER TABLE audit MODIFY date DATE;

CREATE TABLE ab (
	experiment_num INT,
    experiment_group VARCHAR(10),
    user_id INT,
    revenue INT
);
SELECT * FROM ab;

CREATE TABLE lister (
	user_id INT,
	date DATE,
    cnt_adverts INT,
    age INT,
    cnt_contacts INT,
    revenue INT
);
SELECT * FROM lister;

# 1
SELECT 
COUNT(DISTINCT user_id) AS MAU
FROM audit
WHERE date BETWEEN '2023-11-01' AND '2023-11-30';

# 2
WITH dau1 AS
	(SELECT 
	date,  
	COUNT(DISTINCT user_id) AS dau
	FROM audit
	GROUP BY date) 
SELECT AVG(dau) AS DAU
FROM dau1;

# 3
WITH first_day AS
	(SELECT DISTINCT user_id
    FROM audit
    WHERE date = '2023-11-01'),
second_day AS
	(SELECT DISTINCT user_id
    FROM audit
    WHERE date = '2023-11-02')
SELECT 
COUNT(DISTINCT s.user_id)*100/COUNT(DISTINCT f.user_id) AS ret
FROM first_day f
LEFT JOIN second_day s ON f.user_id = s.user_id;

# 5
SELECT 
COUNT(DISTINCT CASE WHEN view_adverts > 0
THEN user_id END)*100/
COUNT(DISTINCT user_id) AS conv
FROM audit
WHERE date BETWEEN '2023-11-01' AND '2023-11-30';

# 6
WITH nov AS
	(SELECT user_id, view_adverts
    FROM audit
    WHERE date BETWEEN '2023-11-01' AND '2023-11-30')
SELECT
SUM(view_adverts)/COUNT(DISTINCT user_id) AS avg_view
FROM nov;
