-- ============================================
-- SCRIPT 1: CREATE DATABASE AND TABLES
-- Description: Sets up the database structure
-- Execute this FIRST
-- ============================================

USE master;
GO

-- Create database if it doesn't exist
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'AnomalyDetectionDB')
BEGIN
    CREATE DATABASE AnomalyDetectionDB;
    PRINT '✓ Database created: AnomalyDetectionDB';
END
ELSE
BEGIN
    PRINT '✓ Database already exists: AnomalyDetectionDB';
END
GO

USE AnomalyDetectionDB;
GO

-- ============================================
-- DROP EXISTING TABLES (Clean Slate)
-- ============================================

PRINT 'Dropping existing tables...';

IF OBJECT_ID('dbo.root_cause_drivers', 'U') IS NOT NULL 
BEGIN
    DROP TABLE dbo.root_cause_drivers;
    PRINT '  ✓ Dropped: root_cause_drivers';
END

IF OBJECT_ID('dbo.anomaly_log', 'U') IS NOT NULL 
BEGIN
    DROP TABLE dbo.anomaly_log;
    PRINT '  ✓ Dropped: anomaly_log';
END

IF OBJECT_ID('dbo.pricing_changes', 'U') IS NOT NULL 
BEGIN
    DROP TABLE dbo.pricing_changes;
    PRINT '  ✓ Dropped: pricing_changes';
END

IF OBJECT_ID('dbo.fact_kpi_metrics', 'U') IS NOT NULL 
BEGIN
    DROP TABLE dbo.fact_kpi_metrics;
    PRINT '  ✓ Dropped: fact_kpi_metrics';
END

IF OBJECT_ID('dbo.dim_stores', 'U') IS NOT NULL 
BEGIN
    DROP TABLE dbo.dim_stores;
    PRINT '  ✓ Dropped: dim_stores';
END

IF OBJECT_ID('dbo.dim_products', 'U') IS NOT NULL 
BEGIN
    DROP TABLE dbo.dim_products;
    PRINT '  ✓ Dropped: dim_products';
END

IF OBJECT_ID('dbo.dim_regions', 'U') IS NOT NULL 
BEGIN
    DROP TABLE dbo.dim_regions;
    PRINT '  ✓ Dropped: dim_regions';
END

GO

-- ============================================
-- CREATE DIMENSION TABLES
-- ============================================

PRINT '';
PRINT 'Creating dimension tables...';

-- Regions Dimension
CREATE TABLE dbo.dim_regions (
    region_id INT PRIMARY KEY,
    region_name VARCHAR(100) NOT NULL,
    country VARCHAR(50) NOT NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE()
);
PRINT '  ✓ Created: dim_regions';

-- Stores Dimension
CREATE TABLE dbo.dim_stores (
    store_id INT PRIMARY KEY,
    store_name VARCHAR(100) NOT NULL,
    region_id INT NOT NULL,
    store_type VARCHAR(50) NOT NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_Store_Region FOREIGN KEY (region_id) 
        REFERENCES dbo.dim_regions(region_id)
);

CREATE INDEX idx_store_region ON dbo.dim_stores(region_id);
PRINT '  ✓ Created: dim_stores (with indexes)';

-- Products Dimension
CREATE TABLE dbo.dim_products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(200) NOT NULL,
    category VARCHAR(100) NOT NULL,
    subcategory VARCHAR(100) NOT NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE()
);

CREATE INDEX idx_product_category ON dbo.dim_products(category);
PRINT '  ✓ Created: dim_products (with indexes)';

GO

-- ============================================
-- CREATE FACT TABLE
-- ============================================

PRINT '';
PRINT 'Creating fact table...';

CREATE TABLE dbo.fact_kpi_metrics (
    metric_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    metric_date DATE NOT NULL,
    store_id INT NOT NULL,
    product_id INT NOT NULL,
    region_id INT NOT NULL,
    revenue DECIMAL(15,2) NOT NULL,
    profit DECIMAL(15,2) NOT NULL,
    margin DECIMAL(5,2) NOT NULL,
    units_sold INT NOT NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_Metrics_Store FOREIGN KEY (store_id) 
        REFERENCES dbo.dim_stores(store_id),
    CONSTRAINT FK_Metrics_Product FOREIGN KEY (product_id) 
        REFERENCES dbo.dim_products(product_id),
    CONSTRAINT FK_Metrics_Region FOREIGN KEY (region_id) 
        REFERENCES dbo.dim_regions(region_id)
);

-- Create performance indexes
CREATE INDEX idx_metrics_date ON dbo.fact_kpi_metrics(metric_date);
CREATE INDEX idx_metrics_store ON dbo.fact_kpi_metrics(store_id);
CREATE INDEX idx_metrics_product ON dbo.fact_kpi_metrics(product_id);
CREATE INDEX idx_metrics_region ON dbo.fact_kpi_metrics(region_id);
CREATE INDEX idx_metrics_date_store ON dbo.fact_kpi_metrics(metric_date, store_id);
CREATE INDEX idx_metrics_date_product ON dbo.fact_kpi_metrics(metric_date, product_id);

PRINT '  ✓ Created: fact_kpi_metrics (with 6 indexes)';

GO

-- ============================================
-- CREATE ANOMALY DETECTION TABLES
-- ============================================

PRINT '';
PRINT 'Creating anomaly detection tables...';

-- Anomaly Log Table
CREATE TABLE dbo.anomaly_log (
    anomaly_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    detection_date DATETIME2 DEFAULT GETDATE(),
    metric_date DATE NOT NULL,
    kpi_type VARCHAR(50) NOT NULL,
    anomaly_score DECIMAL(10,4) NOT NULL,
    expected_value DECIMAL(15,2) NOT NULL,
    actual_value DECIMAL(15,2) NOT NULL,
    deviation_percent DECIMAL(10,2) NOT NULL,
    severity VARCHAR(20) NOT NULL,
    status VARCHAR(20) DEFAULT 'new',
    narrative NVARCHAR(MAX) NULL,
    assigned_to VARCHAR(100) NULL,
    resolved_date DATETIME2 NULL,
    resolution_notes NVARCHAR(MAX) NULL,
    CONSTRAINT CHK_KPI_Type CHECK (kpi_type IN ('revenue', 'profit', 'margin')),
    CONSTRAINT CHK_Severity CHECK (severity IN ('critical', 'high', 'medium', 'low')),
    CONSTRAINT CHK_Status CHECK (status IN ('new', 'investigating', 'resolved', 'false_positive'))
);

CREATE INDEX idx_anomaly_date ON dbo.anomaly_log(metric_date);
CREATE INDEX idx_anomaly_kpi ON dbo.anomaly_log(kpi_type);
CREATE INDEX idx_anomaly_severity ON dbo.anomaly_log(severity);
CREATE INDEX idx_anomaly_status ON dbo.anomaly_log(status);
CREATE INDEX idx_anomaly_detection_date ON dbo.anomaly_log(detection_date);

PRINT '  ✓ Created: anomaly_log (with 5 indexes)';

-- Root Cause Drivers Table
CREATE TABLE dbo.root_cause_drivers (
    driver_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    anomaly_id BIGINT NOT NULL,
    driver_type VARCHAR(50) NOT NULL,
    driver_entity_id INT NOT NULL,
    driver_entity_name VARCHAR(200) NOT NULL,
    contribution_percent DECIMAL(10,2) NOT NULL,
    impact_value DECIMAL(15,2) NOT NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_Driver_Anomaly FOREIGN KEY (anomaly_id) 
        REFERENCES dbo.anomaly_log(anomaly_id) ON DELETE CASCADE,
    CONSTRAINT CHK_Driver_Type CHECK (driver_type IN ('store', 'product', 'region', 'pricing'))
);

CREATE INDEX idx_driver_anomaly ON dbo.root_cause_drivers(anomaly_id);
CREATE INDEX idx_driver_type ON dbo.root_cause_drivers(driver_type);

PRINT '  ✓ Created: root_cause_drivers (with 2 indexes)';

-- Pricing Changes Table
CREATE TABLE dbo.pricing_changes (
    change_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    product_id INT NOT NULL,
    change_date DATE NOT NULL,
    old_price DECIMAL(10,2) NOT NULL,
    new_price DECIMAL(10,2) NOT NULL,
    price_change_percent DECIMAL(10,2) NOT NULL,
    change_reason VARCHAR(500) NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_Pricing_Product FOREIGN KEY (product_id) 
        REFERENCES dbo.dim_products(product_id)
);

CREATE INDEX idx_pricing_date ON dbo.pricing_changes(change_date);
CREATE INDEX idx_pricing_product ON dbo.pricing_changes(product_id);

PRINT '  ✓ Created: pricing_changes (with 2 indexes)';

GO

-- ============================================
-- SUMMARY
-- ============================================

PRINT '';
PRINT '============================================';
PRINT 'TABLE CREATION SUMMARY';
PRINT '============================================';

SELECT 
    t.TABLE_NAME,
    (SELECT COUNT(*) 
     FROM INFORMATION_SCHEMA.COLUMNS c 
     WHERE c.TABLE_NAME = t.TABLE_NAME 
     AND c.TABLE_SCHEMA = 'dbo') AS [Column Count],
    (SELECT COUNT(*) 
     FROM sys.indexes i 
     INNER JOIN sys.tables tb ON i.object_id = tb.object_id
     WHERE tb.name = t.TABLE_NAME 
     AND i.name IS NOT NULL) AS [Index Count]
FROM INFORMATION_SCHEMA.TABLES t
WHERE t.TABLE_SCHEMA = 'dbo'
ORDER BY t.TABLE_NAME;

PRINT '';
PRINT '✓ All tables created successfully!';
PRINT '✓ Ready for data population (run Script 2 next)';
GO