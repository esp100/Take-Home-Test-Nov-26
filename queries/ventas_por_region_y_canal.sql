SELECT region AS `Región`, 
        channel AS `Canal de venta`,
        SUM(`total_from_lines`) AS `Ventas totales de 2024`,
        COUNT(DISTINCT order_id) AS `Número de pedidos`, 
        SUM(`total_from_lines`)/COUNT(DISTINCT order_id) AS `Ticket promedio`
    FROM `fact_pedidos` a 
    JOIN `dim_clientes` b
    ON a.customer_id = b.customer_id
    WHERE `status` = "Entregado"
    AND YEAR(order_date) = 2024
    GROUP BY region, channel
    ORDER BY `Ventas totales de 2024`