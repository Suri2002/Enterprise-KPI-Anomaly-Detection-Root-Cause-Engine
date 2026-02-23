# Enterprise KPI Anomaly Detection & Root Cause Analytics
**SQL Server | Python | Power BI**

End-to-end enterprise analytics project demonstrating a **star-schema warehouse** in SQL Server, **automated KPI anomaly detection** in Python, and an **executive Power BI dashboard** for monitoring and root cause analysis.

---

## Overview
This project simulates an enterprise KPI monitoring system used by leadership to:
- Track revenue/profit/margin trends across stores, products, and regions
- Detect KPI spikes/drops automatically using statistical anomaly detection
- Identify root-cause drivers instantly (store/product/region contribution)
- Enable interactive investigation through an executive Power BI dashboard

---

## Key features
- Star schema data model (facts + dimensions) in SQL Server
- KPI definitions centralized in SQL views (single source of truth)
- Python anomaly detection engine (rolling baseline + Z-score)
- Root-cause attribution by store, product, and region
- Anomalies and contributors logged back to SQL Server
- Power BI dashboard for KPI monitoring and drill-down analysis

---

## Architecture
**SQL Server → Python Detection Engine → Root Cause Logging → Power BI Dashboard**

- SQL Server stores KPI and anomaly data (star schema)
- Python reads KPI time series from SQL views, detects anomalies, and writes results back
- Power BI consumes SQL views + anomaly tables for executive reporting

More details: **[docs/architecture.md](docs/architecture.md)**

---

## Data model

### Fact tables
- `fact_kpi_metrics` — Daily KPI metrics (revenue, profit, margin)
- `fact_anomalies` — Detected anomalies (severity, deviation, z-score)
- `fact_root_causes` — Root-cause contribution by store/product/region

### Dimension tables
- `dim_date`
- `dim_regions`
- `dim_stores`
- `dim_products`

### Dataset
- 90 days of data
- 50 stores
- 100 products
- ~45,000 records

---

## KPI logic (SQL views)
All KPIs are defined in SQL Server views to maintain a **single source of truth**.

### Included KPIs
- Total Revenue
- Total Profit
- Avg Margin %
- Daily KPI trends
- KPI by region/store/product
- Anomaly count by severity
- Root-cause contribution %

Location: `SQL/kpi_views.sql`

---

## Anomaly detection engine (Python)

### Method
- Rolling **28-day baseline**
- **Z-score** anomaly detection
- Threshold: **2.5 standard deviations**
- Severity classification: **Low / Medium / High**

### Pipeline flow
1. Load KPI time series from SQL Server
2. Compute rolling mean and standard deviation
3. Detect anomalies using Z-score thresholds
4. Identify top contributing drivers (region/store/product)
5. Log anomalies and root cause rows back to SQL Server

Location: `Python/`

---

## Power BI dashboard

### Dashboard highlights
- KPI cards: Revenue, Profit, Margin, Total Anomalies
- Trends: KPI trends over time with anomaly drill-down
- Donut: anomalies by severity
- Bar: anomalies by KPI type
- Treemap: root-cause drivers (region/store/product)
- Slicers: Date range, KPI type, severity

Screenshots: `screenshots/`

---

## How to run

### 1) Create database
Create a database named:
- `AnomalyDetectionDB`

### 2) Build schema
Run:
- `SQL/schema.sql`

### 3) Load seed data
Run:
- `SQL/seed_data.sql`

### 4) Create KPI views / procedures
Run:
- `SQL/kpi_views.sql`

### 5) Run Python pipeline
```bash
python Python/main_pipeline.py
```
## Power BI

### File
- `PowerBI/dashboard.pbix`

### Connection
- Connect Power BI to **SQL Server**
- Use the **SQL views** and anomaly tables as the reporting layer:
  - KPI views (single source of truth)
  - `fact_anomalies` (anomaly events)
  - `fact_root_causes` (top contributors)

### Recommended visuals
- KPI cards: Revenue, Profit, Margin, Total Anomalies
- Severity distribution: donut chart
- KPI anomaly breakdown: bar chart (by KPI type)
- Trends: line chart with date slicer
- Root cause: treemap (region/store/product)
- Slicers: Date range, KPI type, severity

---

## Tools & technologies

### Database
- SQL Server
- T-SQL
- Star schema modeling

### Analytics
- Python
- pandas
- numpy
- Statistical modeling (Z-score)

### Visualization
- Power BI
- DAX
- Interactive dashboard design

### Other
- GitHub
- VS Code

---

## Repository structure
```text
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
```
## Business value

### Before
- Manual KPI monitoring
- Delayed anomaly detection
- Root causes unclear

### After
- Automated anomaly detection in seconds
- Immediate root-cause attribution (store/product/region)
- Executive-ready KPI monitoring dashboard

---

## Future enhancements
- Email/Slack anomaly alerts
- ML-based detection (Isolation Forest / Prophet / LSTM)
- Real-time streaming pipeline
- Azure deployment
- Forecasting integration
- REST API for anomaly access

---

## Author
**Venkata Surya Prakash Gunji**  
MS in Information Technology — Arizona State University  
Data Analytics | BI Engineering | Data Engineering
