USE GradeManager;
GO

PRINT N'【实验五】SELECT 语句高级格式和完整格式的使用';

SELECT N'13(1) 与李勇在同一个班级的学生信息' AS Item;
SELECT Sno, Sname, Ssex, Sbirth, Clno
FROM Student
WHERE Clno = (SELECT Clno FROM Student WHERE Sname = N'李勇')
  AND Sname <> N'李勇';

SELECT N'13(2) 与李勇有相同选修课程的学生信息' AS Item;
SELECT DISTINCT s.Sno, s.Sname, s.Ssex, s.Sbirth, s.Clno
FROM Student AS s
WHERE s.Sno <> (SELECT Sno FROM Student WHERE Sname = N'李勇')
  AND s.Sno IN (
      SELECT g.Sno
      FROM Grade AS g
      WHERE g.Cno IN (
          SELECT Cno
          FROM Grade
          WHERE Sno = (SELECT Sno FROM Student WHERE Sname = N'李勇')
      )
  )
ORDER BY s.Sno;

SELECT N'13(3) 年龄介于李勇和25岁之间的学生信息' AS Item;
SELECT Sno, Sname, dbo.AgeOf(Sbirth) AS Age, Sbirth, Clno
FROM Student
WHERE Sname <> N'李勇'
  AND dbo.AgeOf(Sbirth) BETWEEN
      (SELECT dbo.AgeOf(Sbirth) FROM Student WHERE Sname = N'李勇') AND 25
ORDER BY Age, Sno;

SELECT N'13(4) 选修了操作系统的学生学号和姓名' AS Item;
SELECT s.Sno, s.Sname
FROM Student AS s
WHERE s.Sno IN (
    SELECT g.Sno
    FROM Grade AS g
    WHERE g.Cno = (SELECT Cno FROM Course WHERE Cname = N'操作系统')
)
ORDER BY s.Sno;

SELECT N'13(5) 没有选修1号课程的学生姓名' AS Item;
SELECT s.Sname
FROM Student AS s
WHERE NOT EXISTS (
    SELECT 1
    FROM Grade AS g
    WHERE g.Sno = s.Sno AND g.Cno = '1'
)
ORDER BY s.Sno;

SELECT N'13(6) 每个学生超过本人平均成绩的学号和课程号' AS Item;
SELECT g.Sno, g.Cno, g.Gmark
FROM Grade AS g
WHERE g.Gmark > (
    SELECT AVG(g2.Gmark)
    FROM Grade AS g2
    WHERE g2.Sno = g.Sno
)
ORDER BY g.Sno, g.Cno;

SELECT N'13(7) 选修了全部课程的学生姓名' AS Item;
SELECT s.Sname
FROM Student AS s
WHERE NOT EXISTS (
    SELECT 1
    FROM Course AS c
    WHERE NOT EXISTS (
        SELECT 1
        FROM Grade AS g
        WHERE g.Sno = s.Sno AND g.Cno = c.Cno
    )
);

SELECT N'13(8) 数据库系统原理成绩高于该课程平均分的学生学号、姓名、成绩' AS Item;
SELECT s.Sno, s.Sname, g.Gmark
FROM Student AS s
JOIN Grade AS g ON s.Sno = g.Sno
JOIN Course AS c ON g.Cno = c.Cno
WHERE c.Cname = N'数据库系统原理'
  AND g.Gmark > (
      SELECT AVG(g2.Gmark)
      FROM Grade AS g2
      JOIN Course AS c2 ON g2.Cno = c2.Cno
      WHERE c2.Cname = N'数据库系统原理'
  )
ORDER BY g.Gmark DESC;

SELECT N'13(9) 每个班中数据库系统原理成绩高于本班平均分的学生' AS Item;
SELECT s.Clno, s.Sno, s.Sname, g.Gmark
FROM Student AS s
JOIN Grade AS g ON s.Sno = g.Sno
JOIN Course AS c ON g.Cno = c.Cno
WHERE c.Cname = N'数据库系统原理'
  AND g.Gmark > (
      SELECT AVG(g2.Gmark)
      FROM Student AS s2
      JOIN Grade AS g2 ON s2.Sno = g2.Sno
      JOIN Course AS c2 ON g2.Cno = c2.Cno
      WHERE c2.Cname = N'数据库系统原理'
        AND s2.Clno = s.Clno
  )
ORDER BY s.Clno, g.Gmark DESC;

SELECT N'13(10) 至少选修了2020101号学生全部课程的学生学号' AS Item;
SELECT s.Sno
FROM Student AS s
WHERE NOT EXISTS (
    SELECT 1
    FROM Grade AS gy
    WHERE gy.Sno = '2020101'
      AND NOT EXISTS (
          SELECT 1
          FROM Grade AS gx
          WHERE gx.Sno = s.Sno AND gx.Cno = gy.Cno
      )
)
ORDER BY s.Sno;

SELECT N'14(1) 选修3号课程的学生学号及成绩，按成绩降序' AS Item;
SELECT Sno, Gmark
FROM Grade
WHERE Cno = '3'
ORDER BY Gmark DESC;

SELECT N'14(2) 全体学生信息，按班级升序、年龄降序' AS Item;
SELECT Sno, Sname, Ssex, dbo.AgeOf(Sbirth) AS Age, Clno
FROM Student
ORDER BY Clno ASC, Age DESC;

SELECT N'14(3) 每个课程号及相应选课人数' AS Item;
SELECT Cno, COUNT(*) AS StudentCount
FROM Grade
GROUP BY Cno
ORDER BY Cno;

SELECT N'14(4) 选修三门以上课程的学生学号' AS Item;
SELECT Sno, COUNT(*) AS CourseCount
FROM Grade
GROUP BY Sno
HAVING COUNT(*) >= 3
ORDER BY Sno;

SELECT N'14(5) 至少选修1号和2号课程的学生学号和姓名' AS Item;
SELECT s.Sno, s.Sname
FROM Student AS s
WHERE s.Sno IN (
    SELECT Sno
    FROM Grade
    WHERE Cno IN ('1', '2')
    GROUP BY Sno
    HAVING COUNT(DISTINCT Cno) = 2
)
ORDER BY s.Sno;

SELECT N'14(6) 每门课程成绩前三名的学生学号、姓名、课程号和成绩' AS Item;
WITH RankedGrade AS (
    SELECT g.Sno, s.Sname, g.Cno, g.Gmark,
           ROW_NUMBER() OVER (PARTITION BY g.Cno ORDER BY g.Gmark DESC, g.Sno) AS rn
    FROM Grade AS g
    JOIN Student AS s ON s.Sno = g.Sno
)
SELECT Sno, Sname, Cno, Gmark
FROM RankedGrade
WHERE rn <= 3
ORDER BY Cno, Gmark DESC;

SELECT N'14(7) 每个学生的总学分，按总学分降序' AS Item;
SELECT s.Sno, s.Sname, SUM(c.Ccredit) AS TotalCredit
FROM Student AS s
JOIN Grade AS g ON s.Sno = g.Sno
JOIN Course AS c ON g.Cno = c.Cno
GROUP BY s.Sno, s.Sname
ORDER BY TotalCredit DESC, s.Sno;
GO
