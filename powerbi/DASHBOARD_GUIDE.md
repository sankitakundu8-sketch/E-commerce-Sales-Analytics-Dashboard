# Power BI Build Guide (about 30 minutes)

Save the finished file as `powerbi/dashboard.pbix`, then export the page as an image to `screenshots/dashboard.png`.

## 1. Load data
Home > Get Data > Text/CSV > `data/ecommerce_sales.csv` > Transform Data.
- Set `Order_Date` to **Date**; `Quantity` to **Whole Number**; `Unit_Price`, `Discount`, `Sales`, `Cost`, `Profit` to **Decimal Number**.
- Close & Apply.

## 2. Create a Date table (Modeling > New Table)
```DAX
Calendar =
ADDCOLUMNS (
    CALENDAR ( DATE ( 2024, 1, 1 ), DATE ( 2025, 12, 31 ) ),
    "Year", YEAR ( [Date] ),
    "Month No", MONTH ( [Date] ),
    "Month", FORMAT ( [Date], "MMM yy" )
)
```
Sort `Month` by `Month No`. Relate `Calendar[Date]` to `ecommerce_sales[Order_Date]` (one-to-many).

## 3. Measures (Modeling > New Measure)
```DAX
Total Sales      = SUM ( ecommerce_sales[Sales] )
Total Profit     = SUM ( ecommerce_sales[Profit] )
Total Orders     = DISTINCTCOUNT ( ecommerce_sales[Order_ID] )
Total Customers  = DISTINCTCOUNT ( ecommerce_sales[Customer_ID] )
Profit Margin %  = DIVIDE ( [Total Profit], [Total Sales] )
```

## 4. Page layout (16:9, 1280 x 720, View > Page View > Fit to page)
| Area | Visual | Fields |
|---|---|---|
| Top bar | Title text box + 3 slicers | Date (between), Category, Region (dropdown style) |
| Row 1 | 5 **Card** visuals | Total Sales, Total Profit, Total Orders, Total Customers, Profit Margin % |
| Row 2 left | **Line / area chart** | X: Calendar[Month], Y: Total Sales |
| Row 2 right | **Line chart** | X: Calendar[Month], Y: Total Profit |
| Row 3 left | **Bar chart** | Y: Category, X: Total Sales |
| Row 3 middle | **Column chart** | X: Region, Y: Total Sales |
| Row 3 right | **Bar chart** (Top N filter = 6 by Total Profit) | Y: Product, X: Total Profit |

## 5. Styling
- Canvas background: light grey `#F3F5F8`; title bar: navy `#12263F`.
- Visual backgrounds: white, rounded corners, light border.
- Colours: blue `#1F4E79` for sales, teal `#2A9D8F` for profit.
- Remove gridlines and extra axis titles. Format cards with display units (Thousands/Lakhs).
- Keep everything on one page, no scrolling.

## 6. Extra DAX (optional, impressive)
```DAX
Sales LY   = CALCULATE ( [Total Sales], SAMEPERIODLASTYEAR ( 'Calendar'[Date] ) )
YoY Growth % = DIVIDE ( [Total Sales] - [Sales LY], [Sales LY] )
Loss Orders  = CALCULATE ( [Total Orders], ecommerce_sales[Profit] < 0 )
Avg Order Value = DIVIDE ( [Total Sales], [Total Orders] )
```
Add a **Discount vs Margin** column chart: X = Discount, Y = Profit Margin %.
Use `data/ecommerce_sales_clean.csv` if you want ready-made `Year_Month`, `Discount_Band` and `Is_Loss` columns.
