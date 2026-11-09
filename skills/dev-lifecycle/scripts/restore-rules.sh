#!/usr/bin/env bash
# =============================================================================
# restore-rules.sh — 工作流规则恢复（agent 可选项，不阻断门禁）
# =============================================================================
# 【变更说明】原版无条件把三个 .mdc 复制到 .cursor/rules/，并作为硬门禁的一项。
#   现版按 agent 分流：
#     cursor      → 复制 reference/*.mdc 到 .cursor/rules/（仅补缺，不覆盖）
#     claude-code → 不写文件，仅提示可将 reference/ 规则摘要并入 CLAUDE.md
#     codex       → 不写文件，仅提示可并入 AGENTS.md
#     unknown     → 跳过
#   无论结果如何都 exit 0，**不参与** environment-ready 计算。
# 【输入】--dry-run 可选；--agent=<id> 可选
# 【输出】stdout：Rules restored / Rules: all present / Rules: skipped (<原因>)
# 【用法】bash <skill_root>/scripts/restore-rules.sh [--dry-run] [--agent=cursor]
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
KIND="$(dlc_rules_kind "$AGENT")"
SKILL_ROOT="$(dlc_skill_root)"
REF="$SKILL_ROOT/reference"

case "$KIND" in
  mdc)
    RULES=".cursor/rules"
    [ "$DRY" = true ] || mkdir -p "$RULES"
    restored=""
    for f in 01-openspec-workflow.mdc 02-tdd-plan-wave-tracking.mdc 03-askquestion-task-followup.mdc; do
      if [ ! -f "$RULES/$f" ]; then
        if [ "$DRY" = true ]; then
          echo "[dry-run] would restore $f"
        else
          cp "$REF/$f" "$RULES/$f"
        fi
        restored="$restored $f"
      fi
    done
    if [ -n "$restored" ]; then
      echo "Rules restored:$restored"
    else
      echo "Rules: all present"
    fi
    ;;
  memory-file)
    target="$(dlc_rules_targets "$AGENT" | head -1)"
    if [ -f "$target" ]; then
      echo "Rules: memory-file present ($target) — 内容由用户维护，脚本不自动写入"
    else
      echo "Rules: memory-file absent ($target) — 可选：将下列规则摘要并入该文件"
      echo "  $REF/01-openspec-workflow.mdc"
      echo "  $REF/02-tdd-plan-wave-tracking.mdc"
      echo "  $REF/03-askquestion-task-followup.mdc"
    fi
    ;;
  *)
    echo "Rules: skipped (agent=$AGENT 无等价常驻规则机制)"
    ;;
esac

exit 0
