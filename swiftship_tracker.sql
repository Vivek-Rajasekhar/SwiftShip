/* --- DB RESET --- */
DROP TABLE IF EXISTS DeliveryLogs;
DROP TABLE IF EXISTS Shipments;
DROP TABLE IF EXISTS Partners;

/* --- SCHEMA DEFINITION --- */
CREATE TABLE Partners (
    PartnerID INT AUTO_INCREMENT PRIMARY KEY,
    PartnerName VARCHAR(100) NOT NULL
);

CREATE TABLE Shipments (
    ShipmentID INT AUTO_INCREMENT PRIMARY KEY,
    PartnerID INT NOT NULL,
    DestinationCity VARCHAR(100) NOT NULL,
    PromisedDate DATE NOT NULL,
    ActualDeliveryDate DATE NULL,
    FOREIGN KEY (PartnerID) REFERENCES Partners(PartnerID)
);

CREATE TABLE DeliveryLogs (
    LogID INT AUTO_INCREMENT PRIMARY KEY,
    ShipmentID INT NOT NULL,
    Status VARCHAR(50) NOT NULL,
    FOREIGN KEY (ShipmentID) REFERENCES Shipments(ShipmentID)
);

/* --- SAMPLE DATA SEEDING --- */
INSERT INTO Partners (PartnerName) VALUES
('DHL'),
('Porter'),
('UPS'),
('Fedex');

INSERT INTO Shipments (PartnerID, DestinationCity, PromisedDate, ActualDeliveryDate) VALUES
(1, 'New York', CURRENT_DATE - INTERVAL 28 DAY, CURRENT_DATE - INTERVAL 26 DAY),
(1, 'Chicago', CURRENT_DATE - INTERVAL 24 DAY, CURRENT_DATE - INTERVAL 22 DAY),
(2, 'Los Angeles', CURRENT_DATE - INTERVAL 20 DAY, CURRENT_DATE - INTERVAL 17 DAY),
(2, 'Houston', CURRENT_DATE - INTERVAL 18 DAY, CURRENT_DATE - INTERVAL 18 DAY),
(3, 'Phoenix', CURRENT_DATE - INTERVAL 16 DAY, CURRENT_DATE - INTERVAL 13 DAY),
(3, 'New York', CURRENT_DATE - INTERVAL 14 DAY, CURRENT_DATE - INTERVAL 12 DAY),
(4, 'Seattle', CURRENT_DATE - INTERVAL 12 DAY, CURRENT_DATE - INTERVAL 10 DAY),
(4, 'Miami', CURRENT_DATE - INTERVAL 10 DAY, CURRENT_DATE - INTERVAL 10 DAY),
(1, 'New York', CURRENT_DATE - INTERVAL 8 DAY, CURRENT_DATE - INTERVAL 5 DAY),
(2, 'Dallas', CURRENT_DATE - INTERVAL 6 DAY, CURRENT_DATE - INTERVAL 4 DAY),
(3, 'Los Angeles', CURRENT_DATE - INTERVAL 4 DAY, NULL),
(4, 'New York', CURRENT_DATE - INTERVAL 2 DAY, NULL);

INSERT INTO DeliveryLogs (ShipmentID, Status) VALUES
(1, 'Successful'),
(2, 'Successful'),
(3, 'Returned'),
(4, 'Successful'),
(5, 'Returned'),
(6, 'Successful'),
(7, 'Successful'),
(8, 'Returned'),
(9, 'Successful'),
(10, 'Returned'),
(11, 'In Transit'),
(12, 'Pending');

/* --- ANALYTICAL QUERIES --- */
/* Query 1: Delayed Shipment Tracker */
SELECT
    s.ShipmentID,
    p.PartnerName,
    s.DestinationCity,
    s.PromisedDate,
    s.ActualDeliveryDate
FROM Shipments s
JOIN Partners p ON s.PartnerID = p.PartnerID
WHERE s.ActualDeliveryDate > s.PromisedDate
ORDER BY s.ShipmentID;

/* Query 2: Partner Performance Scorecard */
SELECT
    p.PartnerName,
    COUNT(dl.LogID) AS TotalDeliveries,
    COALESCE(SUM(CASE WHEN dl.Status = 'Successful' THEN 1 ELSE 0 END), 0) AS SuccessfulCount,
    COALESCE(SUM(CASE WHEN dl.Status = 'Returned' THEN 1 ELSE 0 END), 0) AS ReturnedCount
FROM Partners p
LEFT JOIN Shipments s ON p.PartnerID = s.PartnerID
LEFT JOIN DeliveryLogs dl ON s.ShipmentID = dl.ShipmentID
GROUP BY p.PartnerName
ORDER BY p.PartnerName;

/* Query 3: Warehouse Route Planner (Zone Filter) */
SELECT
    s.DestinationCity,
    COUNT(*) AS ShipmentCount
FROM Shipments s
WHERE s.PromisedDate >= CURRENT_DATE - INTERVAL 30 DAY
GROUP BY s.DestinationCity
ORDER BY ShipmentCount DESC
LIMIT 1;
