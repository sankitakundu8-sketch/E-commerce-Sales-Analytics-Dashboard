# Tableau Part (Tableau Public is free)

Build the dashboard, publish to Tableau Public, and paste the public link into the README.
Data source: `data/ecommerce_sales_clean.csv`

## 1. Connect
Open Tableau Public > Connect > Text file > `ecommerce_sales_clean.csv`.
Check that `Order_Date` is **Date**; `Sales`, `Profit`, `Cost` are **Number (decimal)**.

## 2. Calculated Fields (Analysis > Create Calculated Field)
```
Profit Margin   = SUM([Profit]) / SUM([Sales])
Total Orders    = COUNTD([Order_ID])
Total Customers = COUNTD([Customer_ID])
Loss Flag       = IF [Profit] < 0 THEN "Loss" ELSE "Profit" END
Sales LY        = LOOKUP(SUM([Sales]), -12)
YoY Growth %    = (SUM([Sales]) - [Sales LY]) / [Sales LY]
```

## 3. Sheets (create each on its own tab)
| Sheet name | Build |
|---|---|
| KPI Sales / Profit / Orders / Customers / Margin | Drag measure to Text; format with large font |
| Sales Trend | Columns: MONTH(Order_Date) continuous; Rows: SUM(Sales); line chart |
| Profit Trend | Same with SUM(Profit); colour teal |
| Category Performance | Rows: Category; Columns: SUM(Sales); colour by Profit Margin |
| Regional Map | Double-click `City` to map (or use `Region` bars); size by Sales |
| Top Products | Rows: Product; Columns: SUM(Profit); sort descending; Top 6 filter |
| Discount vs Margin | Columns: Discount_Band; Rows: Profit Margin; bar chart (red for low) |

## 4. Dashboard (Dashboard > New Dashboard, size: Automatic or 1200 x 800)
1. Top: title + 5 KPI sheets in a horizontal container.
2. Middle: Sales Trend and Profit Trend side by side.
3. Bottom: Category, Regional, Top Products, Discount vs Margin.
4. Add filters (drop-down, apply to all sheets): `Order_Date`, `Category`, `Region`.
5. Dashboard > Actions > Filter: click a category to filter other charts.

## 5. Publish
File > Save to Tableau Public. Copy the link into README under **Dashboard**.
Export a PNG (Dashboard > Export Image) to `screenshots/tableau_dashboard.png`.
