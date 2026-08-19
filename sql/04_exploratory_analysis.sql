-- ============================================================
-- Hospital Patient Visits Analysis
-- Exploratory Data Analysis
--
-- Run after:
--   01_schema.sql
--   02_data_load.sql
--   03_data_cleaning.sql
--
-- Dataset: Synthetic hospital visit data, 2020-2025
-- Total visits: 16,543
-- ============================================================


-- ============================================================
-- Q1. Doctor workload
-- Count how many distinct patients each doctor has treated.
-- ============================================================

SELECT
    doc.DoctorID,
    CONCAT(doc.FirstName, ' ', doc.LastName) AS DoctorName,
    COUNT(DISTINCT v.PatientID) AS DistinctPatients
FROM PatientVisits AS v
JOIN Dim_Doctor AS doc
    ON v.DoctorID = doc.DoctorID
GROUP BY
    doc.DoctorID,
    doc.FirstName,
    doc.LastName
ORDER BY DistinctPatients DESC;


-- ============================================================
-- Q2. Revenue by payment method
-- Show total revenue and number of visits for each payment method.
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


-- ============================================================
-- Q3. Average bill amount by age group
-- Categorize patients based on their age at the time of the visit.
-- ============================================================

WITH PatientAge AS (
    SELECT
        v.VisitID,
        v.BillAmount,
        TIMESTAMPDIFF(YEAR, p.DOB, v.VisitDate) AS Age
    FROM PatientVisits AS v
    JOIN Dim_Patient_Clean AS p
        ON v.PatientID = p.PatientID
    WHERE v.VisitDate IS NOT NULL
      AND p.DOB IS NOT NULL
),

AgeGroups AS (
    SELECT
        VisitID,
        BillAmount,
        CASE
            WHEN Age < 18 THEN '0-17'
            WHEN Age BETWEEN 18 AND 35 THEN '18-35'
            WHEN Age BETWEEN 36 AND 55 THEN '36-55'
            ELSE '56+'
        END AS AgeGroup
    FROM PatientAge
)

SELECT
    AgeGroup,
    COUNT(*) AS TotalVisits,
    ROUND(AVG(BillAmount), 2) AS AvgBillAmount
FROM AgeGroups
GROUP BY AgeGroup
ORDER BY
    CASE AgeGroup
        WHEN '0-17' THEN 1
        WHEN '18-35' THEN 2
        WHEN '36-55' THEN 3
        WHEN '56+' THEN 4
    END;


-- ============================================================
-- Q4. Revenue and visit volume by department
-- Calculate total revenue and number of visits for each department.
-- ============================================================

SELECT
    d.DepartmentName,
    SUM(v.BillAmount) AS TotalRevenue,
    COUNT(v.VisitID) AS TotalVisits
FROM PatientVisits AS v
JOIN Dim_Department_Clean AS d
    ON v.DepartmentID = d.DepartmentID
GROUP BY d.DepartmentName
ORDER BY TotalRevenue DESC;


-- ============================================================
-- Q5. Department revenue ranking within each category
-- Rank departments based on total revenue within their
-- respective department category.
-- ============================================================

WITH DepartmentRevenue AS (
    SELECT
        d.DepartmentCategory,
        d.DepartmentName,
        SUM(v.BillAmount) AS TotalRevenue
    FROM PatientVisits AS v
    JOIN Dim_Department_Clean AS d
        ON v.DepartmentID = d.DepartmentID
    GROUP BY
        d.DepartmentCategory,
        d.DepartmentName
)

SELECT
    DepartmentCategory,
    DepartmentName,
    TotalRevenue,
    RANK() OVER (
        PARTITION BY DepartmentCategory
        ORDER BY TotalRevenue DESC
    ) AS RevenueRank
FROM DepartmentRevenue
ORDER BY
    DepartmentCategory,
    RevenueRank;


-- ============================================================
-- Q6. Patient satisfaction and wait time by department
-- Calculate average satisfaction score and average wait time
-- for each department.
-- ============================================================

SELECT
    d.DepartmentName,
    ROUND(AVG(v.SatisfactionScore), 2) AS AvgSatisfactionScore,
    ROUND(AVG(v.WaitTimeMinutes), 2) AS AvgWaitTime
FROM PatientVisits AS v
JOIN Dim_Department_Clean AS d
    ON v.DepartmentID = d.DepartmentID
GROUP BY d.DepartmentName
ORDER BY AvgSatisfactionScore DESC;


-- ============================================================
-- Q7. Weekday vs weekend visits
-- Compare the total number of hospital visits on weekdays
-- versus weekends.
-- ============================================================

SELECT
    DayType,
    COUNT(*) AS TotalVisits
FROM (
    SELECT
        CASE
            WHEN DAYNAME(VisitDate) IN ('Saturday', 'Sunday')
                THEN 'Weekend'
            ELSE 'Weekday'
        END AS DayType
    FROM PatientVisits
    WHERE VisitDate IS NOT NULL
) AS VisitDays
GROUP BY DayType
ORDER BY TotalVisits DESC;


-- ============================================================
-- Q8. Monthly visits and cumulative visits
-- Calculate total visits for each month and a running
-- cumulative total across the dataset.
-- ============================================================

WITH MonthlyVisits AS (
    SELECT
        DATE_FORMAT(VisitDate, '%Y-%m-01') AS MonthStart,
        COUNT(*) AS TotalVisits
    FROM PatientVisits
    WHERE VisitDate IS NOT NULL
    GROUP BY DATE_FORMAT(VisitDate, '%Y-%m-01')
)

SELECT
    MonthStart,
    TotalVisits,
    SUM(TotalVisits) OVER (
        ORDER BY MonthStart
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS CumulativeVisits
FROM MonthlyVisits
ORDER BY MonthStart;


-- ============================================================
-- Q9. Doctors with the highest average satisfaction
-- Find doctors with an average satisfaction score of at least
-- 100 visits to ensure the comparison is based on a meaningful
-- number of visits.
-- ============================================================

SELECT
    d.DoctorID,
    CONCAT(
        TRIM(d.FirstName),
        ' ',
        TRIM(d.LastName)
    ) AS DoctorName,
    COUNT(v.VisitID) AS TotalVisits,
    ROUND(AVG(v.SatisfactionScore), 2) AS AvgSatisfactionScore
FROM Dim_Doctor AS d
JOIN PatientVisits AS v
    ON d.DoctorID = v.DoctorID
GROUP BY
    d.DoctorID,
    d.FirstName,
    d.LastName
HAVING COUNT(v.VisitID) >= 100
ORDER BY AvgSatisfactionScore DESC;


-- ============================================================
-- Q10. Most commonly prescribed treatment by diagnosis
-- Identify the treatment most frequently associated with each
-- diagnosis. RANK() allows ties to be returned.
-- ============================================================

WITH TreatmentFrequency AS (
    SELECT
        d.DiagnosisName,
        t.TreatmentName,
        COUNT(*) AS TreatmentCount,
        RANK() OVER (
            PARTITION BY d.DiagnosisName
            ORDER BY COUNT(*) DESC
        ) AS DiagnosisRank
    FROM PatientVisits AS v
    JOIN Dim_Diagnosis AS d
        ON v.DiagnosisID = d.DiagnosisID
    JOIN Dim_Treatment AS t
        ON v.TreatmentID = t.TreatmentID
    GROUP BY
        d.DiagnosisName,
        t.TreatmentName
)

SELECT
    DiagnosisName,
    TreatmentName,
    TreatmentCount
FROM TreatmentFrequency
WHERE DiagnosisRank = 1
ORDER BY DiagnosisName;


-- ============================================================
-- Q11. Top 5 diagnoses by visit volume
-- Identify the diagnoses associated with the highest number
-- of hospital visits.
-- ============================================================

SELECT
    d.DiagnosisName,
    COUNT(v.VisitID) AS TotalVisits
FROM PatientVisits AS v
JOIN Dim_Diagnosis AS d
    ON v.DiagnosisID = d.DiagnosisID
GROUP BY d.DiagnosisName
ORDER BY TotalVisits DESC
LIMIT 5;


-- ============================================================
-- Q12. Overall service and billing snapshot
-- Calculate overall average wait time, satisfaction score,
-- and bill amount across all hospital visits.
-- ============================================================

SELECT
    COUNT(v.VisitID) AS TotalVisits,
    ROUND(AVG(v.WaitTimeMinutes), 1) AS AvgWaitMinutes,
    ROUND(AVG(v.SatisfactionScore), 2) AS AvgSatisfactionScore,
    ROUND(AVG(v.BillAmount), 2) AS AvgBillAmount
FROM PatientVisits AS v;