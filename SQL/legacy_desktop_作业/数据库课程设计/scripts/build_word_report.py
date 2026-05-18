from __future__ import annotations

from pathlib import Path

from win32com.client import DispatchEx


ROOT = Path(__file__).resolve().parents[1]
DOC_PATH = ROOT / "1 系统需求分析模板.doc"
IMG_DIR = ROOT / "artifacts" / "screenshots"
SQL_DIR = ROOT / "sql"
STUDENT_ID = "<学号>"
STUDENT_NAME = "<姓名>"


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8-sig").strip()


def add_paragraph(sel, text="", size=12, bold=False, align=0):
    sel.ParagraphFormat.Alignment = align
    sel.ParagraphFormat.LineSpacingRule = 4
    sel.ParagraphFormat.LineSpacing = 20
    sel.ParagraphFormat.SpaceAfter = 0
    sel.ParagraphFormat.SpaceBefore = 0
    sel.ParagraphFormat.LeftIndent = 0
    sel.ParagraphFormat.FirstLineIndent = 0
    sel.Font.NameFarEast = "宋体"
    sel.Font.NameAscii = "Times New Roman"
    sel.Font.NameOther = "Times New Roman"
    sel.Font.Size = size
    sel.Font.Bold = 1 if bold else 0
    sel.TypeText(text.replace("\n", "\r"))
    sel.TypeParagraph()


def add_blank(sel):
    add_paragraph(sel, "")


def add_title(sel, text):
    add_paragraph(sel, text, size=18, bold=True, align=1)


def add_heading(sel, text, level=1):
    size = 14 if level == 1 else 12
    add_paragraph(sel, text, size=size, bold=True, align=0)


def add_image(sel, image_path: Path, caption: str):
    add_blank(sel)
    add_paragraph(sel, caption, size=12, bold=False, align=1)
    sel.ParagraphFormat.Alignment = 1
    sel.ParagraphFormat.LineSpacingRule = 0
    sel.ParagraphFormat.LineSpacing = 12
    sel.ParagraphFormat.SpaceAfter = 0
    sel.ParagraphFormat.SpaceBefore = 0
    sel.ParagraphFormat.LeftIndent = 0
    sel.ParagraphFormat.FirstLineIndent = 0
    shape = sel.InlineShapes.AddPicture(str(image_path), False, True)
    shape.LockAspectRatio = True
    if shape.Width > 430:
        shape.Width = 430
    if shape.Height > 500:
        shape.Height = 500
    shape.Range.ParagraphFormat.Alignment = 1
    shape.Range.ParagraphFormat.LineSpacingRule = 0
    shape.Range.ParagraphFormat.LineSpacing = 12
    shape.Range.ParagraphFormat.SpaceAfter = 0
    shape.Range.ParagraphFormat.SpaceBefore = 0
    sel.TypeParagraph()
    add_blank(sel)


def add_code_block(sel, title: str, code_text: str):
    add_paragraph(sel, title, size=12, bold=True, align=0)
    sel.ParagraphFormat.Alignment = 0
    sel.ParagraphFormat.LineSpacingRule = 4
    sel.ParagraphFormat.LineSpacing = 20
    sel.ParagraphFormat.SpaceAfter = 0
    sel.ParagraphFormat.SpaceBefore = 0
    sel.ParagraphFormat.LeftIndent = 18
    sel.ParagraphFormat.FirstLineIndent = 0
    sel.Font.NameFarEast = "宋体"
    sel.Font.NameAscii = "Times New Roman"
    sel.Font.NameOther = "Times New Roman"
    sel.Font.Size = 12
    sel.Font.Bold = 0
    sel.TypeText(code_text.replace("\n", "\r"))
    sel.TypeParagraph()
    sel.ParagraphFormat.LeftIndent = 0
    add_blank(sel)


def insert_page_break(sel):
    sel.InsertBreak(7)


def build_report():
    lab2_sql = read_text(SQL_DIR / "lab2_setup.sql")
    lab3_create_sql = read_text(SQL_DIR / "lab3_setup.sql")
    lab3_ops_sql = read_text(SQL_DIR / "lab3_ops.sql")
    lab4_query_sql = read_text(SQL_DIR / "lab4_queries.sql")
    lab4_salary_error_sql = read_text(SQL_DIR / "lab4_salary_error.sql")
    lab4_salary_correct_sql = read_text(SQL_DIR / "lab4_salary_correct.sql")

    word = DispatchEx("Word.Application")
    word.Visible = False
    word.DisplayAlerts = 0

    doc = word.Documents.Open(str(DOC_PATH))
    try:
        doc.Range().Delete()
        sel = word.Selection
        sel.HomeKey(Unit=6)

        add_title(sel, "数据库原理上机实验报告")
        add_title(sel, "教材附录A 上机实验一、二、三、四")
        add_blank(sel)
        add_paragraph(sel, f"学号：{STUDENT_ID}", size=14, bold=False, align=1)
        add_paragraph(sel, f"姓名：{STUDENT_NAME}", size=14, bold=False, align=1)
        add_paragraph(sel, "完成时间：2026年04月27日", size=14, bold=False, align=1)
        add_blank(sel)
        add_paragraph(sel, "注：教材附录A用的是 SQL Server 2014。因为本机是 Windows 11，这里改用 SQL Server 2022 完成实验，后面实验二到实验四的 SQL 写法和教材要求基本一致。", size=12, bold=False, align=0)

        insert_page_break(sel)

        add_heading(sel, "实验一 安装和了解 SQL Server", level=1)
        add_heading(sel, "（1）实验目的", level=2)
        add_paragraph(sel, "先把数据库环境跑起来，了解怎么连接数据库，并确认数据库服务能正常使用。")
        add_heading(sel, "（2）实验环境", level=2)
        add_paragraph(sel, "Windows 11 64位，Docker Desktop 4.64.0，SQL Server 2022 Express（容器方式运行）。连接验证时使用 docker exec 和 sqlcmd。")
        add_heading(sel, "（3）实验报告内容", level=2)
        add_paragraph(sel, "题目：安装并了解 SQL Server 的基本运行方式")
        add_paragraph(sel, "操作步骤：")
        add_paragraph(sel, "1. 先查看本机系统和可用空间，确认实验环境能用。")
        add_paragraph(sel, "2. 拉取 SQL Server 2022 镜像，并启动一个 Express 容器。")
        add_paragraph(sel, "3. 用 sqlcmd 执行 SELECT @@VERSION，检查数据库是否真的启动成功。")
        add_code_block(
            sel,
            "关键命令：",
            "\n".join(
                [
                    "docker pull mcr.microsoft.com/mssql/server:2022-latest",
                    "docker run -d --name sql2022-lab -e ACCEPT_EULA=Y -e MSSQL_PID=Express -e MSSQL_SA_PASSWORD=CodexLab!2026 -p 14333:1433 mcr.microsoft.com/mssql/server:2022-latest",
                    "docker exec sql2022-lab /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P \"CodexLab!2026\" -C -Q \"SELECT @@VERSION AS VersionInfo;\"",
                ]
            ),
        )
        add_image(sel, IMG_DIR / "lab1_env.png", "实验一结果截图：环境与版本验证")
        add_heading(sel, "（4）实验中遇到的问题和总结", level=2)
        add_paragraph(sel, "这一步遇到的主要问题是当前账号没有管理员权限，没法像教材那样把 SQL Server 直接装成 Windows 服务。")
        add_paragraph(sel, "后来改成用 Docker 方式启动 SQL Server 2022 Express，数据库还是能正常连接，后面的实验也能继续做。")
        add_paragraph(sel, "做完这个实验后，我觉得安装是否成功不能只看界面，要以能不能连上数据库、能不能查出版本信息为准。")

        insert_page_break(sel)

        add_heading(sel, "实验二 创建 SQL Server 数据库和表", level=1)
        add_heading(sel, "（1）实验目的", level=2)
        add_paragraph(sel, "练习创建数据库、创建数据表，并完成最基本的查询操作。")
        add_heading(sel, "（2）实验环境", level=2)
        add_paragraph(sel, "Windows 11 64位，Docker Desktop，SQL Server 2022 Express，实验数据库名为 GradeManager。")
        add_heading(sel, "（3）实验报告内容", level=2)
        add_paragraph(sel, "题目：创建 GradeManager 数据库和 Worker 表，并查看空表查询结果。")
        add_code_block(sel, "实验代码：", lab2_sql)
        add_image(sel, IMG_DIR / "lab2_result.png", "实验二结果截图：数据库创建与 Worker 空表查询")
        add_paragraph(sel, "问题回答：")
        add_paragraph(sel, "1. SQL Server 的物理数据库文件主要有三类：主数据文件（.mdf）、次数据文件（.ndf）和日志文件（.ldf）。")
        add_paragraph(sel, "2. SQL Server 常见的整型数据类型有 BIGINT、INT、SMALLINT、TINYINT，占用空间分别是 8B、4B、2B、1B；取值范围依次是 -9223372036854775808~9223372036854775807、-2147483648~2147483647、-32768~32767、0~255。")
        add_heading(sel, "（4）实验中遇到的问题和总结", level=2)
        add_paragraph(sel, "一开始我只是把环境启动了，但没有马上确认实例是不是真的能用。")
        add_paragraph(sel, "后面重新做了连接测试，并执行查询语句，确认 GradeManager 和 Worker 表都创建成功。")
        add_paragraph(sel, "这个实验让我更清楚了一点：做数据库实验时，一定要先确认当前操作的是哪个库，不然很容易写错地方。")

        insert_page_break(sel)

        add_heading(sel, "实验三 基本表的建立和修改", level=1)
        add_heading(sel, "（1）实验目的", level=2)
        add_paragraph(sel, "通过建表、插入数据和修改表结构，熟悉关系表的基本操作。")
        add_heading(sel, "（2）实验环境", level=2)
        add_paragraph(sel, "Windows 11 64位，Docker Desktop，SQL Server 2022 Express，数据库为 GradeManager。")
        add_heading(sel, "（3）实验报告内容", level=2)
        add_paragraph(sel, "题目：建立 Student、Course、Class、Grade 四张表，插入样例数据，并完成教材中要求的增删字段、增删改记录和索引操作。")
        add_code_block(sel, "实验代码（一）四个基本表与样例数据：", lab3_create_sql)
        add_code_block(sel, "实验代码（二）习题3第11题操作：", lab3_ops_sql)
        add_image(sel, IMG_DIR / "lab3_result_part1.png", "实验三结果截图（1）：字段结构验证")
        add_image(sel, IMG_DIR / "lab3_result_part2.png", "实验三结果截图（2）：插入、更新、删除验证")
        add_image(sel, IMG_DIR / "lab3_result_part3.png", "实验三结果截图（3）：索引与最终结果验证")
        add_paragraph(sel, "问题回答：")
        add_paragraph(sel, "1. 习题3第10题四个基本表的 SQL 定义见上面的“实验代码（一）”。")
        add_paragraph(sel, "2. 习题3第11题各项操作的 SQL 语句见上面的“实验代码（二）”。")
        add_paragraph(sel, "3. NOT NULL 的作用是不允许该字段为空，这样能保证关键数据一定会填写，不容易出现信息缺失的情况。")
        add_heading(sel, "（4）实验中遇到的问题和总结", level=2)
        add_paragraph(sel, "做这个实验时，最明显的问题是中文样例数据一开始出现了乱码。")
        add_paragraph(sel, "后面我改用 Python 直接连接数据库重新写入数据，中文内容才恢复正常。")
        add_paragraph(sel, "通过这个实验，我把建表、改表、改数据、建索引这些操作重新梳理了一遍，感觉对基本表的操作顺序更熟悉了。")

        insert_page_break(sel)

        add_heading(sel, "实验四 SELECT 语句基本格式的使用", level=1)
        add_heading(sel, "（1）实验目的", level=2)
        add_paragraph(sel, "练习 SELECT 语句的基本写法，能够完成条件查询和简单统计。")
        add_heading(sel, "（2）实验环境", level=2)
        add_paragraph(sel, "Windows 11 64位，Docker Desktop，SQL Server 2022 Express，数据库为 GradeManager。")
        add_heading(sel, "（3）实验报告内容", level=2)
        add_paragraph(sel, "题目：完成习题3第12题中的 9 个查询，并验证 AVG 这类聚合函数不能直接写在 WHERE 子句里。")
        add_code_block(sel, "实验代码（一）习题3第12题查询：", lab4_query_sql)
        add_code_block(sel, "实验代码（二）错误写法：", lab4_salary_error_sql)
        add_code_block(sel, "实验代码（三）正确写法：", lab4_salary_correct_sql)
        add_image(sel, IMG_DIR / "lab4_queries_result_part1.png", "实验四结果截图（一）：习题3第12题查询结果（上）")
        add_image(sel, IMG_DIR / "lab4_queries_result_part2.png", "实验四结果截图（二）：习题3第12题查询结果（中）")
        add_image(sel, IMG_DIR / "lab4_queries_result_part3.png", "实验四结果截图（三）：习题3第12题查询结果（下）")
        add_image(sel, IMG_DIR / "lab4_salary_result.png", "实验四结果截图（四）：错误语句与正确语句对比")
        add_paragraph(sel, "问题回答：")
        add_paragraph(sel, "1. 习题3第12题各项操作的 SQL 语句见上面的“实验代码（一）”。")
        add_paragraph(sel, "2. 实验内容2中的 SQL 语句不正确，因为 AVG(Basepay) 不能直接写在 WHERE 里面。正确做法是先在子查询中求平均值，再拿外层数据去比较。")
        add_paragraph(sel, "3. 当一个查询里用到多张表，或者表之间有同名字段时，就需要起别名。别名只在当前这条查询语句里有效。")
        add_heading(sel, "（4）实验中遇到的问题和总结", level=2)
        add_paragraph(sel, "这个实验里最容易出错的地方就是把聚合函数直接放进 WHERE 条件。")
        add_paragraph(sel, "报错之后，我把 AVG(Basepay) 单独放到子查询里，再让外层查询去比较，语句就能正常执行。")
        add_paragraph(sel, "做完实验四以后，我对 SELECT、条件查询和聚合函数的使用场景更清楚了，尤其是 WHERE 和子查询的区别。")

        doc.Save()
    finally:
        try:
            doc.Close()
        except Exception:
            pass
        try:
            word.Quit()
        except Exception:
            pass


if __name__ == "__main__":
    build_report()
