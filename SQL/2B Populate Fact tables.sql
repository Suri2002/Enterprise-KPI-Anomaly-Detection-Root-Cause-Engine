-- ============================================
-- SCRIPT 2B: POPULATE FACT TABLE
-- Description: Generates sample KPI data (Last 90 days)

USE AnomalyDetectionDB;
GO

-- ============================================
-- CHECK PREREQUISITES
-- ============================================

DECLARE @RegionCount INT = (SELECT COUNT(*) FROM dbo.dim_regions);
DECLARE @StoreCount INT = (SELECT COUNT(*) FROM dbo.dim_stores);
DECLARE @ProductCount INT = (SELECT COUNT(*) FROM dbo.dim_products);

IF @RegionCount < 5 OR @StoreCount < 50 OR @ProductCount < 100
BEGIN
    PRINT '============================================';
    PRINT 'ERROR: Dimension tables not ready!';
    PRINT 'Please run Script 2A first';
    PRINT '============================================';
    RETURN;
END

PRINT '============================================';
PRINT 'POPULATING FACT TABLE (90 DAYS OF DATA)';
PRINT '============================================';
PRINT '';

-- ============================================
-- CONFIGURATION & DATA GENERATION
-- ============================================

DECLARE @DaysToGenerate INT = 90;
DECLARE @StartDate DATE = DATEADD(DAY, -@DaysToGenerate, CAST(GETDATE() AS DATE));
DECLARE @EndDate DATE = CAST(GETDATE() AS DATE);
DECLARE @CurrentDate DATE = @StartDate;
DECLARE @TotalRecords INT = 0;
DECLARE @DayCounter INT = 0;
DECLARE @DayOfYear INT;
DECLARE @SeasonalFactor DECIMAL(5,2);

PRINT 'Configuration:';
PRINT '  Start Date: ' + CAST(@StartDate AS VARCHAR(20));
PRINT '  End Date: ' + CAST(@EndDate AS VARCHAR(20));
PRINT '  Total Days: ' + CAST(@DaysToGenerate AS VARCHAR(10));
PRINT '';
PRINT 'Generating data (this will take 1-2 minutes)...';
PRINT '';

-- ============================================
-- MAIN DATA GENERATION LOOP
-- ============================================

WHILE @CurrentDate <= @EndDate
BEGIN
    SET @DayCounter = @DayCounter + 1;
    
    -- Calculate seasonal factor
    SET @DayOfYear = DATEPART(DAYOFYEAR, @CurrentDate);
    SET @SeasonalFactor = 1 + (0.3 * SIN(2 * PI() * @DayOfYear / 365.0));
    
    -- Generate records for this day
    INSERT INTO dbo.fact_kpi_metrics 
        (metric_date, store_id, product_id, region_id, revenue, profit, margin, units_sold)
    SELECT 
        @CurrentDate AS metric_date,
        s.store_id,
        p.product_id,
        s.region_id,
        -- Revenue with seasonal pattern and anomalies
        CASE 
            WHEN ABS(CHECKSUM(NEWID())) % 100 < 10 THEN
                CASE 
                    WHEN ABS(CHECKSUM(NEWID())) % 2 = 0 THEN
                        (1000 + ABS(CHECKSUM(NEWID())) % 4000) * @SeasonalFactor * 
                        (2.5 + (ABS(CHECKSUM(NEWID())) % 150) / 100.0)
                    ELSE
                        (1000 + ABS(CHECKSUM(NEWID())) % 4000) * @SeasonalFactor * 
                        (0.3 + (ABS(CHECKSUM(NEWID())) % 30) / 100.0)
                END
            ELSE
                (1000 + ABS(CHECKSUM(NEWID())) % 4000) * @SeasonalFactor
        END AS revenue,
        0 AS profit,
        (20 + ABS(CHECKSUM(NEWID())) % 20) AS margin,
        0 AS units_sold
    FROM (
        SELECT TOP 10 store_id, region_id 
        FROM dbo.dim_stores 
        ORDER BY NEWID()
    ) s
    CROSS JOIN (
        SELECT TOP 5 product_id 
        FROM dbo.dim_products 
        ORDER BY NEWID()
    ) p;
    
    SET @TotalRecords = @TotalRecords + @@ROWCOUNT;
    
    -- Progress indicator
    IF @DayCounter % 10 = 0
    BEGIN
        PRINT '  Progress: Day ' + CAST(@DayCounter AS VARCHAR(5)) + 
              ' of ' + CAST(@DaysToGenerate AS VARCHAR(5)) + 
              ' (' + CAST(@TotalRecords AS VARCHAR(10)) + ' records so far)';
    END
    
    SET @CurrentDate = DATEADD(DAY, 1, @CurrentDate);
END

PRINT '';
PRINT 'Inserted ' + CAST(@TotalRecords AS VARCHAR(10)) + ' fact records';

-- ============================================
-- CALCULATE DERIVED FIELDS
-- ============================================

PRINT '';
PRINT 'Calculating profit and units_sold...';

UPDATE dbo.fact_kpi_metrics
SET 
    profit = ROUND(revenue * (margin / 100.0), 2),
    units_sold = CAST(revenue / (50 + ABS(CHECKSUM(NEWID())) % 150) AS INT)
WHERE profit = 0 OR units_sold = 0;

PRINT 'Updated ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' records';

-- ============================================
-- VERIFICATION
-- ============================================

PRINT '';
PRINT '============================================';
PRINT 'FACT DATA VERIFICATION';
PRINT '============================================';

-- Record count
DECLARE @FactCount INT = (SELECT COUNT(*) FROM dbo.fact_kpi_metrics);
PRINT '';
PRINT 'Total Records: ' + CAST(@FactCount AS VARCHAR(10));

-- Date range
SELECT 
    MIN(metric_date) AS [First Date],
    MAX(metric_date) AS [Last Date],
    DATEDIFF(DAY, MIN(metric_date), MAX(metric_date)) + 1 AS [Days Covered],
    COUNT(DISTINCT metric_date) AS [Unique Dates]
FROM dbo.fact_kpi_metrics;

-- Daily summary (last 7 days)
PRINT '';
PRINT 'Daily KPI Summary (Last 7 Days):';
SELECT TOP 7
    metric_date,
    FORMAT(SUM(revenue), 'N0') AS total_revenue,
    FORMAT(SUM(profit), 'N0') AS total_profit,
    FORMAT(AVG(margin), 'N1') AS avg_margin,
    FORMAT(SUM(units_sold), 'N0') AS total_units,
    COUNT(*) AS transaction_count
FROM dbo.fact_kpi_metrics
GROUP BY metric_date
ORDER BY metric_date DESC;

-- Sample records
PRINT '';
PRINT 'Sample Records (Most Recent):';
SELECT TOP 5 
    metric_date,
    store_id,
    product_id,
    FORMAT(revenue, 'N2') AS revenue,
    FORMAT(profit, 'N2') AS profit,
    FORMAT(margin, 'N2') AS margin,
    units_sold
FROM dbo.fact_kpi_metrics 
ORDER BY metric_date DESC, metric_id DESC;

-- Check for data quality issues
PRINT '';
PRINT 'Data Quality Checks:';
SELECT 
    'Records with NULL revenue' AS [Check],
    COUNT(*) AS [Issues]
FROM dbo.fact_kpi_metrics
WHERE revenue IS NULL
UNION ALL
SELECT 
    'Records with negative revenue',
    COUNT(*)
FROM dbo.fact_kpi_metrics
WHERE revenue < 0
UNION ALL
SELECT 
    'Records with zero units',
    COUNT(*)
FROM dbo.fact_kpi_metrics
WHERE units_sold = 0;

PRINT '';
PRINT '============================================';
PRINT 'Fact table populated successfully!';
PRINT 'Ready for pricing changes (run Script 2C next)';
PRINT '============================================';
GO