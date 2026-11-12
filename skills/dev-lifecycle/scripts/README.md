# dev-lifecycle 脚本索引

> 路径前缀：`<skill_root>/scripts/`
> 须在**项目根目录**执行（除注明外）。

## 脚本文件头备注规范

每个脚本文件头部**独立写明**（禁止写「同 xxx.sh」）：

1. **【功能】** — 脚本职责  
2. **【调用阶段】** — 对应 Phase / preparation 步骤  
3. **【输入】** — 参数与环境要求  
4. **【输出】** — stdout、生成文件、exit code 含义  
5. **【流程】** — 执行步骤  

`.ps1` 与 `.sh` 成对脚本内容等价，但备注须各自完整描述。

## 脚本一览

| 脚本 | 路径 | 调用阶段 | 功能 | 入参 | 输出 |
|------|------|---------|------|------|------|
| **preflight** | `preflight.ps1` / `preflight.sh` | 前置（**首个 Shell**） | `check-env` → `restore-rules` → `ensure-openspec` → `check-env`；**内置 7 天门禁缓存**：`.preflight-last-run` 未超期则输出 `gate-cache: valid` 直接跳过 | 可选 `--json` / `-Json`、`--force` / `-Force`、`--max-age-days=N` | 分段检查输出；**仅门禁通过时**刷新 `.preflight-last-run` 时间戳 |
| **check-env** | `check-env.ps1` / `check-env.sh` | 前置步骤 1 | 环境定点检查 | 可选 `--json` | 路径（含 `openspec/`）、`openspec-*`、`superpowers_*`、`environment-ready` 等 |
| **_agent-lib**（库） | `_agent-lib.ps1` / `.sh` | 被其他脚本 source | agent 探测、skills 目录 / openspec slug / 规则载体 / 项目级状态路径解析 | — | 函数库，不单独执行 |
| **check-superpowers** | `check-superpowers.ps1` / `.sh` | 前置 / 单独 | 按 agent 查找 `writing-plans` / `executing-plans` | `--json`、`--agent=<id>` | `agent`、`superpowers-ready`、两个 Skill 路径 |
| **enable-superpowers** | `enable-superpowers.ps1` / `.sh` | 前置 AskUserQuestion #2 | 打印 / 执行 `npx skills add obra/superpowers` | `--run`、`--agent=<id>`、`--project` | `RESULT: ALREADY_READY\|PRINTED\|INSTALLED\|ERROR` |
| **restore-rules** | `restore-rules.ps1` / `restore-rules.sh` | 前置步骤 0 | 复制缺失 Rules | 可选 `--dry-run` | `Rules restored` / `all present` |
| **ensure-openspec** | `ensure-openspec.ps1` / `ensure-openspec.sh` | 前置 / preflight | 缺 `openspec/` 则 `openspec init --tools <agent-slug>` | 可选 `--dry-run` | `initialized` / `already present` / `CLI_MISSING` |
| **init-plan-dir** | `init-plan-dir.ps1` / `init-plan-dir.sh` | Phase 1 前 | 创建 dev-plan 目录 | `--type` + `--detail` | 计划目录路径 |
| **timestamp** | `timestamp.ps1` / `timestamp.sh` | 全阶段 | 系统时间 | `--format datetime\|date\|dir-ts\|iso-date` | 时间字符串 |
| **next-task-id** | `next-task-id.ps1` / `next-task-id.sh` | Phase 1~7 | 下一任务编号 | 可选 `--plan-dir` | `T-YYYYMMDD-N` |
| **validate-project-config** | `validate-project-config.ps1` / `.sh` | Phase 1 前 | 校验 project-config | 可选 `--path` | `RESULT: valid/invalid` |
| **safe-list-files** | `safe-list-files.ps1` / `.sh` | 探索 | 白名单路径列表 | `--scope backend\|frontend\|all` | 允许探索的文件路径 |
| **gate-phase2** | `gate-phase2.ps1` / `.sh` | Phase 2 前 | 硬门禁检查 | `--plan-dir` + `--change-name` | `GATE_PHASE2: pass/block` |
| **gate-phase7** | `gate-phase7.ps1` / `.sh` | Phase 7 | 验收前完整性 | `--plan-dir` | `GATE_PHASE7: pass/block` |
| **check-plan-artifacts** | `check-plan-artifacts.ps1` / `.sh` | 各 Phase 完成 | 按阶段检查产物 | `--plan-dir` + `--phase 1-7` | `ARTIFACTS_PHASEn: pass/block` |
| **run-tests** | `run-tests.ps1` / `run-tests.sh` | Phase 4 | 执行 go test / vitest | `<plan-dir>` | `test-results/*.log`、`test-counts.json` |
| **parse-test-results** | `parse-test-results.js` | Phase 4 | 解析测试日志 | `<plan-dir>` | `test-counts.json`、stdout KEY=VALUE |
| **run-lint** | `run-lint.ps1` / `run-lint.sh` | Phase 5 | Lint 检测 | `<plan-dir>` | `lint-results/`、`5.lint-report.md` |
| **parse-lint-results** | `parse-lint-results.js` / `.py` / `.go` | Phase 5 | 解析 Lint 日志 | `<plan-dir>` | `lint-counts.json` |
| **check-wave-sync** | `check-wave-sync.ps1` / `.sh` | Phase 3 / 7 | Wave 表一致性 | `--plan-dir`、可选 `--tdd-path` | `WAVE_SYNC: pass/block` |
| **check-tasks-sync** | `check-tasks-sync.ps1` / `.sh` | Phase 3 收尾 | tasks 勾选状态 | `--change-name`、可选 `--plan-dir` | `TASKS_SYNC: pass/block` |
| **update-proposal-links** | `update-proposal-links.ps1` / `.sh` | Phase 7 归档后 | 更新 archive 链接 | `--plan-dir`、`--change-name`、`--archive-date` | `LINKS_UPDATED: N` |

## 常用命令

```powershell
# 入口门禁（推荐，替代分步 0.5 + 0；内置 7 天缓存，未超期自动跳过）
& <skill_root>/scripts/preflight.ps1
# 强制全量重跑：& <skill_root>/scripts/preflight.ps1 -Force

# 创建计划目录
& <skill_root>/scripts/init-plan-dir.ps1 -Type feat -Detail user-management

# Phase 2 硬门禁
& <skill_root>/scripts/gate-phase2.ps1 -PlanDir dev-plan/... -ChangeName user-management
```

```bash
bash <skill_root>/scripts/preflight.sh            # 内置 7 天缓存；--force 强制全量
bash <skill_root>/scripts/init-plan-dir.sh --type feat --detail user-management
bash <skill_root>/scripts/run-tests.sh dev-plan/.../
bash <skill_root>/scripts/run-lint.sh dev-plan/.../
```

## 说明

- **preflight** 为 SKILL §1.1 步骤 1 的唯一首调用：先查 `.dev-lifecycle/.preflight-last-run`（仅门禁通过时写入），距今 ≤ 7 天（`--max-age-days` / `DEVLC_GATE_MAX_AGE_DAYS` 可覆盖）→ `gate-cache: valid` 直接退出，本会话跳过全量门禁；超期 / 缺失 / 不可解析 → 自动全量执行，通过后刷新时间戳（并按 §2.1 重新校验 project-config）。`--force` 或删除该标记可强制重跑。
- **preflight** 亦可替换为单独跑 `check-env` + `restore-rules` + `ensure-openspec`（但无缓存、不刷新通过时间戳，不推荐）。
- **writing-plans**、**AskUserQuestion 确认**、**/opsx:*** 命令不可由脚本替代。
- `run-lint` 当前硬编码 `backend/` + `frontend/`；多语言扩展见 [phase5.md](../phases/phase5.md)。

### Windows PowerShell 编码（`.ps1`）

Windows PowerShell 5.x 解析脚本源文件时默认按系统 ANSI 编码，**UTF-8 无 BOM** 的 `.ps1` 会导致源码中的中文在运行时乱码（如标题显示为 `鐜瀹氱偣妫€鏌?`）。

**已采取的修复：**

1. 所有 `.ps1` 保存为 **UTF-8 BOM**（含中文注释与 `Write-Host` 字符串）。
2. 各脚本在 `param` 块后 dot-source 公共初始化：

```powershell
. (Join-Path $PSScriptRoot '_init-ps.ps1')
Initialize-DevLifecycleConsole
```

3. `_init-ps.ps1` 在 PS 5.x 下将控制台输出编码设为 UTF-8（`chcp 65001`）；PowerShell 7+ 跳过。

**验证：** 在项目根执行 `check-env.ps1`，标题应显示 `=== dev-lifecycle 环境定点检查 ===`。

`.sh` 脚本保持 UTF-8（无 BOM），在 Git Bash / WSL / macOS / Linux 下无此问题。
