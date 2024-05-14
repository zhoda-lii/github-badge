-- Use the GymProgressTracker database
USE GymProgressTracker
GO

-- IMPORTANT:
-- Do not run! This obsolete file is just to show the evolution of the data. 
-- This script is initially used in inserting and testing few random data.
-- A new script is generated which contains all working data from 19th April 2024.
-- Please run the new script 02_2_insert_complete_from_script.sql instead.

-- Insert value to Members table
INSERT INTO Members (FirstName, LastName, Gender, Email, Phone, DateOfBirth, MembershipStart, MembershipEnd, MembershipType, TrainerMbrID)
VALUES 
    ('John', 'Doe', 'M', 'john.doe@example.com', '1234567890', '1990-05-15', '2024-03-02', '2024-04-01', 'Premium', NULL),
    ('Jane', 'Smith', 'F', 'jane.smith@example.com', '9876543210', '1985-08-20', '2024-04-03', '2024-05-02', 'Premium', NULL),
    ('Rahul', 'Kumar', 'M', 'rahul.kumar@example.com', '5551234567', '1995-11-10', '2024-04-03', '2024-05-02', 'Standard', 1),
    ('Emily', 'Davis', 'F', 'emily.davis@example.com', '4449876543', '1988-04-25', '2024-04-04', '2024-05-03', 'Standard', 2),
    ('Juan', 'Dela Cruz', 'M', 'juan.delacruz@example.com', '6667890123', '1992-09-30', '2024-04-06', '2024-05-05', 'Standard', 1);
GO
-- Insert value to Payments table
INSERT INTO Payments (PaymentDate, Amount, PaymentMethod, MemberID)
VALUES 
    ('2024-04-03', 100.00, 'Credit Card', 2),
    ('2024-04-04', 50.00, 'Cash', 4),
    ('2024-04-05', 50.00, 'Debit Card', 5),
    ('2024-04-07', 50.00, 'Credit Card', 6),
    ('2024-04-09', 100.00, 'Cash', 10),
    ('2024-04-10', 100.00, 'Cash', 12),
    ('2024-04-10', 50.00, 'Cash', 1);
GO
-- Insert value to Attendances table
INSERT INTO Attendances (AttendanceDate, CheckInTime, CheckOutTime, MemberID)
VALUES 
    ('2024-04-06', '07:30:00', NULL, 1),
    ('2024-04-06', '08:15:00', '09:30:00', 2),
    ('2024-04-06', '08:30:00', NULL, 3),
    ('2024-04-06', '08:45:00', NULL, 4),
    ('2024-04-06', '09:00:00', NULL, 5);
GO
-- Insert value to Equipments table
INSERT INTO Equipments (EquipmentName, EquipmentType)
VALUES 
    ('Dumbbells', 'Strength'),
    ('Barbell', 'Strength'),
    ('Treadmill', 'Cardio'),
    ('Exercise Bike', 'Cardio'),
    ('Elliptical Machine', 'Cardio')
GO
-- Insert value to EquipmentUsages table
INSERT INTO EquipmentUsages (MemberID, UsageDate, UsageStart, UsageEnd, EquipmentID)
VALUES 
    (1, '2024-04-05', '08:00:00', '08:30:00', 1),
    (2, '2024-04-05', '08:30:00', '09:15:00', 2),
    (3, '2024-04-05', '09:00:00', '09:30:00', 3),
    (4, '2024-04-05', '09:15:00', '09:45:00', 4),
    (5, '2024-04-05', '09:30:00', '10:15:00', 5),
    (1, '2024-04-06', '08:00:00', '08:30:00', 1),
    (2, '2024-04-06', '08:30:00', '09:15:00', 2),
    (3, '2024-04-06', '09:00:00', '09:30:00', 3),
    (4, '2024-04-06', '09:15:00', '09:45:00', 4),
    (5, '2024-04-06', '09:30:00', '10:15:00', 5);
GO
-- Insert value to FitnessRecords table
INSERT INTO FitnessRecords (RecordDate, MemberID, CalorieIntake, WeightLbs, HeightInches)
VALUES 
    ('2024-04-05', 1, 1500, 170.5, 70),
    ('2024-04-05', 2, 3000, 170.5, 70),
    ('2024-04-05', 3, 3000, 150.3, 68),
    ('2024-04-05', 4, 4000, 150.3, 68),
    ('2024-04-05', 5, 1800, 120.2, 65),
    ('2024-04-06', 1, 1500, 168.5, 70),
    ('2024-04-06', 2, 3000, 169.5, 70),
    ('2024-04-06', 3, 1500, 120.2, 68),
    ('2024-04-06', 4, 3000, 150.3, 68),
    ('2024-04-06', 5, 1800, 120.2, 65);
GO
