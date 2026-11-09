#!/usr/bin/env bash
#
# git_add_commit.sh - 在指定 Git 仓库执行 git add + git commit
#
# 用法:
#   ./git_add_commit.sh <repo_path> <files> <commit_msg>
#
# 参数:
#   1. repo_path   Git 仓库根目录
#   2. files       待 add 文件，逗号分隔（相对仓库根），如 "a.go,b/c.go"
#   3. commit_msg  Commit message（与计划文案完全一致）
#
# 示例:
#   ./git_add_commit.sh /path/to/backend "pkg/a.go,pkg/b.go" "fix: 修复时长解析"
#
# 成功输出:
#   RESULT: OK
#   COMMIT: <short_hash> <subject>
#
# 仅允许: git add / git commit；暂存区异常时中止且不自动 reset。
#

set -euo pipefail

usage() {
  sed -n '3,18p' "$0" | sed 's/^# \?//'
  exit 2
}

fail() {
  echo "RESULT: FAIL"
  echo "REASON: $1"
  exit 1
}

if [[ $# -lt 3 ]]; then
  usage
fi

REPO_PATH="$1"
FILES_RAW="$2"
COMMIT_MSG="$3"

# 去掉计划文档可能带来的成对反引号
if [[ ${#COMMIT_MSG} -ge 2 && "${COMMIT_MSG:0:1}" == '`' && "${COMMIT_MSG: -1}" == '`' ]]; then
  COMMIT_MSG="${COMMIT_MSG:1:${#COMMIT_MSG}-2}"
fi

COMMIT_MSG="$(printf '%s' "$COMMIT_MSG" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
[[ -n "$COMMIT_MSG" ]] || fail "CommitMsg 为空"
[[ -d "$REPO_PATH" ]] || fail "RepoPath 不存在: $REPO_PATH"

REPO_PATH="$(cd "$REPO_PATH" && pwd)"
git -C "$REPO_PATH" rev-parse --git-dir >/dev/null 2>&1 || fail "路径不是 Git 仓库: $REPO_PATH"

# 解析逗号分隔文件列表（兼容 bash 3.2）
OLD_IFS="$IFS"
IFS=','
# shellcheck disable=SC2206
FILE_PARTS=($FILES_RAW)
IFS="$OLD_IFS"

FILES=()
for f in "${FILE_PARTS[@]}"; do
  f="$(printf '%s' "$f" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/^["'\'']//' -e 's/["'\'']$//')"
  [[ -n "$f" ]] && FILES+=("$f")
done
[[ ${#FILES[@]} -gt 0 ]] || fail "Files 为空"

echo "REPO: $REPO_PATH"
echo "FILES (${#FILES[@]}):"
for f in "${FILES[@]}"; do
  echo "  - $f"
done
echo "MSG: $COMMIT_MSG"

normalize() {
  printf '%s' "$1" | tr '\\' '/'
}

# 暂存区预检
STAGED_TEXT="$(git -C "$REPO_PATH" diff --cached --name-only | sed '/^$/d' || true)"
skip_add=0
if [[ -n "$STAGED_TEXT" ]]; then
  unexpected=""
  while IFS= read -r sf; do
    [[ -z "$sf" ]] && continue
    key="$(normalize "$sf")"
    found=0
    for pf in "${FILES[@]}"; do
      if [[ "$(normalize "$pf")" == "$key" ]]; then
        found=1
        break
      fi
    done
    if [[ $found -eq 0 ]]; then
      unexpected="${unexpected}${sf}"$'\n'
    fi
  done <<< "$STAGED_TEXT"

  if [[ -n "$unexpected" ]]; then
    echo "UNEXPECTED_STAGED:"
    printf '%s' "$unexpected" | sed '/^$/d' | sed 's/^/  - /'
    fail "暂存区存在不属于本次 Commit 的文件，已中止（不自动 reset）"
  fi

  missing=0
  for pf in "${FILES[@]}"; do
    key="$(normalize "$pf")"
    found=0
    while IFS= read -r sf; do
      [[ -z "$sf" ]] && continue
      if [[ "$(normalize "$sf")" == "$key" ]]; then
        found=1
        break
      fi
    done <<< "$STAGED_TEXT"
    if [[ $found -eq 0 ]]; then
      missing=1
      break
    fi
  done

  if [[ $missing -eq 0 ]]; then
    echo "STAGED_MATCH: skip git add"
    skip_add=1
  else
    fail "暂存区与计划文件不完全一致，已中止"
  fi
fi

if [[ $skip_add -eq 0 ]]; then
  git -C "$REPO_PATH" add -- "${FILES[@]}"
fi

STAGED_AFTER_TEXT="$(git -C "$REPO_PATH" diff --cached --name-only | sed '/^$/d' || true)"
[[ -n "$STAGED_AFTER_TEXT" ]] || fail "暂存区为空，无法 commit"

STAGED_COUNT="$(printf '%s\n' "$STAGED_AFTER_TEXT" | sed '/^$/d' | wc -l | tr -d ' ')"

MSG_FILE="$REPO_PATH/.git/COMMIT_MSG_TEMP"
cleanup() {
  rm -f "$MSG_FILE"
}
trap cleanup EXIT

printf '%s\n' "$COMMIT_MSG" >"$MSG_FILE"
git -C "$REPO_PATH" commit -F "$MSG_FILE"

HEAD="$(git -C "$REPO_PATH" log -1 --oneline)"
echo "RESULT: OK"
echo "COMMIT: $HEAD"
echo "STAGED_FILES: $STAGED_COUNT"
exit 0
