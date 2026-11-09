#!/usr/bin/env bash
# =============================================================================
# check-env.sh — 环境定点检查（多 agent：claude-code / cursor / codex）
# =============================================================================
# 【功能】检查 dev-lifecycle 前置环境：agent 识别、OpenSpec（CLI + list + 目录）、
#         Superpowers（writing-plans / executing-plans）、Rules（可选项）、project-config；
#         供门禁报告 §1 引用，禁止 Agent 凭猜测填写 ✅/❌。
# 【调用阶段】前置首个命令（preflight 内嵌调用 / 单独 check-env）；
#             须在任何项目 Read、文件搜索之前执行。
# 【输入】
#   --json          可选，输出 JSON 对象
#   --agent=<id>    可选，覆盖自动探测（claude-code | cursor | codex）
#   须在项目根目录执行（相对路径基于 cwd）
# 【输出】
#   stdout：agent、路径 True/False、openspec-cli-installed、openspec-list-ok、
#           openspec-ready、superpowers_installed / _enabled / _ready、
#           rules-kind / rules-ok、environment-ready、openspec-cli 版本
#   exit 0：脚本正常结束（不表示环境全部就绪，须 Agent 解读 True/False）
# 【门禁口径变更】environment-ready = openspec-ready ∧ superpowers_ready。
#   Rules 已从硬门禁降级为 agent 可选项：rules-ok 仅作信息项输出，
#   **不参与** environment-ready 计算（Cursor 以外的 agent 无等价强制机制）。
# 【用法】bash <skill_root>/scripts/check-env.sh [--json] [--agent=cursor]
# =============================================================================
set -euo pipefail

# 步骤 1：解析参数
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

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_superpowers-lib.sh
source "$SCRIPT_DIR/_superpowers-lib.sh"   # 内部已 source _agent-lib.sh

SKILL_ROOT="$(dlc_skill_root)"
[ -n "$AGENT" ] || AGENT="$(dlc_detect_agent)"
OPENSPEC_TOOL="$(dlc_openspec_tool "$AGENT")"
RULES_KIND="$(dlc_rules_kind "$AGENT")"

ts=$(date +"%Y-%m-%d %H:%M:%S")

# 步骤 2：固定路径列表（openspec 根目录 / project-config；不扫 openspec 子树）
paths=(
  "openspec"
  "$(dlc_project_config_path)"
)

# 步骤 3：OpenSpec CLI 全局安装检测
if command -v openspec >/dev/null 2>&1; then
  cli_installed=true
  openspec_cli=$(openspec --version 2>&1 || echo "error")
else
  cli_installed=false
  openspec_cli="not found"
fi

# 步骤 4：openspec list 检测（CLI 未装时跳过，list-ok 保持 false）
openspec_list_ok=false
if [ "$cli_installed" = true ]; then
  if openspec list >/dev/null 2>&1; then
    openspec_list_ok=true
  fi
fi

# 步骤 5：OpenSpec 汇总（须含项目根 openspec/ 目录）
if [ -d "openspec" ]; then
  openspec_dir_ok=true
else
  openspec_dir_ok=false
fi
if [ "$cli_installed" = true ] && [ "$openspec_list_ok" = true ] && [ "$openspec_dir_ok" = true ]; then
  openspec_ready=true
else
  openspec_ready=false
fi

# 步骤 6：Superpowers（按 agent 在 skills 目录中查找两个 Skill）
{ read -r superpowers_installed; read -r superpowers_enabled; read -r superpowers_ready; } \
  < <(sp_status "$AGENT")
wp_path="$(sp_writing_plans_path "$AGENT" || true)"
ep_path="$(sp_executing_plans_path "$AGENT" || true)"

# 步骤 7：Rules（信息项，不参与门禁）
rules_ok=true
rules_targets=""
if [ "$RULES_KIND" = "none" ]; then
  rules_ok=na
else
  while IFS= read -r r; do
    [ -n "$r" ] || continue
    rules_targets="$rules_targets $r"
    [ -e "$r" ] || rules_ok=false
  done <<EOF
$(dlc_rules_targets "$AGENT")
EOF
fi

# 步骤 8：门禁汇总（Rules 不参与）
if [ "$openspec_ready" = true ] && [ "$superpowers_ready" = true ]; then
  environment_ready=true
else
  environment_ready=false
fi

# 步骤 9：JSON 输出
if [ "$JSON" = true ]; then
  echo "{"
  echo "  \"checked_at\": \"$ts\","
  echo "  \"agent\": \"$AGENT\","
  echo "  \"skill_root\": \"$SKILL_ROOT\","
  echo "  \"openspec_tool\": \"$OPENSPEC_TOOL\","
  echo "  \"paths\": {"
  first=true
  for p in "${paths[@]}"; do
    [ -e "$p" ] && v=true || v=false
    $first || echo ","
    first=false
    printf '    "%s": %s' "$p" "$v"
  done
  echo ""
  echo "  },"
  echo "  \"openspec_cli_installed\": $cli_installed,"
  echo "  \"openspec_list_ok\": $openspec_list_ok,"
  echo "  \"openspec_ready\": $openspec_ready,"
  echo "  \"superpowers_installed\": $superpowers_installed,"
  echo "  \"superpowers_enabled\": $superpowers_enabled,"
  echo "  \"superpowers_ready\": $superpowers_ready,"
  echo "  \"writing_plans_path\": \"$wp_path\","
  echo "  \"executing_plans_path\": \"$ep_path\","
  echo "  \"rules_kind\": \"$RULES_KIND\","
  echo "  \"rules_ok\": \"$rules_ok\","
  echo "  \"environment_ready\": $environment_ready,"
  echo "  \"openspec_cli\": \"$openspec_cli\""
  echo "}"
  exit 0
fi

# 步骤 9：文本输出
echo "=== dev-lifecycle 环境定点检查 ==="
echo "$ts"
echo -e "agent:\t$AGENT ($(dlc_agent_label "$AGENT"))"
echo -e "skill-root:\t$SKILL_ROOT"
echo -e "openspec-tool:\t$OPENSPEC_TOOL"
for p in "${paths[@]}"; do
  [ -e "$p" ] && echo -e "$p\tTrue" || echo -e "$p\tFalse"
done
echo -e "openspec-cli-installed:\t$cli_installed"
echo -e "openspec-list-ok:\t$openspec_list_ok"
echo -e "openspec-ready:\t$openspec_ready"
echo -e "superpowers_installed:\t$superpowers_installed"
echo -e "superpowers_enabled:\t$superpowers_enabled"
echo -e "superpowers_ready:\t$superpowers_ready"
if [ -n "$wp_path" ]; then echo -e "writing-plans:\t$wp_path"; fi
if [ -n "$ep_path" ]; then echo -e "executing-plans:\t$ep_path"; fi
echo -e "rules-kind:\t$RULES_KIND"
echo -e "rules-ok:\t$rules_ok (信息项，不参与门禁)"
if [ -n "$rules_targets" ]; then echo -e "rules-targets:\t$rules_targets"; fi
echo -e "environment-ready:\t$environment_ready"
echo -e "openspec-cli:\t$openspec_cli"

# 未就绪时输出安装提示（运行时引导，不自动执行）
if [ "$environment_ready" != true ]; then
  echo ""
  echo "=== 环境未就绪，安装提示 ==="
  if [ "$cli_installed" != true ]; then
    echo "  OpenSpec CLI: npm install -g @fission-ai/openspec@latest"
  fi
  if [ "$cli_installed" = true ] && { [ "$openspec_list_ok" != true ] || [ "$openspec_dir_ok" != true ]; }; then
    echo "  OpenSpec 项目: openspec init --tools $OPENSPEC_TOOL"
  fi
  if [ "$superpowers_ready" != true ]; then
    echo "  Superpowers: $(sp_install_hint "$AGENT")"
  fi
fi

exit 0
