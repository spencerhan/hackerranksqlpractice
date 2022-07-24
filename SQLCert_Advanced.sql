-- q1

WITH t1 AS (
    SELECT MAX(data_value) AS 'max', MONTH(CAST(record_date AS DATE)) AS 'month'
    FROM temperature_records
    WHERE data_type = 'max'
    GROUP BY MONTH(CAST(record_date AS DATE))
), t2 AS (
    SELECT MIN(data_value) AS 'min', MONTH(CAST(record_date AS DATE)) AS 'month'
    FROM temperature_records
    WHERE data_type = 'min'
    GROUP BY MONTH(CAST(record_date AS DATE))

), t3 AS (
    SELECT CAST(ROUND(avg(data_value *1.0), 0) AS int) AS 'avg', MONTH(CAST(record_date AS DATE)) AS 'month'
    FROM temperature_records
    WHERE data_type = 'avg'
    GROUP BY MONTH(CAST(record_date AS DATE))

),t4 AS (
    SELECT MONTH(CAST(record_date AS DATE)) AS month FROM temperature_records GROUP BY MONTH(CAST(record_date AS DATE))
)


SELECT t4.month, t1.max, t2.min, t3.avg
FROM t4
JOIN t1 ON t4.month = t1.month
JOIN t2 ON t1.month = t2.month
JOIN t3 ON t2.month = t3.month


-- q2

SELECT c.algorithm, SUM(t.transactions_Q1), SUM(t.transactions_Q2 ), SUM(t.transactions_Q3), SUM(t.transactions_Q4)
FROM coins c
JOIN
(SELECT coin_code, 'transactions_Q1' = [1] , 'transactions_Q2' = [2], 'transactions_Q3' = [3], 'transactions_Q4' = [4]
FROM 
(SELECT volume, DATEPART(QUARTER, CAST(dt AS date)) AS quarters, coin_code
FROM transactions 
WHERE YEAR(CAST(dt AS date)) = 2020) AS p
PIVOT
(
    
    SUM(volume)
    FOR quarters IN ([1], [2], [3], [4]) 
) AS pvt) t
ON c.code = t.coin_code
GROUP BY c.algorithm
ORDER BY c.algorithm