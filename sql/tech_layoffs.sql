-- ============================================================
-- PROJECT: TECH LAYOFFS 2020-2026
-- DATABASE: PostgreSQL
-- DESCRIPTION:
-- End-to-end SQL workflow for data cleaning,
-- transformation, and analytical exploration.
-- ============================================================

-- ============================================================
-- SECTION 1: CREATE TABLES
-- ============================================================

-- MAIN LAYOFFS DATA
CREATE TABLE layoffs_data (
    nr                          INTEGER,
    company                     VARCHAR(150),
    location_hq                 VARCHAR(150),
    region                      VARCHAR(100),
    us_state                    VARCHAR(100),
    country                     VARCHAR(100),
    continent                   VARCHAR(100),
    laid_off                    NUMERIC(10,1),
    date_layoffs                DATE,
    percentage                  NUMERIC(5,1),
    company_size_before         NUMERIC(10,1),
    company_size_after          NUMERIC(10,1),
    industry                    VARCHAR(100),
    stage                       VARCHAR(50),
    money_raised_mil            NUMERIC(12,1),
    year                        INTEGER,
    latitude                    NUMERIC(10,7),
    longitude                   NUMERIC(10,7)
);

-- 2025-2026 LAYOFFS DATA
CREATE TABLE layoffs_2025 (
    company                     VARCHAR(150),
    employees_laid_off          INTEGER,
    date_layoffs                DATE,
    industry                    VARCHAR(100),
    location                    VARCHAR(150),
    country                     VARCHAR(100),
    reason                      VARCHAR(300),
    department                  VARCHAR(200),
    percentage_workforce        NUMERIC(5,1),
    total_employees             INTEGER,
    severance_weeks             INTEGER,
    ai_related                  VARCHAR(20),
    year                        INTEGER,
    month                       INTEGER,
    month_name                  VARCHAR(20),
    quarter                     INTEGER
);

-- HIRING TRENDS DATA
CREATE TABLE hiring (
    company                     VARCHAR(150),
    role                        VARCHAR(200),
    number_positions            INTEGER,
    date_posted                 DATE,
    salary_min                  INTEGER,
    salary_max                  INTEGER,
    location                    VARCHAR(150),
    country                     VARCHAR(100),
    remote                      VARCHAR(20),
    skills_required             VARCHAR(300),
    experience_years            INTEGER,
    department                  VARCHAR(100),
    year                        INTEGER,
    month                       INTEGER,
    salary_average              NUMERIC(12,1)
);

-- ============================================================
-- SECTION 2: DATA IMPORT NOTE
-- ============================================================

-- CSV datasets were imported into PostgreSQL prior to analysis.
-- Source files are included in the project repository.


-- ============================================================
-- SECTION 3: VERIFY IMPORTS
-- Validate successful dataset imports
-- ============================================================

SELECT COUNT(*) AS layoffs_main_rows
FROM layoffs_data;

SELECT COUNT(*) AS layoffs_2025_rows
FROM layoffs_2025;

SELECT COUNT(*) AS hiring_rows
FROM hiring;

-- ============================================================
-- SECTION 4: CREATE CLEANING TABLE
-- ============================================================

CREATE TABLE layoffs_clean AS
SELECT *
FROM layoffs_data;

-- ============================================================
-- SECTION 5: REMOVE DUPLICATES
-- Remove duplicate layoff records for cleaner analysis
-- ============================================================

DELETE FROM layoffs_clean
WHERE ctid IN (
    SELECT ctid
    FROM (
        SELECT ctid,
               ROW_NUMBER() OVER (
                   PARTITION BY company,
                                location_hq,
                                industry,
                                laid_off,
                                date_layoffs,
                                country
                   ORDER BY date_layoffs
               ) AS row_num
        FROM layoffs_clean
    ) duplicates
    WHERE row_num > 1
);

-- ============================================================
-- SECTION 6: STANDARDIZE DATA
-- Standardize categorical values for consistent reporting.
-- Consolidates industry names and country aliases.
-- ============================================================

-- ------------------------------------------------------------
-- Standardize Industry Values
-- ------------------------------------------------------------

UPDATE layoffs_clean
SET industry =
    CASE
        WHEN industry ILIKE '%crypto%'
          OR industry ILIKE '%web3%'
            THEN 'Crypto'

        WHEN industry IN (
            'FinTech',
            'Fin Tech',
            'Financial Services'
        )
            THEN 'Finance'

        WHEN industry ILIKE '%transport%'
          OR industry ILIKE '%mobility%'
          OR industry ILIKE '%logistics%'
            THEN 'Transportation'

        WHEN industry ILIKE '%health%'
          OR industry ILIKE '%medical%'
          OR industry ILIKE '%biotech%'
            THEN 'Healthcare'

        WHEN industry ILIKE '%ecommerce%'
          OR industry = 'Retail'
            THEN 'E-Commerce'

        WHEN industry ILIKE '%marketing%'
          OR industry ILIKE '%advertising%'
          OR industry = 'Media'
            THEN 'Marketing'

        WHEN industry IS NULL
          OR TRIM(industry) = ''
            THEN 'Unknown'

        ELSE industry
    END;

-- ------------------------------------------------------------
-- Standardize Country Values
-- ------------------------------------------------------------

UPDATE layoffs_clean
SET country =
    CASE
        WHEN country IN (
            'US',
            'USA',
            'United States of America'
        )
            THEN 'United States'

        WHEN country IN (
            'UK',
            'England',
            'Britain'
        )
            THEN 'United Kingdom'

        ELSE TRIM(TRAILING '.' FROM TRIM(country))
    END;

-- ============================================================
-- SECTION 7: REMOVE INCOMPLETE RECORDS
-- Remove records with no layoff count and no percentage.
-- ============================================================

DELETE
FROM layoffs_clean
WHERE laid_off IS NULL
  AND percentage IS NULL;

-- ============================================================
-- SECTION 8: FEATURE ENGINEERING
-- Create additional columns used for reporting and Tableau.
-- ============================================================

ALTER TABLE layoffs_clean

ADD COLUMN layoff_year INTEGER,

ADD COLUMN layoff_month VARCHAR(7),

ADD COLUMN layoff_quarter VARCHAR(7),

ADD COLUMN company_size_category VARCHAR(30);

UPDATE layoffs_clean
SET
    layoff_year = EXTRACT(YEAR FROM date_layoffs),

    layoff_month = TO_CHAR(date_layoffs, 'YYYY-MM'),

    layoff_quarter =
        CONCAT(
            EXTRACT(YEAR FROM date_layoffs),
            '-Q',
            EXTRACT(QUARTER FROM date_layoffs)
        ),

    company_size_category =
        CASE
            WHEN laid_off >= 10000 THEN 'Massive (10,000+)'
            WHEN laid_off >= 5000 THEN 'Very Large (5,000-9,999)'
            WHEN laid_off >= 1000 THEN 'Large (1,000-4,999)'
            WHEN laid_off >= 100 THEN 'Mid-size (100-999)'
            ELSE 'Small (<100)'
        END;

-- ============================================================
-- SECTION 9: VERIFY CLEANED DATA
-- Validate transformations before building the final dataset.
-- ============================================================

SELECT
    COUNT(*) AS cleaned_records
FROM layoffs_clean;

SELECT
    COUNT(DISTINCT company) AS companies,
    COUNT(DISTINCT industry) AS industries,
    COUNT(DISTINCT country) AS countries
FROM layoffs_clean;

SELECT
    MIN(date_layoffs) AS earliest_date,
    MAX(date_layoffs) AS latest_date
FROM layoffs_clean;

-- ============================================================
-- SECTION 10: CREATE COMBINED ANALYSIS TABLE
-- Combine cleaned historical layoffs with 2025-2026 layoffs data.
-- ============================================================

CREATE TABLE layoffs_combined AS

SELECT
    company,
    location_hq AS location,
    us_state,
    country,
    continent,
    CAST(laid_off AS INTEGER) AS total_laid_off,
    date_layoffs,
    percentage AS pct_workforce,
    industry,
    stage,
    money_raised_mil AS funds_raised_mil,
    year,
    layoff_year,
    layoff_month,
    layoff_quarter,
    company_size_category,
    NULL::VARCHAR(200) AS department,
    NULL::INTEGER AS severance_weeks,
    NULL::VARCHAR(20) AS ai_related,
    NULL::VARCHAR(300) AS reason,
    'main' AS data_source
FROM layoffs_clean

UNION ALL

SELECT
    company,
    location,
    NULL,
    country,
    NULL,
    employees_laid_off,
    date_layoffs,
    percentage_workforce,
    industry,
    NULL,
    NULL,
    year,
    year,
    TO_CHAR(date_layoffs, 'YYYY-MM'),
    CONCAT(year, '-Q', quarter),
    CASE
        WHEN employees_laid_off >= 10000 THEN 'Massive (10,000+)'
        WHEN employees_laid_off >= 5000  THEN 'Very Large (5,000-9,999)'
        WHEN employees_laid_off >= 1000  THEN 'Large (1,000-4,999)'
        WHEN employees_laid_off >= 100   THEN 'Mid-size (100-999)'
        ELSE 'Small (<100)'
    END,
    department,
    severance_weeks,
    ai_related,
    reason,
    '2025_2026'
FROM layoffs_2025;

-- ============================================================
-- SECTION 11: VERIFY FINAL TABLE
-- ============================================================

SELECT COUNT(*) AS combined_rows
FROM layoffs_combined;

SELECT MIN(date_layoffs) AS earliest_date,
       MAX(date_layoffs) AS latest_date
FROM layoffs_combined;

SELECT layoff_year,
       COUNT(*) AS events,
       SUM(total_laid_off) AS total_laid_off
FROM layoffs_combined
GROUP BY layoff_year
ORDER BY layoff_year;

-- ============================================================
-- SECTION 12: BUSINESS ANALYSIS QUERIES
-- SQL queries used for KPI reporting, dashboards,
-- exploratory analysis, and business insights.
-- ============================================================

-- ============================================================
-- TABLEAU DASHBOARD QUERIES
-- ============================================================

-- YEARLY LAYOFF KPI
-- Summarizes yearly layoffs, affected companies, and average workforce reduction.
SELECT
    layoff_year,
    SUM(total_laid_off) AS total_laid_off,
    COUNT(DISTINCT company) AS companies_affected,
    ROUND(AVG(pct_workforce),1) AS avg_pct_cut
FROM layoffs_combined
GROUP BY layoff_year
ORDER BY layoff_year;

-- MONTHLY TREND
-- Analyzes monthly layoff patterns to identify changes over time.
SELECT
    layoff_month,
    SUM(total_laid_off) AS monthly_total
FROM layoffs_combined
GROUP BY layoff_month
ORDER BY layoff_month;

-- TOP COMPANIES
-- Identifies companies with the highest number of employees impacted.
SELECT
    company,
    industry,
    country,
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_combined
GROUP BY company, industry, country
ORDER BY total_laid_off DESC
LIMIT 15;

-- INDUSTRY BREAKDOWN
-- Analyzes layoffs by industry to identify sectors most impacted.
SELECT
    industry,
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_combined
GROUP BY industry
ORDER BY total_laid_off DESC;

-- COUNTRY BREAKDOWN
-- Analyzes geographic distribution of layoffs by country.
SELECT
    country,
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_combined
GROUP BY country
ORDER BY total_laid_off DESC;

-- COMPANY RECORDS TABLE
-- Provides detailed company-level layoff records for dashboard filtering.
SELECT
    company,
    industry,
    location,
    us_state,
    country,
    date_layoffs,
    layoff_year,
    layoff_quarter,
    total_laid_off,
    pct_workforce,
    stage,
    funds_raised_mil,
    company_size_category,
    department,
    severance_weeks,
    ai_related,
    reason,
    data_source
FROM layoffs_combined
ORDER BY date_layoffs DESC;

-- HIRING TRENDS
-- Analyzes job demand, salary averages, and hiring patterns by role and department.
SELECT
    role,
    department,
    SUM(number_positions) AS total_positions,
    ROUND(AVG(salary_average),0) AS avg_salary,
    country,
    remote
FROM hiring
GROUP BY role, department, country, remote
ORDER BY total_positions DESC;

-- ============================================================
-- ADVANCED SQL ANALYSIS QUERIES
-- ============================================================

-- COMPANY LAYOFF SUMMARY (CTE)
-- Calculates total layoffs by company using a Common Table Expression.
WITH company_totals AS (
    SELECT
        company,
        SUM(total_laid_off) AS total_laid_off
    FROM layoffs_combined
    GROUP BY company
)

SELECT
    company,
    total_laid_off
FROM company_totals
ORDER BY total_laid_off DESC;

-- COMPANY LAYOFF RANKING
-- Ranks companies based on total employees impacted.
SELECT
    company,
    SUM(total_laid_off) AS total_laid_off,
    RANK() OVER (
        ORDER BY SUM(total_laid_off) DESC
    ) AS company_rank
FROM layoffs_combined
GROUP BY company;

-- INDUSTRY LAYOFF RANKING
-- Ranks industries based on total employees impacted.
SELECT
    industry,
    SUM(total_laid_off) AS total_laid_off,
    DENSE_RANK() OVER (
        ORDER BY SUM(total_laid_off) DESC
    ) AS industry_rank
FROM layoffs_combined
GROUP BY industry;

-- CUMULATIVE MONTHLY LAYOFFS
-- Calculates the running total of layoffs over time.
SELECT
    layoff_month,
    SUM(total_laid_off) AS monthly_total,
    SUM(SUM(total_laid_off)) OVER (
        ORDER BY layoff_month
    ) AS running_total
FROM layoffs_combined
GROUP BY layoff_month;

-- MONTHLY LAYOFF CHANGE
-- Compares layoffs between the current and previous month.
WITH monthly_layoffs AS (
    SELECT
        layoff_month,
        SUM(total_laid_off) AS total_laid_off
    FROM layoffs_combined
    GROUP BY layoff_month
)

SELECT
    layoff_month,
    total_laid_off,
    LAG(total_laid_off) OVER (
        ORDER BY layoff_month
    ) AS previous_month,
    total_laid_off -
    LAG(total_laid_off) OVER (
        ORDER BY layoff_month
    ) AS monthly_change
FROM monthly_layoffs;

-- INDUSTRY PERCENT OF TOTAL LAYOFFS
-- Calculates each industry's percentage contribution to total layoffs.
SELECT
    industry,
    SUM(total_laid_off) AS total_laid_off,
    ROUND(
        100.0 *
        SUM(total_laid_off) /
        SUM(SUM(total_laid_off)) OVER(),
        2
    ) AS pct_total
FROM layoffs_combined
GROUP BY industry;

-- HIGH IMPACT COMPANIES
-- Identifies companies with more than 5,000 employees impacted.
SELECT
    company,
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_combined
GROUP BY company
HAVING SUM(total_laid_off) > 5000
ORDER BY total_laid_off DESC;

-- COMPANIES ABOVE AVERAGE LAYOFFS
-- Finds companies with layoffs above the overall average.
SELECT
    company,
    total_laid_off
FROM layoffs_combined
WHERE total_laid_off >
(
    SELECT AVG(total_laid_off)
    FROM layoffs_combined
);

-- AI RELATED LAYOFF ANALYSIS
-- Compares layoffs identified as AI-related, non-AI-related,
-- and records without available AI classification.
SELECT
    COUNT(*) FILTER(
        WHERE ai_related = 'Yes'
    ) AS ai_related_events,

    COUNT(*) FILTER(
        WHERE ai_related = 'No'
    ) AS non_ai_events,

    COUNT(*) FILTER(
        WHERE ai_related IS NULL
    ) AS unknown_events
FROM layoffs_combined;

-- COMPANY INFORMATION SUMMARY
-- Handles missing industry and country values using COALESCE.
SELECT
    company,
    COALESCE(industry,'Unknown') AS industry,
    COALESCE(country,'Unknown') AS country
FROM layoffs_combined;

-- TOP COMPANIES BY INDUSTRY
-- Identifies the top three companies with the highest layoffs within each industry.
WITH ranked_companies AS (
    SELECT
        industry,
        company,
        SUM(total_laid_off) AS total_laid_off,
        ROW_NUMBER() OVER (
            PARTITION BY industry
            ORDER BY SUM(total_laid_off) DESC
        ) AS ranking
    FROM layoffs_combined
    GROUP BY industry, company
)

SELECT
    industry,
    company,
    total_laid_off,
    ranking
FROM ranked_companies
WHERE ranking <= 3;

-- LARGEST LAYOFF EVENT BY COUNTRY
-- Identifies the company with the largest single layoff event in each country.
WITH ranked_country AS (
    SELECT
        country,
        company,
        total_laid_off,
        ROW_NUMBER() OVER (
            PARTITION BY country
            ORDER BY total_laid_off DESC
        ) AS ranking
    FROM layoffs_combined
)

SELECT
    country,
    company,
    total_laid_off
FROM ranked_country
WHERE ranking = 1;

-- WORKFORCE REDUCTION SEVERITY
-- Categorizes companies based on percentage of workforce reduced.
SELECT
    company,
    pct_workforce,
    CASE
        WHEN pct_workforce >= 75 THEN 'Critical'
        WHEN pct_workforce >= 50 THEN 'High'
        WHEN pct_workforce >= 25 THEN 'Moderate'
        ELSE 'Low'
    END AS severity
FROM layoffs_combined;

-- REMOTE HIRING ANALYSIS
-- Analyzes hiring activity and salary averages by work arrangement.
SELECT
    remote,
    COUNT(*) AS jobs,
    SUM(number_positions) AS total_positions,
    ROUND(AVG(salary_average),0) AS avg_salary
FROM hiring
GROUP BY remote;

-- DEPARTMENT SALARY ANALYSIS
-- Compares average salary and hiring demand across departments.
SELECT
    department,
    ROUND(AVG(salary_average),0) AS avg_salary,
    SUM(number_positions) AS total_positions
FROM hiring
GROUP BY department
ORDER BY avg_salary DESC;

-- LAYOFFS VS HIRING COMPARISON
-- Compares companies impacted by layoffs with current hiring activity.
SELECT
    l.company,
    SUM(l.total_laid_off) AS total_laid_off,
    MAX(h.number_positions) AS open_positions
FROM layoffs_combined l
LEFT JOIN hiring h
    ON l.company = h.company
GROUP BY l.company
ORDER BY total_laid_off DESC;

-- TOP SKILLS IN HIRING DATA
-- Identifies commonly requested skills from job postings.
SELECT
    skills_required,
    COUNT(*) AS job_postings
FROM hiring
GROUP BY skills_required
ORDER BY job_postings DESC
LIMIT 15;
