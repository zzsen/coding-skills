#!/usr/bin/env bash
# =============================================================================
# timestamp.sh — 系统时间输出
# =============================================================================
# 【功能】从 Shell 获取真实系统时间，禁止 Agent 编造时间戳。
# 【调用阶段】全阶段（产物头、计划目录名、任务编号日期、归档日期等）。
# 【输入】--format datetime|date|dir-ts|iso-date（默认 datetime）
# 【输出】stdout 单行时间字符串；exit 0
# 【流程】解析 format → date 格式化输出
# 【用法】bash <skill_root>/scripts/timestamp.sh [--format dir-ts]
# =============================================================================
set -euo pipefail

FORMAT="datetime"
for arg in "$@"; do
  case "$arg" in
    --format=*) FORMAT="${arg#*=}" ;;
    --format) shift; FORMAT="${1:-datetime}" ;;
    -h|--help)
      echo "用法: $0 [--format datetime|date|dir-ts|iso-date]"
      exit 0
      ;;
  esac
done

case "$FORMAT" in
  datetime) date +"%Y-%m-%d %H:%M:%S" ;;   # 产物「生成时间」「最后更新」
  date) date +"%Y%m%d" ;;                   # 任务编号 T-YYYYMMDD-N
  dir-ts) date +"%Y%m%d%H%M%S" ;;           # dev-plan 目录名时间戳
  iso-date) date +"%Y-%m-%d" ;;             # OpenSpec 归档目录日期
  *) echo "未知 format: $FORMAT" >&2; exit 1 ;;
esac
