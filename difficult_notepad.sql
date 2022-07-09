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

--2153. The Number of Passengers in Each Bus II, https://leetcode.com/problems/the-number-of-passengers-in-each-bus-ii/

WITH t1 AS (
    -- bus arriving window and arriving order
    SELECT
        bus_id,
        arrival_time,
        capacity,
        ROW_NUMBER() OVER (
            ORDER BY
                arrival_time
        ) AS rn,
        LAG(arrival_time, 1, -1) OVER (
            ORDER BY
                arrival_time
        ) AS prev_arrival_time
    FROM
        Buses
),
t2 AS (
    -- attaching arriving window to passengers, counting passengers count.
    -- this gives the passenger per bus if we are not considering the capacity constrain.
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
END


-- 618. Students Report By Geography https://leetcode.com/problems/students-report-by-geography/

