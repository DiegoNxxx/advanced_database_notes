-- Try it 3
select b.*,
       count(*) over ( partition by shape) bricks_per_shape,
       median ( weight ) over ( partition by brick_id) median_weight_per_shape
from   bricks b
order  by shape, weight, brick_id;

-- Try it 5
select b.brick_id, b.weight,
       round ( avg(weight) over (
         order by brick_id
       ), 2 ) running_average_weight
from   bricks b
order  by brick_id;

-- Try it 9
select b.*,
       min ( colour ) over (
         order by brick_id
         rows between 2 preceding and 1 preceding
       ) first_colour_two_prev,
       count (*) over (
         order by weight
         range between current row and 1 following
       ) count_values_this_and_next
from   bricks b
order  by weight;

-- Try it 11
with totals as (
  select b.*,
         sum ( weight ) over (
           partition by shape
         ) weight_per_shape,
         sum ( weight ) over (
           order by brick_id
         ) running_weight_by_id
  from   bricks b
)
select * from totals
where  running_weight_by_id > weight_per_shape
and    shape = 'pyramid'
order  by brick_id;

-- 
WITH ranked_salary AS (
  SELECT 
    name,
    salary,
    department_id,
    DENSE_RANK() OVER (
      PARTITION BY department_id 
      ORDER BY salary DESC
    ) ranking
  FROM employee
)

SELECT 
  d.department_name,
  s.name,
  s.salary
FROM ranked_salary s
INNER JOIN department d
  ON s.department_id = d.department_id
WHERE s.ranking <= 3
ORDER BY d.department_name ASC, s.salary DESC, s.name ASC;