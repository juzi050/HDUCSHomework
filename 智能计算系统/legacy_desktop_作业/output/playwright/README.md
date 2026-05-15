# icourse163 quiz helper

这个脚本只做页面自动化，不提供题目答案，也不会自动提交测验。
支持的完整工作流是：读取网页题目 -> 查询本地授权答案库 -> 回填答案 -> 截图并停在提交前。

## 安装

```powershell
cd C:\Users\86136\Desktop\作业\output\playwright
npm install
```

如果浏览器启动失败，再运行：

```powershell
npx playwright install chromium
```

## 一次性流程

```powershell
npm run icourse:run
```

流程：

1. 脚本打开课程测验页面。
2. 如果需要登录，请在打开的浏览器里完成登录，并确认进入测验页面。
3. 脚本提取题目到 `icourse163/questions.md` 和 `icourse163/questions.json`。
4. 脚本生成 `icourse163/answers.json`。
5. 你把自己的答案填入 `answers.json` 后回到终端按 Enter。
6. 脚本自动勾选答案，截图保存到 `icourse163/after-fill.png`。
7. 请在浏览器里手动检查并自行提交。

## 分步运行

只提取题目：

```powershell
npm run icourse:extract
```

根据答案文件勾选：

```powershell
npm run icourse:fill
```

启动一个可自动接管的 Edge 窗口并回填：

```powershell
npm run icourse:edge-fill
```

这个命令会打开新的 Edge 窗口。你只需要在这个窗口里登录并进入测验页，脚本会自动检测页面就绪，然后按 `icourse163/answers.json` 回填，填完后保留浏览器窗口给你检查。

读取网页并按本地答案库自动回填：

```powershell
npm run icourse:bank
```

默认答案库路径：

```text
C:\Users\86136\Desktop\作业\output\playwright\icourse163\answer-bank.json
```

指定答案库：

```powershell
node .\icourse163_quiz_assist.js bank --bank=C:\Users\86136\Desktop\作业\output\playwright\answer-bank.example.json
```

## 答案格式

```json
{
  "answers": [
    { "question": 1, "select": "A" },
    { "question": 2, "select": ["A", "C"] },
    { "question": 3, "select": 2 }
  ]
}
```

`select` 支持选项字母、从 1 开始的选项序号，或选项文字片段。

## 本地答案库格式

按题干片段匹配：

```json
{
  "bank": [
    { "text": "题干中的一段文字", "answer": "A" },
    { "text": "另一道题的题干片段", "answer": ["A", "C"] }
  ]
}
```

按题号匹配：

```json
{
  "bank": [
    { "question": 1, "answer": "A" },
    { "question": 2, "answer": ["B", "D"] }
  ]
}
```

`answer` 支持选项字母、从 1 开始的选项序号，或选项文字片段。匹配结果会写入 `icourse163/answers.from-bank.json`，没有匹配到的题号会在终端输出。

## 复用已打开的 Chrome

普通 Chrome 不能直接被 Playwright 接管。要复用当前浏览器，需要先用远程调试端口启动 Chrome，例如：

```powershell
chrome.exe --remote-debugging-port=9222 --user-data-dir="$env:TEMP\icourse-debug-profile"
```

然后运行：

```powershell
node .\icourse163_quiz_assist.js run --cdp=http://127.0.0.1:9222
```
