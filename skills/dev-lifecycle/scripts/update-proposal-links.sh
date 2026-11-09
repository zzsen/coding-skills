#!/usr/bin/env bash
# =============================================================================
# update-proposal-links.sh — 归档后更新 OpenSpec 超链接
# =============================================================================
# 【功能】将 1/2/7 产物中 openspec/changes/<name> 替换为 openspec/archive/<date>-<name>。
# 【调用阶段】Phase 7 用户确认验收且 /opsx:archive 完成后。
# 【输入】
#   --plan-dir       必填
#   --change-name    必填
#   --archive-date   YYYY-MM-DD 必填
#   --dry-run        可选，只统计不写入
# 【输出】stdout：更新文件与 LINKS_UPDATED 计数；修改磁盘 Markdown
# 【流程】
#   1. 构造 from/to 路径前缀
#   2. 遍历 1.proposal.md、2.plan.md、7.acceptance.md
#   3. sed 全局替换（保留 .bak 后删除）
# 【用法】bash .../update-proposal-links.sh --plan-dir ... --change-name ... --archive-date 2026-07-02
# =============================================================================
set -euo pipefail

PLAN_DIR=""
CHANGE=""
ARCHIVE_DATE=""
DRY=false
while [ $# -gt 0 ]; do
  case "$1" in
    --plan-dir) PLAN_DIR="${2:-}"; shift 2 ;;
    --change-name) CHANGE="${2:-}"; shift 2 ;;
    --archive-date) ARCHIVE_DATE="${2:-}"; shift 2 ;;
    --dry-run) DRY=true ;;
    -h|--help)
      echo "用法: $0 --plan-dir <path> --change-name <name> --archive-date YYYY-MM-DD [--dry-run]"
      exit 0
      ;;
    *) echo "未知参数: $1" >&2; exit 1 ;;
  esac
done

[ -n "$PLAN_DIR" ] && [ -n "$CHANGE" ] && [ -n "$ARCHIVE_DATE" ] || {
  echo "错误: 需要 --plan-dir --change-name --archive-date" >&2; exit 1
}

FROM="openspec/changes/$CHANGE"
TO="openspec/archive/${ARCHIVE_DATE}-${CHANGE}"
total=0

for f in "$PLAN_DIR/1.proposal.md" "$PLAN_DIR/2.plan.md" "$PLAN_DIR/7.acceptance.md"; do
  [ -f "$f" ] || continue
  count=$(grep -c "$FROM" "$f" 2>/dev/null || echo 0)
  if [ "$count" -gt 0 ]; then
    echo "更新 $f ($count 处)"
    if [ "$DRY" = false ]; then
      sed -i.bak "s|$FROM|$TO|g" "$f" && rm -f "$f.bak"
    fi
    total=$((total + count))
  fi
done

echo "LINKS_UPDATED: $total"
[ "$DRY" = true ] && echo "(dry-run)"
