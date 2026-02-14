"""
root_cause_analyzer.py - Root Cause Analysis
============================================
Identifies dimensional drivers of KPI anomalies.
"""

import pandas as pd
import numpy as np
from datetime import timedelta
from typing import Dict

from config import MIN_CONTRIBUTION_PERCENT, LOOKBACK_PERIOD_DAYS


class RootCauseAnalyzer:
    """Automated root cause analysis across dimensions."""

    def __init__(self, min_contribution: float = MIN_CONTRIBUTION_PERCENT):
        """
        Initialize analyzer.
        
        Args:
            min_contribution: Minimum contribution % to report
        """
        self.min_contribution = min_contribution
        self.lookback_days = LOOKBACK_PERIOD_DAYS
        
        print(f"  ✓ Analyzer initialized — min_contribution={min_contribution}%")

    def find_root_causes(
        self,
        full_data: pd.DataFrame,
        anomaly_date: pd.Timestamp,
        kpi_col: str = "revenue"
    ) -> Dict[str, pd.DataFrame]:
        """
        Identify root causes across store, product, region dimensions.
        
        Args:
            full_data: Complete dataset with all dimensions
            anomaly_date: Date of the anomaly
            kpi_col: KPI column to analyze
            
        Returns:
            Dict: {dimension_name: drivers_dataframe}
        """
        # Ensure anomaly_date is Timestamp
        anomaly_date = pd.to_datetime(anomaly_date)
        
        # Define normal period (lookback days before anomaly)
        normal_start = anomaly_date - timedelta(days=self.lookback_days)
        
        # Split data
        normal_data = full_data[
            (full_data['metric_date'] >= normal_start) & 
            (full_data['metric_date'] < anomaly_date)
        ]
        
        anomaly_data = full_data[full_data['metric_date'] == anomaly_date]
        
        if normal_data.empty or anomaly_data.empty:
            return {}
        
        root_causes = {}
        
        # Analyze each dimension
        dimensions = {
            'store': ('store_id', 'store_name'),
            'product': ('product_id', 'product_name'),
            'region': ('region_id', 'region_name')
        }
        
        for dim_name, (id_col, name_col) in dimensions.items():
            drivers = self._analyze_dimension(
                normal_data, 
                anomaly_data, 
                id_col,
                name_col,
                kpi_col
            )
            
            if not drivers.empty:
                root_causes[dim_name] = drivers
        
        return root_causes

    def _analyze_dimension(
        self,
        normal_data: pd.DataFrame,
        anomaly_data: pd.DataFrame,
        id_col: str,
        name_col: str,
        kpi_col: str
    ) -> pd.DataFrame:
        """
        Analyze impact for a single dimension.
        
        Args:
            normal_data: Normal period data
            anomaly_data: Anomaly period data
            id_col: ID column name
            name_col: Name column name
            kpi_col: KPI column to analyze
            
        Returns:
            pd.DataFrame: Significant drivers
        """
        # Aggregate by dimension
        normal_agg = normal_data.groupby([id_col, name_col])[kpi_col].sum()
        anomaly_agg = anomaly_data.groupby([id_col, name_col])[kpi_col].sum()
        
        # Combine
        comparison = pd.DataFrame({
            'normal_value': normal_agg,
            'anomaly_value': anomaly_agg
        }).fillna(0)
        
        # Calculate change
        comparison['impact_value'] = (
            comparison['anomaly_value'] - comparison['normal_value']
        )
        
        # Calculate contribution
        total_change = anomaly_data[kpi_col].sum() - normal_data[kpi_col].sum()
        
        if total_change != 0:
            comparison['contribution_percent'] = (
                comparison['impact_value'] / total_change * 100
            )
        else:
            comparison['contribution_percent'] = 0
        
        # Filter significant drivers
        drivers = comparison[
            np.abs(comparison['contribution_percent']) >= self.min_contribution
        ].copy()
        
        # Sort by absolute contribution
        drivers = drivers.sort_values(
            'contribution_percent', 
            key=abs, 
            ascending=False
        )
        
        # Reset index to get ID and name as columns
        drivers = drivers.reset_index()
        
        return drivers.head(5)  # Top 5 drivers