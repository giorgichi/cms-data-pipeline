----------------------------------------------------
-- CREATE DATABASE
----------------------------------------------------

-- Check if IowaClinic database already exists; if it doesn't, create it
IF NOT EXISTS (SELECT name
               FROM sys.databases
               WHERE name = N'IowaClinic')
    CREATE DATABASE IowaClinic;

USE [IowaClinic]; 
GO


----------------------------------------------------
-- CREATE SCHEMAS
----------------------------------------------------

-- Check if the BRONZE schema already exists; if it doesn't, create it
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'bronze_cms')
    BEGIN
        EXEC('CREATE SCHEMA bronze_cms;');
        PRINT 'Success: Schema [bronze_cms] has been created.';
    END;
    ELSE
    BEGIN
        PRINT 'WARNING: Schema [bronze_cms] already exists. Skipping creation.';
    END;

-- Check if the SILVER schema already exists; if it doesn't, create it
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'silver_cms')
    BEGIN
        EXEC('CREATE SCHEMA silver_cms;');
        PRINT 'Success: Schema [silver_cms] has been created.';
    END;
    ELSE
    BEGIN
        PRINT 'WARNING: Schema [silver_cms] already exists. Skipping creation.';
    END;

-- Check if the GOLD schema already exists; if it doesn't, create it
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'gold_cms')
    BEGIN
        EXEC('CREATE SCHEMA gold_cms;');
        PRINT 'Success: Schema [gold_cms] has been created.';
    END;
    ELSE
    BEGIN
        PRINT 'WARNING: Schema [gold_cms] already exists. Skipping creation.';
    END;


----------------------------------------------------
-- CREATE TABLES
----------------------------------------------------

-- Check if the BRONZE table already exists; if it doesn't, create it
IF OBJECT_ID('bronze_cms.shared_savings_program', 'U') IS NULL
BEGIN
    CREATE TABLE [bronze_cms].[shared_savings_program] (
        [id]                     INT IDENTITY (1, 1) PRIMARY KEY CLUSTERED,
        [YEAR]                   VARCHAR(MAX) NOT NULL,
        STATE_NAME               VARCHAR(MAX) NOT NULL,
        COUNTY_NAME              VARCHAR(MAX),  -- there is a blank county name, so we have to drop NOT NULL
        STATE_ID                 VARCHAR(MAX) NOT NULL,
        COUNTY_ID                VARCHAR(MAX),  -- there is a blank county id, so we have to drop NOT NULL
        PER_CAPITA_EXP_ESRD      VARCHAR(MAX),
        AVG_RISK_SCORE_ESRD      VARCHAR(MAX),
        AVG_DEMOG_SCORE_ESRD     VARCHAR(MAX),
        PERSON_YEARS_ESRD        VARCHAR(MAX),
        PER_CAPITA_EXP_DIS       VARCHAR(MAX),
        AVG_RISK_SCORE_DIS       VARCHAR(MAX),
        AVG_DEMOG_SCORE_DIS      VARCHAR(MAX),
        PERSON_YEARS_DIS         VARCHAR(MAX),
        PER_CAPITA_EXP_AGDU      VARCHAR(MAX),
        AVG_RISK_SCORE_AGDU      VARCHAR(MAX),
        AVG_DEMOG_SCORE_AGDU     VARCHAR(MAX),
        PERSON_YEARS_AGDU        VARCHAR(MAX),
        PER_CAPITA_EXP_AGND      VARCHAR(MAX),
        AVG_RISK_SCORE_AGND      VARCHAR(MAX),
        AVG_DEMOG_SCORE_AGND     VARCHAR(MAX),
        PERSON_YEARS_AGND        VARCHAR(MAX),
        UUID                     VARCHAR(MAX) NOT NULL,
        source_name              VARCHAR(MAX) NOT NULL,
        ingestion_timestamp      DATETIME2 DEFAULT GETDATE()
    );
    PRINT 'Success: Table  has been created.';
END
ELSE
BEGIN
    PRINT 'WARNING: Table [bronze_cms].[shared_savings_program] already exists. Skipping creation.';
END;


-- Check if the SILVER table already exists; if it doesn't, create it
IF OBJECT_ID('silver_cms.shared_savings_program', 'U') IS NULL
BEGIN
    CREATE TABLE [silver_cms].[shared_savings_program] (
        id                         INT IDENTITY(1,1) PRIMARY KEY, 
        bronze_id                  INT NOT NULL,                  -- lineage link to bronze table
        year                       INT NOT NULL,                  
        state_name                 VARCHAR(4) NOT NULL,
        county_name                VARCHAR(100) NOT NULL,             
        state_id                   VARCHAR(2) NOT NULL,
        county_id                  VARCHAR(3) NOT NULL,
        per_capita_exp_esrd        DECIMAL(18,2) NULL,
        avg_risk_score_esrd        DECIMAL(10,5) NULL,
        avg_demog_score_esrd       DECIMAL(10,5) NULL,
        person_years_esrd          DECIMAL(18,2) NULL,
        per_capita_exp_dis         DECIMAL(18,2) NULL,
        avg_risk_score_dis         DECIMAL(10,5) NULL,
        avg_demog_score_dis        DECIMAL(10,5) NULL,
        person_years_dis           DECIMAL(18,2) NULL,
        per_capita_exp_agdu        DECIMAL(18,2) NULL,
        avg_risk_score_agdu        DECIMAL(10,5) NULL,
        avg_demog_score_agdu       DECIMAL(10,5) NULL,
        person_years_agdu          DECIMAL(18,2) NULL,
        per_capita_exp_agnd        DECIMAL(18,2) NULL,
        avg_risk_score_agnd        DECIMAL(10,5) NULL,
        avg_demog_score_agnd       DECIMAL(10,5) NULL,
        person_years_agnd          DECIMAL(18,2) NULL,
        uuid                       VARCHAR(36) NOT NULL,
        source_name                VARCHAR(255) NOT NULL,
        ingestion_timestamp        DATETIME NOT NULL,
        processed_timestamp        DATETIME DEFAULT GETDATE(),
        -- Add a composite unique constraint and name using following convention [Prefix]_[TableName]_[Columns]
        CONSTRAINT uq_shared_savings_program_year_state_county 
            UNIQUE (year, state_id, county_id)
    );
    PRINT 'Success: Table  has been created.';
END
ELSE
BEGIN
    PRINT 'WARNING: Table [silver_cms].[shared_savings_program] already exists. Skipping creation.';
END;


-- Check if the GOLD table already exists; if it doesn't, create it
IF OBJECT_ID('gold_cms.shared_savings_program', 'U') IS NULL
BEGIN
    CREATE TABLE gold_cms.shared_savings_program (
        year                  INT NOT NULL,
        state_name            VARCHAR(4) NOT NULL,
        county_name           VARCHAR(100) NOT NULL,
        state_id              VARCHAR(2) NOT NULL,
        county_id             VARCHAR(3) NOT NULL,
        eligibility_group     VARCHAR(10) NOT NULL, -- options: 'ESRD', 'DIS', 'AGDU', 'AGND'
        -- 4 new individual metric categories
        per_capita_expenditure DECIMAL(18,2) NULL,
        avg_risk_score         DECIMAL(10,5) NULL,
        avg_demog_score        DECIMAL(10,5) NULL,
        person_years           DECIMAL(18,2) NULL,
        created_timestamp      DATETIME2 DEFAULT GETUTCDATE() NOT NULL,
        CONSTRAINT PK_uq_shared_savings_program_year_state_county_group PRIMARY KEY CLUSTERED 
        (
            year ASC,
            state_id ASC,
            county_id ASC,
            eligibility_group ASC
        )
    );
    PRINT 'Success: Table  has been created.';
END
ELSE
BEGIN
    PRINT 'WARNING: Table [gold_cms].[shared_savings_program] already exists. Skipping creation.';
END;


-- Check if the GOLD table already exists; if it doesn't, create it
IF OBJECT_ID('gold_cms.shared_savings_program_2', 'U') IS NULL
BEGIN
CREATE TABLE gold_cms.shared_savings_program_2
(
    year                   INT NOT NULL,
    fips                   INT NOT NULL,
    eligibility_group      VARCHAR(10) NOT NULL, -- options: 'ESRD', 'DIS', 'AGDU', 'AGND'
    per_capita_expenditure DECIMAL(18,2) NULL,
    avg_risk_score         DECIMAL(10,5) NULL,
    avg_demog_score        DECIMAL(10,5) NULL,
    person_years           DECIMAL(18,2) NULL,
    created_timestamp      DATETIME2 DEFAULT GETUTCDATE() NOT NULL,
    CONSTRAINT PK_uq_shared_savings_program_year_state_county_group_2 PRIMARY KEY CLUSTERED 
    (
        year ASC,
        fips ASC,
        eligibility_group ASC
    )
);
END

