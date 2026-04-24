Exercise 1: Find the slow query

a) What scan type do you see? Why?
Se observa un TABLE ACCESS FULL. Oracle necesita recorrer toda la tabla porque no existe un índice sobre la columna site_id.

b) site_id has values 1–5. Is this high or low cardinality?
Es de baja cardinalidad, ya que solo hay 5 valores distintos en un total de 50,000 registros.

c) Would adding an index on site_id help? Why or why not?
No ayudaría mucho. Como los datos no son muy únicos, el índice devolvería alrededor de 10,000 filas (20% de la tabla). Oracle considera más rápido leer toda la tabla que usar el índice y luego acceder repetidamente a la tabla para tantas filas.

Exercise 2: Create an index and see if it helps

CREATE INDEX idx_pv_visit_date ON patient_visits(visit_date);

a) Does Oracle use the index for this range?
Sí, para un rango de 30 días utiliza el índice mediante un INDEX RANGE SCAN.

b) Change the range to the last 7 days. Does the plan change?
No cambia, sigue utilizando el índice. Al ser un rango más pequeño, el índice sigue siendo conveniente.

c) Change to the last 700 days. What happens?
Oracle vuelve a usar TABLE ACCESS FULL, ya que ese rango cubre casi todos los datos de la tabla (alrededor de 730 días).

d) Why does the range size affect whether Oracle uses the index?
Porque cuando el rango es pequeño, el índice ahorra tiempo. Pero si el rango es muy grande, devuelve casi todas las filas y termina siendo más lento que leer la tabla completa.

Exercise 3: Composite index

a) Does the plan use the composite index?
Sí, el plan sí utiliza el índice compuesto.

b) Now try querying ONLY on visit_date (no patient_id). Does the composite index get used? Why not?
No, se realiza un escaneo completo de la tabla. El índice está organizado primero por patient_id y después por visit_date, por lo que no puede aprovecharse usando solo la segunda columna.

c) What's the rule about column order in composite indexes?
Se debe usar la columna principal (la primera del índice) para que el índice funcione. Si solo se consulta la segunda columna, el índice no sirve.

Exercise 4: Function that breaks an index

a) What scan type did the second query use?
Se utilizó TABLE ACCESS FULL.

b) Why does wrapping a column in a function break index use?
Porque el índice está basado en los valores originales de patient_id. Al usar TO_CHAR(patient_id), Oracle tiene que convertir cada valor antes de compararlo, lo que implica revisar todas las filas y hace que el índice no se utilice.

c) How would you rewrite the second query to allow index use?
SELECT * FROM patient_visits WHERE patient_id = 5432;

Exercise 5: real-world scenarios

Scenario A: (Nightly batch load, daytime date-range queries)
Index? Sí.
On which column(s)? En la columna de fecha.
Concerns? Las inserciones no afectan durante el día porque la carga se hace por la noche. El índice mejora mucho las consultas por rango de fechas sin impactar el rendimiento en horas laborales.

Scenario B: (High inserts, lookups by customer_id or order_status)
Index? Sí en customer_id, no en order_status.
Concerns? Cada índice ralentiza las inserciones. Como hay 10,000 inserciones por minuto, no conviene tener demasiados índices. customer_id tiene alta cardinalidad, pero order_status solo tiene 4 valores, por lo que un índice ahí no sería útil.

Scenario C: (5 million patients, lookup by email)
Index? Sí.
What kind? Un índice UNIQUE. Como cada correo es diferente, este tipo de índice evita duplicados y hace muy rápida la consulta con WHERE