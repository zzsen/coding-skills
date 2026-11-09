#!/usr/bin/env bash
# =============================================================================
# next-task-id.sh — 生成下一任务编号
# =============================================================================
# 【功能】扫描 dev-plan 下已有 T-YYYYMMDD-N，返回当日下一个序号（禁止编造编号）。
# 【调用阶段】Phase 1~7 写入任务编号时。
# 【输入】--plan-dir 可选，限定扫描范围（默认 dev-plan/）
# 【输出】stdout：T-YYYYMMDD-N；exit 0
# 【流程】
#   1. 获取当日日期
#   2. grep 已有 T-日期-序号
#   3. 取最大序号 +1
# 【用法】bash <skill_root>/scripts/next-task-id.sh [--plan-dir dev-plan/...]
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLAN_DIR=""
while [ $# -gt 0 ]; do
  case "$1" in
    --plan-dir) PLAN_DIR="${2:-}"; shift 2 ;;
    -h|--help) echo "用法: $0 [--plan-dir <dir>]"; exit 0 ;;
    *) echo "未知参数: $1" >&2; exit 1 ;;
  esac
done

DATE=$(bash "$SCRIPT_DIR/timestamp.sh" --format date)
PATTERN="T-${DATE}-"
SEARCH_PATH="${PLAN_DIR:-dev-plan}"
max=0
if [ -d "$SEARCH_PATH" ]; then
  while IFS= read -r line; do
    num="${line##*-}"
    [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -gt "$max" ] && max=$num
  done < <(grep -rhoE "${PATTERN}[0-9]+" "$SEARCH_PATH" 2>/dev/null || true)
fi
echo "${PATTERN}$((max + 1))"
