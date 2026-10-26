USE [IowaClinic];
GO

-- Load raw data into BRONZE layer
SELECT TOP 10 * FROM bronze_cms.shared_savings_program

EXEC bronze_cms.ingest_shared_savings_program
    @FilePath = 'C:\CMS\County_level_Aggregate_Expenditure_and_Risk_Score_Data_on_Assignable_Beneficiaries_2025_oc1.csv',
    @UUID = '7763a2ea-d25d-4061-8e11-f023b6df1c2d';

SELECT TOP 10 * FROM bronze_cms.shared_savings_program


-- Clean bronze data and load into SILVER layer
SELECT TOP 10 * FROM silver_cms.shared_savings_program

EXEC silver_cms.clean_shared_savings_program -- @StateName = 'OHIO', @CountyNumber = 88

SELECT TOP 10 * FROM silver_cms.shared_savings_program


-- Create GOLD table for BI input
SELECT * FROM gold_cms.shared_savings_program

EXEC gold_cms.load_shared_savings_program

SELECT * FROM gold_cms.shared_savings_program


------------------------------------------------
-- Option2 for GOLD
------------------------------------------------

-- Create 'global' schema
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'global')
BEGIN
    EXEC('CREATE SCHEMA [global]');
END;
GO

-- Create the target table for county fips table
IF OBJECT_ID('global.county_fips', 'U') IS NOT NULL
    DROP TABLE global.county_fips;
GO

-- Create Iowa County Fips
WITH cte_unique_Iowa_counties AS (
    SELECT DISTINCT 
        state_name, county_name
    FROM silver_cms.shared_savings_program
    WHERE state_name = 'IOWA'
)
SELECT 
    state_name, county_name,
    (ROW_NUMBER() OVER (ORDER BY county_name ASC) * 2) - 1 + 19000 AS fips
INTO global.county_fips
FROM cte_unique_Iowa_counties
ORDER BY county_name ASC;

SELECT * FROM global.county_fips;


-- LookUp table for eligibility groups
IF OBJECT_ID('gold_cms.lkp_eligibility_groups', 'U') IS NULL
BEGIN
    CREATE TABLE [gold_cms].[lkp_eligibility_groups] (
        [id]                     INT IDENTITY (1, 1) PRIMARY KEY CLUSTERED,
        eligibility_groups       VARCHAR(4),
        eligibility_groups_name  VARCHAR(256),
        created_timestamp        DATETIME2 DEFAULT GETDATE()
    );
    PRINT 'Success: Table  has been created.';
END
ELSE
BEGIN
    PRINT 'WARNING: Table [gold_cms].[lkp_eligibility_groups] already exists. Skipping creation.';
END;

INSERT INTO [gold_cms].[lkp_eligibility_groups] (
    eligibility_groups, 
    eligibility_groups_name
)
VALUES 
    ('ESRD',  'ESRD'),
    ('DIS',   'DISABLED'),
    ('AGDU',  'AGED/DUAL'),
    ('AGND',  'AGED/NON-DUAL');

-- Check the lookup table
SELECT * FROM [gold_cms].[lkp_eligibility_groups]


-- Create GOLD table for BI input
SELECT * FROM gold_cms.shared_savings_program_2 

EXEC gold_cms.load_shared_savings_program_2

SELECT * FROM gold_cms.shared_savings_program_2 

-- These two tables need to be pushed only once to BI tool 
SELECT * FROM [gold_cms].[lkp_eligibility_groups]
SELECT * FROM global.county_fips;
