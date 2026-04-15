-- Main goal: Analyze patterns of chronic conditions and associated treatments across patient demographics.
   -- In this file, the exploration goal is to understant the data, test assumptions, check distributions, validate logic, figure out definitions (like 'what is chronic?').

-- =====================================
-- CONDITIONS EXPLORATION
   -- Purpose: To define what 'chronic' means in this dataset.

 -- 1. How many condition records exist?
SELECT 
  COUNT(*) AS total_condition_records
FROM conditions;

SELECT 
  DISTINCT COUNT(*) AS unique_conditions
FROM conditions;

SELECT 
  COUNT(*) AS condition_count, 
  description
FROM conditions
GROUP BY description
ORDER BY condition_count DESC
LIMIT 10;

-- Observations:
   -- The count of condition records and distinc conditions records are the same.
   -- The most frequent condition is "Viral sinusitis (disorder)".
   -- This condition appears to be acute rather than chronic, therefore, raw frequency does not equal chronic prevalence.

-- 2. Are there many duplicates?
SELECT 
  e.id, 
  c.description,
  c.start, 
COUNT(*) AS record_count
FROM encounters AS e
JOIN conditions AS c
  ON e.PATIENT = c.PATIENT
GROUP BY e.id, c.description, c.start 
HAVING COUNT(*) > 1;

-- Observations: 
   -- For each patient, each condition description on each start date, there is only one record.
   -- So it is safe to assume there are no duplicates per patient (at least under that definition).

-- 3. What is the typical duration of conditions?
SELECT 
  DESCRIPTION,
  MIN(julianday(stop) - julianday(start)) AS min_duration,
  MAX(julianday(stop) - julianday(start)) AS max_duration,
  AVG(julianday(stop) - julianday(start)) AS avg_duration
FROM conditions
GROUP BY DESCRIPTION;

-- Observations: 
  -- Some conditions have an average duration exceeding 180 days, indicating the presence of long-term conditions in the dataset.
  -- I used the date function ''julianday'' to convert a date into a number and subtract two dates. 

-- 4. How can be identified Chronic conditions in the dataset? 
SELECT
    *,
    CASE
        WHEN julianday(stop) - julianday(start) >= 180 THEN 'Chronic'
        ELSE 'Acute'
    END AS condition_type
FROM conditions
WHERE stop IS NOT NULL;

-- Observations:
  -- A ''chronic flag'' was created to identify conditions more precisely instead of just using AVG days and maybe misleading final result for accute or chronic condition. 
-- =====================================


-- =====================================
-- PATIENT DEMOGRAPHICS EXPLORATION
   -- Purpose: To know how to segment patients.

-- 1. How will age be calculated?
SELECT 
  *,
  CAST((julianday('now') - julianday(birthdate)) / 365.25 AS INTEGER) AS age
FROM patients

-- Observations: 
  -- The age will be calculated using the ''birthday'' column from the Patients table, with a date function to set the present date. 


-- 2. Is gender clean? Any nulls?
SELECT  
 gender
FROM patients
WHERE gender IS NULL

-- Observations:
  -- There is no null value in the gender column from Patients table. 

-- 3. What’s the age distribution?
WITH age AS ( 
SELECT 
  CAST((julianday('now') - julianday(birthdate)) / 365.25 AS INTEGER) AS patient_age 
FROM patients 
)

SELECT 
  COUNT(*), 
  CASE WHEN patient_age < 18 THEN 'Under age' 
  WHEN patient_age BETWEEN 18 AND 59 THEN 'Adult'
  ELSE 'Senior' 
  END AS age_group 
 FROM age 
 GROUP BY age_group

-- Observations: 
  -- Patients were segmented into age groups to provide context for the chronic condition analysis. Since older patients are more likely to develop chronic diseases, comparing chronic prevalence within each age group (instead of using raw counts) ensures a more meaningful analysis. 
-- =====================================


-- =====================================
-- MEDICATIONS EXPLORATION
   -- Purpose: To understand how treatment is recorded.

   -- 1. How many medication records exist and how many patients received medication?
   SELECT 
     COUNT(*) AS total_medication_records,
     COUNT(DISTINCT patient) AS patients_with_medication
   FROM medications;

   -- Observations: 
     -- There is a high medication intensity per patient. - 42989 medications to 1107 unique patients. 

   -- 2. Which medications are most frequently prescribed?
   SELECT 
   description,
   COUNT(*) AS prescription_count
   FROM medications
   GROUP BY description
   ORDER BY prescription_count DESC;

   -- Observations:
     -- Four medications appear significantly more frequently than others. This may suggest a concentration of treatment around specific conditions, potentially chronic ones, but further analysis is needed to confirm.

   -- 3. Are there medications prescribed only once?
   SELECT 
     description, 
     COUNT(*) as count_prescriptions
  FROM medications
  GROUP BY DESCRIPTION
  HAVING COUNT(*) = 1;

-- Observations: 
  -- Only 12 medications were pescribed only once, so it may represent rare treatments or highly specific clinical cases.
-- =====================================

-- ==================================================
-- END OF EXPLORATION
-- ==================================================

-- The dataset structure and key variables are now understood.
-- Next step: move to deeper analytical queries in 02_analysis.sql