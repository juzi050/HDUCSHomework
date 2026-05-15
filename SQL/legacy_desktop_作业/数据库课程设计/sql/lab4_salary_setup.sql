USE GradeManager;
GO

IF OBJECT_ID(N'dbo.Salary', N'U') IS NOT NULL
    DROP TABLE dbo.Salary;
GO

CREATE TABLE Salary
(
    Eno CHAR(4) NOT NULL PRIMARY KEY,
    Basepay INT NOT NULL,
    Service INT NULL
);
GO

INSERT INTO Salary (Eno, Basepay, Service) VALUES
('1001', 5000, 10),
('1002', 4500, 8),
('1003', 6200, 12),
('1004', 4300, 6);
GO

SELECT *
FROM Salary
ORDER BY Eno;
GO
