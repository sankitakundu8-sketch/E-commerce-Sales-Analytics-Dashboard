/* =====================================================================
   E-COMMERCE SALES ANALYTICS - SQL ANALYSIS (main analysis layer)
   Table  : ecommerce_sales  (import data/ecommerce_sales.csv)
   Dialect: SQLite (DB Browser for SQLite / sqlite3).
            MySQL: replace strftime('%Y-%m', Order_Date) with
                   DATE_FORMAT(Order_Date, '%Y-%m')
   Sections: A. KPIs | B. Time Trends | C. Products | D. Category & Region
             E. Customers | F. Discount & Loss | G. Business Questions
   ===================================================================== */

-- Optional table definition
-- CREATE TABLE ecommerce_sales (
--   Order_ID TEXT PRIMARY KEY, Order_Date DATE, Customer_ID TEXT, Product TEXT,
--   Category TEXT, Region TEXT, City TEXT, Quantity INTEGER, Unit_Price REAL,
--   Discount REAL, Sales REAL, Cost REAL, Profit REAL, Payment_Mode TEXT);

/* ---------------------- A. KPIs ---------------------- */

-- Q1. Headline KPIs in one row
SELECT ROUND(SUM(Sales), 2)                        AS total_sales,
       ROUND(SUM(Profit), 2)                       AS total_profit,
       COUNT(DISTINCT Order_ID)                    AS total_orders,
       COUNT(DISTINCT Customer_ID)                 AS total_customers,
       ROUND(SUM(Profit) * 100.0 / SUM(Sales), 2)  AS profit_margin_pct,
       ROUND(SUM(Sales) / COUNT(Order_ID), 2)      AS avg_order_value
FROM ecommerce_sales;

/* ---------------------- B. TIME TRENDS ---------------------- */

-- Q2. Monthly sales, profit and margin
SELECT strftime('%Y-%m', Order_Date)               AS month,
       ROUND(SUM(Sales), 2)                        AS monthly_sales,
       ROUND(SUM(Profit), 2)                       AS monthly_profit,
       ROUND(SUM(Profit) * 100.0 / SUM(Sales), 2)  AS margin_pct
FROM ecommerce_sales
GROUP BY month
ORDER BY month;

-- Q3. Month-over-month sales growth (window function: LAG)
WITH monthly AS (
    SELECT strftime('%Y-%m', Order_Date) AS month, SUM(Sales) AS sales
    FROM ecommerce_sales
    GROUP BY month
)
SELECT month,
       ROUND(sales, 2) AS sales,
       ROUND((sales - LAG(sales) OVER (ORDER BY month)) * 100.0
             / LAG(sales) OVER (ORDER BY month), 2) AS mom_growth_pct
FROM monthly
ORDER BY month;

-- Q4. Running (cumulative) sales (window function: SUM OVER)
WITH monthly AS (
    SELECT strftime('%Y-%m', Order_Date) AS month, SUM(Sales) AS sales
    FROM ecommerce_sales
    GROUP BY month
)
SELECT month,
       ROUND(sales, 2) AS sales,
       ROUND(SUM(sales) OVER (ORDER BY month), 2) AS cumulative_sales
FROM monthly
ORDER BY month;

-- Q5. Year-over-year performance
SELECT strftime('%Y', Order_Date)  AS year,
       ROUND(SUM(Sales), 2)        AS total_sales,
       ROUND(SUM(Profit), 2)       AS total_profit,
       COUNT(*)                    AS orders
FROM ecommerce_sales
GROUP BY year
ORDER BY year;

-- Q6. Best and worst month by sales
WITH monthly AS (
    SELECT strftime('%Y-%m', Order_Date) AS month, ROUND(SUM(Sales), 2) AS sales
    FROM ecommerce_sales
    GROUP BY month
)
SELECT 'Best' AS type, month, sales
FROM (SELECT * FROM monthly ORDER BY sales DESC LIMIT 1)
UNION ALL
SELECT 'Worst', month, sales
FROM (SELECT * FROM monthly ORDER BY sales ASC LIMIT 1);

/* ---------------------- C. PRODUCTS ---------------------- */

-- Q7. Top 5 products by profit
SELECT Product,
       ROUND(SUM(Sales), 2)  AS total_sales,
       ROUND(SUM(Profit), 2) AS total_profit
FROM ecommerce_sales
GROUP BY Product
ORDER BY total_profit DESC
LIMIT 5;

-- Q8. Worst 5 products by profit margin
SELECT Product,
       ROUND(SUM(Sales), 2)                        AS total_sales,
       ROUND(SUM(Profit) * 100.0 / SUM(Sales), 2)  AS margin_pct
FROM ecommerce_sales
GROUP BY Product
ORDER BY margin_pct ASC
LIMIT 5;

-- Q9. Top 2 products inside each category (window function: RANK)
WITH ranked AS (
    SELECT Category, Product,
           ROUND(SUM(Profit), 2) AS profit,
           RANK() OVER (PARTITION BY Category ORDER BY SUM(Profit) DESC) AS rnk
    FROM ecommerce_sales
    GROUP BY Category, Product
)
SELECT Category, Product, profit, rnk
FROM ranked
WHERE rnk <= 2
ORDER BY Category, rnk;

/* ---------------------- D. CATEGORY & REGION ---------------------- */

-- Q10. Category performance with share of total sales
SELECT Category,
       COUNT(*)                                          AS orders,
       ROUND(SUM(Sales), 2)                              AS total_sales,
       ROUND(SUM(Profit), 2)                             AS total_profit,
       ROUND(SUM(Profit) * 100.0 / SUM(Sales), 2)        AS margin_pct,
       ROUND(SUM(Sales) * 100.0 / (SELECT SUM(Sales) FROM ecommerce_sales), 2) AS sales_share_pct
FROM ecommerce_sales
GROUP BY Category
ORDER BY total_sales DESC;

-- Q11. Best category by profit
SELECT Category, ROUND(SUM(Profit), 2) AS total_profit
FROM ecommerce_sales
GROUP BY Category
ORDER BY total_profit DESC
LIMIT 1;

-- Q12. Regional performance
SELECT Region,
       COUNT(*)                                    AS orders,
       ROUND(SUM(Sales), 2)                        AS total_sales,
       ROUND(SUM(Profit), 2)                       AS total_profit,
       ROUND(SUM(Profit) * 100.0 / SUM(Sales), 2)  AS margin_pct
FROM ecommerce_sales
GROUP BY Region
ORDER BY total_sales DESC;

-- Q13. Top 5 cities by sales
SELECT City, Region, ROUND(SUM(Sales), 2) AS total_sales
FROM ecommerce_sales
GROUP BY City, Region
ORDER BY total_sales DESC
LIMIT 5;

-- Q14. Category x Region sales matrix (CASE pivot)
SELECT Category,
       ROUND(SUM(CASE WHEN Region = 'North' THEN Sales ELSE 0 END), 0) AS north,
       ROUND(SUM(CASE WHEN Region = 'South' THEN Sales ELSE 0 END), 0) AS south,
       ROUND(SUM(CASE WHEN Region = 'East'  THEN Sales ELSE 0 END), 0) AS east,
       ROUND(SUM(CASE WHEN Region = 'West'  THEN Sales ELSE 0 END), 0) AS west
FROM ecommerce_sales
GROUP BY Category
ORDER BY Category;

/* ---------------------- E. CUSTOMERS ---------------------- */

-- Q15. Top 10 customers by sales
SELECT Customer_ID,
       COUNT(*)              AS orders,
       ROUND(SUM(Sales), 2)  AS total_sales,
       ROUND(SUM(Profit), 2) AS total_profit
FROM ecommerce_sales
GROUP BY Customer_ID
ORDER BY total_sales DESC
LIMIT 10;

-- Q16. Customer segments by spend (CTE + CASE)
WITH cust AS (
    SELECT Customer_ID, SUM(Sales) AS spend, COUNT(*) AS orders
    FROM ecommerce_sales
    GROUP BY Customer_ID
)
SELECT CASE WHEN spend >= 150000 THEN 'High Value'
            WHEN spend >= 50000  THEN 'Mid Value'
            ELSE 'Low Value' END       AS segment,
       COUNT(*)                        AS customers,
       ROUND(SUM(spend), 2)            AS total_sales,
       ROUND(AVG(orders), 1)           AS avg_orders
FROM cust
GROUP BY segment
ORDER BY total_sales DESC;

-- Q17. One-time vs repeat customers
WITH cust AS (
    SELECT Customer_ID, COUNT(*) AS orders FROM ecommerce_sales GROUP BY Customer_ID
)
SELECT CASE WHEN orders = 1 THEN 'One-time' ELSE 'Repeat' END AS customer_type,
       COUNT(*) AS customers,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM cust), 1) AS pct
FROM cust
GROUP BY customer_type;

-- Q18. Revenue share of top 20% customers (NTILE)
WITH cust AS (
    SELECT Customer_ID, SUM(Sales) AS spend FROM ecommerce_sales GROUP BY Customer_ID
),
tiles AS (
    SELECT spend, NTILE(5) OVER (ORDER BY spend DESC) AS tile FROM cust
)
SELECT ROUND(SUM(CASE WHEN tile = 1 THEN spend END) * 100.0 / SUM(spend), 1) AS top20_customers_sales_pct
FROM tiles;

/* ---------------------- F. DISCOUNT & LOSS ---------------------- */

-- Q19. Discount impact on profit margin
SELECT ROUND(Discount * 100)                       AS discount_pct,
       COUNT(*)                                    AS orders,
       ROUND(SUM(Sales), 2)                        AS total_sales,
       ROUND(SUM(Profit), 2)                       AS total_profit,
       ROUND(SUM(Profit) * 100.0 / SUM(Sales), 2)  AS margin_pct
FROM ecommerce_sales
GROUP BY Discount
ORDER BY Discount;

-- Q20. Discount impact by category (average margin per order)
SELECT Category,
       ROUND(AVG(CASE WHEN Discount <= 0.05 THEN Profit * 100.0 / Sales END), 1) AS margin_low_discount,
       ROUND(AVG(CASE WHEN Discount >= 0.20 THEN Profit * 100.0 / Sales END), 1) AS margin_high_discount
FROM ecommerce_sales
GROUP BY Category
ORDER BY Category;

-- Q21. Loss-making products (orders sold below cost)
SELECT Product,
       COUNT(*)                      AS loss_orders,
       ROUND(SUM(Profit), 2)         AS total_loss,
       ROUND(AVG(Discount) * 100, 1) AS avg_discount_pct
FROM ecommerce_sales
WHERE Profit < 0
GROUP BY Product
ORDER BY total_loss ASC;

-- Q22. Loss orders overall: count, value, share of orders
SELECT COUNT(*)                                                   AS loss_orders,
       ROUND(SUM(Profit), 2)                                      AS total_loss,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM ecommerce_sales), 2) AS pct_of_orders
FROM ecommerce_sales
WHERE Profit < 0;

/* ---------------------- G. BUSINESS QUESTIONS ---------------------- */

-- Q23. Festive season (Oct-Dec) share of annual sales
SELECT ROUND(SUM(CASE WHEN CAST(strftime('%m', Order_Date) AS INTEGER) IN (10, 11, 12)
                      THEN Sales END) * 100.0 / SUM(Sales), 1) AS festive_sales_pct
FROM ecommerce_sales;

-- Q24. Payment mode share of sales
SELECT Payment_Mode,
       COUNT(*)                                                                 AS orders,
       ROUND(SUM(Sales) * 100.0 / (SELECT SUM(Sales) FROM ecommerce_sales), 1)  AS sales_share_pct
FROM ecommerce_sales
GROUP BY Payment_Mode
ORDER BY sales_share_pct DESC;

-- Q25. Products where profit share is far below sales share (margin drag)
WITH p AS (
    SELECT Product,
           SUM(Sales)  * 100.0 / (SELECT SUM(Sales)  FROM ecommerce_sales) AS sales_share,
           SUM(Profit) * 100.0 / (SELECT SUM(Profit) FROM ecommerce_sales) AS profit_share
    FROM ecommerce_sales
    GROUP BY Product
)
SELECT Product,
       ROUND(sales_share, 1)  AS sales_share_pct,
       ROUND(profit_share, 1) AS profit_share_pct,
       ROUND(sales_share - profit_share, 1) AS gap
FROM p
ORDER BY gap DESC
LIMIT 5;
