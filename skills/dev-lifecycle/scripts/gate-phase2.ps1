# =============================================================================
# gate-phase2.ps1 — Phase 2 硬门禁（PowerShell）
# =============================================================================
# 【功能】验证进入 Phase 2（writing-plans）前的文件级前置条件（不含 AskUserQuestion 用户确认）。
# 【调用阶段】Phase 2 前（phase2.md §一）。
# 【输入】-PlanDir、-ChangeName（均必填）
# 【输出】stdout：逐项 ✅/❌ + GATE_PHASE2: pass|block；exit 0/1
# 【流程】
#   1. 可选检测 .preflight-last-run
#   2. 检查 1.proposal.md 与 openspec/changes/<name>/ 三文件
#   3. 提示 AskUserQuestion 须会话内验证
# 【用法】& .../gate-phase2.ps1 -PlanDir <path> -ChangeName <name>
# =============================================================================
param(
  [Parameter(Mandatory = $true)][string]$PlanDir,
  [Parameter(Mandatory = $true)][string]$ChangeName
)

. (Join-Path $PSScriptRoot '_init-ps.ps1')
Initialize-DevLifecycleConsole

$fail = 0
function Require($path, $label) {
  if (Test-Path $path) { Write-Output "✅ $label" }
  else { Write-Output "❌ $label (缺失: $path)"; $script:fail = 1 }
}

. (Join-Path $PSScriptRoot '_agent-lib.ps1')
$marker = Get-DlcPreflightMarker
$legacyMarker = ".cursor/skills/dev-lifecycle/.preflight-last-run"
if (-not (Test-Path -LiteralPath $marker) -and (Test-Path -LiteralPath $legacyMarker)) { $marker = $legacyMarker }
if (Test-Path $marker) { Write-Output "✅ preflight 已执行 ($marker)" }
else { Write-Output "⚠️ preflight 标记不存在（建议先运行 preflight.ps1）" }

Require "$PlanDir/1.proposal.md" "1.proposal.md 存在"
$os = "openspec/changes/$ChangeName"
Require "$os/proposal.md" "openspec proposal.md"
Require "$os/design.md" "openspec design.md"
Require "$os/tasks.md" "openspec tasks.md"

Write-Output "NOTE: 用户 AskUserQuestion 确认 Phase 1 须由 Agent 会话内验证，脚本无法检测"

if ($fail -eq 0) { "GATE_PHASE2: pass" } else { "GATE_PHASE2: block" }
exit $fail
