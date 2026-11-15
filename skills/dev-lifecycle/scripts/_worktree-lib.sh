#!/usr/bin/env bash
# =============================================================================
# _worktree-lib.sh — worktree 隔离辅助库（dev-lifecycle）
# =============================================================================
# 【功能】worktree 隔离的公共函数：根目录、登记表路径、分支/路径命名、仓库定位。
# 【调用方】被 worktree-create.sh / worktree-status.sh / worktree-merge-back.sh /
#           gate-phase3.sh source，不单独执行。
# 【导出函数】
#   dlc_wt_root            worktree 根目录（默认 .worktrees，DEVLC_WORKTREES_ROOT 可覆盖）
#   dlc_wt_registry [git_root]              登记表路径 .dev-lifecycle/worktrees.tsv
#                                            （带 git_root 时锚定到仓库根，支持多仓库）
#   dlc_wt_branch <kind> <change-name>      分支名 {kind}-{change-name}
#   dlc_wt_path <branch>                    worktree 路径 <root>/<branch>
#   dlc_wt_git_root                         仓库根目录（从 cwd 向上探测，非仓库返回非零）
#   dlc_wt_repo_root <dir>                  给定目录的 git 顶层（--repo 校验用）
#   dlc_wt_find_repos [maxdepth]            在 cwd 下找嵌套 git 仓库根（多仓库场景）
#   dlc_wt_current_branch                   当前分支名
#   dlc_wt_registry_set_status <branch> <status> [git_root]  更新登记表状态列
# 【说明】登记表为 TSV，列序：change_name \t kind \t branch \t path \t base_branch \t
#         base_commit \t created_at \t status（active|merged|abandoned）\t repo（git 根，绝对路径）。
#         path 为相对仓库根的路径（如 .worktrees/feature-user-management）；repo 用于多仓库场景定位。
# 【依赖】source 前需已 source _agent-lib.sh（本库亦自行 source，幂等）。
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_agent-lib.sh
source "$SCRIPT_DIR/_agent-lib.sh"

dlc_wt_root() {
  printf '%s' "${DEVLC_WORKTREES_ROOT:-.worktrees}"
}

dlc_wt_registry() {
  # 可选参数：git 根目录（多仓库场景：登记表锚定到仓库根而非 cwd）
  local git_root="${1:-}"
  if [ -n "$git_root" ]; then
    printf '%s/.dev-lifecycle/worktrees.tsv' "$git_root"
  else
    printf '%s' "$(dlc_state_dir)/worktrees.tsv"
  fi
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

# 校验并输出给定目录（或 --repo 路径）的 git 顶层；失败返回非零
dlc_wt_repo_root() {
  local target="${1:-.}"
  git -C "$target" rev-parse --show-toplevel 2>/dev/null || return 1
}

# 在 cwd 下查找 git 仓库根（「workspace 根非 git、子目录才是 git 仓库」场景）。
# 输出绝对路径每行一个，排序去重；找不到输出空。
# 用法：dlc_wt_find_repos [maxdepth]（默认 3）
dlc_wt_find_repos() {
  local maxdepth="${1:-3}"
  find "$(pwd)" -maxdepth "$maxdepth" \( -name .git -type d -o -name .git -type f \) 2>/dev/null \
    | sed 's#/\.git$##' \
    | sort -u
}

# 更新登记表某 branch 的 status 列（active|merged|abandoned）
# 用法：dlc_wt_registry_set_status <branch> <status>
dlc_wt_registry_set_status() {
  local branch="$1" status="$2" git_root="${3:-}" reg tmp
  reg="$(dlc_wt_registry "$git_root")"
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
