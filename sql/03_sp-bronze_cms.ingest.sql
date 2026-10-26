USE [IowaClinic];
GO

CREATE OR ALTER PROCEDURE [bronze_cms].[ingest_shared_savings_program]
    @FilePath NVARCHAR(MAX),
    @UUID     VARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- If no UUID is passed, generate a new one automatically
    IF @UUID IS NULL
    BEGIN
        SET @UUID = CAST(NEWID() AS VARCHAR(36));
        PRINT 'WARNING: UUID was not passed. A new UUID was automatically generated';
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Create a temporary staging table that match the columns of CSV file
        IF OBJECT_ID('tempdb..#staging_shared_savings') IS NOT NULL
            DROP TABLE #staging_shared_savings;

        CREATE TABLE #staging_shared_savings (
            [YEAR]                  VARCHAR(MAX),
            STATE_NAME              VARCHAR(MAX),
            COUNTY_NAME             VARCHAR(MAX),
            STATE_ID                VARCHAR(MAX),
            COUNTY_ID               VARCHAR(MAX),
            PER_CAPITA_EXP_ESRD     VARCHAR(MAX),
            AVG_RISK_SCORE_ESRD     VARCHAR(MAX),
            AVG_DEMOG_SCORE_ESRD    VARCHAR(MAX),
            PERSON_YEARS_ESRD       VARCHAR(MAX),
            PER_CAPITA_EXP_DIS      VARCHAR(MAX),
            AVG_RISK_SCORE_DIS      VARCHAR(MAX),
            AVG_DEMOG_SCORE_DIS     VARCHAR(MAX),
            PERSON_YEARS_DIS        VARCHAR(MAX),
            PER_CAPITA_EXP_AGDU     VARCHAR(MAX),
            AVG_RISK_SCORE_AGDU     VARCHAR(MAX),
            AVG_DEMOG_SCORE_AGDU    VARCHAR(MAX),
            PERSON_YEARS_AGDU       VARCHAR(MAX),
            PER_CAPITA_EXP_AGND     VARCHAR(MAX),
            AVG_RISK_SCORE_AGND     VARCHAR(MAX),
            AVG_DEMOG_SCORE_AGND    VARCHAR(MAX),
            PERSON_YEARS_AGND       VARCHAR(MAX)
        );

        -- Create dynamic BULK INSERT query
        -- GIO: SQL Server doesn't allow standard variables directly inside a BULK INSERT, 
        --      but we can build the entire SQL statement as a text string and pass it into sp_executesql
        DECLARE @BulkSql NVARCHAR(MAX) = N'
        BULK INSERT #staging_shared_savings
        FROM ''' + REPLACE((@FilePath), '''', '''''') + '''
        WITH (
            FORMAT = ''CSV'',
            FIRSTROW = 2,
            ROWTERMINATOR = ''\n'',
            TABLOCK
        );';

        -- Execute the query
        EXEC sp_executesql @BulkSql;

        -- Insert staging records into the bronze table
        INSERT INTO bronze_cms.shared_savings_program (
            [YEAR],
            STATE_NAME,
            COUNTY_NAME,
            STATE_ID,
            COUNTY_ID,
            PER_CAPITA_EXP_ESRD,
            AVG_RISK_SCORE_ESRD,
            AVG_DEMOG_SCORE_ESRD,
            PERSON_YEARS_ESRD,
            PER_CAPITA_EXP_DIS,
            AVG_RISK_SCORE_DIS,
            AVG_DEMOG_SCORE_DIS,
            PERSON_YEARS_DIS,
            PER_CAPITA_EXP_AGDU,
            AVG_RISK_SCORE_AGDU,
            AVG_DEMOG_SCORE_AGDU,
            PERSON_YEARS_AGDU,
            PER_CAPITA_EXP_AGND,
            AVG_RISK_SCORE_AGND,
            AVG_DEMOG_SCORE_AGND,
            PERSON_YEARS_AGND,
            UUID,
            source_name
            -- [id] and [ingestion_timestamp] auto-populate
        )
        SELECT 
            [YEAR],
            STATE_NAME,
            COUNTY_NAME,
            STATE_ID,
            COUNTY_ID,
            PER_CAPITA_EXP_ESRD,
            AVG_RISK_SCORE_ESRD,
            AVG_DEMOG_SCORE_ESRD,
            PERSON_YEARS_ESRD,
            PER_CAPITA_EXP_DIS,
            AVG_RISK_SCORE_DIS,
            AVG_DEMOG_SCORE_DIS,
            PERSON_YEARS_DIS,
            PER_CAPITA_EXP_AGDU,
            AVG_RISK_SCORE_AGDU,
            AVG_DEMOG_SCORE_AGDU,
            PERSON_YEARS_AGDU,
            PER_CAPITA_EXP_AGND,
            AVG_RISK_SCORE_AGND,
            AVG_DEMOG_SCORE_AGND,
            PERSON_YEARS_AGND,
            @UUID AS UUID,
            @FilePath AS source_name
        FROM #staging_shared_savings;

        -- Clean up staging table
        DROP TABLE #staging_shared_savings;

        -- Commit the transaction if all operations succeed
        COMMIT TRANSACTION;

        PRINT 'Data successfully ingested from file: ' + @FilePath;
    END TRY

    -- Catch the errors gracefully 
    BEGIN CATCH
        -- Roll back changes if an error occurs
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        -- Clean up temp table if created
        IF OBJECT_ID('tempdb..#staging_shared_savings') IS NOT NULL
            DROP TABLE #staging_shared_savings;

        -- Raise the original error
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO