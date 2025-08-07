# SQL query for Primary Analysis questions for which SQL is used.

# Q1
# Bottom 5 area with lowest aqi (december 2024 to may2025)
SELECT 
    area,
    AVG(aqi_value) AS average_aqi_value
FROM aqi
WHERE date_temp BETWEEN '2024-12-01' AND '2025-05-31'
GROUP BY area
ORDER BY average_aqi_value ASC
LIMIT 5;


# Top 5 area with highest aqi (december 2024 to may 2025)
SELECT 
    area,
    AVG(aqi_value) AS average_aqi_value
FROM aqi
WHERE date_temp >= '2024-12-01' AND date_temp <= '2025-05-31'
GROUP BY area
ORDER BY average_aqi_value DESC
LIMIT 5;

# Q2 List out top 2 and bottom 2 prominent pollutants for each state of southern India. 
#(Consider data post covid: 2022 onwards)

select state,prominent_pollutants,aqi_value,
case
	when rank_top <=2 then 'top_2'
    when rank_bottom<=2 then 'bottom_2'
end as Category
from
(select state,prominent_pollutants,aqi_value,
rank() over( partition by state order by aqi_value desc) as rank_top,
rank() over(partition by state order by aqi_value asc) as rank_bottom
from
(select *
from aqi
where state in ("Karnataka","Tamil Nadu","Telangana")) as filtered_data) as t
WHERE rank_top <= 2 OR rank_bottom <= 2
ORDER BY state, prominent_pollutants,aqi_value DESC;


#Q4 Which months consistently show the worst air quality across Indian states —
#(Consider top 10 states with high distinct areas)

SELECT 
    state,
    EXTRACT(MONTH FROM date_temp) AS month,
    AVG(aqi_value) AS avg_aqi
FROM aqi
WHERE state IN (
    SELECT state
    FROM (
        SELECT state
        FROM aqi
        GROUP BY state
        ORDER BY COUNT(DISTINCT area) DESC, SUM(aqi_value) DESC
        LIMIT 10
    ) AS top_states
)
GROUP BY state, EXTRACT(MONTH FROM date_temp)
ORDER BY state, month,avg_aqi desc;

# Q5 For the city of Bengaluru, how many days fell under each air quality category 
# (e.g., Good, Moderate, Poor, etc.) between March and May 2025?

select air_quality_status,count(date_temp) as Days from aqi
where area = "Bengaluru"
and date_temp between "2025-03-01" and "2025-05-31"
group by air_quality_status ;

# Q6 List the top two most reported disease illnesses in each state over the past three 
#years, along with the corresponding average Air Quality Index (AQI) for that 
#period.

with cte as (
SELECT 
  state,
  disease_illness_name,
  ROW_NUMBER() OVER (
    PARTITION BY state 
    ORDER BY disease_illness_name DESC
  ) AS rn
FROM idsp)
select state,disease_illness_name
from cte 
where rn <=2
order by rn desc;

WITH disease_counts AS (
  SELECT 
    state,
    disease_illness_name,
    COUNT(*) AS case_count
  FROM idsp
  WHERE new_outbreak_starting_date >= DATE_SUB(CURDATE(), INTERVAL 3 YEAR)
  GROUP BY state, disease_illness_name
),
ranked_diseases AS (
  SELECT 
    state,
    disease_illness_name,
    case_count,
    ROW_NUMBER() OVER (
      PARTITION BY state 
      ORDER BY case_count DESC
    ) AS rn
  FROM disease_counts
),
avg_aqi AS (
  SELECT 
    state,
    AVG(aqi_value) AS avg_aqi
  FROM aqi
  WHERE date_temp >= DATE_SUB(CURDATE(), INTERVAL 3 YEAR)
  GROUP BY state
)
SELECT 
  r.state,
  r.disease_illness_name,
  r.case_count,
  a.avg_aqi
FROM ranked_diseases r
JOIN avg_aqi a ON r.state = a.state
WHERE r.rn <= 2
ORDER BY r.state, r.case_count DESC;



