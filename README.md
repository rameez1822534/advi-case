# Credit Institution Data Pipeline and Data Warehouse Overview

This project involves setting up an automated data pipeline using Azure Data Factory (ADF) and Snowflake to extract, transform, and load data into a data warehouse. The goal is to provide a scalable, flexible, and understandable data model that supports business requirements and future growth.

## Components

- **Azure Data Factory (ADF):** Used for data extraction, transformation, and loading (ETL).
- **Snowflake:** Used as the data warehouse for storing transformed data and providing analytical capabilities.

## Project Requirements

### Key Components

#### Automated Data Pipeline:

- Extract and transform data from existing IT systems.
- Include data quality checks for accuracy, completeness, and consistency.
- Manage medium quantities of data, estimated to be in the range of millions of new rows per year.
- Justification for technology choices: Azure Data Factory for ETL and Snowflake for warehousing.

#### Expandable Data Model:

- Accommodate existing data and allow for future requirements.
- Prioritize clarity and business relevance.
- Handle flexible business requirements and support reruns due to data quality issues.
- Ensure scalability to handle expected data growth.

## Architecture

### Data Flow

#### Data Ingestion:

Use ADF pipelines to ingest data from various sources into Snowflake staging tables. Implement data flows in ADF for transformation.

#### Data Transformation:

Transform data in ADF using data flows. Load transformed data into Snowflake staging tables.

#### Data Loading:

Load data from staging tables into Snowflake data warehouse.

## Data Model

### Dimension Tables

- **Dim_Customers:** Stores customer information.
- **Dim_Account_Types:** Stores different types of accounts.
- **Dim_Account_Names:** Stores different account names.
- **Dim_Deposit_Types:** Stores types of deposits.
- **Dim_Loan_Types:** Stores types of loans.
- **Dim_Countries:** Stores country information.
- **Dim_Dates:** Stores date information for time-series analysis.

### Fact Tables

- **Fact_Accounts:** Stores account transaction data.
- **Fact_Deposits:** Stores deposit transaction data.
- **Fact_Loans:** Stores loan transaction data.

### Task Scheduling in Snowflake

- **Load Dimension Tables:** Create tasks in Snowflake to populate dimension tables.
- **Load Fact Tables:** Create tasks in Snowflake to populate fact tables after loading dimension tables.
- **Activate Tasks:** Resume the tasks and check task history.

## Data Model Explanation

- **Dim_Customers:** Represents customers and their types.
- **Dim_Account_Types:** Represents different types of accounts.
- **Dim_Account_Names:** Represents names of accounts.
- **Dim_Deposit_Types:** Represents different types of deposits.
- **Dim_Loan_Types:** Represents different types of loans.
- **Dim_Countries:** Represents countries and their codes.
- **Dim_Dates:** Represents dates and their attributes (year, month, day).

### Fact Tables

- **Fact_Accounts:** Records account transactions including the amount, reference date, account type, and account name.
- **Fact_Deposits:** Records deposit transactions including the amount, currency, exchange rate, start date, maturity date, reference date, customer, deposit type, and country.
- **Fact_Loans:** Records loan transactions including the amount, currency, exchange rate, start date, maturity date, reference date, customer, loan type, and country.

### ERD Diagram

Include a visual representation of the ERD (Entity Relationship Diagram) showing the relationships between dimension and fact tables.

## Dashboard Creation

### Basic SQL Queries for Visualization

- **Total Deposits by Month:** Query to aggregate total deposits by month.
- **Total Loans by Month:** Query to aggregate total loans by month.
- **Customer Distribution by Type:** Query to show the distribution of customers by type.

## Things To Do
- Error Logging in ADF and Snowflake
- Make pipeline more moduler by including parameters
- More data tranformations if possible 
- Email notification for pipeline error
- Create a proper dashboard


## Conclusion

This project demonstrates the integration of Azure Data Factory and Snowflake to create a robust and scalable data pipeline and data warehouse solution. The architecture supports future scalability, flexibility in handling business requirements, and ensures data quality and consistency.
