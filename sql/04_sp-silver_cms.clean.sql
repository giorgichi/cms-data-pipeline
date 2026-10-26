USE [IowaClinic];
GO


CREATE OR ALTER PROCEDURE [silver_cms].[clean_shared_savings_program]
    @StateName NVARCHAR(100) = 'IOWA',
    @CountyNumber INT = 99
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @iowa_record_count INT = 0;
    DECLARE @invalid_year_count INT = 0;
    DECLARE @invalid_state_id_count INT = 0;
    DECLARE @invalid_county_id_count INT = 0;
    DECLARE @invalid_county_name_count INT = 0;

    BEGIN TRY
        BEGIN TRANSACTION;

        ------------------------------------------------------------------
        -- Pre-validation checks on Iowa data in Bronze
        ------------------------------------------------------------------

        -- Create a temporary table for runing quality checks before insterting into silver layer
        IF OBJECT_ID('tempdb..#cleaning_shared_savings') IS NOT NULL
            DROP TABLE #cleaning_shared_savings;

        WITH cte_dedup AS (
            SELECT 
                *,
                ROW_NUMBER() OVER (
                    PARTITION BY [YEAR], [STATE_ID], [COUNTY_ID] 
                    ORDER BY [ingestion_timestamp] DESC
                    ) AS RowNum
            FROM bronze_cms.shared_savings_program
            WHERE UPPER(TRIM(STATE_NAME)) = @StateName  
            )
            SELECT
                [id] AS [id],
                [YEAR] AS [year],
                [STATE_NAME] AS [state_name],
                [COUNTY_NAME] AS [county_name],
                [STATE_ID] AS [state_id],
                [COUNTY_ID] AS [county_id],
                [PER_CAPITA_EXP_ESRD] AS [per_capita_exp_esrd],
                [AVG_RISK_SCORE_ESRD] AS [avg_risk_score_esrd],
                [AVG_DEMOG_SCORE_ESRD] AS [avg_demog_score_esrd],
                [PERSON_YEARS_ESRD] AS [person_years_esrd],
                [PER_CAPITA_EXP_DIS] AS [per_capita_exp_dis],
                [AVG_RISK_SCORE_DIS] AS [avg_risk_score_dis],
                [AVG_DEMOG_SCORE_DIS] AS [avg_demog_score_dis],
                [PERSON_YEARS_DIS] AS [person_years_dis],
                [PER_CAPITA_EXP_AGDU] AS [per_capita_exp_agdu],
                [AVG_RISK_SCORE_AGDU] AS [avg_risk_score_agdu],
                [AVG_DEMOG_SCORE_AGDU] AS [avg_demog_score_agdu],
                [PERSON_YEARS_AGDU] AS [person_years_agdu],
                [PER_CAPITA_EXP_AGND] AS [per_capita_exp_agnd],
                [AVG_RISK_SCORE_AGND] AS [avg_risk_score_agnd],
                [AVG_DEMOG_SCORE_AGND] AS [avg_demog_score_agnd],
                [PERSON_YEARS_AGND] AS [person_years_agnd],
                [UUID] AS [uuid],
                [source_name] AS [source_name],
                [ingestion_timestamp] AS [ingestion_timestamp]
            INTO #cleaning_shared_savings
            FROM cte_dedup 
            WHERE 
            -- Select deduplicated records
            RowNum = 1
            -- Exclude years that already exist in the Silver layer
            AND NOT EXISTS (
                SELECT 1
                FROM silver_cms.shared_savings_program s
                WHERE s.[year] = TRY_CAST([YEAR] AS INT) AND s.[state_name] = @StateName
            );

        -- Check if there are new records to process
        SELECT @iowa_record_count = COUNT(*) FROM #cleaning_shared_savings;

        IF @iowa_record_count = 0
        BEGIN;
            PRINT 'No new Iowa records found to process.';
            RETURN;
        END;

        -- Verify total number of records (should be 99 for Iowa)
        IF @iowa_record_count <> @CountyNumber
        BEGIN;
            THROW 50001, 'Data Quality Error: Iowa dataset record count must be exactly 99.', 1;
        END;

        -- Verify YEAR length is 4 digits and is not blank
        SELECT @invalid_year_count = COUNT(*)
        FROM #cleaning_shared_savings
        WHERE LEN([YEAR]) <> 4 OR TRY_CAST([YEAR] AS INT) IS NULL;

        IF @invalid_year_count > 0
        BEGIN;
            THROW 50002, 'Data Quality Error: Found records where YEAR is not 4 digits.', 1;
        END;

        -- Verify STATE_ID length is 2
        SELECT @invalid_state_id_count = COUNT(*)
        FROM #cleaning_shared_savings
        WHERE LEN(state_id) <> 2;

        IF @invalid_state_id_count > 0
        BEGIN;
            THROW 50003, 'Data Quality Error: Found records where STATE_ID is not 2 characters.', 1;
        END;

        -- Verify COUNTY_ID length is less than 3
        SELECT @invalid_county_id_count = COUNT(*)
        FROM #cleaning_shared_savings
        WHERE LEN(county_id) > 3;

        IF @invalid_county_id_count > 0
        BEGIN;
            THROW 50004, 'Data Quality Error: Found records where COUNTY_ID is not 3 characters.', 1;
        END;

        -- Verify COUNTY_NAME is not blank
        SELECT @invalid_county_name_count = COUNT(*)
        FROM #cleaning_shared_savings
        WHERE county_name IS NULL;

        IF @invalid_county_name_count > 0
        BEGIN;
            THROW 50005, 'Data Quality Error: Found records where COUNTY_NAME is blank.', 1;
        END;

        ------------------------------------------------------------------
        -- Insert validated Iowa records into Silver
        ------------------------------------------------------------------
        WITH cte_ranked_iowa_bronze AS (
            SELECT 
                id AS bronze_id,
                CAST(year AS INT) AS year,
                UPPER(TRIM(state_name)) AS state_name,
                UPPER(TRIM(county_name)) AS county_name,
                state_id,
                county_id,
                silver_cms.fn_clean_cms_decimal_2(per_capita_exp_esrd) AS per_capita_exp_esrd,
                silver_cms.fn_clean_cms_decimal_5(avg_risk_score_esrd) AS avg_risk_score_esrd,
                silver_cms.fn_clean_cms_decimal_5(avg_demog_score_esrd) AS avg_demog_score_esrd,
                silver_cms.fn_clean_cms_decimal_2(person_years_esrd) AS person_years_esrd,
                silver_cms.fn_clean_cms_decimal_2(per_capita_exp_dis) AS per_capita_exp_dis,
                silver_cms.fn_clean_cms_decimal_5(avg_risk_score_dis) AS avg_risk_score_dis,
                silver_cms.fn_clean_cms_decimal_5(avg_demog_score_dis) AS avg_demog_score_dis,
                silver_cms.fn_clean_cms_decimal_2(person_years_dis) AS person_years_dis,
                silver_cms.fn_clean_cms_decimal_2(per_capita_exp_agdu) AS per_capita_exp_agdu,
                silver_cms.fn_clean_cms_decimal_5(avg_risk_score_agdu) AS avg_risk_score_agdu,
                silver_cms.fn_clean_cms_decimal_5(avg_demog_score_agdu) AS avg_demog_score_agdu,
                silver_cms.fn_clean_cms_decimal_2(person_years_agdu) AS person_years_agdu,
                silver_cms.fn_clean_cms_decimal_2(per_capita_exp_agnd) AS per_capita_exp_agnd,
                silver_cms.fn_clean_cms_decimal_5(avg_risk_score_agnd) AS avg_risk_score_agnd,
                silver_cms.fn_clean_cms_decimal_5(avg_demog_score_agnd) AS avg_demog_score_agnd,
                silver_cms.fn_clean_cms_decimal_2(person_years_agnd) AS person_years_agnd,
                uuid,
                source_name,
                ingestion_timestamp,
                ROW_NUMBER() OVER (
                    PARTITION BY year, state_id, county_id
                    ORDER BY ingestion_timestamp DESC, id DESC
                ) AS row_num
            FROM #cleaning_shared_savings
        )
        INSERT INTO silver_cms.shared_savings_program (
            bronze_id,
            year,
            state_name,
            county_name,
            state_id,
            county_id,
            per_capita_exp_esrd,
            avg_risk_score_esrd,
            avg_demog_score_esrd,
            person_years_esrd,
            per_capita_exp_dis,
            avg_risk_score_dis,
            avg_demog_score_dis,
            person_years_dis,
            per_capita_exp_agdu,
            avg_risk_score_agdu,
            avg_demog_score_agdu,
            person_years_agdu,
            per_capita_exp_agnd,
            avg_risk_score_agnd,
            avg_demog_score_agnd,
            person_years_agnd,
            uuid,
            source_name,
            ingestion_timestamp
        )
        SELECT 
            bronze_id,
            year,
            state_name,
            county_name,
            state_id,
            county_id,
            per_capita_exp_esrd,
            avg_risk_score_esrd,
            avg_demog_score_esrd,
            person_years_esrd,
            per_capita_exp_dis,
            avg_risk_score_dis,
            avg_demog_score_dis,
            person_years_dis,
            per_capita_exp_agdu,
            avg_risk_score_agdu,
            avg_demog_score_agdu,
            person_years_agdu,
            per_capita_exp_agnd,
            avg_risk_score_agnd,
            avg_demog_score_agnd,
            person_years_agnd,
            uuid,
            source_name,
            ingestion_timestamp
        FROM cte_ranked_iowa_bronze
        WHERE row_num = 1;

        COMMIT TRANSACTION;
        PRINT 'SUCCESS: All Iowa quality checks passed. 99 Iowa records successfully loaded into Silver.';

    END TRY
    BEGIN CATCH
        -- Rollback transaction on failure so no bad data is saved
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        -- Clean up temp table if created
        IF OBJECT_ID('tempdb..#cleaning_shared_savings') IS NOT NULL
            DROP TABLE #cleaning_shared_savings;

        -- Capture and log error details gracefully
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorNumber INT = ERROR_NUMBER();

        PRINT '==================================================';
        PRINT 'DATA QUALITY CHECK FAILED!';
        PRINT 'Error Code: ' + CAST(@ErrorNumber AS VARCHAR(10));
        PRINT 'Message: ' + @ErrorMessage;
        PRINT '==================================================';

        -- Re-raise error to caller
        RAISERROR (@ErrorMessage, 16, 1);
    END CATCH
END;
GO