-- Use the GymProgressTracker database
USE GymProgressTracker
GO

-- Test select all tables
SELECT * FROM Attendances;
SELECT * FROM Equipments;
SELECT * FROM EquipmentUsages;
SELECT * FROM FitnessRecords;
SELECT * FROM Members;
SELECT * FROM Payments;


-- Test the Views
SELECT * FROM vwMemberInitialWeight;
SELECT * FROM vwMemberLatestWeight;
SELECT * FROM vwMemberInitialVsLatest;
-- View #1
SELECT * FROM vwMemberLatestStatus;
-- View #2
SELECT * FROM vwTrainerNutritionTraining
WHERE MemberID = 3;
-- View #3
SELECT * FROM vwFinanceMembershipPayment;



-- Test the Stored Procedures
-- Stored Procedure #1: spAddMember
EXEC spAddMember
	@FirstName = 'Filmer',
	@LastName = 'Cromly',
	@Gender = 'M',
	@Email = 'fcromly3@symantec.com',
	@Phone = '2168969541',
	@DateOfBirth = '1995-08-24',
	@TrainerMbrID = 2; -- pay 100 if has trainer, 50 if no trainer

SELECT * FROM Members;

-- Stored Procedure #2: spAddPaymentUpdateMembership
EXEC spAddPaymentUpdateMembership 
    @MemberID = 23, -- change this to the newly created member id
    @PaymentAmount = 100, -- pay 100 if has trainer, 50 if no trainer
    @PaymentMethod = 'Credit Card';
	
SELECT * FROM Payments;
SELECT * FROM Members;

-- Stored Procedure #3: spMemberCheckIn
EXEC spMemberCheckIn
    @MemberID = 13; -- change this to the newly created member id

SELECT * FROM Attendances;

-- Stored Procedure #4: spMemberCheckOut
EXEC spMemberCheckOut
    @MemberID = 13; -- change this to the newly created member id
	
SELECT * FROM Attendances;

-- Stored Procedure #5: spAddFitnessRecord
EXEC spAddFitnessRecord
	@MemberID = 13, -- change this to the newly created member id
	@CalorieIntake = 2500,
	@WeightLbs = 150,
	@HeightInches = 68;

SELECT * FROM Members;
SELECT * FROM FitnessRecords;

-- Stored Procedure #6: spAddEquipmentUsageStart
EXEC spAddEquipmentUsageStart
	@MemberID = 13, -- change this to the newly created member id
	@EquipmentID = 2;

SELECT * FROM EquipmentUsages;
SELECT * FROM Equipments;

-- Stored Procedure #7: spAddEquipmentUsageEnd
EXEC spAddEquipmentUsageEnd
	@MemberID = 13,
	@EquipmentID = 2;





-- Test the Triggers
-- Trigger #1: tgDeleteAttendanceOutsideGymHours
EXEC spMemberCheckIn
    @MemberID = 2;

-- Trigger #2: tgPreventCheckinsWithoutCheckout
EXEC spMemberCheckIn
    @MemberID = 6;

-- Trigger #3: tgPreventIncorrectPayment
EXEC spAddPaymentUpdateMembership 
    @MemberID = 23, -- change this to the newly created member id
    @PaymentAmount = 99, -- pay 100 if has trainer, 50 if no trainer
    @PaymentMethod = 'Credit Card';
