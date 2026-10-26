# CSM Data Pipeline

## Software/Tool Prerequisites  

**Database Engine**: Microsoft SQL Server Express 2022 or newer ([download](https://www.microsoft.com/en-us/sql-server/sql-server-downloads))  
**Tools**: Visual Studio Code ([download](https://code.visualstudio.com/download)) with the official [`SQL Server (mssql)`](https://marketplace.visualstudio.com/items?itemName=ms-mssql.mssql) extension installed.  

## Access & Permissions Requirements  
**Server Connection**: Ensure the SQL Server Express instance (.\SQLEXPRESS) is actively connected to Visual Studio Code using the `mssql` extension.  
**File Access & Location**: Place source CSV files in a folder path directly accessible by the SQL Server service (e.g., C:\sql_imports\), ensuring the SQL Server engine has read permissions to execute BULK INSERT without access errors.  
**Permissions**: User must have `CREATE ANY DATABASE`, `CREATE SCHEMA`, and `BULK INSERT` permissions.  


## CSM Data

**Data**: County-level Aggregate Expenditure and Risk Score Data on Assignable Beneficiaries  
**Year**: 2025  
**Version**: oc1 (Off-cycle)  
**URL**: [data.csm.gov](https://data.cms.gov/medicare-shared-savings-program/county-level-aggregate-expenditure-and-risk-score-data-on-assignable-beneficiaries/data)  

