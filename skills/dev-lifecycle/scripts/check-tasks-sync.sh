#!/usr/bin/env bash
# =============================================================================
# check-tasks-sync.sh — OpenSpec tasks.md 勾选状态检查
# =============================================================================
# 【功能】统计 tasks.md 未勾选项；可选对比 2.plan.md Wave 未完成行。
# 【调用阶段】Phase 3 收尾 / apply 前。
# 【输入】
#   --change-name  必填
#   --plan-dir     可选
# 【输出】stdout：checked/unchecked 统计 + TASKS_SYNC: pass|block；exit 0/1
# 【流程】
#   1. 定位 changes/ 或 archive/ 下 tasks.md
#   2. grep 未勾选 - [ ]
#   3. 若有 plan-dir，检查 Wave 表是否仍有未开始/进行中
# 【用法】bash .../check-tasks-sync.sh --change-name user-mgmt [--plan-dir ...]
# =============================================================================
set -euo pipefail

CHANGE=""
PLAN_DIR=""
while [ $# -gt 0 ]; do
  case "$1" in
    --change-name) CHANGE="${2:-}"; shift 2 ;;
    --plan-dir) PLAN_DIR="${2:-}"; shift 2 ;;
    -h|--help) echo "用法: $0 --change-name <name> [--plan-dir <path>]"; exit 0 ;;
    *) echo "未知参数: $1" >&2; exit 1 ;;
  esac
done

[ -n "$CHANGE" ] || { echo "错误: 需要 --change-name" >&2; exit 1; }

TASKS="openspec/changes/$CHANGE/tasks.md"
if [ ! -f "$TASKS" ]; then
  arch=$(find openspec/archive -maxdepth 1 -type d -name "*-${CHANGE}" 2>/dev/null | head -1)
  TASKS="${arch}/tasks.md"
fi
[ -f "$TASKS" ] || { echo "错误: 找不到 tasks.md" >&2; exit 1; }

unchecked=$(grep -cE '^\- \[ \]' "$TASKS" 2>/dev/null || echo 0)
checked=$(grep -cE '^\- \[[xX]\]' "$TASKS" 2>/dev/null || echo 0)
echo "tasks.md: checked=$checked unchecked=$unchecked"

if [ -n "$PLAN_DIR" ] && [ -f "$PLAN_DIR/2.plan.md" ]; then
  incomplete=$(grep -cE '⬜ 未开始|🔄 进行中' "$PLAN_DIR/2.plan.md" 2>/dev/null || echo 0)
  echo "2.plan.md: incomplete_waves=$incomplete"
  if [ "$unchecked" -gt 0 ] && [ "$incomplete" -eq 0 ]; then
    echo "⚠️ tasks 仍有未勾选但 Wave 表无进行中/未开始"
  fi
fi

if [ "$unchecked" -eq 0 ]; then
  echo "TASKS_SYNC: pass"
  exit 0
else
  echo "未勾选任务:"
  grep -nE '^\- \[ \]' "$TASKS" || true
  echo "TASKS_SYNC: block"
  exit 1
fi
