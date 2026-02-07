-- SCRIPT 2A: POPULATE DIMENSION TABLES (FIXED)--
-- Description: Inserts reference data--

USE AnomalyDetectionDB;
GO

PRINT '============================================';
PRINT 'POPULATING DIMENSION TABLES';
PRINT '============================================';

-- ============================================
-- STEP 1: CLEAR EXISTING DATA (if any)
-- ============================================

PRINT '';
PRINT 'Clearing existing dimension data...';

DELETE FROM dbo.dim_stores;
DELETE FROM dbo.dim_products;
DELETE FROM dbo.dim_regions;

PRINT 'Existing data cleared';
GO


-- STEP 2: INSERT REGIONS (MUST BE FIRST!)--

PRINT '';
PRINT 'Inserting regions...';

INSERT INTO dbo.dim_regions (region_id, region_name, country)
VALUES 
    (1, 'North America East', 'USA'),
    (2, 'North America West', 'USA'),
    (3, 'Europe', 'Multi-Country'),
    (4, 'Asia Pacific', 'Multi-Country'),
    (5, 'Latin America', 'Multi-Country');

PRINT 'Inserted ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' regions';

-- Verify regions
SELECT 
    region_id,
    region_name,
    country
FROM dbo.dim_regions
ORDER BY region_id;

GO

-- STEP 3: INSERT STORES--


PRINT '';
PRINT 'Inserting stores...';

DECLARE @StoreCounter INT = 1;

WHILE @StoreCounter <= 50
BEGIN
    INSERT INTO dbo.dim_stores (store_id, store_name, region_id, store_type)
    VALUES (
        @StoreCounter,
        'Store_' + RIGHT('000' + CAST(@StoreCounter AS VARCHAR(3)), 3),
        ((@StoreCounter - 1) % 5) + 1,  -- Cycles through regions 1-5
        CASE 
            WHEN @StoreCounter % 3 = 0 THEN 'Mall'
            WHEN @StoreCounter % 3 = 1 THEN 'Standalone'
            ELSE 'Online'
        END
    );
    
    SET @StoreCounter = @StoreCounter + 1;
END

PRINT 'Inserted 50 stores';

-- Show store distribution by region
PRINT '';
PRINT 'Store Distribution by Region:';
SELECT 
    r.region_name,
    s.store_type,
    COUNT(*) AS store_count
FROM dbo.dim_stores s
INNER JOIN dbo.dim_regions r ON s.region_id = r.region_id
GROUP BY r.region_name, s.store_type
ORDER BY r.region_name, s.store_type;
GO

-- STEP 4: INSERT PRODUCTS--

PRINT '';
PRINT 'Inserting products...';

DECLARE @ProductCounter INT = 1;

WHILE @ProductCounter <= 100
BEGIN
    INSERT INTO dbo.dim_products (product_id, product_name, category, subcategory)
    VALUES (
        @ProductCounter,
        'Product_' + RIGHT('000' + CAST(@ProductCounter AS VARCHAR(3)), 3),
        CASE 
            WHEN @ProductCounter % 4 = 0 THEN 'Electronics'
            WHEN @ProductCounter % 4 = 1 THEN 'Clothing'
            WHEN @ProductCounter % 4 = 2 THEN 'Food'
            ELSE 'Home & Garden'
        END,
        'Subcategory_' + CAST((@ProductCounter % 10) AS VARCHAR(2))
    );
    
    SET @ProductCounter = @ProductCounter + 1;
END

PRINT 'Inserted 100 products';

-- Show product distribution by category
PRINT '';
PRINT 'Product Distribution by Category:';
SELECT 
    category,
    COUNT(*) AS product_count
FROM dbo.dim_products
GROUP BY category
ORDER BY category;

GO

-- FINAL VERIFICATION --

PRINT '';
PRINT '============================================';
PRINT 'DIMENSION DATA VERIFICATION';
PRINT '============================================';

DECLARE @RegionCount INT;
DECLARE @StoreCount INT;
DECLARE @ProductCount INT;

SELECT @RegionCount = COUNT(*) FROM dbo.dim_regions;
SELECT @StoreCount = COUNT(*) FROM dbo.dim_stores;
SELECT @ProductCount = COUNT(*) FROM dbo.dim_products;

PRINT '';
PRINT 'Record Counts:';
SELECT 
    'Regions' AS [Dimension],
    @RegionCount AS [Count],
    'Expected: 5' AS [Status],
    CASE WHEN @RegionCount = 5 THEN 'PASS' ELSE 'FAIL' END AS [Result]
UNION ALL
SELECT 
    'Stores',
    @StoreCount,
    'Expected: 50',
    CASE WHEN @StoreCount = 50 THEN 'PASS' ELSE 'FAIL' END
UNION ALL
SELECT 
    'Products',
    @ProductCount,
    'Expected: 100',
    CASE WHEN @ProductCount = 100 THEN 'PASS' ELSE 'FAIL' END;

-- Check for foreign key integrity
PRINT '';
PRINT 'Data Integrity Check:';
SELECT 
    'Stores with invalid region_id' AS [Check],
    COUNT(*) AS [Issues]
FROM dbo.dim_stores s
LEFT JOIN dbo.dim_regions r ON s.region_id = r.region_id
WHERE r.region_id IS NULL;

-- Sample data
PRINT '';
PRINT 'Sample Stores (First 10):';
SELECT TOP 10
    s.store_id,
    s.store_name,
    s.store_type,
    r.region_name
FROM dbo.dim_stores s
INNER JOIN dbo.dim_regions r ON s.region_id = r.region_id
ORDER BY s.store_id;

PRINT '';
PRINT 'Sample Products (First 10):';
SELECT TOP 10
    product_id,
    product_name,
    category,
    subcategory
FROM dbo.dim_products
ORDER BY product_id;

PRINT '';
PRINT 'Dimension tables populated successfully!';
PRINT 'Ready for fact data (run Script 2B next)';
GO

-- ============================================
-- QUICK VERIFICATION BEFORE PROCEEDING
-- ============================================
USE AnomalyDetectionDB;
GO

PRINT 'Checking if Script 2A completed successfully...';
PRINT '';

DECLARE @RegionCount INT = (SELECT COUNT(*) FROM dbo.dim_regions);
DECLARE @StoreCount INT = (SELECT COUNT(*) FROM dbo.dim_stores);
DECLARE @ProductCount INT = (SELECT COUNT(*) FROM dbo.dim_products);

SELECT 
    'Regions' AS [Table],
    @RegionCount AS [Actual Count],
    5 AS [Expected Count],
    CASE WHEN @RegionCount = 5 THEN 'READY' ELSE 'NOT READY' END AS [Status]
UNION ALL
SELECT 
    'Stores',
    @StoreCount,
    50,
    CASE WHEN @StoreCount = 50 THEN 'READY' ELSE 'NOT READY' END
UNION ALL
SELECT 
    'Products',
    @ProductCount,
    100,
    CASE WHEN @ProductCount = 100 THEN 'READY' ELSE 'NOT READY' END;

-- Overall check
IF @RegionCount = 5 AND @StoreCount = 50 AND @ProductCount = 100
BEGIN
    PRINT '';
    PRINT '============================================';
    PRINT 'ALL DIMENSION TABLES READY';
    PRINT 'Safe to proceed with Script 2B';
    PRINT '============================================';
END
ELSE
BEGIN
    PRINT '';
    PRINT '============================================';
    PRINT 'DIMENSION TABLES INCOMPLETE';
    PRINT 'DO NOT run Script 2B yet';
    PRINT 'Re-run the FIXED Script 2A first';
    PRINT '============================================';
END
GO