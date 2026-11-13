#!/usr/bin/env bash
# =============================================================================
# _agent-lib.sh — Agent（IDE）抽象层：路径 / openspec 目标 / Rules 载体解析
# =============================================================================
# 【功能】把原先写死的 Cursor 路径（.cursor/skills、.cursor/rules、.cursor/settings.json）
#         抽象为按 agent 解析，支持 claude-code / cursor / codex。
# 【调用方】被 check-env.sh、check-superpowers.sh、restore-rules.sh、ensure-openspec.sh
#           等脚本 source，不单独执行。
# 【Agent 解析优先级】
#   1. 环境变量 DEVLC_AGENT（claude-code | cursor | codex）— 最高优先
#   2. 本 Skill 自身的安装路径（~/.claude/skills → claude-code，~/.cursor/skills → cursor，
#      ~/.agents/skills → codex）
#   3. 项目内标记目录/文件（.claude/ → claude-code，.cursor/ → cursor，
#      .agents/ 或 AGENTS.md → codex）
#   4. 用户级目录（~/.claude → claude-code，~/.cursor → cursor，~/.agents → codex）
#   5. 以上全不命中 → unknown（调用方须按「未知 agent」降级处理，不得阻断）
# 【导出函数】
#   dlc_skill_root                 本 Skill 根目录绝对路径
#   dlc_detect_agent               输出 agent id
#   dlc_agent_label <id>           人类可读名称
#   dlc_openspec_tool <id>         openspec init --tools 的 slug
#   dlc_skills_dirs <id>           候选 skills 目录（项目 + 全局，每行一个）
#   dlc_rules_kind <id>            rules 载体类型：mdc | memory-file | none
#   dlc_rules_targets <id>         rules 目标路径（每行一个；none 时无输出）
#   dlc_find_skill <id> <name>     在候选 skills 目录中查找某个 skill 的 SKILL.md
#   dlc_state_dir                  项目级运行时状态目录（.dev-lifecycle/）
#   dlc_project_config_path        project-config.md 路径（项目级优先，回落 Skill 内）
#   dlc_preflight_marker           preflight 执行标记路径（项目级）
# 【重要】project-config.md 与 preflight 标记已从 Skill 目录移到项目级
#   .dev-lifecycle/，因为全局安装（~/.claude/skills 等）时 Skill 目录为多项目共享，
#   把单项目配置写进去会互相串台。旧位置保留为只读回落。
# =============================================================================

# ── Skill 根目录 ─────────────────────────────────────────────────────────────
dlc_skill_root() {
  local here
  here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  printf '%s' "$here"
}

# ── Agent 解析 ───────────────────────────────────────────────────────────────
dlc_detect_agent() {
  # 1. 环境变量显式指定
  case "${DEVLC_AGENT:-}" in
    claude-code|cursor|codex) printf '%s' "$DEVLC_AGENT"; return 0 ;;
    "") : ;;
    *) printf 'unknown'; return 0 ;;
  esac

  # 2. 由本 Skill 的安装位置反推
  local root
  root="$(dlc_skill_root)"
  case "$root" in
    *"/.claude/skills/"*) printf 'claude-code'; return 0 ;;
    *"/.cursor/skills/"*) printf 'cursor';      return 0 ;;
    *"/.agents/skills/"*) printf 'codex';       return 0 ;;
  esac

  # 3. 项目内标记
  if [ -d ".claude" ]; then printf 'claude-code'; return 0; fi
  if [ -d ".cursor" ]; then printf 'cursor';      return 0; fi
  if [ -d ".agents" ] || [ -f "AGENTS.md" ]; then printf 'codex'; return 0; fi

  # 4. 用户级目录
  if [ -d "$HOME/.claude" ]; then printf 'claude-code'; return 0; fi
  if [ -d "$HOME/.cursor" ]; then printf 'cursor';      return 0; fi
  if [ -d "$HOME/.agents" ]; then printf 'codex';       return 0; fi

  printf 'unknown'
}

dlc_agent_label() {
  case "$1" in
    claude-code) printf 'Claude Code' ;;
    cursor)      printf 'Cursor' ;;
    codex)       printf 'Codex' ;;
    *)           printf 'Unknown' ;;
  esac
}

# ── openspec init --tools 目标 ───────────────────────────────────────────────
# 未知 agent 回落到 vendor-neutral 的 agents 目标（写 .agents/skills/）
dlc_openspec_tool() {
  case "$1" in
    claude-code) printf 'claude' ;;
    cursor)      printf 'cursor' ;;
    codex)       printf 'codex' ;;
    *)           printf 'agents' ;;
  esac
}

# ── OpenSpec CLI 探测（多安装方式兼容）───────────────────────────────────────
# 依次探测 PATH、nvm、npm-global、volta、fnm 等常见安装位置。找到后把其 bin
# 目录前置到 PATH（该目录通常同时含 node，保证 openspec 的
# `#!/usr/bin/env node` shebang 可解析）。成功返回 0，未找到返回 1。
# 【调用方注意】必须用 `if dlc_openspec_resolve; then ...` 直接调用，勿放进
#   命令替换 $() —— 否则 export PATH 只在子 shell 生效，父 shell 仍找不到 openspec。
dlc_openspec_resolve() {
  local bin d
  bin="$(command -v openspec 2>/dev/null || true)"
  if [ -n "$bin" ]; then
    return 0
  fi
  for d in \
    "$HOME"/.nvm/current/bin \
    "$HOME"/.nvm/versions/node/*/bin \
    "$HOME"/.npm-global/bin \
    "$HOME"/.volta/bin \
    "$HOME"/.local/share/fnm/node-versions/*/installation/bin \
    "$HOME/Library/Application Support/fnm/node-versions"/*/installation/bin \
    "$HOME"/.fnm/node-versions/*/installation/bin \
    "$HOME"/.fnm/aliases/default/bin ; do
    if [ -x "$d/openspec" ]; then
      export PATH="$d:$PATH"
      return 0
    fi
  done
  return 1
}

# ── skills 目录候选（项目优先，其次全局）────────────────────────────────────
dlc_skills_dirs() {
  case "$1" in
    claude-code)
      echo ".claude/skills"
      echo "$HOME/.claude/skills"
      ;;
    cursor)
      # Cursor 原生用 .cursor/skills/；skills CLI 写项目 .agents/skills/
      echo ".cursor/skills"
      echo ".agents/skills"
      echo "$HOME/.cursor/skills"
      ;;
    codex)
      echo ".agents/skills"
      echo "$HOME/.agents/skills"
      ;;
    *)
      echo ".agents/skills"
      echo "$HOME/.agents/skills"
      echo ".claude/skills"
      echo "$HOME/.claude/skills"
      echo ".cursor/skills"
      echo "$HOME/.cursor/skills"
      ;;
  esac
}

# ── Rules 载体（已从硬门禁降级为 agent 可选项）──────────────────────────────
#   mdc         : Cursor 的 .cursor/rules/*.mdc，可自动恢复
#   memory-file : 常驻记忆文件（CLAUDE.md / AGENTS.md），仅提示，不自动写
#   none        : 该 agent 无等价机制，跳过
dlc_rules_kind() {
  case "$1" in
    cursor)      printf 'mdc' ;;
    claude-code) printf 'memory-file' ;;
    codex)       printf 'memory-file' ;;
    *)           printf 'none' ;;
  esac
}

dlc_rules_targets() {
  case "$1" in
    cursor)
      echo ".cursor/rules/01-openspec-workflow.mdc"
      echo ".cursor/rules/02-tdd-plan-wave-tracking.mdc"
      echo ".cursor/rules/03-askquestion-task-followup.mdc"
      ;;
    claude-code) echo "CLAUDE.md" ;;
    codex)       echo "AGENTS.md" ;;
    *)           : ;;
  esac
}

# ── 在候选 skills 目录中查找某个 skill ──────────────────────────────────────
# 用法：dlc_find_skill <agent> <skill-name>
# 命中则输出该 SKILL.md 路径并 return 0；否则 return 1
dlc_find_skill() {
  local agent="$1" name="$2" dir candidate
  while IFS= read -r dir; do
    [ -n "$dir" ] || continue
    candidate="$dir/$name/SKILL.md"
    if [ -f "$candidate" ] && [ -s "$candidate" ]; then
      printf '%s' "$candidate"
      return 0
    fi
  done <<EOF
$(dlc_skills_dirs "$agent")
EOF
  return 1
}

# ── 项目级运行时状态 ────────────────────────────────────────────────────────
dlc_state_dir() {
  printf '%s' "${DEVLC_STATE_DIR:-.dev-lifecycle}"
}

# project-config.md：项目级优先；不存在时回落到 Skill 内旧位置（只读）
dlc_project_config_path() {
  local proj skill_fallback
  proj="$(dlc_state_dir)/project-config.md"
  skill_fallback="$(dlc_skill_root)/project-config.md"
  if [ -f "$proj" ]; then
    printf '%s' "$proj"
  elif [ -f "$skill_fallback" ]; then
    printf '%s' "$skill_fallback"
  else
    printf '%s' "$proj"   # 尚不存在时返回应创建的项目级路径
  fi
}

# 门禁通过时间标记：preflight **仅在 environment-ready: True 时**写入
# （首行可读时间 + 次行 epoch）；preflight 入口处据此判定是否可在
# 有效期内（默认 7 天）跳过全量门禁
dlc_preflight_marker() {
  printf '%s' "$(dlc_state_dir)/.preflight-last-run"
}

