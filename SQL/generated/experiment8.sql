USE GradeManager;
GO

PRINT N'【实验八】完整性约束的实现';

SELECT N'习题4第11题：四个表已加入主键、外键、CHECK、DEFAULT等完整性约束' AS Item;
SELECT tc.TABLE_NAME, tc.CONSTRAINT_TYPE, tc.CONSTRAINT_NAME
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS tc
WHERE tc.TABLE_SCHEMA = 'dbo'
ORDER BY tc.TABLE_NAME, tc.CONSTRAINT_TYPE, tc.CONSTRAINT_NAME;

SELECT N'验证用户自定义完整性：课程学分只能为1到6' AS Item;
BEGIN TRY
    INSERT INTO dbo.Course (Cno, Cname, Ccredit, Cpno)
    VALUES ('999', N'错误学分课程', 8, NULL);
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS ErrorNumber, ERROR_MESSAGE() AS ErrorMessage;
END CATCH;
GO

CREATE OR ALTER TRIGGER dbo.trg_Student_ClassNumberAndLimit
ON dbo.Student
AFTER INSERT, DELETE, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Delta TABLE (
        Clno CHAR(5) NOT NULL PRIMARY KEY,
        DeltaCount INT NOT NULL
    );

    INSERT INTO @Delta (Clno, DeltaCount)
    SELECT Clno, SUM(DeltaCount)
    FROM (
        SELECT Clno, COUNT(*) AS DeltaCount FROM inserted GROUP BY Clno
        UNION ALL
        SELECT Clno, -COUNT(*) AS DeltaCount FROM deleted GROUP BY Clno
    ) AS x
    GROUP BY Clno
    HAVING SUM(DeltaCount) <> 0;

    IF EXISTS (
        SELECT 1
        FROM dbo.Class AS c
        JOIN @Delta AS d ON c.Clno = d.Clno
        WHERE ISNULL(c.Number, 0) + d.DeltaCount > 40
    )
    BEGIN
        RAISERROR(N'该班学生人数超过40人，操作回滚。', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    UPDATE c
    SET Number = ISNULL(c.Number, 0) + d.DeltaCount
    FROM dbo.Class AS c
    JOIN @Delta AS d ON c.Clno = d.Clno;
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_Class_MonitorCheck
ON dbo.Class
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF UPDATE(Monitor)
       AND EXISTS (
           SELECT 1
           FROM inserted AS i
           LEFT JOIN dbo.Student AS s ON i.Monitor = s.Sno
           WHERE i.Monitor IS NOT NULL
             AND (s.Sno IS NULL OR s.Clno <> i.Clno)
       )
    BEGIN
        RAISERROR(N'班长学号必须属于本班学生，更新取消。', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
END;
GO

DROP VIEW IF EXISTS dbo.vw_StudentCredit;
DROP TABLE IF EXISTS dbo.StudentCredit;
GO

CREATE TABLE dbo.StudentCredit (
    Sno CHAR(7) NOT NULL PRIMARY KEY,
    EarnedCredit INT NOT NULL CONSTRAINT DF_StudentCredit_EarnedCredit DEFAULT 0,
    CONSTRAINT FK_StudentCredit_Student FOREIGN KEY (Sno) REFERENCES dbo.Student(Sno) ON DELETE CASCADE
);

INSERT INTO dbo.StudentCredit (Sno, EarnedCredit)
SELECT s.Sno,
       COALESCE(SUM(CASE WHEN g.Gmark >= 60 THEN c.Ccredit ELSE 0 END), 0) AS EarnedCredit
FROM dbo.Student AS s
LEFT JOIN dbo.Grade AS g ON s.Sno = g.Sno
LEFT JOIN dbo.Course AS c ON g.Cno = c.Cno
GROUP BY s.Sno;
GO

CREATE OR ALTER TRIGGER dbo.trg_Grade_UpdateStudentCredit
ON dbo.Grade
AFTER INSERT, DELETE, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    WITH Affected AS (
        SELECT Sno FROM inserted
        UNION
        SELECT Sno FROM deleted
    ),
    Calc AS (
        SELECT a.Sno,
               COALESCE(SUM(CASE WHEN g.Gmark >= 60 THEN c.Ccredit ELSE 0 END), 0) AS EarnedCredit
        FROM Affected AS a
        LEFT JOIN dbo.Grade AS g ON a.Sno = g.Sno
        LEFT JOIN dbo.Course AS c ON g.Cno = c.Cno
        GROUP BY a.Sno
    )
    MERGE dbo.StudentCredit AS target
    USING Calc AS source
       ON target.Sno = source.Sno
    WHEN MATCHED THEN
        UPDATE SET EarnedCredit = source.EarnedCredit
    WHEN NOT MATCHED THEN
        INSERT (Sno, EarnedCredit) VALUES (source.Sno, source.EarnedCredit);
END;
GO

CREATE OR ALTER VIEW dbo.vw_StudentCredit
AS
SELECT s.Sno, s.Sname, sc.EarnedCredit
FROM dbo.Student AS s
JOIN dbo.StudentCredit AS sc ON s.Sno = sc.Sno;
GO

SELECT N'习题4第12题：插入/删除Student时，Class.Number自动维护' AS Item;
SELECT N'插入前' AS Stage, Clno, Number FROM dbo.Class WHERE Clno = '20311';
INSERT INTO dbo.Student (Sno, Sname, Ssex, Sbirth, Clno)
VALUES ('2023999', N'测试学生', N'男', '2004-01-01', '20311');
SELECT N'插入后' AS Stage, Clno, Number FROM dbo.Class WHERE Clno = '20311';
DELETE FROM dbo.Student WHERE Sno = '2023999';
SELECT N'删除后' AS Stage, Clno, Number FROM dbo.Class WHERE Clno = '20311';

SELECT N'习题4第15题：班级人数超过40人时回滚' AS Item;
BEGIN TRY
    INSERT INTO dbo.Student (Sno, Sname, Ssex, Sbirth, Clno)
    VALUES ('2023998', N'超员测试', N'女', '2004-02-01', '21311');
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS ErrorNumber, ERROR_MESSAGE() AS ErrorMessage;
END CATCH;
SELECT Clno, Number FROM dbo.Class WHERE Clno = '21311';

SELECT N'习题4第13题：班长必须为本班学生' AS Item;
BEGIN TRY
    UPDATE dbo.Class SET Monitor = '2020103' WHERE Clno = '20311';
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS ErrorNumber, ERROR_MESSAGE() AS ErrorMessage;
END CATCH;
UPDATE dbo.Class SET Monitor = '2020102' WHERE Clno = '20311';
SELECT Clno, Monitor FROM dbo.Class WHERE Clno = '20311';

SELECT N'习题4第14题：成绩达到60分后才获得该课程学分' AS Item;
SELECT N'修改前' AS Stage, * FROM dbo.vw_StudentCredit WHERE Sno = '2020104';
BEGIN TRAN;
UPDATE dbo.Grade SET Gmark = 61 WHERE Sno = '2020104' AND Cno = '1';
SELECT N'事务内修改后' AS Stage, * FROM dbo.vw_StudentCredit WHERE Sno = '2020104';
ROLLBACK;
SELECT N'回滚后' AS Stage, * FROM dbo.vw_StudentCredit WHERE Sno = '2020104';
GO
