USE GradeManager;
GO

IF OBJECT_ID(N'dbo.Grade', N'U') IS NOT NULL DROP TABLE dbo.Grade;
IF OBJECT_ID(N'dbo.Student', N'U') IS NOT NULL DROP TABLE dbo.Student;
IF OBJECT_ID(N'dbo.Course', N'U') IS NOT NULL DROP TABLE dbo.Course;
IF OBJECT_ID(N'dbo.Class', N'U') IS NOT NULL DROP TABLE dbo.Class;
GO

CREATE TABLE Class
(
    Clno CHAR(5) NOT NULL PRIMARY KEY,
    Speciality VARCHAR(20) NOT NULL,
    Inyear CHAR(4) NOT NULL,
    Number INT NULL,
    Monitor CHAR(7) NULL
);
GO

CREATE TABLE Course
(
    Cno CHAR(3) NOT NULL PRIMARY KEY,
    Cname VARCHAR(20) NOT NULL,
    Ccredit SMALLINT NULL,
    Cpno CHAR(3) NULL
);
GO

CREATE TABLE Student
(
    Sno CHAR(7) NOT NULL PRIMARY KEY,
    Sname VARCHAR(20) NOT NULL,
    Ssex CHAR(2) NOT NULL,
    Sbirth DATE NULL,
    Clno CHAR(5) NOT NULL,
    CONSTRAINT FK_Student_Class FOREIGN KEY (Clno) REFERENCES Class(Clno)
);
GO

CREATE TABLE Grade
(
    Sno CHAR(7) NOT NULL,
    Cno CHAR(3) NOT NULL,
    Gmark NUMERIC(4,1) NULL,
    CONSTRAINT PK_Grade PRIMARY KEY (Sno, Cno),
    CONSTRAINT FK_Grade_Student FOREIGN KEY (Sno) REFERENCES Student(Sno),
    CONSTRAINT FK_Grade_Course FOREIGN KEY (Cno) REFERENCES Course(Cno)
);
GO

INSERT INTO Class (Clno, Speciality, Inyear, Number, Monitor) VALUES
('20311', N'软件工程', '2020', 35, '2020101'),
('20312', N'计算机科学与技术', '2020', 38, '2020103'),
('21311', N'软件工程', '2021', 40, '2021103');
GO

INSERT INTO Course (Cno, Cname, Ccredit, Cpno) VALUES
('1', N'数据库系统原理', 4, '5'),
('2', N'计算机系统结构', 3, '8'),
('3', N'数字电路设计', 2, NULL),
('4', N'操作系统', 4, '8'),
('5', N'数据结构', 4, '7'),
('6', N'软件工程', 2, '1'),
('7', N'C语言', 4, NULL),
('8', N'计算机组成原理', 4, '3');
GO

INSERT INTO Student (Sno, Sname, Ssex, Sbirth, Clno) VALUES
('2020101', N'李勇', N'男', '2002-08-09', '20311'),
('2020102', N'刘诗晨', N'女', '2003-04-01', '20311'),
('2020103', N'王一鸣', N'男', '2002-12-25', '20312'),
('2020104', N'张婷婷', N'女', '2002-10-01', '20312'),
('2021101', N'李勇敏', N'女', '2003-11-11', '21311'),
('2021102', N'贾向东', N'男', '2003-12-12', '21311'),
('2021103', N'陈宝玉', N'男', '2004-05-01', '21311'),
('2021104', N'张逸凡', N'男', '2005-01-01', '21311');
GO

INSERT INTO Grade (Sno, Cno, Gmark) VALUES
('2020101', '1', 92),
('2020101', '3', 88),
('2020101', '5', 86),
('2020102', '1', 78),
('2020102', '6', 55),
('2020103', '3', 65),
('2020103', '6', 78),
('2020103', '5', 66),
('2020104', '1', 54),
('2020104', '6', 83),
('2021101', '2', 70),
('2021101', '4', 65),
('2021102', '2', 80),
('2021102', '4', 90),
('2021103', '1', 83),
('2021103', '2', 76),
('2021103', '4', 56),
('2021103', '7', 88);
GO

PRINT N'已创建的四张表';
SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
  AND TABLE_NAME IN ('Student', 'Course', 'Class', 'Grade')
ORDER BY TABLE_NAME;
GO

PRINT N'四张表的记录数';
SELECT 'Student' AS TableName, COUNT(*) AS TotalRows FROM Student
UNION ALL
SELECT 'Course' AS TableName, COUNT(*) AS TotalRows FROM Course
UNION ALL
SELECT 'Class' AS TableName, COUNT(*) AS TotalRows FROM Class
UNION ALL
SELECT 'Grade' AS TableName, COUNT(*) AS TotalRows FROM Grade;
GO

PRINT N'Student表示例数据';
SELECT TOP 5 *
FROM Student
ORDER BY Sno;
GO
