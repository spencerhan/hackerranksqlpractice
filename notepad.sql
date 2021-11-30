-- New Companies solution, https://www.hackerrank.com/challenges/the-company/problem?isFullScreen=true, Advanced Select
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
from Projects);
-- testing: SELECT * FROM @table_a;

-- Same idea here, End Date that are not in the Start Date list should define a range of 'true' End Date (otherwise they will fall in the middle of project)
SELECT End_Date , ROW_NUMBER() OVER (ORDER BY End_Date) AS RN
FROM Projects
WHERE End_Date NOT IN (SELECT Start_Date
from Projects);
-- debug SELECT * FROM @table_b;

-- join Start Date and End Date pair together use their corresponding row number.
-- key take on, NOT IN can be used to find whether a date falls into a period and ROW_NUMBER can be used to find corresponding pairs.
SELECT a.s_d, b.e_d
FROM @table_a AS a
    JOIN @table_b AS b
    ON a.rn = b.rn
ORDER BY DATEDIFF(day, a.s_d, b.e_d) asc, a.s_d;
-- first sort by project duration then by project start date. 



-- Weather stations, Aggregation, https://www.hackerrank.com/challenges/weather-observation-station-20/problem?isFullScreen=true, Advanced Aggregation

-- unlike oracle which has a built in median() function. sql server has not built in function to calculate median. 
-- the logic to calculate median in sql server is either via calculating the mid between min and max value
-- or in this case, I used the percentile method. 
-- there are three percentile functions in sql server: PERCENTILE_CONT(), PERCENTILE_DISC() and PERCENT_RANK()
-- all three can be used to find the median, here I have used the PERCENT_RANK to achieve that. 
SELECT cast(round(a.LAT_N,4,1) as decimal (9,4))
-- rounding in sql server leaves trailing zeros, I have to cast it to remove these zeros.
FROM STATION as a
    INNER JOIN
    (SELECT ID, PERCENT_RANK() OVER (ORDER BY LAT_N) as median, LAT_N
    FROM STATION) as b
    ON a.ID = b.ID
WHERE b.median = 0.5;

-- The Pads, https://www.hackerrank.com/challenges/the-pads/problem?isFullScreen=true, Advanced Select

SELECT CONCAT(Name, "(", LEFT(Occupation, 1), ")")
FROM OCCUPATIONS
ORDER BY Name ASC;
-- No need to use loop. 
--DECLARE @counter INT;
--SET @counter = (SELECT COUNT(DISTINCT Occupation) FROM OCCUPATIONS);
--WHILE @counter > 0
--BEGIN
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

-- Occupations, https://www.hackerrank.com/challenges/occupations/problem?isFullScreen=true, Advanced Select
-- in this challenge I used sql server's built-in pivoting function. 
-- however, an alternative solution is to use CASE statement to manually aggregate and format the result.
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
    -- row number used to group Name corresponding to the occupation type. I order the name based on the requirement. This return a table with Name, Occupation, Row number in sequences, for example if there are 4 doctors, then 1,2,3,4, if there are 3 Actors, then 1,2,3
    FROM OCCUPATIONS)
AS t
PIVOT ( -- sql server pivting function needs an aggregation for each new column groups. in this case the max function is used to retrive the name, min is fine too. however, count will obvisouly return the occurence rather than the actual name. 
    MAX(Name) FOR Occupation IN ([Doctor],[Professor],[Singer],[Actor])
) AS pt;
