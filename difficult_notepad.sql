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

WITH t1 AS (
    SELECT
        bus_id,
        arrival_time,
        LAG(arrival_time, 1, -1) OVER (
            ORDER BY
                arrival_time
        ) AS pre_bus_time,
        ROW_NUMBER() OVER (
            ORDER BY
                arrival_time
        ) AS rn,
        capacity
    FROM
        Buses
),
t2 AS (
    SELECT
        t1.rn,
        t1.bus_id,
        t1.capacity,
        COUNT(p.passenger_id) AS current_passenger_cnt
    FROM
        t1
        LEFT JOIN Passengers p ON p.arrival_time <= t1.arrival_time
        AND p.arrival_time > t1.pre_bus_time
    GROUP BY
        t1.rn,
        t1.bus_id,
        t1.capacity
),
recursive_cte AS (
    SELECT
        rn,
        bus_id,
        capacity,
        current_passenger_cnt,
        IIF(
            current_passenger_cnt - capacity <= 0,
            0,
            current_passenger_cnt - capacity
        ) AS remaining_passenger_cnt
    FROM
        t2
    WHERE
        rn = 1
    UNION
    ALL
    SELECT
        t2.rn,
        t2.bus_id,
        t2.capacity,
        t2.current_passenger_cnt + rc.remaining_passenger_cnt AS current_passenger_cnt,
        IIF(
            t2.current_passenger_cnt + rc.remaining_passenger_cnt - t2.capacity <= 0,
            0,
            t2.current_passenger_cnt + rc.remaining_passenger_cnt - t2.capacity
        ) AS remaining_passenger_cnt
    FROM
        recursive_cte rc
        JOIN t2 ON t2.rn = rc.rn + 1
)
SELECT
    bus_id,
    IIF(
        remaining_passenger_cnt > 0,
        capacity,
        current_passenger_cnt
    ) AS passengers_cnt
FROM
    recursive_cte
ORDER BY
    bus_id