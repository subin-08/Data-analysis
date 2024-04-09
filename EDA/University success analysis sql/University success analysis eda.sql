use university

select * from university.dbo.country;

select * from university.dbo.ranking_criteria;

select * from university.dbo.ranking_system;


select * from university.dbo.university;

select * from university.dbo.university_ranking_year;


select * from university.dbo.university_year;



select count(distinct university_id) from university.dbo.university_ranking_year;

/*
1 Is there a correlation between a country's GDP and the number of universities?
2 How has the number of universities changed over the years in each country?
3 Is there a relationship between a country's population and the number of universities?
4 Are there any common criteria used by different ranking systems?
5 What is the trend in university rankings over the years according to each system?
6 How does the choice of ranking system affect a university's international student enrollment?
7 Are there any criteria that have different weights in different ranking systems?
8 How have the weights of ranking criteria changed over time?
9 Is there a relationship between a university's score and the student-staff ratio?
10 How does the number of female students differ among universities?
11 What is the distribution of universities across different countries?
12 How has the ranking of universities changed over the years?
13 What is the trend in the percentage of female students over time?
14 How has the ranking score of universities evolved over the years?
15 Is there a relationship between a university's ranking score and the number of students over time?
*/

--1 Is there a correlation between a country's GDP and the number of universities?

--2 How has the number of universities changed over the years in each country?



with cte as (
  select c.country_name,
         year,
         COUNT(university_id) as University_count
  from university.dbo.university_year a
  inner join university.dbo.university b on a.university_id = b.id
  inner join university.dbo.country c on b.country_id = c.id
  group by year, c.country_name
)
select
  cte.country_name,
  cte.year,
  cte.University_count,
  case
    when LAG(cte.University_count) over (partition by cte.country_name order by cte.year asc) is null then null
    else cte.University_count - LAG(cte.University_count) over (partition by cte.country_name order by year asc)
  end as Change_in_number_of_university
from cte;





--3 Is there a relationship between a country's population and the number of universities?


--4 Are there any common criteria used by different ranking systems?



SELECT
  rs.id AS ranking_system_id,
  rc.id AS ranking_criteria_id,
  SUM(ury.score) AS total_score
FROM university.dbo.ranking_system rs
JOIN university.dbo.ranking_criteria rc ON rs.id = rc.ranking_system_id
JOIN university.dbo.university_ranking_year ury ON rc.id = ury.ranking_criteria_id
GROUP BY rs.id, rc.id
ORDER BY ranking_system_id, total_score;





--5 What is the trend in university rankings over the years according to each system? excel - 5,5.1

with cte as (
  select university_id,
         year,
         sum(score) as total_score
  from university.dbo.university_ranking_year
  group by university_id,
          year
)
select cte.university_id,
       cte.year,
       cte.total_score,
       case
         when lag(cte.total_score) over (partition by cte.university_id order by cte.year) is null then null
         else cte.total_score - lag(cte.total_score) over (partition by cte.university_id order by cte.year)
       end as change_in_score
from cte
order by cte.university_id, cte.year;



--6 How does the choice of ranking system affect a university's international student enrollment?


--SELECT
--  b.university_id,
--  b.ranking_criteria_id,
--  COUNT(pct_international_students) AS international_students
--FROM university.dbo.university_year a
--JOIN university.dbo.university_ranking_year b ON a.university_id = b.university_id
--GROUP BY b.university_id, b.ranking_criteria_id
--ORDER BY b.university_id;




--select *,(num_students*pct_international_students/100) as number_of_int_students from university.dbo.university_year

with cte as (
  select uy.university_id,
         uyr.year,
         sum(uy.num_students * uy.pct_international_students / 100) as number_of_int_students
  from university.dbo.university_year as uy
  join university.dbo.university_ranking_year as uyr on uy.university_id = uyr.university_id
  group by uy.university_id, uyr.year
)
select
  cte.university_id,
  cte.number_of_int_students,
  cte.year,
  rs.id as ranking_system_id
from cte
join university.dbo.university_ranking_year as uyr on cte.university_id = uyr.university_id
join university.dbo.ranking_criteria rc on uyr.university_id = rc.id
join university.dbo.ranking_system rs on rc.ranking_system_id = rs.id;









--8 How have the weights of ranking criteria changed over time?



with cte as (
  select rc.id as criteria_id,
         rc.criteria_name,
         ury.year as year,
         sum(ury.score) as total_score
  from university.dbo.university_ranking_year ury
  join university.dbo.ranking_criteria as rc on rc.id = ury.ranking_criteria_id
  group by rc.id, rc.criteria_name, ury.year
)
select
  criteria_id,
  criteria_name,
  year,
  total_score,
  case
    when lag(total_score) over (partition by criteria_id order by year) is null then null
    else total_score - lag(total_score) over (partition by criteria_id order by year)
  end as change_in_score,
  case
    when lag(total_score) over (partition by criteria_id order by year) is null then null
    else round((total_score - lag(total_score) over (partition by criteria_id order by year)) / 
              lag(total_score) over (partition by criteria_id order by year) * 100, 2)
  end as change_in_percentage
from cte
order by criteria_id, year;



--9 Is there a relationship between a university's score and the student-staff ratio? (doubt)


select university_id, year, sum(score) as university_score from university.dbo.university_ranking_year
where university_id = 3
group by university_id, year
order by year;


select * from university.dbo.university_year
where university_id = 3
order by year;


--10 How does the number of female students differ among universities?

SELECT
  university_id,
  ROUND(SUM(num_students * pct_female_students) / 100, 0) AS total_female_students
FROM university.dbo.university_year
GROUP BY university_id
ORDER BY university_id;





--11 What is the distribution of universities across different countries?

SELECT
  a.country_name,
  COUNT(b.id) AS no_university
FROM university.dbo.country a
INNER JOIN university.dbo.university b ON a.id = b.country_id
GROUP BY a.country_name
ORDER BY no_university DESC;




--12 How has the ranking of universities changed over the years?



SELECT
  university_id,
  scores,
  YEAR,
  rank() OVER (PARTITION BY university_id ORDER BY scores DESC) AS ranks
FROM (
  SELECT DISTINCT
    university_id,
    YEAR,
    SUM(score) AS scores
  FROM university.dbo.university_ranking_year
  GROUP BY university_id, YEAR
) AS a;



--13 What is the trend in the percentage of female students over time?




with cte as (
  select year,
         round(SUM(num_students * pct_female_students) / 100, 0) as total_female_students
  from university.dbo.university_year
  group by year
)
select
  year,
  total_female_students,
  case
    when lag(total_female_students) over (order by year) is null then null
    else round((total_female_students - lag(total_female_students) over (order by year)) / 
                lag(total_female_students) over (order by year) * 100, 2)
  end as change_in_percentage
from cte
order by year;




--14 How has the ranking score of universities evolved over the years?


with cte as (
  select university_id,
         year,
         SUM(score) as total_score
  from university.dbo.university_ranking_year
  group by university_id,
          year
)
select
  cte.university_id,
  cte.year,
  cte.total_score,
  case
    when lag(cte.total_score) over (partition by cte.university_id order by cte.year) is null then null
    else round((cte.total_score - lag(cte.total_score) over (partition by cte.university_id order by cte.year)) / 
              lag(cte.total_score) over (partition by cte.university_id order by cte.year) * 100, 2)
  end as change_in_score
from cte
order by cte.university_id, cte.year;


--15 Is there a relationship between a university's ranking score and the number of students over time?

SELECT DISTINCT
  a.university_id,
  a.score,
  b.num_students,
  a.year
FROM university.dbo.university_ranking_year a
INNER JOIN university.dbo.university_year b ON a.university_id = b.university_id
ORDER BY a.score DESC;



