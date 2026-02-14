"""
db_connector.py - Database Connector
====================================
Handles all SQL Server database operations using pyodbc.
"""

import pyodbc
import pandas as pd
from typing import Dict, List, Optional, Any

from config import DB_CONFIG


class AnomalyDBConnector:
    """SQL Server database connector for anomaly detection system."""

    def __init__(self):
        """Initialize connection string for SQL Server."""
        self.conn_str = (
            f"DRIVER={{{DB_CONFIG['driver']}}};"
            f"SERVER={DB_CONFIG['server']};"
            f"DATABASE={DB_CONFIG['database']};"
            f"Trusted_Connection=yes;"
        )
        self.server = DB_CONFIG['server']
        self.database = DB_CONFIG['database']

    def get_connection(self) -> pyodbc.Connection:
        """
        Get a database connection.
        
        Returns:
            pyodbc.Connection: Active database connection
        """
        return pyodbc.connect(self.conn_str)

    def test_connection(self) -> bool:
        """
        Test database connection and display connection info.
        
        Returns:
            bool: True if connection successful, False otherwise
        """
        try:
            conn = self.get_connection()
            cursor = conn.cursor()
            
            cursor.execute("""
                SELECT 
                    @@SERVERNAME AS ServerName,
                    DB_NAME() AS DatabaseName,
                    SUSER_NAME() AS CurrentUser
            """)
            
            result = cursor.fetchone()
            
            if result is None:
                print(f"  ✗ Connection test returned no results")
                conn.close()
                return False
            
            print(f"  ✓ Connected to SQL Server")
            print(f"    Server   : {result.ServerName}")
            print(f"    Database : {result.DatabaseName}")
            print(f"    User     : {result.CurrentUser}")
            
            conn.close()
            return True
            
        except Exception as e:
            print(f"  ✗ Connection failed: {e}")
            return False

    def load_kpi_data(
        self, 
        start_date: Any, 
        end_date: Any
    ) -> pd.DataFrame:
        """
        Load KPI metrics with dimension data.
        
        Args:
            start_date: Start date for data range
            end_date: End date for data range
            
        Returns:
            pd.DataFrame: KPI data with dimensions
        """
        # Convert dates to string format
        if hasattr(start_date, 'strftime'):
            start_str = start_date.strftime('%Y-%m-%d')
        else:
            start_str = str(start_date)
        
        if hasattr(end_date, 'strftime'):
            end_str = end_date.strftime('%Y-%m-%d')
        else:
            end_str = str(end_date)
        
        query = f"""
        SELECT 
            fm.metric_date,
            fm.store_id,
            fm.product_id,
            fm.region_id,
            fm.revenue,
            fm.profit,
            fm.margin,
            fm.units_sold,
            ds.store_name,
            ds.store_type,
            dp.product_name,
            dp.category,
            dr.region_name
        FROM dbo.fact_kpi_metrics fm
        LEFT JOIN dbo.dim_stores ds ON fm.store_id = ds.store_id
        LEFT JOIN dbo.dim_products dp ON fm.product_id = dp.product_id
        LEFT JOIN dbo.dim_regions dr ON fm.region_id = dr.region_id
        WHERE CAST(fm.metric_date AS DATE) BETWEEN '{start_str}' AND '{end_str}'
        ORDER BY fm.metric_date
        """
        
        conn = self.get_connection()
        
        try:
            df = pd.read_sql(query, conn)
            
            if df.empty:
                print(f"  ⚠ No data found between {start_str} and {end_str}")
                return pd.DataFrame()
            
            # Convert metric_date to datetime
            df['metric_date'] = pd.to_datetime(df['metric_date'])
            
            return df
            
        except Exception as e:
            print(f"  ✗ Error loading data: {e}")
            return pd.DataFrame()
        
        finally:
            conn.close()

    def log_anomaly(self, anomaly_record: Dict[str, Any]) -> Optional[int]:
        """
        Insert anomaly record into database.
        
        Args:
            anomaly_record: Dictionary with anomaly details
            
        Returns:
            int: Anomaly ID if successful, None otherwise
        """
        try:
            conn = self.get_connection()
            cursor = conn.cursor()
            
            query = """
            INSERT INTO dbo.anomaly_log 
                (metric_date, kpi_type, anomaly_score, expected_value, 
                 actual_value, deviation_percent, severity)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            """
            
            cursor.execute(
                query,
                anomaly_record['metric_date'],
                anomaly_record['kpi_name'],
                anomaly_record['z_score'],
                anomaly_record['expected_value'],
                anomaly_record['actual_value'],
                anomaly_record['deviation_percent'],
                anomaly_record['severity']
            )
            
            # Get the inserted anomaly_id
            cursor.execute("SELECT @@IDENTITY AS anomaly_id")
            row = cursor.fetchone()
            
            if row is None:
                conn.commit()
                conn.close()
                return None
            
            anomaly_id = int(row[0])
            
            conn.commit()
            conn.close()
            
            return anomaly_id
            
        except Exception as e:
            print(f"  ✗ Error logging anomaly: {e}")
            return None

    def log_root_causes(self, drivers: List[Dict[str, Any]]) -> bool:
        """
        Insert root cause driver records.
        
        Args:
            drivers: List of driver dictionaries
            
        Returns:
            bool: True if successful, False otherwise
        """
        if not drivers:
            return True
        
        try:
            conn = self.get_connection()
            cursor = conn.cursor()
            
            query = """
            INSERT INTO dbo.root_cause_drivers 
                (anomaly_id, driver_type, driver_entity_id, driver_entity_name,
                 contribution_percent, impact_value)
            VALUES (?, ?, ?, ?, ?, ?)
            """
            
            # Bulk insert
            records = [
                (
                    d['anomaly_id'],
                    d['driver_type'],
                    d['entity_id'],
                    d['entity_name'],
                    d['contribution_percent'],
                    d['impact_value']
                )
                for d in drivers
            ]
            
            cursor.executemany(query, records)
            
            conn.commit()
            conn.close()
            
            return True
            
        except Exception as e:
            print(f"  ✗ Error logging root causes: {e}")
            return False

    def get_recent_anomalies(self, days: int = 30) -> pd.DataFrame:
        """
        Retrieve recent anomalies.
        
        Args:
            days: Number of days to look back
            
        Returns:
            pd.DataFrame: Recent anomalies
        """
        query = f"""
        SELECT 
            al.anomaly_id,
            al.metric_date,
            al.kpi_type,
            al.severity,
            al.deviation_percent,
            al.actual_value,
            al.expected_value,
            al.anomaly_score
        FROM dbo.anomaly_log al
        WHERE al.metric_date >= DATEADD(DAY, -{days}, GETDATE())
        ORDER BY al.metric_date DESC, al.severity DESC
        """
        
        conn = self.get_connection()
        df = pd.read_sql(query, conn)
        conn.close()
        
        return df