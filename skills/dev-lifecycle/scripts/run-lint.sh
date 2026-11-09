#!/bin/bash
# =============================================================================
# run-lint.sh — Phase 5 Lint 检测与报告生成
# =============================================================================
# 【功能】执行 backend/frontend 四项 Lint/构建检测，追加日志，解析并生成 5.lint-report.md。
# 【调用阶段】Phase 5（phase5.md）。
# 【输入】<plan-dir> 位置参数；须在项目根目录执行
# 【输出】
#   lint-results/*.log、lint-counts.json、5.lint-report.md
#   stdout：执行进度与总体结果；exit 0（即使存在 Lint 错误，脚本本身正常结束）
# 【流程】
#   1. 创建 lint-results/，写入批次分隔符
#   2. golangci-lint → eslint → vue-tsc -b → npm run build
#   3. 调用 parse-lint-results（node/go/python 自动选择）
#   4. 根据 lint-counts 生成 5.lint-report.md
# 【用法】bash <skill_root>/scripts/run-lint.sh dev-plan/.../
# =============================================================================

set -euo pipefail

PLAN_DIR="${1:?用法: $0 <plan-dir>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ ! -d "$PLAN_DIR" ]; then
    echo "错误: 目录 $PLAN_DIR 不存在"
    exit 1
fi

LINT_DIR="$PLAN_DIR/lint-results"
mkdir -p "$LINT_DIR"

REPORT_FILE="$PLAN_DIR/5.lint-report.md"

GOLINT_LOG="$LINT_DIR/golangci-lint.log"
ESLINT_LOG="$LINT_DIR/eslint.log"
VUETSC_LOG="$LINT_DIR/vue-tsc.log"
BUILD_LOG="$LINT_DIR/build.log"

TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
RUN_SEPARATOR=">>>>>>>>>> LINT RUN @ $TIMESTAMP <<<<<<<<<<"

golint_exit=0
eslint_exit=0
vuetsc_exit=0
build_exit=0

# 计算本次是第几次运行
count_runs() {
    local log_file="$1"
    if [ -f "$log_file" ]; then
        grep -c "^>>>>>>>>>> LINT RUN @" "$log_file" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

TOTAL_RUN=$(($(count_runs "$GOLINT_LOG") + 1))

echo "=========================================="
echo "  Lint 检测开始（第 $TOTAL_RUN 次运行）"
echo "=========================================="
echo ""

# ── 1. golangci-lint（backend）──────────────────────────
echo "[1/4] 运行 golangci-lint (backend/) ..."
echo "$RUN_SEPARATOR" >> "$GOLINT_LOG"
if [ -d "backend" ]; then
    cd backend
    if command -v golangci-lint &> /dev/null; then
        golangci-lint run ./... 2>&1 | tee -a "../$GOLINT_LOG" || golint_exit=$?
    else
        echo "golangci-lint 未安装，尝试使用 go vet" | tee -a "../$GOLINT_LOG"
        go vet ./... 2>&1 | tee -a "../$GOLINT_LOG" || golint_exit=$?
    fi
    cd ..
else
    echo "backend/ 目录不存在，跳过" >> "$GOLINT_LOG"
fi
echo ""

# ── 2. ESLint ─────────────────────────────────
echo "[2/4] 运行 ESLint (frontend/) ..."
echo "$RUN_SEPARATOR" >> "$ESLINT_LOG"
if [ -d "frontend" ]; then
    cd frontend
    npm run lint 2>&1 | tee -a "../$ESLINT_LOG" || eslint_exit=$?
    cd ..
else
    echo "frontend/ 目录不存在，跳过" >> "$ESLINT_LOG"
fi
echo ""

# ── 3. vue-tsc ────────────────────────────────
echo "[3/4] 运行 vue-tsc (frontend/) ..."
echo "$RUN_SEPARATOR" >> "$VUETSC_LOG"
if [ -d "frontend" ]; then
    cd frontend
    npx vue-tsc -b --noEmit 2>&1 | tee -a "../$VUETSC_LOG" || vuetsc_exit=$?
    cd ..
else
    echo "frontend/ 目录不存在，跳过" >> "$VUETSC_LOG"
fi
echo ""

# ── 4. npm run build ──────────────────────────
echo "[4/4] 运行 npm run build (frontend/) ..."
echo "$RUN_SEPARATOR" >> "$BUILD_LOG"
if [ -d "frontend" ]; then
    cd frontend
    npm run build 2>&1 | tee -a "../$BUILD_LOG" || build_exit=$?
    cd ..
else
    echo "frontend/ 目录不存在，跳过" >> "$BUILD_LOG"
fi
echo ""

# ── 调用解析脚本（node → go → python 优先级）────────────
echo "[解析] 调用 parse-lint-results 提取错误数量 ..."

GOLINT_ERRORS=-1
GOLINT_WARNINGS=0
GOLINT_RUNS=0
ESLINT_ERRORS=-1
ESLINT_WARNINGS=0
ESLINT_RUNS=0
VUETSC_ERRORS=-1
VUETSC_RUNS=0
BUILD_ERRORS=-1
BUILD_RUNS=0
TOTAL_ERRORS=-1
PASSED=false

PARSE_OK=false

if command -v node &> /dev/null; then
    echo "  使用 Node.js 解析 ..."
    PARSE_OUTPUT=$(node "$SCRIPT_DIR/parse-lint-results.js" "$PLAN_DIR" 2>/dev/null) && PARSE_OK=true
elif command -v go &> /dev/null; then
    echo "  使用 Go 解析 ..."
    PARSE_OUTPUT=$(go run "$SCRIPT_DIR/parse-lint-results.go" "$PLAN_DIR" 2>/dev/null) && PARSE_OK=true
elif command -v python3 &> /dev/null; then
    echo "  使用 Python3 解析 ..."
    PARSE_OUTPUT=$(python3 "$SCRIPT_DIR/parse-lint-results.py" "$PLAN_DIR" 2>/dev/null) && PARSE_OK=true
elif command -v python &> /dev/null; then
    echo "  使用 Python 解析 ..."
    PARSE_OUTPUT=$(python "$SCRIPT_DIR/parse-lint-results.py" "$PLAN_DIR" 2>/dev/null) && PARSE_OK=true
fi

if [ "$PARSE_OK" = true ] && [ -n "$PARSE_OUTPUT" ]; then
    eval "$PARSE_OUTPUT"
    echo "  解析完成 → lint-counts.json 已生成"
else
    echo "  ⚠️ 解析脚本未成功运行，使用退出码作为降级判断"
    [ "$golint_exit" -ne 0 ] && GOLINT_ERRORS=1
    [ "$eslint_exit" -ne 0 ] && ESLINT_ERRORS=1
    [ "$vuetsc_exit" -ne 0 ] && VUETSC_ERRORS=1
    [ "$build_exit" -ne 0 ] && BUILD_ERRORS=1
    TOTAL_ERRORS=$((GOLINT_ERRORS + ESLINT_ERRORS + VUETSC_ERRORS + BUILD_ERRORS))
    [ "$TOTAL_ERRORS" -eq 0 ] && PASSED=true
    GOLINT_RUNS=$(count_runs "$GOLINT_LOG")
    ESLINT_RUNS=$(count_runs "$ESLINT_LOG")
    VUETSC_RUNS=$(count_runs "$VUETSC_LOG")
    BUILD_RUNS=$(count_runs "$BUILD_LOG")
fi
echo ""

# ── 根据 lint-counts.json 生成 5.lint-report.md ─────────

status_icon() {
    if [ "$1" -eq -1 ]; then echo "⚠️ 未执行"
    elif [ "$1" -eq 0 ]; then echo "✅ 通过"
    else echo "❌ 未通过"
    fi
}

golint_status=$(status_icon "$GOLINT_ERRORS")
eslint_status=$(status_icon "$ESLINT_ERRORS")
vuetsc_status=$(status_icon "$VUETSC_ERRORS")
build_status=$(status_icon "$BUILD_ERRORS")

if [ "$PASSED" = "true" ]; then
    overall_status="✅ 全部通过"
elif [ "$TOTAL_ERRORS" -eq -1 ]; then
    overall_status="⚠️ 存在未执行的检测项"
else
    overall_status="❌ 存在未通过项（共 $TOTAL_ERRORS 个错误）"
fi

# 提取最后一次运行的内容用于错误详情
extract_last_run() {
    local log_file="$1"
    if [ -f "$log_file" ]; then
        awk '/^>>>>>>>>>> LINT RUN @/{buf=""; next} {buf=buf"\n"$0} END{sub(/^\n/,"",buf); print buf}' "$log_file"
    else
        echo ""
    fi
}

last_golint=$(extract_last_run "$GOLINT_LOG")
last_eslint=$(extract_last_run "$ESLINT_LOG")
last_vuetsc=$(extract_last_run "$VUETSC_LOG")
last_build=$(extract_last_run "$BUILD_LOG")

# 保留已有的生成时间
CREATED_TIME="$TIMESTAMP"
if [ -f "$REPORT_FILE" ]; then
    EXISTING_TIME=$(grep '^> 生成时间：' "$REPORT_FILE" | head -1 | sed 's/^> 生成时间：//')
    if [ -n "$EXISTING_TIME" ]; then
        CREATED_TIME="$EXISTING_TIME"
    fi
fi

cat > "$REPORT_FILE" << REPORT_EOF
# Lint 检测汇总报告

> 生成时间：$CREATED_TIME
> 最后更新：$TIMESTAMP
> 计划目录：$PLAN_DIR
> 本次为第 $TOTAL_RUN 次运行
> 错误数量来源：parse-lint-results 脚本正则提取（lint-counts.json）

## 总体结果：$overall_status

## 检测明细

| 检测项 | 状态 | 错误数 | 警告数 | 退出码 | 累计运行次数 | 日志文件 |
|--------|------|--------|--------|--------|-------------|----------|
| golangci-lint (后端) | $golint_status | $GOLINT_ERRORS | $GOLINT_WARNINGS | $golint_exit | $GOLINT_RUNS | lint-results/golangci-lint.log |
| ESLint (前端) | $eslint_status | $ESLINT_ERRORS | $ESLINT_WARNINGS | $eslint_exit | $ESLINT_RUNS | lint-results/eslint.log |
| vue-tsc (前端类型检查) | $vuetsc_status | $VUETSC_ERRORS | 0 | $vuetsc_exit | $VUETSC_RUNS | lint-results/vue-tsc.log |
| npm run build (前端构建) | $build_status | $BUILD_ERRORS | 0 | $build_exit | $BUILD_RUNS | lint-results/build.log |

## 错误详情（仅最后一次运行）

### golangci-lint

\`\`\`
$(if [ "$GOLINT_ERRORS" -eq -1 ]; then echo "日志文件不存在，未执行 golangci-lint"; elif [ "$GOLINT_ERRORS" -gt 0 ]; then echo "$last_golint"; else echo "无错误"; fi)
\`\`\`

### ESLint

\`\`\`
$(if [ "$ESLINT_ERRORS" -eq -1 ]; then echo "日志文件不存在，未执行 ESLint"; elif [ "$ESLINT_ERRORS" -gt 0 ]; then echo "$last_eslint"; else echo "无错误"; fi)
\`\`\`

### vue-tsc

\`\`\`
$(if [ "$VUETSC_ERRORS" -eq -1 ]; then echo "日志文件不存在，未执行 vue-tsc"; elif [ "$VUETSC_ERRORS" -gt 0 ]; then echo "$last_vuetsc"; else echo "无错误"; fi)
\`\`\`

### npm run build

\`\`\`
$(if [ "$BUILD_ERRORS" -eq -1 ]; then echo "日志文件不存在，未执行 npm run build"; elif [ "$BUILD_ERRORS" -gt 0 ]; then echo "$last_build"; else echo "无错误"; fi)
\`\`\`

## 修复建议

$(if [ "$GOLINT_ERRORS" -ne 0 ]; then echo "- [ ] 修复 golangci-lint 报告的 $GOLINT_ERRORS 个错误"; fi)
$(if [ "$ESLINT_ERRORS" -ne 0 ]; then echo "- [ ] 修复 ESLint 报告的 $ESLINT_ERRORS 个错误"; fi)
$(if [ "$VUETSC_ERRORS" -ne 0 ]; then echo "- [ ] 修复 vue-tsc 报告的 $VUETSC_ERRORS 个类型错误"; fi)
$(if [ "$BUILD_ERRORS" -ne 0 ]; then echo "- [ ] 修复 npm run build 报告的 $BUILD_ERRORS 个构建错误"; fi)
$(if [ "$TOTAL_ERRORS" -eq 0 ]; then echo "无需修复，全部通过。"; fi)
REPORT_EOF

echo "=========================================="
echo "  Lint 检测完成（第 $TOTAL_RUN 次运行）"
echo "  总体结果：$overall_status"
echo "  汇总报告：$REPORT_FILE"
echo "  错误统计：$LINT_DIR/lint-counts.json"
echo "=========================================="

if [ "$PASSED" != "true" ]; then
    exit 1
fi
exit 0
