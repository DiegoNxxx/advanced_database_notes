-- lesson 1
SELECT title FROM movies;
SELECT director FROM movies;
SELECT director, title FROM movies;
SELECT year, title FROM movies;
SELECT * FROM movies;

-- lesson 2
SELECT * FROM movies where id = 6
SELECT * FROM movies where year Between 2000 and 2010
SELECT * FROM movies where year Not Between 2000 and 2010
SELECT title, year FROM movies WHERE year <= 2003;
-- lesson 3
SELECT * FROM movies where title Like "%Toy Story%";
SELECT * FROM movies where Director = "John Lasseter";
SELECT * FROM movies where Director != "John Lasseter";
SELECT * FROM movies where Title Like "Wall-%";
-- lesson 4
SELECT distinct director FROM movies ORDER BY director ASC;
SELECT * FROM movies ORDER BY year desc limit 4;
SELECT * FROM movies ORDER BY title ASC limit 5;
SELECT title FROM movies ORDER BY title ASC LIMIT 5 OFFSET 5;
-- lesson 5
SELECT * FROM north_american_cities where Country = "Canada";
SELECT * FROM north_american_cities where country = "United States" order by latitude desc;
SELECT city, longitude FROM north_american_cities WHERE longitude < -87.629798 ORDER BY longitude ASC;
SELECT * FROM north_american_cities WHERE Country = "Mexico" ORDER BY Population desc limit 2;
SELECT * FROM north_american_cities WHERE country LIKE "United States" ORDER BY population DESC LIMIT 2 OFFSET 2;