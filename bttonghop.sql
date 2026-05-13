CREATE DATABASE IF NOT EXISTS RikkeiClinicDB;

USE RikkeiClinicDB;

DROP TABLE IF EXISTS Medicines;
DROP TABLE IF EXISTS Patient_Invoices;

CREATE TABLE Medicines (
    medicine_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price DECIMAL(18,2) NOT NULL,
    stock INT NOT NULL DEFAULT 0
);

CREATE TABLE Patient_Invoices (
    patient_id INT PRIMARY KEY,
    total_due DECIMAL(18,2) NOT NULL DEFAULT 0
);

INSERT INTO Medicines VALUES
(1, 'Amoxicillin 500mg', 15000, 100),
(2, 'Panadol Extra', 5000, 5);

INSERT INTO Patient_Invoices VALUES
(1, 1500000),
(2, 0),
(3, 0);

DROP PROCEDURE IF EXISTS ProcessPrescription;

DELIMITER //

CREATE PROCEDURE ProcessPrescription(
    IN p_patient_id INT,
    IN p_medicine_id INT,
    IN p_quantity INT,
    IN p_discount_code VARCHAR(50),
    OUT o_message VARCHAR(255)
)
BEGIN

    DECLARE v_price DECIMAL(18,2);
    DECLARE v_stock INT;
    DECLARE v_subtotal DECIMAL(18,2);
    DECLARE v_final_amount DECIMAL(18,2);

    SELECT price, stock
    INTO v_price, v_stock
    FROM Medicines
    WHERE medicine_id = p_medicine_id;

    IF v_price IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Medicine does not exist.';
    END IF;

    IF p_quantity <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Quantity must be greater than 0.';
    END IF;

    IF v_stock < p_quantity THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Thất bại: Kho không đủ thuốc';
    END IF;

    SET v_subtotal = p_quantity * v_price;

    IF p_discount_code = 'NV-RIKKEI' THEN
        SET v_final_amount = v_subtotal * 0.5;
    ELSE
        SET v_final_amount = v_subtotal;
    END IF;

    UPDATE Medicines
    SET stock = stock - p_quantity
    WHERE medicine_id = p_medicine_id;

    UPDATE Patient_Invoices
    SET total_due = total_due + v_final_amount
    WHERE patient_id = p_patient_id;

    SET o_message = 'Thành công: Đã xử lý đơn thuốc';

END //

DELIMITER ;

CALL ProcessPrescription(
    1,
    1,
    2,
    NULL,
    @msg
);

SELECT @msg AS message;

SELECT * FROM Medicines;
SELECT * FROM Patient_Invoices;

CALL ProcessPrescription(
    2,
    1,
    4,
    'NV-RIKKEI',
    @msg
);

SELECT @msg AS message;

SELECT * FROM Medicines;
SELECT * FROM Patient_Invoices;

CALL ProcessPrescription(
    3,
    2,
    10,
    NULL,
    @msg
);

SELECT @msg AS message;