USE GradeManager;
GO

PRINT N'错误写法（聚合函数不能直接出现在 WHERE 中）';
SELECT Eno, Basepay, Service
FROM Salary
WHERE Basepay < AVG(Basepay);
GO
