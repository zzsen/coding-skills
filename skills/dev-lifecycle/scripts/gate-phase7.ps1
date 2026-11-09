# =============================================================================
# gate-phase7.ps1 — Phase 7 验收前完整性检查（PowerShell）
# =============================================================================
# 【功能】检查 1~7 阶段产物及 lint-counts.json passed 状态，阻断不完整验收。
# 【调用阶段】Phase 7 生成 7.acceptance.md 前。
# 【输入】-PlanDir（必填）
# 【输出】stdout：逐项 ✅/❌ + GATE_PHASE7: pass|block；exit 0/1
# 【流程】
#   1. 检查 1.proposal ~ 7.acceptance.md
#   2. 检查 lint-counts.json 且 passed=true
# 【用法】& .../gate-phase7.ps1 -PlanDir <path>
# =============================================================================
param([Parameter(Mandatory = $true)][string]$PlanDir)

. (Join-Path $PSScriptRoot '_init-ps.ps1')
Initialize-DevLifecycleConsole

if (-not (Test-Path $PlanDir)) {
  Write-Error "目录不存在: $PlanDir"
  exit 1
}

$fail = 0
function Require($path, $label) {
  if (Test-Path $path) { Write-Output "✅ $label" }
  else { Write-Output "❌ $label ($path)"; $script:fail = 1 }
}

@(
  @("1.proposal.md", "1.proposal.md"),
  @("2.plan.md", "2.plan.md"),
  @("3.dev.md", "3.dev.md"),
  @("4.test-case.md", "4.test-case.md"),
  @("5.lint-report.md", "5.lint-report.md"),
  @("6.docs-update.md", "6.docs-update.md"),
  @("7.acceptance.md", "7.acceptance.md")
) | ForEach-Object { Require (Join-Path $PlanDir $_[0]) $_[1] }

$counts = Join-Path $PlanDir "lint-results/lint-counts.json"
Require $counts "lint-counts.json"
if (Test-Path $counts) {
  $json = Get-Content $counts -Raw | ConvertFrom-Json
  if ($json.passed -eq $true) { Write-Output "✅ lint passed=true" }
  else { Write-Output "❌ lint passed 不为 true"; $fail = 1 }
}

if ($fail -eq 0) { "GATE_PHASE7: pass" } else { "GATE_PHASE7: block" }
exit $fail
