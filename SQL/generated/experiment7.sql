USE GradeManager;
GO

PRINT N'【实验七】视图的建立及操作';
GO

CREATE OR ALTER VIEW Stu_20312_1
AS
SELECT s.Sno, s.Sname, s.Ssex, s.Sbirth, s.Clno, g.Cno, g.Gmark
FROM Student AS s
JOIN Grade AS g ON s.Sno = g.Sno
WHERE s.Clno = '20312' AND g.Cno = '1';
GO

CREATE OR ALTER VIEW Stu_20312_2
AS
SELECT s.Sno, s.Sname, s.Ssex, s.Sbirth, s.Clno, g.Cno, g.Gmark
FROM Student AS s
JOIN Grade AS g ON s.Sno = g.Sno
WHERE s.Clno = '20312' AND g.Cno = '1' AND g.Gmark < 60;
GO

CREATE OR ALTER VIEW Stu_age
AS
SELECT Sno, Sname, dbo.AgeOf(Sbirth) AS Age
FROM Student;
GO

SELECT N'16(1) 20312班选修1号课程的学生视图 Stu_20312_1' AS Item;
SELECT Sno, Sname, Cno, Gmark FROM Stu_20312_1 ORDER BY Sno;

SELECT N'16(2) 20312班选修1号课程且不及格的学生视图 Stu_20312_2' AS Item;
SELECT Sno, Sname, Cno, Gmark FROM Stu_20312_2 ORDER BY Sno;

SELECT N'16(3) 学生学号、姓名和年龄视图 Stu_age' AS Item;
SELECT * FROM Stu_age ORDER BY Sno;

SELECT N'16(4) 查询2000年以后出生的学生姓名' AS Item;
SELECT Sname
FROM Student
WHERE Sbirth >= '2000-01-01'
ORDER BY Sno;

SELECT N'16(5) 查询20312班选修1号课程且不及格学生的学号、姓名和年龄' AS Item;
SELECT v.Sno, v.Sname, a.Age
FROM Stu_20312_2 AS v
JOIN Stu_age AS a ON v.Sno = a.Sno
ORDER BY v.Sno;

SELECT N'16(6) 查询选课数超过两门学生的平均成绩和选课门数' AS Item;
SELECT s.Sno, s.Sname, AVG(g.Gmark) AS AvgMark, COUNT(*) AS CourseCount
FROM Student AS s
JOIN Grade AS g ON s.Sno = g.Sno
GROUP BY s.Sno, s.Sname
HAVING COUNT(*) > 2
ORDER BY AvgMark DESC;

SELECT N'16(7) 软件工程专业中比计算机科学与技术专业所有学生年龄小的学生' AS Item;
SELECT s.Sno, s.Sname, dbo.AgeOf(s.Sbirth) AS Age
FROM Student AS s
JOIN Class AS c ON s.Clno = c.Clno
WHERE c.Speciality = N'软件工程'
  AND dbo.AgeOf(s.Sbirth) < ALL (
      SELECT dbo.AgeOf(s2.Sbirth)
      FROM Student AS s2
      JOIN Class AS c2 ON s2.Clno = c2.Clno
      WHERE c2.Speciality = N'计算机科学与技术'
  )
ORDER BY s.Sno;

SELECT N'16(8) 每门课程平均成绩和不及格率' AS Item;
SELECT c.Cno, c.Cname,
       CAST(AVG(g.Gmark) AS DECIMAL(6,2)) AS AvgMark,
       SUM(CASE WHEN g.Gmark < 60 THEN 1 ELSE 0 END) AS FailCount,
       CAST(100.0 * SUM(CASE WHEN g.Gmark < 60 THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(6,2)) AS FailPercent
FROM Course AS c
JOIN Grade AS g ON c.Cno = g.Cno
GROUP BY c.Cno, c.Cname
ORDER BY c.Cno;
GO

CREATE OR ALTER VIEW Class_grade
AS
SELECT s.Clno, g.Cno, c.Cname,
       CAST(AVG(g.Gmark) AS DECIMAL(6,2)) AS AvgMark
FROM Student AS s
JOIN Grade AS g ON s.Sno = g.Sno
JOIN Course AS c ON g.Cno = c.Cno
GROUP BY s.Clno, g.Cno, c.Cname;
GO

SELECT N'实验内容2：Class_grade视图反映每个班各选修课平均成绩' AS Item;
SELECT * FROM Class_grade ORDER BY Clno, Cno;

SELECT N'验证Class_grade聚合视图是否可以更新' AS Item;
BEGIN TRY
    EXEC(N'UPDATE Class_grade
           SET AvgMark = 90
           WHERE Clno = ''20311'' AND Cno = ''1'';');
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS ErrorNumber, ERROR_MESSAGE() AS ErrorMessage;
END CATCH;
GO
