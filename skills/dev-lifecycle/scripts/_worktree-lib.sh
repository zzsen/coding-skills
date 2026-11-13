#!/usr/bin/env bash
# =============================================================================
# _worktree-lib.sh — worktree 隔离辅助库（dev-lifecycle）
# =============================================================================
# 【功能】worktree 隔离的公共函数：根目录、登记表路径、分支/路径命名、仓库定位。
# 【调用方】被 worktree-create.sh / worktree-status.sh / worktree-merge-back.sh /
#           gate-phase3.sh source，不单独执行。
# 【导出函数】
#   dlc_wt_root            worktree 根目录（默认 .worktrees，DEVLC_WORKTREES_ROOT 可覆盖）
#   dlc_wt_registry        登记表路径 .dev-lifecycle/worktrees.tsv
#   dlc_wt_branch <kind> <change-name>      分支名 {kind}-{change-name}
#   dlc_wt_path <branch>                    worktree 路径 <root>/<branch>
#   dlc_wt_git_root                         仓库根目录（非仓库返回非零）
#   dlc_wt_current_branch                   当前分支名
#   dlc_wt_registry_set_status <branch> <status>   更新登记表状态列
# 【说明】登记表为 TSV，列序：change_name \t kind \t branch \t path \t base_branch \t
#         base_commit \t created_at \t status（active|merged|abandoned）。
#         path 为相对仓库根的路径（如 .worktrees/feature-user-management），便于迁移。
# 【依赖】source 前需已 source _agent-lib.sh（本库亦自行 source，幂等）。
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_agent-lib.sh
source "$SCRIPT_DIR/_agent-lib.sh"

dlc_wt_root() {
  printf '%s' "${DEVLC_WORKTREES_ROOT:-.worktrees}"
}

dlc_wt_registry() {
  printf '%s' "$(dlc_state_dir)/worktrees.tsv"
}

dlc_wt_branch() {
  local kind="$1" change_name="$2"
  printf '%s-%s' "$kind" "$change_name"
}

dlc_wt_path() {
  local branch="$1"
  printf '%s/%s' "$(dlc_wt_root)" "$branch"
}

dlc_wt_git_root() {
  git rev-parse --show-toplevel 2>/dev/null || return 1
}

dlc_wt_current_branch() {
  git branch --show-current 2>/dev/null || return 1
}

# 更新登记表某 branch 的 status 列（active|merged|abandoned）
# 用法：dlc_wt_registry_set_status <branch> <status>
dlc_wt_registry_set_status() {
  local branch="$1" status="$2" reg tmp
  reg="$(dlc_wt_registry)"
  [ -f "$reg" ] || { printf '登记表不存在: %s\n' "$reg" >&2; return 1; }
  tmp="$(mktemp "${TMPDIR:-/tmp}/wt-reg.XXXXXX")"
  awk -F'\t' -v OFS='\t' -v b="$branch" -v s="$status" \
    'BEGIN{hit=0} { if ($3==b) { $8=s; hit=1 } print } END{ if (!hit) print "RESULT_MISSING" > "/dev/stderr" }' \
    "$reg" > "$tmp"
  # 未命中时不覆盖原文件
  if awk -F'\t' -v OFS='\t' -v b="$branch" '$3==b{found=1} END{exit !found}' "$reg"; then
    mv "$tmp" "$reg"
  else
    rm -f "$tmp"
    return 1
  fi
}
