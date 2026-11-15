#!/usr/bin/env bash
# =============================================================================
# detect-repos.sh — 探测项目仓库布局（Phase 1 前，初始化 project-config 时）
# =============================================================================
# 【功能】判断当前项目是 git 单仓库 / 多仓库 / 非 git，输出仓库类型与仓库列表，
#         供 agent 填入 project-config「仓库布局」。后续 Phase 3 worktree 决策据此
#         只对「方案需要改动的仓库」建 worktree，无需再到 Phase 3 懒探测。
# 【调用阶段】exploration §四（project-config 生成时），首个探测脚本。
# 【输入】无（在项目根目录执行）
# 【输出】stdout：
#   REPO_TYPE: single → 一行 repo: <相对路径>|<base>|<绝对路径>
#   REPO_TYPE: multi  → 每仓库一行 repo: <相对路径>|<base>|<绝对路径>
#   REPO_TYPE: none   → 无 repo 行
#   exit 0
# 【用法】bash <skill_root>/scripts/detect-repos.sh
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_agent-lib.sh
source "$SCRIPT_DIR/_agent-lib.sh"
# shellcheck source=_worktree-lib.sh
source "$SCRIPT_DIR/_worktree-lib.sh"

cwd="$(pwd)"

# 1. cwd 本身是 git 仓库
if GIT_ROOT="$(dlc_wt_git_root 2>/dev/null)"; then
  base="$(dlc_wt_current_branch 2>/dev/null || true)"
  [ -n "$base" ] || base="detached"
  echo "REPO_TYPE: single"
  echo "repo: .|${base}|${GIT_ROOT}"
  exit 0
fi

# 2. cwd 非 git，查嵌套仓库
repos="$(dlc_wt_find_repos 3)"
if [ -z "$repos" ]; then
  echo "REPO_TYPE: none"
  exit 0
fi

echo "REPO_TYPE: multi"
while IFS= read -r r; do
  [ -n "$r" ] || continue
  base="$(git -C "$r" branch --show-current 2>/dev/null || true)"
  [ -n "$base" ] || base="detached"
  rel="${r#"$cwd"/}"
  [ "$rel" = "$r" ] && rel="$r"
  echo "repo: ${rel}|${base}|${r}"
done <<< "$repos"
exit 0
