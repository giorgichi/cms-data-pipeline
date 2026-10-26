USE [IowaClinic]; 
GO

-- Function to convert EXPENDITURES and NUMBER of BENEFICIARIES to numeric value
CREATE OR ALTER FUNCTION silver_cms.fn_clean_cms_decimal_2
(
    @raw_value VARCHAR(100)
)
RETURNS DECIMAL(18,2)
AS
BEGIN
    -- Declare local variable to store the cleaned input 
    DECLARE @clean_string VARCHAR(100) = TRIM(@raw_value);

    -- Return NULL if the string matches missing/suppressed flags or empty values
    IF @clean_string IN ('.', '*', '') OR @clean_string IS NULL
    BEGIN
        RETURN NULL;
    END

    -- Return the safely converted decimal value
    RETURN TRY_CAST(@clean_string AS DECIMAL(18,2));
END;
GO

-- Function to convert RISK SCORES to numeric value
CREATE OR ALTER FUNCTION silver_cms.fn_clean_cms_decimal_5
(
    @raw_value VARCHAR(100)
)
RETURNS DECIMAL(10,5)
AS
BEGIN
    -- Declare local variable to store the cleaned input 
    DECLARE @clean_string VARCHAR(100) = TRIM(@raw_value);

    -- Return NULL if the string matches missing/suppressed flags or empty values
    IF @clean_string IN ('.', '*', '') OR @clean_string IS NULL
    BEGIN
        RETURN NULL;
    END

    -- Return the safely converted decimal value
    RETURN TRY_CAST(@clean_string AS DECIMAL(10,5));
END;
GO


-- Function to convert EXPENDITURES and NUMBER of BENEFICIARIES to numeric value
CREATE OR ALTER FUNCTION silver_cms.fn_clean_cms_decimal_2G
(
    @raw_value VARCHAR(100)
)
RETURNS DECIMAL(18,2)
AS
BEGIN
    -- Declare local variable to store the cleaned input 
    DECLARE @clean_string VARCHAR(100) = TRIM(@raw_value);

    -- Return NULL if the string matches missing flags or empty values
    IF @clean_string IN ('.', '') OR @clean_string IS NULL
    BEGIN
        RETURN NULL;
    END

    -- Return -9999 if the string matches suppressed flags
    IF @clean_string = '*'
    BEGIN
        RETURN -9999.00;
    END

    -- Return the safely converted decimal value
    RETURN TRY_CAST(@clean_string AS DECIMAL(18,2));
END;
GO

-- Function to convert RISK SCORES to numeric value
CREATE OR ALTER FUNCTION silver_cms.fn_clean_cms_decimal_5G
(
    @raw_value VARCHAR(100)
)
RETURNS DECIMAL(10,5)
AS
BEGIN
    -- Declare local variable to store the cleaned input 
    DECLARE @clean_string VARCHAR(100) = TRIM(@raw_value);

    -- Return NULL if the string matches missing flags or empty values
    IF @clean_string IN ('.', '') OR @clean_string IS NULL
    BEGIN
        RETURN NULL;
    END

    -- Return -9999 if the string matches suppressed flags
    IF @clean_string = '*'
    BEGIN
        RETURN -9999.00000;
    END

    -- Return the safely converted decimal value
    RETURN TRY_CAST(@clean_string AS DECIMAL(10,5));
END;
GO