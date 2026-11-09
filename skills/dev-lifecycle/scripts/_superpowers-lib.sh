#!/usr/bin/env bash
# =============================================================================
# _superpowers-lib.sh — Superpowers（writing-plans / executing-plans）检测
# =============================================================================
# 【变更说明】原版只认 Cursor 插件缓存（~/.cursor/plugins/cache/cursor-public/superpowers）
#   + .cursor/settings.json 的 plugins.superpowers.enabled，且依赖 python 解析 JSON。
#   现版改为「按 agent 在 skills 目录中查找 SKILL.md」，对 claude-code / cursor / codex
#   通用，且不依赖 python。Cursor 插件缓存保留为向后兼容的回落路径。
# 【判定】superpowers_ready = writing-plans 与 executing-plans 两个 Skill 均可用
#   （原版的 installed / enabled 二元拆分是 Cursor 插件开关特有概念，此处
#     installed=两者至少其一可用，enabled=两者都可用，以兼容既有报告模板字段）
# 【调用方】check-superpowers.sh、check-env.sh（source 使用）
# 【导出函数】
#   sp_find_skill <agent> <name>   查找单个 Superpowers Skill，输出路径
#   sp_find_plugin_dir             向后兼容：查找 Cursor 插件缓存目录
#   sp_writing_plans_path <agent>  writing-plans 的 SKILL.md 路径
#   sp_executing_plans_path <agent>executing-plans 的 SKILL.md 路径
#   sp_status <agent>             输出三行：installed/enabled/ready 的 true|false
#   sp_install_hint <agent>       输出该 agent 的安装命令提示
# =============================================================================

_SP_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_agent-lib.sh
. "$_SP_LIB_DIR/_agent-lib.sh"

# ── 向后兼容：Cursor 插件缓存 ───────────────────────────────────────────────
sp_find_plugin_dir() {
  local base="${HOME}/.cursor/plugins/cache/cursor-public/superpowers"
  [ -d "$base" ] || return 1
  local d skill
  for d in "$base"/*/; do
    [ -d "$d" ] || continue
    skill="${d}skills/writing-plans/SKILL.md"
    [ -f "$skill" ] && [ -s "$skill" ] || continue
    printf '%s' "${d%/}"
    return 0
  done
  return 1
}

# ── 按 agent 查找单个 Superpowers Skill ─────────────────────────────────────
sp_find_skill() {
  local agent="$1" name="$2" plugin_dir candidate
  # 1. 常规 skills 目录
  if candidate="$(dlc_find_skill "$agent" "$name")"; then
    printf '%s' "$candidate"
    return 0
  fi
  # 2. 回落：Cursor 插件缓存
  if plugin_dir="$(sp_find_plugin_dir)"; then
    candidate="$plugin_dir/skills/$name/SKILL.md"
    if [ -f "$candidate" ] && [ -s "$candidate" ]; then
      printf '%s' "$candidate"
      return 0
    fi
  fi
  return 1
}

sp_writing_plans_path()   { sp_find_skill "$1" "writing-plans"; }
sp_executing_plans_path() { sp_find_skill "$1" "executing-plans"; }

# ── 汇总状态：输出 installed / enabled / ready（各一行 true|false）──────────
sp_status() {
  local agent="$1" wp="" ep="" installed=false enabled=false ready=false
  wp="$(sp_writing_plans_path "$agent" || true)"
  ep="$(sp_executing_plans_path "$agent" || true)"
  if [ -n "$wp" ] || [ -n "$ep" ]; then installed=true; fi
  if [ -n "$wp" ] && [ -n "$ep" ]; then enabled=true; ready=true; fi
  echo "$installed"
  echo "$enabled"
  echo "$ready"
}

# ── 安装提示（运行时环境检查命中缺失项时输出给用户）────────────────────────
sp_install_hint() {
  local agent="${1:-unknown}"
  local target="$agent"
  [ "$target" = "unknown" ] && target="claude-code"
  cat <<EOF
npx skills add obra/superpowers --skill writing-plans --skill executing-plans -a $target -g
EOF
}
