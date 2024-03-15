SELECT * FROM artist
SELECT * FROM canvas_size
SELECT * FROM imaga_link
SELECT * FROM museum_hours
SELECT * FROM museum
SELECT * FROM product_size
SELECT * FROM subject 
SELECT * FROM work 


-- Delete duplicate records from work, product_size, subject and image_link tables
DELETE FROM work
WHERE ctid NOT IN (SELECT MIN(ctid)
                   FROM work
                   GROUP BY work_id);
				   
DELETE FROM product_size
WHERE ctid NOT IN (SELECT MIN(ctid)
				  FROM product_size
				  GROUP BY work_id, size_id);
				  
DELETE FROM subject
WHERE ctid NOT IN (SELECT MIN(ctid)
				  FROM subject
				  GROUP BY work_id, subject);
				  
DELETE FROM image_link
WHERE ctid NOT IN (SELECT MIN(ctid)
				  FROM image_link
				  GROUP BY work_id);
				  


--Are there museums without any paintings?
SELECT *
FROM museum m
WHERE NOT EXISTS (
    SELECT 1
    FROM work w
    WHERE w.museum_id = m.museum_id
);


-- Museum_Hours table has 1 invalid entry. Identify it and remove it.
DELETE FROM museum_hours
WHERE ctid NOT IN (
    SELECT MIN(ctid)
    FROM museum_hours
    GROUP BY museum_id, day
);



--Fetch the top 10 most famous painting subject
SELECT subject, COUNT(*) AS painting_count
FROM subject
GROUP BY subject
ORDER BY painting_count DESC
LIMIT 10;



-- How many museums are open every single day?
SELECT COUNT(*) AS museums_open_every_day
FROM (
    SELECT museum_id
    FROM museum_hours
    GROUP BY museum_id
    HAVING COUNT(DISTINCT day) = 7
) AS museums_open_seven_days;



--Which are the top 5 most popular museum?
SELECT m.name AS museum_name, COUNT(w.work_id) AS total_paintings
FROM museum m
JOIN work w ON m.museum_id = w.museum_id
GROUP BY m.name
ORDER BY total_paintings DESC
LIMIT 5;



--Which artist has the most number of Portraits paintings outside USA?. 
--Display artist name, number of paintings and the artist nationality.
SELECT full_name AS artist_name,
       nationality,
       num_of_paintings
FROM (
    SELECT a.full_name,
           a.nationality,
           COUNT(*) AS num_of_paintings,
           RANK() OVER (ORDER BY COUNT(*) DESC) AS rnk
    FROM work w
    JOIN artist a ON a.artist_id = w.artist_id
    JOIN subject s ON s.work_id = w.work_id
    JOIN museum m ON m.museum_id = w.museum_id
    WHERE s.subject = 'Portraits'
      AND m.country != 'USA'
    GROUP BY a.full_name, a.nationality
) x
WHERE rnk = 1;



--Identify the artist and the museum where the most expensive and least expensive painting is placed. 
--Display the artist name, sale_price, painting name, museum name, museum city and canvas label
WITH ranked_paintings AS (
    SELECT *,
           RANK() OVER (ORDER BY sale_price DESC) AS rnk_desc,
           RANK() OVER (ORDER BY sale_price) AS rnk_asc
    FROM product_size
)
SELECT w.name AS painting_name,
       cte.sale_price,
       a.full_name AS artist_name,
       m.name AS museum_name,
       m.city AS museum_city,
       cz.label AS canvas_label
FROM ranked_paintings cte
JOIN work w ON w.work_id = cte.work_id
JOIN museum m ON m.museum_id = w.museum_id
JOIN artist a ON a.artist_id = w.artist_id
JOIN canvas_size cz ON cz.size_id = cte.size_id::NUMERIC
WHERE cte.rnk_desc = 1 OR cte.rnk_asc = 1;



-- Identify the artists whose paintings are displayed in multiple countries
WITH cte AS (
    SELECT DISTINCT a.full_name AS artist,
                    m.country
    FROM work w
    JOIN artist a ON a.artist_id = w.artist_id
    JOIN museum m ON m.museum_id = w.museum_id
)
SELECT artist,
       COUNT(1) AS num_of_countries
FROM cte
GROUP BY artist
HAVING COUNT(1) > 1
ORDER BY num_of_countries DESC;



--Display the 3 least popular canva sizes
SELECT label, ranking, num_of_paintings
FROM (
    SELECT cs.size_id,
           cs.label,
           COUNT(1) AS num_of_paintings,
           DENSE_RANK() OVER (ORDER BY COUNT(1)) AS ranking
    FROM work w
    JOIN product_size ps ON ps.work_id = w.work_id
    JOIN canvas_size cs ON cs.size_id::TEXT = ps.size_id
    GROUP BY cs.size_id, cs.label
) x
WHERE x.ranking <= 3;



--Fetch all the paintings which are not displayed on any museums?
SELECT * FROM work where museum_id is null



-- Are there museums without any paintings?
SELECT *
FROM museum m
WHERE NOT EXISTS (
    SELECT 1
    FROM work w
    WHERE w.museum_id = m.museum_id
);


--Which are the 3 most popular and 3 least popular painting styles?
WITH StyleCounts AS (
    SELECT style,
           COUNT(*) AS painting_count,
           DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS rank_most_popular,
           DENSE_RANK() OVER (ORDER BY COUNT(*) ASC) AS rank_least_popular
    FROM work
    GROUP BY style
)
SELECT style,
       painting_count,
       'Most Popular' AS popularity
FROM StyleCounts
WHERE rank_most_popular <= 3
UNION ALL
SELECT style,
       painting_count,
       'Least Popular' AS popularity
FROM StyleCounts
WHERE rank_least_popular <= 3
ORDER BY popularity, painting_count DESC;


--Identify the museums which are open on both Sunday and Monday. Display museum name, city
SELECT m.name AS museum_name,
       m.city
FROM museum m
JOIN museum_hours mh1 ON m.museum_id = mh1.museum_id
JOIN museum_hours mh2 ON m.museum_id = mh2.museum_id
WHERE mh1.day = 'Sunday'
  AND mh2.day = 'Monday';
  
  

--How many paintings have an asking price of more than their regular price?
SELECT COUNT(*)
FROM work
WHERE asking_price > regular_price;



--Which museum is open for the longest duration during a day. 
--Display museum name, state, and hours open and which day?
WITH MuseumOpenHours AS (
    SELECT m.name AS museum_name,
           m.state,
           mh.day,
           TO_TIMESTAMP(mh.open, 'HH24:MI') AS open_time,
           TO_TIMESTAMP(mh.close, 'HH24:MI') AS close_time,
           (TO_TIMESTAMP(mh.close, 'HH24:MI') - TO_TIMESTAMP(mh.open, 'HH24:MI')) AS duration
    FROM museum m
    JOIN museum_hours mh ON m.museum_id = mh.museum_id
)
SELECT museum_name,
       state,
       day,
       TO_CHAR(open_time, 'HH:MI AM') AS open_time,
       TO_CHAR(close_time, 'HH:MI AM') AS close_time,
       EXTRACT(HOUR FROM duration) || ' hours ' || EXTRACT(MINUTE FROM duration) || ' minutes' AS hours_open
FROM MuseumOpenHours
ORDER BY duration DESC
LIMIT 1;








