# =============================================================================
# _worktree-lib.ps1 — worktree 隔离辅助库（PowerShell）
# =============================================================================
# 【功能】.sh 版 _worktree-lib.sh 的 PowerShell 对等实现。
# 【调用方】被 worktree-create.ps1 / worktree-status.ps1 / worktree-merge-back.ps1 /
#           gate-phase3.ps1 dot-source。
# 【导出函数】
#   Get-DlcWtRoot            worktree 根目录（默认 .worktrees，DEVLC_WORKTREES_ROOT 可覆盖）
#   Get-DlcWtRegistry        登记表路径 .dev-lifecycle/worktrees.tsv
#   Get-DlcWtBranch <Kind> <ChangeName>    分支名 {kind}-{change-name}
#   Get-DlcWtPath <Branch>                 worktree 路径 <root>/<branch>
#   Get-DlcWtGitRoot                       仓库根目录（非仓库返回 $null）
#   Get-DlcWtCurrentBranch                 当前分支名
#   Set-DlcWtRegistryStatus <Branch> <Status>   更新登记表状态列
# 【说明】登记表 TSV 列序同 .sh 版；写入统一 UTF-8 无 BOM、LF 换行，与 .sh 版一致。
# =============================================================================

. (Join-Path $PSScriptRoot '_agent-lib.ps1')

$script:Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Get-DlcWtRoot {
  if ($env:DEVLC_WORKTREES_ROOT) { return $env:DEVLC_WORKTREES_ROOT }
  return '.worktrees'
}

function Get-DlcWtRegistry {
  return (Join-Path (Get-DlcStateDir) 'worktrees.tsv')
}

function Get-DlcWtBranch {
  param([string]$Kind, [string]$ChangeName)
  return "$Kind-$ChangeName"
}

function Get-DlcWtPath {
  param([string]$Branch)
  return (Join-Path (Get-DlcWtRoot) $Branch)
}

function Get-DlcWtGitRoot {
  $r = & git rev-parse --show-toplevel 2>$null
  if ($LASTEXITCODE -eq 0 -and $r) { return $r.Trim() }
  return $null
}

function Get-DlcWtCurrentBranch {
  $b = & git branch --show-current 2>$null
  if ($LASTEXITCODE -eq 0 -and $b) { return $b.Trim() }
  return $null
}

function Set-DlcWtRegistryStatus {
  param([string]$Branch, [string]$Status)
  $reg = Get-DlcWtRegistry
  if (-not (Test-Path -LiteralPath $reg -PathType Leaf)) {
    Write-Error "登记表不存在: $reg"
    return $false
  }
  $lines = @(Get-Content -LiteralPath $reg -Raw) -split "`n"
  $hit = $false
  $out = @()
  foreach ($ln in $lines) {
    if ([string]::IsNullOrEmpty($ln.TrimEnd("`r"))) { continue }
    $f = $ln -split "`t"
    if ($f.Count -ge 8 -and $f[2] -eq $Branch) { $f[7] = $Status; $hit = $true }
    $out += ($f -join "`t")
  }
  if (-not $hit) { return $false }
  [System.IO.File]::WriteAllText($reg, (($out -join "`n") + "`n"), $script:Utf8NoBom)
  return $true
}
