-- ============================================================
-- Lesson 07: KPI Dashboards — Class Exercises
-- File: 06_exercises.sql
-- Purpose: Practice defining KPIs, writing queries, and handling edge cases
-- ============================================================

-- ============================================================
-- EXERCISE 1: Team Velocity
-- ============================================================

-- Business Question:
-- ¿Qué tan rápido completa trabajo cada equipo en comparación con los demás?

-- Exact Definition:
-- Velocity = cantidad de tareas completadas por cada equipo durante su período de actividad.
-- Solo se consideran tareas con status = 'completed' y completed_at no nulo.
-- Se relacionan teams -> users -> tasks mediante LEFT JOIN.

-- Edge Cases:
-- Equipos sin tareas completadas, equipos con pocos días de actividad,
-- usuarios sin tareas asignadas y tareas canceladas.

-- Unit:
-- Tareas completadas por día.

-- What Could Make It Misleading:
-- Los equipos con más integrantes pueden mostrar una velocidad superior
-- únicamente por tamaño y no necesariamente por eficiencia.

WITH team_stats AS (
    SELECT
        t.id                                                    AS team_id,
        t.name                                                  AS team_name,
        COUNT(DISTINCT u.id)                                    AS member_count,
        COUNT(CASE WHEN ts.status = 'completed'
                    AND ts.completed_at IS NOT NULL
               THEN 1 END)                                      AS completed_tasks,
        -- Evitamos que el denominador sea 0 en equipos nuevos
        GREATEST(
            TRUNC(SYSDATE) - TRUNC(MIN(ts.created_at)),
            1
        )                                                       AS days_active
    FROM   teams t
    LEFT   JOIN users u  ON u.team_id = t.id
    LEFT   JOIN tasks ts ON ts.assigned_to = u.id
    GROUP  BY t.id, t.name
),
velocities AS (
    SELECT
        team_name,
        member_count,
        completed_tasks,
        ROUND(completed_tasks / days_active, 2)                 AS tasks_per_day,
        ROUND(
            completed_tasks / NULLIF(member_count * days_active, 0),
            2
        )                                                       AS tasks_per_member_per_day
    FROM   team_stats
)
SELECT
    team_name,
    member_count,
    completed_tasks,
    tasks_per_day,
    tasks_per_member_per_day,
    ROUND(AVG(tasks_per_day) OVER (), 2)                        AS avg_velocity,
    CASE
        WHEN tasks_per_day < AVG(tasks_per_day) OVER ()
        THEN 'BELOW AVERAGE'
        ELSE 'OK'
    END                                                         AS velocity_flag
FROM   velocities
ORDER  BY tasks_per_day DESC;


-- ============================================================
-- EXERCISE 2: On-Time Delivery Rate
-- ============================================================

-- Business Question:
-- ¿Con qué frecuencia las tareas se terminan dentro de la fecha comprometida?

-- Exact Definition:
-- Una tarea es puntual si completed_at ocurre en la misma fecha o antes de due_date.
-- Solo participan tareas completadas con due_date definido.

-- Edge Cases:
-- Tareas sin fecha límite, tareas incompletas y diferencias de minutos
-- alrededor de la medianoche.

-- Unit:
-- Porcentaje de tareas entregadas a tiempo.

-- What Could Make It Misleading:
-- Excluir muchas tareas sin due_date puede producir una tasa artificialmente alta.

SELECT
    priority,
    COUNT(*)                                                    AS total_completed,
    COUNT(CASE WHEN TRUNC(completed_at) <= due_date
               THEN 1 END)                                      AS on_time_count,
    ROUND(
        100 * COUNT(CASE WHEN TRUNC(completed_at) <= due_date
                         THEN 1 END)
        / COUNT(*),
        1
    )                                                           AS on_time_rate_pct,
    -- Promedio de horas de retraso (solo para las tareas tardías)
    ROUND(
        AVG(
            CASE
                WHEN TRUNC(completed_at) > due_date
                THEN
                    EXTRACT(DAY    FROM (completed_at - CAST(due_date AS TIMESTAMP))) * 24 +
                    EXTRACT(HOUR   FROM (completed_at - CAST(due_date AS TIMESTAMP))) +
                    EXTRACT(MINUTE FROM (completed_at - CAST(due_date AS TIMESTAMP))) / 60
            END
        ),
        1
    )                                                           AS avg_late_hours
FROM   tasks
WHERE  status       = 'completed'
  AND  completed_at IS NOT NULL
  AND  due_date     IS NOT NULL
GROUP  BY priority
ORDER  BY CASE priority
              WHEN 'critical' THEN 1
              WHEN 'high'     THEN 2
              WHEN 'medium'   THEN 3
              WHEN 'low'      THEN 4
          END;


-- ============================================================
-- EXERCISE 3: Tasks per Team
-- ============================================================

-- Business Question:
-- ¿Cuál es la carga de trabajo actual y el nivel de cumplimiento de cada equipo?

-- Exact Definition:
-- Se calculan total_tasks, active_tasks y completion_rate.
-- Active_tasks incluye open, in_progress y blocked.
-- Completion_rate excluye tareas canceladas.

-- Edge Cases:
-- Equipos sin usuarios, equipos sin tareas y divisiones entre cero.

-- Unit:
-- Cantidad de tareas y porcentaje.

-- What Could Make It Misleading:
-- Analizar únicamente el total histórico puede ocultar la carga de trabajo real actual.
SELECT
    t.name                                                      AS team_name,
    COUNT(ts.id)                                                AS total_tasks,
    COUNT(CASE WHEN ts.status IN ('open', 'in_progress', 'blocked')
               THEN 1 END)                                      AS active_tasks,
    ROUND(
        100 * COUNT(CASE WHEN ts.status = 'completed'     THEN 1 END)
            / NULLIF(
                COUNT(CASE WHEN ts.status != 'cancelled'  THEN 1 END),
                0
              ),
        1
    )                                                           AS completion_rate_pct,
    CASE
        WHEN COUNT(CASE WHEN ts.status IN ('open','in_progress','blocked')
                        THEN 1 END) > 10  THEN 'Overloaded'
        WHEN COUNT(CASE WHEN ts.status IN ('open','in_progress','blocked')
                        THEN 1 END) >= 5  THEN 'Healthy'
        ELSE                                   'Underutilized'
    END                                                         AS health_score
FROM   teams t
LEFT   JOIN users u  ON u.team_id = t.id
LEFT   JOIN tasks ts ON ts.assigned_to = u.id
GROUP  BY t.id, t.name
ORDER  BY active_tasks DESC;


-- ============================================================
-- EXERCISE 4: Average Resolution Time
-- ============================================================

-- Business Question:
-- ¿Cuánto tiempo tarda en resolverse una tarea según su prioridad?

-- Exact Definition:
-- Tiempo transcurrido entre created_at y completed_at.
-- Solo se consideran tareas completadas.
-- Los resultados se agrupan por prioridad.

-- Edge Cases:
-- Prioridades con muy pocas tareas completadas o tiempos extremos.

-- Unit:
-- Horas.

-- What Could Make It Misleading:
-- El promedio por sí solo puede verse afectado por valores atípicos,
-- por lo que conviene acompañarlo con mediana y cantidad de casos.

SELECT
    priority,
    COUNT(*)                                                    AS completed_count,
    ROUND(AVG(
        EXTRACT(DAY    FROM (completed_at - created_at)) * 24 +
        EXTRACT(HOUR   FROM (completed_at - created_at)) +
        EXTRACT(MINUTE FROM (completed_at - created_at)) / 60
    ), 1)                                                       AS avg_hours,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY
        EXTRACT(DAY    FROM (completed_at - created_at)) * 24 +
        EXTRACT(HOUR   FROM (completed_at - created_at)) +
        EXTRACT(MINUTE FROM (completed_at - created_at)) / 60
    ), 1)                                                       AS median_hours,
    ROUND(MIN(
        EXTRACT(DAY    FROM (completed_at - created_at)) * 24 +
        EXTRACT(HOUR   FROM (completed_at - created_at)) +
        EXTRACT(MINUTE FROM (completed_at - created_at)) / 60
    ), 1)                                                       AS fastest_hours,
    ROUND(MAX(
        EXTRACT(DAY    FROM (completed_at - created_at)) * 24 +
        EXTRACT(HOUR   FROM (completed_at - created_at)) +
        EXTRACT(MINUTE FROM (completed_at - created_at)) / 60
    ), 1)                                                       AS slowest_hours,
    CASE priority
        WHEN 'critical' THEN 24
        WHEN 'high'     THEN 72
        WHEN 'medium'   THEN 168
        WHEN 'low'      THEN 336
    END                                                         AS sla_target_hours,
    CASE
        WHEN ROUND(AVG(
                EXTRACT(DAY    FROM (completed_at - created_at)) * 24 +
                EXTRACT(HOUR   FROM (completed_at - created_at)) +
                EXTRACT(MINUTE FROM (completed_at - created_at)) / 60
             ), 1)
             <=
             CASE priority
                 WHEN 'critical' THEN 24
                 WHEN 'high'     THEN 72
                 WHEN 'medium'   THEN 168
                 WHEN 'low'      THEN 336
             END
        THEN 'SLA MET'
        ELSE 'SLA MISSED'
    END                                                         AS sla_status
FROM   tasks
WHERE  status       = 'completed'
  AND  completed_at IS NOT NULL
GROUP  BY priority
ORDER  BY CASE priority
              WHEN 'critical' THEN 1
              WHEN 'high'     THEN 2
              WHEN 'medium'   THEN 3
              WHEN 'low'      THEN 4
          END;


-- ============================================================
-- EXERCISE 5: Overdue Tasks
-- ============================================================

-- Business Question:
-- ¿Qué tareas vencidas requieren atención inmediata?

-- Exact Definition:
-- Se consideran vencidas las tareas cuya due_date ya pasó
-- y que no están completadas ni canceladas.

-- Edge Cases:
-- Tareas sin fecha límite, tareas vencidas por pocas horas
-- y tareas sin responsable asignado.

-- Unit:
-- Días de retraso.

-- What Could Make It Misleading:
-- Un simple conteo de tareas vencidas no refleja su gravedad
-- ni el impacto de negocio asociado.
WITH overdue_detail AS (
    SELECT
        ts.title,
        u.full_name                                             AS assignee,
        t.name                                                  AS team,
        ts.priority,
        ts.due_date,
        TRUNC(SYSDATE) - ts.due_date                            AS days_overdue,
        CASE
            WHEN ts.priority = 'critical'
                 THEN 'CRITICAL'
            WHEN ts.priority = 'high'
                 AND TRUNC(SYSDATE) - ts.due_date > 2
                 THEN 'HIGH'
            WHEN ts.priority = 'medium'
                 AND TRUNC(SYSDATE) - ts.due_date > 5
                 THEN 'MEDIUM'
            ELSE 'LOW'
        END                                                     AS severity
    FROM   tasks ts
    JOIN   users u ON u.id = ts.assigned_to
    JOIN   teams t ON t.id = u.team_id
    WHERE  ts.due_date < TRUNC(SYSDATE)
      AND  ts.status NOT IN ('completed', 'cancelled')
      AND  ts.due_date IS NOT NULL
)
SELECT
    title,
    assignee,
    team,
    priority,
    due_date,
    days_overdue,
    severity
FROM   overdue_detail
ORDER  BY
    CASE severity
        WHEN 'CRITICAL' THEN 1
        WHEN 'HIGH'     THEN 2
        WHEN 'MEDIUM'   THEN 3
        ELSE                 4
    END,
    days_overdue DESC;

-- Parte 2: Resumen por severity usando ROLLUP
SELECT
    CASE
        WHEN GROUPING(severity) = 1 THEN '--- TOTAL OVERDUE ---'
        ELSE severity
    END                                                         AS severity,
    COUNT(*)                                                    AS overdue_count,
    ROUND(AVG(days_overdue), 1)                                 AS avg_days_overdue
FROM (
    SELECT
        TRUNC(SYSDATE) - ts.due_date                            AS days_overdue,
        CASE
            WHEN ts.priority = 'critical'
                 THEN 'CRITICAL'
            WHEN ts.priority = 'high'
                 AND TRUNC(SYSDATE) - ts.due_date > 2
                 THEN 'HIGH'
            WHEN ts.priority = 'medium'
                 AND TRUNC(SYSDATE) - ts.due_date > 5
                 THEN 'MEDIUM'
            ELSE 'LOW'
        END                                                     AS severity
    FROM   tasks ts
    WHERE  ts.due_date < TRUNC(SYSDATE)
      AND  ts.status NOT IN ('completed', 'cancelled')
      AND  ts.due_date IS NOT NULL
)
GROUP  BY ROLLUP(severity)
ORDER  BY
    CASE
        WHEN GROUPING(severity) = 1 THEN 99
        WHEN severity = 'CRITICAL'  THEN 1
        WHEN severity = 'HIGH'      THEN 2
        WHEN severity = 'MEDIUM'    THEN 3
        ELSE                             4
    END;

-- ============================================================
-- EXERCISE 6: Productivity Score
-- ============================================================

-- Business Question:
-- ¿Qué usuarios generan más valor mediante trabajo completado?

-- Exact Definition:
-- Se consideran únicamente tareas completadas y se asigna
-- un peso según la prioridad de cada tarea.

-- Edge Cases:
-- Usuarios sin tareas, tareas sin prioridad y usuarios nuevos.

-- Unit:
-- Puntos ponderados por día.

-- What Could Make It Misleading:
-- Contar tareas sin considerar complejidad o prioridad
-- puede favorecer cantidad sobre impacto.

SELECT
    u.full_name,
    COUNT(CASE WHEN ts.status = 'completed' THEN 1 END)         AS completed_tasks,
    SUM(CASE
        WHEN ts.status = 'completed'
        THEN CASE ts.priority
                 WHEN 'critical' THEN 4
                 WHEN 'high'     THEN 3
                 WHEN 'medium'   THEN 2
                 WHEN 'low'      THEN 1
                 ELSE                 0
             END
        ELSE 0
    END)                                                         AS weighted_score,
    GREATEST(TRUNC(SYSDATE) - TRUNC(MIN(ts.created_at)), 1)      AS days_active,
    ROUND(
        SUM(CASE
            WHEN ts.status = 'completed'
            THEN CASE ts.priority
                     WHEN 'critical' THEN 4
                     WHEN 'high'     THEN 3
                     WHEN 'medium'   THEN 2
                     WHEN 'low'      THEN 1
                     ELSE                 0
                 END
            ELSE 0
        END)
        /
        GREATEST(TRUNC(SYSDATE) - TRUNC(MIN(ts.created_at)), 1),
        2
    )                                                            AS productivity_score
FROM   users u
LEFT   JOIN tasks ts ON ts.assigned_to = u.id
GROUP  BY u.id, u.full_name
ORDER  BY productivity_score DESC;


-- ============================================================
-- EXERCISE 7: Team Efficiency
-- ============================================================

-- Business Question:
-- ¿Qué porcentaje del trabajo asignado logra completar cada equipo?

-- Exact Definition:
-- Eficiencia = tareas completadas / tareas válidas.
-- Las tareas canceladas se excluyen del cálculo.

-- Edge Cases:
-- Equipos sin tareas y divisiones entre cero.

-- Unit:
-- Porcentaje.

-- What Could Make It Misleading:
-- Un porcentaje alto basado en pocas tareas puede no representar
-- el desempeño real del equipo.
SELECT
    t.name                                                       AS team_name,
    COUNT(CASE WHEN ts.status != 'cancelled' THEN 1 END)         AS total_valid_tasks,
    COUNT(CASE WHEN ts.status = 'completed'  THEN 1 END)         AS completed_tasks,
    ROUND(
        100 * COUNT(CASE WHEN ts.status = 'completed'  THEN 1 END)
            / NULLIF(
                COUNT(CASE WHEN ts.status != 'cancelled' THEN 1 END),
                0
              ),
        1
    )                                                            AS efficiency_pct
FROM   teams t
LEFT   JOIN users u  ON u.team_id = t.id
LEFT   JOIN tasks ts ON ts.assigned_to = u.id
GROUP  BY t.id, t.name
ORDER  BY efficiency_pct DESC NULLS LAST;


-- ============================================================
-- EXERCISE 8: Urgency Index
-- ============================================================

-- Business Question:
-- ¿Qué tareas deben atenderse primero?

-- Exact Definition:
-- Se asigna un peso numérico a la prioridad y se combina
-- con la proximidad de la fecha límite.

-- Edge Cases:
-- Tareas sin due_date, tareas vencidas y prioridades inválidas.

-- Unit:
-- Índice de urgencia.

-- What Could Make It Misleading:
-- Una fórmula mal balanceada puede sobrevalorar la prioridad
-- o el tiempo restante respecto al otro factor.
SELECT
    title,
    priority,
    due_date,
    due_date - TRUNC(SYSDATE)                                    AS days_until_due,
    CASE priority
        WHEN 'critical' THEN 4
        WHEN 'high'     THEN 3
        WHEN 'medium'   THEN 2
        WHEN 'low'      THEN 1
        ELSE                 0
    END                                                          AS priority_weight,
    (CASE priority
         WHEN 'critical' THEN 4
         WHEN 'high'     THEN 3
         WHEN 'medium'   THEN 2
         WHEN 'low'      THEN 1
         ELSE                 0
     END * 10)
    - (due_date - TRUNC(SYSDATE))                                AS urgency_index
FROM   tasks
WHERE  status NOT IN ('completed', 'cancelled')
  AND  due_date IS NOT NULL
ORDER  BY urgency_index DESC;


-- ============================================================
-- PART D: Bonus — Build a Summary Dashboard Query
-- ============================================================

-- Business Question:
-- ¿Cuál es el estado general del sistema de gestión de tareas?

-- Exact Definition:
-- Dashboard consolidado que combina métricas de actividad,
-- cumplimiento, vencimientos, prioridades y carga por equipo.

-- Edge Cases:
-- Ausencia de tareas activas, equipos sin tareas y métricas nulas.

-- Unit:
-- Múltiples unidades (conteos, porcentajes, horas y días).

-- What Could Make It Misleading:
-- Mostrar únicamente indicadores agregados puede ocultar
-- problemas específicos de ciertos equipos o prioridades.
WITH base AS (
    -- Cada tarea enriquecida con columnas calculadas
    SELECT
        ts.id,
        ts.status,
        ts.priority,
        ts.due_date,
        ts.created_at,
        ts.completed_at,
        u.team_id,
        t.name                                                   AS team_name,
        -- ¿Está activa?
        CASE WHEN ts.status IN ('open', 'in_progress', 'blocked')
             THEN 1 END                                          AS is_active,
        -- ¿Está vencida?
        CASE WHEN ts.due_date < TRUNC(SYSDATE)
              AND ts.status NOT IN ('completed', 'cancelled')
              AND ts.due_date IS NOT NULL
             THEN 1 END                                          AS is_overdue,
        -- Horas de resolución (solo completadas)
        CASE WHEN ts.status = 'completed' AND ts.completed_at IS NOT NULL
             THEN EXTRACT(DAY    FROM (ts.completed_at - ts.created_at)) * 24
                + EXTRACT(HOUR   FROM (ts.completed_at - ts.created_at))
                + EXTRACT(MINUTE FROM (ts.completed_at - ts.created_at)) / 60
        END                                                      AS resolution_hours,
        -- Días de retraso (solo vencidas)
        CASE WHEN ts.due_date < TRUNC(SYSDATE)
              AND ts.status NOT IN ('completed', 'cancelled')
              AND ts.due_date IS NOT NULL
             THEN TRUNC(SYSDATE) - ts.due_date
        END                                                      AS days_overdue
    FROM   tasks ts
    LEFT   JOIN users u ON u.id = ts.assigned_to
    LEFT   JOIN teams t ON t.id = u.team_id
),
totals AS (
    SELECT
        COUNT(*)                                                 AS total_tasks,
        COUNT(CASE WHEN status = 'completed' THEN 1 END)         AS completed_tasks,
        COUNT(is_active)                                         AS active_tasks,
        COUNT(is_overdue)                                        AS overdue_tasks,
        ROUND(
            100 * COUNT(CASE WHEN status = 'completed' THEN 1 END)
                / NULLIF(
                    COUNT(CASE WHEN status != 'cancelled' THEN 1 END),
                    0
                  ),
            1
        )                                                        AS completion_rate_pct,
        ROUND(AVG(resolution_hours), 1)                          AS avg_resolution_hours,
        ROUND(AVG(days_overdue), 1)                              AS avg_days_overdue
    FROM   base
),
top_priority AS (
    -- Prioridad más común entre tareas activas
    SELECT priority AS most_common_priority
    FROM (
        SELECT
            priority,
            RANK() OVER (ORDER BY COUNT(*) DESC)                 AS rnk
        FROM   base
        WHERE  is_active IS NOT NULL
        GROUP  BY priority
    )
    WHERE rnk = 1
    FETCH FIRST 1 ROW ONLY
),
top_team AS (
    -- Equipo con más tareas activas
    SELECT team_name AS busiest_team
    FROM (
        SELECT
            team_name,
            RANK() OVER (ORDER BY COUNT(*) DESC)                 AS rnk
        FROM   base
        WHERE  is_active IS NOT NULL
        GROUP  BY team_name
    )
    WHERE rnk = 1
    FETCH FIRST 1 ROW ONLY
)
SELECT
    t.total_tasks,
    t.completed_tasks,
    t.active_tasks,
    t.overdue_tasks,
    t.completion_rate_pct,
    t.avg_resolution_hours,
    t.avg_days_overdue,
    p.most_common_priority,
    tt.busiest_team
FROM   totals t
CROSS  JOIN top_priority p
CROSS  JOIN top_team     tt;