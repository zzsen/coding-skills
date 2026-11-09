#!/usr/bin/env bash
# =============================================================================
# preflight.sh — 入口门禁编排
# =============================================================================
# 【功能】按 SKILL §1.1 顺序执行：环境检查 → Rules 恢复 → OpenSpec 目录补全 → 再次环境检查，并写入执行标记。
# 【调用阶段】前置首个回合（推荐替代分步执行 check-env + restore-rules + ensure-openspec）。
# 【输入】--json 可选（传递给 check-env）
# 【输出】
#   stdout：分段标题 + 两次 check-env 输出 + restore-rules / ensure-openspec 输出 + complete 行
#   文件：.dev-lifecycle/.preflight-last-run（时间戳，项目级）
#   exit 0：编排完成（环境是否就绪由 Agent 解读 check-env 输出）
# 【流程】
#   1. check-env（恢复前）
#   2. restore-rules
#   3. ensure-openspec（缺 openspec/ 则 openspec init --tools <按 agent 解析>）
#   4. check-env（恢复后）
#   5. 写入 .preflight-last-run 标记（gate-phase2 可检测）
# 【用法】bash <skill_root>/scripts/preflight.sh [--json] [--agent=claude-code|cursor|codex]
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_agent-lib.sh
source "$SCRIPT_DIR/_agent-lib.sh"

JSON=false
AGENT_ARG=""
for arg in "$@"; do
  case "$arg" in
    --json) JSON=true ;;
    --agent=*) AGENT_ARG="$arg" ;;
    -h|--help) echo "用法: $0 [--json] [--agent=claude-code|cursor|codex]"; exit 0 ;;
  esac
done

AGENT="$(dlc_detect_agent)"
if [ -n "$AGENT_ARG" ]; then AGENT="${AGENT_ARG#*=}"; fi
echo "=== preflight: agent = $AGENT ($(dlc_agent_label "$AGENT")) ==="
echo ""

echo "=== preflight: 环境检查（恢复前）==="
set +e
if [ "$JSON" = true ]; then
  bash "$SCRIPT_DIR/check-env.sh" --agent="$AGENT" --json
else
  bash "$SCRIPT_DIR/check-env.sh" --agent="$AGENT"
fi
set -e

echo ""
echo "=== preflight: Rules 恢复 ==="
set +e
bash "$SCRIPT_DIR/restore-rules.sh" --agent="$AGENT"
set -e

echo ""
echo "=== preflight: OpenSpec 目录补全 ==="
# 缺 CLI 时 ensure-openspec 会 exit 1；preflight 不因此中断，留给 check-env 标 ❌
set +e
bash "$SCRIPT_DIR/ensure-openspec.sh" --agent="$AGENT"
set -e

echo ""
echo "=== preflight: 环境检查（恢复后）==="
set +e
if [ "$JSON" = true ]; then
  bash "$SCRIPT_DIR/check-env.sh" --agent="$AGENT" --json
else
  bash "$SCRIPT_DIR/check-env.sh" --agent="$AGENT"
fi
set -e

# 标记本次 preflight 已执行（供 gate-phase2 等脚本可选检测）
MARKER="$(dlc_preflight_marker)"
mkdir -p "$(dirname "$MARKER")"
date +"%Y-%m-%d %H:%M:%S" > "$MARKER"
echo ""
echo "preflight: complete (marker: $MARKER)"
