#!/usr/bin/env bash
# =============================================================================
# validate-project-config.sh — 校验 project-config.md
# =============================================================================
# 【功能】按 templates/project-config.md 末尾有效性校验表机器判定配置是否可进入 Propose。
# 【调用阶段】Phase 1 前；SKILL §2.1。
# 【输入】--path 可选（默认 .dev-lifecycle/project-config.md，回落 <skill_root>/project-config.md）
# 【输出】
#   stdout：逐项 ✅/❌ + RESULT: valid|invalid
#   exit 0：valid；exit 1：invalid 或文件不存在
# 【流程】
#   1. 检查文件存在
#   2. 扫描未替换 {{ 占位符
#   3. 对比 backend/go.mod module
#   4. 对比 frontend/package.json name
#   5. 检查 §7 探索约定非空
# 【用法】bash <skill_root>/scripts/validate-project-config.sh
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_agent-lib.sh
source "$SCRIPT_DIR/_agent-lib.sh"
CONFIG="$(dlc_project_config_path)"
while [ $# -gt 0 ]; do
  case "$1" in
    --path) CONFIG="${2:-}"; shift 2 ;;
    -h|--help) echo "用法: $0 [--path <file>]"; exit 0 ;;
    *) echo "未知参数: $1" >&2; exit 1 ;;
  esac
done

fail=0
check() { echo "$1"; }

if [ ! -f "$CONFIG" ]; then
  echo "❌ 文件不存在: $CONFIG"
  exit 1
fi

# 校验 1：无占位符
if grep -q '{{' "$CONFIG"; then
  check "❌ 存在未替换占位符 {{"
  fail=1
else
  check "✅ 无 {{ 占位符"
fi

# 校验 2：go.mod module 一致
go_mod="backend/go.mod"
if [ -f "$go_mod" ]; then
  mod=$(grep -E '^module ' "$go_mod" | awk '{print $2}')
  if grep -q "$mod" "$CONFIG" 2>/dev/null; then
    check "✅ go.mod module 一致: $mod"
  else
    check "❌ go.mod module 不一致（期望含: $mod）"
    fail=1
  fi
else
  check "⚠️ 跳过 go.mod（backend/go.mod 不存在）"
fi

# 校验 3：package.json name 一致
pkg_json="frontend/package.json"
if [ -f "$pkg_json" ]; then
  name=$(node -e "console.log(require('./$pkg_json').name||'')" 2>/dev/null || python3 -c "import json; print(json.load(open('$pkg_json')).get('name',''))" 2>/dev/null || echo "")
  if [ -n "$name" ] && grep -q "$name" "$CONFIG"; then
    check "✅ package.json name 一致: $name"
  elif [ -n "$name" ]; then
    check "❌ package.json name 不一致（期望含: $name）"
    fail=1
  fi
else
  check "⚠️ 跳过 package.json（frontend/package.json 不存在）"
fi

# 校验 4：§7 探索约定
if grep -q '## 7. 探索约定' "$CONFIG" && grep -A5 '## 7. 探索约定' "$CONFIG" | grep -q '|'; then
  check "✅ §7 探索约定已填写"
else
  check "❌ §7 探索约定未填写"
  fail=1
fi

# 校验 5：仓库类型（single / multi / none）
if grep -qE '\| 仓库类型 \|[^\n]*(single|multi|none)' "$CONFIG"; then
  check "✅ 仓库类型已填写（single/multi/none）"
else
  check "❌ 仓库类型未填写或非法（须 single / multi / none）"
  fail=1
fi

[ "$fail" -eq 0 ] && echo "RESULT: valid" || echo "RESULT: invalid"
exit "$fail"
