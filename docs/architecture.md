# Architecture — Enterprise KPI Anomaly Detection & Root Cause Analytics

This document describes the end-to-end architecture for KPI monitoring, anomaly detection, and root cause analytics using **SQL Server**, **Python**, and **Power BI**.

---

## High-level flow

**SQL Server → Python Detection Engine → Root Cause Logging → Power BI Dashboard**

1. **SQL Server (Warehouse + KPI logic)**
   - Stores dimension and fact tables in a star schema
   - Centralizes KPI calculations using SQL views for a single source of truth

2. **Python Detection Engine**
   - Loads KPI time series from SQL views
   - Detects anomalies using a rolling baseline + Z-score
   - Identifies contributing drivers (store/product/region)
   - Logs anomalies and root cause contributions back to SQL Server

3. **Power BI**
   - Connects to SQL Server views/fact tables
   - Provides interactive executive reporting and anomaly drill-down

---

## Components

### 1) SQL Server (Data Warehouse)
**Purpose:** Analytics-ready data model + centralized KPI definitions.

**Key elements**
- Star schema: fact tables for measures, dimension tables for slicing
- Views to standardize KPIs and ensure consistent logic across tools

**Primary tables**
- `fact_kpi_metrics` — daily KPI measures per grain (date, store, product, region)
- `fact_anomalies` — anomaly events with severity, deviation metrics, timestamps
- `fact_root_causes` — top contributors by store/product/region for each anomaly

**Dimensions**
- `dim_date`
- `dim_regions`
- `dim_stores`
- `dim_products`

**KPI Views**
- Stored in: `SQL/kpi_views.sql`
- Examples:
  - Total Revenue
  - Total Profit
  - Avg Margin %
  - KPI trends (daily)
  - KPI by Region/Store/Product
  - Anomaly counts by severity

---

### 2) Python Detection Engine
**Purpose:** Automated anomaly detection + root cause attribution.

**Location:** `Python/`

**Core modules (recommended roles)**
- `db_connector.py` — SQL Server connection + read/write helpers
- `anomaly_detector.py` — rolling baseline + Z-score anomaly detection
- `root_cause_analyzer.py` — contributor analysis by region/store/product
- `main_pipeline.py` — pipeline orchestration

---

## Anomaly detection method

### Baseline window
- Rolling **28-day** baseline for each KPI
- Computes:
  - rolling mean (μ)
  - rolling standard deviation (σ)

### Detection logic (Z-score)
For each day:
- `z = (value - μ) / σ`
- Flag anomaly if:
- `|z| >= 2.5`

### Severity classification (example)
Severity is derived from Z-score magnitude:
- **High:** `|z| >= 4.0`
- **Medium:** `3.0 <= |z| < 4.0`
- **Low:** `2.5 <= |z| < 3.0`

> You can tune these thresholds based on business tolerance.

---

## Root cause analysis method

When an anomaly is detected for a KPI on a given date:

1. Pull the KPI breakdown for that date by:
   - Region
   - Store
   - Product

2. Compute contribution of each dimension member using one of:
   - **Absolute contribution:** `member_value`
   - **Delta contribution:** `member_value - rolling_baseline_member_value`
   - **Percent contribution:** `member_delta / total_delta`

3. Rank contributors and store the top N (e.g., top 3–10) in `fact_root_causes`.

**Output example**
- Anomaly: Revenue spike on 2026-01-18
- Top drivers:
  - Store: S-024 (+18%)
  - Product: P-087 (+11%)
  - Region: West (+9%)

---

## Data written back to SQL Server

### `fact_anomalies` (example fields)
- anomaly_id
- date_key / anomaly_date
- kpi_name
- actual_value
- rolling_mean
- rolling_std
- z_score
- deviation_pct
- severity
- created_at

### `fact_root_causes` (example fields)
- anomaly_id
- dimension_type (Region/Store/Product)
- dimension_key
- contributor_value
- contributor_delta
- contribution_pct
- rank
- created_at

---

## Power BI integration

**Connection**
- Power BI connects directly to SQL Server
- Recommended: Use KPI views as the semantic source

**Suggested model**
- Import or DirectQuery (based on scale)
- Use relationships:
  - facts → dimensions (star schema)
- Build measures and visuals on top of view outputs + anomaly tables

**Dashboard capabilities**
- KPI cards (Revenue/Profit/Margin/Anomalies)
- Trends with anomaly markers
- Severity distribution (donut)
- KPI type breakdown (bar)
- Root cause treemap (region/store/product)
- Slicers: date range, KPI, severity

---

## Performance notes
- Dataset size (~45k) supports fast detection and dashboard refresh
- Python pipeline detects anomalies in **<10 seconds** on local SQL Server
- For larger datasets:
  - index fact tables on date_key, store_key, product_key, region_key
  - pre-aggregate KPI time series in views
  - consider incremental refresh in Power BI

---

## Extensibility roadmap
- Real-time alerts via Email/Slack
- Replace Z-score with ML detection (Isolation Forest, Prophet, LSTM)
- Streaming ingestion + near real-time detection
- Azure deployment (Azure SQL + Functions + Power BI Service)
- REST API for anomalies and root cause endpoints

---

## How to run (quick reference)
1. Create DB: `AnomalyDetectionDB`
2. Run schema: `SQL/schema.sql`
3. Seed data: `SQL/seed_data.sql`
4. Create views: `SQL/kpi_views.sql`
5. Run pipeline: `python Python/main_pipeline.py`
6. Open Power BI: `PowerBI/dashboard.pbix`
