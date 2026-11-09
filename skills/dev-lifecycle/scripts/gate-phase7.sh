#!/usr/bin/env bash
# =============================================================================
# gate-phase7.sh — Phase 7 验收前完整性检查
# =============================================================================
# 【功能】检查 1~7 阶段产物及 lint-counts.json passed 状态，阻断不完整验收。
# 【调用阶段】Phase 7 生成 7.acceptance.md 前。
# 【输入】--plan-dir <path>（必填）
# 【输出】stdout：逐项 ✅/❌ + GATE_PHASE7: pass|block；exit 0/1
# 【流程】
#   1. 检查 1.proposal ~ 7.acceptance.md
#   2. 检查 lint-results/lint-counts.json 且 passed=true
# 【用法】bash .../gate-phase7.sh --plan-dir dev-plan/...
# =============================================================================
set -euo pipefail

PLAN_DIR=""
while [ $# -gt 0 ]; do
  case "$1" in
    --plan-dir) PLAN_DIR="${2:-}"; shift 2 ;;
    -h|--help) echo "用法: $0 --plan-dir <path>"; exit 0 ;;
    *) echo "未知参数: $1" >&2; exit 1 ;;
  esac
done

[ -n "$PLAN_DIR" ] && [ -d "$PLAN_DIR" ] || { echo "错误: 无效 --plan-dir" >&2; exit 1; }

fail=0
require() {
  if [ -f "$1" ]; then echo "✅ $2"
  else echo "❌ $2 ($1)"; fail=1; fi
}

require "$PLAN_DIR/1.proposal.md" "1.proposal.md"
require "$PLAN_DIR/2.plan.md" "2.plan.md"
require "$PLAN_DIR/3.dev.md" "3.dev.md"
require "$PLAN_DIR/4.test-case.md" "4.test-case.md"
require "$PLAN_DIR/5.lint-report.md" "5.lint-report.md"
require "$PLAN_DIR/6.docs-update.md" "6.docs-update.md"
require "$PLAN_DIR/7.acceptance.md" "7.acceptance.md"
require "$PLAN_DIR/lint-results/lint-counts.json" "lint-counts.json"

if [ -f "$PLAN_DIR/lint-results/lint-counts.json" ]; then
  if grep -qE '"passed"\s*:\s*true' "$PLAN_DIR/lint-results/lint-counts.json"; then
    echo "✅ lint passed=true"
  else
    echo "❌ lint passed 不为 true"
    fail=1
  fi
fi

[ "$fail" -eq 0 ] && echo "GATE_PHASE7: pass" || echo "GATE_PHASE7: block"
exit "$fail"
