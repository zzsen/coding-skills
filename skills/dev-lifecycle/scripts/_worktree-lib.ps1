# =============================================================================
# _worktree-lib.ps1 — worktree 隔离辅助库（PowerShell）
# =============================================================================
# 【功能】.sh 版 _worktree-lib.sh 的 PowerShell 对等实现。
# 【调用方】被 worktree-create.ps1 / worktree-status.ps1 / worktree-merge-back.ps1 /
#           gate-phase3.ps1 dot-source。
# 【导出函数】
#   Get-DlcWtRoot            worktree 根目录（默认 .worktrees，DEVLC_WORKTREES_ROOT 可覆盖）
#   Get-DlcWtRegistry [GitRoot]          登记表路径 .dev-lifecycle/worktrees.tsv
#                                          （带 GitRoot 时锚定到仓库根，支持多仓库）
#   Get-DlcWtBranch <Kind> <ChangeName>  分支名 {kind}-{change-name}
#   Get-DlcWtPath <Branch>               worktree 路径 <root>/<branch>
#   Get-DlcWtGitRoot                     仓库根目录（从 cwd 向上探测，非仓库返回 $null）
#   Get-DlcWtRepoRoot <Target>           给定目录的 git 顶层（--repo 校验用）
#   Find-DlcWtRepos [MaxDepth]           在 cwd 下找嵌套 git 仓库根（多仓库场景）
#   Get-DlcWtCurrentBranch               当前分支名
#   Set-DlcWtRegistryStatus <Branch> <Status> [GitRoot]  更新登记表状态列
# 【说明】登记表 TSV 列序同 .sh 版；写入统一 UTF-8 无 BOM、LF 换行，与 .sh 版一致。
# =============================================================================

. (Join-Path $PSScriptRoot '_agent-lib.ps1')

$script:Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Get-DlcWtRoot {
  if ($env:DEVLC_WORKTREES_ROOT) { return $env:DEVLC_WORKTREES_ROOT }
  return '.worktrees'
}

function Get-DlcWtRegistry {
  param([string]$GitRoot = '')
  if ($GitRoot) { return (Join-Path $GitRoot '.dev-lifecycle/worktrees.tsv') }
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

function Get-DlcWtRepoRoot {
  param([string]$Target = '.')
  $r = & git -C $Target rev-parse --show-toplevel 2>$null
  if ($LASTEXITCODE -eq 0 -and $r) { return $r.Trim() }
  return $null
}

function Find-DlcWtRepos {
  param([int]$MaxDepth = 3)
  $start = (Get-Location).Path
  $repos = @()
  Get-ChildItem -LiteralPath $start -Recurse -Depth $MaxDepth -Force -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -eq '.git' } |
    ForEach-Object {
      $repo = $_.FullName -replace '[/\\]\.git$', ''
      if ($repo -and ($repos -notcontains $repo)) { $repos += $repo }
    }
  return ($repos | Sort-Object)
}

function Get-DlcWtCurrentBranch {
  $b = & git branch --show-current 2>$null
  if ($LASTEXITCODE -eq 0 -and $b) { return $b.Trim() }
  return $null
}

function Set-DlcWtRegistryStatus {
  param([string]$Branch, [string]$Status, [string]$GitRoot = '')
  $reg = Get-DlcWtRegistry -GitRoot $GitRoot
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
