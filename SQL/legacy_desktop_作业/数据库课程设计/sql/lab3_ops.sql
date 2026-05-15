USE GradeManager;
GO

ALTER TABLE Student ADD Nation VARCHAR(20) NULL;
GO

PRINT N'增加 Nation 字段后的 Student 表结构';
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Student'
ORDER BY ORDINAL_POSITION;
GO

ALTER TABLE Student DROP COLUMN Nation;
GO

PRINT N'删除 Nation 字段后的 Student 表结构';
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Student'
ORDER BY ORDINAL_POSITION;
GO

INSERT INTO Grade (Sno, Cno, Gmark)
VALUES ('2021104', '3', 80);
GO

PRINT N'插入成绩记录后的查询结果';
SELECT *
FROM Grade
WHERE Sno = '2021104' AND Cno = '3';
GO

UPDATE Grade
SET Gmark = 70
WHERE Sno = '2021104' AND Cno = '3';
GO

PRINT N'更新成绩记录后的查询结果';
SELECT *
FROM Grade
WHERE Sno = '2021104' AND Cno = '3';
GO

DELETE FROM Grade
WHERE Sno = '2021104' AND Cno = '3';
GO

PRINT N'删除成绩记录后的查询结果';
SELECT *
FROM Grade
WHERE Sno = '2021104' AND Cno = '3';
GO

CREATE INDEX IX_Class ON Student(Clno ASC);
GO

PRINT N'创建 IX_Class 索引后的元数据';
SELECT name, type_desc
FROM sys.indexes
WHERE object_id = OBJECT_ID('dbo.Student')
  AND name = 'IX_Class';
GO

DROP INDEX IX_Class ON Student;
GO

PRINT N'删除 IX_Class 索引后的元数据';
SELECT name, type_desc
FROM sys.indexes
WHERE object_id = OBJECT_ID('dbo.Student')
  AND name = 'IX_Class';
GO
