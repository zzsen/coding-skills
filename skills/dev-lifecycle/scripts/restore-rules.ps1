# =============================================================================
# restore-rules.ps1 — Cursor Rules 自动恢复（PowerShell）
# =============================================================================
# 【功能】按 agent 分流恢复工作流规则：cursor→.cursor/rules/*.mdc；claude-code/codex→仅提示。
# 【调用阶段】前置 preparation 步骤 0；preflight 第二步。
# 【输入】-DryRun 可选，只打印将恢复的文件
# 【输出】stdout：Rules restored: <files> 或 Rules: all present；exit 0
# 【流程】
#   1. 确保 .cursor/rules 存在
#   2. 逐个检查三个 .mdc
#   3. 缺失则从 reference 复制
#   4. 汇总输出
# 【用法】& <skill_root>/scripts/restore-rules.ps1 [-DryRun]
# =============================================================================
param([switch]$DryRun, [string]$Agent)

. (Join-Path $PSScriptRoot '_init-ps.ps1')
Initialize-DevLifecycleConsole
. (Join-Path $PSScriptRoot '_agent-lib.ps1')

if (-not $Agent) { $Agent = Get-DlcAgent }
$kind = Get-DlcRulesKind -Agent $Agent
$ref  = Join-Path (Get-DlcSkillRoot) 'reference'

switch ($kind) {
  'mdc' {
    $rules = ".cursor/rules"
    if (-not $DryRun) { New-Item -ItemType Directory -Force -Path $rules | Out-Null }
    $restored = @()
    @("01-openspec-workflow.mdc", "02-tdd-plan-wave-tracking.mdc", "03-askquestion-task-followup.mdc") | ForEach-Object {
      if (-not (Test-Path "$rules/$_")) {
        if ($DryRun) {
          Write-Host "[dry-run] would restore $_"
        } else {
          Copy-Item (Join-Path $ref $_) "$rules/$_"
        }
        $restored += $_
      }
    }
    if ($restored.Count -gt 0) {
      "Rules restored: $($restored -join ', ')"
    } else {
      "Rules: all present"
    }
  }
  'memory-file' {
    $target = (Get-DlcRulesTargets -Agent $Agent)[0]
    if (Test-Path -LiteralPath $target) {
      "Rules: memory-file present ($target) — 内容由用户维护，脚本不自动写入"
    } else {
      "Rules: memory-file absent ($target) — 可选：将下列规则摘要并入该文件"
      "  $(Join-Path $ref '01-openspec-workflow.mdc')"
      "  $(Join-Path $ref '02-tdd-plan-wave-tracking.mdc')"
      "  $(Join-Path $ref '03-askquestion-task-followup.mdc')"
    }
  }
  default {
    "Rules: skipped (agent=$Agent 无等价常驻规则机制)"
  }
}
exit 0
