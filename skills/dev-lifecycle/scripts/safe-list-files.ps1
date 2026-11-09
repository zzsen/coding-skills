# =============================================================================
# safe-list-files.ps1 — 白名单探索路径列表（PowerShell）
# =============================================================================
# 【功能】列出允许 Read/Glob 的路径，排除 exploration.md §一黑名单，替代 Glob **/*。
# 【调用阶段】探索 / 生成 project-config 前。
# 【输入】-Scope backend|frontend|all（默认 all）
# 【输出】stdout：去重排序后的相对路径；exit 0
# 【流程】
#   1. 按 Scope 输出 go.mod、package.json 等定点文件
#   2. 递归枚举源码并过滤黑名单目录
# 【用法】& .../safe-list-files.ps1 [-Scope all]
# =============================================================================
param(
  [ValidateSet('backend', 'frontend', 'all')]
  [string]$Scope = 'all'
)

. (Join-Path $PSScriptRoot '_init-ps.ps1')
Initialize-DevLifecycleConsole

$ignore = 'node_modules|\.git|vendor|\\\.venv\\|\\venv\\|\\dist\\|\\build\\|dev-plan|\.cursor'

function List-If($p) { if (Test-Path $p) { $p } }

function Safe-Glob($base, $filter) {
  if (-not (Test-Path $base)) { return }
  Get-ChildItem -Path $base -Recurse -File -Filter $filter -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch $ignore } |
    ForEach-Object { $_.FullName.Replace((Get-Location).Path + '\', '').Replace('\', '/') }
}

$out = @()
if ($Scope -in @('backend', 'all')) {
  $out += List-If 'backend/go.mod'
  $out += List-If 'backend/conf/config.default.yml'
  $out += Safe-Glob 'backend' '*.go'
}
if ($Scope -in @('frontend', 'all')) {
  $out += List-If 'frontend/package.json'
  $out += List-If 'frontend/vite.config.ts'
  $out += List-If 'frontend/tsconfig.json'
  $out += Safe-Glob 'frontend/src' '*'
}
if ($Scope -eq 'all') {
  $out += List-If '$(Join-Path $PSScriptRoot '../templates/project-config.md')'
}
$out | Where-Object { $_ } | Sort-Object -Unique
