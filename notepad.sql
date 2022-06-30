/* 
 
 MSSQL pivot syntax https://www.c-sharpcorner.com/UploadFile/f0b2ed/pivot-and-unpovit-in-sql-server/
 
 SELECT <non-pivoted column>,  
 <list of pivoted column>  
 FROM  
 (<SELECT query  to produces the data>)  
 AS <alias name>  
 PIVOT  
 (  
 <aggregation function>(<column name>)  
 FOR  
 [<column name that  become column headers>]  
 IN ( [list of  pivoted columns])  
 
 ) AS <alias name  for  pivot table>  
 
 
 */
-- New Companies solution, https://www.hackerrank.com/challenges/the-company/problem?isFullScreen=true, Advanced Select
-- main logic: join
SELECT
    c.company_code,
    c.founder,
    count(DISTINCT l.lead_manager_code),
    count(DISTINCT s.senior_manager_code),
    count(DISTINCT m.manager_code),
    count(DISTINCT e.employee_code)
FROM
    Company AS c
    LEFT JOIN Lead_Manager AS l ON c.company_code = l.company_code
    LEFT JOIN Senior_Manager AS s ON l.lead_manager_code = s.lead_manager_code
    LEFT JOIN Manager AS m ON s.senior_manager_code = m.senior_manager_code
    LEFT JOIN Employee AS e ON m.manager_code = e.manager_code
GROUP BY
    c.founder,
    c.company_code
ORDER BY
    c.company_code ASC;

-- SQL Project Planning, https://www.hackerrank.com/challenges/sql-projects/problem?isFullScreen=true&h_r=next-challenge&h_v=zen, Advanced Join
-- main logic: window function
DECLARE @table_a TABLE (s_d Date, rn int);

-- two placeholder temp table to make code more readable
DECLARE @table_b TABLE (e_d Date, rn int);

-- Start Date that are not in the End Date list should define a range of 'true' Start Date (otherwise they will fall in the middle of project)
-- the window function is used to keep a track of row numbers.
-- then we can use it to pair matching corresponding End Date
INSERT INTO
    @table_a
SELECT
    Start_Date,
    ROW_NUMBER() OVER (
        ORDER BY
            Start_Date
    ) AS RN
FROM
    Projects
WHERE
    Start_Date NOT IN (
        SELECT
            End_Date
        FROM
            Projects
    );

-- testing: SELECT * FROM @table_a;
-- Same idea here, End Date that are not in the Start Date list should define a range of 'true' End Date (otherwise they will fall in the middle of project)
SELECT
    End_Date,
    ROW_NUMBER() OVER (
        ORDER BY
            End_Date
    ) AS RN
FROM
    Projects
WHERE
    End_Date NOT IN (
        SELECT
            Start_Date
        FROM
            Projects
    );

-- debug SELECT * FROM @table_b;
-- join Start Date and End Date pair together use their corresponding row number.
-- key take on, NOT IN can be used to find whether a date falls into a period and ROW_NUMBER can be used to find corresponding pairs.
SELECT
    a.s_d,
    b.e_d
FROM
    @table_a AS a
    JOIN @table_b AS b ON a.rn = b.rn
ORDER BY
    DATEDIFF(DAY, a.s_d, b.e_d) ASC,
    a.s_d;

-- first sort by project duration then by project start date. 
SELECT
    t1.Start_Date,
    t2.End_Date
FROM
    (
        SELECT
            Start_Date,
            ROW_NUMBER() OVER (
                ORDER BY
                    Start_Date ASC
            ) AS rn_start
        FROM
            Projects
        WHERE
            Start_Date NOT IN (
                SELECT
                    End_Date
                FROM
                    Projects
            )
    ) AS t1
    JOIN (
        SELECT
            End_Date,
            ROW_NUMBER() OVER (
                ORDER BY
                    End_Date ASC
            ) AS rn_end
        FROM
            projects
        WHERE
            End_Date NOT IN (
                SELECT
                    Start_Date
                FROM
                    Projects
            )
    ) AS t2 ON t1.rn_start = t2.rn_end
ORDER BY
    DATEDIFF(DAY, t1.Start_date, t2.End_Date) ASC,
    t1.Start_Date;

-- Weather stations, Aggregation, https://www.hackerrank.com/challenges/weather-observation-station-20/problem?isFullScreen=true, Advanced Aggregation
/* main logic: Percentile function with window function
 
 unlike oracle which has a built in median() function. sql server has not built in function to calculate median. 
 the logic to calculate median in sql server is either via calculating the mid between min and max value
 or in this case, I used the percentile method. 
 there are three percentile functions in sql server: PERCENTILE_CONT(), PERCENTILE_DISC() and PERCENT_RANK()
 all three can be used to find the median, here I have used the PERCENT_RANK to achieve that.  */
SELECT
    cast(round(a.LAT_N, 4, 1) AS decimal (9, 4)) -- rounding in sql server leaves trailing zeros, I have to cast it to remove these zeros.
FROM
    STATION AS a
    INNER JOIN (
        SELECT
            ID,
            PERCENT_RANK() OVER (
                ORDER BY
                    LAT_N
            ) AS median,
            LAT_N
        FROM
            STATION
    ) AS b ON a.ID = b.ID
WHERE
    b.median = 0.5;

-- The Pads, https://www.hackerrank.com/challenges/the-pads/problem?isFullScreen=true, Advanced Select
/* Main logic: Case statement. */
SELECT
    CONCAT(Name, "(", LEFT(Occupation, 1), ")")
FROM
    OCCUPATIONS
ORDER BY
    Name ASC;

/* No need to use loop. 
 DECLARE @counter INT;
 SET @counter = (SELECT COUNT(DISTINCT Occupation) FROM OCCUPATIONS);
 WHILE @counter > 0
 BEGIN */
SELECT
    CONCAT(
        "There are a total of ",
        COUNT(Occupation),
        " ",
        LOWER(Occupation),
        CASE
            WHEN COUNT(Occupation) >= 2 THEN "s."
            ELSE "."
        END
    )
FROM
    OCCUPATIONS
GROUP BY
    Occupation
ORDER BY
    COUNT(Occupation),
    Occupation ASC;

--SET @counter -= 1;
--END;
/* Occupations, https://www.hackerrank.com/challenges/occupations/problem?isFullScreen=true, Advanced Select
 main logic: pivoting with window function (use row number )
 
 in this challenge I used sql server's built-in pivoting function. 
 however, an alternative solution is to use CASE statement to manually aggregate and format the result. */
SELECT
    [Doctor],
    [Professor],
    [Singer],
    [Actor] -- after pivot, we only has for columns
FROM
    (
        SELECT
            Name,
            Occupation,
            ROW_NUMBER() OVER (
                PARTITION BY Occupation
                ORDER BY
                    Name
            ) AS rn
            /* row number used to group Name corresponding to the occupation type. I order the name based on the requirement. This return a table with Name, Occupation, Row number in sequences, for example if there are 4 doctors, then 1,2,3,4, if there are 3 Actors, then 1,2,3 */
        FROM
            OCCUPATIONS
    ) AS t PIVOT (
        /* sql server pivting function needs an aggregation for each new column groups. in this case the max function is used to retrive the name, min is fine too. however, count will obvisouly return the occurence rather than the actual name. */
        MAX(Name) FOR Occupation IN ([Doctor], [Professor], [Singer], [Actor])
    ) AS pvt;

-- BST Tree, https://www.hackerrank.com/challenges/binary-search-tree-1/problem?isFullScreen=true, Advanced Select
-- main logic: Case statement
SELECT
    N,
    CASE
        WHEN P IS NULL THEN 'Root'
        WHEN P IS NOT NULL
        AND N IN (
            SELECT
                P
            FROM
                BST
        ) THEN 'Inner'
        ELSE 'Leaf'
    END
FROM
    BST
ORDER BY
    N;

-- Manhattan Distance, https://www.hackerrank.com/challenges/weather-observation-station-18/problem?isFullScreen=true, Advanced aggregation
/* main logic: I accidentally used LAG() calculated the Manhattan Distance amount each individual point. (which I think is harder than the exercise itself.) */
/* SELECT CAST(ROUND(ABS(LAG(LAT_N) OVER (ORDER BY ID) - LAT_N) + ABS(LAG(LONG_W) OVER (ORDER BY ID) - LONG_W), 4) AS DECIMAL(9,4))
 FROM STATION; */
SELECT
    CAST(
        ROUND(
            ABS(MIN(LAT_N) - MAX(LAT_N)) + ABS(MIN(LONG_W) - MAX(LONG_W)),
            4
        ) AS DECIMAL(9, 4)
    )
FROM
    STATION;

-- Euclidean Distance. https://www.hackerrank.com/challenges/weather-observation-station-19/problem?isFullScreen=true, Advanced Aggregation.
/* main logic, similar to previous Manhattan Distance problem; 
 SQRT() for square root, SQUARE() for square in sql server */
SELECT
    CAST(
        ROUND(
            SQRT(
                (SQUARE(MAX(LAT_N) - MIN(LAT_N))) + SQUARE(MAX(LONG_W) - MIN(LONG_W))
            ),
            4
        ) AS DECIMAL(9, 4)
    )
FROM
    STATION;

-- The report, https://www.hackerrank.com/challenges/the-report/problem?isFullScreen=true, Basic Join
/* main logic:  JOIN with BETWEEN instead of normally "=" otherwise FLOOR(s.Marks / 10) * 10 =  g.Min_Marks also a valid logic test.
 IIF() in sql server.
 the ORDER BY is quite confusing.
 */
SELECT
    IIF(g.Grade < 8, NULL, s.Name) AS N,
    g.Grade AS G,
    s.Marks AS M
FROM
    Students AS s
    INNER JOIN Grades AS g ON s.Marks BETWEEN g.Min_Mark
    AND g.Max_Mark
ORDER BY
    g.grade DESC,
    s.name ASC,
    s.Marks ASC;

-- The Top Competititors, https://www.hackerrank.com/challenges/full-score/problem?isFullScreen=true, Basic Join
/* main logic: 1. starting with FROM and JOIN, then work the way to the ouside. 2. use HAVING to do filtering on aggregated results. */
SELECT
    h.hacker_id,
    h.name
FROM
    Hackers AS h
    JOIN Submissions AS s ON h.hacker_id = s.hacker_id
    JOIN Challenges AS c ON s.challenge_id = c.challenge_id
    JOIN Difficulty AS d ON c.difficulty_level = d.difficulty_level
WHERE
    s.score = d.score
GROUP BY
    h.hacker_id,
    h.name
HAVING
    COUNT(h.hacker_id) > 1 -- some people suggested used COUNT(1) > 1 instead of count([column]) works the same. 
ORDER BY
    COUNT(h.hacker_id) DESC,
    h.hacker_id ASC;

-- Ollivander's Inventory, https://www.hackerrank.com/challenges/harry-potter-and-wands/problem?isFullScreen=true, Basic Join
/* main logic: First use a subquery with window function to keep tracking of the minimum cost of wand in each (power and age) group 
 Then use the outter query to filter the result based the coins needed equal the least cost. 
 Another way to achieve this is to use ROW_NUMBER with ORDER BY DESC cluase, then filter the outter query by ROW_NUMBER() = 1
 */
SELECT
    id,
    age,
    coins_needed,
    power
FROM
    (
        SELECT
            w.id AS id,
            wp.age AS age,
            w.coins_needed AS coins_needed,
            MIN(w.coins_needed) OVER (PARTITION BY w.power, wp.age) AS min_coins,
            w.power AS power
        FROM
            Wands AS w
            INNER JOIN Wands_Property AS wp ON w.code = wp.code
        WHERE
            wp.is_evil = 0
    ) AS t
WHERE
    min_coins = coins_needed
ORDER BY
    power DESC,
    age DESC;

-- Challenges, https://www.hackerrank.com/challenges/challenges/problem?isFullScreen=true, basic join
/* main logic:  There are three parts to this problem: 
 1. normal condition: order by total number of challenges desc;
 2. if more than one students, sort by hacker_id desc;
 3. exclude student if more than one students created the same challenge and smaller than the maximum number of chanllenges created. 
 
 The first and second parts can be easily resolved by using ORDER BY with two preceding conditions. 
 
 However the third part have two caveats: 1. if more than one students created the same challenges; or 2. only one student created certain number of challenges. 
 
 Since aggregation involved in this problem (getting count uses aggregation). We need to use Having with OR to deal with the third part (two caveats). 
 
 */
SELECT
    h.hacker_id,
    h.name,
    COUNT(c.challenge_id)
FROM
    Hackers AS h
    JOIN Challenges AS c ON h.hacker_id = c.hacker_id
GROUP BY
    h.hacker_id,
    h.name
HAVING
    COUNT(challenge_id) = (
        SELECT
            MAX(max_cnt)
        FROM
            (
                SELECT
                    COUNT(challenge_id) AS max_cnt,
                    hacker_id
                FROM
                    challenges
                GROUP BY
                    (hacker_id)
            ) AS t1
    ) -- here we use sub queries to find out what's the maximum number of challenges created by each students, and then finding out whether the aggregated amount of challenges equal to that maximum. 
    OR COUNT(c.hacker_id) IN (
        SELECT
            chg_cnt
        FROM
            (
                SELECT
                    COUNT(hacker_id) AS chg_cnt
                FROM
                    Challenges
                GROUP BY
                    hacker_id
            ) AS t2
        GROUP BY
            chg_cnt
        HAVING
            count(chg_cnt) = 1
    ) -- here we solve the second caveat by checking whether a student is in a list of students that create a unique amount of challenges
ORDER BY
    COUNT(c.challenge_id) DESC,
    h.hacker_id;

-- this order solves the first and second requirement. 
-- Contest Leaderboard, https://www.hackerrank.com/challenges/contest-leaderboard/problem?h_r=next-challenge&h_v=zen&isFullScreen=true, Basic Join 
/* Main logic: 1. We need first exclude all students that sored 0 in the sub query, 
 2. then find out the max scored obtained by each student in each challenges (among their multiple submissions in each challenge with MAX aggregation;
 3. lastly use the SUM aggregation to calculate the total. 
 * using windown function with ROW number based on score order for each student and challenge combination should also do the trick.
 */
DECLARE @t1 TABLE (hacker_id int, score int);

DECLARE @t2 TABLE (
    hacker_id int,
    max_score int,
    challenge_id int
);

SELECT
    t2.hacker_id,
    h.name,
    SUM(t2.max_score) AS score
FROM
    Hackers AS h
    JOIN (
        SELECT
            s.hacker_id,
            MAX(score) AS max_score,
            s.challenge_id
        FROM
            Submissions s
            JOIN (
                SELECT
                    hacker_id
                FROM
                    Submissions
                GROUP BY
                    hacker_id
                HAVING
                    SUM(score) > 0
            ) AS t1 -- excluding any students who score 0.
            ON s.hacker_id = t1.hacker_id
        GROUP BY
            s.hacker_id,
            s.challenge_id -- getting max score for each challenge over multiple submissions 
    ) AS t2 ON t2.hacker_id = h.hacker_id
GROUP BY
    t2.hacker_id,
    h.name
ORDER BY
    score DESC,
    t2.hacker_id ASC;

-- Placements, https://www.hackerrank.com/challenges/placements/problem?h_r=next-challenge&h_v=zen&isFullScreen=true, Advanced join
/* Nested join comparison steps outlined below */
---Step 1: Friend salary
SELECT
    s.id AS ID,
    s.Name AS name,
    p.Salary AS fSalary
FROM
    Students s
    JOIN Friend f ON s.id = f.id
    JOIN Packages p ON f.Friend_ID = p.ID;

---Step2: OWN Salary
SELECT
    s.id AS ID,
    s.Name AS name,
    p.Salary AS sSalary
FROM
    Students s
    JOIN Packages p ON s.ID = p.ID;

---Together 
SELECT
    t1.name
FROM
    (
        SELECT
            s.id AS ID,
            s.Name AS name,
            p.Salary AS sSalary
        FROM
            Students s
            JOIN Packages p ON s.ID = p.ID
    ) AS t1
    JOIN (
        SELECT
            s.id AS ID,
            s.Name AS name,
            p.Salary AS fSalary
        FROM
            Students s
            JOIN Friends f ON s.id = f.id
            JOIN Packages p ON f.Friend_ID = p.ID
    ) AS t2 ON t1.name = t2.name
    AND t1.sSalary < t2.fSalary
ORDER BY
    t2.fSalary;

-- Symmetric Pairs, https://www.hackerrank.com/challenges/symmetric-pairs/problem?h_r=next-challenge&h_v=zen, Advanced Join
/* Main logic: Self join, removing duplicate is the key */
SELECT
    t1.X,
    t1.Y
FROM
    Functions t1
    JOIN Functions t2 ON t1.X = t2.Y
    AND t1.Y = t2.X -- it contains duplicate also, the matching condition, we need to remove duplicates in later process. 
GROUP BY
    t1.X,
    t1.Y
HAVING
    COUNT(t1.X) > 1
    OR t1.X < t1.Y -- After group by we will have duplicated records, for example (3,24) appears once is not a symmetric, (3,24) appears twice will be a symmetric pari; 
    -- secondly (3,24) is the same as (24,3), therefore we only need to keep one pair.
ORDER BY
    t1.X ASC;

-- Average Population, https://www.hackerrank.com/challenges/average-population/problem?isFullScreen=true&h_r=next-challenge&h_v=zen, Aggregation
/* main logic: FLOOR, CEILING, ROUND */
SELECT
    FLOOR(AVG(POPULATION))
FROM
    CITY;

-- Interviews, https://www.hackerrank.com/challenges/interviews/problem?isFullScreen=true, Advanced Join
/* main logic, there are 1 to many relationships in here 
 https://medium.com/@smohajer85/sql-challenge-interviews-a50d205d4f3a, this guy also mentioned using CTE. So I reengineered with CTEs based on his brilliant design,
 */
-- contest_id, hacker_id. name, SUM(total_submissions), SUM(total_accepted_submissions), SUM(total_views), SUM(total_unique_views)
SELECT
    Contests.contest_id,
    hacker_id,
    name,
    SUM(totsub),
    SUM(totaccsub),
    SUM(totview),
    SUM(totuniquview)
FROM
    Contests
    JOIN Colleges ON Contests.contest_id = Colleges.contest_id
    JOIN Challenges ON Colleges.college_id = Challenges.college_id
    LEFT JOIN (
        SELECT
            Challenges.challenge_id,
            SUM(total_submissions) AS totsub,
            SUM(total_accepted_submissions) AS totaccsub
        FROM
            Submission_Stats
            JOIN Challenges ON Submission_Stats.challenge_id = Challenges.challenge_id
        GROUP BY
            Challenges.challenge_id
    ) AS t1 ON Challenges.challenge_id = t1.challenge_id
    LEFT JOIN (
        SELECT
            Challenges.challenge_id,
            SUM(total_views) AS totview,
            SUM(total_unique_views) AS totuniquview
        FROM
            View_Stats
            JOIN Challenges ON View_Stats.challenge_id = Challenges.challenge_id
        GROUP BY
            Challenges.challenge_id
    ) AS t2 ON Challenges.challenge_id = t2.challenge_id
GROUP BY
    Contests.contest_id,
    name,
    hacker_id
HAVING
    SUM(totsub) + SUM(totaccsub) + SUM(totview) + SUM(totuniquview) != 0
ORDER BY
    Contests.contest_id;

WITH t1 AS (
    SELECT
        Contests.contest_id,
        hacker_id,
        name,
        Colleges.college_id
    FROM
        Contests
        JOIN Colleges ON Contests.contest_id = Colleges.contest_id
),
t2 AS (
    SELECT
        t1.contest_id,
        hacker_id,
        name,
        Challenges.challenge_id
    FROM
        t1
        JOIN Challenges ON t1.college_id = Challenges.college_id
),
t3 AS (
    SELECT
        Challenges.challenge_id,
        SUM(total_views) AS totview,
        SUM(total_unique_views) AS totuniquview
    FROM
        Challenges
        JOIN View_Stats ON Challenges.challenge_id = View_Stats.challenge_id
    GROUP BY
        Challenges.challenge_id
),
t4 AS (
    SELECT
        Challenges.challenge_id,
        SUM(total_submissions) AS totsub,
        SUM(total_accepted_submissions) AS totaccsub
    FROM
        Challenges
        JOIN Submission_Stats ON Challenges.challenge_id = Submission_Stats.challenge_id
    GROUP BY
        Challenges.challenge_id
),
t5 AS (
    SELECT
        t2.contest_id,
        hacker_id,
        name,
        t2.challenge_id,
        totvie,
        totuniquview
    FROM
        t2
        LEFT JOIN t3 ON t2.challenge_id = t3.challenge_id
),
t6 AS (
    SELECT
        t5.contest_id,
        hacker_id,
        name,
        t5.challenge_id,
        totsub,
        totaccsub,
        totview,
        totuniquview
    FROM
        t5
        LEFT JOIN t4 ON t5.challenge_id = t4.challenge_id
),
-- select * from t6 (left join unmatched will be null in view and submission stats columns), we need to set nulls to 0
t7 AS (
    SELECT
        contest_id,
        hacker_id,
        name,
        COALESCE(totsub, 0) AS totsub,
        COALESCE(totaccsub, 0) AS totaccsub,
        COALESCE(totview, 0) AS totview,
        COALESCE(totuniquview, 0) AS totuniquview
    FROM
        t6
),
t8 AS (
    SELECT
        *,
        total = SUM(totsub, totaccsub, totview, totuniquview)
    FROM
        t7
)
SELECT
    contest_id,
    hacker_id,
    name,
    SUM(totsub),
    SUM(totaccsub),
    SUM(totview),
    SUM(totuniquview)
FROM
    t8
WHERE
    total != 0
GROUP BY
    contest_id,
    name,
    hacker_id
ORDER BY
    contest_id;

-- The Blunder, https://www.hackerrank.com/challenges/the-blunder/problem, Aggregation
/* main logic: multiple cast */
SELECT
    CAST(
        CEILING(
            AVG(CAST(Salary AS FLOAT)) - AVG(
                CAST(REPLACE(CAST(Salary AS VARCHAR), '0', '') AS FLOAT)
            )
        ) AS INT
    )
FROM
    EMPLOYEES;

-- Top Earners, https://www.hackerrank.com/challenges/earnings-of-employees/problem, Aggregation
SELECT
    TOP 1 salary * months,
    COUNT(*)
FROM
    Employee
GROUP BY
    (salary * months)
ORDER BY
    (salary * months) DESC;

-- window funtion version.
SELECT
    topearning,
    count(name)
FROM
    (
        SELECT
            salary * months AS topearning,
            name,
            dense_rank() OVER (
                ORDER BY
                    salary * months DESC
            ) AS rank
        FROM
            Employee
    ) t1
WHERE
    t1.rank = 1
GROUP BY
    topearning;

-- Weather Observation Station 2, https://www.hackerrank.com/challenges/weather-observation-station-2/problem?isFullScreen=true, Aggregation
SELECT
    CAST(ROUND(SUM(LAT_N), 2) AS DECIMAL(9, 2)),
    CAST(ROUND(SUM(LONG_W), 2) AS DECIMAL(9, 2))
FROM
    STATION;

-- Weather Observation Station 13, https://www.hackerrank.com/challenges/weather-observation-station-13/problem, Aggregation
SELECT
    CAST(SUM(LAT_N) AS DECIMAL(18, 4))
FROM
    STATION
WHERE
    LAT_N > 38.7880
    AND LAT_N < 137.2345;

-- Second Highest Salary, https://leetcode.com/problems/second-highest-salary
/* main logic, window function to get rank */
IF (
    SELECT
        COUNT(DISTINCT rank)
    FROM
        (
            SELECT
                dense_rank() OVER (
                    ORDER BY
                        Salary DESC
                ) AS rank
            FROM
                Employee
        ) t
) < 2
SELECT
    TOP 1 NULL AS SecondHighestSalary
FROM
    Employee -- top 1 to get rid of duplicates
    ELSE
SELECT
    TOP 1 e.Salary AS SecondHighestSalary -- top 1 to get rid of duplicates
FROM
    Employee e
    JOIN (
        SELECT
            Salary,
            dense_rank() OVER (
                ORDER BY
                    salary DESC
            ) AS rank
        FROM
            Employee
    ) t ON e.Salary = t.Salary
WHERE
    t.rank = 2;

-- should be a better way of doing this. faster than 46% queries. 
DECLARE @count int;

SET
    @count = (
        SELECT
            COUNT(salary)
        FROM
            Employee
    );

IF @count < 2
SELECT
    'null' AS SecondHighestSalary
FROM
    Employee
    ELSE
SELECT
    DISTINCT salary AS SecondHighestSalary
FROM
    Employee
ORDER BY
    Salary DESC OFFSET 1 ROWS FETCH NEXT 1 ROW ONLY;

-- better solution using offset
-- Nth Highest Salary, https://leetcode.com/problems/nth-highest-salary/
/* main logic, window function to get rank */
CREATE FUNCTION getNthHighestSalary(@N INT) RETURNS INT AS BEGIN RETURN (
    /* Write your T-SQL query statement below. */
    SELECT
        TOP 1 Salary AS getNthHighestSalary -- top 1 to remove duplicates.
    FROM
        (
            SELECT
                Salary,
                dense_rank() OVER (
                    ORDER BY
                        Salary DESC
                ) AS srank
            FROM
                Employee
        ) t
    WHERE
        srank = @N
);

END -- no need to improve, faster than 84% queries. 
-- Rank scores, https://leetcode.com/problems/rank-scores/submissions/
/* main logic: continuous ranking, no gap, needs to use dense_rank. */
-- this is faster than 40% queries, dense_rank is more costly. 
SELECT
    score,
    DENSE_RANK() OVER (
        ORDER BY
            score DESC
    ) AS rank
FROM
    Scores;

-- 1. Interesting comparison, when use group by, this obvisouly will collapse the groups, which is simply gives the rank within the dataset.
SELECT
    b.score,
    count(DISTINCT a.Score) AS rank
FROM
    Scores b
    JOIN Scores a ON b.score <= a.score
GROUP BY
    b.score
ORDER BY
    1 DESC;

-- 2. Alternative way is to use join within the columns to avoid aggregate entire ouput with group by clause. 
-- this is fater than 87% queries. 
SELECT
    b.Score,
    (
        SELECT
            COUNT(DISTINCT a.Score) -- this is actually the rank.
        FROM
            Scores a
        WHERE
            b.Score <= a.Score
    ) AS 'rank'
FROM
    Scores b
ORDER BY
    'rank' -- Game Play Analysis III, https://leetcode.com/problems/game-play-analysis-iii/
    /* main logic: accumulative sum (not rolling sum, otherwise use LAG() */
SELECT
    player_id,
    event_date,
    SUM(games_played) OVER (
        PARTITION BY player_id
        ORDER BY
            event_date
    ) AS games_played_so_far
FROM
    Activity;

-- solution 1: window function with SUM() faster than 85% queries
SELECT
    b.player_id,
    b.event_date,
    (
        SELECT
            SUM(games_played)
        FROM
            Activity a
        WHERE
            a.Player_id = b.Player_id
            AND b.event_date >= a.event_date
    ) -- be careful with the comparison sign
    AS games_played_so_far
FROM
    Activity b
ORDER BY
    b.player_id;

-- solution 2: join query, faster than 93% queries
-- Consecutive Number, https://leetcode.com/problems/consecutive-numbers/submissions/  
SELECT
    DISTINCT t1.ConsecutiveNums -- distinct is needed to remove duplicates
FROM
    (
        SELECT
            (
                CASE
                    WHEN num = LEAD(num, 1, 0) OVER (
                        ORDER BY
                            id DESC
                    )
                    AND num = LEAD(num, 2, 0) OVER (
                        ORDER BY
                            id DESC
                    ) THEN num -- using two lead() to check the next and the third consecutive number.
                END
            ) AS ConsecutiveNums
        FROM
            LOGS
    ) t1
WHERE
    t1.ConsecutiveNums IS NOT NULL;

-- faster than 54% of code. 
SELECT
    DISTINCT t1.num AS ConsecutiveNums
FROM
    (
        SELECT
            num,
            LEAD(num, 1, 0) OVER (
                ORDER BY
                    id DESC
            ) AS next_num,
            LEAD(num, 2, 0) OVER (
                ORDER BY
                    id DESC
            ) AS next_next_num
        FROM
            LOGS
    ) t1
WHERE
    t1.num = t1.next_num
    AND t1.num = t1.next_next_num;

-- using where faster than 77.12%
-- the follwing two queries works the same, notice the difference in joining condition and where clause. 
SELECT
    DISTINCT t1.num AS ConsecutiveNums
FROM
    LOGS t1
    JOIN LOGS t2 ON t1.id = t2.id - 1 -- join on the next consective number. 
    JOIN LOGS t3 ON t1.id = t3.id - 2 -- join on the next next consective number  (this is where the consective from)
WHERE
    t1.num = t2.num
    AND t1.num = t3.num;

-- this only faster than 47.43% queries, I guess there are two full joins here.
SELECT
    DISTINCT t1.num AS ConsecutiveNums
FROM
    LOGS t1
    JOIN LOGS t2 ON t1.id = t2.id - 1
    JOIN LOGS t3 ON t2.id = t3.id - 1
WHERE
    t1.num = t2.num
    AND t1.num = t3.num;

-- faster than 95.20% queries,  the second join is built on the first join where lots of duplicated records has been filtered out. 
-- Combine Two Tables, https://leetcode.com/problems/combine-two-tables/
/* left join */
SELECT
    p.firstName,
    p.lastName,
    a.city,
    a.state
FROM
    PERSON p
    LEFT JOIN ADDRESS a ON p.personId = a.personId -- Department Highest Salary, https://leetcode.com/problems/department-highest-salary/
    /* Highest, top? rank? max? */
SELECT
    d.name AS Department,
    t.name AS Employee,
    t.salary AS Salary
FROM
    (
        SELECT
            *,
            rank() OVER (
                PARTITION BY departmentId
                ORDER BY
                    salary DESC
            ) ranking
        FROM
            Employee
    ) t
    JOIN Department d ON t.departmentId = d.id
WHERE
    t.ranking = 1;

-- faster than 36.44% queries. 
WITH t1 AS (
    SELECT
        d.id AS departmentId,
        d.name AS Department,
        max(salary) AS max_salary
    FROM
        Employee e1
        JOIN Department d ON d.id = e1.departmentId
    GROUP BY
        d.id,
        d.name
) -- the key things is to aggregate on the joined table column instead of own column
SELECT
    t1.Department,
    e2.name AS Employee,
    t1.max_salary AS Salary
FROM
    t1
    JOIN Employee e2 ON e2.departmentId = t1.departmentId
    AND e2.salary = t1.max_salary;

-- CTE implementation, faster than 68.55% solution. 
-- there are might be a way to use TOP 1 with order to get rank, but I have not find a way to do this. 
-- Game Play Analysis IV, https://leetcode.com/problems/game-play-analysis-iv/
/* main logic: DATEADD(day/month/year, ,) to get the second login time. 
 alternatives DATEDIFF(day/month/year, ),
 (WINDOW function might work in this case as well) */
WITH c1 AS (
    SELECT
        COUNT(DISTINCT a1.player_id) AS count
    FROM
        Activity a1
        JOIN ACtivity a2 ON a1.player_id = a2.player_id
        AND a1.event_date = DATEADD(DAY, 1, a2.event_date)
)
SELECT
    ROUND(
        c1.count * 1.00 /(
            SELECT
                COUNT(DISTINCT player_id)
            FROM
                Activity
        ),
        2
    ) AS fraction
FROM
    c1;

-- this is an wrong solution, it does not take into account that the consecutive login has to occur after the first login. 
WITH login_after_first_time AS (
    SELECT
        player_id,
        DATEADD(DAY, 1, min(event_date)) AS consecutive_login
    FROM
        Activity
    GROUP BY
        player_id
),
player_count AS (
    SELECT
        COUNT(DISTINCT(a1.player_id)) AS count
    FROM
        Activity a1
        JOIN login_after_first_time ON login_after_first_time.player_id = a1.player_id
        AND login_after_first_time.consecutive_login = a1.event_date
)
SELECT
    CAST(
        ROUND(
            (
                player_count.count * 1.00 /(
                    SELECT
                        COUNT(DISTINCT(a2.player_id))
                    FROM
                        Activity a2
                )
            ),
            2
        ) AS DECIMAL(9, 2)
    ) AS fraction
FROM
    player_count -- faster than 28.15% queries.
SELECT
    ROUND(
        CAST(
            SUM(
                CASE
                    WHEN datediff(DAY, first_login, event_date) = 1 THEN 1
                    ELSE 0
                END
            ) AS DECIMAL(9, 2)
        ) / count(DISTINCT player_id),
        2
    ) AS fraction
FROM
    (
        SELECT
            player_id,
            event_date,
            first_value(event_date) OVER (
                PARTITION BY player_id
                ORDER BY
                    event_date
            ) AS first_login
        FROM
            activity
    ) t -- window function version, faster than 65.96% result
    --Managers with at Least 5 direct report. https://leetcode.com/problems/managers-with-at-least-5-direct-reports/
SELECT
    e1.name
FROM
    (
        SELECT
            name,
            id
        FROM
            Employee
    ) AS e1
    LEFT JOIN Employee e2 ON e1.id = e2.managerId
GROUP BY
    e1.name
HAVING
    count(e2.managerId) >= 5 -- simple self join. faster than 75.83% result.
    -- Winning Candidate, https://leetcode.com/problems/winning-candidate/
    /* main logic: number of votes exists as repeated occurence in Vote table, for example candiditeId 2 occured twice, means B got 2 votes
     I'm using row number to get the number of occurences
     */
SELECT
    c.name
FROM
    Candidate c
    JOIN Vote v ON c.id = v.candidateId
GROUP BY
    c.name
HAVING
    count(v.id) = (
        SELECT
            max(rn)
        FROM
            (
                SELECT
                    row_number() OVER (
                        PARTITION BY candidateId
                        ORDER BY
                            id
                    ) AS rn
                FROM
                    Vote
            ) t
    ) -- faster than 43.56% query. 
    -- Get Highest Answer Rate Question, https://leetcode.com/problems/get-highest-answer-rate-question/
    WITH t1 AS (
        SELECT
            count(question_id) AS count,
            question_id
        FROM
            SurveyLog
        WHERE
            answer_id IS NOT NULL
            AND ACTION = 'answer'
        GROUP BY
            question_id
    )
SELECT
    question_id AS survey_log
FROM
    SurveyLog
WHERE
    answer_id IS NOT NULL
    AND ACTION = 'answer'
GROUP BY
    question_id
HAVING
    count(question_id) = (
        SELECT
            MAX(t1.count) AS max_answered
        FROM
            t1
    );

-- CTE solution, faster 13.6% of queries,. Purhaps should use window function with ROW_NUMBER
-- Employees Earning More Than Their Managers, https://leetcode.com/problems/employees-earning-more-than-their-managers/
/* Easy self join */
SELECT
    e1.name AS Employee
FROM
    Employee e1
    JOIN Employee e2 ON e1.managerId = e2.id
    AND e1.salary > e2.salary;

-- Count Student Number in Departments, https://leetcode.com/problems/count-student-number-in-departments/
/* count or max(row_number) */
SELECT
    DISTINCT d.dept_name,
    (
        CASE
            WHEN t2.student_count IS NULL THEN 0
            ELSE t2.student_count
        END
    ) AS student_number
FROM
    Department d
    LEFT JOIN (
        SELECT
            MAX(rn) OVER (PARTITION BY t1.dept_id) AS student_count,
            t1.dept_id
        FROM
            (
                SELECT
                    ROW_NUMBER() OVER (
                        PARTITION BY dept_id
                        ORDER BY
                            student_id
                    ) AS rn,
                    dept_id
                FROM
                    Student
            ) AS t1
    ) AS t2 ON d.dept_id = t2.dept_id
ORDER BY
    student_number DESC,
    d.dept_name -- REMERBER!!! use distinct to get rid duplicates from left join. faster than 52% of queries. count should do the trick with window function too.
    --Investments in 2016, https://leetcode.com/problems/investments-in-2016/
    WITH t AS (
        SELECT
            tiv_2016,
            COUNT(*) OVER (PARTITION BY tiv_2015) AS count_15,
            COUNT(*) OVER (PARTITION BY lat, lon) AS count_loc
        FROM
            Insurance
    )
SELECT
    CAST(SUM(tiv_2016) AS DECIMAL(10, 2)) AS tiv_2016
FROM
    t
WHERE
    count_15 >= 2
    AND count_loc = 1;

-- faster than 58% of query
--Friend Requests II: Who Has the Most Friends, https://leetcode.com/problems/friend-requests-ii-who-has-the-most-friends/
/* self left join with CTE, do not use Window function otherwise it will leave duplicates */
WITH t1 AS (
    SELECT
        requester_id,
        count(*) AS rqst_cnt
    FROM
        RequestAccepted
    GROUP BY
        requester_id
),
t2 AS (
    SELECT
        accepter_id,
        count(*) AS accpt_cnt
    FROM
        RequestAccepted
    GROUP BY
        accepter_id
)
SELECT
    TOP 1 t1.requester_id,
    isnull(t1.rqst_cnt, 0) + isnull(t2.accpt_cnt, 0) AS num
FROM
    t1
    LEFT JOIN t2 ON t1.requester_id = t2.accepter_id
ORDER BY
    isnull(t1.rqst_cnt, 0) + isnull(t2.accpt_cnt, 0) DESC -- I only worked out the first logic where 'Left join' is needed. 
    -- However, we need isnull to remove null from left join. and use "top 1" and "order by" to get the result. 
    -- Tree Node, https://leetcode.com/problems/tree-node/
    /* case statement with 'In clause'*/
SELECT
    t1.id,
    (
        CASE
            WHEN t1.p_id IS NULL THEN 'Root'
            WHEN t1.id IN (
                SELECT
                    t2.p_id
                FROM
                    Tree AS t2
            ) THEN 'Inner'
            ELSE 'Leaf'
        END
    ) AS TYPE
FROM
    Tree AS t1 -- this is similar to the one I have done in hackers rank.
    -- 612. Shortest Distance in a Plane, https://leetcode.com/problems/shortest-distance-in-a-plane/
    /* main logic: cross join */
SELECT
    CAST(ROUND(MIN(dis), 2) AS DECIMAL(9, 2)) AS shortest
FROM
    (
        SELECT
            SQRT(SQUARE(p2.x - p1.x) + SQUARE(p2.y - p1.y)) AS dis
        FROM
            Point2D AS p1
            CROSS JOIN Point2D AS p2
    ) AS t
WHERE
    dis > 0 -- this removes self calculating;
    -- I first thought using cursor turns out it's an over complicated thinking. Cross join is way more efficient. 
    -- 614. Second Degree Follower SELECT f1.followee as follower, COUNT(DISTINCT f1.follower) as num
    /* main logic: self join */
SELECT
    f1.followee AS follower,
    COUNT(DISTINCT f1.follower) AS num
FROM
    Follow AS f1
    JOIN Follow AS f2 ON f1.followee = f2.follower
GROUP BY
    f1.followee
ORDER BY
    f1.followee -- 626. Exchange Seats, https://leetcode.com/problems/exchange-seats/
    /* main logic: do not think iteration or if-else , use LEAD and LAG for swap, ISNULL to deal with the first row */
SELECT
    s.id AS id,
    IIF(
        s.id % 2 = 1,
        ISNULL(
            LEAD(student) OVER (
                ORDER BY
                    id ASC
            ),
            s.student
        ),
        LAG(student) OVER (
            ORDER BY
                id ASC
        )
    ) AS student
FROM
    Seat s -- 1045. Customers Who Bought All Products, https://leetcode.com/problems/customers-who-bought-all-products/
    /* main logic: simple sub query */
    /* 
     The following window function will not work as customer may bought multiple products, and you CANNOT use distinct in WINDOW function.
     
     SELECT DISTINCT t1.customer_id FROM
     (SELECT t.customer_id AS customer_id, COUNT(t.product_key) OVER (PARTITION BY t.customer_id) as product_count
     FROM Customer t
     JOIN Product p
     ON t.product_key = p.product_key) AS t1
     WHERE t1.product_count = (SELECT COUNT(DISTINCT product_key) FROM Product) */
SELECT
    c.customer_id
FROM
    Customer c
    JOIN Product p ON c.product_key = p.product_key
GROUP BY
    c.customer_id
HAVING
    COUNT(DISTINCT c.product_key) = (
        SELECT
            COUNT(DISTINCT product_key)
        FROM
            Product
    ) -- 1070. Product Sales Analysis III, https://leetcode.com/problems/product-sales-analysis-iii/
    /* main logic: simple RANK() window function */
SELECT
    product_id,
    year AS first_year,
    quantity,
    price
FROM
    (
        SELECT
            product_id,
            year,
            quantity,
            price,
            RANK() OVER (
                PARTITION BY product_id
                ORDER BY
                    year ASC
            ) AS rk
        FROM
            Sales
    ) t
WHERE
    rk = 1 -- 1010, Pairs of Songs With Total Durations Divisible by 60, https://leetcode.com/problems/pairs-of-songs-with-total-durations-divisible-by-60/
    WITH t1 AS (
        SELECT
            p.project_id,
            p.employee_id,
            DENSE_RANK() OVER (
                PARTITION BY p.project_id
                ORDER BY
                    e.experience_years DESC
            ) AS rnk
        FROM
            Project p
            CROSS APPLY Employee e
        WHERE
            p.employee_id = e.employee_id
    )
SELECT
    project_id,
    employee_id
FROM
    t1
WHERE
    rnk = 1 -- 1098. Unpopular Books, https://leetcode.com/problems/unpopular-books/
    /* main logic: the question itself is really confusing. 
     1. Reverse thinking, to get a list of books that does not fit search criteria.
     2. use dateadd, do not use straight forward date comparison.
     */
SELECT
    book_id,
    name
FROM
    books
WHERE
    book_id NOT IN (
        SELECT
            book_id
        FROM
            Orders
        GROUP BY
            book_id
        HAVING
            sum(
                CASE
                    WHEN dispatch_date >= DATEADD(YEAR, -1, '2019-06-23') THEN quantity
                    ELSE 0
                END
            ) >= 10
        UNION
        (
            SELECT
                book_id
            FROM
                Books
            WHERE
                available_from > DATEADD(MONTH, -1, '2019-06-23')
        )
    )
SELECT
    user_id,
    activity,
    ROW_NUMBER() OVER (PARTITION BY user_id, activity_date) AS rnk,
    activity_date
FROM
    Traffic
WHERE
    activity_date >= DATEADD(DAY, -90, '2019-06-30')
    AND activity = 'login' -- 1164. Product Price at a Given Date, https://leetcode.com/problems/product-price-at-a-given-date/
    /* main logic: 
     step 1: get a list of product that has changed price before the given date 
     step 2: use row number to order the step 1 subset based on the date column.
     step 3: select row number = 1 to get the most recent price
     step 4: get a list of products regardless whether they have changed price or not
     step 5: left join or right join with a case statement to default the price to 10 dollers for products that have not changed price before the given date
     */
    WITH t1 AS (
        SELECT
            product_id,
            new_price AS price
        FROM
            (
                SELECT
                    product_id,
                    new_price,
                    ROW_NUMBER() OVER (
                        PARTITION BY product_id
                        ORDER BY
                            change_date DESC
                    ) AS rownum
                FROM
                    Products
                WHERE
                    change_date <= '2019-08-16'
            ) t
        WHERE
            rownum = 1
    ),
    t2 AS (
        SELECT
            DISTINCT product_id
        FROM
            Products
    )
SELECT
    t2.product_id,
    (
        CASE
            WHEN t1.price IS NULL THEN 10
            ELSE t1.price
        END
    ) AS price
FROM
    t1
    RIGHT JOIN t2 ON t1.product_id = t2.product_id -- 1174. Immediate Food Delivery II, https://leetcode.com/problems/immediate-food-delivery-ii/
    /* main logic: 
     1. row number to get earliest order by date;
     2. then CTEs to organize code
     */
    WITH t1 AS (
        SELECT
            delivery_id
        FROM
            Delivery
        WHERE
            order_date = customer_pref_delivery_date
    ),
    t2 AS (
        SELECT
            delivery_id
        FROM
            (
                SELECT
                    delivery_id,
                    row_number() OVER (
                        PARTITION BY customer_id
                        ORDER BY
                            order_date ASC
                    ) AS rownum
                FROM
                    Delivery
            ) t
        WHERE
            rownum = 1
    )
SELECT
    ROUND(
        (COUNT(t1.delivery_id) * 1.00) / (COUNT(t2.delivery_id) * 1.00) * 100,
        2
    ) AS immediate_percentage
FROM
    t1
    RIGHT JOIN t2 ON t1.delivery_id = t2.delivery_id -- 185. Department Top Three Salaries, Hard, https://leetcode.com/problems/department-top-three-salaries/
    /* place holder */
SELECT
    d.name AS Department,
    e.name AS Employee,
    e.salary AS Salary
FROM
    (
        SELECT
            dense_rank() OVER (
                PARTITION BY departmentId
                ORDER BY
                    salary DESC
            ) AS salary_rank,
            departmentId,
            id
        FROM
            Employee
    ) AS t1
    JOIN Employee e ON t1.id = e.id
    JOIN Department d ON d.id = t1.departmentId
WHERE
    salary_rank <= 3 -- 262. Trips and Users, Hard https://leetcode.com/problems/trips-and-users/
    /* place holder */
    WITH t1 AS (
        SELECT
            *
        FROM
            Users u
        WHERE
            LOWER(banned) = 'No'
            AND LOWER(role) = 'driver'
    ),
    t2 AS (
        SELECT
            *
        FROM
            Users u
        WHERE
            LOWER(banned) = 'No'
            AND LOWER(role) = 'client'
    ),
    t3 AS (
        SELECT
            COUNT(id) AS total_cancelled,
            request_at
        FROM
            Trips
        WHERE
            client_id IN (
                SELECT
                    users_id
                FROM
                    t2
            )
            AND driver_id IN (
                SELECT
                    users_id
                FROM
                    t1
            )
            AND STATUS LIKE '%cancelled%'
            AND request_at BETWEEN '2013-10-01'
            AND '2013-10-03'
        GROUP BY
            request_at
    ),
    t4 AS (
        SELECT
            COUNT(id) AS total_count,
            request_at
        FROM
            Trips
        WHERE
            client_id IN (
                SELECT
                    users_id
                FROM
                    t2
            )
            AND driver_id IN (
                SELECT
                    users_id
                FROM
                    t1
            )
            AND request_at BETWEEN '2013-10-01'
            AND '2013-10-03'
        GROUP BY
            request_at
    )
SELECT
    t4.request_at AS DAY,
    ISNULL(
        CAST(
            CAST(t3.total_cancelled AS FLOAT) / CAST(t4.total_count AS FLOAT) AS DECIMAL(9, 2)
        ),
        0.00
    ) AS 'Cancellation Rate'
FROM
    t3
    RIGHT JOIN t4 ON t3.request_at = t4.request_at -- 1193. Monthly Transactions I， https://leetcode.com/problems/monthly-transactions-i/
    WITH t1 AS (
        SELECT
            FORMAT(trans_date, 'yyyy-MM') AS MONTH,
            country,
            COUNT(id) AS trans_count,
            sum(amount) AS trans_total_amount
        FROM
            Transactions
        GROUP BY
            FORMAT(trans_date, 'yyyy-MM'),
            country
    ),
    t2 AS (
        SELECT
            FORMAT(trans_date, 'yyyy-MM') AS MONTH,
            country,
            COUNT(id) AS approved_count,
            sum(amount) AS approved_total_amount
        FROM
            Transactions
        WHERE
            state LIKE 'approved'
        GROUP BY
            FORMAT(trans_date, 'yyyy-MM'),
            country
    )
SELECT
    t1.month,
    t1.country,
    t1.trans_count,
    ISNULL(t2.approved_count, 0) AS approved_count,
    t1.trans_total_amount,
    ISNULL(t2.approved_total_amount, 0) AS approved_total_amount
FROM
    t1
    LEFT JOIN t2 ON t1.month = t2.month
    AND t1.country = t2.country
    /* alternative method: remember SELECT is acting row by row like a loop */
SELECT
    FORMAT(trans_date, 'yyyy-MM') AS MONTH,
    country,
    SUM(
        CASE
            WHEN state IS NOT NULL THEN 1
            ELSE 0
        END
    ) AS trans_count,
    SUM(
        CASE
            WHEN LOWER(state) = 'approved' THEN 1
            ELSE 0
        END
    ) AS approved_count,
    SUM(
        CASE
            WHEN state IS NOT NULL THEN amount
            ELSE 0
        END
    ) AS trans_total_amount,
    SUM(
        CASE
            WHEN LOWER(state) = 'approved' THEN amount
            ELSE 0
        END
    ) AS approved_total_amount
FROM
    transactions
GROUP BY
    FORMAT(trans_date, 'yyyy-MM'),
    country
ORDER BY
    SUM(
        CASE
            WHEN state IS NOT NULL THEN 1
            ELSE 0
        END
    ) DESC -- 1204. Last Person to Fit in the Bus, https://leetcode.com/problems/last-person-to-fit-in-the-bus/
SELECT
    TOP 1 person_name
FROM
    (
        SELECT
            turn,
            person_name,
            sum(weight) OVER (
                ORDER BY
                    turn
            ) AS rolling_total
        FROM
            Queue
    ) t
WHERE
    rolling_total <= 1000
ORDER BY
    turn DESC -- 1841. League Statistics, https://leetcode.com/problems/league-statistics/
    /* failed on first try, forgot to use Union All 
     main logic: 
     1. try deal the problem from two angels, home game and away game.
     2. then union them together based on team_name
     3. it won't be any duplicates
     
     */
    WITH home AS (
        SELECT
            t.team_name,
            SUM(m.home_team_goals) AS goal_for,
            count(m.home_team_goals) AS played,
            SUM(
                CASE
                    WHEN m.home_team_goals > m.away_team_goals THEN 3 -- when playing on the wining side.
                    WHEN m.home_team_goals = m.away_team_goals THEN 1
                    ELSE 0
                END
            ) AS points,
            SUM(m.away_team_goals) AS goal_against
        FROM
            Teams t
            JOIN Matches m ON t.team_id = m.home_team_id
        GROUP BY
            t.team_name
    ),
    away AS (
        SELECT
            t.team_name,
            SUM(m.away_team_goals) AS goal_for,
            count(m.away_team_goals) AS played,
            SUM(
                CASE
                    WHEN m.home_team_goals < m.away_team_goals THEN 3 -- when playing on the away side
                    WHEN m.home_team_goals = m.away_team_goals THEN 1
                    ELSE 0
                END
            ) AS points,
            SUM(m.home_team_goals) AS goal_against
        FROM
            Teams t
            JOIN Matches m ON t.team_id = m.away_team_id
        GROUP BY
            t.team_name
    )
SELECT
    team_name,
    SUM(played) AS matches_played,
    SUM(points) AS points,
    SUM(goal_for) AS goal_for,
    SUM(goal_against) AS goal_against,
    SUM(goal_for) - SUM(goal_against) AS goal_diff
FROM
    (
        SELECT
            *
        FROM
            home
        UNION
        ALL (
            SELECT
                *
            FROM
                away
        )
    ) AS final
GROUP BY
    team_name
ORDER BY
    points DESC,
    goal_diff DESC,
    team_name ASC;

--1501. Countries You Can Safely Invest In, https://leetcode.com/problems/countries-you-can-safely-invest-in/
/* main logic: similar to 1204, using UNION ALL
 Union all is useful when the same information appears in two columns, and there is a relationship between these two columns, and there is another dimension table contain information for both sides.
 For example, employer vs employee, caller vs callee, requester vs requestee.
 */
WITH caller AS (
    SELECT
        c.name AS country,
        SUM(duration) AS duration,
        count(cs.callee_id) AS calls
    FROM
        Person AS p
        JOIN Country AS c ON LEFT(p.phone_number, 3) = c.country_code
        JOIN Calls cs ON p.id = cs.caller_id
    GROUP BY
        c.name
),
callee AS (
    SELECT
        c.name AS country,
        SUM(duration) AS duration,
        count(cs.callee_id) AS calls
    FROM
        Person AS p
        JOIN Country AS c ON LEFT(p.phone_number, 3) = c.country_code
        JOIN Calls cs ON p.id = cs.callee_id
    GROUP BY
        c.name
)
SELECT
    country
FROM
    (
        (
            SELECT
                *
            FROM
                caller
        )
        UNION
        ALL (
            SELECT
                *
            FROM
                callee
        )
    ) AS t
GROUP BY
    country
HAVING
    (SUM(duration) * 1.00 / SUM(calls)) > (
        SELECT
            AVG(CAST(duration AS DECIMAL(9, 2)))
        FROM
            Calls
    ) 
-- 1454. Active Users, https://leetcode.com/problems/active-users/
    /* main logic: 
     the key idea here is thinking reversely (order by login_date desc)  
     The fist login date is nth day away from the last login date.
     
     Another import thing is to use distinct to get rid of multiple logins in the same day.
     */
    WITH t1 AS (
        SELECT
            id,
            login_date,
            DATEADD(
                DAY,
                DENSE_RANK() OVER (
                    PARTITION BY id
                    ORDER BY
                        login_date DESC
                ),
                login_date
            ) AS ConsecDays
        FROM
            (
                SELECT
                    DISTINCT *
                FROM
                    Logins
            ) AS t
    )
SELECT
    DISTINCT a.id,
    a.name
FROM
    t1
    JOIN Accounts a ON a.id = t1.id
GROUP BY
    a.id,
    a.name,
    ConsecDays
HAVING
    COUNT(DISTINCT login_date) >= 5
ORDER BY
    1 -- 1811. Find Interview Candidates, https://leetcode.com/problems/find-interview-candidates/
    /* the main logic is similar to 1454, with 1 caveat thatL 
     unlike date, to calculate consective number we use contest_id + rank - 1 */
    WITH t1 AS (
        SELECT
            u.user_id AS user_id
        FROM
            Users u
        WHERE
            u.user_id IN (
                SELECT
                    DISTINCT gold_medal
                FROM
                    Contests
                GROUP BY
                    gold_medal
                HAVING
                    COUNT(contest_id) >= 3
            )
    ),
    t2 AS (
        SELECT
            contest_id,
            gold_medal AS user_id
        FROM
            Contests
        UNION
        ALL (
            SELECT
                contest_id,
                silver_medal
            FROM
                Contests
        ) -- this can be replaced with unpivot in sql server
        UNION
        ALL (
            SELECT
                contest_id,
                bronze_medal
            FROM
                Contests
        )
    ),
    t3 AS (
        SELECT
            user_id,
            contest_id,
            (
                contest_id + DENSE_RANK() OVER (
                    PARTITION BY user_id
                    ORDER BY
                        contest_id DESC
                ) - 1
            ) AS consecContest
        FROM
            t2
    ),
    t4 AS (
        SELECT
            DISTINCT user_id
        FROM
            t3
        GROUP BY
            user_id,
            consecContest
        HAVING
            COUNT(DISTINCT contest_id) >= 3
        UNION
        (
            SELECT
                user_id
            FROM
                t1
        )
    )
SELECT
    u.name,
    u.mail
FROM
    Users u
    JOIN t4 ON u.user_id = t4.user_id -- using pivot instead of union
    WITH t1 AS (
        SELECT
            u.user_id AS user_id
        FROM
            Users u
        WHERE
            u.user_id IN (
                SELECT
                    DISTINCT gold_medal
                FROM
                    Contests
                GROUP BY
                    gold_medal
                HAVING
                    COUNT(contest_id) >= 3
            )
    ),
    t2 AS (
        -- this is unique to sql server, using unpivot is actually more tidier than union, because we know have the information of medal type (FOR... IN... section) 
        SELECT
            contest_id,
            user_id
        FROM
            (
                SELECT
                    contest_id,
                    gold_medal,
                    silver_medal,
                    bronze_medal
                FROM
                    Contests
            ) c UNPIVOT (
                user_id FOR medal IN (gold_medal, silver_medal, bronze_medal)
            ) AS pvt
    ),
    t3 AS (
        SELECT
            user_id,
            contest_id,
            (
                contest_id + DENSE_RANK() OVER (
                    PARTITION BY user_id
                    ORDER BY
                        contest_id DESC
                ) - 1
            ) AS consecContest
        FROM
            t2
    ),
    t4 AS (
        SELECT
            DISTINCT user_id
        FROM
            t3
        GROUP BY
            user_id,
            consecContest
        HAVING
            COUNT(DISTINCT contest_id) >= 3
        UNION
        (
            SELECT
                user_id
            FROM
                t1
        )
    )
SELECT
    u.name,
    u.mail
FROM
    Users u
    JOIN t4 ON u.user_id = t4.user_id -- 1934. Confirmation Rate, https://leetcode.com/problems/confirmation-rate/
    /*  */
SELECT
    s.user_id,
    CASE
        WHEN t3.id IS NULL THEN 0
        ELSE t3.confirmation_rate
    END AS confirmation_rate
FROM
    Signups s
    LEFT JOIN (
        SELECT
            t1.id AS id,
            ROUND(COUNT(t2.action) * 1.00 / t1.total_requested, 2) AS confirmation_rate
        FROM
            (
                SELECT
                    COUNT(ACTION) OVER (PARTITION BY user_id) AS total_requested,
                    user_id AS id,
                    time_stamp
                FROM
                    Confirmations
            ) t1
            JOIN (
                SELECT
                    *
                FROM
                    Confirmations
                WHERE
                    ACTION = 'confirmed'
            ) t2 ON t1.time_stamp = t2.time_stamp
        GROUP BY
            id,
            t1.total_requested
    ) t3 ON s.user_id = t3.id -- 1867. Orders With Maximum Quantity Above Average, https://leetcode.com/problems/orders-with-maximum-quantity-above-average/
SELECT
    order_id
FROM
    (
        SELECT
            o.order_id,
            o.quantity,
            MAX(t.avg) OVER () AS max_avg
        FROM
            OrdersDetails o
            JOIN (
                SELECT
                    SUM(quantity) * 1.00 / count(DISTINCT product_id) AS avg,
                    order_id AS id
                FROM
                    OrdersDetails
                GROUP BY
                    order_id
            ) t ON o.order_id = t.id
    ) t1
GROUP BY
    order_id,
    max_avg
HAVING
    MAX(quantity) > max_avg -- 1270, All People Report to the Given Manager, https://leetcode.com/problems/all-people-report-to-the-given-manager/
    /* not right join */
    WITH direct AS (
        SELECT
            e1.employee_id AS employee_id
        FROM
            Employees e
            JOIN Employees e1 ON e.manager_id = e1.manager_id
        WHERE
            e.manager_id = 1
    ),
    direct_exclude_boss AS (
        SELECT
            *
        FROM
            direct
        WHERE
            employee_id <> 1
    ),
    indirect_1 AS (
        SELECT
            e2.employee_id AS employee_id
        FROM
            direct_exclude_boss
            JOIN Employees e2 ON direct_exclude_boss.employee_id = e2.manager_id
    ),
    indirect_2 AS (
        SELECT
            e3.employee_id AS employee_id
        FROM
            indirect_1
            JOIN Employees e3 ON indirect_1.employee_id = e3.manager_id
    ),
    indirect_3 AS (
        SELECT
            e3.employee_id AS employee_id
        FROM
            indirect_2
            JOIN Employees e3 ON indirect_2.employee_id = e3.manager_id
    )
SELECT
    employee_id
FROM
    direct_exclude_boss
UNION
(
    SELECT
        employee_id
    FROM
        indirect_1
)
UNION
(
    SELECT
        employee_id
    FROM
        indirect_2
)
UNION
(
    SELECT
        employee_id
    FROM
        indirect_3
) --2020. Number of Accounts That Did Not Stream, https://leetcode.com/problems/number-of-accounts-that-did-not-stream/
SELECT
    COUNT(DISTINCT account_id) AS accounts_count
FROM
    Subscriptions
WHERE
    (
        YEAR(end_date) = 2021
        OR YEAR(start_date) = 2021
    )
    AND EXISTS (
        SELECT
            1
        FROM
            Streams
        WHERE
            Subscriptions.account_id = Streams.account_id
            AND YEAR(stream_date) <> 2021
    ) -- 1205. Monthly Transactions II, https://leetcode.com/problems/monthly-transactions-ii/
    WITH t1 AS (
        SELECT
            t.id AS id,
            t.country AS country,
            t.state AS state,
            t.amount AS amount,
            FORMAT(t.trans_date, 'yyyy-MM') AS MONTH
        FROM
            Transactions t
        UNION
        (
            SELECT
                c.trans_id AS id,
                t2.country,
                'chargeback' AS state,
                t2.amount AS amount,
                FORMAT(c.trans_date, 'yyyy-MM') AS MONTH
            FROM
                chargebacks c
                LEFT JOIN transactions t2 ON c.trans_id = t2.id
        )
    )
SELECT
    MONTH,
    country,
    SUM(
        CASE
            WHEN state = 'approved' THEN 1
            ELSE 0
        END
    ) AS approved_count,
    SUM(
        CASE
            WHEN state = 'approved' THEN amount
            ELSE 0
        END
    ) AS approved_amount,
    SUM(
        CASE
            WHEN state = 'chargeback' THEN 1
            ELSE 0
        END
    ) AS chargeback_count,
    SUM(
        CASE
            WHEN state = 'chargeback' THEN amount
            ELSE 0
        END
    ) AS chargeback_amount
FROM
    t1
GROUP BY
    MONTH,
    country
HAVING
    SUM(
        CASE
            WHEN state = 'approved' THEN 1
            ELSE 0
        END
    ) + SUM(
        CASE
            WHEN state = 'chargeback' THEN 1
            ELSE 0
        END
    ) != 0 -- remove the rows for charge back
    -- 1321. Restaurant Growth, https://leetcode.com/problems/restaurant-growth/
SELECT
    visited_on,
    SUM(SUM(amount)) OVER(
        ORDER BY
            visited_on ROWS BETWEEN 6 PRECEDING
            AND CURRENT ROW
    ) AS amount,
    ROUND(
        SUM(SUM(amount)) OVER(
            ORDER BY
                visited_on ROWS BETWEEN 6 PRECEDING
                AND CURRENT ROW
        ) / 7.0,
        2
    ) AS average_amount
FROM
    Customer
GROUP BY
    visited_on
ORDER BY
    visited_on OFFSET 6 ROWS -- 1285. Find the Start and End Number of Continuous Ranges, https://leetcode.com/problems/find-the-start-and-end-number-of-continuous-ranges/
SELECT
    DISTINCT MIN(log_id) OVER (PARTITION BY sum_rnk) AS start_id,
    MAX(log_id) OVER (PARTITION BY sum_rnk) AS end_id
FROM
    (
        SELECT
            log_id,
            log_id + RANK() OVER (
                ORDER BY
                    log_id DESC
            ) AS sum_rnk
        FROM
            LOGS
    ) t1 WITH t1 AS (
        SELECT
            user1_id,
            user2_id
        FROM
            Friendship f
        WHERE
            user1_id = 1
    ),
    t2 AS (
        SELECT
            user1_id,
            user2_id
        FROM
            Friendship f
        WHERE
            user2_id = 1
    ),
    t3 AS (
        SELECT
            user1_id,
            user2_id
        FROM
            t1
        UNION
        (
            SELECT
                user2_id,
                user1_id
            FROM
                t2
        )
    ) 
-- 1264. Page Recommendations, https://leetcode.com/problems/page-recommendations/
SELECT page_id AS recommended_page
FROM Likes l1
WHERE (user_id IN
    (SELECT user2_id
    FROM Friendship
    WHERE user1_id = 1) OR user_id IN (SELECT user1_id
    FROM Friendship
    WHERE user2_id = 1 ))
    AND page_id NOT IN (SELECT page_id
    FROM Likes l2
    WHERE user_id = 1)
GROUP BY page_id
-- use IN () and NOT () from the Likes table directly, do not join t3 and the Likes table.
 
 --1907. Count Salary Categories, https://leetcode.com/problems/count-salary-categories/
    /* a way to keep 0 (there is no way to keep the 0 row when using group by*/
SELECT
    'Low Salary' AS category,
    SUM(
        CASE
            WHEN income < 20000 THEN 1
            ELSE 0
        END
    ) AS accounts_count
FROM
    Accounts
UNION
SELECT
    'Average Salary' AS category,
    SUM(
        CASE
            WHEN income >= 20000
            AND income <= 50000 THEN 1
            ELSE 0
        END
    ) AS accounts_count
FROM
    Accounts
UNION
SELECT
    'High Salary' AS category,
    SUM(
        CASE
            WHEN income > 50000 THEN 1
            ELSE 0
        END
    ) AS accounts_count
FROM
    Accounts 
-- 1393. Capital Gain/Loss, https://leetcode.com/problems/capital-gainloss/
    /*
     practicing groupby with rollup
     */
SELECT
    stock_name,
    capital_gain_loss
FROM
    (
        SELECT
            stock_name,
            operation,
            sum(price) AS capital_gain_loss
        FROM
            (
                SELECT
                    stock_name,
                    operation,
                    CASE
                        WHEN operation = 'Buy' THEN price * (-1)
                        WHEN operation = 'Sell' THEN price
                    END AS price
                FROM
                    Stocks
            ) t1
        GROUP BY
            ROLLUP (stock_name, operation)
    ) t2
WHERE
    operation IS NULL
    AND stock_name IS NOT NULL 
-- 1308. Running Total for Different Genders, https://leetcode.com/problems/running-total-for-different-genders/
    /* 1. use unbounded preceding not 1 row; 2,the difference between PARTITION BY and ORDER BY */
SELECT
    gender,
    DAY,
    SUM(score_points) OVER (
        PARTITION BY gender
        ORDER BY
            DAY ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
    ) AS total
FROM
    Scores
ORDER BY
    gender,
    DAY 
--1398. Customers Who Bought Products A and B but Not C，https://leetcode.com/problems/customers-who-bought-products-a-and-b-but-not-c/
SELECT
    customer_id,
    customer_name
FROM
    Customers c
WHERE
    EXISTS (
        SELECT
            customer_id
        FROM
            Orders o
        WHERE
            c.customer_id = o.customer_id
            AND o.product_name = 'A'
    )
    AND EXISTS (
        SELECT
            customer_id
        FROM
            Orders o
        WHERE
            c.customer_id = o.customer_id
            AND o.product_name = 'B'
    )
    AND NOT EXISTS (
        SELECT
            customer_id
        FROM
            Orders o
        WHERE
            c.customer_id = o.customer_id
            AND o.product_name = 'C'
    )
ORDER BY
    customer_id -- 1445. Apples & Oranges， https://leetcode.com/problems/apples-oranges/
SELECT
    sale_date,
    apple - orange AS diff
FROM
    (
        SELECT
            sale_date,
            [apples] AS apple,
            [oranges] AS orange
        FROM
            (
                SELECT
                    *
                FROM
                    Sales
            ) AS source_table PIVOT (
                SUM(sold_num) FOR fruit IN ([apples], [oranges])
            ) AS pvt_table
    ) t
ORDER BY
    sale_date -- 2084. Drop Type 1 Orders for Customers With Type 0 Orders, https://leetcode.com/problems/drop-type-1-orders-for-customers-with-type-0-orders/
    /* This works but really slow */
SELECT
    order_id,
    customer_id,
    order_type
FROM
    Orders o
WHERE
    order_type = 0
UNION
SELECT
    order_id,
    customer_id,
    order_type
FROM
    (
        SELECT
            *
        FROM
            (
                SELECT
                    *
                FROM
                    Orders o
                WHERE
                    order_type = 1
            ) AS t
        WHERE
            NOT EXISTS (
                SELECT
                    *
                FROM
                    Orders o
                WHERE
                    o.order_type = 0
                    AND t.customer_id = o.customer_id
            )
    ) AS t1
    /* NOT IN a lot faster */
SELECT
    order_id,
    customer_id,
    order_type
FROM
    Orders o
WHERE
    order_type = 0
UNION
SELECT
    order_id,
    customer_id,
    order_type
FROM
    (
        SELECT
            *
        FROM
            (
                SELECT
                    *
                FROM
                    Orders o
                WHERE
                    order_type = 1
            ) AS t
        WHERE
            t.customer_id NOT IN (
                SELECT
                    customer_id
                FROM
                    Orders o
                WHERE
                    o.order_type = 0
            )
    ) AS t2 -- 1783. Grand Slam Titles, https://leetcode.com/problems/grand-slam-titles/\
    /* sql unpivot function. union should also do the trick */
SELECT
    p.player_id,
    p.player_name,
    count(tournament) AS grand_slams_count
FROM
    Players p
    JOIN (
        SELECT
            year,
            Wimbledon,
            Fr_open,
            US_open,
            Au_open
        FROM
            Championships
    ) p UNPIVOT (
        champion FOR tournament IN (Wimbledon, Fr_open, US_open, Au_open)
    ) AS unpvt ON p.player_id = unpvt.champion
GROUP BY
    p.player_id,
    p.player_name -- 1699. Number of Calls Between Two Persons, https://leetcode.com/problems/number-of-calls-between-two-persons/
SELECT
    person1,
    person2,
    COUNT(1) AS call_count,
    SUM(duration) AS total_duration
FROM
    (
        SELECT
            c1.from_id AS person1,
            c1.to_id AS person2,
            c1.duration AS duration
        FROM
            Calls c1
        UNION
        ALL (
            SELECT
                c2.to_id,
                c2.from_id,
                c2.duration
            FROM
                Calls c2
        )
    ) AS t
GROUP BY
    person1,
    person2
HAVING
    person1 < person2 -- 2066. Account Balance,  https://leetcode.com/problems/account-balance/
SELECT
    account_id,
    DAY,
    SUM(
        IIF("type" = 'Withdraw', amount * -1, amount)
    ) OVER (
        PARTITION BY account_id
        ORDER BY
            DAY
    ) AS balance
FROM
    Transactions;

-- 1341. Movie Rating, https://leetcode.com/problems/movie-rating/
/* Feels a bit wordy */
WITH t1 AS (
    SELECT
        COUNT(movie_id) AS rating_count,
        user_id
    FROM
        MovieRating
    GROUP BY
        user_id
),
t2 AS (
    SELECT
        u.name AS name,
        t1.rating_count,
        ROW_NUMBER() OVER (
            ORDER BY
                name
        ) AS rn
    FROM
        Users u
        JOIN t1 ON u.user_id = t1.user_id
    WHERE
        t1.rating_count = (
            SELECT
                max(rating_count)
            FROM
                t1
        )
),
t3 AS (
    SELECT
        name AS results
    FROM
        t2
    WHERE
        rn = 1
),
t4 AS (
    SELECT
        movie_id,
        AVG(rating * 1.0) AS avg_rating,
        MONTH(created_at) AS MONTH
    FROM
        MovieRating
    GROUP BY
        movie_id,
        MONTH(created_at)
    HAVING
        MONTH(created_at) = 2
),
t5 AS (
    SELECT
        m.title,
        ROW_NUMBER() OVER (
            ORDER BY
                t4.avg_rating DESC,
                m.title
        ) AS rn
    FROM
        Movies m
        JOIN t4 ON m.movie_id = t4.movie_id
),
t6 AS (
    SELECT
        t5.title AS results
    FROM
        t5
    WHERE
        t5.rn = 1
)
SELECT
    *
FROM
    t3
UNION
ALL
SELECT
    *
FROM
    t6;

--1355. Activity Participants,  https://leetcode.com/problems/activity-participants/
SELECT
    t3.name AS activity
FROM
    (
        SELECT
            count(f.name) AS participants_count,
            a.name AS name
        FROM
            Activities a
            JOIN Friends f ON a.name = f.activity
        GROUP BY
            a.name
    ) t3
WHERE
    t3.participants_count < (
        SELECT
            MAX(participants_count) AS max_count
        FROM
            (
                SELECT
                    count(f.name) AS participants_count,
                    a.name AS name
                FROM
                    Activities a
                    JOIN Friends f ON a.name = f.activity
                GROUP BY
                    a.name
            ) t1
    )
    AND t3.participants_count > (
        SELECT
            MIN(participants_count) AS MIN_count
        FROM
            (
                SELECT
                    count(f.name) AS participants_count,
                    a.name AS name
                FROM
                    Activities a
                    JOIN Friends f ON a.name = f.activity
                GROUP BY
                    a.name
            ) t1
    );

/* window function, simpler and faster */
WITH t1 AS (
    SELECT
        activity,
        COUNT(name) OVER (PARTITION BY activity) AS cnt
    FROM
        Friends
),
min_max AS (
    SELECT
        MIN(cnt) AS min_cnt,
        MAX(cnt) AS max_cnt
    FROM
        t1
)
SELECT
    DISTINCT activity
FROM
    t1
    JOIN min_max ON cnt > min_cnt
    AND cnt < max_cnt;

-- 1364. Number of Trusted Contacts of a Customer, https://leetcode.com/problems/number-of-trusted-contacts-of-a-customer/
WITH t1 AS (
    -- step 1: get a list of customer that made the purchase
    SELECT
        i.invoice_id,
        c1.customer_name,
        i.price
    FROM
        Invoices i
        LEFT JOIN Customers c1 ON i.user_id = c1.customer_id
),
contacts_cnt AS (
    -- get the total number of contacts for each customer
    SELECT
        c1.customer_name,
        COUNT(c2.user_id) AS cnt
    FROM
        Customers c1
        JOIN Contacts c2 ON c1.customer_id = c2.user_id
    GROUP BY
        c1.customer_name
),
trusted_contacts_cnt AS (
    -- connect the customer and contact table again, but this time, trusted contacts are appear in the customer table as well.
    SELECT
        c1.customer_name,
        count(*) AS cnt
    FROM
        Customers c1
        JOIN Contacts c2 ON c1.customer_id = c2.user_id
    WHERE
        c2.contact_name IN (
            SELECT
                customer_name
            FROM
                Customers
        ) -- this is the key!!!
    GROUP BY
        c1.customer_name
)
SELECT
    t1.invoice_id AS invoice_id,
    t1.customer_name AS customer_name,
    t1.price AS price,
    ISNULL(contacts_cnt.cnt, 0) AS contacts_cnt,
    ISNULL(trusted_contacts_cnt.cnt, 0) AS trusted_contacts_cnt
FROM
    t1 -- combine everything together with left join, is ISNULL to remove any null values.
    LEFT JOIN contacts_cnt ON t1.customer_name = contacts_cnt.customer_name
    LEFT JOIN trusted_contacts_cnt ON contacts_cnt.customer_name = trusted_contacts_cnt.customer_name
ORDER BY
    t1.invoice_id ASC --1440. Evaluate Boolean Expression, https://leetcode.com/problems/evaluate-boolean-expression/
    WITH left_operand AS (
        SELECT
            v.value AS left_value,
            e.left_operand,
            e.operator,
            e.right_operand
        FROM
            VARIABLES v
            JOIN Expressions e ON v.name = e.left_operand
    ),
    right_operand AS (
        SELECT
            l.left_value,
            l.left_operand,
            l.operator,
            v.value AS right_value,
            l.right_operand
        FROM
            VARIABLES v
            JOIN left_operand l ON v.name = l.right_operand
    )
SELECT
    left_operand AS left_operand,
    operator AS operator,
    right_operand AS right_operand,
    CASE
        WHEN operator = '>' THEN IIF(left_value > right_value, 'true', 'false')
        WHEN operator = '<' THEN IIF(left_value < right_value, 'true', 'false')
        WHEN operator = '=' THEN IIF(left_value = right_value, 'true', 'false')
    END AS value
FROM
    right_operand
    /* faster without using cte */
SELECT
    e.left_operand,
    e.operator,
    e.right_operand,
    CASE
        e.operator
        WHEN '>' THEN IIF(v_left.value > v_right.value, 'true', 'false')
        WHEN '<' THEN IIF(v_left.value < v_right.value, 'true', 'false')
        WHEN '=' THEN IIF(v_left.value = v_right.value, 'true', 'false')
    END AS value
FROM
    Expressions e
    JOIN VARIABLES AS v_left ON e.left_operand = v_left.name
    JOIN VARIABLES AS v_right ON e.right_operand = v_right.name --1468. Calculate Salaries, https://leetcode.com/problems/calculate-salaries/
    /* condition 
     CASE 
     WHEN @salary < 1000 THEN @salary 
     WHEN @salary >= 1000 AND @salary <= 10000 THEN ROUND(@salary * 0.24, 0)
     WHEN @salary > 10000 THEN ROUND(@salary * 0.49, 0)
     
     */
SELECT
    s.company_id,
    s.employee_id,
    s.employee_name,
    ROUND(s.salary - s.salary * t.tax_rate, 0) AS salary
FROM
    Salaries s
    JOIN (
        SELECT
            company_id,
            CASE
                WHEN MAX(salary) < 1000 THEN 0
                WHEN MAX(salary) >= 1000
                AND MAX(salary) <= 10000 THEN 0.24
                ELSE 0.49
            END AS tax_rate
        FROM
            Salaries
        GROUP BY
            company_id
    ) t ON s.company_id = t.company_id;

--1532. The Most Recent Three Orders,  https://leetcode.com/problems/the-most-recent-three-orders/
SELECT
    c.name AS customer_name,
    c.customer_id,
    t2.order_id,
    t2.order_date
FROM
    Customers c
    CROSS APPLY (
        SELECT
            *
        FROM
            (
                SELECT
                    order_id,
                    order_date,
                    customer_id,
                    ROW_NUMBER() OVER (
                        PARTITION BY customer_id
                        ORDER BY
                            order_date DESC
                    ) AS rn
                FROM
                    Orders
            ) t1
        WHERE
            t1.rn <= 3
            AND t1.customer_id = c.customer_id
    ) t2
ORDER BY
    c.name ASC,
    c.customer_id ASC,
    t2.order_date DESC;

--  1549. The Most Recent Orders for Each Product, https://leetcode.com/problems/the-most-recent-orders-for-each-product/
SELECT
    product_name,
    product_id,
    order_id,
    order_date
FROM
    (
        SELECT
            p.product_name,
            o.order_id,
            o.order_date,
            o.product_id,
            DENSE_RANK() OVER (
                PARTITION BY o.product_id
                ORDER BY
                    o.order_date DESC
            ) AS rnk
        FROM
            Orders o
            JOIN Products p ON o.product_id = p.product_id
    ) t
WHERE
    rnk = 1
ORDER BY
    product_name ASC,
    product_id ASC,
    order_id ASC -- 1555. Bank Account Summary, https://leetcode.com/problems/bank-account-summary/
    /* duplicates be careful */
    WITH earning AS (
        SELECT
            u.user_id,
            SUM(t.amount) AS earning
        FROM
            Users u
            JOIN Transactions t ON u.user_id = t.paid_to
        GROUP BY
            u.user_id
    ),
    debt AS (
        SELECT
            u.user_id,
            SUM(t.amount) * -1 AS debt
        FROM
            Users u
            JOIN Transactions t ON u.user_id = t.paid_by
        GROUP BY
            u.user_id
    ),
    cdt AS (
        SELECT
            u.user_id,
            u.user_name,
            u.credit + ISNULL(e.earning, 0) + ISNULL(d.debt, 0) AS credit
        FROM
            Users u
            LEFT JOIN earning e ON u.user_id = e.user_id
            LEFT JOIN debt d ON u.user_id = d.user_id
    )
SELECT
    *,
    IIF(credit < 0, 'Yes', 'No') AS credit_limit_breached
FROM
    cdt;

-- 1596. The Most Frequently Ordered Products for Each Customer,https://leetcode.com/problems/the-most-frequently-ordered-products-for-each-customer/
/* slow */
WITH product_count AS (
    SELECT
        c.customer_id,
        count(product_id) AS product_count,
        o.product_id
    FROM
        Customers c
        JOIN Orders o ON c.customer_id = o.customer_id
    GROUP BY
        c.customer_id,
        o.product_id
),
max_product_count AS (
    SELECT
        customer_id,
        MAX(product_count) AS cnt
    FROM
        product_count
    GROUP BY
        customer_id
),
count_rank AS (
    SELECT
        p.customer_id,
        p.product_id
    FROM
        product_count p
        JOIN max_product_count m ON p.customer_id = m.customer_id
    WHERE
        p.product_count = m.cnt
)
SELECT
    c.*,
    p.product_name
FROM
    count_rank c
    JOIN Products p ON c.product_id = p.product_id;

/* window function , why not row number? */
SELECT
    t.customer_id,
    p.product_id,
    p.product_name
FROM
    Products p
    JOIN (
        SELECT
            customer_id,
            product_id,
            rank() OVER (
                PARTITION BY customer_id
                ORDER BY
                    COUNT(product_id) DESC
            ) AS rnk
        FROM
            Orders o
        GROUP BY
            customer_id,
            product_id
    ) t ON p.product_id = t.product_id
WHERE
    t.rnk = 1


-- 1613. Find the Missing IDs https://leetcode.com/problems/find-the-missing-ids/

/* Recursive query to create a range from 1 - 100 !! */
WITH maxid AS (
    SELECT MAX(customer_id) as max_id
    FROM Customers
), t1 AS (
    SELECT 1 AS ids
    UNION ALL
    SELECT 1 + ids 
    FROM t1 
    WHERE ids < (SELECT max_id FROM maxid)
)

SELECT t1.ids
FROM t1
WHERE NOT EXISTS (SELECT customer_id FROM Customers c where c.customer_id = t1.ids) 


-- 1715. Count Apples and Oranges, https://leetcode.com/problems/count-apples-and-oranges/

SELECT SUM(b.apple_count + ISNULL(c.apple_count, 0)) AS apple_count, SUM(b.orange_count + ISNULL(c.orange_count, 0)) AS orange_count
FROM Boxes b
LEFT JOIN Chests c
ON b.chest_id = c.chest_id


-- 1747. Leetflex Banned Accounts, https://leetcode.com/problems/leetflex-banned-accounts/

SELECT DISTINCT l1.account_id
FROM LogInfo l1
JOIN LogInfo l2 
ON l1.account_id = l2.account_id
WHERE l1.ip_address != l2.ip_address AND l1.logout BETWEEN l2.login AND l2.logout


-- 1831. Maximum Transaction Each Day, https://leetcode.com/problems/maximum-transaction-each-day/


SELECT DISTINCT t.transaction_id  
FROM Transactions t
JOIN 
    (SELECT transaction_id , MAX(amount) OVER (PARTITION BY CAST(day AS DATE)) AS max_amount, CAST(day AS DATE) AS new_day
    FROM Transactions) t1
ON CAST(t.day AS DATE) = t1.new_day 
WHERE t.amount = t1.max_amount
ORDER BY t.transaction_id  

/* follow up, using window function instead*/

SELECT t.transaction_id
FROM 
    (SELECT transaction_id , CAST(day AS DATE) AS new_date, DENSE_RANK() OVER (PARTITION BY CAST(day AS DATE) ORDER BY amount DESC) AS rnk
    FROM Transactions) t
WHERE t.rnk = 1
ORDER BY t.transaction_id

-- 2041. Accepted Candidates From the Interviews, https://leetcode.com/problems/accepted-candidates-from-the-interviews/

SELECT t.candidate_id 
FROM Rounds r
JOIN (
        SELECT candidate_id, interview_id
        FROM candidates
        WHERE years_of_exp >= 2) t
ON r.interview_id = t.interview_id
GROUP BY t.candidate_id
HAVING SUM(r.score) > 15

-- 2051. The Category of Each Member in the Store, https://leetcode.com/problems/the-category-of-each-member-in-the-store/
WITH t1 AS (
SELECT m.member_id AS m_id ,SUM(IIF(v.visit_id IS NULL,0,1)) AS visits, SUM(IIF(p.visit_id IS NULL,0,1)) AS purchases
FROM Members m
LEFT JOIN Visits v
ON m.member_id = v.member_id
LEFT JOIN Purchases p
ON v.visit_id = p.visit_id
GROUP BY m.member_id, v.member_id
), t2 AS (
SELECT t1.m_id, CASE 
                WHEN t1.visits = 0 THEN 'Bronze'
                WHEN t1.visits <> 0 AND 100 * t1.purchases / t1.visits < 50 THEN 'Silver'
                WHEN t1.visits <> 0 AND 100 * t1.purchases / t1.visits >= 50 AND 100 * t1.purchases / t1.visits < 80 THEN 'Gold'
                WHEN t1.visits <> 0 AND 100 * t1.purchases / t1.visits >= 50 AND 100 * t1.purchases / t1.visits >= 80 THEN 'Diamond'
            ELSE 'Null'
            END AS category
FROM t1
)

SELECT m.member_id, m.name, t2.category
FROM Members m
JOIN t2
ON t2.m_id = m.member_id;


-- 1843. Suspicious Bank Accounts, https://leetcode.com/problems/suspicious-bank-accounts/
WITH t1 AS (
    SELECT SUM(amount) AS monthly_income, account_id, month(day) AS month
    FROM Transactions t
    WHERE type = 'Creditor'
    GROUP BY account_id, month(day)
), t2 AS (

    SELECT t1.account_id, t1.month, CASE 
                                        WHEN a.max_income >= t1.monthly_income  THEN 1
                                        ELSE 0
                                    END AS diff
    FROM t1
    JOIN Accounts a
    ON t1.account_id = a.account_id

)
SELECT DISTINCT t2.account_id
FROM t2
JOIN t2 t3 
ON t3.month = t2.month + 1
WHERE t3.diff = 0 AND t2.diff = 0 AND t2.account_id = t3.account_id

/* rewrite */
WITH t1 AS (
    SELECT
        t.account_id,
        MONTH(t.day) AS 'month',
        SUM(
            CASE
                WHEN TYPE = 'Creditor' THEN t.amount
                ELSE 0
            END
        ) AS monthly_income
    FROM
        Transactions t
        JOIN Accounts a ON t.account_id = a.account_id
    GROUP BY
        t.account_id,
        MONTH(t.day),
        a.max_income
    HAVING
        SUM(
            CASE
                WHEN TYPE = 'Creditor' THEN t.amount
                ELSE 0
            END
        ) > a.max_income
)
SELECT
    DISTINCT t1.account_id
FROM
    t1
    JOIN t1 AS t2 ON t1.month = t2.month + 1
    AND t1.account_id = t2.account_id

-- 1949. Strong Friendship, https://leetcode.com/problems/strong-friendship/

/* In order to solve this, we need to 

1st change the relationship direction from bidirectional to single direction (using UNION);
2nd find my friends' friends (1st join)

3rd, most importantly, find my friends' friends who is myself. (2nd join)

*/
WITH f AS (
    SELECT user1_id AS myself, user2_id friends
    FROM Friendship f1
    UNION ALL
    SELECT user2_id AS myself, user1_id friends
    FROM Friendship f2
)

SELECT a.user1_id, a.user2_id, COUNT(b.friends) AS common_friend
FROM Friendship a
JOIN f b
ON a.user2_id = b.myself
JOIN f c
ON b.friends = c.myself
AND a.user1_id = c.friends
GROUP BY a.user1_id, a.user2_id
HAVING COUNT(b.friends) >= 3

-- 1951. All the Pairs With the Maximum Number of Common Followers, https://leetcode.com/problems/all-the-pairs-with-the-maximum-number-of-common-followers/

WITH relation AS (
    SELECT a.user_id AS user1_id, b.user_id AS user2_id, COUNT(*) AS common_friends
    FROM Relations a
    JOIN Relations b
    ON a.follower_id = b.follower_id AND a.user_id < b.user_id
    GROUP BY a.user_id, b.user_id
)

SELECT user1_id, user2_id
FROM relation
WHERE common_friends = (SELECT MAX(common_friends) FROM relation)

-- 1988. Find Cutoff Score for Each School, https://leetcode.com/problems/find-cutoff-score-for-each-school/

SELECT s.school_id, ISNULL(MIN(e.score), -1) AS score
FROM Schools s
    LEFT JOIN Exam e
    ON s.capacity >= e.student_count
GROUP BY s.school_id
ORDER BY s.school_id

-- 2112. The Airport With the Most Traffic, https://leetcode.com/problems/the-airport-with-the-most-traffic/
SELECT
    airport_id
FROM
    (
        SELECT
            departure_airport AS airport_id,
            flights_count
        FROM
            Flights f1
        UNION ALL
        SELECT
            arrival_airport AS airport_id,
            flights_count
        FROM
            Flights f2
    ) t2
GROUP BY airport_id
HAVING
    SUM(flights_count) = (
        SELECT
            MAX(total_counts)
        FROM
            (
                SELECT
                    SUM(flights_count) AS total_counts
                FROM
                    (
                        SELECT
                            departure_airport AS airport_id,
                            flights_count
                        FROM
                            Flights f1
                        UNION ALL
                        SELECT
                            arrival_airport AS airport_id,
                            flights_count
                        FROM
                            Flights f2
                    ) t
                GROUP BY
                    airport_id
            ) t1
    )

-- 1875. Group Employees of the Same Salary, https://leetcode.com/problems/group-employees-of-the-same-salary/

SELECT
    e.employee_id,
    e.name,
    e.salary,
    DENSE_RANK() OVER (
        ORDER BY
            salary
    ) AS team_id
FROM
    Employees e
WHERE
    EXISTS (
        SELECT
            1
        FROM
            (
                SELECT
                    DISTINCT salary,
                    rn
                FROM
                    (
                        SELECT
                            salary,
                            ROW_NUMBER() OVER (
                                PARTITION BY salary
                                ORDER BY
                                    salary
                            ) AS rn
                        FROM
                            Employees
                    ) t
                WHERE
                    rn > 1
            ) t1
        WHERE
            t1.salary = e.salary
    )
ORDER BY
    DENSE_RANK() OVER (
        ORDER BY
            salary
    ),
    e.employee_id


-- 1990. Count the Number of Experiments, https://leetcode.com/problems/count-the-number-of-experiments/

/* VALUES(),(),() */

WITH experiment AS (
    SELECT * 
    FROM (VALUES ('Reading'), ('Sports'), ('Programming'))
    AS t1(experiment_name )
), plat AS (
    SELECT *
    FROM (VALUES('IOS'), ('Android'), ('Web'))
    AS t2(platform)
), merged AS (
    SELECT platform, experiment_name  FROM plat, experiment
)
 
SELECT m.platform, m.experiment_name , ISNULL(COUNT(e.experiment_id),0) AS num_experiments 
FROM merged m
LEFT JOIN Experiments e
ON m.platform = e.platform AND m.experiment_name  = e.experiment_name 
GROUP BY m.platform, m.experiment_name;


/* Usin Union */

WITH plat AS (

    SELECT 'IOS' AS platform
    UNION 
    SELECT 'Android'
    UNION
    SELECT 'Web'
), experiment AS (
    SELECT 'Programming' AS experiment_name
    UNION 
    SELECT 'Sports'
    UNION
    SELECT 'Reading'
), merged AS (
    SELECT platform, experiment_name FROM plat, experiment
)

SELECT m.platform, m.experiment_name, ISNULL(COUNT(e.experiment_id),0) AS num_experiments 
FROM merged m
LEFT JOIN Experiments e
ON m.platform = e.platform AND m.experiment_name  = e.experiment_name 
GROUP BY m.platform, m.experiment_name;


-- 2159. Order Two Columns Independently, https://leetcode.com/problems/order-two-columns-independently/
SELECT * 
FROM 
    (
        (SELECT first_col, ROW_NUMBER() OVER (ORDER BY first_col ASC) AS rn FROM Data) t1
        JOIN
        (SELECT second_col, ROW_NUMBER() OVER (ORDER BY second_col DESC) AS rn FROM Data) t2
        ON t1.rn = t2.rn
    ) 

