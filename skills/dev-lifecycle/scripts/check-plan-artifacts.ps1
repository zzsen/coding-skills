# =============================================================================
# check-plan-artifacts.ps1 — 按 Phase 检查计划目录产物（PowerShell）
# =============================================================================
# 【功能】根据阶段编号检查 dev-plan 目录中应存在的产物文件（checklist 机器辅助）。
# 【调用阶段】各 Phase 完成时。
# 【输入】-PlanDir、-Phase 1~7（均必填）
# 【输出】stdout：文件存在性 + ARTIFACTS_PHASEn: pass|block；exit 0/1
# 【流程】查表获取该 Phase 必需文件 → 逐项 Test-Path
# 【用法】& .../check-plan-artifacts.ps1 -PlanDir <path> -Phase <1-7>
# =============================================================================
param(
  [Parameter(Mandatory = $true)][string]$PlanDir,
  [Parameter(Mandatory = $true)][ValidateRange(1, 7)][int]$Phase
)

. (Join-Path $PSScriptRoot '_init-ps.ps1')
Initialize-DevLifecycleConsole

$phaseFiles = @{
  1 = @('1.proposal.md')
  2 = @('1.proposal.md', '2.plan.md')
  3 = @('1.proposal.md', '2.plan.md', '3.dev.md')
  4 = @('1.proposal.md', '2.plan.md', '3.dev.md', '4.test-case.md')
  5 = @('1.proposal.md', '2.plan.md', '3.dev.md', '4.test-case.md', '5.lint-report.md', 'lint-results/lint-counts.json')
  6 = @('1.proposal.md', '2.plan.md', '3.dev.md', '4.test-case.md', '5.lint-report.md', '6.docs-update.md')
  7 = @('1.proposal.md', '2.plan.md', '3.dev.md', '4.test-case.md', '5.lint-report.md', '6.docs-update.md', '7.acceptance.md', 'lint-results/lint-counts.json')
}

$fail = 0
foreach ($f in $phaseFiles[$Phase]) {
  $p = Join-Path $PlanDir $f
  if (Test-Path $p) { Write-Output "✅ $f" }
  else { Write-Output "❌ $f"; $fail = 1 }
}

if ($fail -eq 0) { "ARTIFACTS_PHASE${Phase}: pass" } else { "ARTIFACTS_PHASE${Phase}: block" }
exit $fail
