# =============================================================================
# worktree-status.ps1 — 列出 worktree 及状态（PowerShell）
# =============================================================================
# 【功能】汇总 git worktree list 与登记表，输出每个 worktree 的分支/路径/状态。
# 【调用阶段】场景判定 / resume。
# 【输入】-Json 可选。
# 【输出】stdout：可读列表或 JSON；exit 0（非仓库 exit 1）。
# 【用法】& <skill_root>/scripts/worktree-status.ps1 [-Json]
# =============================================================================
param(
  [switch]$Json
)

. (Join-Path $PSScriptRoot '_init-ps.ps1')
Initialize-DevLifecycleConsole
. (Join-Path $PSScriptRoot '_agent-lib.ps1')
. (Join-Path $PSScriptRoot '_worktree-lib.ps1')

$gitRoot = Get-DlcWtGitRoot
if (-not $gitRoot) { Write-Error "RESULT: FAIL（当前目录不是 git 仓库）"; exit 1 }

# 登记表索引：branch -> change_name|kind|base_branch|status
$reg = @{}
$registry = Get-DlcWtRegistry
if (Test-Path -LiteralPath $registry -PathType Leaf) {
  foreach ($ln in (Get-Content -LiteralPath $registry)) {
    $f = $ln -split "`t"
    if ($f.Count -ge 8 -and $f[2]) { $reg[$f[2]] = "$($f[0])|$($f[1])|$($f[4])|$($f[7])" }
  }
}

# 解析 git worktree list --porcelain
$rows = @()
$wt = $null; $head = ''; $br = ''
foreach ($ln in (& git -C $gitRoot worktree list --porcelain)) {
  if ($ln -like 'worktree *') { $wt = $ln.Substring(9) }
  elseif ($ln -like 'HEAD *') { $head = $ln.Substring(5) }
  elseif ($ln -like 'branch *') { $br = $ln.Substring(7) }
  elseif ($ln.Trim() -eq '') {
    if ($wt) {
      $branchName = $br -replace '^refs/heads/', ''
      $cn = ''; $kind = ''; $base = ''; $status = 'unknown'
      if ($branchName -and $reg.ContainsKey($branchName)) {
        $parts = $reg[$branchName] -split '\|'
        $cn = $parts[0]; $kind = $parts[1]; $base = $parts[2]; $status = $parts[3]
      }
      $rel = $wt
      if ($rel.StartsWith($gitRoot)) { $rel = $rel.Substring($gitRoot.Length).TrimStart('/','\') }
      $rows += [pscustomobject]@{
        path = $wt; rel = $rel; branch = $branchName; head = $head;
        change_name = $cn; kind = $kind; base_branch = $base; status = $status
      }
    }
    $wt = $null; $head = ''; $br = ''
  }
}
# 最后一块（无尾随空行）
if ($wt) {
  $branchName = $br -replace '^refs/heads/', ''
  $cn = ''; $kind = ''; $base = ''; $status = 'unknown'
  if ($branchName -and $reg.ContainsKey($branchName)) {
    $parts = $reg[$branchName] -split '\|'
    $cn = $parts[0]; $kind = $parts[1]; $base = $parts[2]; $status = $parts[3]
  }
  $rel = $wt
  if ($rel.StartsWith($gitRoot)) { $rel = $rel.Substring($gitRoot.Length).TrimStart('/','\') }
  $rows += [pscustomobject]@{ path = $wt; rel = $rel; branch = $branchName; head = $head; change_name = $cn; kind = $kind; base_branch = $base; status = $status }
}

if ($Json) {
  $rows | ConvertTo-Json -Depth 3
} else {
  foreach ($r in $rows) {
    $cn = if ($r.change_name) { $r.change_name } else { '—' }
    $kind = if ($r.kind) { $r.kind } else { '—' }
    $base = if ($r.base_branch) { $r.base_branch } else { '—' }
    $headShort = ''
    if ($r.head) { $headShort = $r.head.Substring(0, [Math]::Min(9, $r.head.Length)) }
    Write-Output ("{0,-45} branch={1,-28} head={2,-9} change={3,-18} kind={4,-7} base={5,-10} status={6}" -f $r.rel, $r.branch, $headShort, $cn, $kind, $base, $r.status)
  }
}

Write-Output "RESULT: OK"
