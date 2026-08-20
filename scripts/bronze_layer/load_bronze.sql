USE [data_warehouse]
GO
/****** Object:  StoredProcedure [bronze].[prc_load_bronze]    Script Date: 8/20/2026 1:27:47 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [bronze].[prc_load_bronze]
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        DECLARE @start_time as datetime, @end_time as datetime
        DECLARE @start_load_bronze as datetime, @end_load_bronze as datetime;

        set @start_load_bronze = getdate()

        PRINT N'***********************************************************************'
        PRINT N' *************************Loading Bronze Layer*************************'
        PRINT N'***********************************************************************'
        print N''

        -- CRM section header
        PRINT N'========== CRM SOURCE: Begin loading CRM tables (bronze) ==========';
        print N''

        -- crm_cust_info
        set @start_time = getdate()

        PRINT N'[CRM] Table: bronze.crm_cust_info - Action: TRUNCATE';
        TRUNCATE TABLE bronze.crm_cust_info;

        PRINT N'[CRM] Table: bronze.crm_cust_info - Action: BULK INSERT from source file';
        BULK INSERT bronze.crm_cust_info FROM 'C:\Users\oamee\OneDrive\Courses\dwh_learning\project_files\datasets\source_crm\cust_info.csv'
            WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK);

        PRINT N'[CRM] Table: bronze.crm_cust_info - Status: COMPLETED';

        set @end_time = getdate()

        print N'Executoin Duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + ' seconds'

        print N'';

        -- crm_prd_info
        set @start_time = getdate()

        PRINT N'[CRM] Table: bronze.crm_prd_info - Action: TRUNCATE';
        TRUNCATE TABLE bronze.crm_prd_info;

        PRINT N'[CRM] Table: bronze.crm_prd_info - Action: BULK INSERT from source file';
        BULK INSERT bronze.crm_prd_info FROM 'C:\Users\oamee\OneDrive\Courses\dwh_learning\project_files\datasets\source_crm\prd_info.csv'
            WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK);

        PRINT N'[CRM] Table: bronze.crm_prd_info - Status: COMPLETED';

        set @end_time = getdate()

        print N'Executoin Duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + ' seconds'

        print N'';

        -- crm_sales_details
        set @start_time = getdate()

        PRINT N'[CRM] Table: bronze.crm_sales_details - Action: TRUNCATE';
        TRUNCATE TABLE bronze.crm_sales_details;

        PRINT N'[CRM] Table: bronze.crm_sales_details - Action: BULK INSERT from source file';
        BULK INSERT bronze.crm_sales_details FROM 'C:\Users\oamee\OneDrive\Courses\dwh_learning\project_files\datasets\source_crm\sales_details.csv'
            WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK);

        PRINT N'[CRM] Table: bronze.crm_sales_details - Status: COMPLETED';

        set @end_time = getdate()

        print N'Executoin Duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + ' seconds'

        print N''

        PRINT N'========== CRM SOURCE: Completed ==========';
        print N''

        -- ERP section header
        PRINT N'========== ERP SOURCE: Begin loading ERP tables (bronze) ==========';
        print N''

        -- erp_cust_az12
        set @start_time = getdate()

        PRINT N'[ERP] Table: bronze.erp_cust_az12 - Action: TRUNCATE';
        TRUNCATE TABLE bronze.erp_cust_az12;

        PRINT N'[ERP] Table: bronze.erp_cust_az12 - Action: BULK INSERT from source file';
        BULK INSERT bronze.erp_cust_az12 FROM 'C:\Users\oamee\OneDrive\Courses\dwh_learning\project_files\datasets\source_erp\CUST_AZ12.csv'
            WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK);

        PRINT N'[ERP] Table: bronze.erp_cust_az12 - Status: COMPLETED';

        set @end_time = getdate()

        print N'Executoin Duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + ' seconds'

        print N'';

        -- erp_loc_a101
        set @start_time = getdate()

        PRINT N'[ERP] Table: bronze.erp_loc_a101 - Action: TRUNCATE';
        TRUNCATE TABLE bronze.erp_loc_a101;
        PRINT N'[ERP] Table: bronze.erp_loc_a101 - Action: BULK INSERT from source file';

        BULK INSERT bronze.erp_loc_a101 FROM 'C:\Users\oamee\OneDrive\Courses\dwh_learning\project_files\datasets\source_erp\loc_a101.csv'
            WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK);

        PRINT N'[ERP] Table: bronze.erp_loc_a101 - Status: COMPLETED';

        set @end_time = getdate()

        print N'Executoin Duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + ' seconds'

        print N'';

        -- erp_px_cat_g1v2
        set @start_time = getdate()

        PRINT N'[ERP] Table: bronze.erp_px_cat_g1v2 - Action: TRUNCATE';
        TRUNCATE TABLE bronze.erp_px_cat_g1v2;

        PRINT N'[ERP] Table: bronze.erp_px_cat_g1v2 - Action: BULK INSERT from source file';
        BULK INSERT bronze.erp_px_cat_g1v2 FROM 'C:\Users\oamee\OneDrive\Courses\dwh_learning\project_files\datasets\source_erp\px_cat_g1v2.csv'
            WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK);

        PRINT N'[ERP] Table: bronze.erp_px_cat_g1v2 - Status: COMPLETED';

        set @end_time = getdate()

        print N'Executoin Duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + ' seconds'
        
        print N''
        PRINT N'========== ERP SOURCE: Completed ==========';
        print N''

        set @end_load_bronze = getdate()

        print N'Loading Bronze Layer Duration: ' + cast(datediff(second, @start_load_bronze, @end_load_bronze) as nvarchar) + ' seconds'


    END TRY
    BEGIN CATCH

        print N'-------------------There is Error happened-------------------'
        print N''

        print N'Error Message: ' + error_message();
        print N'Error Number: ' + cast(error_number() as nvarchar);
        print N'Error State: ' + cast(error_state() as nvarchar);
        print N''
        
        print N'-------------------------------------------------------------';

    END CATCH

END
