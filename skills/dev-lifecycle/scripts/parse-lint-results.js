#!/usr/bin/env node
/**
 * =============================================================================
 * parse-lint-results.js — 解析 Phase 5 Lint 日志
 * =============================================================================
 * 【功能】从 lint-results/ 四个 log 提取最后一次运行的 errors/warnings，写 lint-counts.json。
 * 【调用阶段】Phase 5；由 run-lint 自动调用。
 * 【输入】<plan-dir>（argv[2]）
 * 【输出】
 *   <plan-dir>/lint-results/lint-counts.json（含 passed、total_errors、各工具 errors）
 *   stdout：GOLINT_ERRORS=、PASSED= 等 KEY=VALUE
 *   errors=-1 表示该检测项未执行
 * 【流程】
 *   1. 读取四份 log，按分隔符取最后批次
 *   2. 分别用 golangci/eslint/vue-tsc/build 解析器正则统计
 *   3. 汇总 passed（全部执行且 errors 均为 0）
 *   4. 写 JSON 并输出 KEY=VALUE
 * 【用法】node parse-lint-results.js dev-plan/.../
 * =============================================================================
 */

const fs = require('fs');
const path = require('path');

const planDir = process.argv[2];
if (!planDir) {
  console.error('用法: node parse-lint-results.js <plan-dir>');
  process.exit(1);
}

const lintDir = path.join(planDir, 'lint-results');
const SEPARATOR_RE = /^>>>>>>>>>> LINT RUN @/;

function fileExists(filePath) {
  return fs.existsSync(filePath);
}

function readFile(filePath) {
  try { return fs.readFileSync(filePath, 'utf-8'); } catch { return ''; }
}

function extractLastRun(content) {
  if (!content) return '';
  const lines = content.split('\n');
  let lastSepIdx = -1;
  for (let i = lines.length - 1; i >= 0; i--) {
    if (SEPARATOR_RE.test(lines[i])) { lastSepIdx = i; break; }
  }
  if (lastSepIdx >= 0 && lastSepIdx < lines.length - 1) {
    return lines.slice(lastSepIdx + 1).join('\n');
  }
  return content;
}

function countRuns(content) {
  if (!content) return 0;
  return (content.match(/^>>>>>>>>>> LINT RUN @/gm) || []).length;
}

function parseGolangciLint(content) {
  if (!content.trim()) return { errors: 0, warnings: 0 };
  // golangci-lint 输出格式: file.go:line:col: message (linter)
  const issueLines = content.match(/^\S+\.go:\d+:\d+:.*$/gm) || [];
  const warnings = issueLines.filter(l => /\bwarning\b/i.test(l)).length;
  return { errors: issueLines.length - warnings, warnings };
}

function parseEslint(content) {
  if (!content.trim()) return { errors: 0, warnings: 0 };
  // 优先匹配汇总行: ✖ N problems (N errors, N warnings)
  const summaryMatch = content.match(/(\d+)\s+errors?\s*,\s*(\d+)\s+warnings?/);
  if (summaryMatch) {
    return { errors: parseInt(summaryMatch[1]), warnings: parseInt(summaryMatch[2]) };
  }
  // 备选: ✖ N problems
  const problemMatch = content.match(/[✖×]\s*(\d+)\s+problems?/);
  if (problemMatch) return { errors: parseInt(problemMatch[1]), warnings: 0 };
  // 逐行统计: "  line:col  error  message  rule"
  const errorLines = (content.match(/^\s+\d+:\d+\s+error\s+/gm) || []).length;
  const warningLines = (content.match(/^\s+\d+:\d+\s+warning\s+/gm) || []).length;
  return { errors: errorLines, warnings: warningLines };
}

function parseVueTsc(content) {
  if (!content.trim()) return { errors: 0 };
  // 汇总行: Found N errors.
  const foundMatch = content.match(/Found\s+(\d+)\s+errors?/);
  if (foundMatch) return { errors: parseInt(foundMatch[1]) };
  // 逐行统计: "- error TS1234:" 或 "error TS1234:"
  const tsErrors = (content.match(/error TS\d+/g) || []).length;
  return { errors: tsErrors };
}

function parseBuild(content) {
  if (!content.trim()) return { errors: 0 };
  // Vite/esbuild: ✘ [ERROR]
  const esbuildErrors = (content.match(/✘\s*\[ERROR\]/g) || []).length;
  if (esbuildErrors > 0) return { errors: esbuildErrors };
  // TypeScript 编译错误: error TS1234
  const tsErrors = (content.match(/error TS\d+/g) || []).length;
  if (tsErrors > 0) return { errors: tsErrors };
  // Vite 构建错误
  if (/error during build/i.test(content)) return { errors: 1 };
  // 行首 ERROR
  const genericErrors = (content.match(/^ERROR\b/gm) || []).length;
  if (genericErrors > 0) return { errors: genericErrors };
  // "exited with N" where N > 0
  const exitMatch = content.match(/exited with (\d+)/);
  if (exitMatch && parseInt(exitMatch[1]) !== 0) return { errors: 1 };
  return { errors: 0 };
}

// ── 主流程 ──────────────────────────────────────
// errors = -1 表示日志文件不存在（未执行对应检测）
// errors = 0  表示已执行且无错误
// errors > 0  表示已执行且存在错误
const filePaths = {
  golangciLint: path.join(lintDir, 'golangci-lint.log'),
  eslint:       path.join(lintDir, 'eslint.log'),
  vueTsc:       path.join(lintDir, 'vue-tsc.log'),
  build:        path.join(lintDir, 'build.log'),
};

const exists = {
  golangciLint: fileExists(filePaths.golangciLint),
  eslint:       fileExists(filePaths.eslint),
  vueTsc:       fileExists(filePaths.vueTsc),
  build:        fileExists(filePaths.build),
};

const raw = {
  golangciLint: exists.golangciLint ? readFile(filePaths.golangciLint) : '',
  eslint:       exists.eslint       ? readFile(filePaths.eslint)       : '',
  vueTsc:       exists.vueTsc       ? readFile(filePaths.vueTsc)       : '',
  build:        exists.build        ? readFile(filePaths.build)        : '',
};

const last = {
  golangciLint: extractLastRun(raw.golangciLint),
  eslint:       extractLastRun(raw.eslint),
  vueTsc:       extractLastRun(raw.vueTsc),
  build:        extractLastRun(raw.build),
};

const parsed = {
  golangciLint: exists.golangciLint ? parseGolangciLint(last.golangciLint) : { errors: -1, warnings: 0 },
  eslint:       exists.eslint       ? parseEslint(last.eslint)             : { errors: -1, warnings: 0 },
  vueTsc:       exists.vueTsc       ? parseVueTsc(last.vueTsc)             : { errors: -1 },
  build:        exists.build        ? parseBuild(last.build)               : { errors: -1 },
};

const runs = {
  golangciLint: countRuns(raw.golangciLint),
  eslint:       countRuns(raw.eslint),
  vueTsc:       countRuns(raw.vueTsc),
  build:        countRuns(raw.build),
};

const allErrors = [parsed.golangciLint.errors, parsed.eslint.errors, parsed.vueTsc.errors, parsed.build.errors];
const hasMissing = allErrors.some(e => e === -1);
const positiveErrors = allErrors.filter(e => e > 0).reduce((a, b) => a + b, 0);
const totalErrors = hasMissing ? -1 : positiveErrors;
// passed 仅在全部执行且全部为 0 时为 true
const passed = !hasMissing && positiveErrors === 0;

const result = {
  golangci_lint: { errors: parsed.golangciLint.errors, warnings: parsed.golangciLint.warnings || 0, runs: runs.golangciLint },
  eslint:        { errors: parsed.eslint.errors, warnings: parsed.eslint.warnings || 0, runs: runs.eslint },
  vue_tsc:       { errors: parsed.vueTsc.errors, runs: runs.vueTsc },
  build:         { errors: parsed.build.errors, runs: runs.build },
  total_errors:  totalErrors,
  passed,
  parsed_at:     new Date().toISOString(),
  parser:        'node',
};

try {
  fs.mkdirSync(lintDir, { recursive: true });
} catch {}
fs.writeFileSync(path.join(lintDir, 'lint-counts.json'), JSON.stringify(result, null, 2), 'utf-8');

// stdout: KEY=VALUE 格式，供 shell 脚本 eval
console.log(`GOLINT_ERRORS=${parsed.golangciLint.errors}`);
console.log(`GOLINT_WARNINGS=${parsed.golangciLint.warnings}`);
console.log(`GOLINT_RUNS=${runs.golangciLint}`);
console.log(`ESLINT_ERRORS=${parsed.eslint.errors}`);
console.log(`ESLINT_WARNINGS=${parsed.eslint.warnings}`);
console.log(`ESLINT_RUNS=${runs.eslint}`);
console.log(`VUETSC_ERRORS=${parsed.vueTsc.errors}`);
console.log(`VUETSC_RUNS=${runs.vueTsc}`);
console.log(`BUILD_ERRORS=${parsed.build.errors}`);
console.log(`BUILD_RUNS=${runs.build}`);
console.log(`TOTAL_ERRORS=${totalErrors}`);
console.log(`PASSED=${passed}`);
