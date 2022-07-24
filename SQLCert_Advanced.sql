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


-- q3

CREATE TABLE TIMESHEETS
(
     EMP_ID INTEGER,
     TIMESHEET_START_DATE DATE,
     TIMESHEET_END_DATE DATE
);

EMP_ID      |  TIMESHEET_START_DATE |  TIMESHEET_END_DATE
------------+-----------------+---------------
   xyz      |        2018-01-01     |  2018-02-01
   xyz      |        2018-02-15     |  2018-03-19
   abc      |        2018-01-16     |  2018-03-01
   abc      |        2018-03-08     |  2018-03-19

WITH recursive_cte AS (
    SELECT emp_id, timesheet_start_date, timesheet_end_date
    FROM TIMESHEETS
    UNION ALL 
    SELECT cte.emp_id, cte.timesheet_start_date, t.timesheet_end_date
    FROM TIMESHEETS t
    JOIN recursive_cte cte
    ON t.emp_id = cte.emp_id AND t.timesheet_start_date = cte.timesheet_end_date
), t2 AS (
    SELECT emp_id, timesheet_start_date, MAX(timesheet_end_date) AS timesheet_end_date
    FROM recursive_cte
    GROUP BY emp_id, timesheet_start_date
), t3 AS (
    SELECT emp_id, MIN(timesheet_start_date) AS timesheet_start_date, timesheet_end_date
    FROM t2
    GROUP BY emp_id, timesheet_end_date
)

SELECT *, ROW_NUMBER() OVER (PARTITION BY emp_id ORDER BY timesheet_end_date) AS nth_chain
FROM t3
OPTION (maxrecursion 0)
