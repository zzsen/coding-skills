#!/usr/bin/env bash
# =============================================================================
# worktree-merge-back.sh — 交付：rebase → merge 回源分支 → 清理 worktree
# =============================================================================
# 【功能】Phase 7 完成 archive + 验收通过后执行：把 feature 分支 rebase 到源分支最新，
#         再 merge 回源分支；成功后移除 worktree（默认删除已合并分支）并更新登记表
#         status=merged。**冲突一律停下交用户，绝不自动 resolve。**
# 【调用阶段】Phase 7 完成 /opsx:archive 与验收之后。
# 【输入】--change-name <name>（必需）--kind feature|fix（必需）
#         --base-branch <branch>（可选，默认取自登记表；取不到则必需）
#         --repo <path>（可选，显式指定 git 仓库根，多仓库场景用）
#         --keep-branch（可选，merge 后保留分支，默认删除）
#         --no-ff（默认 merge 用 --no-ff；不加则允许 fast-forward）
#         --no-rebase（默认 rebase；跳过用此标志）
#         --dry-run（只预览计划不执行）
# 【输出】stdout：每步 STEP / RESULT；exit 0 成功，非 0 失败（含冲突 / 脏工作树 / 分支未合并）。
# 【流程】定位分支与 worktree → 校验（存在 / 干净 / 源分支匹配）→ [rebase] → [merge]
#         → worktree remove → [branch delete] → 更新登记表。
# 【用法】bash <skill_root>/scripts/worktree-merge-back.sh --change-name user-management --kind feature
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
REPO=""
KEEP_BRANCH=false
NO_FF=true
REBASE=true
DRY_RUN=false

while [ $# -gt 0 ]; do
  case "$1" in
    --change-name)   CHANGE_NAME="$2"; shift ;;
    --change-name=*) CHANGE_NAME="${1#*=}" ;;
    --kind)          KIND="$2"; shift ;;
    --kind=*)        KIND="${1#*=}" ;;
    --base-branch)   BASE_BRANCH="$2"; shift ;;
    --base-branch=*) BASE_BRANCH="${1#*=}" ;;
    --repo)          REPO="$2"; shift ;;
    --repo=*)        REPO="${1#*=}" ;;
    --keep-branch)   KEEP_BRANCH=true ;;
    --no-ff)         NO_FF=true ;;
    --ff)            NO_FF=false ;;
    --no-rebase)     REBASE=false ;;
    --dry-run)       DRY_RUN=true ;;
    -h|--help) echo "用法: $0 --change-name <name> --kind feature|fix [--base-branch <branch>] [--repo <git-root>] [--keep-branch] [--ff] [--no-rebase] [--dry-run]"; exit 0 ;;
    *) echo "未知参数: $1" >&2; exit 2 ;;
  esac
  shift
done

if [ -z "$CHANGE_NAME" ]; then echo "RESULT: FAIL（缺少 --change-name）" >&2; exit 2; fi
if [ "$KIND" != "feature" ] && [ "$KIND" != "fix" ]; then
  echo "RESULT: FAIL（--kind 须为 feature 或 fix）" >&2; exit 2
fi

if [ -n "$REPO" ]; then
  GIT_ROOT="$(dlc_wt_repo_root "$REPO")" || { echo "RESULT: FAIL（--repo 不是 git 仓库: $REPO）" >&2; exit 1; }
else
  GIT_ROOT="$(dlc_wt_git_root)" || { echo "RESULT: FAIL（当前目录不是 git 仓库，请 cd 到仓库根或用 --repo 指定）" >&2; exit 1; }
fi

BRANCH="$(dlc_wt_branch "$KIND" "$CHANGE_NAME")"
WT_PATH="$GIT_ROOT/$(dlc_wt_path "$BRANCH")"

# 从登记表补 base_branch
REGISTRY="$(dlc_wt_registry "$GIT_ROOT")"
if [ -z "$BASE_BRANCH" ] && [ -f "$REGISTRY" ]; then
  BASE_BRANCH="$(awk -F'\t' -v b="$BRANCH" '$3==b{print $5; exit}' "$REGISTRY")"
fi
if [ -z "$BASE_BRANCH" ]; then
  BASE_BRANCH="$(dlc_wt_current_branch)" || { echo "RESULT: FAIL（无法确定源分支，请用 --base-branch 指定）" >&2; exit 1; }
fi

echo "STEP 定位: branch=$BRANCH worktree=$WT_PATH base=$BASE_BRANCH"

# 校验 worktree 存在且分支匹配
if ! git -C "$GIT_ROOT" worktree list --porcelain | grep -qFx "worktree $WT_PATH"; then
  echo "RESULT: FAIL（worktree 不存在: $WT_PATH）" >&2; exit 1
fi
WT_CUR="$(git -C "$WT_PATH" branch --show-current 2>/dev/null || true)"
if [ "$WT_CUR" != "$BRANCH" ]; then
  echo "RESULT: FAIL（worktree 当前分支 $WT_CUR 与 $BRANCH 不符）" >&2; exit 1
fi

# 校验 worktree 干净
if [ -n "$(git -C "$WT_PATH" status --porcelain)" ]; then
  echo "RESULT: FAIL（worktree 有未提交改动，先 git-commit-planner 提交后再交付）" >&2; exit 1
fi
# 校验主工作树干净且在源分支上
MAIN_CUR="$(git -C "$GIT_ROOT" branch --show-current 2>/dev/null || true)"
if [ "$MAIN_CUR" != "$BASE_BRANCH" ]; then
  echo "RESULT: FAIL（主工作树当前在 ${MAIN_CUR}，须切到源分支 ${BASE_BRANCH} 再交付）" >&2; exit 1
fi
# 主工作树：仅校验「已跟踪改动」（未跟踪的运行时目录 .dev-lifecycle/.worktrees/dev-plan 属预期，忽略）
if [ -n "$(git -C "$GIT_ROOT" status --porcelain | grep -v '^??')" ]; then
  echo "RESULT: FAIL（主工作树有未提交的已跟踪改动，先处理干净再交付）" >&2; exit 1
fi

if [ "$DRY_RUN" = true ]; then
  echo "DRY_RUN: 将执行 — rebase($REBASE) → merge($NO_FF → --no-ff=$NO_FF) → worktree remove → branch delete($([ "$KEEP_BRANCH" = false ] && echo yes || echo no))"
  echo "RESULT: DRY_RUN_OK"
  exit 0
fi

# ── rebase ──────────────────────────────────────────────────────────────────
if [ "$REBASE" = true ]; then
  echo "STEP rebase: $BRANCH onto $BASE_BRANCH"
  set +e
  git -C "$WT_PATH" rebase "$BASE_BRANCH"
  RC=$?
  set -e
  if [ "$RC" -ne 0 ]; then
    echo "RESULT: FAIL（rebase 冲突或失败，rc=${RC}；请在 $WT_PATH 内解决冲突后重跑本脚本）" >&2
    exit "$RC"
  fi
  echo "STEP rebase: 完成"
else
  echo "STEP rebase: 跳过（--no-rebase）"
fi

# ── merge ───────────────────────────────────────────────────────────────────
MERGE_ARGS=(merge)
[ "$NO_FF" = true ] && MERGE_ARGS+=(--no-ff)
MERGE_ARGS+=("$BRANCH")
echo "STEP merge: ${MERGE_ARGS[*]}"
set +e
git -C "$GIT_ROOT" "${MERGE_ARGS[@]}"
RC=$?
set -e
if [ "$RC" -ne 0 ]; then
  echo "RESULT: FAIL（merge 冲突，rc=${RC}；请在主工作树解决冲突后完成合并，再重跑本脚本）" >&2
  exit "$RC"
fi
echo "STEP merge: 完成"

# ── worktree remove ─────────────────────────────────────────────────────────
echo "STEP worktree remove: $WT_PATH"
git -C "$GIT_ROOT" worktree remove "$WT_PATH"
echo "STEP worktree remove: 完成"

# ── branch delete ───────────────────────────────────────────────────────────
if [ "$KEEP_BRANCH" = false ]; then
  echo "STEP branch delete: $BRANCH"
  set +e
  git -C "$GIT_ROOT" branch -d "$BRANCH"
  RC=$?
  set -e
  if [ "$RC" -ne 0 ]; then
    echo "WARN: 分支 $BRANCH 未能安全删除（rc=${RC}，可能 --no-ff 未将分支标记为已合并），请手动确认"
  else
    echo "STEP branch delete: 完成"
  fi
fi

# ── 更新登记表 ──────────────────────────────────────────────────────────────
if [ -f "$REGISTRY" ]; then
  dlc_wt_registry_set_status "$BRANCH" "merged" "$GIT_ROOT" \
    && echo "STEP 登记表: status=merged" \
    || echo "WARN: 登记表无该分支记录，跳过状态更新"
fi

echo "RESULT: OK（$BRANCH 已交付回 ${BASE_BRANCH}）"
