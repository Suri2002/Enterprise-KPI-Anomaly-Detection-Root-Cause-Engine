"""
config.py - Configuration
=========================
Central configuration for the KPI anomaly detection system.
"""

# ==============================================================================
# DATABASE CONFIGURATION
# ==============================================================================

DB_CONFIG = {
    "server": "localhost",  # Change to your SQL Server instance
    "database": "AnomalyDetectionDB",
    "driver": "ODBC Driver 17 for SQL Server",
    "trusted_connection": True,  # Windows Authentication
}

# ==============================================================================
# DETECTION PARAMETERS
# ==============================================================================

# Sensitivity levels map to Z-score thresholds
SENSITIVITY_THRESHOLDS = {
    "low": 3.0,      # Fewer anomalies (3 standard deviations)
    "medium": 2.5,   # Balanced (2.5 standard deviations)
    "high": 2.0,     # More anomalies (2 standard deviations)
}

# Default sensitivity
DEFAULT_SENSITIVITY = "medium"

# Minimum contribution % to report as root cause driver
MIN_CONTRIBUTION_PERCENT = 2.0

# Rolling window size for statistical analysis (days)
ROLLING_WINDOW_DAYS = 28

# Lookback period for root cause comparison (days)
LOOKBACK_PERIOD_DAYS = 28

# Data loading period (days to look back from today)
DATA_LOAD_DAYS = 90

# ==============================================================================
# KPI CONFIGURATION
# ==============================================================================

# KPIs to monitor
KPIS_TO_MONITOR = ["revenue", "profit", "margin"]

# Severity classification thresholds (Z-scores)
SEVERITY_THRESHOLDS = {
    "critical": 4.0,
    "high": 3.0,
    "medium": 2.0,
    "low": 0.0,
}