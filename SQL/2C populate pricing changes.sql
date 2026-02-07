-- ============================================
-- SCRIPT 2C: POPULATE PRICING CHANGES
-- ============================================

USE AnomalyDetectionDB;
GO

-- Check Prerequisites
DECLARE @ProductCount INT = (SELECT COUNT(*) FROM dbo.dim_products);
DECLARE @FactCount INT = (SELECT COUNT(*) FROM dbo.fact_kpi_metrics);

IF @ProductCount < 100
BEGIN
   PRINT '==================================';
   PRINT 'Error: Products table not ready';
   PRINT 'Please run Script 2A first';
   PRINT '==================================';
   RETURN;
END

IF @FactCount < 1000
BEGIN
   PRINT '===================================';
   PRINT 'Error: Fact table not ready';
   PRINT 'Please run Script 2B first';
   PRINT '===================================';
   RETURN;
END

PRINT '======================================';
PRINT 'Populating Pricing Changes';
PRINT '======================================';
PRINT '';

-- Clear Existing Pricing Changes
DECLARE @ExistingCount INT = (SELECT COUNT(*) FROM dbo.pricing_changes);

IF @ExistingCount > 0
BEGIN
   DELETE FROM dbo.pricing_changes;
   PRINT 'Cleared ' + CAST(@ExistingCount AS VARCHAR(10)) + ' existing pricing changes';
   PRINT '';
END

-- Generate Pricing Changes
PRINT 'Generating pricing changes (last 90 days)...';

-- Insert 30 pricing changes over the last 90 days
INSERT INTO dbo.pricing_changes
     (product_id, change_date, old_price, new_price, price_change_percent, change_reason)
SELECT TOP 30
    p.product_id,
    DATEADD(DAY, -(ABS(CHECKSUM(NEWID())) % 90), CAST(GETDATE() AS DATE)) AS change_date,
    ROUND(50.0 + (ABS(CHECKSUM(NEWID())) % 150), 2) AS old_price,
    ROUND(50.0 + (ABS(CHECKSUM(NEWID())) % 150), 2) AS new_price,  -- ✓ FIXED: Added closing )
    0.0 AS price_change_percent,
    CASE (ABS(CHECKSUM(NEWID())) % 6)
       WHEN 0 THEN 'Seasonal Promotion'
       WHEN 1 THEN 'Cost Adjustment'
       WHEN 2 THEN 'Competitive Pricing'
       WHEN 3 THEN 'Clearance Sale'
       WHEN 4 THEN 'Market Correction'
       ELSE 'Supplier Price Change'
    END AS change_reason
FROM dbo.dim_products p
ORDER BY NEWID();

DECLARE @InsertedCount INT = @@ROWCOUNT;
PRINT 'Inserted ' + CAST(@InsertedCount AS VARCHAR(10)) + ' pricing changes';

-- Calculate Price Change Percentage
PRINT '';
PRINT 'Calculating price change percentage...';

UPDATE dbo.pricing_changes
SET price_change_percent = ROUND(((new_price - old_price) / old_price * 100.0), 2)
WHERE old_price > 0;

PRINT 'Updated ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' records';

-- Verification
PRINT '';
PRINT '============================================';
PRINT 'Pricing Changes Verification';
PRINT '============================================';

-- Total count
DECLARE @TotalChanges INT = (SELECT COUNT(*) FROM dbo.pricing_changes);
PRINT '';
PRINT 'Total Pricing Changes: ' + CAST(@TotalChanges AS VARCHAR(10));

-- Date Range
PRINT '';
PRINT 'Date Range:';
SELECT 
    MIN(change_date) AS [First Change],
    MAX(change_date) AS [Last Change],
    COUNT(DISTINCT change_date) AS [Unique Dates]
FROM dbo.pricing_changes;

-- Summary by reason
PRINT '';
PRINT 'Pricing Changes by Reason:';
SELECT 
    change_reason,
    COUNT(*) AS change_count,
    FORMAT(AVG(price_change_percent), 'N2') + '%' AS avg_price_change,
    FORMAT(MIN(price_change_percent), 'N2') + '%' AS min_change,
    FORMAT(MAX(price_change_percent), 'N2') + '%' AS max_change
FROM dbo.pricing_changes
GROUP BY change_reason
ORDER BY change_count DESC;

-- Distribution of price changes
PRINT '';
PRINT 'Price Change Distribution:';
SELECT 
    Change_category,
	Count(*) AS [Count]
From(
    Select
    CASE
       WHEN price_change_percent < -20 THEN 'Large Decrease (< -20%)'
       WHEN price_change_percent < -10 THEN 'Medium Decrease (-20% to -10%)'
       WHEN price_change_percent < 0 THEN 'Small Decrease (0% to -10%)'
       WHEN price_change_percent = 0 THEN 'No Change (0%)'
       WHEN price_change_percent < 10 THEN 'Small Increase (0% to 10%)'
       WHEN price_change_percent < 20 THEN 'Medium Increase (10% to 20%)'
       ELSE 'Large Increase (> 20%)'
    END AS change_category,
    CASE
       WHEN price_change_percent < -20 THEN 1
       WHEN price_change_percent < -10 THEN 2
       WHEN price_change_percent < 0 THEN 3
       WHEN price_change_percent = 0 THEN 4
       WHEN price_change_percent < 10 THEN 5
       WHEN price_change_percent < 20 THEN 6
       ELSE 7
    END AS sort_order
  From dbo.pricing_changes
)AS categorized_changes
Group by change_category, sort_order
Order By sort_order;

-- Sample pricing changes with product details
PRINT '';
PRINT 'Sample Pricing Changes (Most Recent):';
SELECT TOP 10
    pc.change_date,
    p.product_name,
    p.category,
    FORMAT(pc.old_price, 'C2') AS old_price,      
    FORMAT(pc.new_price, 'C2') AS new_price,      
    FORMAT(pc.price_change_percent, 'N2') + '%' AS change_percent,
    pc.change_reason
FROM dbo.pricing_changes pc
INNER JOIN dbo.dim_products p ON pc.product_id = p.product_id
ORDER BY pc.change_date DESC;

-- Data quality checks
PRINT '';
PRINT 'Data Quality Checks:';
SELECT
    'Records with NULL Values' AS [Check],
    COUNT(*) AS [Issues]
FROM dbo.pricing_changes
WHERE product_id IS NULL
    OR change_date IS NULL
    OR old_price IS NULL
    OR new_price IS NULL
UNION ALL
SELECT
    'Records with negative prices',
    COUNT(*)
FROM dbo.pricing_changes
WHERE old_price < 0 OR new_price < 0
UNION ALL
SELECT
    'Records with zero prices',
    COUNT(*)
FROM dbo.pricing_changes
WHERE old_price = 0 OR new_price = 0
UNION ALL
SELECT
    'Records with invalid product_id',
    COUNT(*)
FROM dbo.pricing_changes pc
LEFT JOIN dbo.dim_products p ON pc.product_id = p.product_id
WHERE p.product_id IS NULL;

-- Products with Most Price Changes
PRINT '';
PRINT 'Products with Most Price Changes:';
SELECT TOP 5
     p.product_name,
     p.category,
     COUNT(*) AS change_count,
     FORMAT(AVG(pc.price_change_percent), 'N2') + '%' AS avg_change
FROM dbo.pricing_changes pc
INNER JOIN dbo.dim_products p ON pc.product_id = p.product_id
GROUP BY p.product_name, p.category           
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC;

PRINT '';
PRINT '=========================================';
PRINT 'Pricing changes populated successfully';
PRINT 'Data generation complete';
PRINT 'Ready for Script 3 (Views & Stored Procedures)';
PRINT '=========================================';
GO