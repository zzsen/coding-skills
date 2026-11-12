---
name: dev-lifecycle
description: 端到端开发生命周期管理：把需求从 OpenSpec 方案推进到验收归档，强制走 OpenSpec（explore/propose/apply/archive）与 Superpowers（writing-plans/executing-plans）官方工具链，产出 dev-plan 七阶段产物。当用户要求「制定方案 / 制定开发计划 / 做设计 / 开发新功能 / 按流程开发」时使用。执行铁律：首个工具调用仅 preflight（内置 7 天缓存：.preflight-last-run 未超期则自动跳过门禁，超期才全量执行并刷新时间戳、重新校验 project-config）；未过环境门禁禁止探索仓库与写产物；禁用 brainstorming；Explore 须先在对话正文输出 §2.1 六节再提问。
---

# 全流程开发生命周期管理

将需求从 **OpenSpec 方案** 推进到 **验收归档**。dev-plan 存索引，权威内容在 `openspec/` 与 `docs/superpowers/plans/`。

> **本 Skill 为多 IDE 通用版**，支持 Claude Code / Cursor / Codex。路径、openspec 目标、规则载体由
> [scripts/_agent-lib.sh](scripts/_agent-lib.sh)（及 `.ps1` 对等实现）按 agent 解析，见 **§0.3 术语与路径对照**。

> Phase 1 Explore 交付铁律（§2.1 正文 → AskUserQuestion）见 **[phase1.md](phases/phase1.md) 文首「Explore 铁律」**。


各 Phase 规则在独立 phase 文件中，执行具体 Phase 时，**必须**读取具体对应的phase/phaseN.md, 如执行 Phase 1是，必须先读取**[phase1.md](phases/phase1.md) ；**入口强制链除外**（见 §1.3）。

### 文档导航

| 章节 | 内容 |
|------|------|
| [§〇](#〇skill-互斥与强制工具) | Skill 互斥、**强制 OpenSpec/Superpowers 工具**、用户表述路由 |
| [§一](#一入口门禁最高优先级) | 首个回合、禁止项、读取链、环境处理、Phase 2 硬门禁 |
| [§二](#二场景判定仅门禁可以后执行) | project-config、场景、诉求→Phase、Explore 分流 |
| [§三](#三全流程) | 7 Phase 总览与流转 |
| [§四](#四产物与时间) | dev-plan 目录、时间戳、任务编号 |
| [§五](#五快速启动) | 常见场景入口 |
| [§六](#六参考与脚本) | 辅助资源、脚本索引 |

---

## 〇、Skill 互斥与强制工具

> 用户诉求含「制定方案 / 制定开发计划 / 新功能 / 做设计」且命中本 Skill 时，**本 Skill 独占流程**，下列规则 **优先于** Superpowers `brainstorming` 的 “MUST use before creative work”。
>
> **强制工具权威**：[mandatory-tooling.md](reference/mandatory-tooling.md)（Explore / Propose / Apply / Archive → OpenSpec；writing-plans / executing-plans → Superpowers；**禁止手写替代**）。

### 0.1 强制工具一览（硬性）

| 阶段 | 必须（command **或** Skill） | 禁止手写替代 |
|------|------------------------------|-------------|
| Explore | `/opsx:explore` · `openspec-explore` | 纯会话 Explore、brainstorming |
| Propose | `/opsx:propose` · `openspec-propose` | 手写 `openspec/changes/` |
| Apply | `/opsx:apply` · `openspec-apply-change` | **仅**全部 Wave ✅ 后收尾 `tasks` 剩余项；**禁止** Phase 3 入口直接 apply |
| Archive | `/opsx:archive` · `openspec-archive-change` | 仅手动移动目录 |
| TDD 计划 | **`writing-plans`** Skill | 手写 `docs/superpowers/plans/*-tdd.md` |
| Wave 实施 | **`executing-plans`** Skill | Phase 3 **主路径**；不读 Skill 自由编码；用 apply 代替 Wave TDD |

### 0.2 Skill 互斥（违规即流程错误）

| 禁止 | 正确替代 |
|------|----------|
| **Read / 调用 `brainstorming` Skill** | **`/opsx:explore`** 或 **`openspec-explore`** → AskUserQuestion → **`/opsx:propose`** |
| 未过门禁即探索仓库「了解项目」 | 首个 Tool Call：**仅** `preflight`（内置 7 天缓存，未超期自动跳过） |
| 把「制定开发计划」当成 brainstorming | Phase 1 OpenSpec 工具链 → Phase 2 **`writing-plans`** |
| 环境 ❌ 时继续方案/计划讨论 | **停止** + 仅环境 AskUserQuestion |
| 手写 openspec / TDD 替代上述工具 | 补环境后调用对应 command/Skill |
| Phase 3 入口直接 `apply` / `openspec-apply-change` | **先** `executing-plans` → 全部 Wave ✅ → **再** apply 收尾剩余 tasks |

**用户表述路由**（命中 dev-lifecycle 时）

| 用户说 | 实际路径 | 禁止 |
|--------|----------|------|
| 制定开发计划 / 出方案 / 做设计 | 门禁 → Phase 1（OpenSpec explore+propose）→ Phase 2（writing-plans） | `brainstorming`、手写 openspec/TDD |
| 开始开发 / 写代码 | Phase 3：**先**使用 `executing-plans` 按 Wave TDD → **全部 Wave ✅ 后**  → 再 `/opsx:apply` 收尾 | Phase 3 入口直接 `apply`；未过 Phase 2 时 `writing-plans` |
| 新功能 XXX | 门禁 → `/opsx:explore` → **对话正文 §2.1** → AskUserQuestion → `/opsx:propose` | `brainstorming`、纯会话 Explore、跳过 §2.1 正文 |

> 完整禁止项见 [§1.2](#12-禁止项门禁通过前一律生效)。

### 0.3 术语与路径对照（多 IDE）

本文档使用规范名，实际工具名/路径按当前 agent 解析。`preflight` 首行会输出 `agent = <id>`。

| 文档用语 | Claude Code | Cursor | Codex |
|----------|-------------|--------|-------|
| **Shell**（执行命令） | `Bash` | `Shell` | `shell` |
| **AskUserQuestion**（结构化提问） | `AskUserQuestion` | `AskQuestion` | ⚠️ 无此工具 → **在回复正文列出编号选项并停下等待用户选择**，语义等价 |
| **Edit**（按串替换改文件） | `Edit` | `StrReplace` | `apply_patch` |
| **TodoWrite**（待办清单） | `TodoWrite`（无 `id` 字段、用户不可勾选）| `todo_write`（可勾选） | 无 → 在正文维护编号清单 |
| 文件搜索 | `Glob` / `Grep` | `search files` | `rg` via shell |
| `<skill_root>` | `~/.claude/skills/dev-lifecycle` 或 `.claude/skills/dev-lifecycle` | `~/.cursor/skills/dev-lifecycle` 或 `.cursor/skills/dev-lifecycle` | `~/.agents/skills/dev-lifecycle` 或 `.agents/skills/dev-lifecycle` |
| `<agent-skills-dir>` | `.claude/skills/` | `.cursor/skills/` | `.agents/skills/` |
| `<agent-commands-dir>` | `.claude/commands/` | `.cursor/commands/` | （无 slash command，改用 Skill 调用） |
| `<agent-slug>`（openspec init --tools） | `claude` | `cursor` | `codex` |
| 常驻规则载体 | `CLAUDE.md` | `.cursor/rules/*.mdc` | `AGENTS.md` |

> **`<skill_root>` 的解析**：即本 `SKILL.md` 所在目录。文中所有 `bash <skill_root>/scripts/xxx.sh`
> 都应替换为该绝对路径。脚本内部自行用 `SCRIPT_DIR` 定位，无需额外参数。
>
> **Codex 无结构化提问工具**：凡文档要求 `AskUserQuestion` 处，Codex 下改为「正文列编号选项 + 停止等待」，
> **隔离规则（环境专用 / 禁止合并 / 禁止越级）同样适用**，不得因无工具而跳过确认直接推进。

---


## 一、入口门禁（最高优先级）

> **阻断条件**：未完成本节且未在**首个回复**输出 [门禁检查报告](templates/00-pre-flight-check-report.md) → **禁止**写产物、**禁止**探索仓库、**禁止**进入 Phase 1+。

### 1.1 首个回合（Shell 优先，固定三步）

> **步骤 1 必须是本会话第一个工具调用**（先于 Read 项目文件、`validate-project-config`、`safe-list-files`、Glob/Grep）。

| 步 | 动作 | 完成标志 |
|:--:|------|----------|
| 1 | **一次** `Shell`：执行 preflight（**禁止** `cd &&` 拼接）。preflight **内置门禁缓存**：`.preflight-last-run` 距今 ≤ 7 天 → 输出 `gate-cache: valid` 并直接退出（跳过全量门禁）；超期 / 缺失 / 不可解析 → 自动继续全量执行 | 缓存：`gate-cache: valid` + `environment-ready: True（缓存）`；全量：`environment-ready: True` 或明确各项 True/False |
| 2 | 连续 `Read`：`preparation.md` → `00-pre-flight-check-report.md` | 两文件已读；`exploration.md` **门禁「可以」后再读** |
| 3 | **首个回复**输出门禁报告 | §1 引用步骤 1 输出（缓存命中标注「缓存命中 + 上次通过时间」；**禁止猜测** ✅/❌） |

**preflight 唯一合法调用**（项目根；`<skill_root>` = 本 SKILL.md 所在目录）

```bash
bash <skill_root>/scripts/preflight.sh
```

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "<skill_root>\scripts\preflight.ps1"
```

**门禁时间戳缓存规则（preflight 内置）**

- 缓存依据：`.dev-lifecycle/.preflight-last-run`，由 **preflight 仅在门禁通过（`environment-ready: True`）时**写入的最后通过时间（首行可读时间 + 次行 epoch）。**存在且未超期即代表门禁通过**；未通过不刷新，下次会话自然全量重跑。
- `gate-cache: valid`（距今 ≤ 7 天）→ **跳过全量门禁**，门禁报告标注「缓存命中 + 上次通过时间」。
- `missing`（含上次未通过）/ `stale`（超期）/ `malformed` → preflight **自动继续全量执行**；通过后刷新时间戳，并按 §2.1 重新校验/更新 project-config。
- 有效期默认 **7 天**：`--max-age-days=N`（PowerShell：`-MaxAgeDays N`）或环境变量 `DEVLC_GATE_MAX_AGE_DAYS` 覆盖；`--force`（PS：`-Force`）或**删除标记文件**可强制全量重跑。
- preflight 首行输出 `agent = <claude-code|cursor|codex>`，门禁报告须原样引用。
- 自动探测不准时加 `--agent=<id>`（PowerShell：`-Agent <id>`），或设环境变量 `DEVLC_AGENT`。
- preflight 内含 **规则恢复**（仅 Cursor 实际写文件，其余 agent 仅提示；见 §1.4；缓存命中跳过时本周内不重复恢复）。

**环境未就绪时**（§1 任一项 ❌ 且未补全）

- **停止**：禁止 §二、禁止 Phase 1+、禁止探索仓库、禁止写产物
- **仅**输出门禁报告 + **仅**环境 AskUserQuestion（#1a / #1b / #2，见 §1.4）
- **禁止**在同一 `AskUserQuestion` 或同一回复末尾混入 Phase 确认类提问（如「是否开始 Phase 1」「下一步做什么」）

### 1.2 禁止项（门禁通过前一律生效）

| 类别 | 禁止 | 允许 / 替代 |
|------|------|-------------|
| **仓库扫描** | `Glob **/*`、`Glob *`、`backend/**`、`frontend/**` 根递归；`Grep` / `-Recurse` 扫仓库；`@backend` / `@frontend` 后直接全量列举 | `safe-list-files`；定点 `Read`；`preflight` / `check-env` |
| **写产物** | `dev-plan/**`、`openspec/**`、`.dev-lifecycle/project-config.md`、常驻规则载体（恢复除外）、`<agent-commands-dir>/**`（官方 init 除外）、`docs/superpowers/plans/**` | 门禁结论「可以」后 |
| **手写替代** | 手写 `openspec/changes/`、手写 TDD、自编 `opsx-*.md`；不调用 OpenSpec/Superpowers 官方工具 | 见 [mandatory-tooling.md](reference/mandatory-tooling.md) |
| **Skill 互斥** | **`brainstorming`**；未过 Phase 1 调用 **`writing-plans`**；Phase 3 未读 **`executing-plans`** | OpenSpec command/Skill；Superpowers writing-plans / executing-plans |

- **全局扫描黑名单**（`node_modules/`、`.git/`、`vendor/`、`.venv/`、`venv/` 等）：[exploration.md](phases/exploration.md) §1.1
- **门禁通过后**方允许探索：定点 `Read`（如 `backend/go.mod`）、`Glob frontend/src/**`、`Glob backend/**/*.go`
- 报告结论「**不可以**」→ **停止**，按 §1.4 补环境或 **仅**环境 AskUserQuestion，不得静默绕过，**不得**继续后续 Phase

### 1.3 强制读取链

| # | 时机 | 文件 | 用途 |
|---|------|------|------|
| — | **步骤 1 之前** | 无 | **禁止** Read 项目内文件 |
| 1 | 步骤 1 之后 | [phases/preparation.md](phases/preparation.md) | 环境判定、规则恢复、环境 AskUserQuestion #1a/#1b/#2 |
| 2 | 步骤 1 之后 | [templates/00-pre-flight-check-report.md](templates/00-pre-flight-check-report.md) | 首个回复报告模板 |
| 3 | **门禁「可以」后** | [phases/exploration.md](phases/exploration.md) | 扫描黑名单与白名单（未过门禁禁止读） |
| 4 | **进入 Phase 1 新功能 Explore 前** | [phases/phase1.md](phases/phase1.md) | 文首 **Explore 铁律** + §2.0.5–§2.2 |

### 1.4 环境不合规处理

**OpenSpec 就绪** = `openspec-cli-installed: True` **且** `openspec-list-ok: True` **且** 项目根存在 `openspec/` 目录（即 `openspec-ready: True`）。

**OpenSpec 判定**：CLI 全局安装、`openspec list` 退出码 0、以及定点检查 `openspec/` 是否存在。**不**递归扫描 `openspec/changes|specs|archive`。缺失 `openspec/` 时由 **preflight → ensure-openspec** 自动执行 `openspec init --tools <agent-slug>`（类似 Rules 自动恢复，**不询问**）。

**Superpowers 环境就绪** = `writing-plans` **与** `executing-plans` 两个 Skill 均在当前 agent 的 skills 目录中命中（即 `superpowers_ready: True`）。检测由 [check-superpowers](scripts/check-superpowers.sh) 完成，兼容字段 `superpowers_installed`（两者至少其一）/ `superpowers_enabled`（两者都有）。

**门禁「可以」**（进入 **任何** Phase 1~7 的前置条件，**缺一不可**）：

```
environment-ready: True
```

即 Shell 同时满足：`openspec-ready: True` **且** `superpowers_ready: True`。

> ⚠️ **门禁口径变更（多 IDE 版）**：常驻规则（Cursor 的三个 `.mdc`）**已从硬门禁降级为 agent 可选项**，
> `rules-ok` 仅作信息项输出，**不参与** `environment-ready` 计算 —— Claude Code / Codex 没有
> 与 `.cursor/rules/*.mdc` 等价的强制加载机制，继续当硬门禁会导致这两个 agent 永远过不了门禁。
> 规则正文内容与本 Skill 各 phase 文档重复，规则缺失不影响流程正确性。

> **`environment-ready: False` → 禁止进入 Phase 1~7**（含 Explore、propose、写 dev-plan/openspec 产物）。不得因「仅 OpenSpec 就绪」宣告可进入 Phase 1。

**禁止表述（违规）**

| 禁止说法 | 正确说法 |
|----------|----------|
| 「OpenSpec 已就绪，可进入 Phase 1；Superpowers 未就绪会阻塞 Phase 2」 | 「环境未就绪（`environment-ready: False`），**禁止**进入 Phase 1+；须补 Superpowers 后重跑 preflight」 |
| Superpowers ❌ 时标 ⚠️ 并继续 Phase 1 | 门禁结论 **不可以**，仅环境 AskUserQuestion，**停止** |
| 分项就绪即开始任务 Phase | 仅 `environment-ready: True` 后才开始任务 Phase |

| 缺失项 | 判定依据（Shell 输出） | Agent 行为 | AskUserQuestion |
|--------|------------------------|-----------|-------------|
| **规则（可选项）** | `rules-ok: false` | Cursor：自动从 `reference/` 复制 `.mdc`（preflight 已含）；Claude Code / Codex：仅提示可并入 `CLAUDE.md` / `AGENTS.md`，**不自动写**、**不阻断** | 否 |
| **OpenSpec CLI** | `openspec-cli-installed: False` | 报告标 ❌ | **是**（#1a，仅环境） |
| **OpenSpec list / 目录** | `openspec-list-ok: False`，或 `openspec/` 仍缺失（ensure 失败） | 报告标 ❌ | **是**（#1b，仅环境；目录缺失通常由 preflight 自动 init） |
| **Superpowers** | `superpowers_ready: False`（两个 Skill 未齐） | 报告标 ❌ | **是**（#2，仅环境） |
| **project-config** | 门禁通过后按 exploration 白名单生成 | Phase 1 前处理 | 非环境 AskUserQuestion |

**AskUserQuestion 隔离（硬性）**

| 规则 | 说明 |
|------|------|
| **环境专用** | #1a / #1b / #2 仅用于补环境，选项仅：代装 / 手动步骤 / 暂停 |
| **禁止合并** | 不得将 OpenSpec + Superpowers 合并为一次提问 |
| **禁止越级** | OpenSpec 未就绪时不得问 Superpowers；环境 ❌ 时不得问 Phase 1/2/3 确认 |
| **禁止混搭** | 环境未就绪的回复**不得**附带「继续开发 / 制定方案 / 结束会话」等 Phase 续航选项 |
| **Phase 专用** | Explore 方案选定、Phase 1→2、Phase 2→3 等 AskUserQuestion **仅**在门禁「可以」且进入对应 Phase 后单独发起；Explore：**对话正文**须先完整输出 §2.1（1）–（6）（见 [phase1.md](phases/phase1.md) §2.0.5），**再** AskUserQuestion |
| **Explore 跳过 ≠ 确认** | AskUserQuestion 被跳过**不得**自动 Propose；须重发 §2.1 正文并再次 AskUserQuestion |
| **续航 AskUserQuestion 抢先** | Explore 未交付 §2.1 六节正文前，**禁止** Session 续航 / 结束会话类 AskUserQuestion |

**安装方式（运行时引导，不自动静默安装）**

| 缺失项 | 命令 |
|--------|------|
| OpenSpec CLI | `npm install -g @fission-ai/openspec@latest` |
| OpenSpec 项目 | `openspec init --tools <agent-slug>`（缺 `openspec/` 时 preflight 已自动执行） |
| Superpowers | `npx skills add obra/superpowers --skill writing-plans --skill executing-plans -a <agent> -g`<br>或 `bash <skill_root>/scripts/enable-superpowers.sh --run` |

细节见 [preparation.md](phases/preparation.md)。

### 1.5 Phase 2 硬门禁与「制定开发计划」路径

**Phase 2 前置**（缺任一项 → 禁止 **`writing-plans`**、禁止写 `docs/superpowers/plans/`）

1. 首个回合三步已完成
2. `dev-plan/.../1.proposal.md` 存在
3. `openspec/changes/<name>/` 含 `proposal.md`、`design.md`、`tasks.md`
4. 用户 AskUserQuestion **确认 Phase 1**

**「制定开发计划」完整路径**（不可跳步）

```
门禁 → Phase1 /opsx:explore（或 openspec-explore）→ 调研
     → **对话正文 §2.1（1）–（6）** → 方案 AskUserQuestion（用户明确选定）
     → /opsx:propose（或 openspec-propose）→ 1.proposal.md
     → 用户确认 → Phase2 writing-plans Skill → 2.plan.md
```

---

## 二、场景判定（仅门禁「可以」后执行）

> §1 环境未就绪 → **禁止读本节**、禁止 `validate-project-config`、禁止场景推断与 Phase 续航 AskUserQuestion。

### 2.1 project-config

```powershell
& <skill_root>/scripts/validate-project-config.ps1
```

```bash
bash <skill_root>/scripts/validate-project-config.sh
```

- **无效** → 复制 [templates/project-config.md](templates/project-config.md)，用 `safe-list-files` + 白名单探索后重新校验
- **有效** → 继续 §2.2

### 2.2 计划目录与场景

| 条件 | 场景 | 动作 |
|------|------|------|
| 有 `7.acceptance.md` | A：验收后反馈 | 读 [phase3.md](phases/phase3.md) 验收后反馈章节；回复开头声明「检测到验收后反馈…」 |
| 有历史产物、无验收 | B/C/D… | 按最后完成 Phase 从下一阶段继续 |
| 未引用计划目录 | E：新需求 | 从 Phase 1 开始 |

> **worktree 续做**：若该 change 处于 Phase ≥3 且有活跃 worktree（`worktree-status`），代码改动须在 worktree 路径内进行，dev-plan 报告仍在主工作树；定位见「三、worktree 隔离」。

### 2.3 用户诉求 → Phase

| 用户表述 | 应完成 Phase |
|----------|-------------|
| 制定方案 / 出方案 / 做设计 | Phase 1（Explore → Propose） |
| **制定开发计划** | **Phase 1 → Phase 2**（不是只写 `1.proposal.md`） |
| 开始开发 / 写代码 | Phase 3 起（方案与计划已确认） |
| 只做测试 / Lint | 定位计划目录 → Phase 4 / 5 |

### 2.4 Explore 分流

| 需求类型 | 流程 |
|----------|------|
| **新功能** | **`/opsx:explore`** 或 **`openspec-explore`** → 调研 → **对话正文 §2.1** → AskUserQuestion → **`/opsx:propose`** 或 **`openspec-propose`** |
| **已有功能变更** | 可直接 **`/opsx:propose`** 或 **`openspec-propose`**（Explore 可跳过） |

Explore 输出结构与 AskUserQuestion 时机见 [phase1.md](phases/phase1.md) §2.0.5–2.2（**调研结束 ≠ Explore 完成**；须先在对话正文输出 §2.1，再 AskUserQuestion）。

---

## 三、全流程

```
需求 → §一 入口门禁 → 创建 dev-plan 目录
  → Phase 1 /opsx:explore + /opsx:propose → 1.proposal.md + openspec/changes/<name>/
  → Phase 2 writing-plans Skill → 2.plan.md + docs/superpowers/plans/*-tdd.md
  → [worktree] Phase 2 确认后：commit openspec+TDD → 确认源分支 → worktree-create
  → Phase 3（worktree 内）：executing-plans（Wave 1…N，TDD）→ 全部 Wave ✅ → /opsx:apply（仅 tasks 剩余项）→ 3.dev.md（main）+ 代码（worktree）
  → Phase 4（worktree）：run-tests 基线 → 补自动化测试 → 全量 run-tests 循环至通过 → 4.test-case.md
  → Phase 5（worktree）Lint ↔ Phase 4（循环至通过）→ 5.lint-report.md
  → Phase 6（worktree）文档 → 6.docs-update.md
  → Phase 7 验收 → /opsx:archive（worktree）+ 7.acceptance.md（main）
  → [worktree] 验收通过后：worktree-merge-back（rebase → merge → 清理）
  → 用户反馈 → 回退 Phase 3
```

**阶段与产物**

| 阶段 | 规则文件 | 产物 |
|------|---------|------|
| 前置 | [preparation.md](phases/preparation.md) | 环境就绪 |
| 探索 | [exploration.md](phases/exploration.md) | project-config |
| Phase 1 | [phase1.md](phases/phase1.md) | `1.proposal.md` + `openspec/changes/<name>/` |
| Phase 2 | [phase2.md](phases/phase2.md) | `2.plan.md` + TDD 计划 |
| Phase 3 | [phase3.md](phases/phase3.md) | `3.dev.md` + 代码 |
| Phase 4 | [phase4.md](phases/phase4.md) | 自动化测试代码 + `4.test-case.md` + `test-results/` |
| Phase 5 | [phase5.md](phases/phase5.md) | `5.lint-report.md` |
| Phase 6 | [phase6.md](phases/phase6.md) | `6.docs-update.md` |
| Phase 7 | [phase7.md](phases/phase7.md) | `7.acceptance.md` + 归档 |

**阶段流转**

| 从 | 到 | 条件 |
|----|-----|------|
| 开始 | Phase 1 | 门禁通过 + 计划目录已创建 |
| Phase 1 | Phase 2 | 质量门禁 + **用户确认** |
| Phase 2 | Phase 3 | 质量门禁 + **用户确认** + **[worktree] `worktree-create`**（确认源分支后创建） |
| Phase 3 | Phase 4 | **先** 全部 Wave ✅（`executing-plans`）；**再** `/opsx:apply` 或 `openspec-apply-change` 处理 `tasks.md` 剩余项（无剩余可跳过 apply） |
| Phase 4 | Phase 5 | **`run-tests` 全量通过**（`TESTS: pass`）且已补自动化测试；或用户 AskUserQuestion 确认跳过 |
| Phase 5 | Phase 6 | Lint 零错误 |
| Phase 6 | Phase 7 | 文档完成 |
| Phase 7 | 完成 | 验收 + **`/opsx:archive`** 或 **`openspec-archive-change`** + **[worktree] `worktree-merge-back`**（rebase → merge → 清理） |
| Phase 7 | Phase 3 | 验收后反馈 |
| Phase 5 | Phase 4 | Lint 修复后强制回退测试 |

### worktree 隔离（并行开发，可选）

> **目的**：一个 change = 一个分支 + 一个独立 worktree，并行功能互不踩源码。
> 非 git 项目自动降级为单工作树（靠 change 目录隔离，即现状）。rebase / merge /
> worktree 清理由 `worktree-merge-back` 执行，**冲突一律停下交用户，绝不自动 resolve**。

| 内容 | 位置 |
|------|------|
| dev-plan 各 phase 报告、project-config、`.dev-lifecycle/` | **主工作树（源分支）**，全程在此生成/跟进 |
| openspec（changes / specs / archive）、`docs/superpowers/plans/*-tdd.md` | **feature 分支（worktree）**，随分支走 |
| 源码 / 测试 / 项目文档（Phase 3~6 改动） | **worktree** |

**隔离（Phase 2 → Phase 3 之间）**

1. Phase 2 确认后，把 openspec + TDD 计划 **commit 到当前（源）分支**（worktree 是干净 checkout，不 commit 带不过去）。
2. **AskUserQuestion 只确认源分支**（默认当前分支）；分支名 `{feature|fix}-<change-name>` 与前缀由需求分析自动得出，**无需用户确认**。
3. `worktree-create --change-name <name> --kind feature|fix --base-branch <源分支>` → 创建 `.worktrees/<branch>`、登记 `.dev-lifecycle/worktrees.tsv`，并自动把 `.worktrees/` 写进 `.gitignore`。

**开发期（Phase 3~6）**

- 代码 / 测试 / 文档改动都在 **worktree 路径**下；dev-plan 报告（3.dev.md~6.docs-update.md）仍在**主工作树**的 dev-plan 目录跟进。
- apply 勾选 tasks、TDD step 勾选在 worktree 内的 openspec / TDD 副本上做（随 merge 合回）。

**合并（Phase 7 完成后）**

1. Phase 7：`/opsx:archive`（worktree 内）→ 7.acceptance.md（主工作树）→ 用户验收通过。
2. `worktree-merge-back --change-name <name> --kind feature|fix`：rebase（到源分支最新）→ merge（默认 `--no-ff`）→ worktree remove → 删分支 → 登记表置 `merged`。

**resume / 续做**

- 未完成 change 的 dev-plan 目录始终在主工作树；`worktree-status`（或登记表）给出「哪个 change 有活跃 worktree、路径在哪」。
- 续做时：定位 dev-plan 目录 → 取 change-name → `worktree-status` 找对应 worktree → **代码进 worktree、dev-plan 报告进主工作树**。

---

## 四、产物与时间

### 4.1 dev-plan 目录结构

```
dev-plan/<YYYYMM>/<YYYYMMDD>/<YYYYMMDDHHmmss>_<type>_<detail>/
├── 1.proposal.md … 7.acceptance.md
└── lint-results/
```

- `type`：`feat` / `fix` / `refactor` / `perf` / `docs`
- 时间戳 **必须 Shell 获取**
- **plan-dir 内超链接**：跨根目录链接须按 [plan-dir-link-prefix.md](reference/plan-dir-link-prefix.md) 计算 PREFIX，禁止照抄模板 `../../`

| 阶段 | 权威产物 | dev-plan 索引 |
|------|---------|--------------|
| Phase 1 | `openspec/changes/<name>/` | `1.proposal.md` |
| Phase 2 | `docs/superpowers/plans/*-tdd.md` | `2.plan.md` |
| Phase 7 后 | `openspec/archive/<date>-<name>/` | 更新 `1.proposal.md` 链接 |

**初始化**（Phase 1 前）

```powershell
& <skill_root>/scripts/init-plan-dir.ps1 -Type feat -Detail <detail>
```

```bash
bash <skill_root>/scripts/init-plan-dir.sh --type feat --detail <detail>
```

**时间戳 / 任务编号**（均须 Shell 获取，严禁编造）

```powershell
& <skill_root>/scripts/timestamp.ps1 -Format datetime
& <skill_root>/scripts/next-task-id.ps1
```

```bash
bash <skill_root>/scripts/timestamp.sh --format datetime
bash <skill_root>/scripts/next-task-id.sh
```

### 4.2 任务编号

`T-{YYYYMMDD}-{序号}` — 日期与序号 **必须 Shell 获取**。

### 4.3 时间戳

所有产物「生成时间」「最后更新」、计划目录名、阶段耗时 — **均须 Shell 获取**。已存在文件的「生成时间」不可改。

### 4.4 过程追踪（供 Phase 7）

记录各 Phase 耗时、`lint_fail_count` / `test_fail_count` / `build_fail_count`、变更文件路径。

---

## 五、快速启动

| 场景 | 入口 |
|------|------|
| **新功能** | §一 门禁 → project-config → 建计划目录 → Phase 1（禁 brainstorming）→ Phase 2（硬门禁）→ Phase 3~7 |
| **已有 OpenSpec** | 建目录 + `1.proposal.md` 索引 → 从 Phase 2 |
| **紧急修复** | 符合轻量条件可跳过 Phase 1/2，否则简化 propose + 单 Wave → Phase 3~7 |
| **单阶段** | 定位计划目录 → 读对应 phase 文件 |

**新功能逐步清单**

```
1. §1.1 首个回合：Shell preflight（内置 7 天缓存：valid 自动跳过，否则全量执行并刷新时间戳）→ Read preparation + 报告模板 → 输出门禁报告
2. 环境 ❌ → 仅环境 AskUserQuestion（#1a/#1b/#2），补全后重跑 preflight；停止
3. 门禁「可以」→ Read exploration.md → project-config 有效化
4. 创建计划目录（含 lint-results/）
5. Phase 1：`/opsx:explore` → **对话正文 §2.1** → 方案 AskUserQuestion（用户选定）→ `/opsx:propose` → 1.proposal.md
6. 用户确认 Phase 1 → **`writing-plans` Skill** → 2.plan.md
6.5 [worktree] 确认源分支 → `worktree-create`（后续代码在 worktree 内，dev-plan 报告仍在主工作树）
7. Phase 3（worktree）：**`executing-plans`** 按 Wave TDD → 全部 Wave ✅ → **`/opsx:apply`**（仅剩余 tasks）→ Phase 4~7（worktree）
7.5 [worktree] Phase 7 验收 + archive 后 → `worktree-merge-back`
```

---

## 六、参考与脚本

### 6.1 辅助资源

| 资源 | 路径 |
|------|------|
| 使用指南 | [README.md](README.md) |
| Rules 模板 | [reference/01-openspec-workflow.mdc](reference/01-openspec-workflow.mdc)、[02-tdd-plan-wave-tracking.mdc](reference/02-tdd-plan-wave-tracking.mdc)、[03-askquestion-task-followup.mdc](reference/03-askquestion-task-followup.mdc) |
| 超链接 PREFIX | [reference/plan-dir-link-prefix.md](reference/plan-dir-link-prefix.md) |
| **强制工具** | [reference/mandatory-tooling.md](reference/mandatory-tooling.md) |
| 阶段规则 | [phases/preparation.md](phases/preparation.md)、[exploration.md](phases/exploration.md)、[phase1.md](phases/phase1.md) … [phase7.md](phases/phase7.md) |
| 产物模板 | [templates/README.md](templates/README.md) |
| 质量门禁 | [checklist.md](checklist.md) |
| 运行时配置 | [project-config.md](project-config.md) |

### 6.2 脚本入口

完整索引：[scripts/README.md](scripts/README.md)

| 阶段 | 脚本 |
|------|------|
| 前置 | `preflight`（含 7 天门禁缓存）/ `check-env` / `check-superpowers` / `enable-superpowers` / `restore-rules` / `ensure-openspec` |
| Phase 1 前 | `init-plan-dir`、`validate-project-config`、`safe-list-files` |
| Phase 2 前 | `gate-phase2` |
| Phase 3 | `check-wave-sync`、`check-tasks-sync` |
| Phase 4 | `run-tests`、`parse-test-results` |
| Phase 5 | `run-lint`、`parse-lint-results` |
| Phase 7 | `gate-phase7`、`update-proposal-links` |
| worktree 隔离 | `worktree-create`、`worktree-status`、`worktree-merge-back` |
| 通用 | `timestamp`、`next-task-id`、`check-plan-artifacts` |
