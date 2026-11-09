#!/usr/bin/env bash
# =============================================================================
# safe-list-files.sh — 白名单探索路径列表
# =============================================================================
# 【功能】列出允许 Read/Glob 的路径，排除 exploration.md §一黑名单目录，替代 Glob **/*。
# 【调用阶段】探索 / 生成 project-config 前。
# 【输入】--scope backend|frontend|all（默认 all）
# 【输出】stdout：去重排序后的相对路径列表；exit 0
# 【流程】
#   1. 按 scope 输出 go.mod、package.json 等定点文件
#   2. find + grep 过滤 node_modules/.git 等
# 【用法】bash .../safe-list-files.sh --scope all
# =============================================================================
set -euo pipefail

SCOPE="all"
while [ $# -gt 0 ]; do
  case "$1" in
    --scope) SCOPE="${2:-all}"; shift 2 ;;
    -h|--help) echo "用法: $0 [--scope backend|frontend|all]"; exit 0 ;;
    *) echo "未知参数: $1" >&2; exit 1 ;;
  esac
done

IGNORE='node_modules|\.git|vendor|/\.venv/|/venv/|/dist/|/build/|dev-plan|\.cursor'

list_if() { [ -e "$1" ] && echo "$1"; }

safe_glob() {
  local base="$1" pat="$2"
  [ -d "$base" ] || return 0
  find "$base" -path "$pat" 2>/dev/null | while read -r f; do
    echo "$f" | grep -qE "$IGNORE" && continue
    echo "$f"
  done
}

emit_backend() {
  list_if backend/go.mod
  list_if backend/conf/config.default.yml
  safe_glob backend '*.go'
}

emit_frontend() {
  list_if frontend/package.json
  list_if frontend/vite.config.ts
  list_if frontend/vite.config.js
  list_if frontend/tsconfig.json
  safe_glob frontend/src '*'
}

case "$SCOPE" in
  backend) emit_backend ;;
  frontend) emit_frontend ;;
  all)
    emit_backend
    emit_frontend
    list_if "$(cd "$(dirname "$0")/.." && pwd)/templates/project-config.md"
    ;;
  *) echo "错误: scope 须为 backend|frontend|all" >&2; exit 1 ;;
esac | sort -u
