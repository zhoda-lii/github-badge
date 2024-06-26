-- Step 1: Use master
USE master
GO

-- Step 2: Drop the GymProgressTracker database if it already exists
IF DB_ID('GymProgressTracker') IS NOT NULL
	DROP DATABASE GymProgressTracker
GO

-- Step 3: Create the database
CREATE DATABASE GymProgressTracker
GO

-- Step 4: Use the newly created database
USE GymProgressTracker
GO

-- Step 5: Confirm to standards
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Step 6: Create tables and add constraints (PK, NULLs, Checks, etc) 
-- Create the Members table
CREATE TABLE Members (
    MemberID		INT IDENTITY(1,1)	NOT NULL,
    FirstName		NVARCHAR(50)		NOT NULL,
    LastName		NVARCHAR(50)		NOT NULL,
    Gender			CHAR(1)				NOT NULL,
    Email			NVARCHAR(50)		NULL,
    Phone			NVARCHAR(20)		NOT NULL,
    DateOfBirth		DATE				NOT NULL,
    MembershipStart	DATE				NULL,
    MembershipEnd	DATE				NULL,
    MembershipType	NVARCHAR(10)		NULL,
    TrainerMbrID	INT					NULL,
	PRIMARY KEY (MemberID),
	CHECK (Gender = 'M' OR Gender = 'F'),
    CHECK (MembershipType = 'Standard' OR MembershipType = 'Premium')
)
GO
-- Create the Payments table
CREATE TABLE Payments (
    PaymentID		INT IDENTITY(1,1)	NOT NULL,
    PaymentDate		DATE				NOT NULL,
    Amount			MONEY				NOT NULL,
    PaymentMethod	NVARCHAR(50)		NOT NULL,
    MemberID		INT					NOT NULL,
	PRIMARY KEY (PaymentID),
	CHECK (Amount = 50 OR Amount = 100),
    CHECK (PaymentMethod IN ('Cash', 'Debit Card', 'Credit Card'))
)
GO
-- Create the Attendances table
CREATE TABLE Attendances (
    AttendanceID	INT IDENTITY(1,1)	NOT NULL,
    AttendanceDate	DATE		    	NOT NULL,
    CheckInTime		TIME		    	NOT NULL,
    CheckOutTime	TIME	    		NULL,
    MemberID		INT					NOT NULL,
	PRIMARY KEY (AttendanceID)
)
GO
-- Create the Equipments table
CREATE TABLE Equipments (
    EquipmentID		INT IDENTITY(1,1)	NOT NULL,
    EquipmentName	NVARCHAR(50)		NOT NULL,
    EquipmentType	NVARCHAR(50)		NOT NULL,
	PRIMARY KEY (EquipmentID)
)
GO
-- Create the EquipmentUsages table
CREATE TABLE EquipmentUsages (
    UsageDate	DATE	NOT NULL,
    MemberID	INT		NOT NULL,
	EquipmentID	INT		NOT NULL,
    UsageStart	TIME	NOT NULL,
    UsageEnd	TIME	NULL,
	-- Member can use each equipment once per day:
	--   MemberID + UsageDate + EquipmentID must be unique
	PRIMARY KEY (UsageDate, MemberID, EquipmentID)
)
GO
-- Create the FitnessRecords table
CREATE TABLE FitnessRecords (
    RecordDate			DATE				NOT NULL,
    MemberID			INT					NOT NULL,
    CalorieIntake  		DECIMAL(10,2)		NOT NULL,
    WeightLbs       	DECIMAL(10,2)		NOT NULL,
    HeightInches       	DECIMAL(10,2)		NOT NULL,
	PRIMARY KEY (RecordDate, MemberID)
)
GO
-- Step 7: Add Foreign Key constraints
-- For the Members table
ALTER TABLE Members
ADD CONSTRAINT fkMembersMbrID FOREIGN KEY (TrainerMbrID) REFERENCES Members(MemberID);
-- For the Payments table
ALTER TABLE Payments
ADD CONSTRAINT fkPaymentsMbrID FOREIGN KEY (MemberID) REFERENCES Members(MemberID);
-- For the Attendances table
ALTER TABLE Attendances
ADD CONSTRAINT fkAttendancesMbrID FOREIGN KEY (MemberID) REFERENCES Members(MemberID);
-- For the EquipmentUsages table
ALTER TABLE EquipmentUsages
ADD CONSTRAINT fkEquipUsagesMbrID FOREIGN KEY (MemberID) REFERENCES Members(MemberID),
	CONSTRAINT fkEquipUsagesEqpID FOREIGN KEY (EquipmentID) REFERENCES Equipments(EquipmentID);
-- For the FitnessRecords table
ALTER TABLE FitnessRecords
ADD CONSTRAINT fkFitnessRecordsMbrID FOREIGN KEY (MemberID) REFERENCES Members(MemberID);
