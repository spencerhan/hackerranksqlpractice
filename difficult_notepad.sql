-- 185. Department Top Three Salaries, https://leetcode.com/problems/department-top-three-salaries/
WITH salary_rank AS (
    SELECT d.name AS Department , e.name AS Employee, e.salary AS Salary, DENSE_RANK() OVER (PARTITION BY e.departmentId ORDER BY e.salary DESC) AS rnk
    FROM Employee e
    JOIN Department d
    ON e.departmentId = d.id
    
)
SELECT Department, Employee, Salary 
FROM salary_rank
WHERE rnk <= 3

-- 262. Trips and Users,  https://leetcode.com/problems/trips-and-users/

WITH t1 AS (
            SELECT *
            FROM Users u 
            WHERE banned = 'No' AND role = 'driver'
), t2 AS ( 
         SELECT *
         FROM Users u 
         WHERE banned = 'No' AND role = 'client'
), t3 AS (
    SELECT COUNT(id) AS total_cancelled, request_at  
    FROM Trips 
    WHERE client_id IN (SELECT users_id FROM t2) AND driver_id IN (SELECT users_id FROM t1) AND status LIKE '%cancelled%' AND request_at between '2013-10-01' and '2013-10-03'
    GROUP BY request_at
), t4 AS (
    SELECT COUNT(id) AS total_count, request_at  
    FROM Trips 
    WHERE client_id IN (SELECT users_id FROM t2) AND driver_id IN (SELECT users_id FROM t1) AND request_at between '2013-10-01' and '2013-10-03'
    GROUP BY request_at
)

SELECT t4.request_at as Day, ROUND(ISNULL(t3.total_cancelled,0) * 1.0 / t4.total_count, 2) as 'Cancellation Rate'
FROM t3 
RIGHT JOIN t4
ON t3.request_at = t4.request_at

/* simpler */

SELECT
    request_at AS DAY,
        Round(SUM(
            CASE
                WHEN STATUS <> 'completed' THEN 1.0
                ELSE 0.0
            END
        ) * 1.0 / COUNT(*), 2)
    AS 'cancellation rate'
FROM
    trips t
    JOIN users rider ON t.client_id = rider.users_id
    JOIN users driver ON t.driver_id = driver.users_id
WHERE
    t.request_at BETWEEN '2013-10-01' AND '2013-10-03'
    AND rider.banned = 'No'
    AND driver.banned = 'No'
GROUP BY
    request_at


-- 1384. Total Sales Amount by Year, https://leetcode.com/problems/total-sales-amount-by-year/

/*  t1 - t3 is using recursive query to create a date table 
    SQL server recursion default has a limit of 100, need to set OPTION (maxrecursion 0)

*/
WITH t1 AS (
     SELECT MIN(period_start) AS min_date
     FROM Sales 
     
), t2 AS (
    SELECT MAX(period_end) AS max_date 
    FROM Sales 
), t3 AS (
    SELECT min_date AS date
    FROM t1
    UNION ALL
    SELECT DATEADD(day, 1, date)
    FROM t3
    WHERE date <= ALL (SELECT max_date FROM t2)
)


SELECT CAST(p.product_id AS VARCHAR(4)) AS product_id, p.product_name, CAST(year(t3.date) AS VARCHAR(4)) AS report_year, SUM(s.average_daily_sales) AS total_amount
FROM Product p
JOIN Sales s
ON p.product_id = s.product_id
JOIN t3
ON s.period_start <= t3.date AND s.period_end >= t3.date
GROUP BY p.product_id, p.product_name, year(t3.date)
ORDER BY 1, year(t3.date)
OPTION (maxrecursion 0)

--2153. The Number of Passengers in Each Bus II, https://leetcode.com/problems/the-number-of-passengers-in-each-bus-ii/
/* ORDER BY used for running total */
WITH t1 AS ( -- bus arriving window and arriving order
    SELECT bus_id, arrival_time, capacity, ROW_NUMBER() OVER (ORDER BY arrival_time) AS rn, LAG(arrival_time, 1, -1) OVER (ORDER BY arrival_time) AS prev_arrival_time
    FROM Buses 
    
), t2 AS ( -- attaching arriving window to passengers, counting passengers count
    SELECT t1.bus_id, t1.rn, t1.capacity, COUNT(p.passenger_id) AS passenger_cnt
        FROM t1
        LEFT JOIN Passengers p -- using left join as we have to multiple passengers arrival at the same arrival window.
        ON p.arrival_time > t1.prev_arrival_time AND p.arrival_time <= t1.arrival_time
        GROUP BY t1.bus_id, t1.rn, t1.capacity
)


-- 15 days of sql, https://www.hackerrank.com/challenges/15-days-of-learning-sql/problem?isFullScreen=false
/* https://medium.com/geekculture/15-days-of-learning-sql-hackerrank-a40ab17ae462 */

WITH t1 AS ( -- count of submission per day per hacker
    SELECT submission_date, hacker_id, COUNT(1) AS cnt
    FROM Submissions
    GROUP BY submission_date, hacker_id
), t2 AS ( -- getting the rank of submission for each hacker per day
    SELECT submission_date, hacker_id, RANK() OVER (PARTITION BY submission_date ORDER BY cnt DESC, hacker_id) AS rnk
    FROM t1
), t3 AS ( -- keeps tracking the submission day counts in sequences
    SELECT submission_date, hacker_id, DENSE_RANK() OVER (ORDER BY submission_date) AS dayrnk
    FROM Submissions
), t4 AS ( -- check for each hacker, whether they have made submission prior to the days earlier than each submission day
           -- the first day, 2016-03-01, hackers who made the submission should be counted.
    SELECT t3.submission_date, t3.hacker_id, 
        CASE
            WHEN t3.submission_date = '2016-03-01' THEN 1
            ELSE 1 + (
                        SELECT COUNT(DISTINCT s.submission_date) 
                        FROM Submissions s 
                        WHERE s.hacker_id = t3.hacker_id AND s.submission_date < t3.submission_date
                    )
            END AS prevsub_cnt, 
        t3.dayrnk
    FROM t3
), t5 AS ( -- if a hacker is continuously making submissions each day, 
            -- then his total submissions should match the day counts

    SELECT submission_date, COUNT(DISTINCT hacker_id) AS hacker_cnt
    FROM t4 
    WHERE prevsub_cnt = dayrnk
    GROUP BY submission_date
)
-- combine everything together.
SELECT t5.submission_date, t5.hacker_cnt, t2.hacker_id, h.name
FROM t5
JOIN t2
ON t5.submission_date = t2.submission_date
JOIN Hackers h
ON h.hacker_id = t2.hacker_id
WHERE t2.rnk = 1


-- Print Prime Number, https://www.hackerrank.com/challenges/print-prime-numbers/problem?isFullScreen=true

DECLARE @i AS INT = 2;
DECLARE @prime INT = 0;
DECLARE @t AS TABLE (result INT)
WHILE @i <= 1000
BEGIN 
    DECLARE @j INT = @i - 1;
    SET @prime = 1
    WHILE @j > 1
    BEGIN
        IF @i % @j = 0
        BEGIN
            SET @prime = 0;
        END
        SET @j = @j - 1;
    END
    IF @prime = 1
    BEGIN 
        INSERT INTO @t (result) VALUES (@i)
    END 
SET @i = @i + 1
END
DECLARE @result VARCHAR(MAX);
SELECT @RESULT = STRING_AGG(result, '&') FROM @t;
PRINT @result;