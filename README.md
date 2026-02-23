🚀 Enterprise KPI Anomaly Detection & Root Cause Analytics

SQL Server | Python | Power BI

End-to-end enterprise analytics project demonstrating modern data engineering, anomaly detection, and executive dashboarding using SQL Server, Python, and Power BI.

This project simulates a real enterprise KPI monitoring system used by leadership to detect anomalies, identify root causes, and make data-driven decisions in real time.

📌 Project Overview

This solution builds a centralized analytics platform that:

Designs a star schema data warehouse in SQL Server

Detects KPI anomalies using Python statistical modeling

Performs root cause analysis across business dimensions

Centralizes KPI logic in SQL views

Visualizes insights in executive Power BI dashboards

💼 What This Project Demonstrates

⭐ Star schema design for enterprise analytics (fact + dimension modeling)

🤖 Automated anomaly detection using statistical methods

🔎 Root cause analysis across store, product, and region

🧠 Centralized KPI logic using SQL views

🔗 Python pipeline integration with SQL Server

📊 Executive-ready interactive Power BI dashboard

📁 Clean repository structure and documentation

🏗 Architecture

SQL Server → Python Detection Engine → Root Cause Logging → Power BI Dashboard

SQL Server stores KPI and anomaly data

Python pipeline detects anomalies & logs root causes

Power BI connects to SQL views for visualization

📄 More details: docs/architecture.md

🗄 Data Model
Fact Tables

fact_kpi_metrics → Daily KPI metrics (revenue, profit, margin)

fact_anomalies → Detected anomalies with severity & deviation

fact_root_causes → Root cause contribution by store/product/region

Dimension Tables

dim_date

dim_regions

dim_stores

dim_products

Dataset Details

90 days of data

50 stores

100 products

~45,000 records

📊 KPI & Analytics Logic (SQL Views)

All KPIs are defined in SQL Server views to maintain a single source of truth.

Included KPIs

Total Revenue

Total Profit

Average Margin %

Daily KPI Trends

KPI by Region

KPI by Store

KPI by Product

Anomaly Count by Severity

Root Cause Contribution %

📍 Location: SQL/kpi_views.sql

🤖 Python Anomaly Detection Engine

Automated statistical anomaly detection pipeline integrated with SQL Server.

Detection Method

Rolling 28-day baseline

Z-score detection

Threshold: 2.5 standard deviations

Severity Classification

High

Medium

Low

Pipeline Flow

Load KPI data from SQL Server

Calculate rolling mean & standard deviation

Detect anomalies using Z-score

Identify root cause drivers

Log anomalies into database

Output

Detects anomalies in <10 seconds

Logs top contributing stores/products/regions

Fully automated detection system

📍 Location: Python/

📈 Power BI Executive Dashboard

Interactive executive dashboard built using SQL Server views.

Dashboard Highlights

KPI Cards: Revenue, Profit, Margin, Total Anomalies

Donut Chart: Anomalies by Severity

Bar Chart: Anomalies by KPI type

Trend Chart: KPI trends over time

Treemap: Root cause drivers (region/store/product)

Interactive slicers: Date & KPI type

Insights Provided

Detect KPI spikes and drops instantly

Identify root cause store/product/region

Filter by date, KPI, severity

Real-time executive KPI monitoring
