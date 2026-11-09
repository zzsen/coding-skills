# =============================================================================
# _superpowers-lib.ps1 — Superpowers（writing-plans / executing-plans）检测
# =============================================================================
# 【变更说明】原版只认 Cursor 插件缓存 + .cursor/settings.json 的
#   plugins.superpowers.enabled，并依赖 python 解析 JSON。现版改为「按 agent 在
#   skills 目录中查找 SKILL.md」，对 claude-code / cursor / codex 通用，无 python 依赖。
#   Cursor 插件缓存保留为向后兼容回落路径。
# 【调用方】check-superpowers.ps1、check-env.ps1、enable-superpowers.ps1（dot-source）
# =============================================================================

. (Join-Path $PSScriptRoot '_agent-lib.ps1')

# ── 向后兼容：Cursor 插件缓存 ───────────────────────────────────────────────
function Find-SuperpowersPluginDir {
  $home_ = $env:USERPROFILE; if (-not $home_) { $home_ = $env:HOME }
  if (-not $home_) { return $null }
  $base = Join-Path $home_ '.cursor/plugins/cache/cursor-public/superpowers'
  if (-not (Test-Path -LiteralPath $base -PathType Container)) { return $null }
  foreach ($d in (Get-ChildItem -LiteralPath $base -Directory -ErrorAction SilentlyContinue)) {
    $skill = Join-Path $d.FullName 'skills/writing-plans/SKILL.md'
    if ((Test-Path -LiteralPath $skill -PathType Leaf) -and
        ((Get-Item -LiteralPath $skill).Length -gt 0)) {
      return $d.FullName
    }
  }
  return $null
}

# ── 按 agent 查找单个 Superpowers Skill ─────────────────────────────────────
function Find-SuperpowersSkill {
  param([string]$Agent, [string]$Name)
  $hit = Find-DlcSkill -Agent $Agent -Name $Name
  if ($hit) { return $hit }
  $pluginDir = Find-SuperpowersPluginDir
  if ($pluginDir) {
    $candidate = Join-Path $pluginDir "skills/$Name/SKILL.md"
    if ((Test-Path -LiteralPath $candidate -PathType Leaf) -and
        ((Get-Item -LiteralPath $candidate).Length -gt 0)) {
      return $candidate
    }
  }
  return $null
}

# ── 汇总状态 ────────────────────────────────────────────────────────────────
# 返回 PSCustomObject：Installed / Enabled / Ready / WritingPlans / ExecutingPlans
# （Installed/Enabled 为兼容既有报告模板字段：Installed=两者至少其一，Enabled=两者都有）
function Get-SuperpowersStatus {
  param([string]$Agent)
  $wp = Find-SuperpowersSkill -Agent $Agent -Name 'writing-plans'
  $ep = Find-SuperpowersSkill -Agent $Agent -Name 'executing-plans'
  $installed = [bool]$wp -or [bool]$ep
  $ready = [bool]$wp -and [bool]$ep
  return [PSCustomObject]@{
    Installed      = $installed
    Enabled        = $ready
    Ready          = $ready
    WritingPlans   = $wp
    ExecutingPlans = $ep
  }
}

function Get-SuperpowersInstallHint {
  param([string]$Agent)
  $target = $Agent
  if (-not $target -or $target -eq 'unknown') { $target = 'claude-code' }
  return "npx skills add obra/superpowers --skill writing-plans --skill executing-plans -a $target -g"
}
