-- Data Cleaning

-- first thing we want to do is create a staging table. This is the one we will work in and clean the data. We want a table with the raw data in case something happens
CREATE TABLE layoffs_staging 
LIKE layoffs;

INSERT layoffs_staging 
SELECT * FROM layoffs;

-- 1. REMOVE DUPLICATES

-- First let's check for duplicates

SELECT *
FROM (
	SELECT company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions
			) AS row_num
	FROM 
		world_layoffs.layoffs_staging
) duplicates
WHERE 
	row_num > 1;


-- let's just look at 'Casper' to confirm
SELECT *
FROM world_layoffs.layoffs_staging
WHERE company = 'Casper';

-- One solution is to create a new column and add those row numbers in.
-- Then delete where row numbers are over 2, then delete that column

ALTER TABLE layoffs_staging ADD row_num INT;


SELECT *
FROM world_layoffs.layoffs_staging;

CREATE TABLE `world_layoffs`.`layoffs_staging2` (
`company` text,
`location`text,
`industry`text,
`total_laid_off` INT,
`percentage_laid_off` text,
`date` text,
`stage`text,
`country` text,
`funds_raised_millions` int,
row_num INT
);


INSERT INTO layoffs_staging2
(`company`,
`location`,
`industry`,
`total_laid_off`,
`percentage_laid_off`,
`date`,
`stage`,
`country`,
`funds_raised_millions`,
`row_num`)
SELECT `company`,
`location`,
`industry`,
`total_laid_off`,
`percentage_laid_off`,
`date`,
`stage`,
`country`,
`funds_raised_millions`,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions
			) AS row_num
	FROM 
		layoffs_staging;
        
   -- CHECK FOR DUPLICATES
        
	SELECT *
	FROM layoffs_staging2
    WHERE row_num > 1;     
        
  -- Now that we have this we can delete rows were row_num is greater than 2

DELETE FROM layoffs_staging2
WHERE row_num >= 2;      
        
--------------------------------------------------------------------------------------------

-- 2. STANDARDIZE DATA  

SELECT company, TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2 
SET company = TRIM(company);

  
SELECT DISTINCT industry 
FROM layoffs_staging2
ORDER BY 1;

-- We've looked at Company
-- ---------------------------------------------------------------------
 
-- I also noticed the Crypto has multiple different variations. We need to standardize that - let's say all to Crypto

SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto';
    
SELECT DISTINCT industry
FROM layoffs_staging2;   

-- We've looked at industry 
-- -------------------------------------------------

SELECT *
FROM layoffs_staging2;

-- There is an error. We have some "United States" and some "United States."
-- with a period at the end. Let's standardize this.

SELECT *
FROM layoffs_staging2
WHERE country LIKE 'United States%'
ORDER BY 1;


SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;


UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- Now It's fixed
        
 ----------------------------------------------------------------
 
 -- Let's also fix the date columns:
SELECT *
FROM world_layoffs.layoffs_staging2;

-- we can use str to date to update this field
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- now we can convert the data type properly
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- --------------------------------------------------------------------------

-- if we look at industry it looks like we have some null and empty rows, let's take a look at these

SELECT * 
FROM world_layoffs.layoffs_staging2;


SELECT DISTINCT industry
FROM world_layoffs.layoffs_staging2
ORDER BY industry;

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL 
OR industry = ''
ORDER BY industry;

-- let's take a look at these
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE company LIKE 'Bally%';
-- nothing wrong here
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE company LIKE 'airbnb%';

-- it looks like airbnb is a travel, but this one just isn't populated.
-- I'm sure it's the same for the others. What we can do is
-- write a query that if there is another row with the same company name, it will update it to the non-null industry values
-- makes it easy so if there were thousands we wouldn't have to manually check them all

-- we should set the blanks to nulls since those are typically easier to work with
UPDATE world_layoffs.layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- now if we check those are all null

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE industry IS NULL 
OR industry = ''
ORDER BY industry;

-- now we need to populate those nulls if possible

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- and if we check it looks like Bally's was the only one without a populated row to populate this null values
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE industry IS NULL 
OR industry = ''
ORDER BY industry;


--------------------------------------------------------------------------------------------------------------------


-- 4. remove any columns and rows we need to

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Delete Useless data we can't really use
DELETE FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT * 
FROM layoffs_staging2;

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;


SELECT * 
FROM layoffs_staging2;








