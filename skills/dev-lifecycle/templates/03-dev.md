# 3.dev.md 模板 — 开发记录（结构示例）

> **Phase 3** · [phase3.md](../phases/phase3.md) · 每 Wave/轮次追加，时间戳 Shell 获取
>
> ⚠️ TDD 外链须用 `<PREFIX>`，见 [plan-dir-link-prefix.md](../reference/plan-dir-link-prefix.md)。

```markdown
# 开发记录

> 关联计划：[2.plan.md](2.plan.md) → [TDD 计划](<PREFIX>docs/superpowers/plans/YYYY-MM-DD-<feature>-tdd.md)
> 生成时间：YYYY-MM-DD HH:mm:ss
> 最后更新：YYYY-MM-DD HH:mm:ss

## Worktree 隔离上下文

> 进入 Phase 3 时的隔离决策，来自 `gate-phase3` 输出与用户选择；供续做 agent 定位代码位置。
> **每个受影响仓库一行**：single 仓库填一行；多仓库逐仓库填；非 git 时「是否 worktree」= 否、目录填项目根。

| 仓库 | 是否 worktree | 仓库目录 | 源分支 base | 目标分支 target | worktree 路径 |
|------|--------------|---------|------------|----------------|--------------|
| `backend`（仓库名） | 是 / 否 | `/a/b` | `main` | `feature-<change-name>` | `/a/b/.worktrees/feature-<change-name>` |
| `frontend`（仓库名） | 是 / 否 | `/a/c` | `main` | `feature-<change-name>` | `/a/c/.worktrees/feature-<change-name>` |

## 开发轮次

### 第 1 轮 — Wave 1 实施

> Wave：Wave 1
> OpenSpec tasks：1.1–1.3
> 开始时间：YYYY-MM-DD HH:mm:ss
> 完成时间：YYYY-MM-DD HH:mm:ss

#### 开发内容
- 功能点 1：xxx
- 功能点 2：xxx

#### 变更文件
- `path/to/file.go`（新增）
- `path/to/file.vue`（新增）

---

### 第 2 轮 — 验收反馈修复

> 开始时间：YYYY-MM-DD HH:mm:ss
> 完成时间：YYYY-MM-DD HH:mm:ss

#### 反馈来源
用户验收后反馈

#### 问题清单

| # | 类别 | 问题描述 | 处理方式 | 状态 |
|---|------|---------|---------|------|
| 1 | 🐛 Bug | xxx | 修复 xxx | ✅ |
| 2 | ⚡ 优化 | xxx | 优化 xxx | ✅ |
| 3 | 📋 其他 | xxx | 调整 xxx | ✅ |

#### 变更文件
- `path/to/file.go`（修改）
```

> 轮次时间必须通过 Shell 命令获取真实系统时间（参见 SKILL.md「全局时间约束」）。
