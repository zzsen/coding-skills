#!/usr/bin/env node
/**
 * =============================================================================
 * parse-test-results.js — 解析 Phase 4 测试日志
 * =============================================================================
 * 【功能】从 test-results/*.log 最后一次运行批次提取 pass/fail/覆盖率，写 test-counts.json。
 * 【调用阶段】Phase 4；由 run-tests 自动调用，亦可单独执行。
 * 【输入】<plan-dir> 位置参数（argv[2]）
 * 【输出】
 *   <plan-dir>/test-results/test-counts.json
 *   stdout：GO_FAIL=、GO_PASS=、VITEST_*、PASSED=（KEY=VALUE，供 shell eval）
 *   exit 0
 * 【流程】
 *   1. 按分隔符提取各 log 最后一次运行内容
 *   2. 正则解析 go test（--- PASS/FAIL）与 vitest 汇总行
 *   3. 汇总 passed 写入 JSON
 *   4. 输出 KEY=VALUE
 * 【用法】node parse-test-results.js dev-plan/.../
 * =============================================================================
 */

const fs = require('fs');
const path = require('path');

const planDir = process.argv[2];
if (!planDir) {
  console.error('用法: node parse-test-results.js <plan-dir>');
  process.exit(1);
}

const testDir = path.join(planDir, 'test-results');
/** 与 run-tests 写入的分隔符一致，用于多批次日志中取最后一次 */
const SEP = /^>>>>>>>>>> TEST RUN @/;

/**
 * 读取日志中最后一个 TEST RUN 批次之后的内容
 */
function readLastRun(file) {
  if (!fs.existsSync(file)) return '';
  const lines = fs.readFileSync(file, 'utf-8').split('\n');
  let idx = -1;
  for (let i = lines.length - 1; i >= 0; i--) {
    if (SEP.test(lines[i])) { idx = i; break; }
  }
  return idx >= 0 ? lines.slice(idx + 1).join('\n') : fs.readFileSync(file, 'utf-8');
}

/** 解析 go test -v 输出 */
function parseGo(content) {
  const fail = (content.match(/^--- FAIL:/gm) || []).length;
  const pass = (content.match(/^--- PASS:/gm) || []).length;
  const skip = (content.match(/^--- SKIP:/gm) || []).length;
  const cov = content.match(/coverage:\s+([\d.]+%)/);
  return { passed: fail === 0 && pass > 0, fail, pass, skip, coverage: cov ? cov[1] : null };
}

/** 解析 vitest 汇总行（如 "3 passed" / "1 failed"） */
function parseVitest(content) {
  const passMatch = content.match(/(\d+)\s+passed/);
  const failMatch = content.match(/(\d+)\s+failed/);
  const fail = failMatch ? parseInt(failMatch[1], 10) : 0;
  const pass = passMatch ? parseInt(passMatch[1], 10) : 0;
  return { passed: fail === 0, pass, fail };
}

const goLog = path.join(testDir, 'backend-go-test.log');
const vitestLog = path.join(testDir, 'frontend-vitest.log');
const go = parseGo(readLastRun(goLog));
const vitest = parseVitest(readLastRun(vitestLog));

const result = {
  backend_go: go,
  frontend_vitest: vitest,
  passed: (go.fail === 0 && vitest.fail === 0),
  parsed_at: new Date().toISOString(),
  parser: 'node',
};

fs.mkdirSync(testDir, { recursive: true });
fs.writeFileSync(path.join(testDir, 'test-counts.json'), JSON.stringify(result, null, 2), 'utf-8');

console.log(`GO_FAIL=${go.fail}`);
console.log(`GO_PASS=${go.pass}`);
console.log(`VITEST_FAIL=${vitest.fail}`);
console.log(`VITEST_PASS=${vitest.pass}`);
console.log(`PASSED=${result.passed}`);
