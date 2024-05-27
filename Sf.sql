-- Suspend the root task if it exists
ALTER TASK IF EXISTS Load_Dimensions SUSPEND;

-- Suspend the dependent task if it exists
ALTER TASK IF EXISTS Load_Facts SUSPEND;

-- Drop the tasks if they exist
DROP TASK IF EXISTS Load_Dimensions;
DROP TASK IF EXISTS Load_Facts;

-- Create Database
CREATE DATABASE IF NOT EXISTS CreditInstitution;

USE DATABASE CreditInstitution;

-- Create Public Schema
CREATE SCHEMA IF NOT EXISTS Public;

-- Create Staging Schema
CREATE SCHEMA IF NOT EXISTS Staging;

-- Create Data Warehouse Schema
CREATE SCHEMA IF NOT EXISTS DataWarehouse;

-- Create Warehouse
CREATE OR REPLACE WAREHOUSE my_warehouse
WITH WAREHOUSE_SIZE = 'XSMALL'
AUTO_SUSPEND = 300
AUTO_RESUME = TRUE
INITIALLY_SUSPENDED = TRUE;

-- Switch to Staging Schema
USE SCHEMA Staging;

-- Drop Streams and Staging Tables if they exist
DROP STREAM IF EXISTS Accounts_Stream;
DROP STREAM IF EXISTS Deposits_Stream;
DROP STREAM IF EXISTS Loans_Stream;

DROP TABLE IF EXISTS Accounts_Staging;
DROP TABLE IF EXISTS Deposits_Staging;
DROP TABLE IF EXISTS Loans_Staging;

-- Create Staging Tables
CREATE TABLE Accounts_Staging (
    account_number INT,
    amount DECIMAL,
    account_name VARCHAR,
    account_type VARCHAR,
    reference_date DATE
);

CREATE TABLE Deposits_Staging (
    customer VARCHAR,
    customer_type VARCHAR,
    deposit_type VARCHAR,
    country VARCHAR,
    amount DECIMAL,
    currency VARCHAR,
    exchange_rate DECIMAL,
    start_date DATE,
    maturity_date DATE,
    reference_date DATE
);

CREATE TABLE Loans_Staging (
    customer VARCHAR,
    customer_type VARCHAR,
    loan_type VARCHAR,
    country VARCHAR,
    amount DECIMAL,
    currency VARCHAR,
    exchange_rate DECIMAL,
    start_date DATE,
    maturity_date DATE,
    reference_date DATE
);

-- Create Streams for Staging Tables
CREATE OR REPLACE STREAM Accounts_Stream ON TABLE Accounts_Staging;
CREATE OR REPLACE STREAM Deposits_Stream ON TABLE Deposits_Staging;
CREATE OR REPLACE STREAM Loans_Stream ON TABLE Loans_Staging;

-- Switch to DataWarehouse Schema
USE SCHEMA DataWarehouse;

-- Drop Dimension and Fact Tables if they exist
DROP TABLE IF EXISTS Dim_Customers;
DROP TABLE IF EXISTS Dim_Account_Types;
DROP TABLE IF EXISTS Dim_Account_Names;
DROP TABLE IF EXISTS Dim_Deposit_Types;
DROP TABLE IF EXISTS Dim_Loan_Types;
DROP TABLE IF EXISTS Dim_Countries;
DROP TABLE IF EXISTS Dim_Dates;
DROP TABLE IF EXISTS Fact_Accounts;
DROP TABLE IF EXISTS Fact_Deposits;
DROP TABLE IF EXISTS Fact_Loans;

-- Create Dimension Tables
CREATE TABLE Dim_Customers (
    customer_key INT AUTOINCREMENT PRIMARY KEY,
    customer_id VARCHAR,
    customer_type VARCHAR
);

CREATE TABLE Dim_Account_Types (
    account_type_key INT AUTOINCREMENT PRIMARY KEY,
    account_type_name VARCHAR
);

CREATE TABLE Dim_Account_Names (
    account_name_key INT AUTOINCREMENT PRIMARY KEY,
    account_name VARCHAR
);

CREATE TABLE Dim_Deposit_Types (
    deposit_type_key INT AUTOINCREMENT PRIMARY KEY,
    deposit_type_name VARCHAR
);

CREATE TABLE Dim_Loan_Types (
    loan_type_key INT AUTOINCREMENT PRIMARY KEY,
    loan_type_name VARCHAR
);

CREATE TABLE Dim_Countries (
    country_key INT AUTOINCREMENT PRIMARY KEY,
    country_code VARCHAR,
    country_name VARCHAR
);

CREATE TABLE Dim_Dates (
    date_key INT AUTOINCREMENT PRIMARY KEY,
    date DATE,
    year INT,
    month INT,
    day INT
);

-- Create Fact Tables
CREATE TABLE Fact_Accounts (
    account_number VARCHAR PRIMARY KEY,
    amount DECIMAL,
    reference_date DATE,
    account_type_key INT,
    account_name_key INT,
    FOREIGN KEY (account_type_key) REFERENCES Dim_Account_Types(account_type_key),
    FOREIGN KEY (account_name_key) REFERENCES Dim_Account_Names(account_name_key)
);

CREATE TABLE Fact_Deposits (
    deposit_id INT AUTOINCREMENT PRIMARY KEY,
    amount DECIMAL,
    currency VARCHAR,
    exchange_rate DECIMAL,
    start_date DATE,
    maturity_date DATE,
    reference_date DATE,
    customer_key INT,
    deposit_type_key INT,
    country_key INT,
    FOREIGN KEY (customer_key) REFERENCES Dim_Customers(customer_key),
    FOREIGN KEY (deposit_type_key) REFERENCES Dim_Deposit_Types(deposit_type_key),
    FOREIGN KEY (country_key) REFERENCES Dim_Countries(country_key)
);

CREATE TABLE Fact_Loans (
    loan_id INT AUTOINCREMENT PRIMARY KEY,
    amount DECIMAL,
    currency VARCHAR,
    exchange_rate DECIMAL,
    start_date DATE,
    maturity_date DATE,
    reference_date DATE,
    customer_key INT,
    loan_type_key INT,
    country_key INT,
    FOREIGN KEY (customer_key) REFERENCES Dim_Customers(customer_key),
    FOREIGN KEY (loan_type_key) REFERENCES Dim_Loan_Types(loan_type_key),
    FOREIGN KEY (country_key) REFERENCES Dim_Countries(country_key)
);

-- Create Task to Load Dimension Tables
CREATE OR REPLACE TASK Load_Dimensions
    WAREHOUSE = my_warehouse
    SCHEDULE = 'USING CRON 0 1 * * * UTC' -- Daily at 1 AM UTC
AS
BEGIN
    -- Populate dimension tables
    INSERT INTO DataWarehouse.Dim_Customers (customer_id, customer_type)
    SELECT DISTINCT customer, customer_type
    FROM Staging.Deposits_Staging;

    INSERT INTO DataWarehouse.Dim_Account_Types (account_type_name)
    SELECT DISTINCT account_type
    FROM Staging.Accounts_Staging;

    INSERT INTO DataWarehouse.Dim_Account_Names (account_name)
    SELECT DISTINCT account_name
    FROM Staging.Accounts_Staging;

    INSERT INTO DataWarehouse.Dim_Deposit_Types (deposit_type_name)
    SELECT DISTINCT deposit_type
    FROM Staging.Deposits_Staging;

    INSERT INTO DataWarehouse.Dim_Loan_Types (loan_type_name)
    SELECT DISTINCT loan_type
    FROM Staging.Loans_Staging;

    INSERT INTO DataWarehouse.Dim_Countries (country_code, country_name)
    SELECT DISTINCT country, country
    FROM Staging.Deposits_Staging;

    INSERT INTO DataWarehouse.Dim_Dates (date, year, month, day)
    SELECT DISTINCT reference_date,
        EXTRACT(year FROM reference_date),
        EXTRACT(month FROM reference_date),
        EXTRACT(day FROM reference_date)
    FROM Staging.Deposits_Staging;
END;

-- Create Task to Load Fact Tables
CREATE OR REPLACE TASK Load_Facts
    WAREHOUSE = my_warehouse
    AFTER Load_Dimensions
AS
BEGIN

    INSERT INTO DataWarehouse.Fact_Accounts (
        account_number, 
        amount, 
        reference_date, 
        account_type_key, 
        account_name_key
    )
    SELECT 
         a.account_number,
         a.amount,
         a.reference_date,
         at.account_type_key,
         an.account_name_key
    FROM 
         Staging.Accounts_Staging a
        JOIN DataWarehouse.Dim_Account_Types at ON a.account_type = at.account_type_name
        JOIN DataWarehouse.Dim_Account_Names an ON a.account_name = an.account_name;

    INSERT INTO DataWarehouse.Fact_Deposits (
        amount, 
        currency, 
        exchange_rate, 
        start_date, 
        maturity_date, 
        reference_date, 
        customer_key, 
        deposit_type_key, 
        country_key
    )
    SELECT 
        d.amount,
        d.currency,
        d.exchange_rate,
        d.start_date,
        d.maturity_date,
        d.reference_date,
        c.customer_key,
        dt.deposit_type_key,
        co.country_key
    FROM 
        Staging.Deposits_Staging d
        JOIN DataWarehouse.Dim_Customers c ON d.customer = c.customer_id
        JOIN DataWarehouse.Dim_Deposit_Types dt ON d.deposit_type = dt.deposit_type_name
        JOIN DataWarehouse.Dim_Countries co ON d.country = co.country_code;

    INSERT INTO DataWarehouse.Fact_Loans (
        amount, 
        currency, 
        exchange_rate, 
        start_date, 
        maturity_date, 
        reference_date, 
        customer_key, 
        loan_type_key, 
        country_key
    )
    SELECT 
        l.amount,
        l.currency,
        l.exchange_rate,
        l.start_date,
        COALESCE(l.maturity_date, '1900-01-01'), -- Handle null dates
        l.reference_date,
        c.customer_key,
        lt.loan_type_key,
        co.country_key
    FROM 
        Staging.Loans_Staging l
        JOIN DataWarehouse.Dim_Customers c ON l.customer = c.customer_id
        JOIN DataWarehouse.Dim_Loan_Types lt ON l.loan_type = lt.loan_type_name
        JOIN DataWarehouse.Dim_Countries co ON l.country = co.country_code;
END;

-- Resume the tasks
ALTER TASK Load_Facts RESUME;
ALTER TASK Load_Dimensions RESUME;

-- Validate data
SELECT * FROM Staging.Accounts_Staging;
SELECT * FROM Staging.Deposits_Staging;
SELECT * FROM Staging.Loans_Staging;

SELECT * FROM DataWarehouse.Dim_Dates;
SELECT * FROM DataWarehouse.Fact_Accounts;
SELECT * FROM DataWarehouse.Fact_Deposits;