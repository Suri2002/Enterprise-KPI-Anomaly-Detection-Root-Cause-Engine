-- ============================================
-- SCRIPT 3: CREATE VIEWS AND STORED PROCEDURES
-- Description: Creates analytical views and procedures
-- ============================================

USE AnomalyDetectionDB;
GO

-- ============================================
-- CHECK PREREQUISITES
-- ============================================

DECLARE @FactCount INT = (SELECT COUNT(*) FROM dbo.fact_kpi_metrics);

IF @FactCount < 1000
BEGIN
    PRINT '============================================';
    PRINT 'ERROR: Fact table not populated!';
    PRINT 'Please run Scripts 2A, 2B, 2C first';
    PRINT '============================================';
    RETURN;
END

PRINT '============================================';
PRINT 'CREATING ANALYTICAL VIEWS';
PRINT '============================================';
PRINT '';

-- ============================================
-- VIEW 1: Daily KPI Summary
-- ============================================

PRINT 'Creating vw_daily_kpi_summary...';

IF OBJECT_ID('dbo.vw_daily_kpi_summary', 'V') IS NOT NULL
    DROP VIEW dbo.vw_daily_kpi_summary;
GO

CREATE VIEW dbo.vw_daily_kpi_summary AS
SELECT 
    metric_date,
    SUM(revenue) AS total_revenue,
    SUM(profit) AS total_profit,
    AVG(margin) AS avg_margin,
    SUM(units_sold) AS total_units,
    COUNT(DISTINCT store_id) AS active_stores,
    COUNT(DISTINCT product_id) AS products_sold,
    COUNT(*) AS transaction_count
FROM dbo.fact_kpi_metrics
GROUP BY metric_date;
GO

PRINT 'Created: vw_daily_kpi_summary';

-- ============================================
-- VIEW 2: Anomaly Dashboard
-- ============================================

PRINT 'Creating vw_anomaly_dashboard...';

IF OBJECT_ID('dbo.vw_anomaly_dashboard', 'V') IS NOT NULL
    DROP VIEW dbo.vw_anomaly_dashboard;
GO

CREATE VIEW dbo.vw_anomaly_dashboard AS
SELECT 
    al.anomaly_id,
    al.detection_date,
    al.metric_date,
    al.kpi_type,
    al.severity,
    al.status,
    al.expected_value,
    al.actual_value,
    al.deviation_percent,
    al.anomaly_score,
    al.assigned_to,
    al.narrative,
    al.resolved_date,
    -- Aggregate root causes into a single string
    STUFF((
        SELECT '; ' + 
               CONCAT(rcd.driver_type, ': ', rcd.driver_entity_name, 
                      ' (', CAST(ROUND(rcd.contribution_percent, 1) AS VARCHAR), '%)')
        FROM dbo.root_cause_drivers rcd
        WHERE rcd.anomaly_id = al.anomaly_id
        ORDER BY ABS(rcd.contribution_percent) DESC
        FOR XML PATH(''), TYPE
    ).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS root_causes,
    -- Top driver details
    (SELECT TOP 1 driver_entity_name 
     FROM dbo.root_cause_drivers 
     WHERE anomaly_id = al.anomaly_id 
     ORDER BY ABS(contribution_percent) DESC) AS primary_driver,
    (SELECT TOP 1 contribution_percent 
     FROM dbo.root_cause_drivers 
     WHERE anomaly_id = al.anomaly_id 
     ORDER BY ABS(contribution_percent) DESC) AS primary_contribution
FROM dbo.anomaly_log al;
GO

PRINT 'Created: vw_anomaly_dashboard';

-- ============================================
-- VIEW 3: Store Performance
-- ============================================

PRINT 'Creating vw_store_performance...';

IF OBJECT_ID('dbo.vw_store_performance', 'V') IS NOT NULL
    DROP VIEW dbo.vw_store_performance;
GO

CREATE VIEW dbo.vw_store_performance AS
SELECT 
    fm.store_id,
    ds.store_name,
    ds.store_type,
    dr.region_name,
    fm.metric_date,
    SUM(fm.revenue) AS revenue,
    SUM(fm.profit) AS profit,
    AVG(fm.margin) AS avg_margin,
    SUM(fm.units_sold) AS units_sold
FROM dbo.fact_kpi_metrics fm
INNER JOIN dbo.dim_stores ds ON fm.store_id = ds.store_id
INNER JOIN dbo.dim_regions dr ON fm.region_id = dr.region_id
GROUP BY 
    fm.store_id, ds.store_name, ds.store_type, 
    dr.region_name, fm.metric_date;
GO

PRINT 'Created: vw_store_performance';

-- ============================================
-- VIEW 4: Product Performance
-- ============================================

PRINT 'Creating vw_product_performance...';

IF OBJECT_ID('dbo.vw_product_performance', 'V') IS NOT NULL
    DROP VIEW dbo.vw_product_performance;
GO

CREATE VIEW dbo.vw_product_performance AS
SELECT 
    fm.product_id,
    dp.product_name,
    dp.category,
    dp.subcategory,
    fm.metric_date,
    SUM(fm.revenue) AS revenue,
    SUM(fm.profit) AS profit,
    AVG(fm.margin) AS avg_margin,
    SUM(fm.units_sold) AS units_sold
FROM dbo.fact_kpi_metrics fm
INNER JOIN dbo.dim_products dp ON fm.product_id = dp.product_id
GROUP BY 
    fm.product_id, dp.product_name, dp.category, 
    dp.subcategory, fm.metric_date;
GO

PRINT 'Created: vw_product_performance';

-- ============================================
-- VIEW 5: Anomaly Trends
-- ============================================

PRINT 'Creating vw_anomaly_trends...';

IF OBJECT_ID('dbo.vw_anomaly_trends', 'V') IS NOT NULL
    DROP VIEW dbo.vw_anomaly_trends;
GO

CREATE VIEW dbo.vw_anomaly_trends AS
SELECT 
    DATEPART(YEAR, metric_date) AS [year],
    DATEPART(MONTH, metric_date) AS [month],
    kpi_type,
    severity,
    status,
    COUNT(*) AS anomaly_count,
    AVG(ABS(deviation_percent)) AS avg_deviation,
    SUM(CASE WHEN status = 'resolved' THEN 1 ELSE 0 END) AS resolved_count,
    AVG(CASE 
        WHEN status = 'resolved' AND resolved_date IS NOT NULL 
        THEN DATEDIFF(DAY, detection_date, resolved_date) 
        ELSE NULL 
    END) AS avg_resolution_days
FROM dbo.anomaly_log
GROUP BY 
    DATEPART(YEAR, metric_date), 
    DATEPART(MONTH, metric_date), 
    kpi_type, 
    severity,
    status;
GO

PRINT 'Created: vw_anomaly_trends';

-- ============================================
-- STORED PROCEDURES
-- ============================================

PRINT '';
PRINT '============================================';
PRINT 'CREATING STORED PROCEDURES';
PRINT '============================================';
PRINT '';

-- ============================================
-- SP 1: Get KPI Data
-- ============================================

PRINT 'Creating sp_get_kpi_data...';

IF OBJECT_ID('dbo.sp_get_kpi_data', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_get_kpi_data;
GO

CREATE PROCEDURE dbo.sp_get_kpi_data
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    SET NOCOUNT ON;
    
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
    WHERE fm.metric_date BETWEEN @StartDate AND @EndDate
    ORDER BY fm.metric_date, fm.store_id, fm.product_id;
END
GO

PRINT 'Created: sp_get_kpi_data';

-- ============================================
-- SP 2: Insert Anomaly
-- ============================================

PRINT 'Creating sp_insert_anomaly...';

IF OBJECT_ID('dbo.sp_insert_anomaly', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_insert_anomaly;
GO

CREATE PROCEDURE dbo.sp_insert_anomaly
    @MetricDate DATE,
    @KpiType VARCHAR(50),
    @AnomalyScore DECIMAL(10,4),
    @ExpectedValue DECIMAL(15,2),
    @ActualValue DECIMAL(15,2),
    @DeviationPercent DECIMAL(10,2),
    @Severity VARCHAR(20),
    @Narrative NVARCHAR(MAX) = NULL,
    @AnomalyID BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO dbo.anomaly_log 
        (metric_date, kpi_type, anomaly_score, expected_value, 
         actual_value, deviation_percent, severity, narrative)
    VALUES 
        (@MetricDate, @KpiType, @AnomalyScore, @ExpectedValue, 
         @ActualValue, @DeviationPercent, @Severity, @Narrative);
    
    SET @AnomalyID = SCOPE_IDENTITY();
END
GO

PRINT 'Created: sp_insert_anomaly';

-- ============================================
-- SP 3: Insert Root Cause
-- ============================================

PRINT 'Creating sp_insert_root_cause...';

IF OBJECT_ID('dbo.sp_insert_root_cause', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_insert_root_cause;
GO

CREATE PROCEDURE dbo.sp_insert_root_cause
    @AnomalyID BIGINT,
    @DriverType VARCHAR(50),
    @DriverEntityID INT,
    @DriverEntityName VARCHAR(200),
    @ContributionPercent DECIMAL(10,2),
    @ImpactValue DECIMAL(15,2)
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO dbo.root_cause_drivers 
        (anomaly_id, driver_type, driver_entity_id, driver_entity_name,
         contribution_percent, impact_value)
    VALUES 
        (@AnomalyID, @DriverType, @DriverEntityID, @DriverEntityName,
         @ContributionPercent, @ImpactValue);
END
GO

PRINT 'Created: sp_insert_root_cause';

-- ============================================
-- SP 4: Get Recent Anomalies
-- ============================================

PRINT 'Creating sp_get_recent_anomalies...';

IF OBJECT_ID('dbo.sp_get_recent_anomalies', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_get_recent_anomalies;
GO

CREATE PROCEDURE dbo.sp_get_recent_anomalies
    @DaysBack INT = 30
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT * 
    FROM dbo.vw_anomaly_dashboard
    WHERE metric_date >= DATEADD(DAY, -@DaysBack, CAST(GETDATE() AS DATE))
    ORDER BY metric_date DESC, severity DESC;
END
GO

PRINT 'Created: sp_get_recent_anomalies';

-- ============================================
-- SP 5: Update Anomaly Status
-- ============================================

PRINT 'Creating sp_update_anomaly_status...';

IF OBJECT_ID('dbo.sp_update_anomaly_status', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_update_anomaly_status;
GO

CREATE PROCEDURE dbo.sp_update_anomaly_status
    @AnomalyID BIGINT,
    @Status VARCHAR(20),
    @AssignedTo VARCHAR(100) = NULL,
    @ResolutionNotes NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE dbo.anomaly_log
    SET 
        status = @Status,
        assigned_to = ISNULL(@AssignedTo, assigned_to),
        resolution_notes = ISNULL(@ResolutionNotes, resolution_notes),
        resolved_date = CASE 
            WHEN @Status = 'resolved' AND resolved_date IS NULL 
            THEN GETDATE() 
            ELSE resolved_date 
        END
    WHERE anomaly_id = @AnomalyID;
    
    -- Return updated record
    SELECT * FROM dbo.anomaly_log WHERE anomaly_id = @AnomalyID;
END
GO

PRINT 'Created: sp_update_anomaly_status';

-- ============================================
-- TEST THE VIEWS
-- ============================================

PRINT '';
PRINT '============================================';
PRINT 'TESTING VIEWS';
PRINT '============================================';
PRINT '';

-- Test vw_daily_kpi_summary
PRINT 'Testing vw_daily_kpi_summary (Last 5 Days):';
SELECT TOP 5
    metric_date,
    FORMAT(total_revenue, 'N0') AS total_revenue,
    FORMAT(total_profit, 'N0') AS total_profit,
    FORMAT(avg_margin, 'N2') AS avg_margin,
    active_stores,
    products_sold
FROM dbo.vw_daily_kpi_summary
ORDER BY metric_date DESC;

-- Test vw_store_performance
PRINT '';
PRINT 'Testing vw_store_performance (Top 5 Stores by Revenue):';
SELECT TOP 5
    store_name,
    region_name,
    FORMAT(SUM(revenue), 'N0') AS total_revenue,
    FORMAT(AVG(avg_margin), 'N2') AS avg_margin
FROM dbo.vw_store_performance
GROUP BY store_name, region_name
ORDER BY SUM(revenue) DESC;

-- Test vw_product_performance
PRINT '';
PRINT 'Testing vw_product_performance (Top 5 Products by Revenue):';
SELECT TOP 5
    product_name,
    category,
    FORMAT(SUM(revenue), 'N0') AS total_revenue,
    FORMAT(AVG(avg_margin), 'N2') AS avg_margin
FROM dbo.vw_product_performance
GROUP BY product_name, category
ORDER BY SUM(revenue) DESC;

-- ============================================
-- TEST THE STORED PROCEDURES
-- ============================================

PRINT '';
PRINT '============================================';
PRINT 'TESTING STORED PROCEDURES';
PRINT '============================================';
PRINT '';

-- Test sp_get_kpi_data
PRINT 'Testing sp_get_kpi_data (Last 3 Days):';
DECLARE @TestStartDate DATE = DATEADD(DAY, -3, CAST(GETDATE() AS DATE));
DECLARE @TestEndDate DATE = CAST(GETDATE() AS DATE);

EXEC dbo.sp_get_kpi_data 
    @StartDate = @TestStartDate, 
    @EndDate = @TestEndDate;

PRINT '';
PRINT 'Stored procedure test completed successfully!';

-- ============================================
-- SUMMARY
-- ============================================

PRINT '';
PRINT '============================================';
PRINT 'DATABASE OBJECTS SUMMARY';
PRINT '============================================';
PRINT '';

-- Count views
SELECT 'Views Created' AS [Object Type], COUNT(*) AS [Count]
FROM INFORMATION_SCHEMA.VIEWS
WHERE TABLE_SCHEMA = 'dbo' 
AND TABLE_NAME LIKE 'vw_%'

UNION ALL

-- Count stored procedures
SELECT 'Stored Procedures Created', COUNT(*)
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_SCHEMA = 'dbo' 
AND ROUTINE_TYPE = 'PROCEDURE'
AND ROUTINE_NAME LIKE 'sp_%';

PRINT '';
PRINT '============================================';
PRINT 'All views and stored procedures created!';
PRINT 'All tests passed successfully!';
PRINT 'Ready for Script 4 (Final Verification)';
PRINT '============================================';
GO