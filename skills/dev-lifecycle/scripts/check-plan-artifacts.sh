#!/usr/bin/env bash
# =============================================================================
# check-plan-artifacts.sh — 按 Phase 检查计划目录产物
# =============================================================================
# 【功能】根据阶段编号检查 dev-plan 目录中应存在的产物文件（checklist 机器辅助）。
# 【调用阶段】各 Phase 完成时。
# 【输入】--plan-dir <path> --phase <1-7>（均必填）
# 【输出】stdout：文件存在性 + ARTIFACTS_PHASEn: pass|block；exit 0/1
# 【流程】查表获取该 Phase 必需文件列表 → 逐项 Test-Path
# 【用法】bash .../check-plan-artifacts.sh --plan-dir dev-plan/... --phase 3
# =============================================================================
set -euo pipefail

PLAN_DIR=""
PHASE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --plan-dir) PLAN_DIR="${2:-}"; shift 2 ;;
    --phase) PHASE="${2:-}"; shift 2 ;;
    -h|--help) echo "用法: $0 --plan-dir <path> --phase <1-7>"; exit 0 ;;
    *) echo "未知参数: $1" >&2; exit 1 ;;
  esac
done

[ -n "$PLAN_DIR" ] && [ -n "$PHASE" ] || { echo "错误: 需要 --plan-dir 和 --phase" >&2; exit 1; }

declare -A PHASE_FILES=(
  [1]="1.proposal.md"
  [2]="1.proposal.md 2.plan.md"
  [3]="1.proposal.md 2.plan.md 3.dev.md"
  [4]="1.proposal.md 2.plan.md 3.dev.md 4.test-case.md"
  [5]="1.proposal.md 2.plan.md 3.dev.md 4.test-case.md 5.lint-report.md lint-results/lint-counts.json"
  [6]="1.proposal.md 2.plan.md 3.dev.md 4.test-case.md 5.lint-report.md 6.docs-update.md"
  [7]="1.proposal.md 2.plan.md 3.dev.md 4.test-case.md 5.lint-report.md 6.docs-update.md 7.acceptance.md lint-results/lint-counts.json"
)

files="${PHASE_FILES[$PHASE]:-}"
[ -n "$files" ] || { echo "错误: phase 须为 1-7" >&2; exit 1; }

fail=0
for f in $files; do
  p="$PLAN_DIR/$f"
  if [ -e "$p" ]; then echo "✅ $f"
  else echo "❌ $f"; fail=1; fi
done

[ "$fail" -eq 0 ] && echo "ARTIFACTS_PHASE${PHASE}: pass" || echo "ARTIFACTS_PHASE${PHASE}: block"
exit "$fail"
