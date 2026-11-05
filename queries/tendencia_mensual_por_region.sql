WITH RECURSIVE months AS (
    -- Genera el primer día de cada mes del rango de interés
    SELECT DATE('2024-01-01') AS month_start
    UNION ALL
    SELECT DATE_ADD(month_start, INTERVAL 1 MONTH)
    FROM months
    WHERE month_start < DATE('2024-12-01')
),
regions AS (
    -- Universo de regiones: todas las que existen en el negocio
    SELECT DISTINCT region FROM dim_clientes
),
spine AS (
    -- Producto cartesiano regiones × meses = calendario completo
    SELECT r.region, m.month_start,
           YEAR(m.month_start)  AS periodo,
           MONTH(m.month_start) AS mes
    FROM regions r
    CROSS JOIN months m
),
sales AS (
    -- Ventas reales por región y mes
    SELECT 
        b.region,
        DATE_FORMAT(a.order_date, '%Y-%m-01') AS month_start,
        SUM(a.total_from_lines)               AS total_ventas
    FROM fact_pedidos a
    JOIN dim_clientes b ON a.customer_id = b.customer_id
    WHERE a.status = 'Entregado'
    GROUP BY b.region, DATE_FORMAT(a.order_date, '%Y-%m-01')
),
combined AS (
    -- LEFT JOIN + COALESCE: meses sin ventas se materializan con 0
    SELECT 
        s.region, s.periodo, s.mes,
        COALESCE(sl.total_ventas, 0) AS total_ventas
    FROM spine s
    LEFT JOIN sales sl
        ON sl.region = s.region
       AND sl.month_start = s.month_start
),
with_lag AS (
    SELECT 
        *,
        LAG(total_ventas) OVER (
            PARTITION BY region 
            ORDER BY periodo, mes
        ) AS total_ventas_mes_anterior,
        AVG(total_ventas) OVER (
            PARTITION BY region 
            ORDER BY periodo, mes 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS promedio_ventas_3_meses
    FROM combined
),
with_var AS (
    SELECT 
        *,
        (total_ventas - total_ventas_mes_anterior) 
            / NULLIF(total_ventas_mes_anterior, 0) * 100 
            AS variacion_porcentual
    FROM with_lag
)
SELECT 
    *,
    CASE 
        WHEN variacion_porcentual < -15 THEN 'Caída Crítica' 
        ELSE '' 
    END AS Bandera_Caida
FROM with_var
ORDER BY periodo DESC, mes DESC, region;