/*
    This script creates the necessary tables in the bronze layer for stage one of the data pipeline.
    It includes tables for CRM information, product information, sales details, and ERP data.
*/


IF OBJECT_ID('bronze.crm_one_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_one_info;
GO

CREATE TABLE bronze.crm_one_info (
    ctm_id              INT,
    ctm_key             NVARCHAR(50),
    stm_firstname       NVARCHAR(50),
    stm_lastname        NVARCHAR(50),
    stm_marital_status  NVARCHAR(50),
    ctm_gndr            NVARCHAR(50),
    ctm_create_date     DATE
);
GO

IF OBJECT_ID('bronze.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_prd_info;
GO

CREATE TABLE bronze.crm_prd_info (
    prd_id       INT,
    prd_key      NVARCHAR(50),
    prd_nm       NVARCHAR(50),
    prd_cost     INT,
    prd_line     NVARCHAR(50),
    prd_start_dt DATETIME,
    prd_end_dt   DATETIME
);
GO

IF OBJECT_ID('bronze.crm_sales_deatils','U') IS NOT NULL
    DROP TABLE bronze.crm_sales_details;
GO

CREATE TABLE bronze.crm_sales_details (
    prd_id       INT,
    prd_key      NVARCHAR(50),
    prd_nm       NVARCHAR(50),
    prd_cost     INT,
    prd_line     NVARCHAR(50),
    prd_start_dt DATETIME,
    prd_end_dt   DATETIME
);
GO

IF OBJECT_ID('bronze.erp_loc_a101','U') IS NOT NULL
    DROP TABLE bronze.erp_loc_a101;
GO  

CREATE TABLE bronze.erp_loc_a101(
    cid  NVARCHAR(50),
    cntry NVARCHAR(50),
);
GO


IF OBJECT_ID('bronze.erp_cust_az12', 'U') IS NOT NULL
    DROP TABLE bronze.erp_cust_az12;
GO

CREATE TABLE bronze.erp_cust_az12 (
    cid    NVARCHAR(50),
    bdate  DATE,
    gen    NVARCHAR(50)
);
GO

IF OBJECT_ID('bronze.erp_px_cat_g1v2','U') IS NOT NULL
    DROP TABLE bronze.erp_px_cat_g1v2;
GO

CREATE TABLE bronze.erp_px_cat_g1v2 (
    id        NVARCHAR(50),
    cat       NVARCHAR(50),
    subcat    NVARCHAR(50),
    maintanance NVARCHAR(50)
);
GO