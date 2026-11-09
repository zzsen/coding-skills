# =============================================================================
# timestamp.ps1 — 系统时间输出（PowerShell）
# =============================================================================
# 【功能】从 Shell 获取真实系统时间，禁止 Agent 编造时间戳。
# 【调用阶段】全阶段（产物头、计划目录名、任务编号日期、归档日期等）。
# 【输入】-Format datetime|date|dir-ts|iso-date（默认 datetime）
# 【输出】stdout 单行时间字符串；exit 0
# 【流程】按 Format 调用 Get-Date 格式化输出
# 【用法】& <skill_root>/scripts/timestamp.ps1 [-Format dir-ts]
# =============================================================================
param(
  [ValidateSet('datetime', 'date', 'dir-ts', 'iso-date')]
  [string]$Format = 'datetime'
)

. (Join-Path $PSScriptRoot '_init-ps.ps1')
Initialize-DevLifecycleConsole

switch ($Format) {
  'datetime' { Get-Date -Format 'yyyy-MM-dd HH:mm:ss' }
  'date'     { Get-Date -Format 'yyyyMMdd' }
  'dir-ts'   { Get-Date -Format 'yyyyMMddHHmmss' }
  'iso-date' { Get-Date -Format 'yyyy-MM-dd' }
}
