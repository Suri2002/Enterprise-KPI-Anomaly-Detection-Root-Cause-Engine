---Create Database---
Use master;
Go
If Not Exists(Select name from sys.databases Where name = 'AnomalyDetectionDB')
Begin
   Create Database AnomalyDetectionDB;
End
Go

Use AnomalyDetectionDB;
go

---Drop existing tables---
If Object_ID('dbo.root_cause_drivers', 'U') is Not Null Drop Table dbo.root_cause_drivers;
If Object_ID('dbo.anomaly_log', 'U') Is Not Null Drop Table dbo.anomaly_log;
If Object_ID('dbo.pricing_Changes', 'U') Is Not Null Drop Table dbo.pricing_changes;
If Object_ID('dbo.fact_kpi_metrics', 'U') Is Not Null Drop Table dbo.fact_kpi_metric;
If Object_ID('dbo.dim_stores', 'U') Is Not Null Drop Table dbo.dim_stores;
If Object_ID('dbo.dim_products', 'U') Is Not Null Drop Table dbo.dim_products;
If Object_ID('dbo.dim_regions', 'U') Is Not Null Drop Table dbo.dim_regions;
Go

---Dimension Tables---

--Regions Dimension---
Create Table dbo.dim_regions (
    region_id Int Primary key,
	region_name Varchar(100) Not Null,
	country Varchar(50) Not Null,
	created_at Datetime2 Default GetDate(),
	updated_at Datetime2 Default GetDate()
);
go

---Stores Dimension---
Create Table dbo.dim_stores(
     store_id INT Primary Key,
	 store_name Varchar(100) Not Null,
	 region_id INT NOT Null,
	 store_type Varchar(50) NOT NUll,
	 created_at Datetime2 Default GetDate(),
	 updated_at Datetime2 Default getDate(),
	 Constraint Fk_store_region Foreign Key(region_id)
	      References dbo.dim_regions(region_id)
);
Go

Create Index idx_store_region On dbo.dim_stores(region_id);
Go

---Products Dimensions---
Create Table dbo.dim_products(
    product_id Int Primary Key,
	product_name Varchar(200) NOT Null,
	category Varchar(100) Not Null,
	Subcategory Varchar(100) Not Null,
	created_at datetime2 Default GetDate(),
	updated_at Datetime2 Default GetDate()
);
go

Create Index idx_product_category ON dbo.dim_products(category);
Go

---Fact Table---
Create Table dbo.fact_kpi_metrics(
   metric_id BigInt identity(1,1) primary Key,
   metric_date Date Not Null,
   store_id Int Not Null,
   product_id Int Not null,
   region_id Int Not Null,
   profit Decimal(15,2) Not Null,
   margin Decimal(5,2) Not Null,
   units_sold Int not Null,
   created_at DateTime2 Default GetDate(),
   Constraint FK_Metrics_Store Foreign Key (store_id)
       references dbo.dim_stores(store_id),
	Constraint FK_Metrics_region Foreign Key(region_id)
	   references dbo.dim_products(product_id),
	Constraint FK_Metrics_regions Foreign Key (region_id)
	   references dbo.dim_regions(region_id)
);
Go

----Create indexes for better query performance---
Create Index idx_metrics_data On dbo.fact_Kpi_metrics(metric_date);
Create Index idx_metrics_store On dbo.fact_kpi_metrics(store_id);
Create index idx_metrics_product On dbo.fact_kpi_metrics(product_id);
Create Index idx_metrics_region On dbo.fact_kpi_metrics(region_id);
Create Index idx_metrics_date_store ON dbo.fact_Kpi_metrics(metric_date, Store_id);
Create Index idx_metrics_date_product On dbo.fact_Kpi_metrics(metric_date, product_id);
Go

---Anomaly Detection Tables---

---Anomaly log table---
Create table dbo.anomaly_log(
    anomaly_id BigInt identity(1,1) Primary key,
	detection_date Datetime2 Default GetDate(),
	metric_date Date Not Null,
	Kpi_type varchar(50) Not Null,
	anomaly_score Decimal(10,4) not Null,
	expected_value Decimal(15,2) Not Null,
	actual_value Decimal(15,2) Not Null,
	deviation_percent Decimal(10,2) Not Null,
	severity Varchar(20) Not Null,
	status Varchar(20) Default 'new',
	narrative Text Null,
	assigned_to varchar(100) Null,
	resolved_date Datetime2 Null,
	resoultion_notes Text Null,
	Constraint Chk_Kpi_type Check (Kpi_type IN ('revenue', 'profit', 'margin')),
	Constraint Chk_Severity Check (severity IN ('critical', 'high', 'medium', 'low')),
	Constraint CHK_Status Check(status IN ('new', 'investigating', 'resolved', 'false_postive'))
);
Go

Create index idx_anomaly_date ON dbo.anomaly_log(metric_date);
Create Index idx_anomaly_kpi ON dbo.anomaly_log(Kpi_type);
Create Index idx_anomaly_severity ON dbo.anomaly_log(severity);
Create Index idx_anomaly_status ON dbo.anomaly_log(status);
Create index idx_anomaly_detection_date ON dbo.anomaly_log(detection_date);
Go

---Root Cause Drivers table----
Create Table dbo.root_cause_drivers(
    drivers_id BigInt identity(1,1) Primary Key,
	anomaly_id BigInt Not Null,
	driver_type Varchar(50) Not Null,
	driver_entity_id Int Not Null,
	driver_entity_name varchar(200) Not Null,
	contribution_percent Decimal(10,2) Not Null,
	impact_value Decimal(15,2) Not Null,
	created_at Datetime2 Default getdate(),
	Constraint Fk_Driver_Anomaly Foreign key (anomaly_id)
	     References dbo.anomaly_log(anomaly_id) On Delete Cascade,
	Constraint Chk_Driver_type Check(driver_type IN ('store', 'product', 'region', 'pricing'))
);
Go
Create Index idx_driver_anomaly ON dbo.root_cause_drivers(anomaly_id);
Create Index idx_drivers_type ON dbo.root_cause_drivers(driver_type);
Go

---Pricing Changes Table---
Create TAble dbo.pricing_changes(
   change_id Bigint identity(1,1) Primary key,
   product_id int Not Null,
   change_date Date Not null,
   old_price Decimal(10,2) Not Null,
   new_price Decimal(10,2) Not null,
   Price_change_percent Decimal(10,2) Not Null,
   change_reason Varchar(500) Null,
   created_at Datetime2 Default GetDate(),
   Constraint FK_Pricing_product Foreign Key (product_id)
      references dbo.dim_products(product_id)
);
Go
Create Index idx_pricing_date ON dbo.pricing_changes(change_date);
Create Index idx_pricing_Product ON dbo.Pricing_changes(product_id);
go

Print 'Database schema created succcessfully';
go

