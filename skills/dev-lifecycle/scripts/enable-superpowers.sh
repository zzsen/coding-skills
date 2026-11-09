#!/usr/bin/env bash
# =============================================================================
# enable-superpowers.sh — 安装 Superpowers（writing-plans / executing-plans）
# =============================================================================
# 【变更说明】原版做的是「在 .cursor/settings.json 写 plugins.superpowers.enabled=true」，
#   这是 Cursor 插件开关特有的概念。Superpowers 本身只是一组 SKILL.md，可通过
#   skills CLI 装到任意 agent，因此本脚本改为按 agent 安装对应 Skill。
# 【默认行为】只打印命令，不执行（对应 preparation AskUserQuestion #2 的「手动步骤」）。
#   加 --run 才实际执行（对应「由 Agent 代为安装」）。
# 【输入】
#   --run          实际执行 npx skills add（默认仅打印）
#   --agent=<id>   覆盖自动探测（claude-code | cursor | codex）
#   --project      装到项目目录而非全局（默认全局 -g）
# 【输出】
#   stdout：RESULT: ALREADY_READY | PRINTED | INSTALLED | ERROR
#   exit 0：已就绪 / 已打印 / 安装成功；exit 1：安装失败
# 【用法】bash <skill_root>/scripts/enable-superpowers.sh [--run] [--agent=cursor] [--project]
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_superpowers-lib.sh
source "$SCRIPT_DIR/_superpowers-lib.sh"

RUN=false
AGENT=""
SCOPE="-g"
for arg in "$@"; do
  case "$arg" in
    --run) RUN=true ;;
    --agent=*) AGENT="${arg#*=}" ;;
    --project) SCOPE="" ;;
    -h|--help)
      echo "用法: $0 [--run] [--agent=claude-code|cursor|codex] [--project]"
      exit 0
      ;;
  esac
done

[ -n "$AGENT" ] || AGENT="$(dlc_detect_agent)"
TARGET="$AGENT"
[ "$TARGET" = "unknown" ] && TARGET="claude-code"

{ read -r _installed; read -r _enabled; read -r ready; } < <(sp_status "$AGENT")
if [ "$ready" = true ]; then
  echo 'RESULT: ALREADY_READY'
  exit 0
fi

CMD=(npx skills add obra/superpowers --skill writing-plans --skill executing-plans -a "$TARGET")
[ -n "$SCOPE" ] && CMD+=("$SCOPE")

if [ "$RUN" != true ]; then
  echo 'RESULT: PRINTED'
  echo "HINT: 请执行（或改用 --run 让 Agent 代为执行）："
  echo "  ${CMD[*]}"
  exit 0
fi

if ! command -v npx >/dev/null 2>&1; then
  echo 'RESULT: ERROR'
  echo 'HINT: 未找到 npx，请先安装 Node.js 22.20+'
  exit 1
fi

echo "Superpowers: running ${CMD[*]}"
if ! "${CMD[@]}"; then
  echo 'RESULT: ERROR'
  exit 1
fi

{ read -r _installed; read -r _enabled; read -r ready; } < <(sp_status "$AGENT")
if [ "$ready" = true ]; then
  echo 'RESULT: INSTALLED'
  exit 0
fi
echo 'RESULT: ERROR'
echo 'HINT: 命令已执行但仍未检测到 writing-plans / executing-plans，请检查安装目标目录'
exit 1
