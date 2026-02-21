-- Lesson 6 
SELECT Title, domestic_sales, international_sales FROM movies inner join boxoffice on movies.id = boxoffice.Movie_id;

SELECT Title, domestic_sales, international_sales FROM movies inner join boxoffice on movies.id = boxoffice.Movie_id where(international_sales > domestic_sales);

SELECT Title, domestic_sales, international_sales, rating FROM movies inner join boxoffice on movies.id = boxoffice.Movie_id  order by rating desc;

-- Lesson 7 
SELECT distinct building_name FROM employees join buildings on employees.building = buildings.building_name;

SELECT distinct building_name, capacity FROM buildings;

SELECT DISTINCT building_name, role FROM buildings LEFT JOIN employee ON building_name = building;

-- lesson facebook
SELECT p.page_id FROM pages p LEFT JOIN page_likes pl ON p.page_id = pl.page_id WHERE pl.page_id IS NULL
ORDER BY p.page_id ASC;