USE GradeManager;
GO

PRINT N'正确写法（把平均值放到子查询中）';
SELECT Eno, Basepay, Service
FROM Salary
WHERE Basepay < (
    SELECT AVG(Basepay)
    FROM Salary
)
ORDER BY Eno;
GO
