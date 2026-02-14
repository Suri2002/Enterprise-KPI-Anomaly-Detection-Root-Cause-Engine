"""
main_pipeline.py - Main Execution Pipeline
==========================================
Orchestrates the end-to-end KPI anomaly detection workflow.
"""

import sys
from datetime import datetime, timedelta

import pandas as pd

from config import KPIS_TO_MONITOR, DATA_LOAD_DAYS
from db_connector import AnomalyDBConnector
from anomaly_detector import KPIAnomalyDetector
from root_cause_analyzer import RootCauseAnalyzer


def main() -> None:
    """Execute the Enterprise KPI Anomaly Detection pipeline."""

    # Banner
    print("=" * 70)
    print("   ENTERPRISE KPI ANOMALY DETECTION PIPELINE")
    print("=" * 70)
    print(f"  Run started : {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    # ------------------------------------------------------------------
    # STEP 1: Initialize
    # ------------------------------------------------------------------
    print("=" * 70)
    print("  STEP 1 — INITIALIZATION")
    print("=" * 70)
    
    db = AnomalyDBConnector()
    detector = KPIAnomalyDetector(sensitivity="medium")
    analyzer = RootCauseAnalyzer()
    
    # ------------------------------------------------------------------
    # STEP 2: Test Connection
    # ------------------------------------------------------------------
    print()
    print("=" * 70)
    print("  STEP 2 — DATABASE CONNECTION")
    print("=" * 70)
    
    if not db.test_connection():
        print()
        print("  ✗ Cannot proceed. Exiting.")
        sys.exit(1)
    
    # ------------------------------------------------------------------
    # STEP 3: Load Data
    # ------------------------------------------------------------------
    print()
    print("=" * 70)
    print("  STEP 3 — DATA LOADING")
    print("=" * 70)
    
    target_date = datetime.today()
    start_date = target_date - timedelta(days=DATA_LOAD_DAYS)
    
    print(f"  Date range  : {start_date.strftime('%Y-%m-%d')} → {target_date.strftime('%Y-%m-%d')}")
    
    data = db.load_kpi_data(start_date, target_date)
    
    if data.empty:
        print("  ✗ No data returned. Exiting.")
        sys.exit(1)
    
    print(f"  ✓ Loaded {len(data):,} records")

    # ------------------------------------------------------------------
    # STEP 4: Detect Anomalies
    # ------------------------------------------------------------------
    print()
    print("=" * 70)
    print("  STEP 4 — ANOMALY DETECTION")
    print("=" * 70)

    total_anomalies = 0
    anomalies_by_kpi = {}  # Track anomalies per KPI for summary

    # Show data date range
    min_date = data['metric_date'].min()
    max_date = data['metric_date'].max()
    print(f"  Data range: {min_date.date()} → {max_date.date()}")
    print()

    for kpi in KPIS_TO_MONITOR:
        print(f"  {kpi.upper()}")
        print("  " + "-" * 66)

        kpi_anomaly_count = 0  # Track per-KPI count

        # Aggregate daily
        daily_data = data.groupby("metric_date")[kpi].sum().reset_index()

        # Detect anomalies
        anomalies = detector.detect_anomalies(
            df=daily_data,
            kpi_column=kpi,
            date_column="metric_date"
        )

        if anomalies.empty:
            print("  No anomalies detected.")
            print()
            continue

        print(f"  Found {len(anomalies)} anomaly/anomalies to process...\n")

        # Process ALL detected anomalies (not just today's)
        for _, row in anomalies.iterrows():
            # Build record
            anomaly_record = {
                "kpi_name": kpi,
                "metric_date": row["metric_date"].date(),
                "expected_value": round(float(row["expected_value"]), 2),
                "actual_value": round(float(row["actual_value"]), 2),
                "deviation_percent": round(float(row["deviation_percent"]), 2),
                "z_score": round(float(row["z_score"]), 4),
                "severity": row["severity"],
            }

            # Log anomaly
            anomaly_id = db.log_anomaly(anomaly_record)

            if anomaly_id:
                deviation_sign = "+" if row["deviation_percent"] > 0 else ""
                print(
                    f"  ✓ Anomaly #{anomaly_id}"
                    f"  |  Date: {row['metric_date'].date()}"
                    f"  |  Severity: {row['severity']:<8}"
                    f"  |  Deviation: {deviation_sign}{row['deviation_percent']:.1f}%"
                )
                print(f"     Expected: ${row['expected_value']:,.2f}  |  Actual: ${row['actual_value']:,.2f}")

                # Root cause analysis
                root_causes = analyzer.find_root_causes(
                    full_data=data,
                    anomaly_date=row["metric_date"],
                    kpi_col=kpi
                )

                # Build driver records
                drivers = []
                for driver_type, drivers_df in root_causes.items():
                    dim_map = {
                        "store": ("store_id", "store_name"),
                        "product": ("product_id", "product_name"),
                        "region": ("region_id", "region_name"),
                    }
                    id_col, name_col = dim_map[driver_type]

                    for _, d_row in drivers_df.iterrows():
                        drivers.append({
                            "anomaly_id": anomaly_id,
                            "driver_type": driver_type,
                            "entity_id": int(d_row[id_col]),
                            "entity_name": str(d_row[name_col]),
                            "contribution_percent": round(float(d_row["contribution_percent"]), 2),
                            "impact_value": round(float(d_row["impact_value"]), 2),
                        })

                if drivers:
                    db.log_root_causes(drivers)
                    print(f"     ✓ Logged {len(drivers)} root cause(s)")

                    # Show top 3
                    print("     Top contributors:")
                    for i, d in enumerate(drivers[:3], 1):
                        contrib_sign = "+" if d['contribution_percent'] > 0 else ""
                        print(f"       {i}. {d['entity_name']}: {contrib_sign}{d['contribution_percent']:.1f}%")

                print()  # Blank line between anomalies
                
                # Increment counters
                kpi_anomaly_count += 1
                total_anomalies += 1
            else:
                print(f"  ✗ Failed to log anomaly for {kpi}")

        # Store per-KPI count after processing all anomalies for this KPI
        if kpi_anomaly_count > 0:
            anomalies_by_kpi[kpi] = kpi_anomaly_count
        
        print()  # End of KPI section

    # ------------------------------------------------------------------
    # STEP 5: Summary
    # ------------------------------------------------------------------
    print("=" * 70)
    print("  STEP 5 — SUMMARY")
    print("=" * 70)
    print()
    
    if total_anomalies > 0:
        print(f"  Total anomalies detected and logged: {total_anomalies}")
        print()
        print("  Breakdown by KPI:")
        for kpi_name, count in anomalies_by_kpi.items():
            print(f"    • {kpi_name}: {count} anomaly/anomalies")
    else:
        print("  No anomalies detected across all KPIs.")
    
    print()
    print("=" * 70)
    print(f"  ✓ Pipeline Complete")
    print(f"  Finished at : {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 70)


if __name__ == "__main__":
    main()