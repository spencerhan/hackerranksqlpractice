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

DECLARE @table_a TABLE (s_d Date,rn int); -- two placeholder temp table to make code more readable
DECLARE @table_b TABLE (e_d Date,rn int);
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

-- join Start Date and End Date pair together use their corresponding row number
SELECT a.s_d, b.e_d
FROM @table_a AS a
    JOIN @table_b AS b
    ON a.rn = b.rn
ORDER BY DATEDIFF(day, a.s_d, b.e_d) asc, a.s_d; -- first sort by project duration then by project start date. 

-- key take on, NOT IN can be used to find whether a date falls into a period and ROW_NUMBER can be used to find corresponding pairs.