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
    FROM Wands AS w WITH (NOLOCK) INNER JOIN Wands_Property AS wp WITH (NOLOCK) ON w.code=wp.code
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