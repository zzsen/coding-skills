# =============================================================================
# _agent-lib.ps1 — Agent（IDE）抽象层：路径 / openspec 目标 / Rules 载体解析
# =============================================================================
# 【功能】.sh 版 _agent-lib.sh 的 PowerShell 对等实现，支持 claude-code / cursor / codex。
# 【调用方】被 check-env.ps1、check-superpowers.ps1、restore-rules.ps1、
#           ensure-openspec.ps1 等 dot-source 使用，不单独执行。
# 【Agent 解析优先级】环境变量 DEVLC_AGENT → 本 Skill 安装路径 → 项目标记 → 用户级目录 → unknown
# =============================================================================

function Get-DlcSkillRoot {
  return (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
}

function Get-DlcAgent {
  # 1. 环境变量显式指定
  $envAgent = $env:DEVLC_AGENT
  if ($envAgent) {
    if (@('claude-code', 'cursor', 'codex') -contains $envAgent) { return $envAgent }
    return 'unknown'
  }

  # 2. 由本 Skill 的安装位置反推
  $root = (Get-DlcSkillRoot) -replace '\\', '/'
  if ($root -like '*/.claude/skills/*') { return 'claude-code' }
  if ($root -like '*/.cursor/skills/*') { return 'cursor' }
  if ($root -like '*/.agents/skills/*') { return 'codex' }

  # 3. 项目内标记
  if (Test-Path '.claude' -PathType Container) { return 'claude-code' }
  if (Test-Path '.cursor' -PathType Container) { return 'cursor' }
  if ((Test-Path '.agents' -PathType Container) -or (Test-Path 'AGENTS.md')) { return 'codex' }

  # 4. 用户级目录
  $home_ = $env:USERPROFILE; if (-not $home_) { $home_ = $env:HOME }
  if ($home_) {
    if (Test-Path (Join-Path $home_ '.claude') -PathType Container) { return 'claude-code' }
    if (Test-Path (Join-Path $home_ '.cursor') -PathType Container) { return 'cursor' }
    if (Test-Path (Join-Path $home_ '.agents') -PathType Container) { return 'codex' }
  }

  return 'unknown'
}

function Get-DlcAgentLabel {
  param([string]$Agent)
  switch ($Agent) {
    'claude-code' { 'Claude Code' }
    'cursor'      { 'Cursor' }
    'codex'       { 'Codex' }
    default       { 'Unknown' }
  }
}

# openspec init --tools 目标；未知 agent 回落 vendor-neutral 的 agents
function Get-DlcOpenspecTool {
  param([string]$Agent)
  switch ($Agent) {
    'claude-code' { 'claude' }
    'cursor'      { 'cursor' }
    'codex'       { 'codex' }
    default       { 'agents' }
  }
}

# OpenSpec CLI 探测（多安装方式兼容）：PATH / nvm / npm-global / volta / fnm。
# 找到后把其 bin 目录前置到 PATH（该目录通常同时含 node，保证 shebang 可解析），
# 返回 openspec 可执行文件绝对路径；未找到返回 $null。
function Resolve-DlcOpenspec {
  $cmd = Get-Command openspec -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }

  $home_ = $env:USERPROFILE; if (-not $home_) { $home_ = $env:HOME }
  if (-not $home_) { return $null }

  $candidates = @(
    (Join-Path $home_ '.nvm/current/bin'),
    (Join-Path $home_ '.npm-global/bin'),
    (Join-Path $home_ '.volta/bin'),
    (Join-Path $home_ '.fnm/aliases/default/bin')
  )

  $nvmVersions = Join-Path $home_ '.nvm/versions/node'
  if (Test-Path -LiteralPath $nvmVersions -PathType Container) {
    $candidates += Get-ChildItem -LiteralPath $nvmVersions -Directory |
      ForEach-Object { Join-Path $_.FullName 'bin' }
  }

  $fnmRoots = @(
    (Join-Path $home_ '.local/share/fnm/node-versions'),
    (Join-Path $home_ 'Library/Application Support/fnm/node-versions'),
    (Join-Path $home_ '.fnm/node-versions')
  )
  foreach ($root in $fnmRoots) {
    if (Test-Path -LiteralPath $root -PathType Container) {
      $candidates += Get-ChildItem -LiteralPath $root -Directory |
        ForEach-Object { Join-Path $_.FullName 'installation/bin' }
    }
  }

  foreach ($d in $candidates) {
    $bin = Join-Path $d 'openspec'
    if (Test-Path -LiteralPath $bin -PathType Leaf) {
      $sep = [System.IO.Path]::PathSeparator
      $env:PATH = "$d$sep$env:PATH"
      return $bin
    }
  }
  return $null
}

function Get-DlcSkillsDirs {
  param([string]$Agent)
  $home_ = $env:USERPROFILE; if (-not $home_) { $home_ = $env:HOME }
  switch ($Agent) {
    'claude-code' { @('.claude/skills', (Join-Path $home_ '.claude/skills')) }
    'cursor'      { @('.cursor/skills', '.agents/skills', (Join-Path $home_ '.cursor/skills')) }
    'codex'       { @('.agents/skills', (Join-Path $home_ '.agents/skills')) }
    default       {
      @('.agents/skills', (Join-Path $home_ '.agents/skills'),
        '.claude/skills', (Join-Path $home_ '.claude/skills'),
        '.cursor/skills', (Join-Path $home_ '.cursor/skills'))
    }
  }
}

# Rules 载体：mdc | memory-file | none（已从硬门禁降级为 agent 可选项）
function Get-DlcRulesKind {
  param([string]$Agent)
  switch ($Agent) {
    'cursor'      { 'mdc' }
    'claude-code' { 'memory-file' }
    'codex'       { 'memory-file' }
    default       { 'none' }
  }
}

function Get-DlcRulesTargets {
  param([string]$Agent)
  switch ($Agent) {
    'cursor' {
      @('.cursor/rules/01-openspec-workflow.mdc',
        '.cursor/rules/02-tdd-plan-wave-tracking.mdc',
        '.cursor/rules/03-askquestion-task-followup.mdc')
    }
    'claude-code' { @('CLAUDE.md') }
    'codex'       { @('AGENTS.md') }
    default       { @() }
  }
}

function Find-DlcSkill {
  param([string]$Agent, [string]$Name)
  foreach ($dir in (Get-DlcSkillsDirs -Agent $Agent)) {
    if (-not $dir) { continue }
    $candidate = Join-Path $dir "$Name/SKILL.md"
    if ((Test-Path -LiteralPath $candidate -PathType Leaf) -and
        ((Get-Item -LiteralPath $candidate).Length -gt 0)) {
      return $candidate
    }
  }
  return $null
}

# ── 项目级运行时状态（全局安装时 Skill 目录为多项目共享，配置须落项目）────
function Get-DlcStateDir {
  if ($env:DEVLC_STATE_DIR) { return $env:DEVLC_STATE_DIR }
  return '.dev-lifecycle'
}

function Get-DlcProjectConfigPath {
  $proj = Join-Path (Get-DlcStateDir) 'project-config.md'
  $fallback = Join-Path (Get-DlcSkillRoot) 'project-config.md'
  if (Test-Path -LiteralPath $proj -PathType Leaf) { return $proj }
  if (Test-Path -LiteralPath $fallback -PathType Leaf) { return $fallback }
  return $proj
}

# 门禁通过时间标记：preflight **仅在 environment-ready: True 时**写入
# （首行可读时间 + 次行 epoch）；preflight 入口处据此判定是否可在
# 有效期内（默认 7 天）跳过全量门禁
function Get-DlcPreflightMarker {
  return (Join-Path (Get-DlcStateDir) '.preflight-last-run')
}
