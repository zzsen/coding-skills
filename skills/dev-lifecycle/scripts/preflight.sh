#!/usr/bin/env bash
# =============================================================================
# preflight.sh — 入口门禁编排（含 7 天缓存）
# =============================================================================
# 【功能】按 SKILL §1.1 顺序执行：环境检查 → Rules 恢复 → OpenSpec 目录补全 → 再次环境检查。
#         **缓存**：先查 .dev-lifecycle/.preflight-last-run（仅门禁通过时写入），
#         距今 ≤ 有效期（默认 7 天）则输出 gate-cache: valid 并直接退出（跳过全量门禁）；
#         超期 / 缺失 / 不可解析则继续执行全量内容，通过后刷新时间戳。
# 【调用阶段】前置首个回合（推荐替代分步执行 check-env + restore-rules + ensure-openspec）。
# 【输入】--json 可选（传递给 check-env）；--agent=<id> 覆盖 agent 探测；
#         --force 忽略缓存强制全量；--max-age-days=N 覆盖有效期（默认 7，
#         亦可用环境变量 DEVLC_GATE_MAX_AGE_DAYS；0 = 总是全量）
# 【输出】
#   stdout：缓存命中 → gate-cache: valid + environment-ready: True（缓存）+ skipped 行；
#           否则 → gate-cache 状态行 + 分段标题 + 两次 check-env 输出 +
#           restore-rules / ensure-openspec 输出 + complete 行
#   文件：.dev-lifecycle/.preflight-last-run（**仅门禁通过时更新**：首行可读时间 + 次行 epoch；
#         gate-phase2 可检测）
#   exit 0：编排完成/缓存命中（环境是否就绪由 Agent 解读输出）
# 【流程】
#   0. 缓存判定（marker 存在且未超期 → 跳过，exit 0）
#   1. check-env（恢复前）
#   2. restore-rules
#   3. ensure-openspec（缺 openspec/ 则 openspec init --tools <按 agent 解析>）
#   4. check-env（恢复后）
#   5. 取最终 environment-ready；**仅 True 时**刷新 .preflight-last-run 时间戳
# 【用法】bash <skill_root>/scripts/preflight.sh [--json] [--force] [--max-age-days=7] [--agent=claude-code|cursor|codex]
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_agent-lib.sh
source "$SCRIPT_DIR/_agent-lib.sh"

JSON=false
AGENT_ARG=""
FORCE=false
MAX_AGE_DAYS="${DEVLC_GATE_MAX_AGE_DAYS:-7}"
for arg in "$@"; do
  case "$arg" in
    --json) JSON=true ;;
    --agent=*) AGENT_ARG="$arg" ;;
    --force) FORCE=true ;;
    --max-age-days=*) MAX_AGE_DAYS="${arg#*=}" ;;
    -h|--help) echo "用法: $0 [--json] [--force] [--max-age-days=7] [--agent=claude-code|cursor|codex]"; exit 0 ;;
  esac
done

AGENT="$(dlc_detect_agent)"
if [ -n "$AGENT_ARG" ]; then AGENT="${AGENT_ARG#*=}"; fi
echo "=== preflight: agent = $AGENT ($(dlc_agent_label "$AGENT")) ==="

# ── 步骤 0：门禁缓存判定（标记仅门禁通过时写入，存在且未超期即代表通过）─────
MARKER="$(dlc_preflight_marker)"
if [ "$FORCE" = true ]; then
  echo "gate-cache: bypass（--force）→ 执行全量门禁"
elif [ ! -f "$MARKER" ]; then
  echo "gate-cache: missing（无门禁通过标记，含上次未通过）→ 执行全量门禁"
else
  LAST_PASSED="$(head -n1 "$MARKER" | tr -d '\r')"
  EPOCH="$(grep -m1 -E '^epoch:[[:space:]]*[0-9]+$' "$MARKER" | sed -E 's/^epoch:[[:space:]]*//' || true)"
  # 兼容旧格式：首行仅为可读时间时按本地时间解析（macOS date -j / GNU date -d）
  if [ -z "$EPOCH" ]; then
    EPOCH="$(date -j -f "%Y-%m-%d %H:%M:%S" "$LAST_PASSED" +%s 2>/dev/null || date -d "$LAST_PASSED" +%s 2>/dev/null || true)"
  fi
  if [[ "$EPOCH" =~ ^[0-9]+$ ]]; then
    AGE_SEC=$(( $(date +%s) - EPOCH ))
    AGE_DAYS=$(( AGE_SEC / 86400 ))
    if [ "$AGE_SEC" -le $(( MAX_AGE_DAYS * 86400 )) ]; then
      echo "gate-cache: valid（上次门禁通过于 ${LAST_PASSED}，${AGE_DAYS} 天前，≤ ${MAX_AGE_DAYS} 天有效期）"
      echo "environment-ready: True（缓存：标记仅门禁通过时写入，存在且未超期即通过）"
      echo "preflight: skipped（缓存命中，跳过全量门禁；--force 或删除 ${MARKER} 可强制重跑）"
      exit 0
    fi
    echo "gate-cache: stale（上次门禁通过于 ${LAST_PASSED}，已 ${AGE_DAYS} 天，超 ${MAX_AGE_DAYS} 天有效期）→ 重跑全量门禁，通过后刷新时间戳并重新校验 project-config"
  else
    echo "gate-cache: malformed（标记时间不可解析）→ 重跑全量门禁"
  fi
fi
echo ""

echo "=== preflight: 环境检查（恢复前）==="
set +e
if [ "$JSON" = true ]; then
  bash "$SCRIPT_DIR/check-env.sh" --agent="$AGENT" --json
else
  bash "$SCRIPT_DIR/check-env.sh" --agent="$AGENT"
fi
set -e

echo ""
echo "=== preflight: Rules 恢复 ==="
set +e
bash "$SCRIPT_DIR/restore-rules.sh" --agent="$AGENT"
set -e

echo ""
echo "=== preflight: OpenSpec 目录补全 ==="
# 缺 CLI 时 ensure-openspec 会 exit 1；preflight 不因此中断，留给 check-env 标 ❌
set +e
bash "$SCRIPT_DIR/ensure-openspec.sh" --agent="$AGENT"
set -e

echo ""
echo "=== preflight: 环境检查（恢复后）==="
set +e
if [ "$JSON" = true ]; then
  bash "$SCRIPT_DIR/check-env.sh" --agent="$AGENT" --json
else
  bash "$SCRIPT_DIR/check-env.sh" --agent="$AGENT"
fi
set -e

# 取最终门禁结论；**仅通过时**刷新「最后通过时间」标记（preflight 入口缓存据此跳过全量门禁，
# gate-phase2 可检测）；未通过则不更新，下次会话仍会重跑门禁
MARKER="$(dlc_preflight_marker)"
mkdir -p "$(dirname "$MARKER")"
ENV_JSON="$(bash "$SCRIPT_DIR/check-env.sh" --agent="$AGENT" --json 2>/dev/null || true)"
ENV_READY="$(printf '%s\n' "$ENV_JSON" | grep -E '"environment_ready":' | head -n1 | sed -E 's/^[^:]*:[[:space:]]*"?([^",]*)"?,?[[:space:]]*$/\1/')"
echo ""
if [ "$ENV_READY" = "true" ]; then
  { date +"%Y-%m-%d %H:%M:%S"; echo "epoch: $(date +%s)"; } > "$MARKER"
  echo "preflight: complete（门禁通过，已刷新标记: ${MARKER}）"
else
  echo "preflight: complete（environment-ready: False，未刷新标记 ${MARKER}，下次会话将重跑门禁）"
fi
