-- Use the GymProgressTracker database
USE GymProgressTracker
GO



-- Function #1: GetCalorieMaintenance
-- Function to get Calorie Maintenance
CREATE FUNCTION GetCalorieMaintenance(
	@RecordDate DATE,
	@MemberID INT)
RETURNS DECIMAL(10,2)
AS
BEGIN
	-- Get Gender and DOB (Age)
	DECLARE @Gender CHAR(1);
	DECLARE @Age INT;
	DECLARE @DOB DATE;
	SELECT	@Gender = Gender,
			@DOB = DateOfBirth
	FROM Members
	WHERE MemberID = @MemberID;
	SET @Age = DATEDIFF(YEAR, @DOB, @RecordDate);
	-- Get WeightLbs and HeightInches
    DECLARE @WeightLbs DECIMAL(10,2);
    DECLARE @HeightInches DECIMAL(10,2);
	SELECT	@WeightLbs = WeightLbs,
			@HeightInches = HeightInches FROM FitnessRecords
	WHERE RecordDate = @RecordDate AND MemberID = @MemberID;
    -- Calculate Basal Metabolic Rate (BMR) based on gender
    DECLARE @WeightKg DECIMAL(10,2);
    DECLARE @HeightCm DECIMAL(10,2);
	SET @WeightKg = @WeightLbs / 2.204623
	SET @HeightCm = @HeightInches * 2.54

    DECLARE @BMR DECIMAL(10,2);
    DECLARE @CalorieMaintenance DECIMAL(10,2);
    IF @Gender = 'M'
        SET @BMR = (10 * @WeightKg) + (6.25 * @HeightCm) - (5 * @Age) + 5;
    ELSE
        SET @BMR = (10 * @WeightKg) + (6.25 * @HeightCm) - (5 * @Age) - 161;
    -- Calculate TDEE (Calorie Maintenance) based on BMR and activity level
	-- Total Daily Energy Expenditure is how much energy you burn each day
	-- which is basically equivalent to the amount of calories your body needs to maintain weight
    SET @CalorieMaintenance = @BMR * 1.55 -- Moderately active
    RETURN @CalorieMaintenance;
END;
GO

-- Function #2: GetBMIValue
-- Function to calculate the BMI Value
CREATE FUNCTION GetBMIValue(@HeightInches DECIMAL(10,2), @WeightLbs DECIMAL(10,2))
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @BMI DECIMAL(10,2);
    SET @BMI = (@WeightLbs / POWER(@HeightInches, 2)) * 703;
    RETURN @BMI;
END;
GO
-- Function #3: GetBMIClass
-- Function to determine the BMI classification
CREATE FUNCTION GetBMIClass(@BMI DECIMAL(10,2))
RETURNS NVARCHAR(20)
AS
BEGIN
    DECLARE @BMICategory NVARCHAR(50) = NULL;
    -- Determine BMI category
    IF @BMI < 18.5
        SET @BMICategory = 'Underweight';
    ELSE IF @BMI >= 18.5 AND @BMI < 25
        SET @BMICategory = 'Normal';
    ELSE IF @BMI >= 25 AND @BMI < 30
        SET @BMICategory = 'Overweight';
    ELSE IF @BMI >= 30
        SET @BMICategory = 'Obese';

    RETURN @BMICategory;
END;
GO



-- View #1: vwMemberInitialWeight (Member View)
-- This view allows members to check their initial weight.
CREATE VIEW vwMemberInitialWeight
AS
	SELECT fr.MemberID, fr.RecordDate, fr.WeightLbs
	FROM FitnessRecords fr
	INNER JOIN (
		SELECT MemberID, MIN(RecordDate) AS InitialRecordDate
		FROM FitnessRecords
		GROUP BY MemberID) AS initialfr
	ON fr.MemberID = initialfr.MemberID AND fr.RecordDate = initialfr.InitialRecordDate;
GO

-- View #2: vwMemberLatestWeight (Member View)
-- This view allows members to check their latest weight.
CREATE VIEW vwMemberLatestWeight
AS
	SELECT fr.MemberID, fr.RecordDate, fr.WeightLbs
	FROM FitnessRecords fr
	INNER JOIN (
		SELECT MemberID, MAX(RecordDate) AS InitialRecordDate
		FROM FitnessRecords
		GROUP BY MemberID) AS latestfr
	ON fr.MemberID = latestfr.MemberID AND fr.RecordDate = latestfr.InitialRecordDate;
GO

-- View #3: vwMemberInitialVsLatest (Member View) - (View #1+2)
-- This view allows members to see both their initial and latest weights.
CREATE VIEW vwMemberInitialVsLatest
AS
	SELECT i.MemberID,
		i.RecordDate AS InitialRecordDate, i.WeightLbs AS InitialWeightLbs,
		l.RecordDate AS LatestRecordDate, l.WeightLbs AS LatestWeightLbs
	FROM vwMemberInitialWeight i
	INNER JOIN vwMemberLatestWeight l
	ON i.MemberID = l.MemberID;
GO

-- View #4: vwMemberLatestStatus (Member View)
-- This view allows members to review their membership status and track their latest progress.
CREATE VIEW vwMemberLatestStatus
AS
	SELECT m.MemberID, m.FirstName, m.LastName, m.Gender, m.DateOfBirth,
		   m.MembershipStart, m.MembershipEnd,
		   vs.InitialRecordDate, vs.InitialWeightLbs,
		   vs.LatestRecordDate, vs.LatestWeightLbs
	FROM Members m
	LEFT JOIN vwMemberInitialVsLatest vs
	ON m.MemberID = vs.MemberID;
GO

-- View #5: vwTrainerNutritionTraining (Trainer View)
-- This view allows trainers to tailor workouts, monitor nutrition intake, and optimize training plans.
CREATE VIEW vwTrainerNutritionTraining
AS
    SELECT  m.MemberID, fr.RecordDate, 
            m.FirstName, m.LastName, m.DateOfBirth, m.Gender,
			dbo.GetCalorieMaintenance(fr.RecordDate, m.MemberID) AS CalorieMaintenance,
            fr.CalorieIntake, fr.WeightLbs, fr.HeightInches,
			dbo.GetBMIValue(fr.HeightInches, fr.WeightLbs) AS BMIValue,
			dbo.GetBMIClass(dbo.GetBMIValue(fr.HeightInches, fr.WeightLbs)) AS BMIClass,
			e.EquipmentName, e.EquipmentType, u.UsageStart, u.UsageEnd
    FROM Members m
    JOIN FitnessRecords fr
        ON m.MemberID = fr.MemberID
    JOIN EquipmentUsages u
        ON m.MemberID = u.MemberID AND u.UsageDate = fr.RecordDate
    JOIN Equipments e
        ON u.EquipmentID = e.EquipmentID;
GO

-- View #6: vwFinanceMembershipPayment (Finance View)
-- This view allows finance staff to monitor payment statuses, track membership durations.
CREATE VIEW vwFinanceMembershipPayment
AS
    SELECT m.MemberID, m.FirstName, m.LastName,
		m.MembershipStart, m.MembershipEnd, m.MembershipType,
        p.PaymentID, p.PaymentDate, p.Amount, p.PaymentMethod
    FROM Members m
    LEFT JOIN Payments p
	ON m.MemberID = p.MemberID;
GO



-- Stored Procedure #1: spAddMember
-- This stored procedure is responsible for adding a new member to the database.
CREATE PROCEDURE spAddMember 
	@FirstName			NVARCHAR(50),
	@LastName			NVARCHAR(50),
	@Gender				CHAR(1),
	@Email				NVARCHAR(50) = NULL,
	@Phone				NVARCHAR(20),
	@DateOfBirth		DATE,
	@TrainerMbrID		INT = NULL
AS
BEGIN
    BEGIN TRY
        -- Check if mandatory fields are provided
        IF (@FirstName IS NULL OR @LastName IS NULL OR @Gender IS NULL
            OR @Phone IS NULL OR @DateOfBirth IS NULL)
            THROW 50001, 'Mandatory fields cannot be null.', 1;
        -- Insert member into Members table
        INSERT INTO Members
            (FirstName, LastName, Gender, Email, Phone, DateOfBirth, TrainerMbrID)
        VALUES
            (@FirstName, @LastName, @Gender, @Email, @Phone, @DateOfBirth, @TrainerMbrID);
        -- Print success message
		DECLARE @tmpMemberID INT;
		SELECT @tmpMemberID = MAX(MemberID) FROM Members;
        PRINT 'Member successfully added. Your Member ID is: '  + CONVERT(varchar, @tmpMemberID);
    END TRY
    BEGIN CATCH
        PRINT 'Error occurred: ' + CONVERT(varchar, ERROR_MESSAGE());
    END CATCH
END
GO

-- Stored Procedure #2: spAddPaymentUpdateMembership
-- This stored procedure is responsible for adding a payment record then updating the membership info of the member.
CREATE PROCEDURE spAddPaymentUpdateMembership 
    @MemberID       INT,
    @PaymentAmount  MONEY,
    @PaymentMethod	NVARCHAR(50)
AS
BEGIN
    BEGIN TRY
        -- Check if mandatory fields are provided
        IF (@MemberID IS NULL OR @PaymentAmount IS NULL OR @PaymentMethod IS NULL)
            THROW 50001, 'MemberID and Payment Info cannot be null.', 1;
        -- Check if the member exists
        IF NOT EXISTS (
            SELECT 1 -- Arbitrary value to check existence
            FROM Members
            WHERE MemberID = @MemberID
            )
            THROW 50002, 'Member ID does not exist.', 1;

        -- Add payment record
        DECLARE @PaymentDate DATE = GETDATE(); -- Assume payment date is current date
        INSERT INTO Payments
            (PaymentDate, Amount, PaymentMethod, MemberID)
        VALUES
            (@PaymentDate, @PaymentAmount, @PaymentMethod, @MemberID);
        -- Calculate MembershipEnd date (one day before the end of the month following MembershipStart date)
        DECLARE @MembershipStart	DATE = @PaymentDate;
        DECLARE @MembershipEnd		DATE = DATEADD(DAY, -1, DATEADD(MONTH, 1, @PaymentDate));
        -- Check if membership is standard or premium
        DECLARE @MembershipType	NVARCHAR(10);
        IF @PaymentAmount = 50
            SET @MembershipType = 'Standard'
        IF @PaymentAmount = 100
            SET @MembershipType = 'Premium'
		-- Check if member is new or just renewing
		DECLARE @OldMembershipStart DATE;
		SELECT @OldMembershipStart = MembershipStart
		FROM Members
		WHERE MemberID = @MemberID;
		IF @OldMembershipStart IS NOT NULL
			SET @MembershipStart = @OldMembershipStart;
        -- Update MembershipStart, MembershipEnd, and MembershipType columns in Members table
        UPDATE Members
        SET MembershipStart = @MembershipStart,
            MembershipEnd   = @MembershipEnd,
            MembershipType  = @MembershipType
        WHERE MemberID      = @MemberID;
        -- Print success message
        PRINT 'Payment record added and membership details updated.';
    END TRY
    BEGIN CATCH
        PRINT 'Error occurred: ' + CONVERT(varchar, ERROR_MESSAGE());
    END CATCH
END
GO

-- Stored Procedure #3: spMemberCheckIn
-- This stored procedure is responsible for member check-ins while checking active membership period.
CREATE PROCEDURE spMemberCheckIn
    @MemberID INT
AS
BEGIN
    BEGIN TRY
        -- Check if mandatory fields are provided
        IF (@MemberID IS NULL)
            THROW 50001, 'MemberID cannot be null.', 1;
        -- Get it to the current date and time
        DECLARE @AttendanceDate DATE;
        DECLARE @CheckInTime    TIME;
        SET @AttendanceDate = CONVERT(DATE, GETDATE());
        SET @CheckInTime    = CONVERT(TIME, GETDATE());
        -- Check if the member exists
        IF NOT EXISTS (
            SELECT 1 -- Arbitrary value to check existence
            FROM Members
            WHERE MemberID = @MemberID
            )
            THROW 50002, 'Member ID does not exist.', 1;
        -- Check if the attendance date falls within the member's active membership period
		ELSE IF NOT EXISTS (
            SELECT 1 -- Arbitrary value to check existence
            FROM Members
            WHERE (MemberID = @MemberID) AND (@AttendanceDate BETWEEN MembershipStart AND MembershipEnd)
            )
            THROW 50002, 'Attendance date is not within the member''s active membership period.', 1;
        -- Insert attendance record into the Attendances table
        INSERT INTO Attendances
            (AttendanceDate, CheckInTime, MemberID)
        VALUES
            (@AttendanceDate, @CheckInTime, @MemberID);
        -- Print success message
        PRINT 'Member successfully checked in.';
    END TRY
    BEGIN CATCH
        PRINT 'Error occurred: ' + CONVERT(varchar, ERROR_MESSAGE());
    END CATCH
END
GO

-- Stored Procedure #4: spMemberCheckOut
-- This stored procedure is responsible for member check-outs while checking active membership period.
CREATE PROCEDURE spMemberCheckOut
    @MemberID INT
AS
BEGIN
    BEGIN TRY
        -- Check if mandatory fields are provided
        IF (@MemberID IS NULL)
            THROW 50001, 'MemberID cannot be null.', 1;
        -- Get it to the current date and time
        DECLARE @AttendanceDate	DATE;
        DECLARE @CheckOutTime   TIME;
        SET @AttendanceDate = CONVERT(DATE, GETDATE());
        SET @CheckOutTime   = CONVERT(TIME, GETDATE());
        -- Check if the member exists
        IF NOT EXISTS (
            SELECT 1 -- Arbitrary value to check existence
            FROM Members
            WHERE MemberID = @MemberID
            )
            THROW 50002, 'Member ID does not exist.', 1;
        -- Check if the attendance date falls within the member's active membership period
		ELSE IF NOT EXISTS (
            SELECT 1 -- Arbitrary value to check existence
            FROM Members
            WHERE MemberID = @MemberID AND @AttendanceDate BETWEEN MembershipStart AND MembershipEnd
            )
            THROW 50002, 'Attendance date is not within the member''s active membership period.', 1;
        -- Check if the latest checkin has a NULL checkout
		ELSE IF NOT EXISTS (
            SELECT TOP 1 AttendanceID
			FROM Attendances
			WHERE MemberID = @MemberID AND
				  AttendanceDate = @AttendanceDate AND
				  CheckOutTime IS NULL
			ORDER BY AttendanceDate, CheckInTime DESC
            )
            THROW 50002, 'Member already clocked out.', 1;
        -- Get the AttendanceID of the latest attendance done by the member
		DECLARE @AttendanceID INT;
		SELECT TOP 1 @AttendanceID = AttendanceID
		FROM Attendances
		WHERE MemberID = @MemberID AND
			  AttendanceDate = @AttendanceDate
		ORDER BY AttendanceDate, CheckInTime DESC;
		 -- Update attendance record into the Attendances table
        UPDATE Attendances
		SET CheckOutTime = @CheckOutTime
        WHERE AttendanceID = @AttendanceID;
        -- Print success message
        PRINT 'Member successfully checked out.';
    END TRY
    BEGIN CATCH
        PRINT 'Error occurred: ' + CONVERT(varchar, ERROR_MESSAGE());
    END CATCH
END
GO

-- Stored Procedure #5: spAddFitnessRecord
-- This stored procedure is responsible for adding a fitness record to the database.
CREATE PROCEDURE spAddFitnessRecord
	@MemberID			INT,
	@CalorieIntake		DECIMAL(10,2),
	@WeightLbs			DECIMAL(10,2),
	@HeightInches		DECIMAL(10,2)
AS
BEGIN
    BEGIN TRY
        -- Check if mandatory fields are provided
        IF (@MemberID IS NULL OR @CalorieIntake IS NULL OR @WeightLbs IS NULL OR @HeightInches IS NULL)
            THROW 50001, 'Mandatory fields cannot be null.', 1;
        -- Get it to the current date
        DECLARE @RecordDate DATE;
        SET @RecordDate = CONVERT(DATE, GETDATE());
        -- Check if the member exists
        IF NOT EXISTS (
            SELECT 1 -- Arbitrary value to check existence
            FROM Members
            WHERE MemberID = @MemberID
            )
            THROW 50002, 'Member ID does not exist.', 1;
        -- Check if the attendance date falls within the member's active membership period
		ELSE IF NOT EXISTS (
            SELECT 1 -- Arbitrary value to check existence
            FROM Members
            WHERE (MemberID = @MemberID) AND (@RecordDate BETWEEN MembershipStart AND MembershipEnd)
            )
            THROW 50002, 'Record date is not within the member''s active membership period.', 1;
        -- Insert fitness record data
        INSERT INTO FitnessRecords
            (RecordDate, MemberID, WeightLbs, HeightInches, CalorieIntake)
        VALUES
            (@RecordDate, @MemberID, @WeightLbs, @HeightInches, @CalorieIntake);
        -- Print success message
        PRINT 'Fitness record successfully added. BMI is: ' + CONVERT(varchar, dbo.GetBMIClass(dbo.GetBMIValue(@HeightInches, @WeightLbs)));
        PRINT 'Current BMI value is: ' + CONVERT(varchar, dbo.GetBMIValue(@HeightInches, @WeightLbs));
    END TRY
    BEGIN CATCH
        PRINT 'Error occurred: ' + CONVERT(varchar, ERROR_MESSAGE());
    END CATCH
END
GO

-- Stored Procedure #6: spAddEquipmentUsageStart
-- This stored procedure is responsible for starting an equipment usage record to the database.
CREATE PROCEDURE spAddEquipmentUsageStart
	@MemberID		INT,
	@EquipmentID	INT
AS
BEGIN
    BEGIN TRY
        -- Check if mandatory fields are provided
        IF (@MemberID IS NULL OR @EquipmentID IS NULL)
            THROW 50001, 'Mandatory fields cannot be null.', 1;
        -- Get it to the current date and time
        DECLARE @UsageDate		DATE;
        DECLARE @UsageStart     TIME;
        SET @UsageDate	= CONVERT(DATE, GETDATE());
        SET @UsageStart = CONVERT(TIME, GETDATE());
        -- Check if the member exists
        IF NOT EXISTS (
            SELECT 1 -- Arbitrary value to check existence
            FROM Members
            WHERE MemberID = @MemberID
            )
            THROW 50002, 'Member ID does not exist.', 1;
        -- Check if the equipment exists
        ELSE IF NOT EXISTS (
            SELECT 1 -- Arbitrary value to check existence
            FROM Equipments
            WHERE EquipmentID = @EquipmentID
            )
            THROW 50002, 'Equipment ID does not exist.', 1;
        -- Check if the usage date falls within the member's active membership period
        ELSE IF NOT EXISTS (
            SELECT 1 -- Arbitrary value to check existence
            FROM Members
            WHERE (MemberID = @MemberID) AND (@UsageDate BETWEEN MembershipStart AND MembershipEnd)
            )
            THROW 50002, 'Usage date is not within the member''s active membership period.', 1;
        -- Insert fitness record data
        INSERT INTO EquipmentUsages
            (MemberID, UsageDate, UsageStart, UsageEnd, EquipmentID)
        VALUES
            (@MemberID, @UsageDate, @UsageStart, NULL, @EquipmentID);
        -- Print success message
        PRINT 'Equipment usage start time successfully added.';
    END TRY
    BEGIN CATCH
        PRINT 'Error occurred: ' + CONVERT(varchar, ERROR_MESSAGE());
    END CATCH
END
GO

-- Stored Procedure #7: spAddEquipmentUsageEnd
-- This stored procedure is responsible for ending an equipment usage record to the database.
CREATE PROCEDURE spAddEquipmentUsageEnd
	@MemberID		INT,
	@EquipmentID	INT
AS
BEGIN
    BEGIN TRY
        -- Check if mandatory fields are provided
        IF (@MemberID IS NULL OR @EquipmentID IS NULL)
            THROW 50001, 'Mandatory fields cannot be null.', 1;
        -- Get it to the current date and time
        DECLARE @UsageDate	DATE;
        DECLARE @UsageEnd   TIME;
        SET @UsageDate = CONVERT(DATE, GETDATE());
        SET @UsageEnd  = CONVERT(TIME, GETDATE());
        -- Check if the member exists
        IF NOT EXISTS (
            SELECT 1 -- Arbitrary value to check existence
            FROM Members
            WHERE MemberID = @MemberID
            )
            THROW 50002, 'Member ID does not exist.', 1;
        -- Check if the attendance date falls within the member's active membership period
		ELSE IF NOT EXISTS (
            SELECT 1 -- Arbitrary value to check existence
            FROM Members
            WHERE MemberID = @MemberID AND @UsageDate BETWEEN MembershipStart AND MembershipEnd
            )
            THROW 50002, 'Usage date is not within the member''s active membership period.', 1;
        -- Check if the equipment exists
        ELSE IF NOT EXISTS (
            SELECT 1 -- Arbitrary value to check existence
            FROM Equipments
            WHERE EquipmentID = @EquipmentID
            )
            THROW 50002, 'Equipment ID does not exist.', 1;
        -- Check if the equipment used by member
        ELSE IF NOT EXISTS (
            SELECT 1 -- Arbitrary value to check existence
            FROM EquipmentUsages
            WHERE MemberID = @MemberID AND EquipmentID = @EquipmentID
            )
            THROW 50002, 'Equipment ID not in use.', 1;
        -- Check if the latest checkin has a NULL checkout
		ELSE IF NOT EXISTS (
            SELECT TOP 1 *
			FROM EquipmentUsages
			WHERE MemberID = @MemberID AND
				EquipmentID = @EquipmentID AND
				UsageDate = @UsageDate AND
				UsageEnd IS NULL
			ORDER BY UsageDate, UsageStart DESC
            )
            THROW 50002, 'End time already logged.', 1;
		 -- Update attendance record into the Attendances table
        UPDATE EquipmentUsages
		SET UsageEnd = @UsageEnd
        WHERE MemberID = @MemberID AND
				EquipmentID = @EquipmentID AND
				UsageDate = @UsageDate AND
				UsageEnd IS NULL;
        -- Print success message
        PRINT 'Equipment usage end time successfully updated.';
    END TRY
    BEGIN CATCH
        PRINT 'Error occurred: ' + CONVERT(varchar, ERROR_MESSAGE());
    END CATCH
END
GO



-- Trigger #1: tgDeleteAttendanceOutsideGymHours
-- This trigger ensures records outside of gym hours are deleted from the Attendances table.
CREATE TRIGGER tgDeleteAttendanceOutsideGymHours
	ON Attendances
	AFTER INSERT
AS
BEGIN
    -- Define the fixed open and close times for the gym
    DECLARE @GymOpenTime	TIME = '04:30:00';
    DECLARE @GymCloseTime	TIME = '23:30:00';
    -- Define the last check-in as 1 hour before the gym's closing time
    DECLARE @GymLastCheckIn TIME = DATEADD(HOUR, -1, @GymCloseTime);
    -- Check if the inserted attendance record falls OUTSIDE of gym hours
    IF EXISTS (
        SELECT 1 -- Arbitrary value to check existence
        FROM Inserted AS i
        WHERE i.CheckInTime < @GymOpenTime OR i.CheckInTime > @GymLastCheckIn
    )
	BEGIN
		THROW 50113, 'TG1: Check-in is outside gym hours.', 1;
		ROLLBACK TRAN;
	END
END
GO

-- Trigger #2: tgPreventCheckinsWithoutCheckout
-- This trigger ensures that members cannot check in multiple times without clocking out first.
CREATE TRIGGER tgPreventCheckinsWithoutCheckout
    ON Attendances
    INSTEAD OF INSERT
AS
BEGIN
    -- Check if any inserted records violate the rule
    IF EXISTS (
        SELECT 1 -- Arbitrary value to check existence
        FROM Inserted AS i
        JOIN Attendances AS a
            ON i.MemberID = a.MemberID
        WHERE (i.AttendanceDate = a.AttendanceDate
            AND i.CheckInTime IS NOT NULL
            AND a.CheckOutTime IS NULL) -- Member hasn't clocked out yet
    )
        THROW 50114, 'TG2: Please check-out first.', 1;
    ELSE
    BEGIN
        -- Perform the actual insert operation
        INSERT INTO Attendances
            (AttendanceDate, CheckInTime, MemberID)
            (SELECT i.AttendanceDate, i.CheckInTime, i.MemberID
                FROM Inserted AS i);
    END
END
GO

-- Trigger #3: tgPreventIncorrectPayment
CREATE TRIGGER tgPreventIncorrectPayment
    ON Payments
    INSTEAD OF INSERT
AS
BEGIN
	-- Check existence of TrainerID in Member Record
	DECLARE @InsertedMbrID INT;
	DECLARE @Amount MONEY;
	DECLARE @TrainerMbrID INT;

	SELECT	@InsertedMbrID = MemberID,
			@Amount = Amount
	FROM Inserted;

	SELECT @TrainerMbrID = TrainerMbrID
	FROM Members
	WHERE MemberID = @InsertedMbrID;

    -- Check if any inserted records violate the rule
	IF @Amount NOT IN (50, 100)
		THROW 50114, 'TG3: Must be $50 or $100.', 1;
    ELSE IF (@TrainerMbrID IS NULL AND @Amount <> 50)
		THROW 50114, 'TG3: Amount should be 50.', 1;
    ELSE IF (@TrainerMbrID IS NOT NULL	AND @Amount <> 100)
		THROW 50114, 'TG3: Amount should be 100.', 1;
	ELSE
		BEGIN
			-- Perform the actual insert operation
			INSERT INTO Payments
				(PaymentDate, Amount, PaymentMethod, MemberID)
				(SELECT i.PaymentDate, i.Amount, i.PaymentMethod, i.MemberID
				 FROM Inserted AS i);
		END
END
GO