##🚀 Enterprise KPI Anomaly Detection & Root Cause Engine

A complete end-to-end analytics system that automatically monitors business KPIs, detects anomalies using statistical methods, identifies root causes, and visualizes insights through an interactive Power BI dashboard.

This project simulates a real-world enterprise analytics solution used by data teams and business leaders to monitor performance and detect unusual trends instantly.

##🏗️ System Architecture
```text
SQL Server Data Warehouse
        ↓
Python Anomaly Detection Engine
        ↓
Root Cause Analysis + Logging
        ↓
Power BI Interactive Dashboard
```
##🎯 Project Objective

Build an automated analytics system that:

Monitors Revenue, Profit, and Margin

Detects anomalies using statistical methods

Identifies root cause drivers (store, product, region)

Logs anomalies automatically

Displays insights in an executive dashboard

##💾 Part 1: SQL Server Data Warehouse
Database Design (Star Schema)

Built using Kimball methodology.

Dimension Tables

Regions (5)

Stores (50)

Products (100)

Fact Tables

KPI Metrics (~45,000 records, 90 days)

Anomaly Logs

Root Cause Logs

Additional Components

7 analytical views

5 stored procedures

Indexed relationships

Realistic anomaly-injected data

✔ Production-style mini data warehouse ready for analytics.

##🐍 Part 2: Python Anomaly Detection Engine
Tech Used

Python

pandas

numpy

SQL Server (pyodbc)

Detection Method

Rolling 28-day baseline

Z-score statistical detection

Threshold: 2.5 standard deviations

Severity levels: High, Medium, Low

Pipeline Steps

Load KPI data from SQL Server

Calculate rolling mean & standard deviation

Detect anomalies

Identify root causes (store/product/region contribution)

Log anomalies back to database

Performance

Processes ~45K records

Runs in under 10 seconds

Detects and explains anomalies automatically

✔ Not only detects issues — explains why they happened.

##📊 Part 3: Power BI Dashboard (Final Output)

This dashboard provides executive-level insights into business KPIs and anomalies.

According to the dashboard view:

Total Revenue: $14.7M

Total Profit: $4.3M

Avg Margin: 29.6%

Total Anomalies: 5 

KPI_Anomaly_Detection_Dashboard…

##📌 Dashboard Components
🔹 KPI Cards (Top Section)

Total Revenue

Total Profit

Average Margin %

Total Anomalies

Quick executive summary of business performance.

🔹 Donut Chart — Anomalies by Severity

Shows anomaly distribution:

Medium: 80%

High: 20%

Helps identify risk level quickly.

🔹 Bar Chart — Anomalies by KPI & Severity

Breakdown of anomalies across:

Revenue

Profit

Margin

Severity level

Used to identify which KPI is most impacted.

🔹 Revenue Trend Chart

Displays:

Revenue trend over time

KPI comparison (Revenue, Profit, Margin)

Date-based anomaly tracking

Helps detect spikes, drops, and trends visually.

🔹 Root Cause Drivers Treemap

Shows contribution of:

Regions

Stores

Products

Example insights:

Which store drove anomaly

Which region contributed most

Which product impacted KPI

This allows instant root cause visibility.

🔹 Interactive Filters (Slicers)

Users can filter dashboard by:

Date range

KPI type (Revenue, Profit, Margin)

All visuals update dynamically.

##🔄 End-to-End Workflow

SQL Server stores KPI data

Python pipeline runs

Detects anomalies statistically

Finds root causes

Logs results in database

Power BI refreshes

Dashboard shows insights

##💡 Business Value
Before This System

Manual KPI monitoring

Late anomaly detection

Unknown root causes

Slow decision making

After This System

Automated detection in seconds

Instant root cause identification

Real-time KPI monitoring

Executive-ready dashboard

Example:

Revenue spike detected → System shows Store_043 caused 32% of increase.

##🛠 Technologies Used
Database

SQL Server

T-SQL

Star Schema Modeling

Analytics

Python

pandas

numpy

Statistical Z-score detection

Visualization

Power BI

DAX measures

Interactive filtering

Treemap & KPI cards

##📈 System Capabilities
Feature	Value
KPIs monitored	3
Stores analyzed	50
Products analyzed	100
Data processed	~45K records
Detection time	<10 sec
Detection method	Z-score
Dashboard	Interactive Power BI
##🎯 Skills Demonstrated

Data Engineering

Data Warehousing (Star Schema)

Python Analytics Automation

Statistical Modeling

Root Cause Analysis

Power BI Dashboarding

Business Intelligence Engineering

End-to-End Analytics Pipeline

##🚀 Future Enhancements

Email/Slack anomaly alerts

Machine learning anomaly detection

Real-time streaming pipeline

Azure cloud deployment

Forecasting integration

REST API for anomaly data

##👨‍💻 Author

Venkata Surya Prakash Gunji
MS in Information Technology – ASU
Data Analytics | BI Engineering | Data Engineering

##⭐ Final Result

A complete enterprise-grade KPI monitoring and anomaly detection system that automatically identifies:

What went wrong → Why it happened → Where it happened → Visualized instantly
