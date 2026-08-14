/*
Purpose: Create a clean `data_warehouse` database and three schemas for layered data storage.

What this script will create:
- A database named: data_warehouse
- Schemas inside that database: bronze, silver, gold

Warning: This script contains a conditional DROP of `data_warehouse` if it already exists. 
If the database exists it will be dropped (all data and objects inside it will be permanently removed) and then recreated. 
Do NOT run this script on a production server unless you have an explicit, tested backup and you intend to destroy the existing database.
*/

SET NOCOUNT ON;

-- Switch to the instance `master` database to manage databases
USE master;

-- Safety: Only attempt to drop the database if it exists to prevent errors.
-- The drop sequence sets the database to SINGLE_USER with immediate rollback to ensure DROP succeeds
-- Wrap destructive actions in TRY/CATCH so errors are reported cleanly.
IF DB_ID(N'data_warehouse') IS NOT NULL
BEGIN
    PRINT N'Database "data_warehouse" exists. Dropping it to recreate...';
    BEGIN TRY
        ALTER DATABASE [data_warehouse] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
        DROP DATABASE [data_warehouse];
        print(N'data_warehouse database is dropped')
    END TRY
    BEGIN CATCH
        PRINT N'Error dropping database "data_warehouse": ' + ERROR_MESSAGE();
        THROW; -- re-raise to surface the error to the caller
    END CATCH
END
ELSE
BEGIN
    PRINT N'Database "data_warehouse" does not exist. Creating a new database.';
END

GO

-- Create the database. This is a DDL operation that will create a new empty database.
CREATE DATABASE data_warehouse;
print(N'data_warehouse database is created')
GO

-- Change context to the newly created database so subsequent schema creation occurs inside it.
USE data_warehouse;
GO

-- Create the `bronze` schema. Bronze is typically raw ingested data.
CREATE SCHEMA bronze

GO
print(N'bronze schema is created')
GO

-- Create the `silver` schema. Silver is typically cleaned/standardized data.
CREATE SCHEMA silver

GO
print(N'silver schema is created')
GO

-- Create the `gold` schema. Gold is typically curated, production-ready data.
CREATE SCHEMA gold

GO
print(N'gold schema is created')
