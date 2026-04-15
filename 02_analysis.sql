-- ANALYSIS
-- ==================================================
-- Main Goal: Investigate relationships between chronic conditions, patient demographics, and treatment patterns.
   -- The following analysis builds on the exploration phase, where chronic conditions were defined as those lasting 180 days or longer.

-- ==================================================
-- CHRONIC CONDITIONS ANALYSIS
-- ==================================================
   -- Purpose: Identify which diseases represent the largest share of long-term conditions in the dataset.

-- 1. Which medical conditions are most frequently classified as chronic?
WITH condition_type AS (
  SELECT 
    description,
    patient,
    CASE
        WHEN julianday(stop) - julianday(start) >= 180 THEN 'Chronic'
        ELSE 'Acute'
    END AS condition
  FROM conditions
)

  SELECT
    COUNT(*) AS chronic_frequency,
    COUNT(DISTINCT patient) AS unique_patients,
    description
  FROM condition_type
  WHERE condition =  'Chronic'
  GROUP BY description
  ORDER BY chronic_frequency DESC;

-- Observations: 
  -- "Normal pregnancy" appears as the most frequent chronic condition based on the duration-based definition (≥ 180 days). However, pregnancy is not a chronic disease, indicating that duration alone is not sufficient to accurately classify chronic conditions.
  -- However, this approach does not account for how conditions are distributed across patients.
  -- To address this, the analysis was complemented to include the number of unique patients affected by each condition. This provides a more complete view of both condition frequency and patient-level impact.

-- 2. What proportion of patients live with at least one chronic condition by age group?
WITH age AS ( 
SELECT 
  id,
  CASE WHEN (julianday('now') - julianday(birthdate)) / 365.25 < 18 THEN 'Under age' 
    WHEN (julianday('now') - julianday(birthdate)) / 365.25 BETWEEN 18 AND 59 THEN 'Adult'
    ELSE 'Senior' 
  END AS age_group 
 FROM patients
),

chronic_conditions_patients AS (
SELECT
  DISTINCT patient
FROM conditions
WHERE julianday(stop) - julianday(start) >= 180 
)

SELECT 
  age_group, 
  COUNT(a.id) AS total_patients,
  COUNT(cp.patient) AS patients_with_chronic,
  1.0 * COUNT(cp.patient) / COUNT(a.id) AS proportion
FROM age AS a
LEFT JOIN chronic_conditions_patients AS cp 
ON a.id = cp.patient
GROUP BY age_group;

-- Observations: 
  -- Adult patients show the highest proportion of chronic conditions (34%), more than double that of seniors (16%) and underage patients (15%).
  -- This is a surprising pattern, as chronic conditions are typically associated with older populations. This may suggest either a dataset bias or that chronic conditions are being defined in a way that captures long-lasting conditions not necessarily related to aging.

-- 3. How common is multimorbidity (patients with multiple chronic conditions)?
WITH chronic_conditions AS (
SELECT
  patient,
  description
FROM conditions
WHERE julianday(stop) - julianday(start) >= 180 
), 

conditions_per_patient AS (
SELECT 
  patient,
  COUNT(*) AS conditions_patient
FROM chronic_conditions
GROUP BY patient
) 

SELECT  
  COUNT(*) AS total_patients,
  SUM(CASE WHEN conditions_patient >= 2 THEN 1 ELSE 0 END) AS multimorbid_patients,
  1.0 * SUM(CASE WHEN conditions_patient >= 2 THEN 1
     ELSE 0
     END) / COUNT(*) AS multimorbidity_rate
FROM conditions_per_patient;

-- Observations: 
  -- Approximately 40% of patients with at least one chronic condition are affected by multimorbidity (having two or more chronic conditions).
  -- This indicates a relatively high level of disease complexity within the patient population, suggesting that a significant portion of patients may require more comprehensive and coordinated treatment strategies.


-- 4. Are the most frequently prescribed medications associated with chronic conditions?
WITH chronic_conditions AS (
SELECT
  patient
FROM conditions
WHERE julianday(stop) - julianday(start) >= 180 
)

SELECT 
  m.description, 
  COUNT(*) AS total_prescriptions,
  COUNT(cc.patient) AS chronic_prescriptions,
  1.0 *  COUNT(cc.patient) / COUNT(*) AS chronic_prescription_rate
FROM medications AS m
LEFT JOIN chronic_conditions AS cc
  ON m.patient = cc.patient 
GROUP BY m.description
ORDER BY  chronic_prescription_rate DESC;

-- Observations: 
  -- While several medications show a 100% association with chronic patients, most of them have very low prescription counts, limiting their analytical significance.
  -- Medications with both high prescription volume and high proportions of use among chronic patients can be considered strongly associated with chronic conditions. 
  -- In contrast, medications that show high proportions but low prescription counts provide limited analytical value, as their apparent association may be driven by small sample sizes rather than meaningful trends.