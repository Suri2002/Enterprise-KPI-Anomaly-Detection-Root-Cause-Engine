# Enterprise KPI Anomaly Detection & Root Cause Analytics
**SQL Server | Python | Power BI**

End-to-end enterprise analytics project demonstrating a **star-schema data warehouse** in SQL Server, **automated KPI anomaly detection** in Python, and an **executive Power BI dashboard** for monitoring and root cause analysis.

---

## Table of Contents
- [What this project demonstrates](#what-this-project-demonstrates)
- [Architecture](#architecture)
- [Data model](#data-model)
- [KPI & analytics logic (SQL views)](#kpi--analytics-logic-sql-views)
- [Python anomaly detection engine](#python-anomaly-detection-engine)
- [Power BI dashboard](#power-bi-dashboard)
- [How to run](#how-to-run)
- [Tools & technologies](#tools--technologies)
- [Repository structure](#repository-structure)
- [Business value](#business-value)
- [Future enhancements](#future-enhancements)
- [Author](#author)

---

## What this project demonstrates
- Star schema design for analytics (fact + dimension modeling)
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
- Power BI consumes SQL views for visualization

More details: **[docs/architecture.md](docs/architecture.md)**

---

## Data model

### Fact tables
- **fact_kpi_metrics** — Daily KPI metrics (revenue, profit, margin)
- **fact_anomalies** — Detected anomalies with severity and deviation
- **fact_root_causes** — Root cause contribution by store/product/region

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
KPIs are defined in SQL Server using views to maintain a **single source of truth**.

### Included KPIs
- Total Revenue
- Total Profit
- Avg Margin %
- Daily KPI Trends
- KPI by Region
- KPI by Store
- KPI by Product
- Anomaly Count by Severity
- Root Cause Contribution %

Location: **`SQL/kpi_views.sql`**

---

## Python anomaly detection engine
Automated statistical anomaly detection pipeline integrated with SQL Server.

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
4. Identify root cause drivers
5. Log anomalies to database

### Output
- Detects anomalies in **< 10 seconds**
- Logs top contributing stores/products/regions
- Fully automated detection system

Location: **`Python/`**

---

## Power BI dashboard
Interactive executive dashboard built using SQL Server views.

### Dashboard highlights
- KPI Cards: Revenue, Profit, Margin, Total Anomalies
- Donut Chart: Anomalies by Severity
- Bar Chart: Anomalies by KPI type
- Trend Chart: KPI trends over time
- Treemap: Root cause drivers (region/store/product)
- Interactive slicers: Date and KPI type

### Insights provided
- Detect KPI spikes/drops instantly
- Identify which store or product caused the anomaly
- Filter by date, KPI, severity
- Executive-level KPI monitoring

Screenshots: **`screenshots/`**

---

## How to run

### 1) Create database
Create a database named: **`AnomalyDetectionDB`**

### 2) Run schema
Run:
- **`SQL/schema.sql`**

### 3) Load seed data
Run:
- **`SQL/seed_data.sql`**

### 4) Create views & procedures
Run:
- **`SQL/kpi_views.sql`**

### 5) Run Python pipeline
```bash
python Python/main_pipeline.py


├── SQL/
│   ├── schema.sql
│   ├── seed_data.sql
│   ├── kpi_views.sql
│   └── stored_procedures.sql
│
├── Python/
│   ├── config.py
│   ├── db_connector.py
│   ├── anomaly_detector.py
│   ├── root_cause_analyzer.py
│   └── main_pipeline.py
│
├── PowerBI/
│   └── dashboard.pbix
│
├── screenshots/
├── docs/
│   └── architecture.md
└── README.md
