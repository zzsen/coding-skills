# =============================================================================
# preflight.ps1 — 入口门禁编排（PowerShell）
# =============================================================================
# 【功能】按 SKILL §1.1 顺序执行：环境检查 → Rules 恢复 → OpenSpec 目录补全 → 再次环境检查，并写入执行标记。
# 【调用阶段】前置首个回合（推荐替代分步执行 check-env + restore-rules + ensure-openspec）。
# 【输入】-Json 可选（传递给 check-env）
# 【输出】
#   stdout：分段标题 + 两次 check-env 输出 + restore-rules / ensure-openspec 输出 + complete 行
#   文件：.dev-lifecycle/.preflight-last-run（时间戳，项目级）
#   exit 0：编排完成（环境是否就绪由 Agent 解读 check-env 输出）
# 【流程】
#   1. check-env（恢复前）
#   2. restore-rules
#   3. ensure-openspec（缺 openspec/ 则 openspec init --tools <按 agent 解析>）
#   4. check-env（恢复后）
#   5. 写入 .preflight-last-run 标记
# 【用法】& <skill_root>/scripts/preflight.ps1 [-Json]
# =============================================================================
param([switch]$Json, [string]$Agent)

. (Join-Path $PSScriptRoot '_init-ps.ps1')
Initialize-DevLifecycleConsole
. (Join-Path $PSScriptRoot '_agent-lib.ps1')

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $Agent) { $Agent = Get-DlcAgent }
Write-Host "=== preflight: agent = $Agent ($(Get-DlcAgentLabel -Agent $Agent)) ==="
Write-Host ""

Write-Host "=== preflight: 环境检查（恢复前）==="
if ($Json) { & "$ScriptDir/check-env.ps1" -Agent $Agent -Json } else { & "$ScriptDir/check-env.ps1" -Agent $Agent }

Write-Host ""
Write-Host "=== preflight: Rules 恢复 ==="
& "$ScriptDir/restore-rules.ps1" -Agent $Agent

Write-Host ""
Write-Host "=== preflight: OpenSpec 目录补全 ==="
# 缺 CLI 时 ensure-openspec 会 exit 1；preflight 不因此中断，留给 check-env 标 ❌
& "$ScriptDir/ensure-openspec.ps1" -Agent $Agent

Write-Host ""
Write-Host "=== preflight: 环境检查（恢复后）==="
if ($Json) { & "$ScriptDir/check-env.ps1" -Agent $Agent -Json } else { & "$ScriptDir/check-env.ps1" -Agent $Agent }

$marker = Get-DlcPreflightMarker
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $marker) | Out-Null
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Set-Content -Path $marker -Encoding utf8
Write-Host ""
Write-Host "preflight: complete (marker: $marker)"
