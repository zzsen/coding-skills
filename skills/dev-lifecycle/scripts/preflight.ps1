# =============================================================================
# preflight.ps1 — 入口门禁编排（含 7 天缓存，PowerShell）
# =============================================================================
# 【功能】按 SKILL §1.1 顺序执行：环境检查 → Rules 恢复 → OpenSpec 目录补全 → 再次环境检查。
#         **缓存**：先查 .dev-lifecycle/.preflight-last-run（仅门禁通过时写入），
#         距今 ≤ 有效期（默认 7 天）则输出 gate-cache: valid 并直接退出（跳过全量门禁）；
#         超期 / 缺失 / 不可解析则继续执行全量内容，通过后刷新时间戳。
# 【调用阶段】前置首个回合（推荐替代分步执行 check-env + restore-rules + ensure-openspec）。
# 【输入】-Json 可选（传递给 check-env）；-Agent <id> 覆盖 agent 探测；
#         -Force 忽略缓存强制全量；-MaxAgeDays <N> 覆盖有效期（默认 7，
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
# 【用法】& <skill_root>/scripts/preflight.ps1 [-Json] [-Force] [-MaxAgeDays 7] [-Agent cursor]
# =============================================================================
param([switch]$Json, [string]$Agent, [switch]$Force, [int]$MaxAgeDays = -1)

. (Join-Path $PSScriptRoot '_init-ps.ps1')
Initialize-DevLifecycleConsole
. (Join-Path $PSScriptRoot '_agent-lib.ps1')

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $Agent) { $Agent = Get-DlcAgent }
if ($MaxAgeDays -lt 0) {
  if ($env:DEVLC_GATE_MAX_AGE_DAYS) { $MaxAgeDays = [int]$env:DEVLC_GATE_MAX_AGE_DAYS }
  else { $MaxAgeDays = 7 }
}
Write-Host "=== preflight: agent = $Agent ($(Get-DlcAgentLabel -Agent $Agent)) ==="

# ── 步骤 0：门禁缓存判定（标记仅门禁通过时写入，存在且未超期即代表通过）─────
$marker = Get-DlcPreflightMarker
if ($Force) {
  Write-Host "gate-cache: bypass（-Force）→ 执行全量门禁"
} elseif (-not (Test-Path -LiteralPath $marker -PathType Leaf)) {
  Write-Host "gate-cache: missing（无门禁通过标记，含上次未通过）→ 执行全量门禁"
} else {
  $lines = @(Get-Content -LiteralPath $marker -Encoding utf8)
  $lastPassed = if ($lines.Count -gt 0) { $lines[0].Trim() } else { '' }
  $epoch = $null
  $epochLine = $lines | Where-Object { $_ -match '^epoch:\s*(\d+)\s*$' } | Select-Object -First 1
  if ($epochLine -and $Matches[1]) {
    $epoch = [long]$Matches[1]
  } elseif ($lastPassed) {
    # 兼容旧格式：首行仅为可读时间时按本地时间解析
    try {
      $dt = [DateTime]::ParseExact($lastPassed, 'yyyy-MM-dd HH:mm:ss', [Globalization.CultureInfo]::InvariantCulture)
      $epoch = [long][DateTimeOffset]::new($dt, [TimeZoneInfo]::Local.GetUtcOffset($dt)).ToUnixTimeSeconds()
    } catch { $epoch = $null }
  }
  if ($null -ne $epoch) {
    $ageSec = [long][DateTimeOffset]::UtcNow.ToUnixTimeSeconds() - $epoch
    $ageDays = [math]::Floor($ageSec / 86400)
    if ($ageSec -le ($MaxAgeDays * 86400)) {
      Write-Host "gate-cache: valid（上次门禁通过于 $lastPassed，$ageDays 天前，≤ $MaxAgeDays 天有效期）"
      Write-Host "environment-ready: True（缓存：标记仅门禁通过时写入，存在且未超期即通过）"
      Write-Host "preflight: skipped（缓存命中，跳过全量门禁；-Force 或删除 $marker 可强制重跑）"
      exit 0
    }
    Write-Host "gate-cache: stale（上次门禁通过于 $lastPassed，已 $ageDays 天，超 $MaxAgeDays 天有效期）→ 重跑全量门禁，通过后刷新时间戳并重新校验 project-config"
  } else {
    Write-Host "gate-cache: malformed（标记时间不可解析）→ 重跑全量门禁"
  }
}
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

# 取最终门禁结论；**仅通过时**刷新「最后通过时间」标记（preflight 入口缓存据此跳过全量门禁，
# gate-phase2 可检测）；未通过则不更新，下次会话仍会重跑门禁
$marker = Get-DlcPreflightMarker
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $marker) | Out-Null
$envJson = (& "$ScriptDir/check-env.ps1" -Agent $Agent -Json 2>$null) -join "`n"
$envReady = ''
$m = [regex]::Match($envJson, '"environment_ready":\s*"?([^",]+)"?,?')
if ($m.Success) { $envReady = $m.Groups[1].Value }
Write-Host ""
if ($envReady -eq 'true') {
  @((Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), "epoch: $([long][DateTimeOffset]::UtcNow.ToUnixTimeSeconds())") |
    Set-Content -Path $marker -Encoding utf8
  Write-Host "preflight: complete（门禁通过，已刷新标记: $marker）"
} else {
  Write-Host "preflight: complete（environment-ready: False，未刷新标记 $marker，下次会话将重跑门禁）"
}
