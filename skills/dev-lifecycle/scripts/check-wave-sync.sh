#!/usr/bin/env bash
# =============================================================================
# check-wave-sync.sh — Wave 表一致性检查
# =============================================================================
# 【功能】对比 2.plan.md 中 Wave 镜像表与 TDD 计划「Wave 汇总」是否一致。
# 【调用阶段】Phase 3 每 Wave 完成后 / Phase 7 联动更新前。
# 【输入】
#   --plan-dir   必填
#   --tdd-path   可选；缺省从 2.plan.md 超链接解析
# 【输出】stdout：对比结果 + WAVE_SYNC: pass|block；exit 0/1
# 【流程】
#   1. 定位 2.plan.md 与 TDD 计划路径
#   2. awk 提取 | Wave N | ... | 状态 | 行
#   3. sort 后字符串比较
# 【用法】bash .../check-wave-sync.sh --plan-dir dev-plan/...
# =============================================================================
set -euo pipefail

PLAN_DIR=""
TDD_PATH=""
while [ $# -gt 0 ]; do
  case "$1" in
    --plan-dir) PLAN_DIR="${2:-}"; shift 2 ;;
    --tdd-path) TDD_PATH="${2:-}"; shift 2 ;;
    -h|--help) echo "用法: $0 --plan-dir <path> [--tdd-path <file>]"; exit 0 ;;
    *) echo "未知参数: $1" >&2; exit 1 ;;
  esac
done

[ -f "$PLAN_DIR/2.plan.md" ] || { echo "错误: 缺少 2.plan.md" >&2; exit 1; }

if [ -z "$TDD_PATH" ]; then
  TDD_PATH=$(grep -oE 'docs/superpowers/plans/[^)]+\-tdd\.md' "$PLAN_DIR/2.plan.md" | head -1)
fi
[ -n "$TDD_PATH" ] && [ -f "$TDD_PATH" ] || { echo "错误: 无法定位 TDD 计划（用 --tdd-path）" >&2; exit 1; }

# 从 Markdown 表格提取 Wave 列与完成情况列
extract_waves() {
  awk -F'|' '
    /^\| Wave [0-9]+ / {
      gsub(/^ +| +$/, "", $2);
      gsub(/^ +| +$/, "", $4);
      if ($2 ~ /^Wave/) print $2 "\t" $4
    }
  ' "$1" | sort
}

plan_waves=$(extract_waves "$PLAN_DIR/2.plan.md")
tdd_waves=$(extract_waves "$TDD_PATH")

fail=0
if [ "$plan_waves" != "$tdd_waves" ]; then
  echo "❌ Wave 表不一致"
  echo "--- 2.plan.md ---"
  echo "$plan_waves"
  echo "--- TDD ---"
  echo "$tdd_waves"
  fail=1
else
  echo "✅ Wave 表一致"
  echo "$plan_waves"
fi

[ "$fail" -eq 0 ] && echo "WAVE_SYNC: pass" || echo "WAVE_SYNC: block"
exit "$fail"
