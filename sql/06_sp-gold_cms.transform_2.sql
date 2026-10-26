USE [IowaClinic];
GO

CREATE OR ALTER  PROCEDURE [gold_cms].[load_shared_savings_program_2]
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Clear Gold table before refreshing with the latest Silver batch
        TRUNCATE TABLE gold_cms.shared_savings_program_2;

        -- CTE to isolate latest batch (deduplicate) & transform from wide to long format
        WITH cte_long AS (
            SELECT 
            s.year,
            s.state_name,
            s.county_name,
            u.eligibility_group,
            u.per_capita_expenditure,
            u.avg_risk_score,
            u.avg_demog_score,
            u.person_years
        FROM silver_cms.shared_savings_program s
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
        ),
        cte_with_fips AS (
            SELECT 
                f.fips, 
                s.year, 
                s.eligibility_group, 
                s.per_capita_expenditure, 
                s.avg_risk_score, 
                s.avg_demog_score,
                s.person_years
            FROM cte_long AS s
            LEFT JOIN global.county_fips AS f 
            ON s.state_name = f.state_name AND s.county_name = f.county_name
        )
        INSERT INTO gold_cms.shared_savings_program_2 (
            fips,
            year,
            eligibility_group,
            per_capita_expenditure,
            avg_risk_score,
            avg_demog_score,
            person_years
        )
        SELECT 
            fips, 
            year,
            eligibility_group,
            per_capita_expenditure,
            avg_risk_score,
            avg_demog_score,
            person_years
        FROM cte_with_fips;

        COMMIT TRANSACTION;
        PRINT 'SUCCESS: Gold table gold_cms.shared_savings_program_2 loaded successfully.';

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
