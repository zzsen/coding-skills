#!/usr/bin/env bash
# =============================================================================
# gate-phase3.sh — Phase 3 硬门禁（worktree 隔离决策）
# =============================================================================
# 【功能】进入 Phase 3 前校验 worktree 隔离状态：
#         非 git 项目 → 放行（单工作树，按 change 目录隔离）；
#         git 项目且该 change 已有 active worktree → 放行并输出 worktree 上下文
#         （target_branch / base_branch / worktree_path，供写入 3.dev.md）；
#         git 项目但无 active worktree → block，由 Agent AskUserQuestion 确认
#         是否使用 worktree 及源分支（默认当前分支），确认后再 worktree-create。
# 【调用阶段】Phase 3 入口（phase3.md §〇），首个脚本。
# 【输入】--change-name <name>（必需，kebab-case）
# 【输出】stdout：GATE_PHASE3: pass|block + worktree: true|false + 上下文
#         （worktree=true 时：target_branch / base_branch / worktree_path）
#   exit 0：pass（非 git 或已有 active worktree）；exit 1：block（git 且无 active worktree）
# 【流程】定位 git 根 → 查登记表 active 记录 → 校验路径 → 输出结果。
# 【用法】bash <skill_root>/scripts/gate-phase3.sh --change-name user-management
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_agent-lib.sh
source "$SCRIPT_DIR/_agent-lib.sh"
# shellcheck source=_worktree-lib.sh
source "$SCRIPT_DIR/_worktree-lib.sh"

CHANGE_NAME=""
while [ $# -gt 0 ]; do
  case "$1" in
    --change-name) CHANGE_NAME="$2"; shift ;;
    --change-name=*) CHANGE_NAME="${1#*=}" ;;
    -h|--help) echo "用法: $0 --change-name <kebab-name>"; exit 0 ;;
    *) echo "未知参数: $1" >&2; exit 2 ;;
  esac
  shift
done

if [ -z "$CHANGE_NAME" ]; then
  echo "错误: 需要 --change-name" >&2
  exit 2
fi

# 非 git 项目 → 放行（单工作树，按 change 目录隔离）
if ! GIT_ROOT="$(dlc_wt_git_root 2>/dev/null)"; then
  echo "GATE_PHASE3: pass"
  echo "worktree: false"
  echo "reason: 非 git 项目（单工作树，按 change 目录隔离）"
  exit 0
fi

REG="$(dlc_wt_registry)"
row=""
if [ -f "$REG" ]; then
  row="$(awk -F'\t' -v c="$CHANGE_NAME" '$1==c && $8=="active"{print; exit}' "$REG")"
fi

if [ -n "$row" ]; then
  branch="$(printf '%s\n' "$row" | awk -F'\t' '{print $3}')"
  path="$(printf '%s\n' "$row" | awk -F'\t' '{print $4}')"
  base="$(printf '%s\n' "$row" | awk -F'\t' '{print $5}')"
  if [ -d "$GIT_ROOT/$path" ]; then
    echo "GATE_PHASE3: pass"
    echo "worktree: true"
    echo "target_branch: $branch"
    echo "base_branch: $base"
    echo "worktree_path: $GIT_ROOT/$path"
    exit 0
  fi
  echo "GATE_PHASE3: block"
  echo "worktree: false"
  echo "reason: 登记表有 active 记录但 worktree 路径缺失（状态不一致，请 worktree remove 后重建）"
  exit 1
fi

echo "GATE_PHASE3: block"
echo "worktree: false"
echo "reason: 该 change 无 active worktree"
echo "action: 由 Agent AskUserQuestion 确认是否使用 worktree 及源分支（默认当前分支），确认后 worktree-create"
exit 1
