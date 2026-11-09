#!/usr/bin/env bash
# =============================================================================
# check-superpowers.sh — 检测 Superpowers（writing-plans / executing-plans）可用性
# =============================================================================
# 【功能】按当前 agent（claude-code / cursor / codex）在其 skills 目录中查找
#         writing-plans 与 executing-plans 两个 Skill。
# 【调用阶段】前置 preparation；亦被 check-env 调用。
# 【输入】--json 可选；--agent=<id> 可选（覆盖自动探测）
# 【输出】
#   agent、superpowers-plugin-installed / -enabled / superpowers-ready、
#   两个 Skill 的命中路径、未就绪时的安装命令提示；exit 0
# 【用法】bash <skill_root>/scripts/check-superpowers.sh [--json] [--agent=claude-code]
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_superpowers-lib.sh
source "$SCRIPT_DIR/_superpowers-lib.sh"

JSON=false
AGENT=""
for arg in "$@"; do
  case "$arg" in
    --json) JSON=true ;;
    --agent=*) AGENT="${arg#*=}" ;;
    -h|--help)
      echo "用法: $0 [--json] [--agent=claude-code|cursor|codex]"
      exit 0
      ;;
  esac
done

[ -n "$AGENT" ] || AGENT="$(dlc_detect_agent)"

wp="$(sp_writing_plans_path "$AGENT" || true)"
ep="$(sp_executing_plans_path "$AGENT" || true)"

{ read -r installed; read -r enabled; read -r ready; } < <(sp_status "$AGENT")

if [ "$JSON" = true ]; then
  printf '{\n'
  printf '  "agent": "%s",\n' "$AGENT"
  printf '  "superpowers_plugin_installed": %s,\n' "$installed"
  printf '  "superpowers_plugin_enabled": %s,\n' "$enabled"
  printf '  "superpowers_ready": %s,\n' "$ready"
  printf '  "writing_plans_path": "%s",\n' "$wp"
  printf '  "executing_plans_path": "%s"\n' "$ep"
  printf '}\n'
  exit 0
fi

echo -e "agent:\t$AGENT ($(dlc_agent_label "$AGENT"))"
echo -e "superpowers-plugin-installed:\t$installed"
echo -e "superpowers-plugin-enabled:\t$enabled"
echo -e "superpowers-ready:\t$ready"
if [ -n "$wp" ]; then echo -e "writing-plans:\t$wp"; fi
if [ -n "$ep" ]; then echo -e "executing-plans:\t$ep"; fi
if [ "$ready" != true ]; then
  echo "HINT: 安装 Superpowers（writing-plans / executing-plans）："
  echo "  $(sp_install_hint "$AGENT")"
fi

exit 0
