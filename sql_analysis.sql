sql-- =====================================================
-- BANK LOAN RISK ANALYSIS - COMPLETE SQL CODE
-- Author: James E. Nance Jr.
-- Project: $312M Portfolio Risk Optimization
-- Dataset: 32,581 loan records
-- GitHub: github.com/JamesENance/bank-loan-risk-analysis
-- =====================================================

-- =====================================================
-- 1. DATABASE SETUP AND TABLE CREATION
-- =====================================================

-- Create database
CREATE DATABASE LoanRiskAnalysis;
GO

-- Use the database
USE LoanRiskAnalysis;
GO

-- Create table structure
CREATE TABLE credit_risk_dataset (
    person_age INT,
    person_income DECIMAL(12,2),
    person_home_ownership VARCHAR(20),
    person_emp_length DECIMAL(5,2),
    loan_intent VARCHAR(30),
    loan_grade VARCHAR(5),
    loan_amnt DECIMAL(12,2),
    loan_int_rate DECIMAL(6,3),
    loan_status INT,
    loan_percent_income DECIMAL(8,4),
    cb_person_default_on_file VARCHAR(5),
    cb_person_cred_hist_length INT
);
GO

-- =====================================================
-- 2. DATA IMPORT
-- =====================================================

-- Import CSV data using BULK INSERT
BULK INSERT credit_risk_dataset
FROM 'C:\path\to\credit_risk_dataset.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2,  -- Skip header row
    KEEPNULLS
);
GO

-- =====================================================
-- 3. DATA EXPLORATION AND VALIDATION
-- =====================================================

-- Check data import success
SELECT COUNT(*) as total_records FROM credit_risk_dataset;

-- View first 10 records
SELECT TOP 10 * FROM credit_risk_dataset;

-- Check data types and structure
SELECT COLUMN_NAME, DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'credit_risk_dataset';

-- Check for null values
SELECT 
    COUNT(*) - COUNT(person_income) AS missing_income,
    COUNT(*) - COUNT(loan_amnt) AS missing_loan_amount,
    COUNT(*) - COUNT(loan_status) AS missing_status
FROM credit_risk_dataset;

-- =====================================================
-- 4. PORTFOLIO OVERVIEW ANALYSIS
-- =====================================================

-- Basic loan portfolio overview
SELECT 
    COUNT(*) AS total_loans,
    AVG(CAST(person_income AS FLOAT)) AS avg_income,
    AVG(CAST(loan_amnt AS FLOAT)) AS avg_loan_amount,
    SUM(CASE WHEN loan_status = '1' THEN 1 ELSE 0 END) AS total_defaults,
    ROUND(AVG(CASE WHEN loan_status = '1' THEN 1.0 ELSE 0.0 END) * 100, 2) AS default_rate_pct,
    SUM(CAST(loan_amnt AS FLOAT)) AS total_portfolio_value
FROM credit_risk_dataset;

-- =====================================================
-- 5. INCOME-BASED RISK SEGMENTATION
-- =====================================================

-- Default rate by income bracket
SELECT 
    CASE 
        WHEN CAST(person_income AS FLOAT) < 50000 THEN 'Low Income (<$50K)'
        WHEN CAST(person_income AS FLOAT) BETWEEN 50000 AND 100000 THEN 'Middle Income ($50K-$100K)'
        ELSE 'High Income (>$100K)'
    END AS income_bracket,
    COUNT(*) AS total_loans,
    SUM(CASE WHEN loan_status = '1' THEN 1 ELSE 0 END) AS defaults,
    ROUND(AVG(CASE WHEN loan_status = '1' THEN 1.0 ELSE 0.0 END) * 100, 2) AS default_rate_pct,
    AVG(CAST(loan_amnt AS FLOAT)) AS avg_loan_amount
FROM credit_risk_dataset
GROUP BY 
    CASE 
        WHEN CAST(person_income AS FLOAT) < 50000 THEN 'Low Income (<$50K)'
        WHEN CAST(person_income AS FLOAT) BETWEEN 50000 AND 100000 THEN 'Middle Income ($50K-$100K)'
        ELSE 'High Income (>$100K)'
    END
ORDER BY default_rate_pct DESC;

-- =====================================================
-- 6. PRODUCT-BASED RISK ANALYSIS
-- =====================================================

-- Default rate by loan purpose
SELECT 
    loan_intent,
    COUNT(*) AS total_loans,
    SUM(CASE WHEN loan_status = '1' THEN 1 ELSE 0 END) AS defaults,
    ROUND(AVG(CASE WHEN loan_status = '1' THEN 1.0 ELSE 0.0 END) * 100, 2) AS default_rate_pct,
    AVG(CAST(loan_amnt AS FLOAT)) AS avg_loan_amount,
    SUM(CAST(loan_amnt AS FLOAT)) AS total_loan_volume
FROM credit_risk_dataset
GROUP BY loan_intent
ORDER BY default_rate_pct DESC;

-- =====================================================
-- 7. CROSS-SEGMENTATION ANALYSIS (THE MONEY MAKER!)
-- =====================================================

-- Risk by income AND loan purpose - KEY BUSINESS INSIGHTS
SELECT 
    CASE 
        WHEN CAST(person_income AS FLOAT) < 50000 THEN 'Low Income'
        WHEN CAST(person_income AS FLOAT) BETWEEN 50000 AND 100000 THEN 'Middle Income'
        ELSE 'High Income'
    END AS income_level,
    loan_intent,
    COUNT(*) AS loans,
    ROUND(AVG(CASE WHEN loan_status = '1' THEN 1.0 ELSE 0.0 END) * 100, 2) AS default_rate_pct,
    SUM(CAST(loan_amnt AS FLOAT)) AS total_volume
FROM credit_risk_dataset
GROUP BY 
    CASE 
        WHEN CAST(person_income AS FLOAT) < 50000 THEN 'Low Income'
        WHEN CAST(person_income AS FLOAT) BETWEEN 50000 AND 100000 THEN 'Middle Income'
        ELSE 'High Income'
    END,
    loan_intent
ORDER BY default_rate_pct DESC;

-- =====================================================
-- 8. FINANCIAL IMPACT ANALYSIS
-- =====================================================

-- Total portfolio metrics
SELECT 
    SUM(CAST(loan_amnt AS FLOAT)) AS total_portfolio_value,
    SUM(CASE WHEN loan_status = '1' THEN CAST(loan_amnt AS FLOAT) ELSE 0 END) AS total_defaults_value,
    ROUND(SUM(CASE WHEN loan_status = '1' THEN CAST(loan_amnt AS FLOAT) ELSE 0 END) * 1.0 / 
          SUM(CAST(loan_amnt AS FLOAT)) * 100, 2) AS portfolio_loss_pct
FROM credit_risk_dataset;

-- ROI by risk segment
SELECT 
    CASE 
        WHEN CAST(loan_int_rate AS FLOAT) < 10 THEN 'Low Rate (<10%)'
        WHEN CAST(loan_int_rate AS FLOAT) BETWEEN 10 AND 15 THEN 'Medium Rate (10-15%)'
        ELSE 'High Rate (>15%)'
    END AS rate_segment,
    COUNT(*) AS loan_count,
    AVG(CAST(loan_int_rate AS FLOAT)) AS avg_rate,
    ROUND(AVG(CASE WHEN loan_status = '1' THEN 1.0 ELSE 0.0 END) * 100, 2) AS default_rate_pct,
    SUM(CAST(loan_amnt AS FLOAT)) AS total_volume
FROM credit_risk_dataset
GROUP BY 
    CASE 
        WHEN CAST(loan_int_rate AS FLOAT) < 10 THEN 'Low Rate (<10%)'
        WHEN CAST(loan_int_rate AS FLOAT) BETWEEN 10 AND 15 THEN 'Medium Rate (10-15%)'
        ELSE 'High Rate (>15%)'
    END
ORDER BY default_rate_pct;

-- =====================================================
-- 9. HIGH-RISK vs LOW-RISK BORROWER PROFILES
-- =====================================================

-- High-risk borrower characteristics
SELECT 
    'High Risk Borrowers' AS profile_type,
    AVG(CAST(person_age AS FLOAT)) AS avg_age,
    AVG(CAST(person_income AS FLOAT)) AS avg_income,
    AVG(CAST(person_emp_length AS FLOAT)) AS avg_employment_years,
    AVG(CAST(loan_amnt AS FLOAT)) AS avg_loan_amount,
    AVG(CAST(loan_int_rate AS FLOAT)) AS avg_interest_rate,
    AVG(CAST(loan_percent_income AS FLOAT)) AS avg_loan_to_income_ratio
FROM credit_risk_dataset
WHERE loan_status = '1'

UNION ALL

-- Low-risk borrower characteristics
SELECT 
    'Low Risk Borrowers' AS profile_type,
    AVG(CAST(person_age AS FLOAT)) AS avg_age,
    AVG(CAST(person_income AS FLOAT)) AS avg_income,
    AVG(CAST(person_emp_length AS FLOAT)) AS avg_employment_years,
    AVG(CAST(loan_amnt AS FLOAT)) AS avg_loan_amount,
    AVG(CAST(loan_int_rate AS FLOAT)) AS avg_interest_rate,
    AVG(CAST(loan_percent_income AS FLOAT)) AS avg_loan_to_income_ratio
FROM credit_risk_dataset
WHERE loan_status = '0';

-- =====================================================
-- 10. BUSINESS INTELLIGENCE QUERIES
-- =====================================================

-- Top 10 riskiest segments (AVOID THESE)
SELECT TOP 10
    CASE 
        WHEN CAST(person_income AS FLOAT) < 50000 THEN 'Low Income'
        WHEN CAST(person_income AS FLOAT) BETWEEN 50000 AND 100000 THEN 'Middle Income'
        ELSE 'High Income'
    END AS income_level,
    loan_intent,
    COUNT(*) AS loans,
    ROUND(AVG(CASE WHEN loan_status = '1' THEN 1.0 ELSE 0.0 END) * 100, 2) AS default_rate_pct,
    SUM(CAST(loan_amnt AS FLOAT)) AS total_volume,
    SUM(CASE WHEN loan_status = '1' THEN CAST(loan_amnt AS FLOAT) ELSE 0 END) AS estimated_losses
FROM credit_risk_dataset
GROUP BY 
    CASE 
        WHEN CAST(person_income AS FLOAT) < 50000 THEN 'Low Income'
        WHEN CAST(person_income AS FLOAT) BETWEEN 50000 AND 100000 THEN 'Middle Income'
        ELSE 'High Income'
    END,
    loan_intent
HAVING COUNT(*) > 100  -- Only segments with significant volume
ORDER BY default_rate_pct DESC;

-- Top 10 safest segments (FOCUS ON THESE)
SELECT TOP 10
    CASE 
        WHEN CAST(person_income AS FLOAT) < 50000 THEN 'Low Income'
        WHEN CAST(person_income AS FLOAT) BETWEEN 50000 AND 100000 THEN 'Middle Income'
        ELSE 'High Income'
    END AS income_level,
    loan_intent,
    COUNT(*) AS loans,
    ROUND(AVG(CASE WHEN loan_status = '1' THEN 1.0 ELSE 0.0 END) * 100, 2) AS default_rate_pct,
    SUM(CAST(loan_amnt AS FLOAT)) AS total_volume
FROM credit_risk_dataset
GROUP BY 
    CASE 
        WHEN CAST(person_income AS FLOAT) < 50000 THEN 'Low Income'
        WHEN CAST(person_income AS FLOAT) BETWEEN 50000 AND 100000 THEN 'Middle Income'
        ELSE 'High Income'
    END,
    loan_intent
HAVING COUNT(*) > 100  -- Only segments with significant volume
ORDER BY default_rate_pct ASC;

-- =====================================================
-- 11. EXECUTIVE SUMMARY METRICS
-- =====================================================

-- Key metrics for executive dashboard
SELECT 
    'Portfolio Summary' AS metric_category,
    COUNT(*) AS total_loans,
    ROUND(AVG(CAST(person_income AS FLOAT)), 0) AS avg_income,
    ROUND(AVG(CAST(loan_amnt AS FLOAT)), 0) AS avg_loan_amount,
    SUM(CASE WHEN loan_status = '1' THEN 1 ELSE 0 END) AS total_defaults,
    ROUND(AVG(CASE WHEN loan_status = '1' THEN 1.0 ELSE 0.0 END) * 100, 2) AS default_rate_pct,
    ROUND(SUM(CAST(loan_amnt AS FLOAT)) / 1000000, 1) AS portfolio_value_millions
FROM credit_risk_dataset;

-- =====================================================
-- 12. BUSINESS RECOMMENDATIONS QUERY
-- =====================================================

-- Segments to eliminate (>25% default rate)
SELECT 
    'ELIMINATE - High Risk' AS recommendation,
    CASE 
        WHEN CAST(person_income AS FLOAT) < 50000 THEN 'Low Income'
        WHEN CAST(person_income AS FLOAT) BETWEEN 50000 AND 100000 THEN 'Middle Income'
        ELSE 'High Income'
    END AS income_level,
    loan_intent,
    COUNT(*) AS loans,
    ROUND(AVG(CASE WHEN loan_status = '1' THEN 1.0 ELSE 0.0 END) * 100, 2) AS default_rate_pct,
    ROUND(SUM(CAST(loan_amnt AS FLOAT)) / 1000000, 1) AS volume_millions
FROM credit_risk_dataset
GROUP BY 
    CASE 
        WHEN CAST(person_income AS FLOAT) < 50000 THEN 'Low Income'
        WHEN CAST(person_income AS FLOAT) BETWEEN 50000 AND 100000 THEN 'Middle Income'
        ELSE 'High Income'
    END,
    loan_intent
HAVING AVG(CASE WHEN loan_status = '1' THEN 1.0 ELSE 0.0 END) > 0.25
   AND COUNT(*) > 100
ORDER BY default_rate_pct DESC;

-- =====================================================
-- END OF ANALYSIS
-- =====================================================

-- Final verification query
SELECT 
    'Analysis Complete' AS status,
    COUNT(*) AS records_analyzed,
    GETDATE() AS analysis_date,
    'James E. Nance Jr.' AS analyst
FROM credit_risk_dataset;

-- =====================================================
-- PORTFOLIO IMPACT SUMMARY
-- =====================================================
-- This analysis identified:
-- * 21.82% overall default rate (4x industry average)
-- * 52 percentage point risk spread between segments
-- * Low Income + Home Improvement: 56.27% default rate
-- * High Income + Venture: 4.32% default rate
-- * Potential $10M+ annual savings through optimization
-- =====================================================
