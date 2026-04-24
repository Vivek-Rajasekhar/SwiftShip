# SwiftShip Tracker SQL

A single-file SQL analytics project that models logistics deliveries and surfaces shipment delays, partner performance, and top destination demand.

## 1) Project Title & Catchy Description

- **Project title:** `SwiftShip Tracker SQL`
- **The Why:** Helps identify delayed shipments and evaluate delivery partner outcomes from operational shipment data.
- **The What:** A SQL script project (database schema + seed data + analytical queries), not a web app or library.
- **Visuals:** [Watch the Demo Video](https://drive.google.com/file/d/1E3w5iO5sxr3XvsXke9MjqDdzjytl3iqd/view?usp=sharing)

## 2) Key Features

- Idempotent setup using `DROP TABLE IF EXISTS` in dependency-safe order.
- Relational schema with foreign keys across `Partners`, `Shipments`, and `DeliveryLogs`.
- Realistic seeded states including delivered, returned, in-transit, and pending shipments.
- Delay detection query using promised vs actual delivery date comparison.
- Partner scorecard query with `LEFT JOIN` + conditional aggregation + `COALESCE` for zero-safe reporting.
- Route planning query to find the top destination city in the last 30 days.

## 3) Tech Stack

- **Language:** SQL
- **Database flavor implied by syntax:** MySQL-compatible SQL (uses `AUTO_INCREMENT`, `CURRENT_DATE - INTERVAL 30 DAY`, `LIMIT`).
- **Infrastructure/frameworks:** Not defined in code (no containers, cloud services, or application framework present).

## 4) Getting Started (The Most Critical Section)

### Prerequisites

- A modern browser.
- An online MySQL playground account/session (recommended: [DB Fiddle](https://www.db-fiddle.com/)).

No API keys or external services are required by this code.

### Installation

1. Open [DB Fiddle](https://www.db-fiddle.com/).
2. Select **MySQL** as the database engine.
3. Paste the **Schema + Seed SQL block** (from `swiftship_tracker.sql`) into the left/schema panel and run it.
4. Paste one analytical query at a time into the right/query panel and execute.

### Environment Configuration

This codebase does not define a `.env` file or environment variables.

## 5) Usage Examples

### Quick Start

1. Open [DB Fiddle](https://www.db-fiddle.com/) and choose MySQL.
2. Run this in the **Schema SQL** area:

```sql
/* IDEMPOTENCY + DDL + DML */
DROP TABLE IF EXISTS DeliveryLogs;
DROP TABLE IF EXISTS Shipments;
DROP TABLE IF EXISTS Partners;

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
```

3. Run each of these in the **Query SQL** area:

```sql
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
```

```sql
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
```

```sql
/* Query 3: Warehouse Route Planner (Zone Filter) */
SELECT
    s.DestinationCity,
    COUNT(*) AS ShipmentCount
FROM Shipments s
WHERE s.PromisedDate >= CURRENT_DATE - INTERVAL 30 DAY
GROUP BY s.DestinationCity
ORDER BY ShipmentCount DESC
LIMIT 1;
```

## 6) Architecture & Data Flow

1. **Schema reset:** Drops tables in reverse dependency order.
2. **Schema creation:** Builds parent-to-child model:
   - `Partners` -> `Shipments` -> `DeliveryLogs`
3. **Data seeding:** Inserts partner master data, shipment records, then status logs.
4. **Analytics execution:**
   - Query 1 joins shipments with partners to flag delays.
   - Query 2 reports successful vs returned counts per partner while retaining partners with zero shipment activity.
   - Query 3 ranks destination demand in the recent 30-day window.

## 7) API Documentation / Reference

This project exposes SQL queries, not HTTP endpoints.

- **Core entities (tables):**
  - `Partners(PartnerID, PartnerName)`
  - `Shipments(ShipmentID, PartnerID, DestinationCity, PromisedDate, ActualDeliveryDate)`
  - `DeliveryLogs(LogID, ShipmentID, Status)`
- **Analytical outputs:**
  - delayed shipment rows with partner and date details
  - per-partner delivery counts (`TotalDeliveries`, `SuccessfulCount`, `ReturnedCount`)
  - top `DestinationCity` by shipment count in the last 30 days

No separate Swagger/ReadTheDocs site is defined in the current codebase.

## 8) Development & Testing

- **Running tests:** No automated test suite is defined in this repository segment.
- **Linting/format checks:** No SQL lint configuration is defined in this directory.
- **Contribution workflow:** No branching strategy is documented in code files here.

Practical verification method from existing code:
- Re-run `swiftship_tracker.sql` to confirm idempotency and successful table recreation.
- Inspect analytics query result sets for expected business behavior.

## 9) Roadmap & Known Issues

### Roadmap (inferred from current implementation boundaries)

- Add explicit indexes for larger datasets.
- Expand log lifecycle statuses and timestamped event history.
- Add parameterized/report-ready query variants.

### Known Issues

- Seed data is static and illustrative only.
- Query outputs are console result sets; no packaged reporting/export layer exists.
- SQL is MySQL-oriented and may need syntax adjustments for other engines.
