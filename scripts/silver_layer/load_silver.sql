USE [data_warehouse]
GO
/****** Object:  StoredProcedure [silver].[prc_load_silver]    Script Date: 8/20/2026 1:27:23 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [silver].[prc_load_silver]
AS
BEGIN
    SET NOCOUNT ON;

/*
Script: Silver layer refresh from Bronze
Purpose: Clean and load silver-layer tables from bronze staging tables.

Behavior summary:
- For each target table in the `silver` schema, this script deletes existing rows
  and inserts transformed/cleaned data selected from the corresponding `bronze` table.
- The script prints section headers, per-table actions, and durations to make execution traceable.

Important notes / warnings:
- This script performs destructive DELETE operations on silver tables. Existing data will be removed.
  Ensure you intend to replace silver contents before running this on production systems.
- The script assumes transformations are safe and that source data types are compatible with the
  casts used. Review and test on a development instance first.
- Remove or adjust hard-coded logic (e.g., file paths, business rules) as needed.
*/

    SET NOCOUNT ON;

    PRINT N'=================================================================';
    PRINT N' Starting Silver layer refresh from Bronze - ' + CONVERT(nvarchar(30), GETDATE(), 121);
    PRINT N'=================================================================';

    BEGIN TRY

        DECLARE @load_start DATETIME = GETDATE();
        DECLARE @section_start DATETIME;
        DECLARE @section_end DATETIME;

        ------------------------------------------------------------------
        -- CRM section
        ------------------------------------------------------------------
        PRINT N'-----------------------------------------------------------------';
        PRINT N' CRM SOURCE: Begin loading CRM tables into [silver]';
        PRINT N'-----------------------------------------------------------------';

        -- silver.crm_cust_info
        SET @section_start = GETDATE();
        PRINT N'[CRM] silver.crm_cust_info - Action: DELETE existing rows';
        DELETE FROM silver.crm_cust_info;

        PRINT N'[CRM] silver.crm_cust_info - Action: INSERT cleaned latest records from bronze.crm_cust_info';
        INSERT INTO silver.crm_cust_info (
               [cst_id]
              ,[cst_key]
              ,[cst_firstname]
              ,[cst_lastname]
              ,[cst_marital_status]
              ,[cst_gndr]
              ,[cst_create_date]
        )
        SELECT 
               [cst_id]
              ,[cst_key]
              ,TRIM([cst_firstname]) [cst_firstname]
              ,TRIM([cst_lastname]) [cst_lastname]
              ,CASE 
                WHEN UPPER(TRIM([cst_marital_status])) = 'S' THEN 'Single'
                WHEN UPPER(TRIM([cst_marital_status])) = 'M' THEN 'Married'
                ELSE 'n/a'
                END [cst_marital_status]
              ,CASE 
                WHEN UPPER(TRIM([cst_gndr])) = 'M' THEN 'Male'
                WHEN UPPER(TRIM([cst_gndr])) = 'F' THEN 'Female'
                ELSE 'n/a'
                END [cst_gndr]
              ,[cst_create_date]
        FROM (
          SELECT 
                *,
                ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) flag_last
            FROM bronze.crm_cust_info
        ) aa
        WHERE flag_last = 1 AND cst_id IS NOT NULL;

        SET @section_end = GETDATE();
        PRINT N'[CRM] silver.crm_cust_info - Completed. Duration: ' + CAST(DATEDIFF(second, @section_start, @section_end) AS nvarchar(10)) + ' seconds';
        PRINT N'';

        -- silver.crm_prd_info
        SET @section_start = GETDATE();
        PRINT N'[CRM] silver.crm_prd_info - Action: DELETE existing rows';
        DELETE FROM silver.crm_prd_info;

        PRINT N'[CRM] silver.crm_prd_info - Action: INSERT transformed product records from bronze.crm_prd_info';
        INSERT INTO silver.crm_prd_info (
               [prd_id]
              ,[cat_id]
              ,[prd_key]
              ,[prd_nm]
              ,[prd_cost]
              ,[prd_line]
              ,[prd_start_dt]
              ,[prd_end_dt]
        )
        SELECT
             [prd_id]
            ,REPLACE(SUBSTRING([prd_key],1,5), '-', '_') prd_cat_id
            ,SUBSTRING([prd_key],7) prd_id
            ,[prd_nm]
            ,COALESCE([prd_cost], 0) [prd_cost]
            ,CASE UPPER(TRIM([prd_line]))
                WHEN 'M' THEN 'Mountain'
                WHEN 'S' THEN 'Other Sales'
                WHEN 'R' THEN 'Road'
                WHEN 'T' THEN 'Touring'
             ELSE 'n/a'
             END [prd_line]
            ,[prd_start_dt]
            ,DATEADD(day, -1, LEAD([prd_start_dt]) OVER(PARTITION BY prd_key ORDER BY prd_start_dt ASC)) [prd_end_dt]
        FROM bronze.crm_prd_info;

        SET @section_end = GETDATE();
        PRINT N'[CRM] silver.crm_prd_info - Completed. Duration: ' + CAST(DATEDIFF(second, @section_start, @section_end) AS nvarchar(10)) + ' seconds';
        PRINT N'';

        -- silver.crm_sales_details
        SET @section_start = GETDATE();
        PRINT N'[CRM] silver.crm_sales_details - Action: DELETE existing rows';
        DELETE FROM silver.crm_sales_details;

        PRINT N'[CRM] silver.crm_sales_details - Action: INSERT cleaned sales details from bronze.crm_sales_details';
        INSERT INTO silver.crm_sales_details (
               [sls_ord_num]
              ,[sls_prd_key]
              ,[sls_cust_id]
              ,[sls_order_dt]
              ,[sls_ship_dt]
              ,[sls_due_dt]
              ,[sls_sales]
              ,[sls_quantity]
              ,[sls_price]
        )
        SELECT 
               [sls_ord_num]
              ,[sls_prd_key]
              ,[sls_cust_id]
              ,CASE 
                    WHEN [sls_order_dt] <= 0 OR LEN(CAST([sls_order_dt] AS varchar(50))) <> 8 THEN NULL
                    ELSE CAST(CAST(sls_order_dt AS varchar(50)) AS date)
                END [sls_order_dt]
              ,CASE 
                    WHEN [sls_ship_dt] <= 0 OR LEN(CAST([sls_ship_dt] AS varchar(50))) <> 8 THEN NULL
                    ELSE CAST(CAST(sls_ship_dt AS varchar(50)) AS date)
                END [sls_ship_dt]
              ,CASE 
                    WHEN [sls_due_dt] <= 0 OR LEN(CAST([sls_due_dt] AS varchar(50))) <> 8 THEN NULL
                    ELSE CAST(CAST(sls_due_dt AS varchar(50)) AS date)
                END [sls_due_dt]
              ,CASE WHEN (
                    sls_sales != sls_quantity * sls_price OR
                    sls_sales <= 0 OR
                    sls_sales IS NULL
                    )
                    AND (sls_price IS NOT NULL AND sls_price != 0)
                    THEN sls_quantity * ABS(sls_price)
                    ELSE sls_sales
                END sls_sales
              ,sls_quantity
              ,CASE WHEN sls_price IS NULL THEN sls_sales / sls_quantity ELSE ABS(sls_price) END sls_price
        FROM [data_warehouse].[bronze].[crm_sales_details];

        SET @section_end = GETDATE();
        PRINT N'[CRM] silver.crm_sales_details - Completed. Duration: ' + CAST(DATEDIFF(second, @section_start, @section_end) AS nvarchar(10)) + ' seconds';
        PRINT N'';

        PRINT N'-----------------------------------------------------------------';
        PRINT N' CRM SOURCE: Completed';
        PRINT N'-----------------------------------------------------------------';

        ------------------------------------------------------------------
        -- ERP section
        ------------------------------------------------------------------
        PRINT N'-----------------------------------------------------------------';
        PRINT N' ERP SOURCE: Begin loading ERP tables into [silver]';
        PRINT N'-----------------------------------------------------------------';

        -- silver.erp_cust_az12
        SET @section_start = GETDATE();
        PRINT N'[ERP] silver.erp_cust_az12 - Action: DELETE existing rows';
        DELETE FROM silver.erp_cust_az12;

        PRINT N'[ERP] silver.erp_cust_az12 - Action: INSERT transformed customer records from bronze.erp_cust_az12';
        INSERT INTO silver.erp_cust_az12 (
            cid,
            bdate,
            gen
        )
        SELECT 
            CASE WHEN a.cid LIKE 'NAS%' THEN SUBSTRING(a.cid, 4) ELSE a.cid END cid,
            CASE WHEN a.BDATE > GETDATE() THEN NULL ELSE a.BDATE END BDATE,
            CASE 
                WHEN LOWER(LTRIM(RTRIM(a.GEN))) IN ('f', 'female') THEN 'Female'
                WHEN LOWER(LTRIM(RTRIM(a.GEN))) IN ('m', 'male') THEN 'Male'
                ELSE 'n/a'
            END GEN
        FROM bronze.erp_cust_az12 a;

        SET @section_end = GETDATE();
        PRINT N'[ERP] silver.erp_cust_az12 - Completed. Duration: ' + CAST(DATEDIFF(second, @section_start, @section_end) AS nvarchar(10)) + ' seconds';
        PRINT N'';

        -- silver.erp_loc_a101
        SET @section_start = GETDATE();
        PRINT N'[ERP] silver.erp_loc_a101 - Action: DELETE existing rows';
        DELETE FROM silver.erp_loc_a101;

        PRINT N'[ERP] silver.erp_loc_a101 - Action: INSERT cleaned location data from bronze.erp_loc_a101';
        INSERT INTO silver.erp_loc_a101 (
            cid,
            cntry
        )
        SELECT 
            REPLACE(cid,'-','') cid, 
            CASE 
                WHEN LOWER(LTRIM(RTRIM(CNTRY))) = '' OR LOWER(LTRIM(RTRIM(CNTRY))) IS NULL THEN 'n/a' 
                WHEN LOWER(LTRIM(RTRIM(CNTRY))) = 'de' THEN 'Germany'
                WHEN LOWER(LTRIM(RTRIM(CNTRY))) IN ('us', 'usa') THEN 'United States'
                ELSE TRIM(CNTRY)
            END cntry
        FROM bronze.erp_loc_a101;

        SET @section_end = GETDATE();
        PRINT N'[ERP] silver.erp_loc_a101 - Completed. Duration: ' + CAST(DATEDIFF(second, @section_start, @section_end) AS nvarchar(10)) + ' seconds';
        PRINT N'';

        -- silver.erp_px_cat_g1v2
        SET @section_start = GETDATE();
        PRINT N'[ERP] silver.erp_px_cat_g1v2 - Action: DELETE existing rows';
        DELETE FROM [silver].[erp_px_cat_g1v2];

        PRINT N'[ERP] silver.erp_px_cat_g1v2 - Action: INSERT cleaned category data from bronze.erp_px_cat_g1v2';
        INSERT INTO [silver].[erp_px_cat_g1v2] (
                   [id]
                   ,[cat]
                   ,[subcat]
                   ,[maintenance]
        )
        SELECT  
               [ID]
              ,TRIM([CAT]) [CAT]
              ,TRIM([SUBCAT]) [SUBCAT]
              ,[MAINTENANCE]
        FROM  bronze.erp_px_cat_g1v2;

        SET @section_end = GETDATE();
        PRINT N'[ERP] silver.erp_px_cat_g1v2 - Completed. Duration: ' + CAST(DATEDIFF(second, @section_start, @section_end) AS nvarchar(10)) + ' seconds';
        PRINT N'';

        PRINT N'-----------------------------------------------------------------';
        PRINT N' ERP SOURCE: Completed';
        PRINT N'-----------------------------------------------------------------';

        ------------------------------------------------------------------
        -- Overall duration
        ------------------------------------------------------------------
        DECLARE @load_end DATETIME = GETDATE();
        PRINT N'Total Silver layer load duration: ' + CAST(DATEDIFF(second, @load_start, @load_end) AS nvarchar(10)) + ' seconds';
        PRINT N'Completed at: ' + CONVERT(nvarchar(30), @load_end, 121);

    END TRY
    BEGIN CATCH
        PRINT N'------------------- Error during Silver layer refresh -------------------';
        PRINT N'Error Message: ' + ERROR_MESSAGE();
        PRINT N'Error Number : ' + CAST(ERROR_NUMBER() AS nvarchar(10));
        PRINT N'Error State  : ' + CAST(ERROR_STATE() AS nvarchar(10));
        PRINT N'Error Line   : ' + CAST(ERROR_LINE() AS nvarchar(10));
        PRINT N'Error Proc   : ' + ISNULL(ERROR_PROCEDURE(), N'');
        PRINT N'---------------------------------------------------------------------------';
        THROW;
    END CATCH

END
