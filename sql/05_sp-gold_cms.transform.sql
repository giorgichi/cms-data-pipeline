USE [IowaClinic];
GO

CREATE OR ALTER PROCEDURE [gold_cms].[load_shared_savings_program]
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Clear Gold table before refreshing with the latest Silver batch
        TRUNCATE TABLE gold_cms.shared_savings_program;

        -- CTE to isolate latest batch (deduplicate) & transform from wide to long format
        WITH cte_latest_silver_records AS (
            SELECT 
                year,
                state_name,
                county_name,
                state_id,
                county_id,
                -- ESRD Metrics
                per_capita_exp_esrd,
                avg_risk_score_esrd,
                avg_demog_score_esrd,
                person_years_esrd,
                -- DIS Metrics
                per_capita_exp_dis,
                avg_risk_score_dis,
                avg_demog_score_dis,
                person_years_dis,
                -- AGDU Metrics
                per_capita_exp_agdu,
                avg_risk_score_agdu,
                avg_demog_score_agdu,
                person_years_agdu,
                -- AGND Metrics
                per_capita_exp_agnd,
                avg_risk_score_agnd,
                avg_demog_score_agnd,
                person_years_agnd,
                processed_timestamp,
                ROW_NUMBER() OVER (
                    PARTITION BY year, state_id, county_id 
                    ORDER BY processed_timestamp DESC
                ) AS RowNum
            FROM silver_cms.shared_savings_program
        )
        INSERT INTO gold_cms.shared_savings_program (
            year,
            state_name,
            county_name,
            state_id,
            county_id,
            eligibility_group,
            per_capita_expenditure,
            avg_risk_score,
            avg_demog_score,
            person_years
        )
        SELECT 
            s.year,
            s.state_name,
            s.county_name,
            s.state_id,
            s.county_id,
            u.eligibility_group,
            u.per_capita_expenditure,
            u.avg_risk_score,
            u.avg_demog_score,
            u.person_years
        FROM cte_latest_silver_records s
        CROSS APPLY (
            VALUES 
                ('ESRD', s.per_capita_exp_esrd, s.avg_risk_score_esrd, s.avg_demog_score_esrd, s.person_years_esrd),
                ('DIS',  s.per_capita_exp_dis,  s.avg_risk_score_dis,  s.avg_demog_score_dis,  s.person_years_dis),
                ('AGDU', s.per_capita_exp_agdu, s.avg_risk_score_agdu, s.avg_demog_score_agdu, s.person_years_agdu),
                ('AGND', s.per_capita_exp_agnd, s.avg_risk_score_agnd, s.avg_demog_score_agnd, s.person_years_agnd)
        ) AS u (
            eligibility_group, 
            per_capita_expenditure, 
            avg_risk_score, 
            avg_demog_score, 
            person_years
        )
        WHERE s.RowNum = 1;

        COMMIT TRANSACTION;
        PRINT 'SUCCESS: Gold table gold_cms.shared_savings_program loaded successfully.';

    END TRY
    BEGIN CATCH
        -- Safely roll back transaction on failure
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();

        PRINT '==================================================';
        PRINT 'GOLD ETL LOAD FAILED!';
        PRINT 'Error Message: ' + @ErrorMessage;
        PRINT '==================================================';

        RAISERROR (@ErrorMessage, @ErrorSeverity, 1);
    END CATCH
END;
GO