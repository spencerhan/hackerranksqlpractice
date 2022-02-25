-- New Companies solution, https://www.hackerrank.com/challenges/the-company/problem?isFullScreen=true, Advanced Select
-- main logic: join
select c.company_code, c.founder, count(distinct l.lead_manager_code), count(distinct s.senior_manager_code), count(distinct m.manager_code), count(distinct e.employee_code)
from Company as c
    left join Lead_Manager as l
    on c.company_code = l.company_code
    left join Senior_Manager as s
    on l.lead_manager_code = s.lead_manager_code
    left join Manager as m
    on s.senior_manager_code = m.senior_manager_code
    left join Employee as e
    on m.manager_code = e.manager_code
group by c.founder, c.company_code
order by c.company_code asc;

-- SQL Project Planning, https://www.hackerrank.com/challenges/sql-projects/problem?isFullScreen=true&h_r=next-challenge&h_v=zen, Advanced Join
-- main logic: window function
DECLARE @table_a TABLE (s_d Date,
    rn int);
-- two placeholder temp table to make code more readable
DECLARE @table_b TABLE (e_d Date,
    rn int);
-- Start Date that are not in the End Date list should define a range of 'true' Start Date (otherwise they will fall in the middle of project)
-- the window function is used to keep a track of row numbers.
-- then we can use it to pair matching corresponding End Date
INSERT INTO @table_a
SELECT Start_Date , ROW_NUMBER() OVER (ORDER BY Start_Date) AS RN
FROM Projects
WHERE Start_Date NOT IN (SELECT End_Date
FROM Projects);
-- testing: SELECT * FROM @table_a;

-- Same idea here, End Date that are not in the Start Date list should define a range of 'true' End Date (otherwise they will fall in the middle of project)
SELECT End_Date , ROW_NUMBER() OVER (ORDER BY End_Date) AS RN
FROM Projects
WHERE End_Date NOT IN (SELECT Start_Date
FROM Projects);
-- debug SELECT * FROM @table_b;

-- join Start Date and End Date pair together use their corresponding row number.
-- key take on, NOT IN can be used to find whether a date falls into a period and ROW_NUMBER can be used to find corresponding pairs.
SELECT a.s_d, b.e_d
FROM @table_a AS a
    JOIN @table_b AS b
    ON a.rn = b.rn
ORDER BY DATEDIFF(day, a.s_d, b.e_d) asc, a.s_d;
-- first sort by project duration then by project start date. 


SELECT t1.Start_Date, t2.End_Date
FROM
    (SELECT Start_Date, ROW_NUMBER() OVER (ORDER BY Start_Date ASC) as rn_start
    FROM Projects
    WHERE Start_Date 
    NOT IN (SELECT End_Date FROM Projects)) AS t1
JOIN 
    (SELECT End_Date, ROW_NUMBER() OVER (ORDER BY End_Date ASC) as rn_end
    FROM projects
    WHERE End_Date 
    NOT IN (SELECT Start_Date From Projects)) AS t2 
ON t1.rn_start = t2.rn_end
ORDER BY DATEDIFF(day,t1.Start_date, t2.End_Date) ASC, t1.Start_Date;



-- Weather stations, Aggregation, https://www.hackerrank.com/challenges/weather-observation-station-20/problem?isFullScreen=true, Advanced Aggregation
/* main logic: Percentile function with window function

unlike oracle which has a built in median() function. sql server has not built in function to calculate median. 
the logic to calculate median in sql server is either via calculating the mid between min and max value
or in this case, I used the percentile method. 
there are three percentile functions in sql server: PERCENTILE_CONT(), PERCENTILE_DISC() and PERCENT_RANK()
all three can be used to find the median, here I have used the PERCENT_RANK to achieve that.  */
SELECT cast(round(a.LAT_N,4,1) as decimal (9,4))
-- rounding in sql server leaves trailing zeros, I have to cast it to remove these zeros.
FROM STATION as a
    INNER JOIN
    (SELECT ID, PERCENT_RANK() OVER (ORDER BY LAT_N) as median, LAT_N
    FROM STATION) as b
    ON a.ID = b.ID
WHERE b.median = 0.5;

-- The Pads, https://www.hackerrank.com/challenges/the-pads/problem?isFullScreen=true, Advanced Select
/* Main logic: Case statement. */
SELECT CONCAT(Name, "(", LEFT(Occupation, 1), ")")
FROM OCCUPATIONS
ORDER BY Name ASC;
/* No need to use loop. 
DECLARE @counter INT;
SET @counter = (SELECT COUNT(DISTINCT Occupation) FROM OCCUPATIONS);
WHILE @counter > 0
BEGIN */
SELECT CONCAT("There are a total of ", 
                  COUNT(Occupation),
                  " ",
                  LOWER(Occupation), 
                  CASE
                     WHEN COUNT(Occupation) >= 2 THEN "s." 
                     ELSE "."
                  END
                 )
FROM OCCUPATIONS
GROUP BY Occupation
ORDER BY COUNT(Occupation), Occupation ASC;
--SET @counter -= 1;
--END;

/* Occupations, https://www.hackerrank.com/challenges/occupations/problem?isFullScreen=true, Advanced Select
main logic: pivoting with window function (use row number )

in this challenge I used sql server's built-in pivoting function. 
however, an alternative solution is to use CASE statement to manually aggregate and format the result. */

DECLARE @pivot_columns varchar(MAX);
SET @pivot_columns = '';
SELECT @pivot_columns = CONCAT("[", @pivot_columns, t.occ, "],[")
FROM (SELECT DISTINCT Occupation as occ
    FROM OCCUPATIONS) AS t
SET @pivot_columns = LEFT(@pivot_columns, LEN(@pivot_columns) - 1)
-- DEBUGGING and get order of occupations, print(@pivot_columns);

SELECT [Doctor], [Professor], [Singer], [Actor]
-- after pivot, we only has for columns
FROM
    (SELECT Name, Occupation, ROW_NUMBER() OVER (PARTITION BY Occupation ORDER BY Name) as rn
    /* row number used to group Name corresponding to the occupation type. I order the name based on the requirement. This return a table with Name, Occupation, Row number in sequences, for example if there are 4 doctors, then 1,2,3,4, if there are 3 Actors, then 1,2,3 */
    FROM OCCUPATIONS)
AS t
PIVOT ( /* sql server pivting function needs an aggregation for each new column groups. in this case the max function is used to retrive the name, min is fine too. however, count will obvisouly return the occurence rather than the actual name. */ 
    MAX(Name) FOR Occupation IN ([Doctor],[Professor],[Singer],[Actor])
) AS pt;


-- BST Tree, https://www.hackerrank.com/challenges/binary-search-tree-1/problem?isFullScreen=true, Advanced Select
-- main logic: Case statement

SELECT N, Case 
            WHEN P IS null THEN 'Root'
            WHEN P IS NOT null AND N IN (SELECT P
        FROM BST) THEN 'Inner'
            ELSE 'Leaf'
          END
FROM BST
ORDER BY N;

-- Manhattan Distance, https://www.hackerrank.com/challenges/weather-observation-station-18/problem?isFullScreen=true, Advanced aggregation
/* main logic: I accidentally used LAG() calculated the Manhattan Distance amount each individual point. (which I think is harder than the exercise itself.) */

/* SELECT CAST(ROUND(ABS(LAG(LAT_N) OVER (ORDER BY ID) - LAT_N) + ABS(LAG(LONG_W) OVER (ORDER BY ID) - LONG_W), 4) AS DECIMAL(9,4))
FROM STATION; */
SELECT CAST(ROUND(ABS(MIN(LAT_N)-MAX(LAT_N))+ABS(MIN(LONG_W)-MAX(LONG_W)), 4) AS DECIMAL(9,4))
FROM STATION;


-- Euclidean Distance. https://www.hackerrank.com/challenges/weather-observation-station-19/problem?isFullScreen=true, Advanced Aggregation.
/* main logic, similar to previous Manhattan Distance problem; 
SQRT() for square root, SQUARE() for square in sql server */

SELECT CAST(ROUND(SQRT((SQUARE(MAX(LAT_N) - MIN(LAT_N))) + SQUARE(MAX(LONG_W) - MIN(LONG_W))) ,4) AS DECIMAL(9,4))
FROM STATION;


-- The report, https://www.hackerrank.com/challenges/the-report/problem?isFullScreen=true, Basic Join
/* main logic:  JOIN with BETWEEN instead of normally "=" otherwise FLOOR(s.Marks / 10) * 10 =  g.Min_Marks also a valid logic test.
   IIF() in sql server.
   the ORDER BY is quite confusing.
 */

SELECT IIF(g.Grade < 8, NULL, s.Name) as N,
    g.Grade as G,
    s.Marks as M
FROM Students as s
    INNER JOIN Grades as g
    ON s.Marks BETWEEN g.Min_Mark AND g.Max_Mark
ORDER BY g.grade DESC, s.name ASC, s.Marks ASC;

-- The Top Competititors, https://www.hackerrank.com/challenges/full-score/problem?isFullScreen=true, Basic Join
/* main logic: 1. starting with FROM and JOIN, then work the way to the ouside. 2. use HAVING to do filtering on aggregated results. */
SELECT h.hacker_id, h.name
FROM Hackers AS h
    JOIN Submissions AS s ON h.hacker_id = s.hacker_id
    JOIN Challenges AS c ON s.challenge_id = c.challenge_id
    JOIN Difficulty AS d ON c.difficulty_level = d.difficulty_level
WHERE s.score = d.score
GROUP BY h.hacker_id, h.name
HAVING COUNT(h.hacker_id) > 1
-- some people suggested used COUNT(1) > 1 instead of count([column]) works the same. 
ORDER BY COUNT(h.hacker_id) desc, h.hacker_id asc;

-- Ollivander's Inventory, https://www.hackerrank.com/challenges/harry-potter-and-wands/problem?isFullScreen=true, Basic Join
/* main logic: First use a subquery with window function to keep tracking of the minimum cost of wand in each (power and age) group 
               Then use the outter query to filter the result based the coins needed equal the least cost. 
    Another way to achieve this is to use ROW_NUMBER with ORDER BY DESC cluase, then filter the outter query by ROW_NUMBER() = 1
*/

SELECT id, age, coins_needed, power
FROM (SELECT w.id AS id, wp.age AS age, w.coins_needed AS coins_needed, MIN(w.coins_needed) OVER (PARTITION BY w.power, wp.age) AS min_coins, w.power as power
    FROM Wands AS w INNER JOIN Wands_Property AS wp  ON w.code=wp.code
    WHERE wp.is_evil=0) AS t
WHERE min_coins=coins_needed
ORDER BY power DESC, age DESC;

-- Challenges, https://www.hackerrank.com/challenges/challenges/problem?isFullScreen=true, basic join
/* main logic:  There are three parts to this problem: 
1. normal condition: order by total number of challenges desc;
2. if more than one students, sort by hacker_id desc;
3. exclude student if more than one students created the same challenge and smaller than the maximum number of chanllenges created. 

The first and second parts can be easily resolved by using ORDER BY with two preceding conditions. 

However the third part have two caveats: 1. if more than one students created the same challenges; or 2. only one student created certain number of challenges. 

Since aggregation involved in this problem (getting count uses aggregation). We need to use Having with OR to deal with the third part (two caveats). 

 */

SELECT h.hacker_id, h.name, COUNT(c.challenge_id)
FROM Hackers as h
    JOIN Challenges as c
    ON h.hacker_id = c.hacker_id
GROUP BY h.hacker_id, h.name
HAVING COUNT(challenge_id) = (SELECT MAX(max_cnt)
                                FROM
                                    (SELECT COUNT(challenge_id) AS max_cnt, hacker_id
                                    FROM challenges
                                    GROUP BY (hacker_id)) AS t1) -- here we use sub queries to find out what's the maximum number of challenges created by each students, and then finding out whether the aggregated amount of challenges equal to that maximum. 
       OR COUNT(c.hacker_id) IN (SELECT chg_cnt
                                 FROM
                                    (SELECT COUNT(hacker_id) AS chg_cnt
                                    FROM Challenges
                                    GROUP BY hacker_id) AS t2
                                GROUP BY chg_cnt
                                HAVING count(chg_cnt) = 1
                                )  -- here we solve the second caveat by checking whether a student is in a list of students that create a unique amount of challenges
ORDER BY COUNT(c.challenge_id) DESC, h.hacker_id; -- this order solves the first and second requirement. 


-- Contest Leaderboard, https://www.hackerrank.com/challenges/contest-leaderboard/problem?h_r=next-challenge&h_v=zen&isFullScreen=true, Basic Join 

/* Main logic: 1. We need first exclude all students that sored 0 in the sub query, 
               2. then find out the max scored obtained by each student in each challenges (among their multiple submissions in each challenge with MAX aggregation;
               3. lastly use the SUM aggregation to calculate the total. 
               * using windown function with ROW number based on score order for each student and challenge combination should also do the trick.
*/
DECLARE @t1 TABLE (hacker_id int, score int);
DECLARE @t2 TABLE (hacker_id int, max_score int, challenge_id int);
SELECT t2.hacker_id, h.name, SUM(t2.max_score) as score
FROM Hackers as h
JOIN
    (SELECT s.hacker_id, MAX(score) as max_score, s.challenge_id
    FROM Submissions s
    JOIN
        (SELECT hacker_id
        FROM Submissions
        GROUP BY hacker_id
        HAVING SUM(score) > 0
        ) AS t1 -- excluding any students who score 0.
    ON s.hacker_id = t1.hacker_id
    GROUP BY s.hacker_id, s.challenge_id -- getting max score for each challenge over multiple submissions 
    ) AS t2 
ON t2.hacker_id = h.hacker_id
GROUP BY t2.hacker_id, h.name
ORDER BY score DESC, t2.hacker_id ASC;

-- Placements, https://www.hackerrank.com/challenges/placements/problem?h_r=next-challenge&h_v=zen&isFullScreen=true, Advanced join
/* Nested join comparison steps outlined below */

---Step 1: Friend salary
SELECT s.id AS ID, s.Name AS name, p.Salary AS fSalary
FROM Students s
JOIN Friend f
ON s.id = f.id
JOIN Packages p 
ON f.Friend_ID = p.ID
;

---Step2: OWN Salary
SELECT s.id AS ID, s.Name AS name, p.Salary AS sSalary
FROM Students s
JOIN Packages p
ON s.ID = p.ID;

---Together 
SELECT t1.name
FROM
    (SELECT s.id AS ID, s.Name AS name, p.Salary AS sSalary
    FROM Students s
        JOIN Packages p
        ON s.ID = p.ID) AS t1
    JOIN (SELECT s.id AS ID, s.Name AS name, p.Salary AS fSalary
    FROM Students s
        JOIN Friends f
        ON s.id = f.id
        JOIN Packages p
        ON f.Friend_ID = p.ID) AS t2
    ON t1.name = t2.name AND t1.sSalary < t2.fSalary
ORDER BY t2.fSalary;


-- Symmetric Pairs, https://www.hackerrank.com/challenges/symmetric-pairs/problem?h_r=next-challenge&h_v=zen, Advanced Join
 /* Main logic: Self join, removing duplicate is the key */

SELECT t1.X, t1.Y
FROM Functions t1
JOIN Functions t2
ON t1.X = t2.Y AND t1.Y = t2.X -- it contains duplicate also, the matching condition, we need to remove duplicates in later process. 
GROUP BY t1.X, t1.Y
HAVING COUNT(t1.X) > 1 OR t1.X < t1.Y 
-- After group by we will have duplicated records, for example (3,24) appears once is not a symmetric, (3,24) appears twice will be a symmetric pari; 
-- secondly (3,24) is the same as (24,3), therefore we only need to keep one pair.
ORDER BY t1.X ASC; 

-- Average Population, https://www.hackerrank.com/challenges/average-population/problem?isFullScreen=true&h_r=next-challenge&h_v=zen, Aggregation
/* main logic: FLOOR, CEILING, ROUND */
SELECT FLOOR(AVG(POPULATION))
FROM CITY;

-- Interviews, https://www.hackerrank.com/challenges/interviews/problem?isFullScreen=true, Advanced Join
/* main logic, there are 1 to many relationships in here 
https://medium.com/@smohajer85/sql-challenge-interviews-a50d205d4f3a, this guy also mentioned using CTE. So I reengineered with CTEs based on his brilliant design,
*/
-- contest_id, hacker_id. name, SUM(total_submissions), SUM(total_accepted_submissions), SUM(total_views), SUM(total_unique_views)

SELECT Contests.contest_id, hacker_id, name, SUM(totsub), SUM(totaccsub), SUM(totview), SUM(totuniquview)
FROM Contests
JOIN Colleges
ON Contests.contest_id = Colleges.contest_id
JOIN Challenges
ON Colleges.college_id  = Challenges.college_id  
LEFT JOIN
    (SELECT Challenges.challenge_id, SUM(total_submissions) AS totsub, SUM(total_accepted_submissions) AS totaccsub
    FROM Submission_Stats
    JOIN Challenges
        ON Submission_Stats.challenge_id  = Challenges.challenge_id  
    GROUP BY Challenges.challenge_id) AS t1
ON Challenges.challenge_id = t1.challenge_id
LEFT JOIN
    (SELECT Challenges.challenge_id, SUM(total_views) AS totview, SUM(total_unique_views) AS totuniquview
    FROM View_Stats
    JOIN Challenges
        ON View_Stats.challenge_id = Challenges.challenge_id
    GROUP BY Challenges.challenge_id) AS t2
ON Challenges.challenge_id = t2.challenge_id
GROUP BY Contests.contest_id, name, hacker_id
HAVING SUM(totsub) + SUM(totaccsub) + SUM(totview) + SUM(totuniquview) != 0
ORDER BY Contests.contest_id;


WITH 
t1 AS (SELECT Contests.contest_id, hacker_id, name, Colleges.college_id
            FROM Contests
            JOIN Colleges
            ON Contests.contest_id = Colleges.contest_id
), 
t2 AS (SELECT t1.contest_id, hacker_id, name, Challenges.challenge_id
       FROM t1
       JOIN Challenges
       ON t1.college_id = Challenges.college_id
), 
t3 AS (SELECT Challenges.challenge_id, SUM(total_views) AS totview, SUM(total_unique_views) AS totuniquview 
       FROM Challenges
       JOIN View_Stats
       ON Challenges.challenge_id = View_Stats.challenge_id
       GROUP BY Challenges.challenge_id
),
t4 AS (SELECT Challenges.challenge_id, SUM(total_submissions) AS totsub, SUM(total_accepted_submissions) AS totaccsub 
       FROM Challenges
       JOIN Submission_Stats
       ON Challenges.challenge_id = Submission_Stats.challenge_id
       GROUP BY Challenges.challenge_id
),
t5 AS (SELECT t2.contest_id, hacker_id, name, t2.challenge_id, totvie, totuniquview 
       FROM t2
       LEFT JOIN t3
       ON t2.challenge_id = t3.challenge_id

),
t6 AS (
       SELECT t5.contest_id, hacker_id, name, t5.challenge_id, totsub, totaccsub, totview, totuniquview
       FROM t5
       LEFT JOIN t4
       ON t5.challenge_id = t4.challenge_id
),  -- select * from t6 (left join unmatched will be null in view and submission stats columns), we need to set nulls to 0
t7 AS (
    SELECT contest_id, hacker_id, name, COALESCE(totsub,0) AS totsub, COALESCE(totaccsub,0) AS totaccsub, COALESCE(totview,0) AS totview, COALESCE(totuniquview,0) AS totuniquview
    FROM t6
), 
t8 AS (
    SELECT *, total = SUM(totsub, totaccsub, totview, totuniquview)
    FROM t7
)
SELECT contest_id, hacker_id, name, SUM(totsub), SUM(totaccsub), SUM(totview), SUM(totuniquview)
FROM t8
WHERE total != 0
GROUP BY contest_id, name, hacker_id
ORDER BY contest_id;


-- The Blunder, https://www.hackerrank.com/challenges/the-blunder/problem, Aggregation
/* main logic: multiple cast */
SELECT CAST(CEILING(AVG(CAST(Salary AS FLOAT)) - AVG(CAST(REPLACE(CAST(Salary AS VARCHAR),'0','') AS FLOAT))) AS INT)
FROM EMPLOYEES;

-- Top Earners, https://www.hackerrank.com/challenges/earnings-of-employees/problem, Aggregation
SELECT TOP 1 salary*months, COUNT(*) 
FROM Employee 
GROUP BY (salary * months) 
ORDER BY (salary * months) DESC;
-- window funtion version.
SELECT topearning, count(name)
FROM (SELECT salary * months as topearning, name, dense_rank() OVER (ORDER BY salary * months DESC) as rank
FROM Employee
) t1
WHERE t1.rank = 1
GROUP BY topearning; 

-- Weather Observation Station 2, https://www.hackerrank.com/challenges/weather-observation-station-2/problem?isFullScreen=true, Aggregation
SELECT CAST(ROUND(SUM(LAT_N),2) AS DECIMAL(9,2)), CAST(ROUND(SUM(LONG_W),2) AS DECIMAL(9,2))
FROM STATION;



-- Weather Observation Station 13, https://www.hackerrank.com/challenges/weather-observation-station-13/problem, Aggregation
SELECT CAST(SUM(LAT_N) AS DECIMAL(18,4))
FROM STATION
WHERE LAT_N > 38.7880 AND LAT_N < 137.2345;


-- Second Highest Salary, https://leetcode.com/problems/second-highest-salary
/* main logic, window function to get rank */
IF (SELECT COUNT(DISTINCT rank) FROM (SELECT dense_rank() OVER (ORDER BY Salary desc) AS rank FROM Employee) t) < 2 
    SELECT TOP 1 null as SecondHighestSalary FROM Employee -- top 1 to get rid of duplicates
ELSE
SELECT TOP 1 e.Salary as SecondHighestSalary -- top 1 to get rid of duplicates
FROM Employee e
JOIN
(SELECT Salary, dense_rank() OVER (ORDER BY salary desc) AS rank
FROM Employee) t
ON e.Salary = t.Salary
WHERE t.rank = 2;

-- should be a better way of doing this. faster than 46% queries. 
DECLARE @count int;
SET @count = (SELECT COUNT(salary) FROM Employee);
IF @count < 2
    SELECT 'null' as SecondHighestSalary FROM Employee
ELSE 
    SELECT DISTINCT salary as SecondHighestSalary
    FROM Employee
    ORDER BY Salary DESC
    OFFSET 1 ROWS
    FETCH NEXT 1 ROW ONLY;

-- better solution using offset

-- Nth Highest Salary, https://leetcode.com/problems/nth-highest-salary/
/* main logic, window function to get rank */
CREATE FUNCTION getNthHighestSalary(@N INT) RETURNS INT AS
BEGIN
    RETURN (
        /* Write your T-SQL query statement below. */
       SELECT TOP 1
        Salary AS getNthHighestSalary -- top 1 to remove duplicates.
       FROM
            (SELECT Salary, dense_rank() OVER (ORDER BY Salary desc) AS srank
            FROM Employee
            ) t
       WHERE srank = @N
    );
END

-- no need to improve, faster than 84% queries. 

-- Rank scores, https://leetcode.com/problems/rank-scores/submissions/

/* main logic: continuous ranking, no gap, needs to use dense_rank. */
-- this is faster than 40% queries, dense_rank is more costly. 
SELECT score, DENSE_RANK() OVER (ORDER BY score DESC) as rank
FROM Scores;

-- 1. Interesting comparison, when use group by, this obvisouly will collapse the groups, which is simply gives the rank within the dataset.
SELECT b.score, count(distinct a.Score) as rank
FROM Scores b
JOIN Scores a
ON b.score<=a.score
group by b.score
order by 1 desc;

-- 2. Alternative way is to use join within the columns to avoid aggregate entire ouput with group by clause. 
-- this is fater than 87% queries. 
SELECT 
    b.Score, 
	(SELECT COUNT(DISTINCT a.Score) -- this is actually the rank.
    FROM Scores a WHERE b.Score <= a.Score) as 'rank'
FROM Scores b ORDER BY 'rank'


-- Game Play Analysis III, https://leetcode.com/problems/game-play-analysis-iii/
/* main logic: accumulative sum (not rolling sum, otherwise use LAG() */

SELECT player_id, event_date,
SUM(games_played) OVER (PARTITION BY player_id ORDER BY event_date) as games_played_so_far
FROM Activity
;
-- solution 1: window function with SUM() faster than 85% queries

SELECT b.player_id, b.event_date,
    (SELECT SUM(games_played)
    FROM Activity a
    WHERE a.Player_id = b.Player_id AND b.event_date >= a.event_date) -- be careful with the comparison sign
    AS games_played_so_far
FROM Activity b
ORDER BY b.player_id;
-- solution 2: join query, faster than 93% queries


-- Consecutive Number, https://leetcode.com/problems/consecutive-numbers/submissions/  

SELECT DISTINCT t1.ConsecutiveNums -- distinct is needed to remove duplicates
FROM
    (SELECT
        (CASE 
    WHEN num = LEAD(num, 1, 0) OVER (ORDER BY id DESC) AND num = LEAD(num,2,0) OVER (ORDER BY id DESC) THEN num -- using two lead() to check the next and the third consecutive number.
    END) AS ConsecutiveNums
    FROM Logs) t1
WHERE  t1.ConsecutiveNums  IS NOT NULL;

-- faster than 54% of code. 

SELECT DISTINCT t1.num as ConsecutiveNums
FROM (SELECT num, LEAD(num,1,0) OVER (ORDER BY id DESC) as next_num, LEAD(num,2,0) OVER (ORDER BY id DESC) as next_next_num
      FROM Logs
     ) t1
WHERE t1.num = t1.next_num AND t1.num = t1.next_next_num;

-- using where faster than 77.12%

-- the follwing two queries works the same, notice the difference in joining condition and where clause. 
SELECT DISTINCT t1.num as ConsecutiveNums
FROM Logs t1
JOIN Logs t2
ON t1.id = t2.id - 1 -- join on the next consective number. 
JOIN Logs t3
ON t1.id = t3.id - 2 -- join on the next next consective number  (this is where the consective from)
WHERE t1.num = t2.num AND t1.num = t3.num;
-- this only faster than 47.43% queries, I guess there are two full joins here.


SELECT DISTINCT t1.num as ConsecutiveNums
FROM Logs t1
JOIN Logs t2
ON t1.id = t2.id - 1 
JOIN Logs t3
ON t2.id = t3.id - 1 
WHERE t1.num = t2.num AND t1.num = t3.num;
-- faster than 95.20% queries,  the second join is built on the first join where lots of duplicated records has been filtered out. 

-- Combine Two Tables, https://leetcode.com/problems/combine-two-tables/
/* left join */

SELECT p.firstName, p.lastName, a.city, a.state
FROM PERSON p
LEFT JOIN ADDRESS a
ON p.personId = a.personId


-- Department Highest Salary, https://leetcode.com/problems/department-highest-salary/
/* Highest, top? rank? max? */
SELECT d.name as Department, t.name as Employee, t.salary as Salary
FROM
(SELECT * , rank() OVER (PARTITION BY departmentId ORDER BY salary DESC) ranking
FROM Employee) t
JOIN Department d
ON t.departmentId = d.id
WHERE t.ranking = 1;

-- faster than 36.44% queries. 

WITH t1 AS (SELECT d.id as departmentId, d.name as Department, max(salary) as max_salary
FROM Employee e1
JOIN Department d
ON d.id = e1.departmentId
GROUP BY d.id, d.name) -- the key things is to aggregate on the joined table column instead of own column
SELECT t1.Department, e2.name as Employee, t1.max_salary as Salary
FROM t1
JOIN Employee e2
ON e2.departmentId = t1.departmentId AND e2.salary = t1.max_salary;

-- CTE implementation, faster than 68.55% solution. 
-- there are might be a way to use TOP 1 with order to get rank, but I have not find a way to do this. 


-- Game Play Analysis IV, https://leetcode.com/problems/game-play-analysis-iv/
/* main logic: DATEADD(day/month/year, ,) to get the second login time. 
alternatives DATEDIFF(day/month/year, ),
(WINDOW function might work in this case as well) */


WITH c1 AS (
SELECT COUNT(DISTINCT a1.player_id) as count
FROM Activity a1
JOIN ACtivity a2
ON a1.player_id = a2.player_id AND a1.event_date = DATEADD(day, 1, a2.event_date)
) 
SELECT ROUND(c1.count * 1.00/(SELECT COUNT(DISTINCT player_id) FROM Activity),2) AS fraction
FROM c1;

-- this is an wrong solution, it does not take into account that the consecutive login has to occur after the first login. 

WITH login_after_first_time AS (
    SELECT player_id, DATEADD(day, 1, min(event_date)) as consecutive_login
    FROM Activity 
    GROUP BY player_id
),
player_count AS (
    SELECT COUNT(DISTINCT(a1.player_id)) AS count
    FROM Activity a1
    JOIN login_after_first_time
    ON login_after_first_time.player_id = a1.player_id AND login_after_first_time.consecutive_login = a1.event_date
)

SELECT CAST(ROUND((player_count.count * 1.00/(SELECT COUNT(DISTINCT(a2.player_id)) FROM Activity a2)),2) AS DECIMAL(9,2)) AS fraction
FROM player_count

-- faster than 28.15% queries.

SELECT
    ROUND(CAST(SUM(CASE WHEN datediff(day,first_login,event_date)=1 THEN 1 ELSE 0 END) AS DECIMAL(9,2))/count(DISTINCT player_id),2) AS fraction
FROM
    (    
    SELECT
        player_id,
        event_date,
        first_value(event_date) OVER (PARTITION BY player_id ORDER BY event_date) AS first_login
    FROM activity
) t
-- window function version, faster than 65.96% result

--Managers with at Least 5 direct report. https://leetcode.com/problems/managers-with-at-least-5-direct-reports/
SELECT e1.name
FROM
(SELECT name, id
FROM Employee) AS e1
LEFT JOIN Employee e2
ON e1.id = e2.managerId
GROUP BY e1.name
HAVING count(e2.managerId) >= 5
-- simple self join. faster than 75.83% result.

-- Winning Candidate, https://leetcode.com/problems/winning-candidate/
/* main logic: number of votes exists as repeated occurence in Vote table, for example candiditeId 2 occured twice, means B got 2 votes
    I'm using row number to get the number of occurences
*/


SELECT c.name
FROM Candidate c
    JOIN Vote v
    ON c.id = v.candidateId
GROUP BY c.name
HAVING count(v.id) = (SELECT max(rn)
                    FROM
                        (SELECT row_number() OVER (PARTITION BY candidateId ORDER BY id) as rn
                        FROM Vote) t)

-- faster than 43.56% query. 


-- Get Highest Answer Rate Question, https://leetcode.com/problems/get-highest-answer-rate-question/

WITH t1 AS (
    SELECT count(question_id) AS count, question_id
    FROM SurveyLog
    WHERE answer_id IS NOT null AND action = 'answer'
    GROUP BY question_id)
SELECT question_id as survey_log 
FROM SurveyLog
WHERE answer_id IS NOT null AND action = 'answer'
GROUP BY question_id
HAVING count(question_id)  = (SELECT MAX(t1.count) as max_answered FROM t1);

-- CTE solution, faster 13.6% of queries,. Purhaps should use window function with ROW_NUMBER


-- Employees Earning More Than Their Managers, https://leetcode.com/problems/employees-earning-more-than-their-managers/
/* Easy self join */

SELECT e1.name as Employee
FROM Employee e1
JOIN Employee e2
ON e1.managerId = e2.id AND e1.salary > e2.salary;


-- Count Student Number in Departments, https://leetcode.com/problems/count-student-number-in-departments/

/* count or max(row_number) */


SELECT DISTINCT d.dept_name, (CASE
                      WHEN t2.student_count IS Null Then 0
                      ELSE t2.student_count
                   END) AS student_number
FROM Department d
LEFT JOIN
    (SELECT MAX(rn) OVER (PARTITION BY t1.dept_id) AS student_count, t1.dept_id
    FROM
        (SELECT ROW_NUMBER() OVER (PARTITION BY dept_id ORDER BY student_id) as rn, dept_id
        FROM Student) AS t1) AS t2
ON d.dept_id = t2.dept_id
ORDER BY student_number desc, d.dept_name

-- REMERBER!!! use distinct to get rid duplicates from left join. faster than 52% of queries. count should do the trick with window function too.


--Investments in 2016, https://leetcode.com/problems/investments-in-2016/
WITH t AS(
    SELECT
        tiv_2016
        , COUNT(*) OVER (PARTITION BY tiv_2015) AS count_15
        , COUNT(*) OVER (PARTITION BY lat, lon) AS  count_loc
    FROM Insurance
)
SELECT
    CAST(SUM(tiv_2016) AS DECIMAL(10,2)) AS tiv_2016
FROM t
WHERE count_15 >= 2 AND count_loc = 1;

-- faster than 58% of query



--Friend Requests II: Who Has the Most Friends, https://leetcode.com/problems/friend-requests-ii-who-has-the-most-friends/

/* self left join with CTE, do not use Window function otherwise it will leave duplicates */

WITH t1 AS (
            SELECT requester_id, count(*) as rqst_cnt
            FROM RequestAccepted
            GROUP BY requester_id
),
t2 AS (
       SELECT accepter_id, count(*) as accpt_cnt
       FROM RequestAccepted
       GROUP BY accepter_id 
)
SELECT TOP 1 t1.requester_id, isnull(t1.rqst_cnt,0) + isnull(t2.accpt_cnt,0) as num
FROM t1
LEFT JOIN t2
ON t1.requester_id = t2.accepter_id
ORDER BY isnull(t1.rqst_cnt,0) + isnull(t2.accpt_cnt,0) desc

-- I only worked out the first logic where 'Left join' is needed. 
-- However, we need isnull to remove null from left join. and use "top 1" and "order by" to get the result. 


-- Tree Node, https://leetcode.com/problems/tree-node/
/* case statement with 'In clause'*/

SELECT t1.id, (CASE
               WHEN t1.p_id is null then 'Root'
               WHEN t1.id in (SELECT t2.p_id FROM Tree AS t2)  then 'Inner'
               ELSE 'Leaf'
           END) AS type
FROM Tree AS t1

-- this is similar to the one I have done in hackers rank.


-- 612. Shortest Distance in a Plane, https://leetcode.com/problems/shortest-distance-in-a-plane/
/* main logic: cross join */

SELECT CAST(ROUND(MIN(dis),2) AS DECIMAL(9,2)) as shortest
FROM 
(SELECT SQRT(SQUARE(p2.x - p1.x) + SQUARE(p2.y - p1.y)) as dis
FROM Point2D as p1
CROSS JOIN Point2D as p2) as t
WHERE dis > 0 -- this removes self calculating;
-- I first thought using cursor turns out it's an over complicated thinking. Cross join is way more efficient. 

-- 614. Second Degree Follower SELECT f1.followee as follower, COUNT(DISTINCT f1.follower) as num
/* main logic: self join */
SELECT f1.followee as follower, COUNT(DISTINCT f1.follower) as num
FROM Follow as f1
JOIN Follow as f2
ON f1.followee = f2.follower
GROUP BY f1.followee
ORDER BY f1.followee


-- 626. Exchange Seats, https://leetcode.com/problems/exchange-seats/
/* main logic: do not think iteration or if-else , use LEAD and LAG for swap, ISNULL to deal with the first row */

SELECT s.id AS id
,IIF(s.id % 2 = 1, 
    ISNULL(LEAD(student) OVER (ORDER BY id ASC), s.student), LAG(student) OVER (ORDER BY id ASC)
    ) AS student
FROM Seat s



-- 1045. Customers Who Bought All Products, https://leetcode.com/problems/customers-who-bought-all-products/

/* main logic: simple sub query */

/* 
The following window function will not work as customer may bought multiple products, and you CANNOT use distinct in WINDOW function.

SELECT DISTINCT t1.customer_id FROM
    (SELECT t.customer_id AS customer_id, COUNT(t.product_key) OVER (PARTITION BY t.customer_id) as product_count
    FROM Customer t
    JOIN Product p
    ON t.product_key = p.product_key) AS t1
WHERE t1.product_count = (SELECT COUNT(DISTINCT product_key) FROM Product) */


SELECT c.customer_id 
From Customer c
JOIN Product p
ON c.product_key = p.product_key
GROUP BY c.customer_id
HAVING COUNT(DISTINCT c.product_key) = (SELECT COUNT(DISTINCT product_key) FROM Product)

-- 1070. Product Sales Analysis III, https://leetcode.com/problems/product-sales-analysis-iii/
/* main logic: simple RANK() window function */
SELECT product_id, year as first_year, quantity, price
FROM
    (SELECT product_id, year, quantity, price, RANK() OVER (PARTITION BY product_id ORDER BY year asc) as rk 
    FROM Sales) t
WHERE rk = 1


-- 1010, Pairs of Songs With Total Durations Divisible by 60, https://leetcode.com/problems/pairs-of-songs-with-total-durations-divisible-by-60/

WITH t1 AS (
    SELECT p.project_id, p.employee_id, DENSE_RANK() OVER (PARTITION BY p.project_id ORDER BY e.experience_years desc) as rnk
    FROM Project p
    CROSS APPLY Employee e
    WHERE p.employee_id = e.employee_id
)
SELECT project_id, employee_id
FROM t1
WHERE rnk = 1


-- 1098. Unpopular Books, https://leetcode.com/problems/unpopular-books/

/* main logic: the question itself is really confusing. 
    1. Reverse thinking, to get a list of books that does not fit search criteria.
    2. use dateadd, do not use straight forward date comparison.
*/

SELECT book_id, name
FROM books
WHERE book_id NOT IN (
                        SELECT book_id
                        FROM Orders
                        GROUP BY book_id
                        HAVING sum(CASE WHEN dispatch_date >= DATEADD(YEAR, -1, '2019-06-23' ) THEN quantity else 0 end) >= 10
                    UNION (
                             SELECT book_id
                             FROM Books
                             WHERE available_from > DATEADD(MONTH, -1, '2019-06-23' )))  


SELECT user_id, activity,  ROW_NUMBER() OVER (PARTITION BY user_id, activity_date) as rnk, activity_date
FROM Traffic
WHERE activity_date >= DATEADD(day, -90, '2019-06-30') AND activity = 'login'

-- 1164. Product Price at a Given Date, https://leetcode.com/problems/product-price-at-a-given-date/
/* main logic: 
step 1: get a list of product that has changed price before the given date 
step 2: use row number to order the step 1 subset based on the date column.
step 3: select row number = 1 to get the most recent price
step 4: get a list of products regardless whether they have changed price or not
step 5: left join or right join with a case statement to default the price to 10 dollers for products that have not changed price before the given date
*/
WITH t1 AS (
    SELECT product_id, new_price as price
    FROM
        (SELECT product_id, new_price, ROW_NUMBER() OVER (partition BY product_id ORDER BY change_date desc) as rownum
        FROM Products
        WHERE change_date <= '2019-08-16') t
    WHERE rownum = 1
), t2 AS (
        SELECT DISTINCT product_id
        FROM Products
)
SELECT t2.product_id, (CASE
                       WHEN t1.price IS NULL THEN 10
                       ELSE t1.price
                      END) as price
FROM t1
RIGHT JOIN t2
ON t1.product_id = t2.product_id