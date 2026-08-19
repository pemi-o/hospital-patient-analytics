-- Data Cleaning

SELECT * FROM Dim_Patient;
SELECT * FROM Dim_Doctor;
SELECT * FROM Dim_Department;
SELECT * FROM Dim_Diagnosis;
SELECT * FROM Dim_Treatment;
SELECT * FROM Dim_PaymentMethod;
SELECT * FROM PatientVisits_2020_2021;
SELECT * FROM PatientVisits_2022_2023;
SELECT * FROM PatientVisits_2024;
SELECT * FROM PatientVisits_2025;

-- Data Cleaning (Patient Table)
-- Remove patient rows where FirstName is missing
-- Standardize FirstName and LastName to proper case and create a new FullName column
-- Gender values should be either Male or Female
-- Split CityStateCountry into City, State, and Country columns


CREATE TABLE `Dim_Patient_Clean` (
  `PatientID` varchar(20) NOT NULL,
  `FullName` varchar(120),
  `Gender` varchar(10),
  `DOB` date,
  `City` varchar(50),
  `State` varchar(50),
  `Country` varchar(50),
  PRIMARY KEY (`PatientID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO Dim_Patient_Clean (
	PatientID, FullName, Gender, DOB, City, State, Country
)
SELECT 
	p.PatientID,
    CONCAT (
		UPPER(LEFT(TRIM(p.FirstName), 1)), 
        LOWER(SUBSTRING(TRIM(p.FirstName),2)),
        " ",
        UPPER(LEFT(TRIM(p.LastName), 1)), 
        LOWER(SUBSTRING(TRIM(p.LastName),2)) 
    ) AS FullName,
    CASE
		WHEN TRIM(p.Gender) = "M" THEN "Male"
        WHEN TRIM(p.Gender) = "F" THEN "Female"
        ELSE TRIM(p.Gender)
	END AS Gender,
    p.DOB,
    TRIM(SUBSTRING_INDEX(p.CityStateCountry, ',', 1)) AS City,
	TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.CityStateCountry, ',', 2), ',', -1)) AS State,
	TRIM(SUBSTRING_INDEX(p.CityStateCountry, ',', -1)) AS Country
FROM Dim_Patient AS p
WHERE p.FirstName IS NOT NULL
;    


-- SUBSTRING_INDEX(string, delimiter, count)


-- Data Cleaning (Department Table)
-- Remove departments where DepartmentCategory is missing
-- Drop HOD and DepartmentName columns
-- Use Specialization as DepartmentName column



CREATE TABLE `Dim_Department_Clean` (
  `DepartmentID` varchar(20) NOT NULL,
  `DepartmentName` varchar(100),
  `DepartmentCategory` varchar(100),
  PRIMARY KEY (`DepartmentID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO Dim_Department_Clean (
	DepartmentID, DepartmentName, DepartmentCategory
)
SELECT 
	d.DepartmentID,
    TRIM(d.Specialization) AS DepartmentName,
    TRIM(d.DepartmentCategory) AS DepartmentCategory
FROM Dim_Department AS d
WHERE NULLIF(TRIM(d.DepartmentCategory), "") IS NOT NULL
;

-- Data Cleaning (Patient Visits Table)
-- Merge all yearly visit tables (2020�2025) into one consolidated PatientVisits table



CREATE TABLE `PatientVisits` (
  `VisitID` varchar(20) NOT NULL,
  `PatientID` varchar(20),
  `DoctorID` varchar(20),
  `DepartmentID` varchar(20),
  `DiagnosisID` varchar(20),
  `TreatmentID` varchar(20),
  `PaymentMethodID` varchar(20),
  `VisitDate` date,
  `VisitTime` time,
  `DischargeDate` date,
  `BillAmount` decimal(18,2),
  `InsuranceAmount` decimal(18,2),
  `SatisfactionScore` int,
  `WaitTimeMinutes` int,
  PRIMARY KEY (`VisitID`),
  FOREIGN KEY (`PatientID`) REFERENCES `Dim_Patient_Clean` (`PatientID`),
  FOREIGN KEY (`DoctorID`) REFERENCES `Dim_Doctor` (`DoctorID`),
  FOREIGN KEY (`DepartmentID`) REFERENCES `Dim_Department_Clean` (`DepartmentID`),
  FOREIGN KEY (`DiagnosisID`) REFERENCES `Dim_Diagnosis` (`DiagnosisID`),
  FOREIGN KEY (`TreatmentID`) REFERENCES `Dim_Treatment` (`TreatmentID`),
  FOREIGN KEY (`PaymentMethodID`) REFERENCES `Dim_PaymentMethod` (`PaymentMethodID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO PatientVisits (
	VisitID, PatientID, DoctorID, DepartmentID, DiagnosisID, TreatmentID, PaymentMethodID, 
    VisitDate, VisitTime, DischargeDate, BillAmount, InsuranceAmount, SatisfactionScore, WaitTimeMinutes
)

SELECT *
FROM PatientVisits_2020_2021

UNION ALL

SELECT *
FROM PatientVisits_2022_2023

UNION ALL

SELECT *
FROM PatientVisits_2024

UNION ALL

SELECT *
FROM PatientVisits_2025
;









    