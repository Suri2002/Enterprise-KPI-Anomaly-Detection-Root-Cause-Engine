# Enterprise KPI Anomaly Detection & Root Cause Analytics
**SQL Server | Python | Power BI**

End-to-end enterprise analytics project demonstrating a star-schema warehouse in SQL Server, automated anomaly detection in Python, and executive dashboards in Power BI.

---

## What this project demonstrates
- Star schema design for analytics (facts + dimensions)
- Automated anomaly detection using statistical methods
- Root cause analysis across store, product, and region
- Centralized KPI logic using SQL views (single source of truth)
- Python pipeline integration with SQL Server
- Executive-ready interactive Power BI dashboard
- Clean repo structure + documentation

---

## Architecture
**SQL Server → Python Detection Engine → Root Cause Logging → Power BI Dashboard**

- SQL Server stores KPI and anomaly data
- Python pipeline detects anomalies and logs root causes
- Power BI connects to SQL views for visualization

More detail: **[docs/architecture.md](docs/architecture.md)**

---

## Data model

### Fact tables
- **fact_kpi_metrics** — Daily KPI metrics (revenue, profit, margin)
- **fact_anomalies** — Detected anomalies with severity and deviation
- **fact_root_causes** — Root-cause contribution by store/product/region

### Dimension tables
- **dim_date**
- **dim_regions**
- **dim_stores**
- **dim_products**

### Dataset
- 90 days of data
- 50 stores
- 100 products
- ~45,000 records

---

## KPI & analytics logic (SQL views)
KPIs are defined in SQL Server views to maintain a **single source of truth**.

**Included KPIs**
- Total Revenue
- Total Profit
- Avg Margin %
- Daily KPI Trends
- KPI by Region
- KPI by Store
- KPI by Product
- Anomaly Count by Severity
- Root Cause Contribution %

Location: **SQL/kpi_views.sql**

---

## Python anomaly detection engine
Automated statistical anomaly detection pipeline.

### Detection method
- Rolling 28-day baseline
- Z-score detection
- Threshold: 2.5 standard deviations

### Severity classification
- High
- Medium
- Low

### Pipeline flow
1. Load KPI data from SQL Server
2. Calculate rolling mean and standard deviation
3. Detect anomalies (Z-score)
4. Identify root-cause drivers
5. Log anomalies to database

### Output
- Detects anomalies in **< 10 seconds**
- Logs top contributing stores/products/regions
- Fully automated detection system

Location: **Python/**

---

## Power BI dashboard
Interactive executive dashboard built using SQL Server views.

### Dashboard highlights
- KPI Cards: Revenue, Profit, Margin, Total Anomalies
- Donut Chart: Anomalies by Severity
- Bar Chart: Anomalies by KPI type
- Trend Chart: KPI trends over time
- Treemap: Root-cause drivers (region/store/product)
- Interactive slicers: Date and KPI type

### Insights provided
- Detect KPI spikes/drops instantly
- Identify which store/product/region caused the anomaly
- Filter by date, KPI, severity
- Executive-level KPI monitoring

Screenshots: **screenshots/**

---

## How to run (rebuild from scratch)

### 1) Create database
Create a database named:
- **AnomalyDetectionDB**

### 2) Run schema
```sql
-- SQL/schema.sql
