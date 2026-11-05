WITH CUSTOMER_TOTAL AS (
    SELECT 
        a.customer_id,
        customer_name,
        product_name,
        category, 
        SUM(line_amount) AS customer_product_total,
        SUM(SUM(line_amount)) OVER (PARTITION BY a.customer_id) AS customer_total
    FROM `dim_clientes` a
    JOIN `fact_pedidos` b       ON a.customer_id = b.customer_id
    JOIN `fact_lineas_pedido` c ON c.order_id = b.order_id
    JOIN `dim_productos` d      ON c.product_id = d.product_id
    WHERE b.status = 'Entregado'
    GROUP BY a.customer_id, d.product_id, customer_name, product_name, category
),
RANKED AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id 
            ORDER BY customer_product_total DESC, 
                     product_name ASC, 
                     category ASC
        ) AS ranking,
        SAFE_DIVIDE(customer_product_total, customer_total) * 100 AS pct_cliente
    FROM CUSTOMER_TOTAL
)
SELECT 
    customer_id,
    customer_name,
    ranking,
    product_name,
    category, 
    customer_product_total,
    pct_cliente
FROM RANKED
WHERE ranking <= 3
ORDER BY customer_id, ranking