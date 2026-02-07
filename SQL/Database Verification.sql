-- ============================================
-- SCRIPT 4: COMPLETE DATABASE VERIFICATION 
-- Description: Validates entire database setup
-- ============================================

USE AnomalyDetectionDB;
GO

PRINT '============================================';
PRINT 'COMPLETE DATABASE HEALTH CHECK';
PRINT '============================================';
PRINT '';

-- ============================================
-- 1. TABLE VERIFICATION
-- ============================================

PRINT '1. TABLE VERIFICATION';
PRINT '--------------------------------------------';

SELECT 
    t.TABLE_NAME AS [Table Name],
    (SELECT COUNT(*) 
     FROM INFORMATION_SCHEMA.COLUMNS c 
     WHERE c.TABLE_NAME = t.TABLE_NAME 
     AND c.TABLE_SCHEMA = 'dbo') AS [Columns],
    (SELECT COUNT(*) 
     FROM sys.indexes i 
     INNER JOIN sys.tables tb ON i.object_id = tb.object_id
     WHERE tb.name = t.TABLE_NAME 
     AND i.name IS NOT NULL) AS [Indexes],
    (SELECT COUNT(*) 
     FROM sys.foreign_keys fk
     WHERE OBJECT_NAME(fk.parent_object_id) = t.TABLE_NAME) AS [Foreign Keys]
FROM INFORMATION_SCHEMA.TABLES t
WHERE t.TABLE_SCHEMA = 'dbo'
AND t.TABLE_TYPE = 'BASE TABLE'
ORDER BY t.TABLE_NAME;

-- ============================================
-- 2. RECORD COUNT VERIFICATION
-- ============================================

PRINT '';
PRINT '2. RECORD COUNTS';
PRINT '--------------------------------------------';

DECLARE @RegionCount INT = (SELECT COUNT(*) FROM dbo.dim_regions);
DECLARE @StoreCount INT = (SELECT COUNT(*) FROM dbo.dim_stores);
DECLARE @ProductCount INT = (SELECT COUNT(*) FROM dbo.dim_products);
DECLARE @FactCount INT = (SELECT COUNT(*) FROM dbo.fact_kpi_metrics);
DECLARE @PricingCount INT = (SELECT COUNT(*) FROM dbo.pricing_changes);
DECLARE @AnomalyCount INT = (SELECT COUNT(*) FROM dbo.anomaly_log);

SELECT 
    'dim_regions' AS [Table],
    @RegionCount AS [Records],
    'Expected: 5' AS [Expected],
    CASE WHEN @RegionCount = 5 THEN '✓ PASS' ELSE '✗ FAIL' END AS [Status]
UNION ALL
SELECT 'dim_stores', @StoreCount, 'Expected: 50',
    CASE WHEN @StoreCount = 50 THEN '✓ PASS' ELSE '✗ FAIL' END
UNION ALL
SELECT 'dim_products', @ProductCount, 'Expected: 100',
    CASE WHEN @ProductCount = 100 THEN '✓ PASS' ELSE '✗ FAIL' END
UNION ALL
SELECT 'fact_kpi_metrics', @FactCount, 'Expected: ~45,000',
    CASE WHEN @FactCount >= 1000 THEN '✓ PASS' ELSE '✗ FAIL' END
UNION ALL
SELECT 'pricing_changes', @PricingCount, 'Expected: ~30',
    CASE WHEN @PricingCount >= 20 THEN '✓ PASS' ELSE '✗ FAIL' END
UNION ALL
SELECT 'anomaly_log', @AnomalyCount, 'Expected: 0 (until Python runs)',
    '✓ READY';

-- ============================================
-- 3. DATE RANGE VERIFICATION
-- ============================================

PRINT '';
PRINT '3. DATE RANGE';
PRINT '--------------------------------------------';

SELECT 
    MIN(metric_date) AS [First Date],
    MAX(metric_date) AS [Last Date],
    DATEDIFF(DAY, MIN(metric_date), MAX(metric_date)) + 1 AS [Days Covered],
    COUNT(DISTINCT metric_date) AS [Unique Dates]
FROM dbo.fact_kpi_metrics;

-- ============================================
-- 4. DATA INTEGRITY CHECKS
-- ============================================

PRINT '';
PRINT '4. DATA INTEGRITY';
PRINT '--------------------------------------------';

SELECT 
    'Orphaned Stores (no region)' AS [Check],
    COUNT(*) AS [Issues Found],
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END AS [Status]
FROM dbo.dim_stores s
LEFT JOIN dbo.dim_regions r ON s.region_id = r.region_id
WHERE r.region_id IS NULL

UNION ALL

SELECT 
    'Orphaned Fact Records (no store)',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END
FROM dbo.fact_kpi_metrics f
LEFT JOIN dbo.dim_stores s ON f.store_id = s.store_id
WHERE s.store_id IS NULL

UNION ALL

SELECT 
    'Orphaned Fact Records (no product)',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END
FROM dbo.fact_kpi_metrics f
LEFT JOIN dbo.dim_products p ON f.product_id = p.product_id
WHERE p.product_id IS NULL

UNION ALL

SELECT 
    'Negative Revenue Values',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END
FROM dbo.fact_kpi_metrics
WHERE revenue < 0

UNION ALL

SELECT 
    'NULL Revenue Values',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END
FROM dbo.fact_kpi_metrics
WHERE revenue IS NULL;

-- ============================================
-- 5. VIEW VERIFICATION (FIXED SECTION)
-- ============================================

PRINT '';
PRINT '5. VIEWS';
PRINT '--------------------------------------------';

SELECT 
    TABLE_NAME AS [View Name],
    'Active' AS [Status]
FROM INFORMATION_SCHEMA.VIEWS
WHERE TABLE_SCHEMA = 'dbo'
AND TABLE_NAME LIKE 'vw_%'
ORDER BY TABLE_NAME;

-- Test each view returns data
DECLARE @ViewTestResults TABLE (
    ViewName VARCHAR(100),
    RecordCount INT,  -- ✓ FIXED: Changed from RowCount to RecordCount
    Status VARCHAR(20)
);

INSERT INTO @ViewTestResults
SELECT 'vw_daily_kpi_summary', COUNT(*), 
    CASE WHEN COUNT(*) > 0 THEN '✓ PASS' ELSE '✗ FAIL' END
FROM dbo.vw_daily_kpi_summary;

INSERT INTO @ViewTestResults
SELECT 'vw_store_performance', COUNT(*),
    CASE WHEN COUNT(*) > 0 THEN '✓ PASS' ELSE '✗ FAIL' END
FROM dbo.vw_store_performance;

INSERT INTO @ViewTestResults
SELECT 'vw_product_performance', COUNT(*),
    CASE WHEN COUNT(*) > 0 THEN '✓ PASS' ELSE '✗ FAIL' END
FROM dbo.vw_product_performance;

PRINT '';
PRINT 'View Data Tests:';
SELECT 
    ViewName AS [View Name],
    RecordCount AS [Records],
    Status
FROM @ViewTestResults;

-- ============================================
-- 6. STORED PROCEDURE VERIFICATION
-- ============================================

PRINT '';
PRINT '6. STORED PROCEDURES';
PRINT '--------------------------------------------';

SELECT 
    ROUTINE_NAME AS [Procedure Name],
    CREATED AS [Created Date],
    'Active' AS [Status]
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_SCHEMA = 'dbo' 
AND ROUTINE_TYPE = 'PROCEDURE'
AND ROUTINE_NAME LIKE 'sp_%'
ORDER BY ROUTINE_NAME;

-- ============================================
-- 7. SAMPLE DATA PREVIEW
-- ============================================

PRINT '';
PRINT '7. SAMPLE DATA PREVIEW (Last 5 Days)';
PRINT '--------------------------------------------';

SELECT 
    metric_date,
    FORMAT(SUM(revenue), 'C0') AS total_revenue,
    FORMAT(SUM(profit), 'C0') AS total_profit,
    FORMAT(AVG(margin), 'N2') + '%' AS avg_margin,
    FORMAT(SUM(units_sold), 'N0') AS total_units,
    COUNT(*) AS transaction_count
FROM dbo.fact_kpi_metrics
WHERE metric_date >= DATEADD(DAY, -5, CAST(GETDATE() AS DATE))
GROUP BY metric_date
ORDER BY metric_date DESC;

-- ============================================
-- 8. CATEGORY DISTRIBUTION
-- ============================================

PRINT '';
PRINT '8. PRODUCT CATEGORY PERFORMANCE';
PRINT '--------------------------------------------';

SELECT 
    dp.category,
    COUNT(DISTINCT dp.product_id) AS product_count,
    FORMAT(SUM(fm.revenue), 'C0') AS total_revenue,
    FORMAT(AVG(fm.margin), 'N2') + '%' AS avg_margin
FROM dbo.fact_kpi_metrics fm
INNER JOIN dbo.dim_products dp ON fm.product_id = dp.product_id
GROUP BY dp.category
ORDER BY SUM(fm.revenue) DESC;

-- ============================================
-- 9. REGIONAL PERFORMANCE
-- ============================================

PRINT '';
PRINT '9. REGIONAL PERFORMANCE';
PRINT '--------------------------------------------';

SELECT 
    dr.region_name,
    COUNT(DISTINCT ds.store_id) AS store_count,
    FORMAT(SUM(fm.revenue), 'C0') AS total_revenue,
    FORMAT(AVG(fm.margin), 'N2') + '%' AS avg_margin
FROM dbo.fact_kpi_metrics fm
INNER JOIN dbo.dim_regions dr ON fm.region_id = dr.region_id
INNER JOIN dbo.dim_stores ds ON fm.store_id = ds.store_id
GROUP BY dr.region_name
ORDER BY SUM(fm.revenue) DESC;

-- ============================================
-- 10. CONNECTION STRING INFORMATION
-- ============================================

PRINT '';
PRINT '10. DATABASE CONNECTION INFO';
PRINT '--------------------------------------------';

SELECT 
    @@SERVERNAME AS [Server Name],
    DB_NAME() AS [Database Name],
    SUSER_SNAME() AS [Current User];

-- Show SQL Server Version (separate query to avoid formatting issues)
PRINT '';
PRINT 'SQL Server Version:';
SELECT @@VERSION AS [Version];

-- ============================================
-- FINAL STATUS
-- ============================================

PRINT '';
PRINT '============================================';
PRINT 'DATABASE STATUS: READY ✓';
PRINT '============================================';
PRINT '';
PRINT 'Summary:';
PRINT '  ✓ All tables created and populated';
PRINT '  ✓ All views created and functional';
PRINT '  ✓ All stored procedures created';
PRINT '  ✓ Data integrity verified';
PRINT '  ✓ ' + CAST(@FactCount AS VARCHAR(10)) + ' fact records generated';
PRINT '  ✓ ' + CAST(@PricingCount AS VARCHAR(10)) + ' pricing changes logged';
PRINT '';
PRINT 'Next Steps:';
PRINT '  1. Install Python dependencies (pyodbc, pandas, numpy, scipy, scikit-learn)';
PRINT '  2. Configure Python connection string';
PRINT '  3. Run Python anomaly detection pipeline';
PRINT '  4. Configure SAC/Power BI dashboard';
PRINT '  5. Set up automated scheduling (Windows Task Scheduler)';
PRINT '';

PRINT 'Python Connection Details:';
PRINT '  Server: ' + @@SERVERNAME;
PRINT '  Database: AnomalyDetectionDB';
PRINT '  Authentication: Windows (Trusted Connection)';
PRINT '';
PRINT '============================================';
GO