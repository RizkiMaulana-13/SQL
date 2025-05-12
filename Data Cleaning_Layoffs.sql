-- Data Cleaning

SELECT *
FROM layoffs;

-- now when we are data cleaning we usually follow a few steps
-- 1. check for duplicates and remove any
-- 2. standardize data and fix errors
-- 3. Look at null values and see what 
-- 4. remove any columns and rows that are not necessary - few ways


-- the first thing to do is creating a staging table,
-- staging table is the one we will work in and clean the data
-- with creating staging table we have a raw tables in case something happens,

CREATE TABLE layoffs_staging
LIKE layoffs;

SELECT *
FROM layoffs_staging;

INSERT layoffs_staging
SELECT *
FROM layoffs;

-- 1. Check for Duplicates and Delete Any
WITH duplicate_cte as
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) as row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

SELECT  *
FROM layoffs_staging
WHERE company = 'Yahoo';

-- this will not work because cte cant be update
WITH duplicate_cte as
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) as row_num
FROM layoffs_staging
)
DELETE
FROM duplicate_cte
WHERE row_num > 1; 

-- instead we will gonna create a new staging table with a row number column and than we can delete the duplicate
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


SELECT *
FROM layoffs_staging2;

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) as row_num
FROM layoffs_staging;

DELETE
FROM layoffs_staging2
WHERE row_num > 1; 

-- always check for duplicate to known that its been deleted/not
SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

-- 2. Standardazing Data
SELECT company, TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);	# TRIM Gonna make every white spaces gone

SELECT DISTINCT(industry)
FROM layoffs_staging2
ORDER BY 1; 

SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%'; 

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';	# this gonna make every Crypto Currency/CryptoCurrency to Crypto

SELECT DISTINCT(country)
FROM layoffs_staging2;

SELECT *
FROM layoffs_staging2
WHERE country LIKE 'United State%'
ORDER BY 1; 

SELECT  DISTINCT country, TRIM(TRAILING '.' FROM country)	# this will specify what char do we want to trim in the country 
FROM layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country like 'United States%';

SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y') # changing the string value to date value
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');	# updating the string value in date to date format

-- after formating the value you can now alter it to date 
-- only do this to the staging table not the raw tables
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- 3. Null/blank values
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS null 
AND percentage_laid_off IS NULL;	# this data isn't usefull because those doesnt have a value

SELECT *
FROM layoffs_staging2
WHERE industry = ''
OR industry IS NULL;	# this data isn't exactly useful u can double check it to be sure

SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb';	# by doing this you can see that even if the industry is null, they've other values

SELECT t1.industry, t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
    AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
    AND t1.location = t2.location
SET t1.industry = t2.industry
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

-- we need to change the white values to null first
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
    AND t1.location = t2.location
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

# now for the total_laid_off, percentage_laid_off, and funds_raised_millions is null
# we cant do anything about it because we dont have the total employee before the laid off to calculate it

-- 4. Remove any columns and rows

DELETE
FROM layoffs_staging2
WHERE total_laid_off IS null 
AND percentage_laid_off IS NULL;	# we cant do anything about this and the value is null so we have to delete it, bcs its unnecessary data

SELECT *
FROM layoffs_staging2;

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;	# we dont need the row_num column anymore
