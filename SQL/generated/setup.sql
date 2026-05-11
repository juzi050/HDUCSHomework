USE master;
IF DB_ID(N'GradeManager') IS NOT NULL
BEGIN
    ALTER DATABASE GradeManager SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE GradeManager;
END;
GO

CREATE DATABASE GradeManager COLLATE Chinese_PRC_CI_AS;
GO

USE GradeManager;
GO

CREATE TABLE Class (
    Clno CHAR(5) NOT NULL PRIMARY KEY,
    Speciality VARCHAR(20) NOT NULL,
    Inyear CHAR(4) NOT NULL,
    Number INTEGER NULL,
    Monitor CHAR(7) NULL
);

CREATE TABLE Student (
    Sno CHAR(7) NOT NULL PRIMARY KEY,
    Sname VARCHAR(20) NOT NULL,
    Ssex CHAR(2) NOT NULL,
    Sbirth DATE NULL,
    Clno CHAR(5) NOT NULL
);

CREATE TABLE Course (
    Cno CHAR(3) NOT NULL PRIMARY KEY,
    Cname VARCHAR(20) NOT NULL,
    Ccredit SMALLINT NULL,
    Cpno CHAR(3) NULL
);

CREATE TABLE Grade (
    Sno CHAR(7) NOT NULL,
    Cno CHAR(3) NOT NULL,
    Gmark NUMERIC(4,1) NULL,
    CONSTRAINT PK_Grade PRIMARY KEY (Sno, Cno)
);

INSERT INTO Student (Sno, Sname, Ssex, Sbirth, Clno) VALUES
('2020101', N'李勇', N'男', '2002-08-09', '20311'),
('2020102', N'刘诗晨', N'女', '2003-04-01', '20311'),
('2020103', N'王一鸣', N'男', '2002-12-25', '20312'),
('2020104', N'张婷婷', N'女', '2002-10-01', '20312'),
('2021101', N'李勇敏', N'女', '2003-11-11', '21311'),
('2021102', N'贾向东', N'男', '2003-12-12', '21311'),
('2021103', N'陈宝玉', N'男', '2004-05-01', '21311'),
('2021104', N'张逸凡', N'男', '2005-01-01', '21311');

INSERT INTO Course (Cno, Cname, Ccredit, Cpno) VALUES
('1', N'数据库系统原理', 4, '5'),
('2', N'计算机系统结构', 3, '8'),
('3', N'数字电路设计', 2, NULL),
('4', N'操作系统', 4, '8'),
('5', N'数据结构', 4, '7'),
('6', N'软件工程', 2, '1'),
('7', N'C语言', 4, NULL),
('8', N'计算机组成原理', 4, '3');

INSERT INTO Class (Clno, Speciality, Inyear, Number, Monitor) VALUES
('20311', N'软件工程', '2020', 35, '2020101'),
('20312', N'计算机科学与技术', '2020', 38, '2020103'),
('21311', N'软件工程', '2021', 40, '2021103');

INSERT INTO Grade (Sno, Cno, Gmark) VALUES
('2020101', '1', 92), ('2020101', '3', 88), ('2020101', '5', 86),
('2020102', '1', 78), ('2020102', '6', 55),
('2020103', '3', 65), ('2020103', '6', 78), ('2020103', '5', 66),
('2020104', '1', 54), ('2020104', '6', 83),
('2021101', '2', 70), ('2021101', '4', 65),
('2021102', '2', 80), ('2021102', '4', 90),
('2020103', '1', 83), ('2020103', '2', 76), ('2020103', '4', 56), ('2020103', '7', 88);

CREATE TABLE Employee (
    Eno CHAR(6) NOT NULL PRIMARY KEY,
    Ename VARCHAR(20) NOT NULL,
    Title VARCHAR(20) NOT NULL
);

CREATE TABLE Salary (
    Eno CHAR(6) NOT NULL PRIMARY KEY,
    Basepay DECIMAL(10,2) NOT NULL,
    Service DECIMAL(10,2) NOT NULL
);

INSERT INTO Employee (Eno, Ename, Title) VALUES
('E001', N'赵强', N'工程师'),
('E002', N'钱华', N'助理工程师'),
('E003', N'孙敏', N'工程师'),
('E004', N'周宁', N'经理');

INSERT INTO Salary (Eno, Basepay, Service) VALUES
('E001', 3600, 420),
('E002', 2800, 300),
('E003', 4100, 500),
('E004', 5200, 800);
GO

CREATE OR ALTER FUNCTION dbo.AgeOf(@birth DATE)
RETURNS INT
AS
BEGIN
    RETURN DATEDIFF(YEAR, @birth, CAST(GETDATE() AS DATE))
           - CASE
               WHEN DATEADD(YEAR, DATEDIFF(YEAR, @birth, CAST(GETDATE() AS DATE)), @birth) > CAST(GETDATE() AS DATE)
               THEN 1 ELSE 0
             END;
END;
GO

SELECT N'GradeManager 初始化完成' AS Info,
       (SELECT COUNT(*) FROM Student) AS StudentRows,
       (SELECT COUNT(*) FROM Course) AS CourseRows,
       (SELECT COUNT(*) FROM Class) AS ClassRows,
       (SELECT COUNT(*) FROM Grade) AS GradeRows;
GO
