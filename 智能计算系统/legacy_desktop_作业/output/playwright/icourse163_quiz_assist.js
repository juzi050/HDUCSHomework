const fs = require('node:fs');
const path = require('node:path');
const readline = require('node:readline/promises');
const { stdin: input, stdout: output } = require('node:process');
const { chromium } = require('playwright');

const DEFAULT_URL =
  'https://www.icourse163.org/learn/HDU-1472771170?tid=1476670444#/learn/quiz?id=1247839085';

const ROOT_DIR = __dirname;
const ARTIFACT_DIR = path.join(ROOT_DIR, 'icourse163');
const PROFILE_DIR = path.join(ARTIFACT_DIR, 'chrome-profile');
const QUESTIONS_JSON = path.join(ARTIFACT_DIR, 'questions.json');
const QUESTIONS_MD = path.join(ARTIFACT_DIR, 'questions.md');
const ANSWERS_JSON = path.join(ARTIFACT_DIR, 'answers.json');
const ANSWER_BANK_JSON = path.join(ARTIFACT_DIR, 'answer-bank.json');
const ANSWERS_FROM_BANK_JSON = path.join(ARTIFACT_DIR, 'answers.from-bank.json');
const SCREENSHOT_PATH = path.join(ARTIFACT_DIR, 'after-fill.png');

function parseArgs(argv) {
  const args = { mode: argv[2] || 'run', url: DEFAULT_URL, headed: true };
  for (const raw of argv.slice(3)) {
    if (raw === '--headless') args.headed = false;
    else if (raw.startsWith('--url=')) args.url = raw.slice('--url='.length);
    else if (raw.startsWith('--answers=')) args.answers = path.resolve(raw.slice('--answers='.length));
    else if (raw.startsWith('--bank=')) args.bank = path.resolve(raw.slice('--bank='.length));
    else if (raw.startsWith('--profile=')) args.profile = path.resolve(raw.slice('--profile='.length));
    else if (raw.startsWith('--cdp=')) args.cdp = raw.slice('--cdp='.length);
    else if (raw === '--poll-ready') args.pollReady = true;
    else if (raw === '--no-final-prompt') args.noFinalPrompt = true;
    else if (raw === '--keep-open') args.keepOpen = true;
    else if (raw === '--help' || raw === '-h') args.mode = 'help';
  }
  return args;
}

function ensureDir(dir) {
  fs.mkdirSync(dir, { recursive: true });
}

function readJson(file) {
  return JSON.parse(fs.readFileSync(file, 'utf8'));
}

function writeJson(file, data) {
  fs.writeFileSync(file, `${JSON.stringify(data, null, 2)}\n`, 'utf8');
}

function normalizeAnswerPayload(payload) {
  const raw = Array.isArray(payload) ? payload : payload.answers || payload;
  if (Array.isArray(raw)) {
    return raw
      .filter((item) => item && item.question != null)
      .map((item) => ({
        question: Number(item.question),
        select: Array.isArray(item.select) ? item.select : [item.select],
      }))
      .filter((item) => item.question > 0 && item.select.some((value) => value !== '' && value != null));
  }

  return Object.entries(raw)
    .map(([question, select]) => ({
      question: Number(question),
      select: Array.isArray(select) ? select : [select],
    }))
    .filter((item) => item.question > 0 && item.select.some((value) => value !== '' && value != null));
}

function normalizeBankPayload(payload) {
  const raw = Array.isArray(payload) ? payload : payload.bank || payload.items || payload.answers || payload;

  if (Array.isArray(raw)) {
    return raw
      .map((item) => ({
        question: item.question == null ? null : Number(item.question),
        text: item.text || item.prompt || item.keyword || item.questionText || '',
        select: item.select ?? item.answer ?? item.answers ?? item.correct,
      }))
      .map((item) => ({
        ...item,
        select: Array.isArray(item.select) ? item.select : [item.select],
      }))
      .filter((item) => (item.question > 0 || item.text) && item.select.some((value) => value !== '' && value != null));
  }

  return Object.entries(raw)
    .map(([text, select]) => ({
      question: /^\d+$/.test(text) ? Number(text) : null,
      text: /^\d+$/.test(text) ? '' : text,
      select: Array.isArray(select) ? select : [select],
    }))
    .filter((item) => (item.question > 0 || item.text) && item.select.some((value) => value !== '' && value != null));
}

function normalizeMatchText(value) {
  return String(value || '')
    .toLowerCase()
    .replace(/\s+/g, '')
    .replace(/[^\p{L}\p{N}]+/gu, '');
}

function commonSubstringScore(a, b) {
  if (!a || !b) return 0;
  const short = a.length <= b.length ? a : b;
  const long = a.length <= b.length ? b : a;
  const maxWindow = Math.min(short.length, 80);

  for (let size = maxWindow; size >= 8; size -= 1) {
    for (let start = 0; start + size <= short.length; start += 1) {
      if (long.includes(short.slice(start, start + size))) {
        return size / Math.max(a.length, b.length);
      }
    }
  }
  return 0;
}

function scoreBankItem(question, item) {
  if (item.question && item.question === question.number) return 10000;
  if (!item.text) return 0;

  const questionText = normalizeMatchText(
    `${question.text}\n${question.options.map((option) => option.cleanText || option.text).join('\n')}`,
  );
  const bankText = normalizeMatchText(item.text);
  if (!questionText || !bankText) return 0;
  if (questionText === bankText) return 9000;
  if (questionText.includes(bankText) || bankText.includes(questionText)) {
    return 5000 + Math.min(questionText.length, bankText.length);
  }

  const ratio = commonSubstringScore(questionText, bankText);
  return ratio >= 0.25 ? Math.floor(ratio * 1000) : 0;
}

function resolveAnswersFromBank(snapshot, bankItems) {
  const answers = [];
  const unmatched = [];

  for (const question of snapshot.questions) {
    const matches = bankItems
      .map((item) => ({ item, score: scoreBankItem(question, item) }))
      .filter((match) => match.score > 0)
      .sort((a, b) => b.score - a.score);

    const best = matches[0];
    if (!best) {
      unmatched.push({ question: question.number, text: question.text });
      continue;
    }

    answers.push({
      question: question.number,
      select: best.item.select,
      matchedBy: best.item.question ? 'question-number' : 'question-text',
      score: best.score,
      sourceText: best.item.text || `question ${best.item.question}`,
    });
  }

  return { answers, unmatched };
}

async function pause(rl, message) {
  await rl.question(`${message}\n`);
}

async function launchContext(args) {
  if (args.cdp) {
    const browser = await chromium.connectOverCDP(args.cdp);
    const context = browser.contexts()[0] || (await browser.newContext());
    return { context, close: () => (args.keepOpen ? Promise.resolve() : browser.close()) };
  }

  const profile = args.profile || PROFILE_DIR;
  const common = {
    headless: !args.headed,
    viewport: { width: 1440, height: 1000 },
    acceptDownloads: true,
    args: ['--disable-blink-features=AutomationControlled'],
  };

  try {
    const context = await chromium.launchPersistentContext(profile, {
      ...common,
      channel: process.env.PW_CHANNEL || 'chrome',
    });
    return { context, close: () => context.close() };
  } catch (error) {
    if (!String(error.message || '').includes('chrome')) throw error;
    const context = await chromium.launchPersistentContext(profile, common);
    return { context, close: () => context.close() };
  }
}

async function openQuizPage(context, url) {
  let page = context.pages().find((candidate) => candidate.url().includes('icourse163.org'));
  if (!page) page = context.pages()[0] || (await context.newPage());

  if (!page.url().includes('icourse163.org') || !page.url().includes('quiz')) {
    await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 60000 });
  }

  await page.bringToFront();
  await page.waitForTimeout(2500);
  return page;
}

async function waitForReady(page, rl, args = {}) {
  for (;;) {
    const state = await page.evaluate(() => {
      const text = document.body?.innerText || '';
      const choiceCount = document.querySelectorAll(
        'input[type=radio],input[type=checkbox],[role=radio],[role=checkbox]',
      ).length;
      return {
        title: document.title,
        url: location.href,
        choiceCount,
        hasLoginText: /登录|登陆|手机号|网易/.test(text),
        hasQuizText: /测验|作业|单选|多选|判断|题/.test(text),
        textLength: text.trim().length,
      };
    });

    if (state.choiceCount > 0 || (state.hasQuizText && state.textLength > 80)) {
      console.log(`Page looks ready: ${state.title}`);
      return;
    }

    console.log('The quiz page is not ready yet.');
    console.log(`Current URL: ${state.url}`);
    if (args.pollReady) {
      console.log('Waiting for login/page readiness...');
      await page.waitForTimeout(3000);
    } else {
      await pause(rl, 'Log in and open the quiz page in the browser, then press Enter here.');
    }
    await page.waitForTimeout(1500);
  }
}

async function markAndExtract(page) {
  return page.evaluate(() => {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const markPrefix = `pwq-${Date.now()}-${Math.random().toString(36).slice(2)}-`;

    const norm = (value) =>
      String(value || '')
        .replace(/\u00a0/g, ' ')
        .replace(/[ \t\r\f\v]+/g, ' ')
        .replace(/\n[ \t]+/g, '\n')
        .replace(/\n{3,}/g, '\n\n')
        .trim();

    const visible = (el) => {
      if (!el || !(el instanceof Element)) return false;
      const style = window.getComputedStyle(el);
      if (style.visibility === 'hidden' || style.display === 'none' || Number(style.opacity) === 0) return false;
      const rect = el.getBoundingClientRect();
      return rect.width > 0 && rect.height > 0;
    };

    const textOf = (el) => norm(el?.innerText || el?.textContent || el?.getAttribute?.('aria-label') || '');

    const controlSelector = 'input[type=radio],input[type=checkbox],[role=radio],[role=checkbox]';

    const controlCount = (el) => el.querySelectorAll(controlSelector).length;

    const clickableForInput = (input) => {
      const label = input.closest('label');
      if (label && textOf(label)) return label;
      if (input.id && window.CSS?.escape) {
        const forLabel = document.querySelector(`label[for="${CSS.escape(input.id)}"]`);
        if (forLabel && textOf(forLabel)) return forLabel;
      }
      let el = input.parentElement;
      while (el && el !== document.body) {
        if (textOf(el) && controlCount(el) <= 1) return el;
        el = el.parentElement;
      }
      return input;
    };

    const optionTextFromInput = (input, clickable) => {
      let text = textOf(clickable);
      if (!text && input.id && window.CSS?.escape) {
        const forLabel = document.querySelector(`label[for="${CSS.escape(input.id)}"]`);
        text = textOf(forLabel);
      }
      return text || textOf(input);
    };

    const makeOption = (clickable, control, source) => {
      if (!clickable || !visible(clickable)) return null;
      const text = source === 'input' ? optionTextFromInput(control, clickable) : textOf(clickable);
      if (!text || text.length > 800) return null;
      return {
        clickable,
        control,
        source,
        text,
        type:
          control?.getAttribute?.('type') === 'checkbox' || control?.getAttribute?.('role') === 'checkbox'
            ? 'multiple'
            : 'single',
      };
    };

    const optionMap = new Map();
    for (const input of Array.from(document.querySelectorAll('input[type=radio],input[type=checkbox]'))) {
      const clickable = clickableForInput(input);
      const option = makeOption(clickable, input, 'input');
      if (option) optionMap.set(clickable, option);
    }

    for (const roleEl of Array.from(document.querySelectorAll('[role=radio],[role=checkbox]'))) {
      const option = makeOption(roleEl, roleEl, 'role');
      if (option) optionMap.set(roleEl, option);
    }

    const textOptionPattern = /^[A-Ha-h][\.\u3001\uff0e\uff1a:\uff09\)]\s*\S+/;
    const textCandidates = Array.from(document.querySelectorAll('label, li, div, p, span')).filter((el) => {
      const text = textOf(el);
      if (!visible(el) || !textOptionPattern.test(text) || text.length > 500) return false;
      return !Array.from(el.children).some((child) => textOptionPattern.test(textOf(child)));
    });

    for (const candidate of textCandidates) {
      if (![...optionMap.keys()].some((existing) => existing === candidate || existing.contains(candidate))) {
        const option = makeOption(candidate, null, 'text');
        if (option) optionMap.set(candidate, option);
      }
    }

    let options = [...optionMap.values()].filter((option, index, all) => {
      return !all.some(
        (other, otherIndex) =>
          otherIndex !== index &&
          other.clickable.contains(option.clickable) &&
          textOf(other.clickable) === textOf(option.clickable),
      );
    });

    const countOptionsIn = (container) => options.filter((option) => container.contains(option.clickable)).length;

    let containers = Array.from(
      document.querySelectorAll(
        '[class*="question"],[class*="Question"],[class*="quiz"],[class*="Quiz"],[class*="problem"],[id*="question"],[id*="quiz"]',
      ),
    ).filter((el) => visible(el) && countOptionsIn(el) >= 2 && textOf(el).length > 20);

    containers = containers.filter(
      (container) =>
        !containers.some(
          (other) => other !== container && container.contains(other) && countOptionsIn(other) >= 2,
        ),
    );

    if (!containers.length) {
      const rootSet = new Set();
      for (const option of options) {
        let el = option.clickable.parentElement;
        let current = null;
        while (el && el !== document.body) {
          if (countOptionsIn(el) >= 2 && textOf(el).length > 20) {
            current = el;
            break;
          }
          el = el.parentElement;
        }

        while (current?.parentElement && current.parentElement !== document.body) {
          const parent = current.parentElement;
          if (countOptionsIn(parent) !== countOptionsIn(current)) break;
          const diff = textOf(parent).length - textOf(current).length;
          const cls = String(parent.className || '').toLowerCase();
          if (/question|quiz|problem/.test(cls) || (diff > 8 && diff < 2000)) current = parent;
          else break;
        }

        if (current) rootSet.add(current);
      }
      containers = [...rootSet];
    }

    containers.sort((a, b) => a.getBoundingClientRect().top - b.getBoundingClientRect().top);

    const stripChoicePrefix = (text) => norm(text).replace(/^[A-Ha-h][\.\u3001\uff0e\uff1a:\uff09\)]\s*/, '');

    const questions = containers
      .map((container, questionIndex) => {
        const inContainer = options
          .filter((option) => container.contains(option.clickable))
          .sort((a, b) => a.clickable.getBoundingClientRect().top - b.clickable.getBoundingClientRect().top);

        if (inContainer.length < 2) return null;

        const optionItems = inContainer.map((option, optionIndex) => {
          const text = norm(option.text);
          const explicitLetter = text.match(/^([A-Ha-h])[\.\u3001\uff0e\uff1a:\uff09\)]/);
          const letter = explicitLetter ? explicitLetter[1].toUpperCase() : letters[optionIndex] || String(optionIndex + 1);
          const domId = `${markPrefix}${questionIndex}-${optionIndex}`;
          option.clickable.setAttribute('data-pw-quiz-option', domId);
          return {
            domId,
            letter,
            index: optionIndex + 1,
            text,
            cleanText: stripChoicePrefix(text),
            kind: option.type,
          };
        });

        let questionText = textOf(container);
        for (const option of [...optionItems].sort((a, b) => b.text.length - a.text.length)) {
          questionText = norm(questionText.replace(option.text, '\n'));
        }

        return {
          number: questionIndex + 1,
          type: optionItems.some((option) => option.kind === 'multiple') ? 'multiple' : 'single',
          text: questionText,
          options: optionItems,
        };
      })
      .filter(Boolean);

    return {
      title: document.title,
      url: location.href,
      extractedAt: new Date().toISOString(),
      questionCount: questions.length,
      questions,
    };
  });
}

function renderMarkdown(snapshot) {
  const lines = [
    `# ${snapshot.title || 'icourse163 quiz'}`,
    '',
    `URL: ${snapshot.url}`,
    `Extracted: ${snapshot.extractedAt}`,
    `Questions: ${snapshot.questionCount}`,
    '',
  ];

  for (const question of snapshot.questions) {
    lines.push(`## ${question.number}. ${question.type}`);
    lines.push('');
    lines.push(question.text || '(no question text extracted)');
    lines.push('');
    for (const option of question.options) {
      lines.push(`- ${option.letter}. ${option.cleanText || option.text}`);
    }
    lines.push('');
  }

  return `${lines.join('\n')}\n`;
}

function writeQuestionArtifacts(snapshot) {
  ensureDir(ARTIFACT_DIR);
  writeJson(QUESTIONS_JSON, snapshot);
  fs.writeFileSync(QUESTIONS_MD, renderMarkdown(snapshot), 'utf8');

  if (!fs.existsSync(ANSWERS_JSON)) {
    writeJson(ANSWERS_JSON, {
      answers: snapshot.questions.map((question) => ({
        question: question.number,
        select: question.type === 'multiple' ? [] : '',
      })),
    });
  }

  if (!fs.existsSync(ANSWER_BANK_JSON)) {
    writeJson(ANSWER_BANK_JSON, {
      bank: snapshot.questions.map((question) => ({
        text: question.text.slice(0, 120),
        answer: question.type === 'multiple' ? [] : '',
      })),
    });
  }
}

function pickOption(question, rawSelection) {
  const selection = String(rawSelection).trim();
  if (!selection) return null;

  if (/^\d+$/.test(selection)) {
    const index = Number(selection);
    return question.options.find((option) => option.index === index);
  }

  if (/^[A-Za-z]$/.test(selection)) {
    const letter = selection.toUpperCase();
    return question.options.find((option) => option.letter === letter);
  }

  const lowered = selection.toLowerCase();
  return question.options.find(
    (option) =>
      option.cleanText.toLowerCase().includes(lowered) || option.text.toLowerCase().includes(lowered),
  );
}

async function fillAnswers(page, answers) {
  const snapshot = await markAndExtract(page);
  const results = [];

  for (const item of answers) {
    const question = snapshot.questions.find((candidate) => candidate.number === item.question);
    if (!question) {
      results.push({ question: item.question, status: 'missing-question' });
      continue;
    }

    for (const selection of item.select) {
      const option = pickOption(question, selection);
      if (!option) {
        results.push({ question: item.question, selection, status: 'missing-option' });
        continue;
      }

      const locator = page.locator(`[data-pw-quiz-option="${option.domId}"]`).first();
      try {
        await locator.scrollIntoViewIfNeeded({ timeout: 5000 });
        await locator.click({ timeout: 5000 });
        await page.waitForTimeout(250);
        results.push({
          question: item.question,
          selection,
          option: `${option.letter}. ${option.cleanText || option.text}`,
          status: 'clicked',
        });
      } catch (error) {
        results.push({
          question: item.question,
          selection,
          option: `${option.letter}. ${option.cleanText || option.text}`,
          status: 'click-failed',
          error: String(error.message || error),
        });
      }
    }
  }

  return results;
}

function printFillResults(results) {
  const clicked = results.filter((result) => result.status === 'clicked').length;
  console.log(`Clicked ${clicked} answer option(s).`);
  for (const result of results) {
    const suffix = result.option ? ` -> ${result.option}` : '';
    console.log(`Q${result.question} ${result.status}${suffix}`);
  }
}

function printHelp() {
  console.log(`
Usage:
  node icourse163_quiz_assist.js run
  node icourse163_quiz_assist.js extract
  node icourse163_quiz_assist.js fill --answers=icourse163/answers.json
  node icourse163_quiz_assist.js bank --bank=icourse163/answer-bank.json

Options:
  --url=<quiz-url>       Override quiz URL
  --answers=<file>       Answer file path
  --bank=<file>          Local authorized answer bank path
  --profile=<dir>        Browser profile directory
  --cdp=<endpoint>       Connect to an existing Chrome remote debugging endpoint
  --poll-ready           Keep polling until the quiz page is ready
  --no-final-prompt      Do not wait for Enter before ending the script
  --keep-open            Keep a CDP-connected external browser open after filling
  --headless             Run without a visible browser

Answer formats:
  { "answers": [{ "question": 1, "select": "A" }] }
  { "answers": [{ "question": 2, "select": ["A", "C"] }] }
  { "1": "A", "2": ["B", "D"] }

Local bank formats:
  { "bank": [{ "text": "question text fragment", "answer": "A" }] }
  { "bank": [{ "question": 1, "answer": ["A", "C"] }] }
`);
}

async function main() {
  const args = parseArgs(process.argv);
  if (args.mode === 'help') {
    printHelp();
    return;
  }

  if (!['run', 'extract', 'fill', 'bank'].includes(args.mode)) {
    throw new Error(`Unknown mode: ${args.mode}`);
  }

  ensureDir(ARTIFACT_DIR);
  const rl = readline.createInterface({ input, output });
  const { context, close } = await launchContext(args);

  try {
    const page = await openQuizPage(context, args.url);
    await waitForReady(page, rl, args);

    if (args.mode === 'extract' || args.mode === 'run' || args.mode === 'bank') {
      const snapshot = await markAndExtract(page);
      writeQuestionArtifacts(snapshot);
      console.log(`Extracted ${snapshot.questionCount} question(s).`);
      console.log(`Questions JSON: ${QUESTIONS_JSON}`);
      console.log(`Questions MD:   ${QUESTIONS_MD}`);
      console.log(`Answers file:   ${ANSWERS_JSON}`);

      if (args.mode === 'bank') {
        const bankFile = args.bank || ANSWER_BANK_JSON;
        if (!fs.existsSync(bankFile)) {
          throw new Error(`Answer bank not found: ${bankFile}`);
        }

        const bankItems = normalizeBankPayload(readJson(bankFile));
        const resolved = resolveAnswersFromBank(snapshot, bankItems);
        writeJson(ANSWERS_FROM_BANK_JSON, resolved);
        console.log(`Matched ${resolved.answers.length}/${snapshot.questionCount} question(s) from local bank.`);
        console.log(`Resolved answers: ${ANSWERS_FROM_BANK_JSON}`);
        if (resolved.unmatched.length) {
          console.log(`Unmatched question(s): ${resolved.unmatched.map((item) => item.question).join(', ')}`);
        }

        if (resolved.answers.length) {
          const results = await fillAnswers(page, resolved.answers);
          printFillResults(results);
        } else {
          console.log('No matched answers found. Nothing was clicked.');
        }

        await page.screenshot({ path: SCREENSHOT_PATH, fullPage: true });
        console.log(`Screenshot: ${SCREENSHOT_PATH}`);
        console.log('Review the browser manually. This script intentionally does not submit the quiz.');
      }
    }

    if (args.mode === 'run') {
      await pause(rl, `Fill your own answers in ${ANSWERS_JSON}, save it, then press Enter here.`);
    }

    if (args.mode === 'fill' || args.mode === 'run') {
      const answersFile = args.answers || ANSWERS_JSON;
      if (!fs.existsSync(answersFile)) {
        throw new Error(`Answers file not found: ${answersFile}`);
      }

      const answers = normalizeAnswerPayload(readJson(answersFile));
      if (!answers.length) {
        console.log('No answers found in the answer file. Nothing was clicked.');
      } else {
        const results = await fillAnswers(page, answers);
        printFillResults(results);
      }

      await page.screenshot({ path: SCREENSHOT_PATH, fullPage: true });
      console.log(`Screenshot: ${SCREENSHOT_PATH}`);
      console.log('Review the browser manually. This script intentionally does not submit the quiz.');
    }

    if (!args.noFinalPrompt) {
      await pause(rl, 'Press Enter to close the browser.');
    }
  } finally {
    rl.close();
    await close();
    if (args.keepOpen) {
      setTimeout(() => process.exit(process.exitCode || 0), 50);
    }
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
