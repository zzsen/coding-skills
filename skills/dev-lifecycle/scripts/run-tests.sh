#!/usr/bin/env bash
# =============================================================================
# run-tests.sh — Phase 4 测试执行
# =============================================================================
# 【功能】在 backend 跑 go test、frontend 跑 vitest，追加日志并调用 parse-test-results。
# 【调用阶段】Phase 4（phase4.md）。
# 【输入】<plan-dir> 位置参数（必填）；须在项目根目录执行
# 【输出】
#   <plan-dir>/test-results/backend-go-test.log
#   <plan-dir>/test-results/frontend-vitest.log
#   <plan-dir>/test-results/test-counts.json（由 parse-test-results 生成）
#   stdout：TESTS: pass|fail；exit 0/1
# 【流程】
#   1. 创建 test-results/，写入批次分隔符
#   2. backend: go test -v -coverprofile（存在 go.mod 时）
#   3. frontend: npx vitest run --coverage（存在 package.json 时）
#   4. 调用 parse-test-results.js
#   5. 根据退出码汇总 pass/fail
# 【用法】bash <skill_root>/scripts/run-tests.sh dev-plan/.../
# =============================================================================
set -euo pipefail

PLAN_DIR="${1:?用法: $0 <plan-dir>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

[ -d "$PLAN_DIR" ] || { echo "错误: 目录不存在: $PLAN_DIR" >&2; exit 1; }

TEST_DIR="$PLAN_DIR/test-results"
mkdir -p "$TEST_DIR"
TS=$(date "+%Y-%m-%d %H:%M:%S")
SEP=">>>>>>>>>> TEST RUN @ $TS <<<<<<<<<<"

go_exit=0
vitest_exit=0

echo "=========================================="
echo "  测试执行开始"
echo "=========================================="

# --- 后端 Go 测试 ---
GO_LOG="$TEST_DIR/backend-go-test.log"
echo "$SEP" >> "$GO_LOG"
if [ -d "backend" ] && [ -f "backend/go.mod" ]; then
  echo "[backend] go test ./..."
  (cd backend && go test -v -coverprofile=coverage.out ./... 2>&1 | tee -a "../$GO_LOG") || go_exit=$?
else
  echo "backend/ 跳过" >> "$GO_LOG"
fi

# --- 前端 Vitest ---
VITEST_LOG="$TEST_DIR/frontend-vitest.log"
echo "$SEP" >> "$VITEST_LOG"
if [ -d "frontend" ] && [ -f "frontend/package.json" ]; then
  echo "[frontend] vitest run"
  (cd frontend && npx vitest run --coverage 2>&1 | tee -a "../$VITEST_LOG") || vitest_exit=$?
else
  echo "frontend/ 跳过" >> "$VITEST_LOG"
fi

# --- 解析汇总 ---
echo ""
echo "[解析] parse-test-results ..."
if command -v node >/dev/null 2>&1; then
  node "$SCRIPT_DIR/parse-test-results.js" "$PLAN_DIR" || true
else
  echo "⚠️ node 不可用，跳过 parse-test-results"
fi

overall=0
[ "$go_exit" -ne 0 ] || [ "$vitest_exit" -ne 0 ] && overall=1
[ "$overall" -eq 0 ] && echo "TESTS: pass" || echo "TESTS: fail"
exit "$overall"
