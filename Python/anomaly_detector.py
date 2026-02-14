"""
anomaly_detector.py - Anomaly Detection
========================================
Statistical anomaly detection using Z-score method.
"""

import pandas as pd
import numpy as np
from typing import Optional

from config import SENSITIVITY_THRESHOLDS, SEVERITY_THRESHOLDS, ROLLING_WINDOW_DAYS


class KPIAnomalyDetector:
    """Z-score based anomaly detector for KPI metrics."""

    def __init__(self, sensitivity: str = "medium"):
        """
        Initialize detector with sensitivity threshold.
        
        Args:
            sensitivity: 'low', 'medium', or 'high'
        """
        self.threshold = SENSITIVITY_THRESHOLDS.get(sensitivity, 2.5)
        self.window = ROLLING_WINDOW_DAYS
        
        print(f"  ✓ Detector initialized — sensitivity={sensitivity}, threshold={self.threshold}σ")

    def detect_anomalies(
        self,
        df: pd.DataFrame,
        kpi_column: str = "revenue",
        date_column: str = "metric_date"
    ) -> pd.DataFrame:
        """
        Detect anomalies using rolling Z-score method.
        
        Args:
            df: DataFrame with date and KPI columns
            kpi_column: Name of KPI column to analyze
            date_column: Name of date column
            
        Returns:
            pd.DataFrame: Anomalies only (where is_anomaly == True)
        """
        # Sort by date
        df = df.sort_values(date_column).copy()
        
        # Calculate rolling statistics
        df['rolling_mean'] = df[kpi_column].rolling(
            window=self.window, 
            min_periods=7
        ).mean()
        
        df['rolling_std'] = df[kpi_column].rolling(
            window=self.window, 
            min_periods=7
        ).std()
        
        # Calculate Z-score
        df['z_score'] = (
            (df[kpi_column] - df['rolling_mean']) / df['rolling_std']
        )
        
        # Flag anomalies
        df['is_anomaly'] = np.abs(df['z_score']) > self.threshold
        df['anomaly_score'] = np.abs(df['z_score'])
        
        # Expected vs Actual
        df['expected_value'] = df['rolling_mean']
        df['actual_value'] = df[kpi_column]
        df['deviation_percent'] = (
            (df['actual_value'] - df['expected_value']) / 
            df['expected_value'] * 100
        )
        
        # Classify severity
        df['severity'] = df['z_score'].apply(self._classify_severity)
        
        # Return only anomalies
        anomalies = df[df['is_anomaly'] == True].copy()
        
        if not anomalies.empty:
            severity_counts = anomalies['severity'].value_counts()
            print(f"  ✓ Detected {len(anomalies)} anomalie(s)")
            for sev in ['critical', 'high', 'medium', 'low']:
                if sev in severity_counts:
                    print(f"    {sev.capitalize()}: {severity_counts[sev]}")
        else:
            print(f"  ✓ No anomalies detected")
        
        return anomalies

    def _classify_severity(self, z_score: float) -> str:
        """
        Classify anomaly severity based on Z-score magnitude.
        
        Args:
            z_score: Z-score value
            
        Returns:
            str: Severity level
        """
        abs_z = abs(z_score)
        
        if abs_z >= SEVERITY_THRESHOLDS['critical']:
            return 'critical'
        elif abs_z >= SEVERITY_THRESHOLDS['high']:
            return 'high'
        elif abs_z >= SEVERITY_THRESHOLDS['medium']:
            return 'medium'
        else:
            return 'low'