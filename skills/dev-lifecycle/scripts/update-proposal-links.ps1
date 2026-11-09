# =============================================================================
# update-proposal-links.ps1 — 归档后更新 OpenSpec 超链接（PowerShell）
# =============================================================================
# 【功能】将 1/2/7 产物中 openspec/changes/<name> 替换为 openspec/changes/archive/<date>-<name>。
# 【调用阶段】Phase 7 用户确认验收且 /opsx:archive 完成后。
# 【输入】-PlanDir、-ChangeName、-ArchiveDate（必填）；-DryRun 可选
# 【输出】stdout：更新文件列表 + LINKS_UPDATED 计数；修改磁盘 Markdown
# 【流程】
#   1. 构造 from/to 路径（与 openspec CLI 归档目录一致：changes/archive/）
#   2. 遍历 1.proposal、2.plan、7.acceptance
#   3. 全局替换链接
# 【用法】& .../update-proposal-links.ps1 -PlanDir ... -ChangeName ... -ArchiveDate YYYY-MM-DD
# =============================================================================
param(
  [Parameter(Mandatory = $true)][string]$PlanDir,
  [Parameter(Mandatory = $true)][string]$ChangeName,
  [Parameter(Mandatory = $true)][string]$ArchiveDate,
  [switch]$DryRun
)

. (Join-Path $PSScriptRoot '_init-ps.ps1')
Initialize-DevLifecycleConsole

$from = "openspec/changes/$ChangeName"
$to = "openspec/changes/archive/${ArchiveDate}-${ChangeName}"
$total = 0

foreach ($name in @('1.proposal.md', '2.plan.md', '7.acceptance.md')) {
  $f = Join-Path $PlanDir $name
  if (-not (Test-Path $f)) { continue }
  $content = Get-Content $f -Raw -Encoding UTF8
  $count = ([regex]::Matches($content, [regex]::Escape($from))).Count
  if ($count -gt 0) {
    Write-Output "更新 $name ($count 处)"
    if (-not $DryRun) {
      $updated = $content -replace [regex]::Escape($from), $to
      $utf8NoBom = New-Object System.Text.UTF8Encoding $false
      [System.IO.File]::WriteAllText((Resolve-Path $f).Path, $updated, $utf8NoBom)
    }
    $total += $count
  }
}

"LINKS_UPDATED: $total"
if ($DryRun) { "(dry-run)" }
