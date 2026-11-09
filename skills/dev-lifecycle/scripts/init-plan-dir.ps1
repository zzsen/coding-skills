# =============================================================================
# init-plan-dir.ps1 — 创建 dev-plan 计划目录（PowerShell）
# =============================================================================
# 【功能】按 SKILL §4.1 规范创建带时间戳的计划目录及 lint-results/ 子目录。
# 【调用阶段】Phase 1 前（新需求场景 E）。
# 【输入】-Type feat|fix|refactor|perf|docs、-Detail kebab-case（均必填）
# 【输出】stdout：新建计划目录相对路径；exit 0
# 【流程】
#   1. 校验 Type / Detail
#   2. Get-Date 生成 YYYYMM、YYYYMMDD、时间戳
#   3. 创建 dev-plan/.../lint-results/
#   4. 打印路径
# 【用法】& <skill_root>/scripts/init-plan-dir.ps1 -Type feat -Detail user-mgmt
# =============================================================================
param(
  [Parameter(Mandatory = $true)]
  [ValidateSet('feat', 'fix', 'refactor', 'perf', 'docs')]
  [string]$Type,
  [Parameter(Mandatory = $true)]
  [string]$Detail
)

. (Join-Path $PSScriptRoot '_init-ps.ps1')
Initialize-DevLifecycleConsole

$yyyymm = Get-Date -Format 'yyyyMM'
$yyyymmdd = Get-Date -Format 'yyyyMMdd'
$ts = Get-Date -Format 'yyyyMMddHHmmss'
$planDir = "dev-plan/$yyyymm/$yyyymmdd/${ts}_${Type}_${Detail}"
New-Item -ItemType Directory -Path "$planDir/lint-results" -Force | Out-Null
Write-Output $planDir
