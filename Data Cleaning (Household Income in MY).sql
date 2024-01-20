-- change table name
RENAME TABLE householdincome to household_income; 

SELECT *
FROM household_income;

SELECT *
FROM population;


-- format date
SELECT DATE_FORMAT(STR_TO_DATE(date,'%W,%M %e,%Y'),'%d-%m-%Y') as formatdate
FROM household_income;

UPDATE household_income
SET date = DATE_FORMAT(STR_TO_DATE(date,'%W,%M %e,%Y'),'%d-%m-%Y');

SET SQL_SAFE_UPDATES = 0;

-- split state-district into two different column
SELECT TRIM(SUBSTRING_INDEX(statedistrict,'-',1)) AS state,TRIM(SUBSTRING_INDEX(statedistrict,'-',-1)) as district
FROM household_income;

-- add new column and insert data
ALTER TABLE household_income
ADD COLUMN state text,
ADD COLUMN district text;

UPDATE household_income
SET state = TRIM(SUBSTRING_INDEX(statedistrict,'-',1)),
	district = TRIM(SUBSTRING_INDEX(statedistrict,'-',-1));
    
-- delete combine statedistrict column
ALTER TABLE household_income
DROP COLUMN statedistrict;


-- rename column
ALTER TABLE household_income
CHANGE COLUMN Zon zone TEXT;

ALTER TABLE household_income
CHANGE COLUMN gini gini_coefficient FLOAT;

ALTER TABLE household_income
CHANGE COLUMN poverty poverty_rate FLOAT;


-- to fill in country code
UPDATE household_income
SET country_code =
 CASE   WHEN state = 'Johor' THEN 'JHR'
        WHEN state = 'Kedah' THEN 'KDH'
        WHEN state = 'Selangor' THEN 'SGR'
        WHEN state = 'Sabah' THEN 'SBH'
        WHEN state = 'Sarawak' THEN 'SWRK'
ELSE country_code
END;

-- check spelling error by ensure country_code standardize & update table
SELECT DISTINCT country_code
FROM household_income;

SELECT DISTINCT country_code,LENGTH(country_code)
FROM household_income
WHERE LENGTH(country_code) > 3;

UPDATE household_income
SET country_code = 'KTN'
WHERE country_code = 'KLTN';

UPDATE household_income
SET country_code = 'SWK'
WHERE country_code = 'SWRK';

SELECT *
FROM household_income;

-- standardise zone column

SELECT DISTINCT zone
FROM household_income;

UPDATE household_income
SET zone = REPLACE(zone,' ','');

-- classify gini value
SELECT MIN(gini_coefficient), MAX(gini_coefficient)
FROM household_income;

ALTER TABLE household_income
ADD COLUMN income_between_household text;

UPDATE household_income
SET income_between_household =
  CASE  WHEN gini_coefficient BETWEEN 0.1 AND 0.25 THEN 'lower inequality'
		WHEN gini_coefficient BETWEEN 0.26 AND 0.35 THEN 'moderate inequality'
        WHEN gini_coefficient > 0.35 THEN 'greater ineaquality'
ELSE 'Not Applicable' 
END;

SELECT *
FROM household_income;

-- update missing string

UPDATE household_income
SET state = 'W.P. Kuala Lumpur'
WHERE country_code = 'KUL';

UPDATE household_income
SET state = 'W.P. Labuan'
WHERE country_code = 'LBN';

UPDATE household_income
SET state = 'W.P. Putrajaya'
WHERE country_code = 'PJY';

-- join table and create new table

CREATE TABLE finaltable AS
SELECT HI.date,
		P. idxs,
		HI.state,
        HI.country_code,
        HI.zone,
        P.pop,
        HI.district,
        HI.income_median,
        HI.expenditure_mean,
        HI.gini_coefficient,
        HI.income_between_household,
        HI.poverty_rate
FROM household_income HI
JOIN population P ON HI.state = P.state;

SELECT * 
FROM finaltable;

-- find and remove duplicate 
SELECT district, count(*)
FROM finaltable
GROUP BY district
HAVING count(*) > 1;

WITH RowNumCTE AS (
SELECT *, ROW_NUMBER() OVER (PARTITION BY district ORDER BY idxs) AS row_num
FROM finaltable
)

DELETE 
FROM finaltable
WHERE (district, idxs) IN 
(SELECT district, idxs
 FROM RowNumCTE
WHERE row_num > 1);

-- final result after undergo data cleaning
SELECT * 
FROM finaltable;










