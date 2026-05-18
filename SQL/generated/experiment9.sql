USE GradeManager;
GO

PRINT N'【实验九】安全性的实现';

DROP VIEW IF EXISTS dbo.vw_CS_CourseStats;
GO

IF DATABASE_PRINCIPAL_ID(N'计算机专业负责人') IS NOT NULL DROP ROLE [计算机专业负责人];
IF DATABASE_PRINCIPAL_ID(N'张老师') IS NOT NULL DROP USER [张老师];
IF DATABASE_PRINCIPAL_ID(N'李老师') IS NOT NULL DROP USER [李老师];
IF DATABASE_PRINCIPAL_ID(N'张勇') IS NOT NULL DROP USER [张勇];
IF DATABASE_PRINCIPAL_ID(N'李勇') IS NOT NULL DROP USER [李勇];
IF DATABASE_PRINCIPAL_ID(N'李勇敏') IS NOT NULL DROP USER [李勇敏];
GO

CREATE USER [张勇] WITHOUT LOGIN;
CREATE USER [李勇] WITHOUT LOGIN;
CREATE USER [李勇敏] WITHOUT LOGIN;
CREATE USER [张老师] WITHOUT LOGIN;
CREATE USER [李老师] WITHOUT LOGIN;
GO

SELECT N'习题4第17题(1)：张勇获得Student、Course查询权限' AS Item;
GRANT SELECT ON dbo.Student TO [张勇];
GRANT SELECT ON dbo.Course TO [张勇];

SELECT N'习题4第17题(2)：张勇获得Student插入、删除权限且可再授权' AS Item;
GRANT INSERT, DELETE ON dbo.Student TO [张勇] WITH GRANT OPTION;
EXECUTE AS USER = N'张勇';
GRANT INSERT, DELETE ON dbo.Student TO [李勇];
REVERT;

SELECT N'习题4第17题(3)：李勇获得Course查询权限和Ccredit修改权限' AS Item;
GRANT SELECT ON dbo.Course TO [李勇];
GRANT UPDATE (Ccredit) ON dbo.Course TO [李勇];

SELECT N'习题4第17题(4)：李勇敏获得Student全部数据操作权限且可再授权' AS Item;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Student TO [李勇敏] WITH GRANT OPTION;
EXECUTE AS USER = N'李勇敏';
GRANT SELECT ON dbo.Student TO [李勇];
REVERT;

SELECT N'授权结果查询' AS Item;
SELECT USER_NAME(dp.grantee_principal_id) AS Grantee,
       dp.permission_name,
       dp.state_desc,
       OBJECT_NAME(dp.major_id) AS ObjectName,
       COL_NAME(dp.major_id, dp.minor_id) AS ColumnName
FROM sys.database_permissions AS dp
WHERE USER_NAME(dp.grantee_principal_id) IN (N'张勇', N'李勇', N'李勇敏')
ORDER BY Grantee, ObjectName, permission_name, ColumnName;

SELECT N'习题4第17题(5)：撤销张勇在Student、Course上的查询权限' AS Item;
REVOKE SELECT ON dbo.Student FROM [张勇];
REVOKE SELECT ON dbo.Course FROM [张勇];

SELECT N'习题4第17题(6)：撤销张勇Student插入、删除权限，并级联撤销其再授权结果' AS Item;
REVOKE INSERT, DELETE ON dbo.Student FROM [张勇] CASCADE;

SELECT N'撤销后结果查询' AS Item;
SELECT USER_NAME(dp.grantee_principal_id) AS Grantee,
       dp.permission_name,
       dp.state_desc,
       OBJECT_NAME(dp.major_id) AS ObjectName,
       COL_NAME(dp.major_id, dp.minor_id) AS ColumnName
FROM sys.database_permissions AS dp
WHERE USER_NAME(dp.grantee_principal_id) IN (N'张勇', N'李勇', N'李勇敏')
ORDER BY Grantee, ObjectName, permission_name, ColumnName;

SELECT N'习题4第17题(7)：张勇、李勇获得建表和建存储过程权限' AS Item;
GRANT CREATE TABLE, CREATE PROCEDURE TO [张勇], [李勇];

GO

CREATE OR ALTER VIEW dbo.vw_CS_CourseStats
AS
SELECT c.Cno, c.Cname,
       COUNT(g.Sno) AS SelectCount,
       CAST(AVG(g.Gmark) AS DECIMAL(6,2)) AS AvgMark,
       MAX(g.Gmark) AS MaxMark,
       MIN(g.Gmark) AS MinMark
FROM dbo.Class AS cl
JOIN dbo.Student AS s ON cl.Clno = s.Clno
JOIN dbo.Grade AS g ON s.Sno = g.Sno
JOIN dbo.Course AS c ON g.Cno = c.Cno
WHERE cl.Speciality = N'计算机科学与技术'
GROUP BY c.Cno, c.Cname;
GO

CREATE ROLE [计算机专业负责人];
ALTER ROLE [计算机专业负责人] ADD MEMBER [张老师];
ALTER ROLE [计算机专业负责人] ADD MEMBER [李老师];
GRANT SELECT ON dbo.vw_CS_CourseStats TO [计算机专业负责人];
GO

SELECT N'习题4第18题：角色只能查看计算机科学与技术专业课程成绩统计视图' AS Item;
EXECUTE AS USER = N'张老师';
SELECT * FROM dbo.vw_CS_CourseStats ORDER BY Cno;
BEGIN TRY
    EXEC(N'SELECT TOP (1) Sno, Sname FROM dbo.Student;');
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS ErrorNumber, ERROR_MESSAGE() AS ErrorMessage;
END CATCH;
REVERT;

SELECT N'角色成员与授权结果' AS Item;
SELECT rp.name AS RoleName, mp.name AS MemberName
FROM sys.database_role_members AS drm
JOIN sys.database_principals AS rp ON drm.role_principal_id = rp.principal_id
JOIN sys.database_principals AS mp ON drm.member_principal_id = mp.principal_id
WHERE rp.name = N'计算机专业负责人'
ORDER BY MemberName;
GO
