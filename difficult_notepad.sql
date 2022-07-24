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
        ROUND(SUM(
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
=======
-- 2153. The Number of Passengers in Each Bus II, https://leetcode.com/problems/the-number-of-passengers-in-each-bus-ii/
WITH t1 AS (
    -- bus arriving window and arriving order
    SELECT
        bus_id,
        arrival_time,
        capacity,
        ROW_NUMBER() OVER (ORDER BY arrival_time ) AS rn,
        LAG(arrival_time, 1, -1) OVER (ORDER BY arrival_time) AS prev_arrival_time
    FROM
        Buses
),
t2 AS (
    -- attaching arriving window to passengers, counting passengers count.
    -- this gives the passenger per bus if we are not considering capacity.
    -- the first bus will take all first two passengers, the second bus takes none, and the last bus takes the remaining 3. obvisiously this is not correct.
    SELECT
        t1.bus_id,
        t1.rn,
        t1.capacity,
        COUNT(p.passenger_id) AS passenger_cnt
    FROM
        t1
        LEFT JOIN Passengers p -- using left join as we have to multiple passengers arrival at the same arrival window.
        ON p.arrival_time > t1.prev_arrival_time
        AND p.arrival_time <= t1.arrival_time
    GROUP BY
        t1.bus_id,
        t1.rn,
        t1.capacity
), recursive_cte AS ( -- now we need a reiteration to update remaining passengers, to see if they fit into next buses capacity
    SELECT bus_id, rn, capacity, passenger_cnt, IIF(passenger_cnt - capacity <= 0, 0, passenger_cnt - capacity) AS remaining_p
    FROM t2
    WHERE rn = 1
    UNION ALL
    -- the next bus from t2 table
    SELECT t2.bus_id,t2.rn, t2.capacity, cte.remaining_p + t2.passenger_cnt AS passenger_cnt, IIF(cte.remaining_p + t2.passenger_cnt - t2.capacity <= 0, 0, cte.remaining_p + t2.passenger_cnt - t2.capacity) AS remaining_p
    FROM recursive_cte cte
    JOIN t2 ON t2.rn = cte.rn + 1 -- getting updated count of remaining passenger from previous bus and capacity of the next ariving bus
)

SELECT bus_id, IIF(remaining_p <= 0, passenger_cnt, capacity) AS passengers_cnt -- if no remaining passenger, then all passengers are taken, if there are remaining passenger, then bus capacity is full
FROM 
recursive_cte
ORDER BY bus_id


-- 569. Median Employee Salary, https://leetcode.com/problems/median-employee-salary/


SELECT id, company, salary
FROM 
    (SELECT id, company, salary, ROW_NUMBER() OVER (PARTITION BY company ORDER BY salary) AS rn, COUNT(1) OVER (PARTITION BY company) employee_cnt
    FROM Employee) t
WHERE (employee_cnt % 2 = 0 AND rn IN (employee_cnt/2, employee_cnt/2 + 1)) OR (employee_cnt % 2 = 1 AND rn = ceiling(employee_cnt/2.0))


-- 1767. Find the Subtasks That Did Not Execute, https://leetcode.com/problems/find-the-subtasks-that-did-not-execute/

WITH recursive_cte AS ( -- this give a table of all tasks and their matching subtasks
    SELECT
        task_id,
        subtasks_count,
        1 AS subtasks
    FROM
        Tasks
    UNION ALL
    SELECT
        task_id,
        subtasks_count,
        subtasks + 1
    FROM
        recursive_cte
    WHERE
        subtasks < subtasks_count
)

SELECT c.task_id, c.subtasks AS subtask_id
FROM recursive_cte c
LEFT JOIN Executed e
ON c.task_id = e.task_id AND c.subtasks = e.subtask_id 
WHERE e.task_id IS NULL  -- anything does not match is our missing subtasks that was not executed.
ORDER BY 1, 2


/* this recursive does the same, I just realise I could do the count reversely */


WITH recursive_cte AS (
    SELECT
        task_id,
        subtasks_count
    FROM
        Tasks
    UNION
    ALL
    SELECT
        task_id,
        subtasks_count - 1
    FROM   recursive_cte
    WHERE
        subtasks_count > 1
)
SELECT
    c.task_id,
    c.subtasks_count AS subtask_id
FROM
    recursive_cte c
    LEFT JOIN executed e ON c.task_id = e.task_id
    AND c.subtasks_count = e.subtask_id
WHERE
    e.task_id IS NULL
ORDER BY c.task_id, c.subtasks_count


-- 1479. Sales by Day of the Week, https://leetcode.com/problems/sales-by-day-of-the-week/

SET DATEFIRST 1;
WITH pvt AS (
    SELECT item_id, SUM(IIF(DATEPART(WEEKDAY, order_date) = 1, quantity, 0)) AS 'MONDAY',
                                           SUM(IIF(DATEPART(WEEKDAY, order_date) = 2, quantity, 0)) AS 'TUESDAY',
                                           SUM(IIF(DATEPART(WEEKDAY, order_date) = 3, quantity, 0)) AS 'WEDNESDAY',
                                           SUM(IIF(DATEPART(WEEKDAY, order_date) = 4, quantity, 0)) AS 'THURSDAY',
                                           SUM(IIF(DATEPART(WEEKDAY, order_date) = 5, quantity, 0)) AS 'FRIDAY',
                                           SUM(IIF(DATEPART(WEEKDAY, order_date) = 6, quantity, 0)) AS 'SATURDAY',
                                           SUM(IIF(DATEPART(WEEKDAY, order_date) = 7, quantity, 0)) AS 'SUNDAY'
                                           
    FROM Orders 
    GROUP BY item_id
)

SELECT i.item_category AS CATEGORY, SUM(IIF(p.item_id IS NOT NULL, p.MONDAY, 0)) AS MONDAY,
                                    SUM(IIF(p.item_id IS NOT NULL, p.TUESDAY, 0)) AS TUESDAY,
                                    SUM(IIF(p.item_id IS NOT NULL, p.WEDNESDAY, 0)) AS WEDNESDAY,
                                    SUM(IIF(p.item_id IS NOT NULL, p.THURSDAY, 0)) AS THURSDAY,
                                    SUM(IIF(p.item_id IS NOT NULL, p.FRIDAY, 0)) AS FRIDAY,
                                    SUM(IIF(p.item_id IS NOT NULL, p.SATURDAY, 0)) AS SATURDAY,
                                    SUM(IIF(p.item_id IS NOT NULL, p.SUNDAY, 0)) AS SUNDAY
FROM pvt p
RIGHT JOIN Items i 
ON p.item_id = i.item_id
GROUP BY i.item_category
ORDER BY i.item_category


-- 1369. Get the Second Most Recent Activity, https://leetcode.com/problems/get-the-second-most-recent-activity/
WITH t AS (
SELECT username, activity, ROW_NUMBER() OVER (PARTITION BY username ORDER BY startDate DESC) AS rn, COUNT(startDate) OVER (PARTITION BY username) AS cnt, startDate, endDate
FROM UserActivity
)

SELECT username, activity, startDate, endDate
FROM t
WHERE cnt = 1
UNION ALL
SELECT  username, activity, startDate, endDate
FROM t
WHERE rn = 2


-- 1651. Hopper Company Queries III, https://leetcode.com/problems/hopper-company-queries-iii/

/* three month running average without window function 
    can substitute with AVG() OVER (ORDER BY 'date' ROWS BETWEEN 2 PRECEEDING AND CURRENT ROW)

    filter(where) on join clause, not after
*/

WITH t1 AS (
    SELECT
        1 AS month
    UNION
    ALL
    SELECT
        1 + month
    FROM
        t1
    WHERE
        month < 12
)
SELECT 
  t1.month,
  ROUND(ISNULL((SUM(ride_distance) * 1.0) / 3, 0.00),2) AS average_ride_distance,
  ROUND(ISNULL((SUM(ride_duration) * 1.0) / 3, 0.00),2) AS average_ride_duration
FROM t1 
LEFT JOIN Rides r 
ON (MONTH(r.requested_at) BETWEEN t1.month AND t1.month + 2) AND YEAR(r.requested_at) = 2020
LEFT JOIN AcceptedRides a ON a.ride_id = r.ride_id
GROUP BY t1.month
HAVING t1.month <= 10
ORDER BY t1.month



-- 2253. Dynamic Unpivoting of a Table, https://leetcode.com/problems/dynamic-unpivoting-of-a-table/


CREATE PROCEDURE UnpivotProducts AS
BEGIN
    /* Write your T-SQL query statement below. */
 

    DECLARE @output TABLE (product_id int, store varchar(100), price int)
    DECLARE @query NVARCHAR(MAX)
    
    SELECT @column_list = COALESCE(@column_list + ',', '') + QUOTENAME(COLUMN_NAME)
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = N'Products' AND COLUMN_NAME <> 'product_id'

    -- INSERT INTO @output (product_id, store, price)
    SET @query = N'
    SELECT product_id, store, price
    FROM Products
    UNPIVOT ( 
            price FOR store IN ('+@column_list+')
    ) AS unpvt
    ';
    EXEC sp_executesql @query;
END;


-- 618. Students Report By Geography https://leetcode.com/problems/students-report-by-geography/

/* standard */
SELECT MAX(America) AS America, MAX(Asia) AS Asia, MAX(Europe) AS Europe
FROM 
    (SELECT ROW_NUMBER() OVER (PARTITION BY continent ORDER BY name) AS row_id,
            IIF(continent = 'America', name, null) AS America,
            IIF(continent = 'Asia', name, null) AS Asia,
            IIF(continent = 'Europe', name, null) AS Europe
    FROM Student
    ) t
GROUP BY row_id;


/* pivot function */

SELECT America, Asia, Europe
FROM 
(SELECT ROW_NUMBER() OVER (PARTITION BY continent ORDER BY name) AS row_id, name, continent
FROM
 Student
) AS t
PIVOT
(MAX(name) FOR continent in (America, Asia, Europe)) AS pvt; 

 -- 1225. Report Contiguous Dates, https://leetcode.com/problems/report-contiguous-dates/

WITH failed_and_successed AS (
    SELECT 'failed' AS period_state,
            f.fail_date AS date,
            ROW_NUMBER() OVER (ORDER BY f.fail_date) AS date_order
    FROM Failed f
    WHERE f.fail_date BETWEEN '2019-01-01' AND '2019-12-31'
    UNION ALL
    SELECT 'succeeded' AS period_state,
            s.success_date AS date,            ROW_NUMBER() OVER (ORDER BY s.success_date) AS date_order
    FROM Succeeded s
    WHERE s.success_date BETWEEN '2019-01-01' AND '2019-12-31'
), group_interval AS (
    SELECT period_state, date, ROW_NUMBER() OVER (ORDER BY date) - date_order AS interval
    FROM failed_and_successed
) 
SELECT period_state, MIN(date) AS start_date, MAX(date) AS end_date
FROM group_interval
GROUP BY interval, period_state
ORDER BY start_date;


-- 1412. Find the Quiet Students in All Exams, https://leetcode.com/problems/find-the-quiet-students-in-all-exams/
/* simple window function, but I didn't resolve it somehow, not sure why. */

WITH ranking AS (
    SELECT s.student_id, s.student_name,
    DENSE_RANK() OVER (PARTITION BY e.exam_id ORDER BY e.score DESC) AS high_rank, 
    DENSE_RANK() OVER (PARTITION BY e.exam_id ORDER BY e.score ASC) AS low_rank
    FROM Student s
    JOIN Exam e
    ON s.Student_id = e.Student_id
)
SELECT student_id, student_name
FROM ranking 
WHERE student_id NOT IN (SELECT student_id FROM ranking WHERE high_rank = 1 OR low_rank = 1)
GROUP BY student_id, student_name
ORDER BY 1;


-- 1159. Market Analysis II ,https://leetcode.com/problems/market-analysis-ii/
SELECT u.user_id AS seller_id, IIF(t1.seller_id IS NULL OR u.favorite_brand <> t1.item_brand, 'no', 'yes') AS '2nd_item_fav_brand'
FROM Users u 
LEFT JOIN
    (SELECT i.item_brand, t.seller_id 
    FROM 
        (SELECT ROW_NUMBER() OVER (PARTITION BY seller_id ORDER BY order_date) AS rn, item_id, seller_id 
        FROM Orders) t
    JOIN Items i
    ON t.item_id = i.item_id AND t.rn = 2
    ) t1
ON u.user_id = t1.seller_id;

--2118. Build the Equation, https://leetcode.com/problems/build-the-equation/

WITH t1 AS (
    SELECT CASE 
                WHEN factor = 0 THEN ''
                WHEN (power = 0) AND (factor > 0) THEN CONCAT('+', factor)
                WHEN (power = 0) AND (factor < 0) THEN CONCAT('-', ABS(factor))
                WHEN (power = 1) AND (factor > 0) THEN CONCAT('+', factor, 'X')
                WHEN (power = 1) AND (factor < 0) THEN CONCAT('-', ABS(factor), 'X')
                WHEN (power > 1) AND (factor > 0) THEN CONCAT('+', factor, 'X^', power)
                WHEN (power > 1) AND (factor < 0) THEN CONCAT('-', ABS(factor), 'X^', power)
            END AS term, power
    FROM Terms 
) 

SELECT CONCAT(STRING_AGG(term,'') WITHIN GROUP (ORDER BY power desc), '=0') AS equation
FROM t1

-- 2010. The Number of Seniors and Juniors to Join the Company II, https://leetcode.com/problems/the-number-of-seniors-and-juniors-to-join-the-company-ii/


WITH all_running_total AS (
    SELECT employee_id, experience, salary, SUM(salary) OVER (PARTITION BY experience ORDER BY salary ASC) AS running_total
    FROM Candidates
), senior_candidates AS (
    SELECT employee_id, experience, running_total
    FROM all_running_total
    WHERE experience = 'Senior' AND running_total < 70000
), junior_candidates AS (
    SELECT employee_id, experience, running_total
    FROM all_running_total 
                                                     -- maybe can't hire any Senior. and 70000 - SELECT is slower than SELECT 70000 - 
    WHERE experience = 'Junior' AND running_total <  (SELECT 70000 - ISNULL(MAX(running_total),0) FROM senior_candidates) 
)

SELECT employee_id 
FROM junior_candidates
UNION 
SELECT employee_id 
FROM senior_candidates



-- 615. Average Salary: Departments VS Company, https://leetcode.com/problems/average-salary-departments-vs-company/

WITH company_avg AS (
    SELECT FORMAT(s.pay_date,'yyyy-MM') AS pay_month, AVG(s.amount * 1.00) AS average
    FROM Salary s
    JOIN Employee e
    ON s.employee_id = e.employee_id 
    GROUP BY FORMAT(s.pay_date,'yyyy-MM')
), department_avg AS (

    SELECT FORMAT(s.pay_date,'yyyy-MM') AS pay_month, AVG(s.amount * 1.00) AS average, e.department_id
    FROM Salary s
    JOIN Employee e
    ON s.employee_id = e.employee_id 
    GROUP BY FORMAT(s.pay_date,'yyyy-MM'), e.department_id
)
SELECT d.pay_month, d.department_id, CASE 
                                        WHEN d.average > c.average THEN 'higher'
                                        WHEN d.average < c.average THEN 'lower'
                                        ELSE 'same' 
                                     END AS comparison 
FROM company_avg c  
JOIN department_avg d
ON c.pay_month  = d.pay_month;

-- 2173. Longest Winning Streak, https://leetcode.com/problems/longest-winning-streak/

WITH all_match AS (
    SELECT player_id, match_day, ROW_NUMBER() OVER (PARTITION BY player_id ORDER BY match_day) AS rn
    FROM Matches
 
), win_match AS (
    SELECT player_id, match_day, ROW_NUMBER() OVER (PARTITION BY player_id ORDER BY match_day) AS rn
    FROM  Matches
    WHERE result = 'Win'
), t AS (

    SELECT  all_match.player_id, 
            all_match.rn - win_match.rn AS DIFF, 
            COUNT(DISTINCT all_match.match_day) AS cnt, -- consective days
            RANK() OVER (PARTITION BY all_match.player_id ORDER BY COUNT(DISTINCT all_match.match_day) DESC) AS rnk -- rank by consective days
    FROM all_match
    JOIN win_match 
    ON all_match.player_id = win_match.player_id AND all_match.match_day = win_match.match_day
    GROUP BY all_match.player_id, all_match.rn - win_match.rn
)

SELECT DISTINCT m.player_id, IIF(t.player_id IS NULL, 0, cnt) AS longest_streak -- missing players are not winning players
FROM Matches m
LEFT JOIN t
ON m.player_id = t.player_id
AND t.rnk = 1

-- 2252. Dynamic Pivoting of a Table, https://leetcode.com/problems/dynamic-pivoting-of-a-table/

