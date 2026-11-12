#!/usr/bin/env bash
# =============================================================================
# worktree-status.sh — 列出 worktree 及状态（dev-lifecycle）
# =============================================================================
# 【功能】汇总 git worktree list（git 权威）与登记表 .dev-lifecycle/worktrees.tsv，
#         输出每个 worktree 的分支、路径、HEAD、change-name、kind、base_branch、状态。
# 【调用阶段】场景判定 / resume：定位「未完成的 change 在哪个 worktree」。
# 【输入】--json 可选。
# 【输出】stdout：可读列表（每 worktree 一行）或 JSON 数组；exit 0（非仓库 exit 1）。
# 【流程】校验仓库 → git worktree list --porcelain → 逐 worktree 查登记表 → 输出。
# 【用法】bash <skill_root>/scripts/worktree-status.sh [--json]
# 【兼容】bash 3.2+（macOS 默认 /bin/bash），不使用关联数组。
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_agent-lib.sh
source "$SCRIPT_DIR/_agent-lib.sh"
# shellcheck source=_worktree-lib.sh
source "$SCRIPT_DIR/_worktree-lib.sh"

JSON=false
for arg in "$@"; do
  case "$arg" in
    --json) JSON=true ;;
    -h|--help) echo "用法: $0 [--json]"; exit 0 ;;
  esac
done

GIT_ROOT="$(dlc_wt_git_root)" || { echo "RESULT: FAIL（当前目录不是 git 仓库）" >&2; exit 1; }
REGISTRY="$(dlc_wt_registry)"

# 查登记表：$1=branch，输出 change_name|kind|base_branch|status（无记录输出空）
reg_lookup() {
  local branch="$1"
  [ -f "$REGISTRY" ] || return 0
  awk -F'\t' -v b="$branch" '$3==b{print $1"|"$2"|"$5"|"$8; exit}' "$REGISTRY" 2>/dev/null
}

# 输出一个 worktree 行/对象
# $1=path $2=head $3=branch
emit() {
  local path="$1" head="$2" branch="$3" rel info cn kind base status
  [ -n "$path" ] || return 0
  rel="${path#"$GIT_ROOT"/}"
  [ "$rel" = "$path" ] && rel="(main)"
  info="$(reg_lookup "$branch")"
  if [ -n "$info" ]; then
    IFS='|' read -r cn kind base status <<< "$info"
  else
    cn=""; kind=""; base=""; status="unknown"
  fi
  if [ "$JSON" = true ]; then
    printf '{"path":"%s","branch":"%s","head":"%s","change_name":"%s","kind":"%s","base_branch":"%s","status":"%s"}\n' \
      "$path" "$branch" "$head" "$cn" "$kind" "$base" "$status"
  else
    printf '%-45s branch=%-28s head=%.9s change=%-18s kind=%-7s base=%-10s status=%s\n' \
      "$rel" "$branch" "${head:0:9}" "${cn:--}" "${kind:--}" "${base:--}" "$status"
  fi
}

WTPATH=""; HEAD=""; BRANCH=""
while IFS= read -r line; do
  case "$line" in
    "worktree "*) WTPATH="${line#worktree }" ;;
    "HEAD "*)     HEAD="${line#HEAD }" ;;
    "branch "*)   BRANCH="${line#branch }" ;;
    "")           emit "$WTPATH" "$HEAD" "${BRANCH#refs/heads/}"; WTPATH=""; HEAD=""; BRANCH="" ;;
  esac
done < <(git -C "$GIT_ROOT" worktree list --porcelain)
# 最后一块（无尾随空行时）
emit "$WTPATH" "$HEAD" "${BRANCH#refs/heads/}"

echo "RESULT: OK"
