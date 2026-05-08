CREATE OR ALTER PROCEDURE bronze.prod_load_bronze AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME, @batch_end_time DATETIME;
    SET @batch_start_time = GETDATE();
    PRINT 'Starting the Bronze layer load process...';
    PRINT('----------------------------------------');
    PRINT('Loading crm tables into Bronze layer...');
    print('----------------------------------------');

    SET @start_time = GETDATE();
    PRINT '>>Truncating the tables in Bronze layer...';
    TRUNCATE TABLE bronze.crm_one_info;
    PRINT '>> Inserting data into bronze.crm_one_info...';
    BULK INSERT bronze.crm_one_info
    FROM 'C:\dataset\source_crm\crm_one_info.csv'
    WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '\n',
        TABLOCK
    );
    