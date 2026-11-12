# coding-skills

多 IDE 通用的 Agent Skills 集合，支持 **Claude Code / Cursor / Codex**，通过
[`skills` CLI](https://github.com/vercel-labs/skills) 安装。

| Skill | 作用 |
|-------|------|
| [dev-lifecycle](skills/dev-lifecycle/) | 端到端开发生命周期管理：OpenSpec 方案 → TDD 计划 → Wave 实施 → 测试 / Lint / 文档 → 验收归档，共 7 个 Phase，带入口环境门禁，支持 worktree 多分支并行隔离 |
| [git-commit-planner](skills/git-commit-planner/) | 扫描工作区内所有 Git 仓库，按功能模块与时间线分析改动，生成结构化多提交点计划，再逐步安全执行 `git add` / `git commit` |

两个 Skill 相互独立，可单独安装。

## 安装

需要 Node.js 22.20+。

```bash
# 交互式：勾选要装的 Skill 和目标 IDE
npx skills add zzsen/coding-skills

# 或直接指定
npx skills add zzsen/coding-skills --skill dev-lifecycle --skill git-commit-planner -a claude-code -g
```

- `-a`：`claude-code` | `cursor` | `codex`（不传则由 CLI 探测本机已装的 agent 让你多选）
- `-g`：装到全局；去掉则装到当前项目

### 安装落点

| agent | 全局 | 项目 |
|-------|------|------|
| claude-code | `~/.claude/skills/` | `.claude/skills/` |
| cursor | `~/.cursor/skills/` | `.agents/skills/` |
| codex | `~/.agents/skills/` | `.agents/skills/` |

下文的 `<skill_root>` 即安装后 `SKILL.md` 所在目录。

## dev-lifecycle 的环境依赖

dev-lifecycle 依赖两套外部工具链。**安装 Skill 不会自动装它们** —— Skill 在运行时由
`preflight` 检测，未就绪则输出安装命令，并通过提问让你选择「代为安装 / 手动安装 / 暂停」。

```bash
# OpenSpec（CLI + 项目 init）
npm install -g @fission-ai/openspec@latest
openspec init --tools claude     # cursor → --tools cursor；codex → --tools codex

# Superpowers（writing-plans / executing-plans）
npx skills add obra/superpowers --skill writing-plans --skill executing-plans -a claude-code -g
```

也可以装好 Skill 后直接跑脚本：

```bash
bash <skill_root>/scripts/preflight.sh                   # 查看缺什么
bash <skill_root>/scripts/enable-superpowers.sh --run    # 代为安装 Superpowers
```

只有 `environment-ready: True` 时 dev-lifecycle 才允许进入 Phase 1~7。

## Agent 探测

所有脚本自动探测当前 agent，优先级从高到低：

1. 环境变量 `DEVLC_AGENT`（`claude-code` | `cursor` | `codex`）
2. Skill 自身的安装路径（`~/.claude/skills` → `claude-code`，依此类推）
3. 项目内标记目录 / 文件（`.claude/` / `.cursor/` / `.agents/` / `AGENTS.md`）
4. 用户级目录（`~/.claude` / `~/.cursor` / `~/.agents`）

探测不准时显式覆盖：

```bash
bash <skill_root>/scripts/preflight.sh --agent=cursor
DEVLC_AGENT=codex bash <skill_root>/scripts/preflight.sh
```

探测结果决定三件事：skills 目录、`openspec init --tools` 的目标 slug、常驻规则载体
（Cursor `.cursor/rules/*.mdc` / Claude Code `CLAUDE.md` / Codex `AGENTS.md`）。

## 产物位置（使用 Skill 的项目内）

| 内容 | 位置 |
|------|------|
| dev-lifecycle 运行时配置 | `.dev-lifecycle/project-config.md` |
| preflight 执行标记 | `.dev-lifecycle/.preflight-last-run` |
| 阶段产物索引 | `dev-plan/<YYYYMM>/<YYYYMMDD>/<ts>_<type>_<detail>/` |
| OpenSpec 权威产物 | `openspec/changes/<name>/` |
| TDD 计划 | `docs/superpowers/plans/*-tdd.md` |
| 提交计划 | `commit-plan/<YYYYMM>/` |
| worktree 隔离工作树（可选） | `.worktrees/<feature\|fix>-<change>/` |
| worktree 登记表 | `.dev-lifecycle/worktrees.tsv` |

> 配置与标记放在项目级 `.dev-lifecycle/` 而非 Skill 目录内 —— 全局安装时 Skill 目录为多项目共享。

## worktree 并行开发（dev-lifecycle 可选）

多分支并行开发时，每个 change 对应一个分支 + 一个独立 worktree，互不踩源码：

- **隔离点**：Phase 2 确认后、Phase 3 前；源分支默认当前分支（由 Agent 与用户确认），分支名 `{feature|fix}-<change-name>` 由需求分析自动得出。
- **工作树**：落在 `.worktrees/<branch>/`；dev-plan 各阶段报告仍在主工作树跟进，源码 / 测试 / openspec 随 worktree 走。
- **合并点**：Phase 7 验收通过后 `worktree-merge-back`（rebase → merge --no-ff → worktree remove → 删分支）；**冲突停下交用户，绝不自动 resolve**。
- **降级**：非 git 项目自动降级为单工作树内按 change 目录隔离（即无 worktree 时的现状）。

## 跨 IDE 差异

Skill 文档使用规范工具名，实际名称按 IDE 取用（完整对照见
[dev-lifecycle SKILL.md §0.3](skills/dev-lifecycle/SKILL.md)）：

| 文档用语 | Claude Code | Cursor | Codex |
|----------|-------------|--------|-------|
| 执行命令 | `Bash` | `Shell` | `shell` |
| 结构化提问 | `AskUserQuestion` | `AskQuestion` | 无 → 正文列编号选项并等待 |
| 按串替换改文件 | `Edit` | `StrReplace` | `apply_patch` |
| 待办清单 | `TodoWrite`（无 `id`、不可勾选） | `todo_write`（可勾选） | 无 → 正文编号清单 |

两个需要注意的降级点：

- **Codex 没有结构化提问工具** —— 凡需要提问处改为「正文列编号选项 + 停下等待」，
  隔离规则（环境专用 / 禁止合并 / 禁止越级）同样适用，不得跳过确认直接推进。
- **Claude Code 的待办不可被用户勾选** —— git-commit-planner 必须用文字确认要执行哪些提交点，
  不能靠待办项状态推断用户意图。

## 目录结构

```
coding-skills/
├── README.md
└── skills/                      # skills CLI 的标准发现路径
    ├── dev-lifecycle/
    │   ├── SKILL.md             # 主文档：门禁、场景判定、7 Phase 总览
    │   ├── checklist.md         # 质量门禁清单
    │   ├── phases/              # 各 Phase 规则（preparation / exploration / phase1~7）
    │   ├── reference/           # 强制工具链说明、规则模板、链接前缀规则
    │   ├── templates/           # 产物模板（门禁报告、proposal、plan…）
    │   └── scripts/             # bash + PowerShell 双实现
    └── git-commit-planner/
        ├── SKILL.md
        └── scripts/             # git_add_commit.sh / .ps1
```

## 脚本

`skills/dev-lifecycle/scripts/` 下每个脚本都有 `.sh` 与 `.ps1` 两份实现（`_init-ps.ps1` 除外），
索引见 [scripts/README.md](skills/dev-lifecycle/scripts/README.md)。关键的几个：

| 脚本 | 用途 |
|------|------|
| `_agent-lib` | agent 探测与路径解析（函数库，被其他脚本 source） |
| `preflight` | 入口门禁编排：check-env → restore-rules → ensure-openspec → check-env |
| `check-env` | 环境定点检查，输出 `environment-ready` |
| `check-superpowers` / `enable-superpowers` | Superpowers 检测 / 安装 |
| `init-plan-dir`、`timestamp`、`next-task-id` | dev-plan 目录与时间戳（**时间必须由脚本取，禁止编造**） |
| `run-tests`、`run-lint` | Phase 4 / 5 的测试与 Lint 执行与结果解析 |
| `gate-phase2`、`gate-phase7` | 阶段硬门禁的文件级校验 |
| `worktree-create`、`worktree-status`、`worktree-merge-back` | worktree 并行开发：创建隔离 / 定位续做 / 合并回源分支 |

## License

MIT
