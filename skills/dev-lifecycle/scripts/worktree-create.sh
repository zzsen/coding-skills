#!/usr/bin/env bash
# =============================================================================
# worktree-create.sh — 创建隔离 worktree（dev-lifecycle）
# =============================================================================
# 【功能】在当前 git 仓库内，从指定源分支（默认当前分支）创建功能/修复隔离 worktree：
#         git worktree add -b {kind}-{change-name} <root>/<branch> <base-branch>，
#         并登记到 .dev-lifecycle/worktrees.tsv（status=active）。
# 【调用阶段】Phase 2 确认后、Phase 3 前。**源分支须由 Agent 先经 AskUserQuestion
#         与用户确认**，再把确认后的分支作为 --base-branch 传入；分支名/前缀由需求
#         分析自动得出，无需用户确认。
# 【输入】--change-name <name>（必需，kebab-case）
#         --kind feature|fix（必需，按需求类型判定）
#         --base-branch <branch>（可选，默认当前分支）
#         --worktrees-root <dir>（可选，默认 .worktrees / DEVLC_WORKTREES_ROOT）
# 【输出】stdout：WORKTREE_CREATED: branch=... path=... base=... base_commit=...；
#         登记表追加一行。exit 0 成功；非 0 失败（非仓库 / 参数缺失 / 分支或路径已存在）。
# 【流程】校验仓库与参数 → 计算分支名/路径 → 查重 → git worktree add → 取 base_commit
#         → 写登记表 → 输出结果。
# 【用法】bash <skill_root>/scripts/worktree-create.sh --change-name user-management --kind feature --base-branch main
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_agent-lib.sh
source "$SCRIPT_DIR/_agent-lib.sh"
# shellcheck source=_worktree-lib.sh
source "$SCRIPT_DIR/_worktree-lib.sh"

CHANGE_NAME=""
KIND=""
BASE_BRANCH=""
WORKTREES_ROOT="$(dlc_wt_root)"

while [ $# -gt 0 ]; do
  case "$1" in
    --change-name)      CHANGE_NAME="$2"; shift ;;
    --change-name=*)    CHANGE_NAME="${1#*=}" ;;
    --kind)             KIND="$2"; shift ;;
    --kind=*)           KIND="${1#*=}" ;;
    --base-branch)      BASE_BRANCH="$2"; shift ;;
    --base-branch=*)    BASE_BRANCH="${1#*=}" ;;
    --worktrees-root)   WORKTREES_ROOT="$2"; shift ;;
    --worktrees-root=*) WORKTREES_ROOT="${1#*=}" ;;
    -h|--help) echo "用法: $0 --change-name <name> --kind feature|fix [--base-branch <branch>]"; exit 0 ;;
    *) echo "未知参数: $1" >&2; exit 2 ;;
  esac
  shift
done

if [ -z "$CHANGE_NAME" ]; then echo "RESULT: FAIL（缺少 --change-name）" >&2; exit 2; fi
if [ "$KIND" != "feature" ] && [ "$KIND" != "fix" ]; then
  echo "RESULT: FAIL（--kind 须为 feature 或 fix）" >&2; exit 2
fi

GIT_ROOT="$(dlc_wt_git_root)" || { echo "RESULT: FAIL（当前目录不是 git 仓库）" >&2; exit 1; }

# 源分支：默认当前分支
if [ -z "$BASE_BRANCH" ]; then
  BASE_BRANCH="$(dlc_wt_current_branch)" || { echo "RESULT: FAIL（无法确定当前分支）" >&2; exit 1; }
fi

BRANCH="$(dlc_wt_branch "$KIND" "$CHANGE_NAME")"
WT_PATH="$GIT_ROOT/$WORKTREES_ROOT/$BRANCH"
WT_REL="$WORKTREES_ROOT/$BRANCH"

# 查重
if git -C "$GIT_ROOT" show-ref --verify --quiet "refs/heads/$BRANCH"; then
  echo "RESULT: FAIL（分支 $BRANCH 已存在）" >&2; exit 1
fi
if [ -e "$WT_PATH" ]; then
  echo "RESULT: FAIL（路径 $WT_PATH 已存在）" >&2; exit 1
fi

# 创建 worktree
git -C "$GIT_ROOT" worktree add -b "$BRANCH" "$WT_PATH" "$BASE_BRANCH"
BASE_COMMIT="$(git -C "$GIT_ROOT" rev-parse --short "$BASE_BRANCH")"

# 确保 .worktrees/ 被 .gitignore 忽略（幂等），避免主工作树 git status 噪声与误提交
GI="$GIT_ROOT/.gitignore"
if [ -f "$GI" ]; then
  if ! grep -qFx '.worktrees/' "$GI"; then
    printf '\n.worktrees/\n' >> "$GI"
  fi
else
  printf '.worktrees/\n' > "$GI"
fi

# 登记
REGISTRY="$(dlc_wt_registry)"
mkdir -p "$(dirname "$REGISTRY")"
CREATED_AT="$(date +"%Y-%m-%d %H:%M:%S")"
printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
  "$CHANGE_NAME" "$KIND" "$BRANCH" "$WT_REL" "$BASE_BRANCH" "$BASE_COMMIT" "$CREATED_AT" "active" \
  >> "$REGISTRY"

echo "WORKTREE_CREATED: branch=$BRANCH path=$WT_PATH base=$BASE_BRANCH base_commit=$BASE_COMMIT"
echo "RESULT: OK"
