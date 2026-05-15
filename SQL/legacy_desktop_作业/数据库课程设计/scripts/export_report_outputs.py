from __future__ import annotations

import subprocess
from pathlib import Path

import pymssql


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "artifacts" / "outputs"


def connect(database: str = "master"):
    return pymssql.connect(
        server="127.0.0.1",
        port=14333,
        user="sa",
        password="CodexLab!2026",
        database=database,
        charset="UTF-8",
        autocommit=True,
    )


def run_query(cursor, sql: str):
    cursor.execute(sql)
    if cursor.description:
        columns = [desc[0] for desc in cursor.description]
        rows = cursor.fetchall()
        return columns, rows
    return [], []


def execute_many(cursor, statements):
    for statement in statements:
        cursor.execute(statement)


def rebuild_database():
    with connect("master") as conn:
        cur = conn.cursor()
        execute_many(
            cur,
            [
                """
                IF DB_ID(N'GradeManager') IS NOT NULL
                BEGIN
                    ALTER DATABASE GradeManager SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
                    DROP DATABASE GradeManager;
                END
                """,
                "CREATE DATABASE GradeManager",
            ],
        )

    with connect("GradeManager") as conn:
        cur = conn.cursor()
        execute_many(
            cur,
            [
                """
                CREATE TABLE dbo.Worker
                (
                    Wno CHAR(4) NOT NULL UNIQUE,
                    Wname CHAR(8) NOT NULL,
                    Sex CHAR(2) NOT NULL,
                    Birthday DATETIME NULL
                )
                """,
                """
                CREATE TABLE dbo.Class
                (
                    Clno CHAR(5) NOT NULL PRIMARY KEY,
                    Speciality NVARCHAR(20) NOT NULL,
                    Inyear CHAR(4) NOT NULL,
                    Number INT NULL,
                    Monitor CHAR(7) NULL
                )
                """,
                """
                CREATE TABLE dbo.Course
                (
                    Cno CHAR(3) NOT NULL PRIMARY KEY,
                    Cname NVARCHAR(20) NOT NULL,
                    Ccredit SMALLINT NULL,
                    Cpno CHAR(3) NULL
                )
                """,
                """
                CREATE TABLE dbo.Student
                (
                    Sno CHAR(7) NOT NULL PRIMARY KEY,
                    Sname NVARCHAR(20) NOT NULL,
                    Ssex NVARCHAR(2) NOT NULL,
                    Sbirth DATE NULL,
                    Clno CHAR(5) NOT NULL,
                    CONSTRAINT FK_Student_Class FOREIGN KEY (Clno) REFERENCES dbo.Class(Clno)
                )
                """,
                """
                CREATE TABLE dbo.Grade
                (
                    Sno CHAR(7) NOT NULL,
                    Cno CHAR(3) NOT NULL,
                    Gmark NUMERIC(4,1) NULL,
                    CONSTRAINT PK_Grade PRIMARY KEY (Sno, Cno),
                    CONSTRAINT FK_Grade_Student FOREIGN KEY (Sno) REFERENCES dbo.Student(Sno),
                    CONSTRAINT FK_Grade_Course FOREIGN KEY (Cno) REFERENCES dbo.Course(Cno)
                )
                """,
            ],
        )

        cur.executemany(
            "INSERT INTO dbo.Class (Clno, Speciality, Inyear, Number, Monitor) VALUES (%s, %s, %s, %s, %s)",
            [
                ("20311", "软件工程", "2020", 35, "2020101"),
                ("20312", "计算机科学与技术", "2020", 38, "2020103"),
                ("21311", "软件工程", "2021", 40, "2021103"),
            ],
        )
        cur.executemany(
            "INSERT INTO dbo.Course (Cno, Cname, Ccredit, Cpno) VALUES (%s, %s, %s, %s)",
            [
                ("1", "数据库系统原理", 4, "5"),
                ("2", "计算机系统结构", 3, "8"),
                ("3", "数字电路设计", 2, None),
                ("4", "操作系统", 4, "8"),
                ("5", "数据结构", 4, "7"),
                ("6", "软件工程", 2, "1"),
                ("7", "C语言", 4, None),
                ("8", "计算机组成原理", 4, "3"),
            ],
        )
        cur.executemany(
            "INSERT INTO dbo.Student (Sno, Sname, Ssex, Sbirth, Clno) VALUES (%s, %s, %s, %s, %s)",
            [
                ("2020101", "李勇", "男", "2002-08-09", "20311"),
                ("2020102", "刘诗晨", "女", "2003-04-01", "20311"),
                ("2020103", "王一鸣", "男", "2002-12-25", "20312"),
                ("2020104", "张婷婷", "女", "2002-10-01", "20312"),
                ("2021101", "李勇敏", "女", "2003-11-11", "21311"),
                ("2021102", "贾向东", "男", "2003-12-12", "21311"),
                ("2021103", "陈宝玉", "男", "2004-05-01", "21311"),
                ("2021104", "张逸凡", "男", "2005-01-01", "21311"),
            ],
        )
        cur.executemany(
            "INSERT INTO dbo.Grade (Sno, Cno, Gmark) VALUES (%s, %s, %s)",
            [
                ("2020101", "1", 92),
                ("2020101", "3", 88),
                ("2020101", "5", 86),
                ("2020102", "1", 78),
                ("2020102", "6", 55),
                ("2020103", "3", 65),
                ("2020103", "6", 78),
                ("2020103", "5", 66),
                ("2020104", "1", 54),
                ("2020104", "6", 83),
                ("2021101", "2", 70),
                ("2021101", "4", 65),
                ("2021102", "2", 80),
                ("2021102", "4", 90),
                ("2021103", "1", 83),
                ("2021103", "2", 76),
                ("2021103", "4", 56),
                ("2021103", "7", 88),
            ],
        )


def format_table(title: str, columns, rows) -> str:
    lines = [title]
    if not columns:
        lines.append("（无结果集）")
        return "\n".join(lines)

    str_rows = [[("" if value is None else str(value)) for value in row] for row in rows]
    widths = [len(col) for col in columns]
    for row in str_rows:
        for idx, value in enumerate(row):
            widths[idx] = max(widths[idx], len(value))

    header = " | ".join(col.ljust(widths[idx]) for idx, col in enumerate(columns))
    separator = "-+-".join("-" * widths[idx] for idx in range(len(columns)))
    lines.append(header)
    lines.append(separator)

    if not str_rows:
        lines.append("（0 行）")
    else:
        for row in str_rows:
            lines.append(" | ".join(value.ljust(widths[idx]) for idx, value in enumerate(row)))
    return "\n".join(lines)


def write_text(name: str, content: str) -> Path:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    path = OUT_DIR / name
    path.write_text(content.strip() + "\n", encoding="utf-8")
    return path


def export_lab1():
    docker_ps = subprocess.run(
        ["docker", "ps", "--filter", "name=sql2022-lab", "--format", "table {{.Names}}\t{{.Image}}\t{{.Status}}"],
        capture_output=True,
        text=True,
        encoding="utf-8",
        check=True,
    ).stdout.strip()
    with connect("master") as conn:
        cur = conn.cursor()
        version_cols, version_rows = run_query(cur, "SELECT @@VERSION AS VersionInfo;")
    content = "\n\n".join(
        [
            "实验一环境验证",
            "说明：当前终端无管理员令牌，无法把 SQL Server 服务直接安装进 Windows；实际验证环境采用 Docker Desktop 中的 SQL Server 2022 Express 容器完成，SQL 语法与教材实验二至四保持一致。",
            "Docker 容器状态：\n" + docker_ps,
            format_table("SQL Server 版本验证", version_cols, version_rows),
        ]
    )
    write_text("lab1_env.txt", content)


def export_lab2():
    with connect("GradeManager") as conn:
        cur = conn.cursor()
        db_cols, db_rows = run_query(cur, "SELECT name FROM sys.databases WHERE name = 'GradeManager';")
        worker_cols, worker_rows = run_query(cur, "SELECT * FROM Worker;")
    content = "\n\n".join(
        [
            "实验二结果",
            format_table("数据库 GradeManager 创建结果", db_cols, db_rows),
            format_table("Worker 空表查询结果", worker_cols, worker_rows),
        ]
    )
    write_text("lab2_result.txt", content)


def export_lab3():
    sections: list[str] = ["实验三结果"]
    with connect("GradeManager") as conn:
        cur = conn.cursor()

        cur.execute("IF COL_LENGTH('dbo.Student', 'Nation') IS NOT NULL ALTER TABLE dbo.Student DROP COLUMN Nation;")
        cur.execute("DELETE FROM dbo.Grade WHERE Sno = '2021104' AND Cno = '3';")
        cur.execute("IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.Student') AND name = 'IX_Class') DROP INDEX IX_Class ON dbo.Student;")

        cur.execute("ALTER TABLE dbo.Student ADD Nation VARCHAR(20) NULL;")
        cols, rows = run_query(
            cur,
            "SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Student' ORDER BY ORDINAL_POSITION;",
        )
        sections.append(format_table("1. 增加 Nation 字段后的 Student 表结构", cols, rows))

        cur.execute("ALTER TABLE dbo.Student DROP COLUMN Nation;")
        cols, rows = run_query(
            cur,
            "SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Student' ORDER BY ORDINAL_POSITION;",
        )
        sections.append(format_table("2. 删除 Nation 字段后的 Student 表结构", cols, rows))

        cur.execute("INSERT INTO dbo.Grade (Sno, Cno, Gmark) VALUES ('2021104', '3', 80);")
        cols, rows = run_query(cur, "SELECT Sno, Cno, Gmark FROM dbo.Grade WHERE Sno = '2021104' AND Cno = '3';")
        sections.append(format_table("3. 插入成绩记录后的结果", cols, rows))

        cur.execute("UPDATE dbo.Grade SET Gmark = 70 WHERE Sno = '2021104' AND Cno = '3';")
        cols, rows = run_query(cur, "SELECT Sno, Cno, Gmark FROM dbo.Grade WHERE Sno = '2021104' AND Cno = '3';")
        sections.append(format_table("4. 更新成绩记录后的结果", cols, rows))

        cur.execute("DELETE FROM dbo.Grade WHERE Sno = '2021104' AND Cno = '3';")
        cols, rows = run_query(cur, "SELECT Sno, Cno, Gmark FROM dbo.Grade WHERE Sno = '2021104' AND Cno = '3';")
        sections.append(format_table("5. 删除成绩记录后的结果", cols, rows))

        cur.execute("CREATE INDEX IX_Class ON dbo.Student(Clno ASC);")
        cols, rows = run_query(cur, "SELECT name, type_desc FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.Student') AND name = 'IX_Class';")
        sections.append(format_table("6. 创建 IX_Class 索引后的结果", cols, rows))

        cur.execute("DROP INDEX IX_Class ON dbo.Student;")
        cols, rows = run_query(cur, "SELECT name, type_desc FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.Student') AND name = 'IX_Class';")
        sections.append(format_table("7. 删除 IX_Class 索引后的结果", cols, rows))

        cols, rows = run_query(
            cur,
            """
            SELECT 'Student' AS TableName, COUNT(*) AS TotalRows FROM dbo.Student
            UNION ALL
            SELECT 'Course' AS TableName, COUNT(*) AS TotalRows FROM dbo.Course
            UNION ALL
            SELECT 'Class' AS TableName, COUNT(*) AS TotalRows FROM dbo.Class
            UNION ALL
            SELECT 'Grade' AS TableName, COUNT(*) AS TotalRows FROM dbo.Grade;
            """,
        )
        sections.append(format_table("8. 实验三结束后四张表的记录数", cols, rows))
    write_text("lab3_result.txt", "\n\n".join(sections))


def export_lab4():
    query_sections = ["实验四查询结果"]
    salary_sections = ["实验四错误语句验证"]
    with connect("GradeManager") as conn:
        cur = conn.cursor()

        queries = [
            ("12(1) 所有被学生选修了的课程号", "SELECT DISTINCT Cno FROM dbo.Grade ORDER BY Cno;"),
            ("12(2) 20311班女学生的个人信息", "SELECT Sno, Sname, Ssex, Sbirth, Clno FROM dbo.Student WHERE Clno = '20311' AND Ssex = N'女';"),
            ("12(3) 20311班、20312班的学生姓名、性别、出生年份", "SELECT Sname, Ssex, YEAR(Sbirth) AS BirthYear FROM dbo.Student WHERE Clno IN ('20311', '20312') ORDER BY Sno;"),
            ("12(4) 所有姓李的学生的个人信息", "SELECT Sno, Sname, Ssex, Sbirth, Clno FROM dbo.Student WHERE Sname LIKE N'李%';"),
            ("12(5) 学生李勇所在班级的学生人数", "SELECT c.Number AS StudentCount FROM dbo.Class c WHERE c.Clno = (SELECT s.Clno FROM dbo.Student s WHERE s.Sname = N'李勇');"),
            ("12(6) 课程名为操作系统的平均成绩、最高分、最低分", "SELECT AVG(g.Gmark) AS AvgMark, MAX(g.Gmark) AS MaxMark, MIN(g.Gmark) AS MinMark FROM dbo.Grade g JOIN dbo.Course c ON g.Cno = c.Cno WHERE c.Cname = N'操作系统';"),
            ("12(7) 选修了课程的学生人数", "SELECT COUNT(DISTINCT Sno) AS StudentCount FROM dbo.Grade;"),
            ("12(8) 选修了课程操作系统的学生人数", "SELECT COUNT(DISTINCT g.Sno) AS StudentCount FROM dbo.Grade g JOIN dbo.Course c ON g.Cno = c.Cno WHERE c.Cname = N'操作系统';"),
            ("12(9) 2020级软件工程专业成绩为空的学生姓名", "SELECT DISTINCT s.Sname FROM dbo.Student s JOIN dbo.Class c ON s.Clno = c.Clno JOIN dbo.Grade g ON s.Sno = g.Sno WHERE c.Inyear = '2020' AND c.Speciality = N'软件工程' AND g.Gmark IS NULL;"),
        ]
        for title, sql in queries:
            cols, rows = run_query(cur, sql)
            query_sections.append(format_table(title, cols, rows))

        cur.execute("IF OBJECT_ID(N'dbo.Salary', N'U') IS NOT NULL DROP TABLE dbo.Salary;")
        cur.execute(
            """
            CREATE TABLE dbo.Salary
            (
                Eno CHAR(4) NOT NULL PRIMARY KEY,
                Basepay INT NOT NULL,
                Service INT NULL
            );
            """
        )
        cur.executemany(
            "INSERT INTO dbo.Salary (Eno, Basepay, Service) VALUES (%s, %s, %s);",
            [
                ("1001", 5000, 10),
                ("1002", 4500, 8),
                ("1003", 6200, 12),
                ("1004", 4300, 6),
            ],
        )
        cols, rows = run_query(cur, "SELECT Eno, Basepay, Service FROM dbo.Salary ORDER BY Eno;")
        salary_sections.append(format_table("Salary 表初始数据", cols, rows))

        try:
            cur.execute("SELECT Eno, Basepay, Service FROM dbo.Salary WHERE Basepay < AVG(Basepay);")
        except Exception as exc:  # noqa: BLE001
            salary_sections.append("错误写法执行结果\n" + str(exc))

        cols, rows = run_query(
            cur,
            "SELECT Eno, Basepay, Service FROM dbo.Salary WHERE Basepay < (SELECT AVG(Basepay) FROM dbo.Salary) ORDER BY Eno;",
        )
        salary_sections.append(format_table("正确写法执行结果", cols, rows))

    write_text("lab4_queries_result.txt", "\n\n".join(query_sections))
    write_text("lab4_salary_result.txt", "\n\n".join(salary_sections))


def main():
    rebuild_database()
    export_lab1()
    export_lab2()
    export_lab3()
    export_lab4()


if __name__ == "__main__":
    main()
