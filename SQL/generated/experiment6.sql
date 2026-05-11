USE GradeManager;
GO

PRINT N'【实验六】SQL 的存储操作';

BEGIN TRAN;

SELECT N'15(1) 将20311班全体学生的成绩置0值（事务内演示）' AS Item;
UPDATE g
SET Gmark = 0
FROM Grade AS g
JOIN Student AS s ON s.Sno = g.Sno
WHERE s.Clno = '20311';
SELECT @@ROWCOUNT AS UpdatedRows;
SELECT s.Clno, g.Sno, g.Cno, g.Gmark
FROM Grade AS g
JOIN Student AS s ON s.Sno = g.Sno
WHERE s.Clno = '20311'
ORDER BY g.Sno, g.Cno;

ROLLBACK;

BEGIN TRAN;

SELECT N'15(2) 删除2021级软件工程学生的选课记录（事务内演示）' AS Item;
DELETE g
FROM Grade AS g
WHERE g.Sno IN (
    SELECT s.Sno
    FROM Student AS s
    JOIN Class AS c ON s.Clno = c.Clno
    WHERE c.Inyear = '2021' AND c.Speciality LIKE N'%软件%'
);
SELECT @@ROWCOUNT AS DeletedRows;

ROLLBACK;

BEGIN TRAN;

SELECT N'15(3) 学生李勇退学，删除与他有关的记录（事务内演示）' AS Item;
DELETE FROM Grade
WHERE Sno = (SELECT Sno FROM Student WHERE Sname = N'李勇');
SELECT @@ROWCOUNT AS DeletedGradeRows;
DELETE FROM Student
WHERE Sname = N'李勇';
SELECT @@ROWCOUNT AS DeletedStudentRows;

ROLLBACK;

SELECT N'15(4) 对每个班求学生平均年龄，并把结果存入数据库' AS Item;
DROP TABLE IF EXISTS ClassAvgAge;
SELECT c.Clno, c.Speciality, c.Inyear,
       CAST(AVG(CAST(dbo.AgeOf(s.Sbirth) AS DECIMAL(6,2))) AS DECIMAL(6,2)) AS AvgAge
INTO ClassAvgAge
FROM Class AS c
JOIN Student AS s ON c.Clno = s.Clno
GROUP BY c.Clno, c.Speciality, c.Inyear;
SELECT * FROM ClassAvgAge ORDER BY Clno;

SELECT N'验证工程师基本工资增加100的UPDATE语句（事务内演示）' AS Item;
BEGIN TRAN;
SELECT N'更新前' AS Stage, e.Eno, e.Ename, e.Title, s.Basepay
FROM Employee AS e
JOIN Salary AS s ON e.Eno = s.Eno
WHERE e.Title = N'工程师'
ORDER BY e.Eno;

UPDATE Salary
SET Basepay = Basepay + 100
WHERE Eno IN (
    SELECT Eno
    FROM Employee
    WHERE Title = N'工程师'
);
SELECT @@ROWCOUNT AS UpdatedEngineerRows;

SELECT N'更新后（事务内）' AS Stage, e.Eno, e.Ename, e.Title, s.Basepay
FROM Employee AS e
JOIN Salary AS s ON e.Eno = s.Eno
WHERE e.Title = N'工程师'
ORDER BY e.Eno;
ROLLBACK;
GO
