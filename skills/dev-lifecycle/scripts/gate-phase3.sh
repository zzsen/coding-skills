#!/usr/bin/env bash
# =============================================================================
# gate-phase3.sh — Phase 3 worktree 状态查询
# =============================================================================
# 【功能】查询某 change 在指定 git 仓库内是否已有 active worktree，并输出其上下文。
#         注意：**本脚本只做状态查询，不做决策**——「选哪个仓库 / 是否用 worktree」
#         由 phase3.md §〇 读 project-config（detect-repos 前置记录）+ AskUserQuestion 决定。
#         输出分支：
#         ① git 仓库（cwd 在仓库内或 --repo 指定）且该 change 已有 active worktree
#           → pass + target_branch / base_branch / worktree_path；
#         ② git 仓库但无 active worktree → block（reason=无 active worktree）；
#         ③ cwd 非 git 但子目录存在 git 仓库（多仓库）→ block + 列 repo 行（兜底）；
#         ④ 完全非 git → block（reason=非 git）。
# 【调用阶段】Phase 3：worktree-create 之后确认 / 续做（resume）定位 / 状态一致性校验。
# 【输入】--change-name <name>（必需）；--repo <path>（可选，显式指定 git 仓库根）
# 【输出】stdout：GATE_PHASE3: pass|block + git: true|false + worktree: true|false
#         + 上下文（pass 时：target_branch / base_branch / worktree_path；多仓库时：repo 行）
#   exit 0：pass；exit 1：block
# 【流程】解析仓库根（--repo → cwd → 嵌套探测）→ 查登记表 active 记录 → 校验路径 → 输出。
# 【用法】bash <skill_root>/scripts/gate-phase3.sh --change-name user-management [--repo /path/to/repo]
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_agent-lib.sh
source "$SCRIPT_DIR/_agent-lib.sh"
# shellcheck source=_worktree-lib.sh
source "$SCRIPT_DIR/_worktree-lib.sh"

CHANGE_NAME=""
REPO=""
while [ $# -gt 0 ]; do
  case "$1" in
    --change-name) CHANGE_NAME="$2"; shift ;;
    --change-name=*) CHANGE_NAME="${1#*=}" ;;
    --repo) REPO="$2"; shift ;;
    --repo=*) REPO="${1#*=}" ;;
    -h|--help) echo "用法: $0 --change-name <kebab-name> [--repo <git-root>]"; exit 0 ;;
    *) echo "未知参数: $1" >&2; exit 2 ;;
  esac
  shift
done

if [ -z "$CHANGE_NAME" ]; then
  echo "错误: 需要 --change-name" >&2
  exit 2
fi

# ── 解析 git 根：--repo → cwd → 嵌套仓库探测 ────────────────────────────────
GIT_ROOT=""
if [ -n "$REPO" ]; then
  GIT_ROOT="$(dlc_wt_repo_root "$REPO")" || {
    echo "GATE_PHASE3: block"
    echo "git: false"
    echo "worktree: false"
    echo "reason: --repo 指定的路径不是 git 仓库（repo=$REPO）"
    exit 1
  }
elif GIT_ROOT="$(dlc_wt_git_root 2>/dev/null)"; then
  : # cwd 处于 git 仓库内
else
  REPOS="$(dlc_wt_find_repos 3)"
  if [ -z "$REPOS" ]; then
    # 完全非 git
    echo "GATE_PHASE3: block"
    echo "git: false"
    echo "worktree: false"
    echo "reason: 当前目录不是 git 仓库（cwd=$(pwd)），且未发现嵌套 git 仓库"
    exit 1
  fi
  # 多仓库场景：cwd 非 git，但子目录存在 git 仓库（兜底，供 agent 定位）
  echo "GATE_PHASE3: block"
  echo "git: true"
  echo "nested_repos: true"
  echo "reason: cwd 不是 git 仓库，但发现子目录 git 仓库（多仓库场景）"
  while IFS= read -r r; do
    [ -n "$r" ] && echo "repo: $r"
  done <<< "$REPOS"
  exit 1
fi

REG="$(dlc_wt_registry "$GIT_ROOT")"
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
    echo "git: true"
    echo "worktree: true"
    echo "target_branch: $branch"
    echo "base_branch: $base"
    echo "worktree_path: $GIT_ROOT/$path"
    exit 0
  fi
  echo "GATE_PHASE3: block"
  echo "git: true"
  echo "worktree: false"
  echo "reason: 登记表有 active 记录但 worktree 路径缺失（状态不一致，请 worktree remove 后重建）"
  exit 1
fi

echo "GATE_PHASE3: block"
echo "git: true"
echo "worktree: false"
echo "reason: 该 change 无 active worktree（如需隔离，先 worktree-create）"
exit 1
