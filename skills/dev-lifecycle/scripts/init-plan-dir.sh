#!/usr/bin/env bash
# =============================================================================
# init-plan-dir.sh — 创建 dev-plan 计划目录
# =============================================================================
# 【功能】按 SKILL §4.1 规范创建带时间戳的计划目录及 lint-results/ 子目录。
# 【调用阶段】Phase 1 前（新需求场景 E）。
# 【输入】
#   --type    feat|fix|refactor|perf|docs（必填）
#   --detail  kebab-case 功能描述（必填）
# 【输出】stdout：新建计划目录相对路径；磁盘创建目录；exit 0
# 【流程】
#   1. 校验 type / detail
#   2. 调用 timestamp 获取 YYYYMM、YYYYMMDD、dir-ts
#   3. mkdir dev-plan/<YYYYMM>/<YYYYMMDD>/<ts>_<type>_<detail>/lint-results
#   4. 打印路径供 Agent 后续引用
# 【用法】bash <skill_root>/scripts/init-plan-dir.sh --type feat --detail user-mgmt
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TYPE=""
DETAIL=""

while [ $# -gt 0 ]; do
  case "$1" in
    --type) TYPE="${2:-}"; shift 2 ;;
    --detail) DETAIL="${2:-}"; shift 2 ;;
    -h|--help)
      echo "用法: $0 --type feat|fix|refactor|perf|docs --detail <kebab-case>"
      exit 0
      ;;
    *) echo "未知参数: $1" >&2; exit 1 ;;
  esac
done

if [ -z "$TYPE" ] || [ -z "$DETAIL" ]; then
  echo "错误: 必须指定 --type 和 --detail" >&2
  exit 1
fi

case "$TYPE" in
  feat|fix|refactor|perf|docs) ;;
  *) echo "错误: 无效 type: $TYPE" >&2; exit 1 ;;
esac

YYYYMMDD=$(bash "$SCRIPT_DIR/timestamp.sh" --format date)
YYYYMM="${YYYYMMDD:0:6}"
TS=$(bash "$SCRIPT_DIR/timestamp.sh" --format dir-ts)
PLAN_DIR="dev-plan/$YYYYMM/$YYYYMMDD/${TS}_${TYPE}_${DETAIL}"
mkdir -p "$PLAN_DIR/lint-results"
echo "$PLAN_DIR"
