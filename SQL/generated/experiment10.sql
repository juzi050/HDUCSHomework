USE GradeManager;
GO

PRINT N'【实验十】创建存储过程和用户自定义函数';
GO

CREATE OR ALTER PROCEDURE dbo.usp_QueryStudentGrades
    @Sno CHAR(7)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT s.Sno, s.Sname, c.Cno, c.Cname, g.Gmark
    FROM dbo.Student AS s
    JOIN dbo.Grade AS g ON s.Sno = g.Sno
    JOIN dbo.Course AS c ON g.Cno = c.Cno
    WHERE s.Sno = @Sno
    ORDER BY c.Cno;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_ClassHasStudents
    @Clno CHAR(5),
    @ExistsFlag INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM dbo.Student WHERE Clno = @Clno)
        SET @ExistsFlag = 1;
    ELSE
        SET @ExistsFlag = 0;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_QueryStudentNameAndMajor
    @Sno CHAR(7),
    @Sname VARCHAR(20) OUTPUT,
    @Speciality VARCHAR(20) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT @Sname = s.Sname,
           @Speciality = c.Speciality
    FROM dbo.Student AS s
    JOIN dbo.Class AS c ON s.Clno = c.Clno
    WHERE s.Sno = @Sno;
END;
GO

CREATE OR ALTER FUNCTION dbo.fn_StudentGrades(@Sno CHAR(7))
RETURNS TABLE
AS
RETURN
(
    SELECT s.Sno, s.Sname, c.Cno, c.Cname, g.Gmark
    FROM dbo.Student AS s
    JOIN dbo.Grade AS g ON s.Sno = g.Sno
    JOIN dbo.Course AS c ON g.Cno = c.Cno
    WHERE s.Sno = @Sno
);
GO

CREATE OR ALTER FUNCTION dbo.fn_ClassHasStudents(@Clno CHAR(5))
RETURNS INT
AS
BEGIN
    DECLARE @ExistsFlag INT;
    IF EXISTS (SELECT 1 FROM dbo.Student WHERE Clno = @Clno)
        SET @ExistsFlag = 1;
    ELSE
        SET @ExistsFlag = 0;
    RETURN @ExistsFlag;
END;
GO

CREATE OR ALTER FUNCTION dbo.fn_StudentNameAndMajor(@Sno CHAR(7))
RETURNS TABLE
AS
RETURN
(
    SELECT s.Sno, s.Sname, c.Speciality
    FROM dbo.Student AS s
    JOIN dbo.Class AS c ON s.Clno = c.Clno
    WHERE s.Sno = @Sno
);
GO

SELECT N'习题5第17题：按学号查询该学生所有选修课成绩的存储过程' AS Item;
EXEC dbo.usp_QueryStudentGrades @Sno = '2020103';

SELECT N'习题5第18题：按班级号判断该班是否有学生的存储过程' AS Item;
DECLARE @HasStudent INT;
EXEC dbo.usp_ClassHasStudents @Clno = '20312', @ExistsFlag = @HasStudent OUTPUT;
SELECT '20312' AS Clno, @HasStudent AS HasStudent;
EXEC dbo.usp_ClassHasStudents @Clno = '99999', @ExistsFlag = @HasStudent OUTPUT;
SELECT '99999' AS Clno, @HasStudent AS HasStudent;

SELECT N'习题5第19题：按学号输出姓名和专业的存储过程' AS Item;
DECLARE @Name VARCHAR(20), @Major VARCHAR(20);
EXEC dbo.usp_QueryStudentNameAndMajor
    @Sno = '2020103',
    @Sname = @Name OUTPUT,
    @Speciality = @Major OUTPUT;
SELECT '2020103' AS Sno, @Name AS Sname, @Major AS Speciality;

SELECT N'习题5第20题：将第17-19题改写为用户自定义函数' AS Item;
SELECT * FROM dbo.fn_StudentGrades('2020103') ORDER BY Cno;
SELECT '20312' AS Clno, dbo.fn_ClassHasStudents('20312') AS HasStudent,
       '99999' AS EmptyClno, dbo.fn_ClassHasStudents('99999') AS EmptyClassHasStudent;
SELECT * FROM dbo.fn_StudentNameAndMajor('2020103');
GO
