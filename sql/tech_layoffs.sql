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
-- SECTION 6: STANDARDIZE INDUSTRIES
-- ============================================================

UPDATE layoffs_clean
SET industry = 'Crypto'
WHERE industry ILIKE '%crypto%'
   OR industry ILIKE '%web3%';

UPDATE layoffs_clean
SET industry = 'Finance'
WHERE industry IN (
    'FinTech',
    'Fin Tech',
    'Financial Services'
);

UPDATE layoffs_clean
SET industry = 'Transportation'
WHERE industry ILIKE '%transport%'
   OR industry ILIKE '%mobility%'
   OR industry ILIKE '%logistics%';

UPDATE layoffs_clean
SET industry = 'Healthcare'
WHERE industry ILIKE '%health%'
   OR industry ILIKE '%medical%'
   OR industry ILIKE '%biotech%';

UPDATE layoffs_clean
SET industry = 'E-Commerce'
WHERE industry ILIKE '%ecommerce%'
   OR industry = 'Retail';

UPDATE layoffs_clean
SET industry = 'Marketing'
WHERE industry ILIKE '%marketing%'
   OR industry ILIKE '%advertising%'
   OR industry = 'Media';

UPDATE layoffs_clean
SET industry = 'Unknown'
WHERE industry IS NULL
   OR TRIM(industry) = '';

-- ============================================================
-- SECTION 7: STANDARDIZE COUNTRIES
-- ============================================================

UPDATE layoffs_clean
SET country = TRIM(TRAILING '.' FROM TRIM(country));

UPDATE layoffs_clean
SET country = 'United States'
WHERE country IN (
    'US',
    'USA',
    'United States of America'
);

UPDATE layoffs_clean
SET country = 'United Kingdom'
WHERE country IN (
    'UK',
    'England',
    'Britain'
);

-- ============================================================
-- SECTION 8: REMOVE EMPTY ROWS
-- ============================================================

DELETE FROM layoffs_clean
WHERE laid_off IS NULL
  AND percentage IS NULL;

-- ============================================================
-- SECTION 9: ADD TABLEAU DATE COLUMNS
-- ============================================================

ALTER TABLE layoffs_clean
ADD COLUMN layoff_year INTEGER;

ALTER TABLE layoffs_clean
ADD COLUMN layoff_month VARCHAR(7);

ALTER TABLE layoffs_clean
ADD COLUMN layoff_quarter VARCHAR(7);

UPDATE layoffs_clean
SET layoff_year = EXTRACT(YEAR FROM date_layoffs),
    layoff_month = TO_CHAR(date_layoffs, 'YYYY-MM'),
    layoff_quarter =
        CONCAT(
            EXTRACT(YEAR FROM date_layoffs),
            '-Q',
            EXTRACT(QUARTER FROM date_layoffs)
        );

-- ============================================================
-- SECTION 10: COMPANY SIZE CATEGORY
-- ============================================================

ALTER TABLE layoffs_clean
ADD COLUMN company_size_category VARCHAR(30);

UPDATE layoffs_clean
SET company_size_category =
    CASE
        WHEN laid_off >= 10000 THEN 'Massive (10,000+)'
        WHEN laid_off >= 5000  THEN 'Very Large (5,000-9,999)'
        WHEN laid_off >= 1000  THEN 'Large (1,000-4,999)'
        WHEN laid_off >= 100   THEN 'Mid-size (100-999)'
        ELSE 'Small (<100)'
    END;

-- ============================================================
-- SECTION 11: CREATE FINAL TABLE FOR TABLEAU
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
-- SECTION 12: VERIFY FINAL TABLE
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
-- SECTION 13: TABLEAU ANALYSIS QUERIES
-- ============================================================

-- YEARLY LAYOFF KPI
SELECT
    layoff_year,
    SUM(total_laid_off) AS total_laid_off,
    COUNT(DISTINCT company) AS companies_affected,
    ROUND(AVG(pct_workforce),1) AS avg_pct_cut
FROM layoffs_combined
GROUP BY layoff_year
ORDER BY layoff_year;

-- MONTHLY TREND
SELECT
    layoff_month,
    SUM(total_laid_off) AS monthly_total
FROM layoffs_combined
GROUP BY layoff_month
ORDER BY layoff_month;

-- TOP COMPANIES
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
SELECT
    industry,
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_combined
GROUP BY industry
ORDER BY total_laid_off DESC;

-- COUNTRY BREAKDOWN
SELECT
    country,
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_combined
GROUP BY country
ORDER BY total_laid_off DESC;

-- COMPANY RECORDS TABLE
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
