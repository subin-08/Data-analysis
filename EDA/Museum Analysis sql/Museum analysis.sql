Use painting

select * from artist;
select * from canvas_size;
select * from image_link;
select * from museum;
select * from museum_hours;
select * from product_size;
select * from subject;
select * from work;

--1 Fetch all the paintings which are not displayed on any museums?

select * from work
where museum_id is NULL;


--2 Are there museuems without any paintings?

select * from museum a
left join work b
on a.museum_id = b.work_id
where work_id is null



--3 How many paintings have an asking price of more than their regular price?

select count(*) as Total
from product_size
where sale_price>regular_price;


--4 Identify the paintings whose asking price is less than 50% of its regular price

select work_id
from product_size
where sale_price<(regular_price/2);


 --5 Which canvas size costs the most?

 select top 1 a.label, MAX(sale_price) as maximum_sale_price from canvas_size a
 join product_size b
 on a.size_id = b.size_id
 group by a.label
 order by maximum_sale_price desc;

--6 Delete duplicate records from work, product_size, subject and image_link tables.


--duplicate records in work table

select work_id, count(work_id) from work
group by work_id
having count(work_id)>1;



-- duplicate records in product_size table
select work_id, count(work_id) from product_size
group by work_id
having count(work_id)>1;


-- duplicate records in subject table
select work_id, count(work_id) from subject
group by work_id
having count(work_id)>1;

-- duplicate records in image_link table.

select work_id, count(work_id) from image_link
group by work_id
having count(work_id)>1;

--7 Identify the museums with invalid city information in the given dataset

SELECT museum_id, name
FROM museum
WHERE city LIKE '[0-9]%'



--8  Museum_Hours table has 1 invalid entry. Identify it and remove it.

select day, count(museum_id) from museum_hours
group by day
-- Thursday is written as Thusday in some of the cell replace and right the correct name



--9 Fetch the top 10 most famous painting subject


with cte as
(
select top 10 subject, count(b.work_id) as count_of_images
from subject a
join work b
on a.work_id = b.work_id
group by subject
)
select *,
((count_of_images) / sum(count_of_images) over()) as total_images
from cte
order by count_of_images desc;





--10 Identify the museums which are open on both Sunday and Monday. Display museum name, city.(Doubt)

select a.museum_id, b.name,b.city,b.state,b.country, a.day from museum_hours a
join museum b
on a.museum_id = b.museum_id
where day in ('Sunday', 'Monday')
group by a.museum_id, b.name,b.city,b.state,b.country, a.day
having count(day) = 2
order by b.name asc;

--11 How many museums are open every single day?

select count(*) AS total_museums_open_7_days from 
(select museum_id, count(museum_id) as count_of_museum from museum_hours
group by museum_id
having count(day) = 7) as a;



--12 Which are the top 5 most popular museum? (Popularity is defined based on most no of paintings in a museum)

select top 5 a.museum_id,a.name ,COUNT(b.work_id) as count_of_paintings from museum a
join work b
on a.museum_id = b.museum_id
group by a.museum_id, a.name
order by count(b.work_id) desc;

--13 Who are the top 5 most popular artist? (Popularity is defined based on most no of paintings done by an artist)

select top 5 a.artist_id, a.full_name, count(b.work_id) from artist a
join work b on a.artist_id = b.artist_id
group by a.artist_id, a.full_name
order by count(b.work_id) desc;


--14 Display the 3 least popular canva sizes

select label, count(size_id) from canvas_size
group by label
order by count(size_id) asc;


select size_id, count(*) from canvas_size
group by size_id
order by 2 desc;


-- 15 Which museum is open for the longest during a day. 
--	  Dispay museum name, state and hours open and which day?



--select * from museum_hours;


--Alter table museum_hours
--RENAME COLUMN open to opening_hours

--select b.name, b.city, (a.open)-(b.close) as total_time from museum_hours a
--join museum b on a.museum_id = b.museum_id;

--select open, close from museum_hours




--16 Which museum has the most no of most popular painting style?


select top 1 a.name, b.style,count(b.style) from museum a
join work b
on a.museum_id = b.museum_id
group by a.name, b.style
order by count(b.style) desc;


	with pop_style as 
			(select style
			,rank() over(order by count(style) desc) as rnk
			from work
			group by style),
		cte as
			(select w.museum_id,m.name as museum_name,ps.style, count(1) as no_of_paintings
			,rank() over(order by count(1) desc) as rnk
			from work w
			join museum m on m.museum_id=w.museum_id
			join pop_style ps on ps.style = w.style
			where w.museum_id is not null
			and ps.rnk=1
			group by w.museum_id, m.name,ps.style)
	select museum_name,style,no_of_paintings
	from cte 
	where rnk=1;


--17 Identify the artists whose paintings are displayed in multiple countries


select top 5 a.full_name, a.style, count(*) no_of_paintings from artist a
join work b on a.artist_id = b.artist_id
join museum c on b.museum_id = c.museum_id
group by a.full_name, a.style
order by count(*) desc;


--18 Display the country and the city with most no of museums. Output 2 seperate columns to mention the 
--	 city and country. If there are multiple value, seperate them with comma.

select country, city, count(*) from museum
group by country, city
order by count(*) desc

select * from museum;




--19 Identify the artist and the museum where the most expensive and least expensive painting is placed. 
--	 Display the artist name, sale_price, painting name, museum name, museum city and canvas label.

with cte as
(
select
work_id,
size_id,
sale_price,
rank() over(order by sale_price desc) as rnk_desc,
rank() over(order by sale_price asc) as rnk_asc
from product_size
)
select b.name as painting,a.full_name as artist_name,c.city,sum(cte.sale_price) as total_price from cte
join work b on cte.work_id = b.work_id
join artist a on a.artist_id = b.artist_id
join museum c on b.museum_id = c.museum_id
join product_size d on d.work_id = b.work_id
join canvas_size e on e.size_id = d.size_id
where rnk_desc=1 or rnk_asc=1
group by b.name,a.full_name,c.city;





select * from work;
select * from museum;
select * from product_size;
select * from work;

--20 Which country has the 5th highest no of paintings?





with cte as 
	(select m.country, count(w.work_id) as no_of_Paintings
	,rank() over(order by count(w.work_id) desc) as rnk_desc
	from work w
	join museum m on m.museum_id=w.museum_id
	group by m.country)
select country, no_of_Paintings
from cte 
where rnk_desc=5;


--21 Which are the 3 most popular and 3 least popular painting styles?

with cte as
(
select style, count(*) as no_of_paintings,
rank() over(order by count(*) desc) as rnk_desc,
rank() over(order by count(*)) as rnk_asc
from work
where style is not null
group by style)
select style, no_of_paintings, rnk_desc, rnk_asc from cte
where rnk_asc<=3 or rnk_desc<=3



select top 3 style, count(*) as no_of_paintings from work
where style is not null
group by style 
order by no_of_paintings desc;


select top 3 style, count(*) as no_of_paintings from work
group by style 
order by no_of_paintings;




--22 Which artist has the most no of Portraits paintings outside USA?. 
--	 Display artist name, no of paintings and the artist nationality

select full_name,nationality,no_of_paintings from
(
select
full_name,
nationality,
count(1) as no_of_paintings,
rank() over(order by count(1) desc) as rnk_desc
from artist a
join work w on a.artist_id = w.artist_id
join subject s on s.work_id = w.work_id
where s.subject = 'Portraits' and a.nationality != 'USA'
group by full_name, nationality) z
where rnk_desc<=5



