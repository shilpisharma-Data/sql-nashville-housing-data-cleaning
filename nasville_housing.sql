/*
Nashville Housing Data Cleaning

Skills Used: Data Manipulation Language (DML), Data Query Language (DQL), Data Definition Lanuage (DDL)

*/

-- Cleaning Data in SQL Queries


USE nashville_housing;

-- View Data
SELECT * FROM nashville_data;

-- Standardize Date Format
-- Convert SaleDate to proper DATE format

ALTER TABLE nashville_data
ADD COLUMN SaleDateConverted DATE;

SET SQL_SAFE_UPDATES = 0;

UPDATE nashville_data
SET SaleDateConverted = STR_TO_DATE(SaleDate, '%M %d, %Y');

SET SQL_SAFE_UPDATES = 1;


-- Fill Missing PropertyAddress (Self Join)
-- Some rows have NULL property addresses but same ParcelID.- 

SET SQL_SAFE_UPDATES = 0;

UPDATE nashville_data t1
JOIN nashville_data t2
  ON t1.ParcelID = t2.ParcelID
  AND t1.UniqueID <> t2.UniqueID
SET t1.PropertyAddress = t2.PropertyAddress
WHERE t1.PropertyAddress IS NULL;

SET SQL_SAFE_UPDATES = 1;

-- Split Property Address into  individual columns (Address, City) [USING SUBSTRING()]

-- Add new columns
ALTER TABLE nashville_data
ADD COLUMN PropertyStreet VARCHAR(255),
ADD COLUMN PropertyCity VARCHAR(255);

-- Split using comma
SET SQL_SAFE_UPDATES = 0;
UPDATE nashville_data
SET 
PropertyStreet = SUBSTRING_INDEX(PropertyAddress, ',', 1),
PropertyCity = TRIM(SUBSTRING_INDEX(PropertyAddress, ',', -1));
SET SQL_SAFE_UPDATES = 1;

-- Split Owner Address into individual columns (Address, City)
ALTER TABLE nashville_data
ADD COLUMN OwnerStreet VARCHAR(255),
ADD COLUMN OwnerCity VARCHAR(255),
ADD COLUMN OwnerState VARCHAR(50);

SET SQL_SAFE_UPDATES = 0;
UPDATE nashville_data
SET 
OwnerStreet = SUBSTRING_INDEX(OwnerAddress, ',', 1),
OwnerCity = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1),
OwnerState = SUBSTRING_INDEX(OwnerAddress, ',', -1);
SET SQL_SAFE_UPDATES = 1;


-- Standardize SoldAsVacant (Y/N → Yes/No)
SET SQL_SAFE_UPDATES = 0;
UPDATE nashville_data
SET SoldAsVacant = 
CASE 
    WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
END;
SET SQL_SAFE_UPDATES = 1;

SELECT DISTINCT SoldAsVacant
FROM nashville_data;

-- Remove Duplicates
-- Check duplicates first

SELECT ParcelID, PropertyAddress, SalePrice, SaleDateConverted, COUNT(*)
FROM nashville_data
GROUP BY ParcelID, PropertyAddress, SalePrice, SaleDateConverted
HAVING COUNT(*) > 1;

-- Delete duplicates (keep minimum UniqueID)

SET SQL_SAFE_UPDATES = 0;
DELETE FROM nashville_data
WHERE UniqueID NOT IN (
    SELECT * FROM (
        SELECT MIN(UniqueID)
        FROM nashville_data
        GROUP BY ParcelID, PropertyAddress, SalePrice, SaleDateConverted
    ) AS temp
);

-- Create a Duplicate Table with Row Number- 
SET SQL_SAFE_UPDATES = 0;

CREATE TABLE nashville_dedup AS
SELECT *,
       ROW_NUMBER() OVER (
           PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDateConverted
           ORDER BY UniqueID
       ) AS row_num
FROM nashville_data;

SET SQL_SAFE_UPDATES = 1;

-- Delete Duplicates Safely
SET SQL_SAFE_UPDATES = 0;
DELETE FROM nashville_dedup
WHERE row_num > 1;

-- Drop Old Table
DROP TABLE nashville_data;

ALTER TABLE nashville_dedup
DROP COLUMN row_num;

RENAME TABLE nashville_dedup TO nashville_data;
SELECT* FROM  nashville_housing.nashville_data;



 




