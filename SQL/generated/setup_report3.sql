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

CREATE TABLE dbo.Class (
    Clno CHAR(5) NOT NULL,
    Speciality VARCHAR(20) NOT NULL,
    Inyear CHAR(4) NOT NULL,
    Number INTEGER NULL,
    Monitor CHAR(7) NULL,
    CONSTRAINT PK_Class PRIMARY KEY (Clno),
    CONSTRAINT CK_Class_Number CHECK (Number > 25 AND Number < 50)
);

CREATE TABLE dbo.Student (
    Sno CHAR(7) NOT NULL,
    Sname VARCHAR(20) NOT NULL,
    Ssex CHAR(2) NOT NULL CONSTRAINT DF_Student_Ssex DEFAULT N'男',
    Sbirth DATE NULL,
    Clno CHAR(5) NOT NULL,
    CONSTRAINT PK_Student PRIMARY KEY (Sno),
    CONSTRAINT CK_Student_Ssex CHECK (Ssex IN (N'男', N'女')),
    CONSTRAINT CK_Student_Sbirth CHECK (Sbirth IS NULL OR Sbirth < CONVERT(date, GETDATE())),
    CONSTRAINT FK_Student_Class FOREIGN KEY (Clno) REFERENCES dbo.Class(Clno) ON UPDATE CASCADE
);

CREATE TABLE dbo.Course (
    Cno CHAR(3) NOT NULL,
    Cname VARCHAR(20) NOT NULL,
    Ccredit SMALLINT NULL,
    Cpno CHAR(3) NULL,
    CONSTRAINT PK_Course PRIMARY KEY (Cno),
    CONSTRAINT CK_Course_Ccredit CHECK (Ccredit IS NULL OR Ccredit IN (1, 2, 3, 4, 5, 6)),
    CONSTRAINT FK_Course_PreCourse FOREIGN KEY (Cpno) REFERENCES dbo.Course(Cno)
);

CREATE TABLE dbo.Grade (
    Sno CHAR(7) NOT NULL,
    Cno CHAR(3) NOT NULL,
    Gmark NUMERIC(4,1) NULL,
    CONSTRAINT PK_Grade PRIMARY KEY (Sno, Cno),
    CONSTRAINT CK_Grade_Gmark CHECK (Gmark IS NULL OR (Gmark > 0 AND Gmark < 100)),
    CONSTRAINT FK_Grade_Student FOREIGN KEY (Sno) REFERENCES dbo.Student(Sno) ON DELETE CASCADE,
    CONSTRAINT FK_Grade_Course FOREIGN KEY (Cno) REFERENCES dbo.Course(Cno) ON UPDATE CASCADE
);

INSERT INTO dbo.Class (Clno, Speciality, Inyear, Number, Monitor) VALUES
('20311', N'软件工程', '2020', 35, NULL),
('20312', N'计算机科学与技术', '2020', 38, NULL),
('21311', N'软件工程', '2021', 40, NULL);

INSERT INTO dbo.Student (Sno, Sname, Ssex, Sbirth, Clno) VALUES
('2020101', N'李勇', N'男', '2002-08-09', '20311'),
('2020102', N'刘诗晨', N'女', '2003-04-01', '20311'),
('2020103', N'王一鸣', N'男', '2002-12-25', '20312'),
('2020104', N'张婷婷', N'女', '2002-10-01', '20312'),
('2021101', N'李勇敏', N'女', '2003-11-11', '21311'),
('2021102', N'贾向东', N'男', '2003-12-12', '21311'),
('2021103', N'陈宝玉', N'男', '2004-05-01', '21311'),
('2021104', N'张逸凡', N'男', '2005-01-01', '21311');

UPDATE dbo.Class SET Monitor = '2020101' WHERE Clno = '20311';
UPDATE dbo.Class SET Monitor = '2020103' WHERE Clno = '20312';
UPDATE dbo.Class SET Monitor = '2021103' WHERE Clno = '21311';

ALTER TABLE dbo.Class
ADD CONSTRAINT FK_Class_Monitor FOREIGN KEY (Monitor) REFERENCES dbo.Student(Sno);

INSERT INTO dbo.Course (Cno, Cname, Ccredit, Cpno) VALUES
('7', N'C语言', 4, NULL),
('3', N'数字电路设计', 2, NULL),
('8', N'计算机组成原理', 4, '3'),
('5', N'数据结构', 4, '7'),
('1', N'数据库系统原理', 4, '5'),
('2', N'计算机系统结构', 3, '8'),
('4', N'操作系统', 4, '8'),
('6', N'软件工程', 2, '1');

INSERT INTO dbo.Grade (Sno, Cno, Gmark) VALUES
('2020101', '1', 92), ('2020101', '3', 88), ('2020101', '5', 86),
('2020102', '1', 78), ('2020102', '6', 55),
('2020103', '3', 65), ('2020103', '6', 78), ('2020103', '5', 66),
('2020104', '1', 54), ('2020104', '6', 83),
('2021101', '2', 70), ('2021101', '4', 65),
('2021102', '2', 80), ('2021102', '4', 90),
('2020103', '1', 83), ('2020103', '2', 76), ('2020103', '4', 56), ('2020103', '7', 88);

SELECT N'GradeManager 实验8-10初始化完成' AS Info,
       (SELECT COUNT(*) FROM dbo.Student) AS StudentRows,
       (SELECT COUNT(*) FROM dbo.Course) AS CourseRows,
       (SELECT COUNT(*) FROM dbo.Class) AS ClassRows,
       (SELECT COUNT(*) FROM dbo.Grade) AS GradeRows;
GO
