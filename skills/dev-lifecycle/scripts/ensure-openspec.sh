#!/usr/bin/env bash
# =============================================================================
# ensure-openspec.sh — 项目根缺少 openspec/ 时自动 init
# =============================================================================
# 【功能】若项目根不存在 openspec/ 目录，且 openspec CLI 可用，则执行
#         openspec init --tools <按 agent 解析>（及 openspec update）；已存在则跳过。
# 【调用阶段】前置 preparation；preflight 在 restore-rules 之后调用。
# 【输入】--dry-run 可选，只打印将执行的动作；--agent=<id> 可选（覆盖自动探测）
# 【输出】stdout：OpenSpec init: ... / already present / CLI missing；exit 0（缺 CLI 时 exit 1）
# 【流程】
#   1. 检测 openspec/ 是否存在
#   2. 不存在则检测 CLI（command -v openspec）
#   3. 执行 openspec init --tools <slug>，再 openspec update
#      slug 由 _agent-lib 解析：claude-code→claude / cursor→cursor / codex→codex /
#      未知→agents（vendor-neutral，写 .agents/skills/）
# 【用法】bash <skill_root>/scripts/ensure-openspec.sh [--dry-run] [--agent=cursor]
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_agent-lib.sh
source "$SCRIPT_DIR/_agent-lib.sh"

DRY=false
AGENT=""
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY=true ;;
    --agent=*) AGENT="${arg#*=}" ;;
    -h|--help) echo "用法: $0 [--dry-run] [--agent=claude-code|cursor|codex]"; exit 0 ;;
  esac
done

[ -n "$AGENT" ] || AGENT="$(dlc_detect_agent)"
TOOL="$(dlc_openspec_tool "$AGENT")"

OPENSPEC_DIR="openspec"

if [ -d "$OPENSPEC_DIR" ]; then
  echo "OpenSpec: openspec/ already present"
  exit 0
fi

if ! dlc_openspec_resolve; then
  echo "RESULT: OPENSPEC_CLI_MISSING"
  echo "HINT: Install with npm install -g @fission-ai/openspec@latest"
  exit 1
fi

if [ "$DRY" = true ]; then
  echo "[dry-run] would run: openspec init --tools $TOOL"
  echo "[dry-run] would run: openspec update"
  exit 0
fi

echo "OpenSpec: openspec/ missing — running openspec init --tools $TOOL (agent=$AGENT)"
openspec init --tools "$TOOL"

echo "OpenSpec: running openspec update"
openspec update

if [ ! -d "$OPENSPEC_DIR" ]; then
  echo "RESULT: INIT_OK_BUT_OPENSPEC_DIR_MISSING"
  exit 1
fi

echo "OpenSpec: initialized (openspec/ created)"
exit 0
