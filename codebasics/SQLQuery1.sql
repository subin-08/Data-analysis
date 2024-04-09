Use ipl;

select * from dbo.dim_match_summary

select * from dbo.dim_players

select * from dbo.fact_bating_summary

select * from dbo.fact_bowling_summary


--1 Top 10 batsmen based on past 3 years total runs scored

select * from(
select batsmanName,SUM(runs) as total_runs, DENSE_RANK() over(order by sum(runs) desc) as rnk from dbo.fact_bating_summary
group by batsmanName)t1
where rnk<11



--2 Top 10 batsmen based on past 3 years batting average. (min 60 balls faced in each season)
WITH my_cte AS
(SELECT b.batsmanName, right(dms.matchDate,4) as seasons, 
SUM(CASE WHEN out_not_out = 'out' THEN runs END)AS total_runs_scored,
SUM(balls)AS total_balls_played, COUNT(CASE WHEN out_not_out = 'out' THEN runs END)AS num_of_out
FROM dbo.fact_bating_summary b
JOIN dim_match_summary dms ON dms.match_id = b.match_id
GROUP BY batsmanName, right(dms.matchDate,4)
HAVING SUM(balls)>=60)

select top 10 batsmanName ,round(SUM(total_runs_scored)/SUM(num_of_out),2) as batting_average from my_cte
group by batsmanName
having sum(total_balls_played)>60
order by batting_average desc


----3 Top 10 batsmen based on past 3 years strike rate (min 60 balls faced in each season)


select top 10 t1.batsmanName, round(avg(t1.avg_strike_rate),2) as avg_strike_rate from (
select 
a.batsmanName, RIGHT(b.matchDate,4) as years,round(AVG(a.SR),2) as avg_strike_rate
from dbo.fact_bating_summary a
join dbo.dim_match_summary b on a.match_id = b.match_id
group by batsmanName, RIGHT(b.matchDate,4)) t1
group by batsmanName
having COUNT(distinct years)=3
order by 2 desc


--4 Top 10 bowlers based on past 3 years total wickets taken.

select * from(
select bowlerName, SUM(wickets) as total_wickets, DENSE_RANK() over(order by sum(wickets) desc) as rnk_wickets from dbo.fact_bowling_summary
group by bowlerName) t1
where rnk_wickets<11


--5 Top 10 bowlers based on past 3 years bowling average. (min 60 balls bowled in each season)


select bowlerName, (sum(runs)/SUM(wickets)) as bowling_average from dbo.fact_bowling_summary
group by bowlerName
having sum(wickets)>0
order by 2 desc

------------------------------------------

--6 Top 10 bowlers based on past 3 years economy rate. (min 60 balls bowled in each season)


with cte as(
select a.bowlerName,
RIGHT(b.matchDate,4) as season,
AVG(a.economy) as avg_economy,
sum(a.overs*6) as total_balls, 
SUM(a.runs) as runs_conceded 
from fact_bowling_summary a
join dim_match_summary b on a.match_id = b.match_id
group by bowlerName, RIGHT(b.matchDate,4)
having sum(a.overs*6)>60)

select top 10 cte.bowlerName, round(AVG(avg_economy),2) as economy from cte
group by cte.bowlerName
having COUNT(distinct cte.season) = 3
order by round(AVG(avg_economy),2)


-----------------------------------------------------------------

--7. Top 5 batsmen based on past 3 years boundary % (fours and sixes).



--------------------------------------total_boundries score / total_runs---------------
with cte as(
select batsmanName, RIGHT(matchDate,4) as season, SUM(runs) as total_runs, SUM(balls) as total_balls,sum(a.[4s]+a.[6s]) as total_boundaries,
sum(a.[4s]*4+a.[6s]*6) as total_boundaries_score,
round((sum(a.[4s]*4+a.[6s]*6)*100)/SUM(runs),0) as boundary_percentage
from fact_bating_summary a
join dim_match_summary b on a.match_id = b.match_id
where runs>0
group by batsmanName, RIGHT(matchDate,4))

select top 10 batsmanName, round(AVG(boundary_percentage),2) as boundries_percentage from cte
where total_balls>60
group by batsmanName
having COUNT(distinct season) = 3
order by 2 desc



--------------------------total_boundries / total_balls

with cte as(
select batsmanName, RIGHT(matchDate,4) as season, SUM(balls) as total_balls, sum(a.[4s]+a.[6s]) as total_boundaries,
sum([4s]*4+[6s]*6) as total_boundaries_score,
round((sum([4s]+[6s])*100)/SUM(balls),4) as boundary_percentage
from fact_bating_summary a
join dim_match_summary b on a.match_id = b.match_id
where balls>0
group by batsmanName, RIGHT(matchDate,4))

select batsmanName, round(AVG(boundary_percentage),2) as boundries_percentage from cte
group by batsmanName
having COUNT(distinct season) = 3
order by 2 desc




---8. Top 5 bowlers based on past 3 years dot ball %.

select top 10 bowlerName, round((sum(dot_balls)*100)/SUM(total_balls),2) as dot_balls_percentage from
(select bowlerName,RIGHT(b.matchDate,4) as seasons, SUM(_0s) as dot_balls, SUM(overs*6) as total_balls, SUM(wickets) total_wicktes from fact_bowling_summary a
join dim_match_summary b on a.match_id = b.match_id
group by bowlerName, RIGHT(b.matchDate,4))t1
where total_balls>0
group by bowlerName
having COUNT(distinct seasons) = 3
order by 2 desc


--9. Top 4 teams based on past 3 years winning %.


select winner as teams, (sum(winning_count)/count(total_matches)) as winning_percentage from(
select winner, RIGHT(matchDate,4) as seasons, COUNT(winner) as winning_count, count(match_id) as total_matches from dim_match_summary
group by winner, RIGHT(matchDate,4)) t1
group by winner
having count(distinct seasons)=3
order by 2 desc





--10.Top 2 teams with the highest number of wins achieved by chasing targets over the past 3 years.

-- team1 - batting first
-- team2 - batting second



------------------------------------
select * from
(select team2,sum(case when a.team2 = winner then 1 else 0 end) as total_wins,
DENSE_RANK() over(order by sum(case when a.team2 = winner then 1 else 0 end) desc) as bowling_team_win_rnk
from dim_match_summary a
group by team2) t1
where bowling_team_win_rnk<3


--------------------------------------






