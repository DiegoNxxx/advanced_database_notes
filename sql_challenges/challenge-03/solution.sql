-- Lesson 10
SELECT max(Years_employed) FROM employees;
SELECT role, avg(years_employed) FROM employees group by role ;
SELECT building, sum(years_employed) FROM employees group by building ;

-- lesson 11
SELECT role, count(*) as number_artist FROM employees where role = "Artist";
SELECT role , count(*) FROM employees group by role;
select role, sum(years_employed) from employees group by role having role = "Engineer"

-- FreeSQL

drop table bricks cascade constraints;
create table bricks (
  colour varchar2(10),
  shape  varchar2(10),
  weight integer
);

insert into bricks values ( 'red', 'cube', 1 );
insert into bricks values ( 'red', 'pyramid', 2 );
insert into bricks values ( 'red', 'cuboid', 1 );

insert into bricks values ( 'blue', 'cube', 1 );
insert into bricks values ( 'blue', 'pyramid', 2 );

insert into bricks values ( 'green', 'cube', 3 );

commit;
