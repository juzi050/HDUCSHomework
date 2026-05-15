USE GradeManager;
GO

PRINT N'12(1) 所有被学生选修了的课程号';
SELECT DISTINCT Cno
FROM Grade;
GO

PRINT N'12(2) 20311班女学生的个人信息';
SELECT *
FROM Student
WHERE Clno = '20311' AND Ssex = N'女';
GO

PRINT N'12(3) 20311班、20312班的学生姓名、性别、出生年份';
SELECT Sname, Ssex, YEAR(Sbirth) AS BirthYear
FROM Student
WHERE Clno IN ('20311', '20312');
GO

PRINT N'12(4) 所有姓李的学生的个人信息';
SELECT *
FROM Student
WHERE Sname LIKE N'李%';
GO

PRINT N'12(5) 学生李勇所在班级的学生人数';
SELECT c.Number
FROM Class c
WHERE c.Clno = (
    SELECT s.Clno
    FROM Student s
    WHERE s.Sname = N'李勇'
);
GO

PRINT N'12(6) 课程名为操作系统的平均成绩、最高分、最低分';
SELECT AVG(g.Gmark) AS AvgMark, MAX(g.Gmark) AS MaxMark, MIN(g.Gmark) AS MinMark
FROM Grade g
JOIN Course c ON g.Cno = c.Cno
WHERE c.Cname = N'操作系统';
GO

PRINT N'12(7) 选修了课程的学生人数';
SELECT COUNT(DISTINCT Sno) AS StudentCount
FROM Grade;
GO

PRINT N'12(8) 选修了课程操作系统的学生人数';
SELECT COUNT(DISTINCT g.Sno) AS StudentCount
FROM Grade g
JOIN Course c ON g.Cno = c.Cno
WHERE c.Cname = N'操作系统';
GO

PRINT N'12(9) 2020级计算机软件班成绩为空的学生姓名';
SELECT DISTINCT s.Sname
FROM Student s
JOIN Class c ON s.Clno = c.Clno
JOIN Grade g ON s.Sno = g.Sno
WHERE c.Inyear = '2020'
  AND c.Speciality = N'软件工程'
  AND g.Gmark IS NULL;
GO
