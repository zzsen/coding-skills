#!/usr/bin/env bash
# =============================================================================
# gate-phase2.sh — Phase 2 硬门禁
# =============================================================================
# 【功能】验证进入 Phase 2（writing-plans）前的文件级前置条件（不含 AskUserQuestion 用户确认）。
# 【调用阶段】Phase 2 前（phase2.md §一）。
# 【输入】
#   --plan-dir      dev-plan 计划目录（必填）
#   --change-name   OpenSpec 变更名 kebab-case（必填）
# 【输出】
#   stdout：逐项 ✅/❌ + GATE_PHASE2: pass|block
#   exit 0：pass；exit 1：block
# 【流程】
#   1. 可选检测 .preflight-last-run 标记
#   2. 检查 1.proposal.md
#   3. 检查 openspec/changes/<name>/proposal|design|tasks.md
#   4. 提示 AskUserQuestion 须会话内验证
# 【用法】bash .../gate-phase2.sh --plan-dir dev-plan/... --change-name user-mgmt
# =============================================================================
set -euo pipefail

PLAN_DIR=""
CHANGE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --plan-dir) PLAN_DIR="${2:-}"; shift 2 ;;
    --change-name) CHANGE="${2:-}"; shift 2 ;;
    -h|--help)
      echo "用法: $0 --plan-dir <path> --change-name <kebab-name>"
      exit 0
      ;;
    *) echo "未知参数: $1" >&2; exit 1 ;;
  esac
done

if [ -z "$PLAN_DIR" ] || [ -z "$CHANGE" ]; then
  echo "错误: 需要 --plan-dir 和 --change-name" >&2
  exit 1
fi

fail=0
require() {
  if [ -e "$1" ]; then echo "✅ $2"
  else echo "❌ $2 (缺失: $1)"; fail=1; fi
}

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_agent-lib.sh
source "$SCRIPT_DIR/_agent-lib.sh"
MARKER="$(dlc_preflight_marker)"
LEGACY_MARKER=".cursor/skills/dev-lifecycle/.preflight-last-run"
[ -e "$MARKER" ] || [ ! -e "$LEGACY_MARKER" ] || MARKER="$LEGACY_MARKER"
if [ -f "$MARKER" ]; then echo "✅ preflight 已执行 ($MARKER)"
else echo "⚠️ preflight 标记不存在（建议先运行 preflight.sh）"; fi

require "$PLAN_DIR/1.proposal.md" "1.proposal.md 存在"
OS="openspec/changes/$CHANGE"
require "$OS/proposal.md" "openspec proposal.md"
require "$OS/design.md" "openspec design.md"
require "$OS/tasks.md" "openspec tasks.md"

echo "NOTE: 用户 AskUserQuestion 确认 Phase 1 须由 Agent 会话内验证，脚本无法检测"

[ "$fail" -eq 0 ] && echo "GATE_PHASE2: pass" || echo "GATE_PHASE2: block"
exit "$fail"
