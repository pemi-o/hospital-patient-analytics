-- Exploratory Data Analysis
-- Run after 01_schema.sql, 02_data_load.sql, and 03_data_cleaning.sql

-- ============================================================
-- Q1. For each doctor, count how many distinct patients they treated.
-- ============================================================
SELECT
    doc.DoctorID,
    CONCAT(doc.FirstName, " ", doc.LastName) AS DoctorName,
    COUNT(DISTINCT v.PatientID) AS DistinctPatients
FROM PatientVisits AS v
JOIN Dim_Doctor AS doc
    ON v.DoctorID = doc.DoctorID
GROUP BY doc.DoctorID, doc.FirstName, doc.LastName
ORDER BY DistinctPatients DESC;

-- Result: 200 doctors handled between ~50 and 108 distinct patients each,
-- fairly evenly spread — no single doctor is a major bottleneck.
-- Top doctor: Dr. Vikram Singh, 108 distinct patients.


-- ============================================================
-- Q2. Revenue split by payment method, with total visits per method.
-- ============================================================
SELECT
    pm.PaymentMethod,
    SUM(v.BillAmount) AS TotalRevenue,
    COUNT(v.VisitID) AS TotalVisits
FROM PatientVisits AS v
JOIN Dim_PaymentMethod AS pm
    ON v.PaymentMethodID = pm.PaymentMethodID
GROUP BY pm.PaymentMethod
ORDER BY TotalRevenue DESC;

-- Result: UPI leads with ~₹496M across 5,404 visits (33% of all visits),
-- ahead of Debit Card, Credit Card, and Cash, which are nearly tied
-- (~₹332-340M / ~3,700 visits each).


-- ============================================================
-- Q3. Categorize patients into age groups and find avg bill amount per band.
-- (Age calculated at time of visit, using VisitDate - DOB.)
-- ============================================================
SELECT
    CASE
        WHEN age < 18 THEN '0-17'
        WHEN age BETWEEN 18 AND 34 THEN '18-34'
        WHEN age BETWEEN 35 AND 50 THEN '35-50'
        WHEN age BETWEEN 51 AND 65 THEN '51-65'
        ELSE '66+'
    END AS AgeBand,
    COUNT(*) AS Visits,
    ROUND(AVG(v.BillAmount), 2) AS AvgBillAmount
FROM PatientVisits AS v
JOIN Dim_Patient_Clean AS p
    ON p.PatientID = v.PatientID
CROSS JOIN LATERAL (
    SELECT
        TIMESTAMPDIFF(YEAR, p.DOB, v.VisitDate) AS age
) AS a
WHERE v.VisitDate IS NOT NULL AND p.DOB IS NOT NULL
GROUP BY AgeBand
ORDER BY MIN(age);

-- Note: MySQL 8+ syntax above uses TIMESTAMPDIFF for accurate age-at-visit.
-- Result: avg bill is fairly flat across age bands (~₹88K-94K), with the
-- 66+ group slightly the highest (₹93,640) and 0-17 slightly the lowest
-- (₹88,389) — age alone isn't a strong driver of bill amount in this data.


-- ============================================================
-- Bonus. Top 5 diagnoses by visit volume, and overall service-quality snapshot.
-- ============================================================
SELECT
    dx.DiagnosisName,
    COUNT(*) AS Visits
FROM PatientVisits AS v
JOIN Dim_Diagnosis AS dx
    ON v.DiagnosisID = dx.DiagnosisID
GROUP BY dx.DiagnosisName
ORDER BY Visits DESC
LIMIT 5;

SELECT
    ROUND(AVG(WaitTimeMinutes), 1) AS AvgWaitMinutes,
    ROUND(AVG(SatisfactionScore), 2) AS AvgSatisfactionScore,
    ROUND(AVG(BillAmount), 2) AS AvgBillAmount
FROM PatientVisits;

-- Result: avg wait time ~56.5 minutes, avg satisfaction 3.62/5,
-- avg bill ₹91,150 across all 16,543 visits.
